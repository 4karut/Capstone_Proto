import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

/// Transport and account-scoped snapshots; the server owns every domain mutation.
class ServerGateway extends ChangeNotifier {
  final ApiClient api;
  void Function(Map<String, dynamic>)? applySnapshot;
  Map<String, dynamic>? account;
  bool isAdmin = false, busy = false, demo = false;
  int sessionEpoch = 0, revision = -1;
  String? error;
  SharedPreferences? _prefs;
  Timer? _poll;
  Future<void>? _refreshing;
  bool _disposed = false;
  DateTime? _serverTime, _receivedAt;
  ServerGateway({ApiClient? api}) : api = api ?? ApiClient() {
    this.api.onUnauthorized = _expire;
  }
  String get _key => 'hantuck.v2.session:${api.baseUrl}';
  DateTime get currentTime => _serverTime == null
      ? DateTime.now()
      : _serverTime!.add(DateTime.now().difference(_receivedAt!));
  static String commandId() {
    final r = Random.secure();
    return List.generate(
      4,
      (_) => r.nextInt(1 << 32).toRadixString(16).padLeft(8, '0'),
    ).join('-');
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<dynamic> _call(String method, String path, [Object? data]) async {
    try {
      return await api.call(method, path, data);
    } on ApiError catch (e) {
      throw StateError(e.message);
    }
  }

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    try {
      demo = (await _call('GET', '/health'))['demo'] == true;
    } catch (e) {
      error = e.toString();
    }
    api.token = _prefs!.getString(_key);
    if (api.token != null) {
      try {
        await refresh();
      } catch (e) {
        error = e.toString();
      }
    }
    _poll = Timer.periodic(const Duration(seconds: 3), (_) {
      if (account != null && !busy && _refreshing == null) {
        unawaited(
          refresh().catchError((Object e) {
            error = e is StateError ? e.message : e.toString();
            _notify();
          }),
        );
      }
    });
  }

  Future<T> _working<T>(Future<T> Function() operation) async {
    if (busy) throw StateError('처리 중인 요청이 있습니다. 잠시 기다려 주세요.');
    busy = true;
    error = null;
    _notify();
    try {
      if (_refreshing != null) {
        try {
          await _refreshing;
        } catch (_) {}
      }
      return await operation();
    } finally {
      busy = false;
      _notify();
    }
  }

  void _publish(dynamic value) {
    final s = Map<String, dynamic>.from(value as Map);
    if ((s['revision'] as int) < revision) return;
    revision = s['revision'];
    account = Map<String, dynamic>.from(s['account']);
    isAdmin = s['isAdmin'] == true;
    _serverTime = DateTime.parse(s['serverTime']);
    _receivedAt = DateTime.now();
    applySnapshot?.call(s);
    error = null;
    _notify();
  }

  Future<void> refresh() {
    if (api.token == null) return Future.value();
    if (_refreshing != null) return _refreshing!;
    final token = api.token;
    final future = _call('GET', '/snapshot').then<void>((s) {
      if (api.token == token && !_disposed) _publish(s);
    });
    _refreshing = future;
    return future.whenComplete(() => _refreshing = null);
  }

  Future<Map<String, dynamic>?> login(String id, String password) =>
      _working(() async {
        final result = await _call('POST', '/auth/login', {
          'id': id.trim(),
          'password': password,
        });
        api.token = result['accessToken'];
        revision = -1;
        await _prefs?.setString(_key, api.token!);
        await refresh();
        return account;
      });
  Future<bool> available(String id) async =>
      (await _call(
        'GET',
        '/auth/availability?id=${Uri.encodeQueryComponent(id.trim())}',
      ))['available'] ==
      true;
  Future<String> emailChallenge(String email) => _working(
    () async =>
        (await _call('POST', '/auth/email-challenges', {
              'email': email.trim(),
            }))['challengeId']
            as String,
  );
  Future<String> verifyEmail(String challenge, String code) => _working(
    () async =>
        (await _call('POST', '/auth/email-verify', {
              'challengeId': challenge,
              'code': code,
            }))['verificationToken']
            as String,
  );
  Future<Map<String, dynamic>> register(Map<String, Object?> fields) =>
      _working(
        () async => Map<String, dynamic>.from(
          await _call('POST', '/auth/register', fields),
        ),
      );
  Future<Map<String, dynamic>> command(
    String action,
    Map<String, dynamic> data, {
    String? id,
  }) => _working(() async {
    const routes = <String, String>{
      'group.join': '/groups/join',
      'group.invite': '/groups/invite',
      'group.approve': '/groups/approve',
      'group.favorite': '/groups/favorite',
      'store.favorite': '/stores/favorite',
      'store.apply': '/stores/apply',
      'store.approve': '/stores/approve',
      'store.reject': '/stores/reject',
      'store.thumbnail': '/stores/thumbnail',
      'store.menu.save': '/stores/menus/save',
      'store.menu.remove': '/stores/menus/remove',
      'donation.complete': '/donations/complete',
      'usage.begin': '/usages/begin',
      'usage.find': '/usages/find',
      'usage.amount': '/usages/amount',
      'usage.approve': '/usages/approve',
      'usage.cancel': '/usages/cancel',
      'usage.reverse': '/usages/reverse',
      'usage.thanks': '/usages/thanks',
    };
    final path = routes[action];
    if (path == null) {
      throw ArgumentError.value(action, 'action', 'Unknown command');
    }
    final response = await _call('POST', path, {
      'commandId': id ?? commandId(),
      'data': data,
    });
    _publish(response['snapshot']);
    return Map<String, dynamic>.from(response['result']);
  });
  Future<void> logout() async {
    try {
      if (api.token != null) await _call('POST', '/auth/logout');
    } finally {
      await _expire();
    }
  }

  Future<void> _expire() async {
    api.token = null;
    account = null;
    isAdmin = false;
    revision = -1;
    sessionEpoch++;
    _notify();
    applySnapshot?.call({
      'groups': [],
      'members': {},
      'groupApplications': [],
      'stores': [],
      'storeApplications': [],
      'offers': [],
      'donations': [],
      'requests': [],
      'receipts': [],
      'groupFavorites': [],
      'storeFavorites': [],
    });
    await _prefs?.remove(_key);
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _poll?.cancel();
    api.close();
    super.dispose();
  }
}
