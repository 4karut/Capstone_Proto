import 'server_widgets.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'demo_auth_store.dart';
import 'group_widgets.dart';
import 'prepaid_store.dart';
import 'prepaid_usage_store.dart';
import 'store_application_history_screen.dart';
import 'store_widgets.dart';
import 'thanks_screen.dart';
import 'theme.dart';
import 'usage_receipt_widgets.dart';
import 'usage_cancellation_dialog.dart';

class PrepaidQrScreen extends StatefulWidget {
  const PrepaidQrScreen({
    required this.auth,
    required this.account,
    required this.requestId,
    super.key,
  });
  final DemoAuthStore auth;
  final DemoAccount account;
  final String requestId;
  @override
  State<PrepaidQrScreen> createState() => _PrepaidQrScreenState();
}

class _PrepaidQrScreenState extends State<PrepaidQrScreen> {
  bool _busy = false;
  String? _error;
  Future<void> _approve() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final receipt = await widget.auth.usage.approveRemote(
        requestId: widget.requestId,
        userId: widget.account.id,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute(
          builder: (_) => ThanksComposeScreen(
            auth: widget.auth,
            account: widget.account,
            receiptId: receipt.id,
          ),
        ),
      );
    } on StateError catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.message;
      });
    }
  }

  Future<void> _renew(PrepaidUsageRequest request) async {
    try {
      final renewed = await widget.auth.usage.beginRemote(
        offerId: request.offerId,
        userId: widget.account.id,
        userName: widget.account.name,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute(
          builder: (_) => PrepaidQrScreen(
            auth: widget.auth,
            account: widget.account,
            requestId: renewed.id,
          ),
        ),
      );
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
      PrepaidUsageRequest request;
      try {
        request = auth.usage.requestForUser(
          widget.requestId,
          widget.account.id,
        );
      } on StateError {
        return const AuthPage(
          child: Text(
            '본인의 이용 요청만 확인할 수 있어요.',
            key: ValueKey('usage-request-denied'),
          ),
        );
      }
      final receipt = request.receiptId == null
          ? null
          : auth.usage.receiptForUser(request.receiptId!, widget.account.id);
      final completed = receipt != null;
      final ended =
          auth.usage.isExpired(request) ||
          request.status == UsageRequestStatus.cancelled;
      PrepaidStoreOffer? offer;
      if (!completed) {
        try {
          offer = auth.groups.availablePrepaidOffer(
            request.offerId,
            widget.account.id,
          );
        } on StateError {
          /* The status below offers a safe exit. */
        }
      }
      final available = offer != null && !ended && !completed;
      return AuthPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GroupPageHeader(title: '선결제 이용 QR', backKey: 'usage-qr-back'),
            const SizedBox(height: 24),
            Text(
              auth.stores.store(request.storeId).name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              auth.groups.group(request.groupId).name,
              style: const TextStyle(fontSize: 13, color: HantuckColors.muted),
            ),
            const SizedBox(height: 22),
            Text(
              auth.usage.statusLabel(request),
              key: const ValueKey('usage-request-status'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: HantuckColors.orange,
              ),
            ),
            const SizedBox(height: 18),
            if (available) ...[
              Center(
                child: QrImageView(
                  key: const ValueKey('usage-qr-image'),
                  data: request.qrData,
                  size: 220,
                  padding: const EdgeInsets.all(18),
                  backgroundColor: Colors.white,
                  semanticsLabel: '선택한 선결제의 이용 QR 코드',
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                '이용 코드',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: HantuckColors.muted),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SelectableText(
                    request.code,
                    key: const ValueKey('usage-code'),
                    style: const TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('usage-copy-code'),
                    tooltip: '이용 코드 복사',
                    onPressed: () =>
                        Clipboard.setData(ClipboardData(text: request.code)),
                    icon: const Icon(Icons.copy_rounded, size: 20),
                  ),
                ],
              ),
              Text(
                '${formatApplicationTime(request.expiresAt)}까지 유효',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: HantuckColors.muted,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '선택한 선결제 잔액 ${formatWon(offer.remainingAmount)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '사장님께 QR 또는 이용 코드를 보여주세요. 프로토타입에서는 가게 관리에 이용 코드를 입력해요.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.8,
                  color: HantuckColors.muted,
                ),
              ),
              const SizedBox(height: 22),
              if (request.status == UsageRequestStatus.awaitingUser) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: HantuckColors.orangeSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '사장님이 요청한 사용 금액',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        formatWon(request.amount!),
                        key: const ValueKey('usage-confirm-amount'),
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '가게와 금액을 확인한 뒤 승인해 주세요.',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.7,
                          color: HantuckColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  key: const ValueKey('usage-approve'),
                  onPressed: _busy ? null : _approve,
                  child: const Text('금액 확인 · 결제 승인'),
                ),
                const SizedBox(height: 12),
              ] else
                const Text(
                  '가게에서 사용 금액을 요청하면 여기에서 확인하고 승인할 수 있어요.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.8,
                    color: HantuckColors.muted,
                  ),
                ),
              TextButton(
                key: const ValueKey('usage-cancel'),
                onPressed: _busy
                    ? null
                    : () => remoteUiAction(
                        context,
                        () => auth.usage.cancelRemote(
                          requestId: request.id,
                          userId: widget.account.id,
                        ),
                      ),
                child: const Text('이용 요청 취소'),
              ),
            ] else if (completed) ...[
              UsageReceiptCard(auth: auth, receipt: receipt),
              if (!receipt.cancelled || receipt.thanks != null)
                FilledButton(
                  key: const ValueKey('usage-open-thanks'),
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => ThanksComposeScreen(
                        auth: auth,
                        account: widget.account,
                        receiptId: request.receiptId!,
                      ),
                    ),
                  ),
                  child: Text(
                    receipt.cancelled ? '보낸 감사 메시지 보기' : '감사 메시지 확인·작성',
                  ),
                ),
            ] else ...[
              const Text(
                '현재 사용할 수 없는 이용 요청이에요. 소속·잔액·사용 기한을 확인한 뒤 새 QR을 발급해 주세요.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.9,
                  color: HantuckColors.muted,
                ),
              ),
              const SizedBox(height: 22),
              OutlinedButton(
                key: const ValueKey('usage-renew'),
                onPressed: () => _renew(request),
                child: const Text('새 QR 발급하기'),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: Text(
                  _error!,
                  key: const ValueKey('usage-error'),
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

class UsageRequestsScreen extends StatelessWidget {
  const UsageRequestsScreen({
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
      final requests = auth.usage.requestsForUser(account.id);
      return AuthPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GroupPageHeader(
              title: '선결제 이용 내역',
              backKey: 'usage-requests-back',
            ),
            const SizedBox(height: 24),
            const Text(
              'QR과 결제 요청 확인',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            const Text(
              '승인 대기 금액을 확인하거나 사용 후 감사 메시지를 작성할 수 있어요.',
              style: TextStyle(
                fontSize: 12,
                height: 1.8,
                color: HantuckColors.muted,
              ),
            ),
            const SizedBox(height: 24),
            if (requests.isEmpty)
              const DiscoveryEmptyState(
                key: ValueKey('usage-requests-empty'),
                icon: Icons.qr_code_rounded,
                title: '아직 선결제 이용 내역이 없어요',
                description: '이용 가능한 가게에서 선결제를 골라 주세요.',
              ),
            for (final request in requests)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: HantuckColors.border),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: ValueKey('usage-request-${request.id}'),
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => PrepaidQrScreen(
                          auth: auth,
                          account: account,
                          requestId: request.id,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            auth.stores.store(request.storeId).name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            auth.groups.group(request.groupId).name,
                            style: const TextStyle(
                              fontSize: 12,
                              color: HantuckColors.muted,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${auth.usage.statusLabel(request)}${request.amount == null ? '' : ' · ${formatWon(request.amount!)}'}',
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.8,
                              fontWeight: FontWeight.w700,
                              color: HantuckColors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

class UsageNotificationsScreen extends StatelessWidget {
  const UsageNotificationsScreen({
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

  Future<void> _reverse(
    BuildContext context,
    PrepaidUsageReceipt receipt,
  ) async {
    final result = await showDialog<UsageCancellation>(
      context: context,
      builder: (_) => UsageCancellationDialog(
        auth: auth,
        account: account,
        receipt: receipt,
      ),
    );
    if (result == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('결제를 취소하고 ${formatWon(receipt.amount)}을 복구했어요.')),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([auth.usage, auth.stores]),
    builder: (context, _) {
      final receipts = forStore
          ? auth.usage.notificationsForStoreOwner(account.id, storeId: storeId)
          : auth.usage.notificationsForDonor(account.id);
      return AuthPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GroupPageHeader(
              title: '선결제 사용 알림',
              backKey: 'usage-notifications-back',
            ),
            const SizedBox(height: 24),
            Text(
              '사용 내역 ${receipts.length}건',
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              forStore ? '우리 가게에서 사용한 선결제 내역이에요.' : '내가 후원한 선결제의 사용 소식을 확인해요.',
              style: const TextStyle(
                fontSize: 12,
                height: 1.8,
                color: HantuckColors.muted,
              ),
            ),
            const SizedBox(height: 24),
            if (receipts.isEmpty)
              const DiscoveryEmptyState(
                key: ValueKey('usage-notifications-empty'),
                icon: Icons.notifications_none_rounded,
                title: '선결제 사용 알림이 없어요',
                description: '이용자의 결제 승인이 완료되면 알려드려요.',
              ),
            for (final receipt in receipts)
              UsageReceiptCard(
                auth: auth,
                receipt: receipt,
                showThanks: !forStore,
                onCancel: forStore && !receipt.cancelled
                    ? () => _reverse(context, receipt)
                    : null,
              ),
          ],
        ),
      );
    },
  );
}
