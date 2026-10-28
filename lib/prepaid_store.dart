/// A group's prepaid allocation at a store. Amounts are whole KRW.
class PrepaidStoreOffer {
  PrepaidStoreOffer({
    required this.id,
    required this.groupId,
    required this.storeName,
    required this.totalAmount,
    required this.usedAmount,
    required this.startsOn,
    required this.expiresOn,
    String? storeId,
    this.donorId,
    this.donorName,
  }) : storeId = storeId ?? id,
       assert(totalAmount > 0),
       assert(usedAmount >= 0 && usedAmount <= totalAmount),
       assert(!expiresOn.isBefore(startsOn));

  final String id;
  final String storeId;
  final String groupId;
  final String storeName;
  final int totalAmount;
  final int usedAmount;
  final DateTime startsOn;
  final DateTime expiresOn;
  final String? donorId;
  final String? donorName;

  PrepaidStoreOffer withUsedAmount(int amount) => PrepaidStoreOffer(
    id: id,
    storeId: storeId,
    groupId: groupId,
    storeName: storeName,
    totalAmount: totalAmount,
    usedAmount: amount,
    startsOn: startsOn,
    expiresOn: expiresOn,
    donorId: donorId,
    donorName: donorName,
  );

  int get remainingAmount => totalAmount - usedAmount;
  double get usageRatio => usedAmount / totalAmount;

  static DateTime _date(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);

  static DateTime _todayInSeoul(DateTime? instant) {
    final seoul = (instant ?? DateTime.now()).toUtc().add(
      const Duration(hours: 9),
    );
    return _date(seoul);
  }

  int daysRemaining({DateTime? at}) =>
      _date(expiresOn).difference(_todayInSeoul(at)).inDays;

  bool isAvailable({DateTime? at}) {
    final today = _todayInSeoul(at);
    return remainingAmount > 0 &&
        !today.isBefore(_date(startsOn)) &&
        !today.isAfter(_date(expiresOn));
  }
}

/// Display summary only. Original allocations keep their own balances and dates.
class PrepaidStoreSummary {
  PrepaidStoreSummary._(this.offers);

  factory PrepaidStoreSummary(List<PrepaidStoreOffer> offers) {
    if (offers.isEmpty ||
        offers.any(
          (offer) =>
              offer.groupId != offers.first.groupId ||
              offer.storeId != offers.first.storeId,
        )) {
      throw ArgumentError('같은 그룹과 가게의 선결제만 묶을 수 있어요.');
    }
    final sorted = [...offers]
      ..sort((a, b) {
        final dateOrder = a.expiresOn.compareTo(b.expiresOn);
        return dateOrder != 0 ? dateOrder : a.id.compareTo(b.id);
      });
    return PrepaidStoreSummary._(List.unmodifiable(sorted));
  }

  final List<PrepaidStoreOffer> offers;
  String get storeId => offers.first.storeId;
  String get storeName => offers.first.storeName;
  String get groupId => offers.first.groupId;
  int get totalAmount =>
      offers.fold(0, (total, offer) => total + offer.totalAmount);
  int get usedAmount =>
      offers.fold(0, (total, offer) => total + offer.usedAmount);
  int get remainingAmount =>
      offers.fold(0, (total, offer) => total + offer.remainingAmount);
  double get usageRatio => usedAmount / totalAmount;
}

/// Call with allocations already filtered for membership, balance, and period.
List<PrepaidStoreSummary> summarizePrepaidStores(
  Iterable<PrepaidStoreOffer> offers,
) {
  final grouped = <(String, String), List<PrepaidStoreOffer>>{};
  for (final offer in offers) {
    grouped.putIfAbsent((offer.groupId, offer.storeId), () => []).add(offer);
  }
  return grouped.values.map(PrepaidStoreSummary.new).toList();
}

String formatWon(int amount) =>
    '${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}원';

String formatOfferDate(DateTime date) =>
    '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
