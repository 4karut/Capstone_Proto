import 'dart:math';

import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';

import 'prepaid_store.dart';

class DemoGroup {
  const DemoGroup({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.tags,
    required this.description,
    required this.ownerId,
    required this.thumbnail,
    this.locked = false,
  });

  final String id;
  final String code;
  final String name;
  final String category;
  final List<String> tags;
  final String description;
  final String ownerId;
  final String thumbnail;
  final bool locked;
}

enum GroupJoinStatus { notApplied, pending, member }

class GroupApplication {
  GroupApplication({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.userName,
    required this.introduction,
    required this.createdAt,
  });
  final String id;
  final String groupId;
  final String userId;
  final String userName;
  final String introduction;
  final DateTime createdAt;
  bool _approved = false;
  bool get approved => _approved;
}

class DemoGroupStore extends ChangeNotifier {
  DemoGroupStore({
    Random? random,
    this.introductionRequired = false,
    DateTime Function()? now,
  }) : _random = random ?? Random(),
       _now = now ?? DateTime.now {
    for (final group in allGroups) {
      _members[group.id] = {_userKey(group.ownerId)};
    }
    if (allGroups.map((g) => g.code.toUpperCase()).toSet().length !=
        allGroups.length) {
      throw StateError('그룹 코드는 고유해야 합니다.');
    }
  }

  static const categories = ['전체', '학교·동문', '직장·팀', '취미·모임'];
  static const allGroups = [
    DemoGroup(
      id: 'group-1',
      code: 'HG0001',
      name: '예시 그룹 1',
      category: '학교·동문',
      tags: ['대학생', '캠퍼스', '선후배'],
      description: '캠퍼스에서 작은 응원을 나누는 그룹이에요.',
      ownerId: 'leader01',
      thumbnail: 'assets/images/group-campus.png',
    ),
    DemoGroup(
      id: 'group-2',
      code: 'HG0002',
      name: '예시 그룹 2',
      category: '직장·팀',
      tags: ['직장인', '점심', '동료'],
      description: '동료들과 따뜻한 한 끼를 나눠요.',
      ownerId: 'leader02',
      thumbnail: 'assets/images/group-team.png',
    ),
    DemoGroup(
      id: 'group-3',
      code: 'HG0003',
      name: '예시 그룹 3',
      category: '취미·모임',
      tags: ['산책', '주말', '친목'],
      description: '함께 걷고 마음을 나누는 초대 모임이에요.',
      ownerId: 'leader03',
      thumbnail: 'assets/images/group-walk.png',
      locked: true,
    ),
  ];

  final bool introductionRequired;
  final Random _random;
  final DateTime Function() _now;
  DateTime get currentTime => _now();
  final Map<String, Set<String>> _members = {};
  final List<GroupApplication> _applications = [];
  final Map<String, String> _invitationCodes = {'group-3': '123456'};
  final Map<String, Set<String>> _favorites = {};
  final _prepaidOffers = [
    PrepaidStoreOffer(
      id: 'example-store-1',
      groupId: 'group-3',
      storeName: '예시 가게 1',
      totalAmount: 100000,
      usedAmount: 35000,
      startsOn: DateTime(2026, 10, 28),
      expiresOn: DateTime(2026, 11, 27),
      donorId: 'hantuck01',
      donorName: '한나눔',
    ),
  ];
  static String _userKey(String userId) => userId.trim().toLowerCase();

  DemoGroup group(String id) => allGroups.firstWhere((g) => g.id == id);

  List<DemoGroup> search({String query = '', String category = '전체'}) {
    final tokens = query
        .trim()
        .toLowerCase()
        .replaceAll('#', '')
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    final results = allGroups.where((g) {
      if (category != '전체' && g.category != category) return false;
      final corpus = '${g.name} ${g.code} ${g.tags.join(' ')}'.toLowerCase();
      final compactCorpus = corpus.replaceAll(RegExp(r'\s+'), '');
      return tokens.every(
        (token) => corpus.contains(token) || compactCorpus.contains(token),
      );
    }).toList();
    if (tokens.isEmpty) results.shuffle(_random);
    return results;
  }

  bool isOwner(String groupId, String userId) =>
      _userKey(group(groupId).ownerId) == _userKey(userId);

  bool ownsAnyGroup(String userId) =>
      allGroups.any((g) => isOwner(g.id, userId));

  bool isMember(String groupId, String userId) =>
      _members[groupId]?.contains(_userKey(userId)) ?? false;

  List<DemoGroup> memberships(String userId) =>
      allGroups.where((g) => isMember(g.id, userId)).toList();

  bool isFavorite(String groupId, String userId) =>
      _favorites[_userKey(userId)]?.contains(groupId) ?? false;

  List<DemoGroup> favoritesFor(String userId) =>
      allGroups.where((group) => isFavorite(group.id, userId)).toList();

  bool toggleFavorite(String groupId, String userId) {
    group(groupId);
    final favorites = _favorites.putIfAbsent(
      _userKey(userId),
      () => <String>{},
    );
    final added = !favorites.remove(groupId);
    if (added) favorites.add(groupId);
    notifyListeners();
    return added;
  }

  List<PrepaidStoreOffer> prepaidOffersFor(
    String groupId,
    String userId, {
    DateTime? at,
  }) {
    if (!isMember(groupId, userId)) return const [];
    final instant = at ?? currentTime;
    return _prepaidOffers
        .where(
          (offer) => offer.groupId == groupId && offer.isAvailable(at: instant),
        )
        .toList();
  }

  List<GroupApplication> pendingForUser(String userId) => _applications
      .where((a) => _userKey(a.userId) == _userKey(userId) && !a.approved)
      .toList();

  List<PrepaidStoreOffer> storePrepaidHistory(String storeId) =>
      _prepaidOffers.where((offer) => offer.storeId == storeId).toList();

  PrepaidStoreOffer availablePrepaidOffer(String offerId, String userId) {
    final offer = _prepaidOffers.firstWhere((offer) => offer.id == offerId);
    if (!isMember(offer.groupId, userId) ||
        !offer.isAvailable(at: currentTime)) {
      throw StateError('현재 소속과 선결제 잔액·사용 기한을 확인해 주세요.');
    }
    return offer;
  }

  PrepaidStoreOffer consumePrepaid({
    required String offerId,
    required String userId,
    required int amount,
  }) {
    final offer = availablePrepaidOffer(offerId, userId);
    if (amount <= 0 || amount > offer.remainingAmount) {
      throw StateError('사용 금액이 현재 남은 선결제를 초과해요.');
    }
    final updated = offer.withUsedAmount(offer.usedAmount + amount);
    _prepaidOffers[_prepaidOffers.indexWhere((item) => item.id == offerId)] =
        updated;
    notifyListeners();
    return updated;
  }

  PrepaidStoreOffer restorePrepaid({
    required String offerId,
    required int amount,
    void Function(PrepaidStoreOffer)? onRestored,
  }) {
    final index = _prepaidOffers.indexWhere((offer) => offer.id == offerId);
    if (index < 0) throw StateError('복구할 원래 선결제를 찾을 수 없어요.');
    final offer = _prepaidOffers[index];
    if (amount <= 0 || amount > offer.usedAmount) {
      throw StateError('복구할 사용 금액을 다시 확인해 주세요.');
    }
    final restored = offer.withUsedAmount(offer.usedAmount - amount);
    _prepaidOffers[index] = restored;
    onRestored?.call(restored);
    notifyListeners();
    return restored;
  }

  void recordPrepaidDonation({
    required String id,
    required String groupId,
    required String storeId,
    required String storeName,
    required int amount,
    required DateTime expiresOn,
    required String donorId,
    required String donorName,
  }) {
    group(groupId);
    final seoul = currentTime.toUtc().add(const Duration(hours: 9));
    final today = DateTime(seoul.year, seoul.month, seoul.day);
    final deadline = DateTime(expiresOn.year, expiresOn.month, expiresOn.day);
    if (amount <= 0 ||
        deadline.isBefore(today) ||
        _prepaidOffers.any((offer) => offer.id == id)) {
      throw StateError('선결제 후원 정보를 확인해 주세요.');
    }
    _prepaidOffers.add(
      PrepaidStoreOffer(
        id: id,
        storeId: storeId,
        groupId: groupId,
        storeName: storeName,
        totalAmount: amount,
        usedAmount: 0,
        startsOn: today,
        expiresOn: deadline,
        donorId: donorId,
        donorName: donorName,
      ),
    );
    notifyListeners();
  }

  List<GroupApplication> notificationsForOwner(String userId) => _applications
      .where((a) => !a.approved && isOwner(a.groupId, userId))
      .toList()
      .reversed
      .toList();

  GroupJoinStatus joinStatus(String groupId, String userId) {
    if (isMember(groupId, userId)) return GroupJoinStatus.member;
    if (pendingForUser(userId).any((a) => a.groupId == groupId)) {
      return GroupJoinStatus.pending;
    }
    return GroupJoinStatus.notApplied;
  }

  GroupApplication requestJoin({
    required String groupId,
    required String userId,
    required String userName,
    required String introduction,
  }) {
    if (group(groupId).locked) throw StateError('초대 코드가 필요한 그룹이에요.');
    if (joinStatus(groupId, userId) != GroupJoinStatus.notApplied) {
      throw StateError('이미 신청했거나 가입한 그룹이에요.');
    }
    final intro = introduction.trim();
    if (intro.characters.length > 100) {
      throw StateError('자기소개는 100자 이내로 작성해 주세요.');
    }
    if (introductionRequired && intro.isEmpty) {
      throw StateError('자기소개를 작성해 주세요.');
    }
    final application = GroupApplication(
      id: 'application-${_applications.length + 1}',
      groupId: groupId,
      userId: userId,
      userName: userName,
      introduction: intro,
      createdAt: DateTime.now(),
    );
    _applications.add(application);
    notifyListeners();
    return application;
  }

  void approve({required String applicationId, required String ownerId}) {
    final application = _applications.firstWhere((a) => a.id == applicationId);
    if (!isOwner(application.groupId, ownerId)) {
      throw StateError('그룹장만 승인할 수 있어요.');
    }
    if (application.approved) return;
    _members[application.groupId]!.add(_userKey(application.userId));
    application._approved = true;
    notifyListeners();
  }

  void joinWithInvitation({
    required String groupId,
    required String userId,
    required String code,
  }) {
    if (!group(groupId).locked) throw StateError('이 그룹은 가입 신청을 이용해 주세요.');
    if (isMember(groupId, userId)) throw StateError('이미 가입한 그룹이에요.');
    if (_invitationCodes[groupId] != code.trim()) {
      throw StateError('초대 코드가 일치하지 않아요.');
    }
    _members[groupId]!.add(_userKey(userId));
    notifyListeners();
  }
}
