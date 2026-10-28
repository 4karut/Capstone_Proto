import 'package:flutter/material.dart';

import 'demo_auth_store.dart';
import 'prepaid_store.dart';
import 'prepaid_usage_store.dart';
import 'store_application_history_screen.dart';
import 'theme.dart';
import 'donation_store.dart';

class UsageReceiptCard extends StatelessWidget {
  const UsageReceiptCard({
    required this.auth,
    required this.receipt,
    this.showThanks = false,
    this.onCancel,
    super.key,
  });
  final DemoAuthStore auth;
  final PrepaidUsageReceipt receipt;
  final bool showThanks;
  final VoidCallback? onCancel;
  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey('usage-receipt-${receipt.id}'),
    padding: const EdgeInsets.all(18),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      border: Border.all(color: HantuckColors.border),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          receipt.cancelled ? '선결제 사용 취소' : '선결제 사용 완료',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: receipt.cancelled
                ? const Color(0xFFB64540)
                : HantuckColors.orange,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          formatWon(receipt.amount),
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        Text(
          auth.stores.store(receipt.storeId).name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          '${auth.groups.group(receipt.groupId).name} · ${receipt.userName}',
          style: const TextStyle(fontSize: 12, height: 1.8),
        ),
        Text(
          '사용 후 해당 선결제 잔액 ${formatWon(receipt.remainingAmount)}',
          style: const TextStyle(
            fontSize: 11,
            height: 1.8,
            color: HantuckColors.muted,
          ),
        ),
        Text(
          '${formatApplicationTime(receipt.createdAt)} (한국 시간)',
          style: const TextStyle(
            fontSize: 10,
            height: 1.8,
            color: HantuckColors.muted,
          ),
        ),
        if (receipt.cancellation case final cancellation?) ...[
          const SizedBox(height: 16),
          Container(
            key: ValueKey('usage-cancellation-${receipt.id}'),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '복구 금액 ${formatWon(receipt.amount)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB64540),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '취소 후 해당 선결제 잔액 ${formatWon(cancellation.remainingAmount)}',
                  style: const TextStyle(fontSize: 11, height: 1.8),
                ),
                Text(
                  '원래 사용 기한 ${formatOfferDate(cancellation.expiresOn)}까지',
                  style: const TextStyle(fontSize: 11, height: 1.8),
                ),
                if (cancellation.expiresOn.isBefore(
                  seoulCalendarDate(auth.groups.currentTime),
                ))
                  const Text(
                    '기한이 종료되어 복구된 잔액을 사용할 수 없어요.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.8,
                      color: Color(0xFFB64540),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  '취소 사유: ${cancellation.reason.isEmpty ? '입력하지 않았어요.' : cancellation.reason}',
                  style: const TextStyle(fontSize: 12, height: 1.8),
                ),
                const SizedBox(height: 8),
                Text(
                  '취소 ${formatApplicationTime(cancellation.createdAt)} (한국 시간)',
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.8,
                    color: HantuckColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (showThanks && receipt.thanks != null) ...[
          const SizedBox(height: 20),
          const Divider(color: HantuckColors.border),
          const SizedBox(height: 12),
          const Text(
            '후원 감사 메시지',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (receipt.thanks!.text.isNotEmpty)
            Text(
              receipt.thanks!.text,
              key: ValueKey('received-thanks-text-${receipt.id}'),
              style: const TextStyle(fontSize: 13, height: 1.9),
            ),
          if (receipt.thanks!.photo != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                receipt.thanks!.photo!.bytes,
                key: ValueKey('received-thanks-photo-${receipt.id}'),
                fit: BoxFit.contain,
                semanticLabel: '이용자가 첨부한 감사 사진',
                errorBuilder: (_, _, _) => const Text('사진을 표시할 수 없어요.'),
              ),
            ),
          ],
          const SizedBox(height: 9),
          Text(
            '메시지 도착 ${formatApplicationTime(receipt.thanks!.createdAt)}',
            style: const TextStyle(fontSize: 10, color: HantuckColors.muted),
          ),
        ],
        if (onCancel != null && !receipt.cancelled) ...[
          const SizedBox(height: 18),
          OutlinedButton.icon(
            key: ValueKey('usage-reverse-${receipt.id}'),
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB64540),
              minimumSize: const Size.fromHeight(50),
            ),
            icon: const Icon(Icons.undo_rounded, size: 20),
            label: const Text('결제 취소'),
          ),
        ],
      ],
    ),
  );
}
