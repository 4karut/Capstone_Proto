import 'package:flutter/material.dart';

import 'demo_auth_store.dart';
import 'group_widgets.dart';
import 'store_catalog.dart';
import 'store_application_history_screen.dart';
import 'store_widgets.dart';
import 'theme.dart';

class StoreReviewScreen extends StatelessWidget {
  const StoreReviewScreen({
    required this.auth,
    required this.account,
    super.key,
  });
  final DemoAuthStore auth;
  final DemoAccount account;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: auth.stores,
    builder: (context, _) {
      if (!auth.isAdmin(account.id)) {
        return const AuthPage(child: Text('관리자만 가게 신청을 확인할 수 있어요.'));
      }
      final applications = auth.stores.pendingApplications(account.id);
      return AuthPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GroupPageHeader(
              title: '가게 신청 심사',
              backKey: 'store-review-back',
            ),
            const SizedBox(height: 22),
            Text(
              '심사 대기 ${applications.length}건',
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const Text(
              '신청 정보를 확인하고 승인 또는 반려해 주세요.',
              style: TextStyle(
                fontSize: 12,
                height: 1.7,
                color: HantuckColors.muted,
              ),
            ),
            const SizedBox(height: 24),
            if (applications.isEmpty)
              const DiscoveryEmptyState(
                key: ValueKey('store-review-empty'),
                icon: Icons.fact_check_outlined,
                title: '대기 중인 신청이 없어요',
                description: '새 가게 신청이 도착하면 여기에서 확인해요.',
              ),
            ...applications.map(
              (app) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Material(
                  color: Colors.white,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: HantuckColors.border),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: InkWell(
                    key: ValueKey('store-review-${app.id}'),
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => _ApplicationReview(
                          auth: auth,
                          account: account,
                          application: app,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${app.submissionNumber}차 신청${app.previousApplicationId == null ? '' : ' · 재신청'}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: HantuckColors.orange,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${app.category} · 신청자 ${app.ownerName}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: HantuckColors.orange,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            app.address,
                            style: const TextStyle(
                              fontSize: 11,
                              height: 1.7,
                              color: HantuckColors.muted,
                            ),
                          ),
                        ],
                      ),
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

class _ApplicationReview extends StatelessWidget {
  const _ApplicationReview({
    required this.auth,
    required this.account,
    required this.application,
  });
  final DemoAuthStore auth;
  final DemoAccount account;
  final StoreApplication application;

  void _approve(BuildContext context) {
    try {
      auth.stores.approve(applicationId: application.id, adminId: account.id);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${application.name}가 승인됐어요.')));
    } on StateError catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _reject(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _RejectionReasonDialog(),
    );
    if (reason == null || !context.mounted) return;
    try {
      auth.stores.reject(
        applicationId: application.id,
        adminId: account.id,
        reason: reason,
      );
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('반려 사유가 신청자에게 전달됐어요.')));
    } on StateError catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) => AuthPage(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GroupPageHeader(
          title: '가게 신청 정보',
          backKey: 'store-review-detail-back',
        ),
        const SizedBox(height: 24),
        Text(
          application.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 23),
        Text(
          '${application.submissionNumber}차 신청${application.previousApplicationId == null ? '' : ' · 재신청'}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: HantuckColors.orange,
          ),
        ),
        const SizedBox(height: 18),
        if (application.previousApplicationId != null) ...[
          OutlinedButton.icon(
            key: const ValueKey('store-review-history'),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => StoreApplicationHistoryScreen(
                  auth: auth,
                  account: account,
                  applicationId: application.id,
                ),
              ),
            ),
            icon: const Icon(Icons.history_rounded, size: 20),
            label: const Text('이전 신청·반려 이력 확인'),
          ),
          const SizedBox(height: 22),
        ],
        for (final row in [
          ('사업자등록번호', application.registrationNumber),
          ('주소', application.address),
          ('카테고리', application.category),
          ('가게 전화번호', application.phoneNumber),
          (
            '한 줄 소개',
            application.description.isEmpty
                ? '입력하지 않았어요.'
                : application.description,
          ),
          ('신청자', '${application.ownerName} · ${application.ownerId}'),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.$1,
                  style: const TextStyle(
                    fontSize: 11,
                    color: HantuckColors.muted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(row.$2, style: const TextStyle(fontSize: 14, height: 1.7)),
              ],
            ),
          ),
        const SizedBox(height: 12),
        const Text(
          '프로토타입 심사이며 실제 사업자·영업 신고 확인은 진행하지 않아요.',
          style: TextStyle(
            fontSize: 10,
            height: 1.8,
            color: HantuckColors.muted,
          ),
        ),
        const SizedBox(height: 19),
        FilledButton(
          key: ValueKey('store-approve-${application.id}'),
          onPressed: () => _approve(context),
          child: const Text('승인하기'),
        ),
        const SizedBox(height: 13),
        OutlinedButton(
          key: ValueKey('store-reject-${application.id}'),
          onPressed: () => _reject(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: rejectionColor,
            minimumSize: const Size.fromHeight(52),
          ),
          child: const Text('반려하기'),
        ),
      ],
    ),
  );
}

class _RejectionReasonDialog extends StatefulWidget {
  const _RejectionReasonDialog();
  @override
  State<_RejectionReasonDialog> createState() => _RejectionReasonDialogState();
}

class _RejectionReasonDialogState extends State<_RejectionReasonDialog> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  bool _submitted = false;
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text(
      '가게 신청 반려',
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
          const Text(
            '신청자가 수정할 내용을 알 수 있도록 사유를 작성해 주세요.',
            style: TextStyle(
              fontSize: 12,
              height: 1.8,
              color: HantuckColors.muted,
            ),
          ),
          const SizedBox(height: 18),
          TextFormField(
            key: const ValueKey('store-rejection-reason-input'),
            controller: _reason,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            maxLength: 300,
            style: const TextStyle(fontSize: 13, height: 1.7),
            decoration: const InputDecoration(
              labelText: '반려 사유 (필수)',
              hintText: '예: 상세 주소에 층·호수를 입력해 주세요.',
              errorMaxLines: 2,
            ),
            validator: (value) =>
                (value ?? '').trim().isEmpty ||
                    (value ?? '').trim().characters.length > 300
                ? '반려 사유를 1~300자로 입력해 주세요.'
                : null,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        key: const ValueKey('store-rejection-cancel'),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('취소'),
      ),
      FilledButton(
        key: const ValueKey('store-rejection-submit'),
        onPressed: () {
          setState(() => _submitted = true);
          if (_form.currentState!.validate()) {
            Navigator.of(context).pop(_reason.text.trim());
          }
        },
        child: const Text('반려 확정'),
      ),
    ],
  );
}
