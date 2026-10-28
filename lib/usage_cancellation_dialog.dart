import 'package:flutter/material.dart';

import 'demo_auth_store.dart';
import 'prepaid_store.dart';
import 'prepaid_usage_store.dart';
import 'theme.dart';

class UsageCancellationDialog extends StatefulWidget {
  const UsageCancellationDialog({
    required this.auth,
    required this.account,
    required this.receipt,
    super.key,
  });
  final DemoAuthStore auth;
  final DemoAccount account;
  final PrepaidUsageReceipt receipt;
  @override
  State<UsageCancellationDialog> createState() =>
      _UsageCancellationDialogState();
}

class _UsageCancellationDialogState extends State<UsageCancellationDialog> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  bool _working = false;
  bool _submitted = false;
  String? _error;
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_working) return;
    setState(() => _submitted = true);
    if (!_form.currentState!.validate()) return;
    setState(() => _working = true);
    try {
      final result = await widget.auth.usage.reversePaymentRemote(
        receiptId: widget.receipt.id,
        storeId: widget.receipt.storeId,
        ownerId: widget.account.id,
        reason: _reason.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } on StateError catch (error) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text(
      '선결제 사용 취소',
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
    ),
    content: Form(
      key: _form,
      autovalidateMode: _submitted
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.auth.stores.store(widget.receipt.storeId).name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.auth.groups.group(widget.receipt.groupId).name} · ${widget.receipt.userName}',
            style: const TextStyle(
              fontSize: 12,
              height: 1.8,
              color: HantuckColors.muted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '복구 금액 ${formatWon(widget.receipt.amount)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: HantuckColors.orange,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '이 결제의 사용 금액 전액을 원래 선결제 잔액에 복구합니다. 원래 사용 기한은 유지되며 기한이 지난 잔액은 사용할 수 없습니다.',
            style: TextStyle(
              fontSize: 12,
              height: 1.8,
              color: HantuckColors.muted,
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            key: const ValueKey('usage-cancellation-reason'),
            controller: _reason,
            maxLength: 300,
            minLines: 2,
            maxLines: 5,
            style: const TextStyle(fontSize: 13, height: 1.8),
            decoration: const InputDecoration(
              labelText: '취소 사유 (선택)',
              hintText: '예: 이용 금액을 잘못 입력했어요.',
            ),
            validator: (value) => (value ?? '').trim().characters.length > 300
                ? '취소 사유는 300자 이내로 입력해 주세요.'
                : null,
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _error!,
                key: const ValueKey('usage-cancellation-error'),
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.8,
                  color: Color(0xFFBE3A35),
                ),
              ),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        key: const ValueKey('usage-cancellation-dismiss'),
        onPressed: _working ? null : () => Navigator.of(context).pop(),
        child: const Text('돌아가기'),
      ),
      FilledButton(
        key: const ValueKey('usage-cancellation-confirm'),
        onPressed: _working ? null : _confirm,
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB64540)),
        child: const Text('결제 취소 확정'),
      ),
    ],
  );
}
