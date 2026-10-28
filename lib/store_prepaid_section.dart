import 'package:flutter/material.dart';

import 'demo_auth_store.dart';
import 'prepaid_store.dart';
import 'prepaid_usage_screen.dart';
import 'theme.dart';

class StorePrepaidSection extends StatefulWidget {
  const StorePrepaidSection({
    required this.auth,
    required this.offers,
    required this.account,
    this.groupId,
    super.key,
  });
  final DemoAuthStore auth;
  final DemoAccount account;
  final List<PrepaidStoreOffer> offers;
  final String? groupId;

  @override
  State<StorePrepaidSection> createState() => _StorePrepaidSectionState();
}

class _StorePrepaidSectionState extends State<StorePrepaidSection> {
  String? _selected;

  void _use(PrepaidStoreOffer offer) {
    try {
      final request = widget.auth.usage.begin(
        offerId: offer.id,
        userId: widget.account.id,
        userName: widget.account.name,
      );
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => PrepaidQrScreen(
            auth: widget.auth,
            account: widget.account,
            requestId: request.id,
          ),
        ),
      );
    } on StateError catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.auth;
    final offers = widget.offers;
    final groupId = widget.groupId;
    final sorted = [...offers]
      ..sort((a, b) {
        final dateOrder = a.expiresOn.compareTo(b.expiresOn);
        return dateOrder != 0 ? dateOrder : a.id.compareTo(b.id);
      });
    final remaining = sorted.fold(
      0,
      (total, offer) => total + offer.remainingAmount,
    );
    return Container(
      key: const ValueKey('store-availability'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HantuckColors.orangeSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            sorted.isEmpty ? '현재 이용 가능한 선결제가 없어요' : '그룹 선결제로 이용 가능해요',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: HantuckColors.orange,
            ),
          ),
          if (groupId != null) ...[
            const SizedBox(height: 7),
            Text(
              '${auth.groups.group(groupId).name}의 선결제',
              style: const TextStyle(
                fontSize: 11,
                height: 1.6,
                color: HantuckColors.muted,
              ),
            ),
          ],
          if (sorted.isEmpty) ...[
            const SizedBox(height: 7),
            const Text(
              '가게 정보와 메뉴는 계속 확인할 수 있어요.',
              style: TextStyle(
                fontSize: 10,
                height: 1.6,
                color: HantuckColors.muted,
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            Text(
              '총 잔액 ${formatWon(remaining)}',
              key: const ValueKey('store-prepaid-total'),
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 9),
            Text(
              '기한별 선결제 ${sorted.length}건',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              '사용 기한이 빠른 순서로 보여드려요.',
              style: TextStyle(
                fontSize: 10,
                height: 1.6,
                color: HantuckColors.muted,
              ),
            ),
            const SizedBox(height: 14),
            for (var index = 0; index < sorted.length; index++)
              _OfferDetail(
                auth: auth,
                offer: sorted[index],
                number: index + 1,
                selected: _selected == sorted[index].id,
                onSelect: () => setState(
                  () => _selected = _selected == sorted[index].id
                      ? null
                      : sorted[index].id,
                ),
                onUse: () => _use(sorted[index]),
              ),
          ],
        ],
      ),
    );
  }
}

class _OfferDetail extends StatelessWidget {
  const _OfferDetail({
    required this.auth,
    required this.offer,
    required this.number,
    required this.selected,
    required this.onSelect,
    required this.onUse,
  });
  final DemoAuthStore auth;
  final PrepaidStoreOffer offer;
  final int number;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final days = offer.daysRemaining(at: auth.groups.currentTime);
    return Padding(
      key: ValueKey('store-prepaid-offer-${offer.id}'),
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? HantuckColors.orange : Colors.transparent,
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onSelect,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${auth.groups.group(offer.groupId).name} · 선결제 $number',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 19,
                      color: selected
                          ? HantuckColors.orange
                          : HantuckColors.muted,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '남은 선결제',
                  style: TextStyle(fontSize: 10, color: HantuckColors.muted),
                ),
                const SizedBox(height: 4),
                Text(
                  formatWon(offer.remainingAmount),
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: HantuckColors.orange,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '총 ${formatWon(offer.totalAmount)} · 사용 ${formatWon(offer.usedAmount)}',
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.6,
                    color: HantuckColors.muted,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '사용 기한 ${formatOfferDate(offer.expiresOn)}까지',
                      style: const TextStyle(fontSize: 11, height: 1.7),
                    ),
                    Text(
                      days == 0 ? '오늘까지' : '$days일 남음',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: HantuckColors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  '이용 기간 ${formatOfferDate(offer.startsOn)} ~ ${formatOfferDate(offer.expiresOn)}',
                  style: const TextStyle(
                    fontSize: 9,
                    height: 1.7,
                    color: HantuckColors.muted,
                  ),
                ),
                if (selected) ...[
                  const SizedBox(height: 16),
                  FilledButton(
                    key: ValueKey('prepaid-use-${offer.id}'),
                    onPressed: onUse,
                    child: const Text('선결제 이용'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
