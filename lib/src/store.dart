import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class AppStore extends ChangeNotifier {
  static const storageKey = 'hantteok.prototype.v1';
  bool loggedIn = false, merchantAccess = false;
  String nickname = '다정한 이웃', realName = '김한결', communityId = 'school';
  Set<String> verified = {'school'};
  List<Shop> shops = seedShops();
  List<Benefit> benefits = [];
  List<Usage> usages = [];
  List<SupportTicket> tickets = [];
  List<AppNotice> notices = [];
  Set<String> settled = {};
  Map<String, bool> notificationSettings = {
    '사용 알림': true,
    '소진 알림': true,
    '환불 알림': true,
  };
  UseRequest? request;
  SharedPreferences? _prefs;
  String? storageError;
  Future<void> _writeQueue = Future.value();
  String newId(String prefix) =>
      '$prefix${DateTime.now().microsecondsSinceEpoch}';
  Community get community => communities.firstWhere((c) => c.id == communityId);
  Shop shop(String id) => shops.firstWhere((s) => s.id == id);
  Benefit benefit(String id) => benefits.firstWhere((b) => b.id == id);
  Community group(String id) => communities.firstWhere((c) => c.id == id);
  bool get isVerified => verified.contains(communityId);
  int get unread => notices.where((n) => !n.read).length;
  List<Benefit> get available => benefits
      .where((b) => b.communityId == communityId && b.state == 'active')
      .toList();
  int usedByMe(Benefit b) =>
      usages.where((u) => u.benefitId == b.id).fold(0, (a, u) => a + u.applied);
  int allowance(Benefit b) =>
      b.state == 'active' && verified.contains(b.communityId)
      ? max(0, min(b.remaining, b.limit - usedByMe(b)))
      : 0;

  Future<void> load() async {
    _seed();
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs!.getString(storageKey);
      if (raw == null) return;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      loggedIn = j['loggedIn'];
      merchantAccess = j['merchantAccess'] ?? false;
      nickname = j['nickname'];
      realName = j['realName'];
      communityId = j['communityId'];
      verified = Set<String>.from(j['verified']);
      benefits = (j['benefits'] as List)
          .map((x) => Benefit.fromJson(x))
          .toList();
      usages = (j['usages'] as List).map((x) => Usage.fromJson(x)).toList();
      tickets = (j['tickets'] as List)
          .map((x) => SupportTicket.fromJson(x))
          .toList();
      notices = (j['notices'] as List)
          .map((x) => AppNotice.fromJson(x))
          .toList();
      notificationSettings = Map<String, bool>.from(j['settings']);
      settled = Set<String>.from(j['settled'] ?? []);
      for (final s in shops) {
        final saved = j['shops']?[s.id];
        if (saved != null) {
          s.hours = saved['hours'];
          s.description = saved['description'];
          s.menu = (saved['menu'] as List)
              .map((x) => MenuItem.fromJson(x))
              .toList();
        }
      }
    } catch (_) {
      storageError = '저장 데이터를 읽지 못해 데모 데이터를 불러왔어요.';
      _seed();
    }
  }

  void _seed() {
    final now = DateTime.now();
    benefits = [
      Benefit(
        id: 'b1',
        shopId: 's1',
        communityId: 'school',
        donor: '졸업생 선배',
        message: '시험 준비하느라 고생 많죠?\n밥은 꼭 챙겨 먹어요. 오늘 한 끼는 제가 쏠게요!',
        total: 200000,
        remaining: 145000,
        limit: 5000,
        createdAt: now.subtract(const Duration(days: 3)),
        expiresAt: now.add(const Duration(days: 27)),
        menus: [],
      ),
      Benefit(
        id: 'b2',
        shopId: 's2',
        communityId: 'school',
        donor: '익명의 이웃',
        message: '열심히 달리는 여러분에게 커피 한 잔의 여유를.',
        total: 100000,
        remaining: 68000,
        limit: 4500,
        createdAt: now.subtract(const Duration(days: 2)),
        expiresAt: now.add(const Duration(days: 12)),
        menus: ['아메리카노', '바닐라 라테'],
      ),
      Benefit(
        id: 'b3',
        shopId: 's3',
        communityId: 'school',
        donor: '다정한 이웃',
        message: '갓 구운 빵처럼 따뜻한 하루 보내세요.',
        total: 50000,
        remaining: 35000,
        limit: 4000,
        createdAt: now.subtract(const Duration(days: 1)),
        expiresAt: now.add(const Duration(days: 20)),
        menus: [],
        mine: true,
      ),
      Benefit(
        id: 'b4',
        shopId: 's4',
        communityId: 'volunteer',
        donor: '동네 주민',
        message: '세상을 따뜻하게 해주시는 여러분을 응원해요.',
        total: 150000,
        remaining: 120000,
        limit: 7000,
        createdAt: now.subtract(const Duration(days: 4)),
        expiresAt: now.add(const Duration(days: 15)),
        menus: [],
      ),
    ];
    notices = [
      AppNotice('우리 학교에 따뜻한 한턱이 도착했어요', '온기 식탁에서 든든한 한 끼를 만나보세요.', 'b1', now),
    ];
  }

  void commit() {
    notifyListeners();
    final encoded = jsonEncode({
      'loggedIn': loggedIn,
      'merchantAccess': merchantAccess,
      'nickname': nickname,
      'realName': realName,
      'communityId': communityId,
      'verified': verified.toList(),
      'benefits': benefits.map((b) => b.toJson()).toList(),
      'usages': usages.map((u) => u.toJson()).toList(),
      'tickets': tickets.map((t) => t.toJson()).toList(),
      'notices': notices.map((n) => n.toJson()).toList(),
      'settings': notificationSettings,
      'settled': settled.toList(),
      'shops': {
        for (final s in shops)
          s.id: {
            'description': s.description,
            'hours': s.hours,
            'menu': s.menu.map((m) => m.toJson()).toList(),
          },
      },
    });
    _writeQueue = _writeQueue.then((_) async {
      try {
        if (_prefs == null || !await _prefs!.setString(storageKey, encoded)) {
          storageError = '기기 저장에 실패했어요. 앱 종료 시 변경 내용이 사라질 수 있어요.';
          notifyListeners();
        }
      } catch (_) {
        storageError = '기기 저장 공간을 확인해 주세요.';
        notifyListeners();
      }
    });
  }

  Future<void> flush() => _writeQueue;
  void dismissStorageError() {
    storageError = null;
    notifyListeners();
  }

  void loginDemo({bool merchant = false}) {
    loggedIn = true;
    merchantAccess = merchant;
    commit();
  }

  void logout() {
    loggedIn = false;
    request = null;
    commit();
  }

  void setCommunity(String id) {
    communityId = id;
    commit();
  }

  void addNotice(
    String title,
    String body,
    String targetId, {
    String setting = '사용 알림',
  }) {
    if (notificationSettings[setting] ?? true) {
      notices.insert(0, AppNotice(title, body, targetId, DateTime.now()));
    }
  }

  Benefit pay({
    required String shopId,
    required String target,
    required int amount,
    required int limit,
    required DateTime expiry,
    required String donor,
    required String message,
    required List<String> menus,
  }) {
    if (amount < 1000 ||
        limit <= 0 ||
        limit > amount ||
        !expiry.isAfter(DateTime.now())) {
      throw StateError('금액과 이용 기간을 확인해 주세요.');
    }
    final b = Benefit(
      id: newId('B'),
      shopId: shopId,
      communityId: target,
      donor: donor,
      message: message,
      total: amount,
      remaining: amount,
      limit: limit,
      createdAt: DateTime.now(),
      expiresAt: expiry,
      menus: List.of(menus),
      mine: true,
    );
    benefits.insert(0, b);
    addNotice(
      '한턱이 도착했어요!',
      '${group(target).name}에 ${won(amount)}의 마음을 전했어요.',
      b.id,
    );
    commit();
    return b;
  }

  UseRequest issue(Benefit b) {
    if (!loggedIn || allowance(b) <= 0) {
      throw StateError('인증 상태와 이용 한도를 확인해 주세요.');
    }
    if (request != null &&
        !['completed', 'cancelled'].contains(request!.status)) {
      request!.status = 'cancelled';
    }
    request = UseRequest(newId('QR'), b.id);
    notifyListeners();
    return request!;
  }

  void submitOrder(UseRequest r, String menu, int amount) {
    final b = benefit(r.benefitId);
    if (!merchantAccess ||
        request != r ||
        r.expired ||
        r.status != 'issued' ||
        allowance(b) <= 0 ||
        amount <= 0 ||
        !shop(b.shopId).menu.any((m) => m.name == menu) ||
        (b.menus.isNotEmpty && !b.menus.contains(menu))) {
      throw StateError('QR 유효 상태, 사용 가능 메뉴와 금액을 확인해 주세요.');
    }
    r.menu = menu;
    r.orderAmount = amount;
    r.status = 'pending';
    notifyListeners();
  }

  Usage approve(UseRequest r) {
    if (request != r || r.status != 'pending' || r.expired || !loggedIn) {
      throw StateError('만료되었거나 이미 처리된 요청이에요. QR을 다시 발급해 주세요.');
    }
    final b = benefit(r.benefitId);
    final amount = min(allowance(b), r.orderAmount);
    if (amount <= 0 || usages.any((u) => u.requestId == r.id)) {
      throw StateError('사용 가능 금액이 없거나 이미 완료된 거래예요.');
    }
    final u = Usage(
      id: newId('HT'),
      requestId: r.id,
      benefitId: b.id,
      shopId: b.shopId,
      menu: r.menu,
      orderAmount: r.orderAmount,
      applied: amount,
      date: DateTime.now(),
    );
    b.remaining -= amount;
    r.status = 'completed';
    usages.insert(0, u);
    addNotice(
      '혜택 사용이 완료되었어요',
      '${shop(b.shopId).name}에서 ${won(amount)} 사용',
      u.id,
    );
    if (b.remaining == 0) {
      addNotice(
        '한턱의 마음이 모두 전해졌어요',
        '${shop(b.shopId).name}의 공동 잔액이 소진되었어요.',
        b.id,
        setting: '소진 알림',
      );
    }
    commit();
    return u;
  }

  void cancelRequest(UseRequest r) {
    if (r.status != 'completed') {
      r.status = 'cancelled';
      notifyListeners();
    }
  }

  SupportTicket submitTicket(
    String target,
    String type,
    String reason,
    String evidence,
  ) {
    if (reason.trim().length < 5) {
      throw StateError('사유를 5자 이상 입력해 주세요.');
    }
    if (type == '취소·환불') {
      final b = benefit(target);
      if (!b.mine || b.remaining <= 0 || b.status != 'active') {
        throw StateError('남은 잔액이 있는 본인의 선결제만 신청할 수 있어요.');
      }
      b.status = 'refund';
    }
    final t = SupportTicket(
      id: newId('CS'),
      targetId: target,
      type: type,
      reason: reason.trim(),
      evidence: evidence.trim(),
      date: DateTime.now(),
    );
    tickets.insert(0, t);
    addNotice(
      '$type 신청이 접수되었어요',
      '처리 상태는 마이페이지에서 확인할 수 있어요.',
      t.id,
      setting: '환불 알림',
    );
    commit();
    return t;
  }

  void advanceTicket(SupportTicket t) {
    if (t.status == '처리 완료') return;
    t.status = t.status == '접수' ? '검토 중' : '처리 완료';
    if (t.status == '처리 완료' && t.type == '취소·환불') {
      final b = benefit(t.targetId);
      b.status = 'cancelled';
      addNotice(
        '환불 처리가 완료되었어요',
        '모의 환불 금액 ${won(b.remaining)}',
        b.id,
        setting: '환불 알림',
      );
    }
    commit();
  }
}
