import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'demo_auth_store.dart';
import 'donation_store.dart';
import 'group_widgets.dart';
import 'prepaid_store.dart';
import 'prepaid_usage_store.dart';
import 'theme.dart';

class StoreCashierScreen extends StatefulWidget {
  const StoreCashierScreen({
    required this.auth,
    required this.account,
    required this.storeId,
    super.key,
  });
  final DemoAuthStore auth;
  final DemoAccount account;
  final String storeId;
  @override
  State<StoreCashierScreen> createState() => _StoreCashierScreenState();
}

class _StoreCashierScreenState extends State<StoreCashierScreen> {
  final _code = TextEditingController();
  final _amount = TextEditingController();
  PrepaidUsageRequest? _request;
  String? _error;
  @override
  void dispose() {
    _code.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    try {
      final request = await widget.auth.usage.findForStoreRemote(
        code: _code.text,
        storeId: widget.storeId,
        ownerId: widget.account.id,
      );
      if (!mounted) return;
      setState(() {
        _request = request;
        _error = null;
        _amount.clear();
      });
      FocusManager.instance.primaryFocus?.unfocus();
    } on StateError catch (error) {
      if (!mounted) return;
      setState(() {
        _request = null;
        _error = error.message;
      });
    }
  }

  Future<void> _requestAmount() async {
    final amount = parseDonationAmount(_amount.text);
    if (amount == null) {
      setState(() => _error = '1원 이상의 사용 금액을 입력해 주세요.');
      return;
    }
    try {
      await widget.auth.usage.requestAmountRemote(
        requestId: _request!.id,
        storeId: widget.storeId,
        ownerId: widget.account.id,
        amount: amount,
      );
      if (!mounted) return;
      setState(() => _error = null);
      FocusManager.instance.primaryFocus?.unfocus();
    } on StateError catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([widget.auth.usage, widget.auth.groups]),
    builder: (context, _) {
      final auth = widget.auth;
      if (!auth.stores.ownsStore(widget.storeId, widget.account.id)) {
        return const AuthPage(
          child: Column(
            children: [
              GroupPageHeader(title: 'QR 결제 처리', backKey: 'cashier-back'),
              SizedBox(height: 24),
              Text('본인 가게의 결제만 처리할 수 있어요.', key: ValueKey('cashier-denied')),
            ],
          ),
        );
      }
      final request = _request;
      PrepaidStoreOffer? offer;
      if (request != null) {
        try {
          offer = auth.groups.availablePrepaidOffer(
            request.offerId,
            request.userId,
          );
        } on StateError {
          /* Completion and expiry are shown below. */
        }
      }
      final active =
          request != null &&
          !auth.usage.isExpired(request) &&
          request.status != UsageRequestStatus.cancelled &&
          request.status != UsageRequestStatus.paymentCancelled &&
          request.status != UsageRequestStatus.completed &&
          offer != null;
      return AuthPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GroupPageHeader(title: 'QR 결제 처리', backKey: 'cashier-back'),
            const SizedBox(height: 24),
            Text(
              auth.stores.store(widget.storeId).name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            const Text(
              '이용자의 QR 옆에 표시된 6자리 코드를 입력해 주세요.',
              style: TextStyle(
                fontSize: 12,
                height: 1.8,
                color: HantuckColors.muted,
              ),
            ),
            const SizedBox(height: 25),
            TextField(
              key: const ValueKey('cashier-code'),
              controller: _code,
              maxLength: 6,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: '이용 코드'),
              onChanged: (_) => setState(() {
                _request = null;
                _error = null;
              }),
              onSubmitted: (_) => _find(),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const ValueKey('cashier-find'),
              onPressed: _find,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('선결제 확인'),
            ),
            if (request != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: HantuckColors.orangeSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      auth.groups.group(request.groupId).name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '이용자 ${request.userName}',
                      style: const TextStyle(fontSize: 12, height: 1.8),
                    ),
                    Text(
                      auth.usage.statusLabel(request),
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.8,
                        color: HantuckColors.orange,
                      ),
                    ),
                    if (offer != null)
                      Text(
                        '남은 선결제 ${formatWon(offer.remainingAmount)}',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (request.amount != null)
                      Text(
                        '요청 금액 ${formatWon(request.amount!)}',
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (active &&
                  request.status == UsageRequestStatus.awaitingStore) ...[
                TextField(
                  key: const ValueKey('cashier-amount'),
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: '실제 메뉴 이용 금액',
                    suffixText: '원',
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton(
                  key: const ValueKey('cashier-request-amount'),
                  onPressed: _requestAmount,
                  child: const Text('이용자에게 결제 확인 요청'),
                ),
              ] else
                Text(
                  request.status == UsageRequestStatus.paymentCancelled
                      ? '가게에서 결제를 취소하고 원래 선결제 잔액에 사용 금액을 복구했어요.'
                      : request.status == UsageRequestStatus.completed
                      ? '이용자 승인이 완료되어 선결제가 차감됐어요.'
                      : active
                      ? '이용자가 QR 화면 또는 마이페이지에서 금액을 확인하고 승인하면 결제가 완료돼요.'
                      : '이용자에게 새 QR을 발급해 달라고 안내해 주세요.',
                  key: const ValueKey('cashier-request-result'),
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.9,
                    color: HantuckColors.muted,
                  ),
                ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Text(
                  _error!,
                  key: const ValueKey('cashier-error'),
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.8,
                    color: Color(0xFFBE3A35),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
