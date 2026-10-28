import 'server_gateway.dart';

import 'package:flutter/foundation.dart';

import 'group_store.dart';
import 'store_catalog.dart';

enum DonationType { money, prepaid }

DateTime seoulCalendarDate(DateTime instant) {
  final seoul = instant.toUtc().add(const Duration(hours: 9));
  return DateTime(seoul.year, seoul.month, seoul.day);
}

int? parseDonationAmount(String value) {
  final input = value.trim();
  if (!RegExp(r'^[0-9]+$').hasMatch(input)) return null;
  final amount = int.tryParse(input);
  // Keep whole-won values exact on Dart's web runtime, too.
  return amount != null && amount > 0 && amount <= 9007199254740991
      ? amount
      : null;
}

DateTime? parseDonationDeadline(String value) {
  final input = value.trim();
  if (!RegExp(r'^(\d{8}|\d{4}[.-]\d{2}[.-]\d{2})$').hasMatch(input)) {
    return null;
  }
  final digits = input.replaceAll(RegExp(r'\D'), '');
  final year = int.parse(digits.substring(0, 4));
  final month = int.parse(digits.substring(4, 6));
  final day = int.parse(digits.substring(6, 8));
  final date = DateTime(year, month, day);
  return year > 0 && date.year == year && date.month == month && date.day == day
      ? date
      : null;
}

class DemoDonation {
  const DemoDonation({
    required this.id,
    required this.checkoutId,
    required this.type,
    required this.groupId,
    required this.donorId,
    required this.donorName,
    required this.amount,
    required this.createdAt,
    this.storeId,
    this.expiresOn,
  });
  final String id;
  final String checkoutId;
  final DonationType type;
  final String groupId;
  final String donorId;
  final String donorName;
  final int amount;
  final DateTime createdAt;
  final String? storeId;
  final DateTime? expiresOn;
  String get label => type == DonationType.money ? '금액 후원' : '선결제 후원';
}

/// Simulated payments and recipient-specific in-app notifications. No real charge.
class DemoDonationStore extends ChangeNotifier {
  ServerGateway? gateway;
  DemoDonationStore({required this.groups, required this.stores});
  final DemoGroupStore groups;
  final DemoStoreCatalog stores;
  final List<DemoDonation> _donations = [];
  int _checkoutSequence = 0;

  static String _key(String id) => id.trim().toLowerCase();
  String beginCheckout() => gateway == null
      ? 'checkout-${++_checkoutSequence}'
      : ServerGateway.commandId();

  DemoDonation complete({
    required String checkoutId,
    required DonationType type,
    required String groupId,
    required String donorId,
    required String donorName,
    required int amount,
    String? storeId,
    DateTime? expiresOn,
  }) {
    final deadline = expiresOn == null
        ? null
        : DateTime(expiresOn.year, expiresOn.month, expiresOn.day);
    for (final existing in _donations) {
      if (existing.checkoutId != checkoutId) continue;
      if (existing.type != type ||
          existing.groupId != groupId ||
          _key(existing.donorId) != _key(donorId) ||
          existing.amount != amount ||
          existing.storeId != storeId ||
          existing.expiresOn != deadline) {
        throw StateError('이미 완료한 결제의 정보가 달라요.');
      }
      return existing;
    }
    if (checkoutId.isEmpty ||
        donorId.trim().isEmpty ||
        parseDonationAmount('$amount') == null) {
      throw StateError('후원 금액을 1원 이상의 정수로 입력해 주세요.');
    }
    groups.group(groupId);
    if (type == DonationType.prepaid) {
      if (storeId == null ||
          deadline == null ||
          deadline.isBefore(seoulCalendarDate(groups.currentTime))) {
        throw StateError('가게와 오늘 이후의 올바른 사용 기한을 입력해 주세요.');
      }
      stores.store(storeId);
    } else if (storeId != null || deadline != null) {
      throw StateError('금액 후원에는 가게와 사용 기한이 필요하지 않아요.');
    }
    final donation = DemoDonation(
      id: 'donation-${_donations.length + 1}',
      checkoutId: checkoutId,
      type: type,
      groupId: groupId,
      donorId: donorId.trim(),
      donorName: donorName.trim(),
      amount: amount,
      createdAt: groups.currentTime,
      storeId: storeId,
      expiresOn: deadline,
    );
    if (type == DonationType.prepaid) {
      groups.recordPrepaidDonation(
        id: 'prepaid-${donation.id}',
        groupId: groupId,
        storeId: storeId!,
        storeName: stores.store(storeId).name,
        amount: amount,
        expiresOn: deadline!,
        donorId: donation.donorId,
        donorName: donation.donorName,
      );
    }
    _donations.add(donation);
    notifyListeners();
    return donation;
  }

  List<DemoDonation> notificationsForGroupOwner(String userId) => _donations
      .where((donation) => groups.isOwner(donation.groupId, userId))
      .toList()
      .reversed
      .toList();

  List<DemoDonation> notificationsForStoreOwner(String userId) => _donations
      .where(
        (donation) =>
            donation.type == DonationType.prepaid &&
            stores.ownsStore(donation.storeId!, userId),
      )
      .toList()
      .reversed
      .toList();

  void importSnapshot(Map<String, dynamic> s) {
    _donations.clear();
    for (final d in s['donations']) {
      _donations.add(
        DemoDonation(
          id: d['id'],
          checkoutId: d['checkoutId'],
          type: DonationType.values.byName(d['type']),
          groupId: d['groupId'],
          donorId: d['donorId'],
          donorName: d['donorName'],
          amount: d['amount'],
          createdAt: DateTime.parse(d['createdAt']).toLocal(),
          storeId: d['storeId'],
          expiresOn: d['expiresOn'] == null
              ? null
              : DateTime.parse(d['expiresOn']),
        ),
      );
    }
    notifyListeners();
  }

  Future<DemoDonation> completeRemote({
    required String checkoutId,
    required DonationType type,
    required String groupId,
    required String donorId,
    required String donorName,
    required int amount,
    String? storeId,
    DateTime? expiresOn,
  }) async {
    if (gateway == null) {
      return complete(
        checkoutId: checkoutId,
        type: type,
        groupId: groupId,
        donorId: donorId,
        donorName: donorName,
        amount: amount,
        storeId: storeId,
        expiresOn: expiresOn,
      );
    }
    final r = await gateway!.command('donation.complete', {
      'checkoutId': checkoutId,
      'type': type.name,
      'groupId': groupId,
      'amount': amount,
      'storeId': storeId,
      'expiresOn': expiresOn == null
          ? null
          : '${expiresOn.year.toString().padLeft(4, '0')}-${expiresOn.month.toString().padLeft(2, '0')}-${expiresOn.day.toString().padLeft(2, '0')}',
    });
    return _donations.firstWhere((d) => d.id == r['id']);
  }
}
