import 'package:flutter/material.dart';

import 'demo_auth_store.dart';
import 'donation_store.dart';
import 'donation_widgets.dart';
import 'main_navigation.dart';
import 'theme.dart';

class DonationCompleteScreen extends StatelessWidget {
  const DonationCompleteScreen({
    required this.auth,
    required this.donation,
    super.key,
  });
  final DemoAuthStore auth;
  final DemoDonation donation;
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: AuthPage(
      child: Column(
        key: const ValueKey('donation-complete'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 22),
          const Center(
            child: Icon(
              Icons.check_circle_rounded,
              color: HantuckColors.orange,
              size: 78,
            ),
          ),
          const SizedBox(height: 23),
          const Text(
            '결제가 완료됐습니다',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 9),
          const Text(
            '따뜻한 마음을 나눠 주셔서 감사해요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.7,
              color: HantuckColors.muted,
            ),
          ),
          const SizedBox(height: 28),
          DonationReceipt(auth: auth, donation: donation),
          const SizedBox(height: 22),
          Text(
            donation.type == DonationType.prepaid
                ? '그룹장과 가게의 알림함에\n선결제 후원 내역을 남겼어요.'
                : '그룹장의 알림함에\n금액 후원 내역을 남겼어요.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.8,
              color: HantuckColors.muted,
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            '프로토타입 결제 완료 · 실제 청구 없음',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: HantuckColors.muted),
          ),
          const SizedBox(height: 26),
          FilledButton(
            key: const ValueKey('donation-complete-confirm'),
            onPressed: () {
              final navigation = MainNavigation.maybeOf(context);
              if (navigation != null) {
                navigation.select(0);
              } else {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    ),
  );
}
