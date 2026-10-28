import 'package:flutter/material.dart';

import 'prepaid_store.dart';
import 'theme.dart';

class PrepaidStoreCard extends StatelessWidget {
  const PrepaidStoreCard({
    required this.summary,
    this.now,
    this.onTap,
    super.key,
  });
  final PrepaidStoreSummary summary;
  final DateTime? now;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final firstToExpire = summary.offers.first;
    final days = firstToExpire.daysRemaining(at: now);
    final multiple = summary.offers.length > 1;
    return Padding(
      key: ValueKey('prepaid-store-${summary.storeId}'),
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: HantuckColors.border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: HantuckColors.orangeSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.storefront_outlined,
                        size: 26,
                        color: HantuckColors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            summary.storeName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '그룹 전용 선결제 · ${summary.offers.length}건',
                            style: const TextStyle(
                              fontSize: 11,
                              color: HantuckColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onTap != null)
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: HantuckColors.muted,
                        size: 22,
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _Amount(
                        label: '사용한 선결제',
                        value: formatWon(summary.usedAmount),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Amount(
                        label: '남은 선결제',
                        value: formatWon(summary.remainingAmount),
                        emphasized: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: summary.usageRatio,
                    minHeight: 7,
                    backgroundColor: HantuckColors.orangeSoft,
                    color: HantuckColors.orange,
                    semanticsLabel: '선결제 사용률',
                    semanticsValue: '${(summary.usageRatio * 100).round()}%',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '총 ${formatWon(summary.totalAmount)} 중 ${(summary.usageRatio * 100).round()}% 사용',
                  style: const TextStyle(
                    fontSize: 10,
                    color: HantuckColors.muted,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: HantuckColors.muted,
                    ),
                    Text(
                      '${multiple ? '가장 빠른 사용 기한' : '사용 기한'} ${formatOfferDate(firstToExpire.expiresOn)}까지',
                      style: const TextStyle(
                        fontSize: 11,
                        color: HantuckColors.ink,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: HantuckColors.orangeSoft,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        days < 0
                            ? '기간 종료'
                            : days == 0
                            ? '오늘까지'
                            : '$days일 남음',
                        key: ValueKey('prepaid-period-${summary.storeId}'),
                        style: const TextStyle(
                          fontSize: 10,
                          color: HantuckColors.orange,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  multiple
                      ? '가게를 눌러 기한별 남은 선결제를 확인해 주세요.'
                      : '이용 기간 ${formatOfferDate(firstToExpire.startsOn)} ~ ${formatOfferDate(firstToExpire.expiresOn)}',
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.6,
                    color: HantuckColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({
    required this.label,
    required this.value,
    this.emphasized = false,
  });
  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: HantuckColors.muted),
      ),
      const SizedBox(height: 7),
      Text(
        value,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: emphasized ? HantuckColors.orange : HantuckColors.ink,
          letterSpacing: -.5,
        ),
      ),
    ],
  );
}
