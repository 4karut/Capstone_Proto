import 'package:flutter/material.dart';

import 'demo_auth_store.dart';
import 'donation_store.dart';
import 'group_store.dart';
import 'group_widgets.dart';
import 'prepaid_store.dart';
import 'theme.dart';

class DonationGroupSummary extends StatelessWidget {
  const DonationGroupSummary({required this.group, super.key});
  final DemoGroup group;
  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('donation-target-group'),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: HantuckColors.orangeSoft,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '후원 대상 그룹',
                style: TextStyle(
                  fontSize: 10,
                  color: HantuckColors.orange,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                group.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${group.category} · ${group.code}',
                style: const TextStyle(
                  fontSize: 10,
                  color: HantuckColors.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GroupThumbnail(group: group, size: 58),
      ],
    ),
  );
}

class DonationReceipt extends StatelessWidget {
  const DonationReceipt({
    required this.auth,
    required this.donation,
    super.key,
  });
  final DemoAuthStore auth;
  final DemoDonation donation;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      border: Border.all(color: HantuckColors.border),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          donation.label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: HantuckColors.orange,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          formatWon(donation.amount),
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 18),
        _Line(label: '후원 그룹', value: auth.groups.group(donation.groupId).name),
        _Line(label: '후원자', value: '${donation.donorName}님'),
        if (donation.type == DonationType.prepaid) ...[
          _Line(
            label: '선결제 가게',
            value: auth.stores.store(donation.storeId!).name,
          ),
          _Line(
            label: '사용 기한',
            value: '${formatOfferDate(donation.expiresOn!)}까지',
          ),
        ],
        _Line(
          label: '결제일',
          value: formatOfferDate(seoulCalendarDate(donation.createdAt)),
        ),
      ],
    ),
  );
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: HantuckColors.muted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              height: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
