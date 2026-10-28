import 'package:flutter/material.dart';

import 'demo_auth_store.dart';
import 'group_widgets.dart';
import 'prepaid_store.dart';
import 'store_widgets.dart';
import 'theme.dart';

class StoreOwnerPrepaidScreen extends StatelessWidget {
  const StoreOwnerPrepaidScreen({
    required this.auth,
    required this.account,
    required this.storeId,
    super.key,
  });
  final DemoAuthStore auth;
  final DemoAccount account;
  final String storeId;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([auth.stores, auth.groups]),
    builder: (context, _) {
      if (!auth.stores.ownsStore(storeId, account.id)) {
        return const AuthPage(
          child: Text(
            '본인 가게의 선결제만 확인할 수 있어요.',
            key: ValueKey('store-prepaid-denied'),
          ),
        );
      }
      final offers = auth.stores.managedPrepaidOffers(
        storeId: storeId,
        ownerId: account.id,
        groups: auth.groups,
      );
      final byGroup = <String, List<PrepaidStoreOffer>>{};
      for (final offer in offers) {
        byGroup.putIfAbsent(offer.groupId, () => []).add(offer);
      }
      return AuthPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GroupPageHeader(
              title: '선결제 관리',
              backKey: 'store-owner-prepaid-back',
            ),
            const SizedBox(height: 22),
            Text(
              auth.stores.store(storeId).name,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const Text(
              '그룹별 선결제와 남은 금액을 확인해요.',
              style: TextStyle(
                fontSize: 12,
                height: 1.7,
                color: HantuckColors.muted,
              ),
            ),
            const SizedBox(height: 23),
            if (offers.isEmpty)
              const DiscoveryEmptyState(
                key: ValueKey('store-owner-prepaid-empty'),
                icon: Icons.receipt_long_outlined,
                title: '선결제 내역이 없어요',
                description: '이 가게에 선결제가 도착하면 그룹별로 보여드려요.',
              ),
            ...byGroup.entries.map((entry) {
              final total = entry.value.fold(
                0,
                (sum, offer) => sum + offer.totalAmount,
              );
              final remaining = entry.value.fold(
                0,
                (sum, offer) => sum + offer.remainingAmount,
              );
              final available = entry.value
                  .where(
                    (offer) => offer.isAvailable(at: auth.groups.currentTime),
                  )
                  .fold(0, (sum, offer) => sum + offer.remainingAmount);
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Material(
                  color: Colors.white,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: HantuckColors.border),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    key: ValueKey('managed-prepaid-group-${entry.key}'),
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => StoreOwnerGroupPrepaidScreen(
                          auth: auth,
                          account: account,
                          storeId: storeId,
                          groupId: entry.key,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  auth.groups.group(entry.key).name,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 22,
                                color: HantuckColors.muted,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '총 선결제 ${formatWon(total)}',
                            style: const TextStyle(fontSize: 12, height: 1.8),
                          ),
                          Text(
                            '남은 선결제 ${formatWon(remaining)}',
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.8,
                              fontWeight: FontWeight.w800,
                              color: HantuckColors.orange,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${entry.value.length}건 · 현재 사용 가능 ${formatWon(available)}',
                            style: const TextStyle(
                              fontSize: 10,
                              height: 1.7,
                              color: HantuckColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      );
    },
  );
}

class StoreOwnerGroupPrepaidScreen extends StatelessWidget {
  const StoreOwnerGroupPrepaidScreen({
    required this.auth,
    required this.account,
    required this.storeId,
    required this.groupId,
    super.key,
  });
  final DemoAuthStore auth;
  final DemoAccount account;
  final String storeId;
  final String groupId;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([auth.stores, auth.groups]),
    builder: (context, _) {
      if (!auth.stores.ownsStore(storeId, account.id)) {
        return const AuthPage(
          child: Text(
            '본인 가게의 선결제만 확인할 수 있어요.',
            key: ValueKey('store-prepaid-denied'),
          ),
        );
      }
      final offers =
          auth.stores
              .managedPrepaidOffers(
                storeId: storeId,
                ownerId: account.id,
                groups: auth.groups,
              )
              .where((offer) => offer.groupId == groupId)
              .toList()
            ..sort((a, b) => a.expiresOn.compareTo(b.expiresOn));
      return AuthPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GroupPageHeader(
              title: '그룹별 선결제',
              backKey: 'store-owner-group-prepaid-back',
            ),
            const SizedBox(height: 22),
            Text(
              auth.groups.group(groupId).name,
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              auth.stores.store(storeId).name,
              style: const TextStyle(fontSize: 12, color: HantuckColors.muted),
            ),
            const SizedBox(height: 22),
            ...offers.indexed.map((entry) {
              final offer = entry.$2;
              final days = offer.daysRemaining(at: auth.groups.currentTime);
              final status = offer.remainingAmount == 0
                  ? '전액 사용'
                  : days < 0
                  ? '기간 종료'
                  : offer.isAvailable(at: auth.groups.currentTime)
                  ? '사용 가능'
                  : '사용 전';
              return Container(
                key: ValueKey('managed-prepaid-offer-${offer.id}'),
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  border: Border.all(color: HantuckColors.border),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '선결제 ${entry.$1 + 1} · $status',
                      style: const TextStyle(
                        fontSize: 12,
                        color: HantuckColors.orange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      '남은 선결제',
                      style: TextStyle(
                        fontSize: 11,
                        color: HantuckColors.muted,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      formatWon(offer.remainingAmount),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '총 ${formatWon(offer.totalAmount)} · 사용 ${formatWon(offer.usedAmount)}',
                      style: const TextStyle(fontSize: 12, height: 1.7),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: offer.usageRatio,
                        minHeight: 7,
                        color: HantuckColors.orange,
                        backgroundColor: HantuckColors.orangeSoft,
                        semanticsLabel: '선결제 사용률',
                        semanticsValue: '${(offer.usageRatio * 100).round()}%',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '사용 기한 ${formatOfferDate(offer.expiresOn)}까지',
                      style: const TextStyle(fontSize: 12, height: 1.7),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '이용 기간 ${formatOfferDate(offer.startsOn)} ~ ${formatOfferDate(offer.expiresOn)}',
                      style: const TextStyle(
                        fontSize: 10,
                        height: 1.7,
                        color: HantuckColors.muted,
                      ),
                    ),
                    if (days < 0 && offer.remainingAmount > 0) ...[
                      const SizedBox(height: 8),
                      const Text(
                        '기간이 종료된 잔액은 사용할 수 없어요.',
                        style: TextStyle(
                          fontSize: 10,
                          color: HantuckColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      );
    },
  );
}
