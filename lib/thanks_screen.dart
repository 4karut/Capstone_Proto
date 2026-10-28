import 'package:flutter/material.dart';

import 'demo_auth_store.dart';
import 'group_widgets.dart';
import 'main_navigation.dart';
import 'prepaid_usage_store.dart';
import 'store_widgets.dart';
import 'theme.dart';
import 'usage_receipt_widgets.dart';

void finishUsage(BuildContext context) {
  final main = MainNavigation.maybeOf(context);
  if (main != null) {
    main.select(0);
  } else {
    Navigator.of(context).maybePop();
  }
}

class ThanksComposeScreen extends StatefulWidget {
  const ThanksComposeScreen({
    required this.auth,
    required this.account,
    required this.receiptId,
    super.key,
  });
  final DemoAuthStore auth;
  final DemoAccount account;
  final String receiptId;
  @override
  State<ThanksComposeScreen> createState() => _ThanksComposeScreenState();
}

class _ThanksComposeScreenState extends State<ThanksComposeScreen> {
  final _message = TextEditingController();
  UsagePhoto? _photo;
  bool _picking = false;
  bool _sending = false;
  String? _error;
  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    if (_picking || _sending) return;
    setState(() => _picking = true);
    try {
      final picked = await widget.auth.pickThanksPhoto();
      if (!mounted) return;
      if (picked != null) {
        setState(() {
          _photo = picked;
          _error = null;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error is StateError
            ? error.message
            : '사진을 선택하지 못했어요. 다시 선택해 주세요.',
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _send() async {
    if (_sending || _picking) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.auth.usage.sendThanksRemote(
        receiptId: widget.receiptId,
        userId: widget.account.id,
        message: _message.text,
        photo: _photo,
      );
      if (!mounted) return;
      FocusManager.instance.primaryFocus?.unfocus();
    } on StateError catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.auth.usage,
    builder: (context, _) => _content(context),
  );

  Widget _content(BuildContext context) {
    PrepaidUsageReceipt receipt;
    try {
      receipt = widget.auth.usage.receiptForUser(
        widget.receiptId,
        widget.account.id,
      );
    } on StateError {
      return const AuthPage(child: Text('본인의 사용 내역만 확인할 수 있어요.'));
    }
    final sent = receipt.thanks != null;
    final cancelled = receipt.cancelled;
    return AuthPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GroupPageHeader(title: '후원 감사 메시지', backKey: 'thanks-back'),
          const SizedBox(height: 24),
          Icon(
            cancelled
                ? Icons.undo_rounded
                : sent
                ? Icons.mark_email_read_outlined
                : Icons.check_circle_rounded,
            size: 62,
            color: HantuckColors.orange,
          ),
          const SizedBox(height: 18),
          Text(
            cancelled
                ? '취소된 결제 내역이에요'
                : sent
                ? '감사 메시지를 보냈어요'
                : '선결제를 사용했어요',
            key: ValueKey(
              cancelled
                  ? 'thanks-payment-cancelled'
                  : sent
                  ? 'thanks-sent'
                  : 'usage-complete',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          UsageReceiptCard(
            auth: widget.auth,
            receipt: receipt,
            showThanks: sent,
          ),
          if (cancelled) ...[
            const Text(
              '이 결제에는 새 감사 메시지를 보낼 수 없어요. 이미 보낸 메시지와 사진은 취소 표시와 함께 보존됩니다.',
              style: TextStyle(
                fontSize: 12,
                height: 1.8,
                color: HantuckColors.muted,
              ),
            ),
            const SizedBox(height: 18),
          ],
          if (sent || cancelled)
            FilledButton(
              key: const ValueKey('thanks-done'),
              onPressed: () => finishUsage(context),
              child: const Text('확인'),
            )
          else ...[
            const Text(
              '후원자에게 고마운 마음을 전해요. 메시지와 사진은 선택이며 건너뛸 수 있어요.',
              style: TextStyle(
                fontSize: 12,
                height: 1.8,
                color: HantuckColors.muted,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              key: const ValueKey('thanks-message'),
              controller: _message,
              maxLength: 500,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: '후원 감사 메시지 (선택)',
                hintText: '따뜻한 한 끼를 나눠 주셔서 감사합니다.',
              ),
              style: const TextStyle(fontSize: 14, height: 1.8),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              key: const ValueKey('thanks-photo-pick'),
              onPressed: _picking || _sending ? null : _pick,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(
                _picking
                    ? '사진을 불러오는 중이에요'
                    : _photo == null
                    ? '사진 첨부 (선택)'
                    : '사진 바꾸기',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'JPG·PNG·WebP 사진 1장 · 최대 5MB',
              style: TextStyle(fontSize: 10, color: HantuckColors.muted),
            ),
            if (_photo != null) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(
                  _photo!.bytes,
                  key: const ValueKey('thanks-photo-preview'),
                  height: 190,
                  fit: BoxFit.contain,
                  semanticLabel: '첨부할 감사 사진',
                ),
              ),
              TextButton(
                key: const ValueKey('thanks-photo-remove'),
                onPressed: _sending
                    ? null
                    : () => setState(() => _photo = null),
                child: const Text('첨부 사진 삭제'),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  _error!,
                  key: const ValueKey('thanks-error'),
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.8,
                    color: Color(0xFFBE3A35),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              key: const ValueKey('thanks-send'),
              onPressed: _sending || _picking ? null : _send,
              child: const Text('후원 메시지 보내기'),
            ),
            const SizedBox(height: 12),
            TextButton(
              key: const ValueKey('thanks-skip'),
              onPressed: _picking || _sending
                  ? null
                  : () => finishUsage(context),
              child: const Text('건너뛰고 홈으로'),
            ),
          ],
        ],
      ),
    );
  }
}

class ReceivedThanksScreen extends StatelessWidget {
  const ReceivedThanksScreen({
    required this.auth,
    required this.account,
    super.key,
  });
  final DemoAuthStore auth;
  final DemoAccount account;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: auth.usage,
    builder: (context, _) {
      final receipts = auth.usage.thanksForDonor(account.id);
      return AuthPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GroupPageHeader(
              title: '받은 감사 메시지',
              backKey: 'received-thanks-back',
            ),
            const SizedBox(height: 24),
            Text(
              '도착한 감사 ${receipts.length}건',
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            const Text(
              '내가 후원한 선결제를 이용한 분들의 마음이에요.',
              style: TextStyle(
                fontSize: 12,
                height: 1.8,
                color: HantuckColors.muted,
              ),
            ),
            const SizedBox(height: 24),
            if (receipts.isEmpty)
              const DiscoveryEmptyState(
                key: ValueKey('received-thanks-empty'),
                icon: Icons.mark_email_read_outlined,
                title: '아직 받은 감사 메시지가 없어요',
                description: '이용자가 메시지나 사진을 보내면 여기에서 볼 수 있어요.',
              ),
            for (final receipt in receipts)
              UsageReceiptCard(auth: auth, receipt: receipt, showThanks: true),
          ],
        ),
      );
    },
  );
}
