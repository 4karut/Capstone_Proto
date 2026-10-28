import 'package:flutter/material.dart';

import 'demo_auth_store.dart';
import 'donation_form_screen.dart';
import 'donation_store.dart';
import 'donation_widgets.dart';
import 'group_store.dart';
import 'group_widgets.dart';
import 'theme.dart';

class DonationChoiceScreen extends StatelessWidget {
  const DonationChoiceScreen({
    required this.auth,
    required this.account,
    required this.group,
    super.key,
  });
  final DemoAuthStore auth;
  final DemoAccount account;
  final DemoGroup group;

  @override
  Widget build(BuildContext context) => AuthPage(
    child: Column(
      key: const ValueKey('donation-choice'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GroupPageHeader(title: '후원하기', backKey: 'donation-choice-back'),
        const SizedBox(height: 22),
        DonationGroupSummary(group: group),
        const SizedBox(height: 30),
        const Text(
          '어떤 마음을 전할까요?',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 9),
        const Text(
          '그룹을 응원하는 후원 방식을 선택해 주세요.',
          style: TextStyle(
            fontSize: 12,
            height: 1.7,
            color: HantuckColors.muted,
          ),
        ),
        const SizedBox(height: 24),
        for (final type in DonationType.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Material(
              color: Colors.white,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: HantuckColors.border),
              ),
              child: InkWell(
                key: ValueKey(
                  type == DonationType.money
                      ? 'donation-choose-money'
                      : 'donation-choose-prepaid',
                ),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => DonationFormScreen(
                      auth: auth,
                      account: account,
                      group: group,
                      type: type,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: HantuckColors.orangeSoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          type == DonationType.money
                              ? Icons.volunteer_activism_outlined
                              : Icons.storefront_outlined,
                          color: HantuckColors.orange,
                          size: 27,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type == DonationType.money ? '금액 후원' : '선결제 후원',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              type == DonationType.money
                                  ? '그룹에 후원금을 전해요.'
                                  : '가게에 미리 결제해\n그룹원들의 한 끼를 응원해요.',
                              style: const TextStyle(
                                fontSize: 11,
                                height: 1.8,
                                color: HantuckColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: HantuckColors.muted,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 14),
        const Text(
          '실제 결제 없이 후원 과정을 체험하는 프로토타입이에요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            height: 1.7,
            color: HantuckColors.muted,
          ),
        ),
      ],
    ),
  );
}
