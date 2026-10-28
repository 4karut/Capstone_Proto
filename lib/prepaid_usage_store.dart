import 'dart:math';

import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';

import 'donation_store.dart';
import 'group_store.dart';
import 'prepaid_store.dart';
import 'store_catalog.dart';

enum UsageRequestStatus {
  awaitingStore,
  awaitingUser,
  completed,
  cancelled,
  paymentCancelled,
}

class UsagePhoto {
  UsagePhoto({required this.name, required Uint8List bytes})
    : bytes = Uint8List.fromList(bytes).asUnmodifiableView() {
    if (bytes.isEmpty || bytes.length > maxBytes || !isSupportedImage(bytes)) {
      throw StateError('JPG·PNG·WebP 사진 1장(최대 5MB)을 선택해 주세요.');
    }
  }
  static const maxBytes = 5 * 1024 * 1024;
  final String name;
  final Uint8List bytes;
  static bool isSupportedImage(Uint8List data) =>
      (data.length >= 8 &&
          listEquals(data.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10])) ||
      (data.length >= 3 &&
          data[0] == 255 &&
          data[1] == 216 &&
          data[2] == 255) ||
      (data.length >= 12 &&
          String.fromCharCodes(data.sublist(0, 4)) == 'RIFF' &&
          String.fromCharCodes(data.sublist(8, 12)) == 'WEBP');
}

class ThanksMessage {
  const ThanksMessage({
    required this.text,
    required this.createdAt,
    this.photo,
  });
  final String text;
  final UsagePhoto? photo;
  final DateTime createdAt;
}

class PrepaidUsageRequest {
  PrepaidUsageRequest({
    required this.id,
    required this.code,
    required this.offerId,
    required this.storeId,
    required this.groupId,
    required this.userId,
    required this.userName,
    required this.createdAt,
    required this.expiresAt,
  });
  final String id;
  final String code;
  final String offerId;
  final String storeId;
  final String groupId;
  final String userId;
  final String userName;
  final DateTime createdAt;
  final DateTime expiresAt;
  UsageRequestStatus _status = UsageRequestStatus.awaitingStore;
  UsageRequestStatus get status => _status;
  int? _amount;
  int? get amount => _amount;
  String? _cashierId;
  String? _receiptId;
  String? get receiptId => _receiptId;
  String get qrData => 'hantuck:prepaid:$code';
}

class UsageCancellation {
  const UsageCancellation({
    required this.ownerId,
    required this.reason,
    required this.createdAt,
    required this.remainingAmount,
    required this.expiresOn,
  });
  final String ownerId;
  final String reason;
  final DateTime createdAt;
  final int remainingAmount;
  final DateTime expiresOn;
}

class PrepaidUsageReceipt {
  PrepaidUsageReceipt({
    required this.id,
    required this.requestId,
    required this.offerId,
    required this.groupId,
    required this.storeId,
    required this.donorId,
    required this.userId,
    required this.userName,
    required this.amount,
    required this.remainingAmount,
    required this.createdAt,
  });
  final String id;
  final String requestId;
  final String offerId;
  final String groupId;
  final String storeId;
  final String donorId;
  final String userId;
  final String userName;
  final int amount;
  final int remainingAmount;
  final DateTime createdAt;
  ThanksMessage? _thanks;
  ThanksMessage? get thanks => _thanks;
  UsageCancellation? _cancellation;
  UsageCancellation? get cancellation => _cancellation;
  bool get cancelled => _cancellation != null;
}

/// Local prototype ledger. Creating a QR or requesting an amount never consumes funds.
class DemoPrepaidUsageStore extends ChangeNotifier {
  DemoPrepaidUsageStore({
    required this.groups,
    required this.stores,
    Random? random,
  }) : _random = random ?? Random.secure();
  final DemoGroupStore groups;
  final DemoStoreCatalog stores;
  final Random _random;
  final List<PrepaidUsageRequest> _requests = [];
  final List<PrepaidUsageReceipt> _receipts = [];
  static String _key(String value) => value.trim().toLowerCase();

  bool isExpired(PrepaidUsageRequest request) =>
      request.status != UsageRequestStatus.completed &&
      request.status != UsageRequestStatus.cancelled &&
      request.status != UsageRequestStatus.paymentCancelled &&
      !groups.currentTime.isBefore(request.expiresAt);

  String statusLabel(PrepaidUsageRequest request) => isExpired(request)
      ? '이용 코드 만료'
      : switch (request.status) {
          UsageRequestStatus.awaitingStore => '가게 확인 대기',
          UsageRequestStatus.awaitingUser => '결제 승인 대기',
          UsageRequestStatus.completed => '사용 완료',
          UsageRequestStatus.cancelled => '요청 취소',
          UsageRequestStatus.paymentCancelled => '결제 취소',
        };

  PrepaidUsageRequest requestForUser(String id, String userId) {
    final request = _requests.firstWhere((request) => request.id == id);
    if (_key(request.userId) != _key(userId)) {
      throw StateError('본인의 이용 요청만 확인할 수 있어요.');
    }
    return request;
  }

  List<PrepaidUsageRequest> requestsForUser(String userId) => _requests
      .where((request) => _key(request.userId) == _key(userId))
      .toList()
      .reversed
      .toList();

  PrepaidStoreOffer _available(PrepaidUsageRequest request) =>
      groups.availablePrepaidOffer(request.offerId, request.userId);

  void _requireActive(PrepaidUsageRequest request) {
    if (isExpired(request) ||
        request.status == UsageRequestStatus.cancelled ||
        request.status == UsageRequestStatus.completed) {
      throw StateError('만료되었거나 이미 처리한 이용 코드예요. 새 QR을 발급해 주세요.');
    }
    if (request.status == UsageRequestStatus.paymentCancelled) {
      throw StateError('만료되었거나 이미 처리한 이용 코드예요. 새 QR을 발급해 주세요.');
    }
    _available(request);
  }

  PrepaidUsageRequest begin({
    required String offerId,
    required String userId,
    required String userName,
  }) {
    final offer = groups.availablePrepaidOffer(offerId, userId);
    stores.store(offer.storeId);
    if (offer.donorId == null || offer.donorId!.trim().isEmpty) {
      throw StateError('후원자 정보가 없는 선결제예요.');
    }
    for (final request in requestsForUser(userId)) {
      if (request.offerId == offerId &&
          !isExpired(request) &&
          (request.status == UsageRequestStatus.awaitingStore ||
              request.status == UsageRequestStatus.awaitingUser)) {
        return request;
      }
    }
    String? code;
    for (var attempt = 0; attempt < 100; attempt++) {
      final candidate = '${100000 + _random.nextInt(900000)}';
      if (!_requests.any((request) => request.code == candidate)) {
        code = candidate;
        break;
      }
    }
    if (code == null) throw StateError('이용 코드를 다시 발급해 주세요.');
    final request = PrepaidUsageRequest(
      id: 'usage-${_requests.length + 1}',
      code: code,
      offerId: offer.id,
      storeId: offer.storeId,
      groupId: offer.groupId,
      userId: userId.trim(),
      userName: userName.trim(),
      createdAt: groups.currentTime,
      expiresAt: groups.currentTime.add(const Duration(minutes: 10)),
    );
    _requests.add(request);
    notifyListeners();
    return request;
  }

  PrepaidUsageRequest findForStore({
    required String code,
    required String storeId,
    required String ownerId,
  }) {
    if (!stores.ownsStore(storeId, ownerId)) {
      throw StateError('본인 가게의 결제만 처리할 수 있어요.');
    }
    final matches = _requests.where(
      (request) => request.code == code.trim() && request.storeId == storeId,
    );
    if (matches.isEmpty) throw StateError('이 가게에서 사용할 수 있는 이용 코드를 확인해 주세요.');
    final request = matches.single;
    _requireActive(request);
    return request;
  }

  void requestAmount({
    required String requestId,
    required String storeId,
    required String ownerId,
    required int amount,
  }) {
    final request = _requests.firstWhere((request) => request.id == requestId);
    if (request.storeId != storeId || !stores.ownsStore(storeId, ownerId)) {
      throw StateError('본인 가게의 결제만 처리할 수 있어요.');
    }
    _requireActive(request);
    if (request.status != UsageRequestStatus.awaitingStore) {
      throw StateError('이미 이용자에게 금액 확인을 요청했어요.');
    }
    if (parseDonationAmount('$amount') == null ||
        amount > _available(request).remainingAmount) {
      throw StateError('현재 잔액 이내의 사용 금액을 입력해 주세요.');
    }
    request._amount = amount;
    request._cashierId = ownerId;
    request._status = UsageRequestStatus.awaitingUser;
    notifyListeners();
  }

  PrepaidUsageReceipt approve({
    required String requestId,
    required String userId,
  }) {
    final request = requestForUser(requestId, userId);
    if (request.status == UsageRequestStatus.completed) {
      return receiptForUser(request.receiptId!, userId);
    }
    _requireActive(request);
    if (request.status != UsageRequestStatus.awaitingUser ||
        request.amount == null ||
        request._cashierId == null ||
        !stores.ownsStore(request.storeId, request._cashierId!)) {
      throw StateError('사장님이 요청한 금액을 먼저 확인해 주세요.');
    }
    final offer = _available(request);
    if (offer.donorId == null ||
        offer.donorId!.trim().isEmpty ||
        request.amount! > offer.remainingAmount) {
      throw StateError('남은 선결제와 후원 정보를 다시 확인해 주세요.');
    }
    final receipt = PrepaidUsageReceipt(
      id: 'usage-receipt-${_receipts.length + 1}',
      requestId: request.id,
      offerId: offer.id,
      groupId: offer.groupId,
      storeId: offer.storeId,
      donorId: offer.donorId!,
      userId: request.userId,
      userName: request.userName,
      amount: request.amount!,
      remainingAmount: offer.remainingAmount - request.amount!,
      createdAt: groups.currentTime,
    );
    groups.consumePrepaid(
      offerId: offer.id,
      userId: userId,
      amount: request.amount!,
    );
    _receipts.add(receipt);
    request._receiptId = receipt.id;
    request._status = UsageRequestStatus.completed;
    notifyListeners();
    return receipt;
  }

  void cancel({required String requestId, required String userId}) {
    final request = requestForUser(requestId, userId);
    if (request.receiptId != null) {
      throw StateError('사용 완료된 결제는 가게에서 취소할 수 있어요.');
    }
    request._status = UsageRequestStatus.cancelled;
    notifyListeners();
  }

  UsageCancellation reversePayment({
    required String receiptId,
    required String storeId,
    required String ownerId,
    String reason = '',
  }) {
    final receipt = _receipts.firstWhere((receipt) => receipt.id == receiptId);
    if (receipt.storeId != storeId || !stores.ownsStore(storeId, ownerId)) {
      throw StateError('본인 가게에서 완료한 결제만 취소할 수 있어요.');
    }
    if (receipt.cancelled) return receipt.cancellation!;
    final trimmed = reason.trim();
    if (trimmed.characters.length > 300) {
      throw StateError('취소 사유는 300자 이내로 입력해 주세요.');
    }
    final request = _requests.firstWhere(
      (request) => request.id == receipt.requestId,
    );
    if (request.status != UsageRequestStatus.completed ||
        request.receiptId != receipt.id) {
      throw StateError('사용 완료된 결제만 취소할 수 있어요.');
    }
    late final UsageCancellation cancellation;
    groups.restorePrepaid(
      offerId: receipt.offerId,
      amount: receipt.amount,
      onRestored: (restored) {
        cancellation = UsageCancellation(
          ownerId: ownerId.trim(),
          reason: trimmed,
          createdAt: groups.currentTime,
          remainingAmount: restored.remainingAmount,
          expiresOn: restored.expiresOn,
        );
        receipt._cancellation = cancellation;
        request._status = UsageRequestStatus.paymentCancelled;
      },
    );
    notifyListeners();
    return cancellation;
  }

  PrepaidUsageReceipt receiptForUser(String id, String userId) {
    final receipt = _receipts.firstWhere((receipt) => receipt.id == id);
    if (_key(receipt.userId) != _key(userId)) {
      throw StateError('본인의 사용 내역만 확인할 수 있어요.');
    }
    return receipt;
  }

  void sendThanks({
    required String receiptId,
    required String userId,
    required String message,
    UsagePhoto? photo,
  }) {
    final receipt = receiptForUser(receiptId, userId);
    if (receipt.cancelled) throw StateError('취소된 결제에는 새 감사 메시지를 보낼 수 없어요.');
    final text = message.trim();
    if (text.characters.length > 500 || (text.isEmpty && photo == null)) {
      throw StateError('감사 메시지를 500자 이내로 적거나 사진을 첨부해 주세요.');
    }
    if (receipt.thanks != null) {
      final previous = receipt.thanks!;
      if (previous.text == text &&
          previous.photo?.name == photo?.name &&
          listEquals(previous.photo?.bytes, photo?.bytes)) {
        return;
      }
      throw StateError('이미 감사 메시지를 보냈어요.');
    }
    receipt._thanks = ThanksMessage(
      text: text,
      photo: photo,
      createdAt: groups.currentTime,
    );
    notifyListeners();
  }

  List<PrepaidUsageReceipt> notificationsForDonor(String userId) => _receipts
      .where((receipt) => _key(receipt.donorId) == _key(userId))
      .toList()
      .reversed
      .toList();
  List<PrepaidUsageReceipt> thanksForDonor(String userId) =>
      notificationsForDonor(userId)
          .where((receipt) => receipt.thanks != null)
          .toList()
        ..sort((a, b) => b.thanks!.createdAt.compareTo(a.thanks!.createdAt));
  List<PrepaidUsageReceipt> notificationsForStoreOwner(
    String userId, {
    String? storeId,
  }) => _receipts
      .where(
        (receipt) =>
            (storeId == null || receipt.storeId == storeId) &&
            stores.ownsStore(receipt.storeId, userId),
      )
      .toList()
      .reversed
      .toList();
}
