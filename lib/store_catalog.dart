import 'server_gateway.dart';

import 'package:flutter/foundation.dart';
import 'package:characters/characters.dart';

import 'group_store.dart';
import 'prepaid_store.dart';

class StoreMenuItem {
  const StoreMenuItem({
    required this.name,
    required this.description,
    required this.price,
    this.recommended = false,
  });
  final String name;
  final String description;
  final int price;
  final bool recommended;
}

class DemoStore {
  const DemoStore({
    required this.id,
    required this.name,
    required this.address,
    required this.description,
    required this.tags,
    required this.thumbnail,
    required this.menu,
    required this.ownerId,
    this.category = '한식',
    this.registrationNumber = '',
    this.phoneNumber = '',
  });
  final String id;
  final String name;
  final String address;
  final String description;
  final List<String> tags;
  final String thumbnail;
  final List<StoreMenuItem> menu;
  final String ownerId;
  final String category;
  final String registrationNumber;
  final String phoneNumber;

  DemoStore copyWith({String? thumbnail, List<StoreMenuItem>? menu}) =>
      DemoStore(
        id: id,
        name: name,
        address: address,
        description: description,
        tags: tags,
        thumbnail: thumbnail ?? this.thumbnail,
        menu: menu ?? this.menu,
        ownerId: ownerId,
        category: category,
        registrationNumber: registrationNumber,
        phoneNumber: phoneNumber,
      );
}

enum StoreApplicationStatus {
  pending('심사 대기'),
  approved('승인 완료'),
  rejected('반려');

  const StoreApplicationStatus(this.label);
  final String label;
}

class StoreApplication {
  StoreApplication({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.name,
    required this.registrationNumber,
    required this.address,
    required this.category,
    required this.phoneNumber,
    required this.description,
    required this.createdAt,
    this.previousApplicationId,
    this.submissionNumber = 1,
    String? rootApplicationId,
  }) : rootApplicationId = rootApplicationId ?? id;
  final String id;
  final String ownerId;
  final String ownerName;
  final String name;
  final String registrationNumber;
  final String address;
  final String category;
  final String phoneNumber;
  final String description;
  final DateTime createdAt;
  final String rootApplicationId;
  final String? previousApplicationId;
  final int submissionNumber;
  String? _storeId;
  String? get storeId => _storeId;
  StoreApplicationStatus _status = StoreApplicationStatus.pending;
  StoreApplicationStatus get status => _status;
  bool get approved => _status == StoreApplicationStatus.approved;
  bool get rejected => _status == StoreApplicationStatus.rejected;
  String? _rejectionReason;
  String? get rejectionReason => _rejectionReason;
  DateTime? _reviewedAt;
  DateTime? get reviewedAt => _reviewedAt;
  String? _resubmissionId;
  String? get resubmissionId => _resubmissionId;
}

/// Store information and account-scoped favorites for the local prototype.
class DemoStoreCatalog extends ChangeNotifier {
  ServerGateway? gateway;
  DemoStoreCatalog({
    bool Function(String)? canApprove,
    DateTime Function()? now,
  }) : _canApprove = canApprove ?? ((_) => false),
       _now = now ?? DateTime.now;
  final bool Function(String) _canApprove;
  final DateTime Function() _now;
  static const categories = ['한식', '중식', '일식', '양식', '분식', '카페·디저트', '기타'];
  static const thumbnailChoices = [
    'assets/images/group-team.png',
    'assets/images/group-campus.png',
    'assets/images/group-walk.png',
  ];
  static const allStores = [
    DemoStore(
      id: 'example-store-1',
      name: '예시 가게 1',
      ownerId: 'store01',
      registrationNumber: '0000000000',
      phoneNumber: '0200000000',
      address: '서울특별시 마포구 나눔로 12, 1층 (예시 주소)',
      description: '정성껏 차린 한 끼로 따뜻한 마음을 나눠요.',
      tags: ['한식', '든든한 한 끼', '함께하는 식사'],
      thumbnail: 'assets/images/group-team.png',
      menu: [
        StoreMenuItem(
          name: '따뜻한 집밥 정식',
          description: '밥과 국, 매일 준비하는 반찬을 함께 담았어요.',
          price: 9000,
          recommended: true,
        ),
        StoreMenuItem(
          name: '제육볶음 한 상',
          description: '매콤한 제육볶음에 밥과 반찬을 곁들였어요.',
          price: 10000,
        ),
        StoreMenuItem(
          name: '채소 비빔밥',
          description: '다채로운 채소를 담은 가벼운 한 끼예요.',
          price: 8000,
        ),
      ],
    ),
  ];

  final Map<String, Set<String>> _favorites = {};
  final List<DemoStore> _stores = List.of(allStores);
  final List<StoreApplication> _applications = [];
  static String _userKey(String id) => id.trim().toLowerCase();
  static String _searchKey(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');

  DemoStore store(String id) => _stores.firstWhere((store) => store.id == id);

  List<PrepaidStoreOffer> offersFor(
    String storeId,
    String userId,
    DemoGroupStore groups,
  ) => [
    for (final group in groups.memberships(userId))
      ...groups
          .prepaidOffersFor(group.id, userId)
          .where((offer) => offer.storeId == storeId),
  ];

  List<DemoStore> searchAvailable({
    required String userId,
    required DemoGroupStore groups,
    String query = '',
  }) {
    final name = _searchKey(query);
    return _stores
        .where(
          (store) =>
              _searchKey(store.name).contains(name) &&
              offersFor(store.id, userId, groups).isNotEmpty,
        )
        .toList();
  }

  bool isFavorite(String storeId, String userId) =>
      _favorites[_userKey(userId)]?.contains(storeId) ?? false;

  List<DemoStore> searchAll({String query = ''}) => _stores
      .where((store) => _searchKey(store.name).contains(_searchKey(query)))
      .toList();

  bool ownsStore(String storeId, String userId) => _stores.any(
    (store) =>
        store.id == storeId && _userKey(store.ownerId) == _userKey(userId),
  );
  bool ownsAnyStore(String userId) =>
      _stores.any((store) => ownsStore(store.id, userId));

  List<DemoStore> ownedStores(String userId) => _stores
      .where((store) => _userKey(store.ownerId) == _userKey(userId))
      .toList();
  List<StoreApplication> applicationsFor(String userId) => _applications
      .where((app) => _userKey(app.ownerId) == _userKey(userId))
      .toList()
      .reversed
      .toList();

  List<StoreApplication> latestApplicationsFor(String userId) =>
      applicationsFor(userId)
          .where((app) => app.resubmissionId == null)
          .toList();

  StoreApplication application(String id, String viewerId) {
    final app = _applications.firstWhere((app) => app.id == id);
    if (_userKey(app.ownerId) != _userKey(viewerId) && !_canApprove(viewerId)) {
      throw StateError('본인의 가게 신청만 확인할 수 있어요.');
    }
    return app;
  }

  List<StoreApplication> applicationHistory(String id, String viewerId) {
    final app = application(id, viewerId);
    return List.unmodifiable(
      _applications.where(
        (entry) => entry.rootApplicationId == app.rootApplicationId,
      ),
    );
  }

  bool canResubmit(String id, String ownerId) => _applications.any(
    (app) =>
        app.id == id &&
        _userKey(app.ownerId) == _userKey(ownerId) &&
        app.rejected &&
        app.resubmissionId == null,
  );

  List<StoreApplication> pendingApplications(String adminId) {
    if (!_canApprove(adminId)) throw StateError('관리자만 가게 신청을 확인할 수 있어요.');
    return _applications
        .where((app) => app.status == StoreApplicationStatus.pending)
        .toList()
        .reversed
        .toList();
  }

  StoreApplication apply({
    required String ownerId,
    required String ownerName,
    required String name,
    required String registrationNumber,
    required String address,
    required String category,
    required String phoneNumber,
    String description = '',
    String? resubmissionOf,
  }) {
    StoreApplication? previous;
    if (resubmissionOf != null) {
      if (!canResubmit(resubmissionOf, ownerId)) {
        throw StateError('본인의 반려된 최신 신청만 다시 신청할 수 있어요.');
      }
      previous = this.application(resubmissionOf, ownerId);
    }
    final number = registrationNumber.replaceAll('-', '').trim();
    final phone = phoneNumber.replaceAll('-', '').trim();
    if (ownerId.trim().isEmpty ||
        name.trim().isEmpty ||
        name.trim().length > 50 ||
        !RegExp(r'^\d{10}$').hasMatch(number) ||
        address.trim().isEmpty ||
        address.trim().length > 150 ||
        !categories.contains(category) ||
        !RegExp(r'^0\d{8,10}$').hasMatch(phone) ||
        description.trim().length > 100) {
      throw StateError('가게명·사업자등록번호·주소·카테고리·전화번호를 확인해 주세요.');
    }
    final duplicate =
        _applications.any(
          (app) =>
              (previous == null ||
                  app.rootApplicationId != previous.rootApplicationId) &&
              app.registrationNumber == number &&
              _searchKey(app.address) == _searchKey(address),
        ) ||
        _stores.any(
          (store) =>
              store.registrationNumber == number &&
              _searchKey(store.address) == _searchKey(address),
        );
    if (duplicate) throw StateError('같은 사업자등록번호와 주소로 이미 신청하거나 등록한 가게예요.');
    final application = StoreApplication(
      id: 'store-application-${_applications.length + 1}',
      ownerId: ownerId.trim(),
      ownerName: ownerName.trim(),
      name: name.trim(),
      registrationNumber: number,
      address: address.trim(),
      category: category,
      phoneNumber: phone,
      description: description.trim(),
      createdAt: _now(),
      previousApplicationId: previous?.id,
      rootApplicationId: previous?.rootApplicationId,
      submissionNumber: (previous?.submissionNumber ?? 0) + 1,
    );
    _applications.add(application);
    previous?._resubmissionId = application.id;
    notifyListeners();
    return application;
  }

  DemoStore approve({required String applicationId, required String adminId}) {
    if (!_canApprove(adminId)) throw StateError('관리자만 가게를 승인할 수 있어요.');
    final app = _applications.firstWhere((app) => app.id == applicationId);
    if (app.approved) return store(app.storeId!);
    if (app.status != StoreApplicationStatus.pending) {
      throw StateError('심사 대기 중인 신청만 승인할 수 있어요.');
    }
    final approved = DemoStore(
      id: 'registered-${app.id}',
      name: app.name,
      address: app.address,
      description: app.description.isEmpty
          ? '${app.name}에서 따뜻한 한 끼를 나눠요.'
          : app.description,
      tags: [app.category],
      thumbnail: thumbnailChoices.first,
      menu: const [],
      ownerId: app.ownerId,
      category: app.category,
      registrationNumber: app.registrationNumber,
      phoneNumber: app.phoneNumber,
    );
    _stores.add(approved);
    app._storeId = approved.id;
    app._status = StoreApplicationStatus.approved;
    app._reviewedAt = _now();
    notifyListeners();
    return approved;
  }

  void reject({
    required String applicationId,
    required String adminId,
    required String reason,
  }) {
    if (!_canApprove(adminId)) throw StateError('관리자만 가게 신청을 반려할 수 있어요.');
    final trimmed = reason.trim();
    if (trimmed.isEmpty || trimmed.characters.length > 300) {
      throw StateError('반려 사유를 1~300자로 입력해 주세요.');
    }
    final app = _applications.firstWhere((app) => app.id == applicationId);
    if (app.status != StoreApplicationStatus.pending) {
      throw StateError('심사 대기 중인 신청만 반려할 수 있어요.');
    }
    app._status = StoreApplicationStatus.rejected;
    app._rejectionReason = trimmed;
    app._reviewedAt = _now();
    notifyListeners();
  }

  void _requireOwner(String storeId, String ownerId) {
    if (!ownsStore(storeId, ownerId)) {
      throw StateError('본인이 등록한 가게만 관리할 수 있어요.');
    }
  }

  void updateThumbnail({
    required String storeId,
    required String ownerId,
    required String thumbnail,
  }) {
    _requireOwner(storeId, ownerId);
    if (!thumbnailChoices.contains(thumbnail)) {
      throw StateError('사용할 사진을 선택해 주세요.');
    }
    final index = _stores.indexWhere((store) => store.id == storeId);
    _stores[index] = _stores[index].copyWith(thumbnail: thumbnail);
    notifyListeners();
  }

  void saveMenu({
    required String storeId,
    required String ownerId,
    required StoreMenuItem item,
    int? index,
  }) {
    _requireOwner(storeId, ownerId);
    final current = store(storeId);
    if (item.name.trim().isEmpty ||
        item.name.trim().length > 50 ||
        item.price <= 0 ||
        item.price > 9007199254740991 ||
        item.description.trim().length > 150 ||
        (index != null && (index < 0 || index >= current.menu.length))) {
      throw StateError('메뉴 이름과 가격을 확인해 주세요.');
    }
    if (current.menu.indexed.any(
      (entry) =>
          entry.$1 != index &&
          _searchKey(entry.$2.name) == _searchKey(item.name),
    )) {
      throw StateError('이미 등록된 메뉴 이름이에요.');
    }
    final items = [...current.menu];
    final saved = StoreMenuItem(
      name: item.name.trim(),
      description: item.description.trim(),
      price: item.price,
      recommended: item.recommended,
    );
    if (index == null) {
      items.add(saved);
    } else {
      items[index] = saved;
    }
    final storeIndex = _stores.indexWhere((store) => store.id == storeId);
    _stores[storeIndex] = current.copyWith(menu: List.unmodifiable(items));
    notifyListeners();
  }

  void removeMenu({
    required String storeId,
    required String ownerId,
    required int index,
  }) {
    _requireOwner(storeId, ownerId);
    final current = store(storeId);
    if (index < 0 || index >= current.menu.length) {
      throw StateError('메뉴를 다시 확인해 주세요.');
    }
    final items = [...current.menu]..removeAt(index);
    _stores[_stores.indexWhere((store) => store.id == storeId)] = current
        .copyWith(menu: List.unmodifiable(items));
    notifyListeners();
  }

  List<PrepaidStoreOffer> managedPrepaidOffers({
    required String storeId,
    required String ownerId,
    required DemoGroupStore groups,
  }) {
    _requireOwner(storeId, ownerId);
    return groups.storePrepaidHistory(storeId);
  }

  bool toggleFavorite(String storeId, String userId) {
    store(storeId);
    final favorites = _favorites.putIfAbsent(
      _userKey(userId),
      () => <String>{},
    );
    final added = !favorites.remove(storeId);
    if (added) favorites.add(storeId);
    notifyListeners();
    return added;
  }

  List<DemoStore> favoritesFor(String userId) =>
      _stores.where((store) => isFavorite(store.id, userId)).toList();

  static Map<String, dynamic> menuJson(StoreMenuItem m) => {
    'name': m.name,
    'description': m.description,
    'price': m.price,
    'recommended': m.recommended,
  };
  void importSnapshot(Map<String, dynamic> s) {
    _stores.clear();
    for (final a in s['stores']) {
      _stores.add(
        DemoStore(
          id: a['id'],
          name: a['name'],
          address: a['address'],
          description: a['description'],
          tags: List<String>.from(a['tags']),
          thumbnail: a['thumbnail'],
          ownerId: a['ownerId'],
          category: a['category'],
          registrationNumber: a['registrationNumber'],
          phoneNumber: a['phoneNumber'],
          menu: (a['menu'] as List)
              .map(
                (m) => StoreMenuItem(
                  name: m['name'],
                  description: m['description'],
                  price: m['price'],
                  recommended: m['recommended'],
                ),
              )
              .toList(),
        ),
      );
    }
    final old = {for (final a in _applications) a.id: a};
    _applications.clear();
    for (final a in s['storeApplications']) {
      _applications.add(
        (old[a['id']] ??
              StoreApplication(
                id: a['id'],
                ownerId: a['ownerId'],
                ownerName: a['ownerName'],
                name: a['name'],
                registrationNumber: a['registrationNumber'],
                address: a['address'],
                category: a['category'],
                phoneNumber: a['phoneNumber'],
                description: a['description'],
                createdAt: DateTime.parse(a['createdAt']).toLocal(),
                rootApplicationId: a['rootApplicationId'],
                previousApplicationId: a['previousApplicationId'],
                submissionNumber: a['submissionNumber'],
              ))
          .._storeId = a['storeId']
          .._status = StoreApplicationStatus.values.byName(a['status'])
          .._rejectionReason = a['rejectionReason']
          .._reviewedAt = a['reviewedAt'] == null
              ? null
              : DateTime.parse(a['reviewedAt']).toLocal()
          .._resubmissionId = a['resubmissionId'],
      );
    }
    _favorites.clear();
    if (s['account'] != null) {
      _favorites[s['account']['id']] = Set<String>.from(s['storeFavorites']);
    }
    notifyListeners();
  }

  Future<StoreApplication> applyRemote({
    required String ownerId,
    required String ownerName,
    required String name,
    required String registrationNumber,
    required String address,
    required String category,
    required String phoneNumber,
    String description = '',
    String? resubmissionOf,
  }) async {
    if (gateway == null) {
      return apply(
        ownerId: ownerId,
        ownerName: ownerName,
        name: name,
        registrationNumber: registrationNumber,
        address: address,
        category: category,
        phoneNumber: phoneNumber,
        description: description,
        resubmissionOf: resubmissionOf,
      );
    }
    final r = await gateway!.command('store.apply', {
      'name': name,
      'registrationNumber': registrationNumber,
      'address': address,
      'category': category,
      'phoneNumber': phoneNumber,
      'description': description,
      'resubmissionOf': resubmissionOf,
    });
    return _applications.firstWhere((a) => a.id == r['id']);
  }

  Future<DemoStore> approveRemote({
    required String applicationId,
    required String adminId,
  }) async {
    if (gateway == null) {
      return approve(applicationId: applicationId, adminId: adminId);
    }
    final r = await gateway!.command('store.approve', {
      'applicationId': applicationId,
    });
    return store(r['id']);
  }

  Future<void> rejectRemote({
    required String applicationId,
    required String adminId,
    required String reason,
  }) async {
    if (gateway == null) {
      reject(applicationId: applicationId, adminId: adminId, reason: reason);
      return;
    }
    await gateway!.command('store.reject', {
      'applicationId': applicationId,
      'reason': reason,
    });
  }

  Future<void> updateThumbnailRemote({
    required String storeId,
    required String ownerId,
    required String thumbnail,
  }) async {
    if (gateway == null) {
      updateThumbnail(storeId: storeId, ownerId: ownerId, thumbnail: thumbnail);
      return;
    }
    await gateway!.command('store.thumbnail', {
      'storeId': storeId,
      'thumbnail': thumbnail,
    });
  }

  Future<void> saveMenuRemote({
    required String storeId,
    required String ownerId,
    required StoreMenuItem item,
    int? index,
  }) async {
    if (gateway == null) {
      saveMenu(storeId: storeId, ownerId: ownerId, item: item, index: index);
      return;
    }
    await gateway!.command('store.menu.save', {
      'storeId': storeId,
      'item': menuJson(item),
      'index': index,
      'expectedMenu': store(storeId).menu.map(menuJson).toList(),
    });
  }

  Future<void> removeMenuRemote({
    required String storeId,
    required String ownerId,
    required int index,
  }) async {
    if (gateway == null) {
      removeMenu(storeId: storeId, ownerId: ownerId, index: index);
      return;
    }
    await gateway!.command('store.menu.remove', {
      'storeId': storeId,
      'index': index,
      'expectedMenu': store(storeId).menu.map(menuJson).toList(),
    });
  }

  Future<bool> toggleFavoriteRemote(String storeId, String userId) async {
    if (gateway == null) return toggleFavorite(storeId, userId);
    return (await gateway!.command('store.favorite', {
          'storeId': storeId,
        }))['added'] ==
        true;
  }
}
