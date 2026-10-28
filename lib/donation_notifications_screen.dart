import 'package:flutter/material.dart';

import 'demo_auth_store.dart';
import 'donation_widgets.dart';
import 'group_widgets.dart';
import 'store_widgets.dart';
import 'theme.dart';

class DonationNotificationsScreen extends StatelessWidget {
  const DonationNotificationsScreen({
    required this.auth,
    required this.account,
    this.forStore = false,
    this.storeId,
    super.key,
  });
  final DemoAuthStore auth;
  final DemoAccount account;
  final bool forStore;
  final String? storeId;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: auth.donations,
    builder: (context, _) {
      final received = forStore
          ? auth.donations.notificationsForStoreOwner(account.id)
          : auth.donations.notificationsForGroupOwner(account.id);
      final donations = received
          .where((donation) => storeId == null || donation.storeId == storeId)
          .toList();
      return AuthPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GroupPageHeader(
              title: forStore ? '가게 선결제 알림' : '그룹 후원 알림',
              backKey: 'donation-notifications-back',
            ),
            const SizedBox(height: 22),
            if (forStore &&
                storeId != null &&
                auth.stores.ownsStore(storeId!, account.id)) ...[
              Text(
                auth.stores.store(storeId!).name,
                style: const TextStyle(
                  fontSize: 13,
                  color: HantuckColors.orange,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              '도착한 후원 ${donations.length}건',
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 9),
            Text(
              forStore
                  ? '우리 가게에 도착한 그룹 선결제를 확인해요.'
                  : '우리 그룹에 도착한 따뜻한 마음을 확인해요.',
              style: const TextStyle(
                fontSize: 12,
                height: 1.7,
                color: HantuckColors.muted,
              ),
            ),
            const SizedBox(height: 24),
            if (donations.isEmpty)
              const DiscoveryEmptyState(
                key: ValueKey('donation-notifications-empty'),
                icon: Icons.notifications_none_rounded,
                title: '도착한 후원이 없어요',
                description: '후원이 완료되면 여기에 알려드려요.',
              ),
            ...donations.map(
              (donation) => Padding(
                key: ValueKey('donation-notification-${donation.id}'),
                padding: const EdgeInsets.only(bottom: 14),
                child: DonationReceipt(auth: auth, donation: donation),
              ),
            ),
          ],
        ),
      );
    },
  );
}
