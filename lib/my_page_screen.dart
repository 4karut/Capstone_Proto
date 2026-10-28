import 'server_widgets.dart';

import 'package:flutter/material.dart';

import 'demo_auth_store.dart';
import 'group_widgets.dart';
import 'login_screen.dart';
import 'store_application_screen.dart';
import 'store_application_history_screen.dart';
import 'store_management_screen.dart';
import 'store_review_screen.dart';
import 'theme.dart';
import 'prepaid_usage_screen.dart';
import 'thanks_screen.dart';

String displayPhone(String phone) => phone.length == 11
    ? '${phone.substring(0, 3)}-${phone.substring(3, 7)}-${phone.substring(7)}'
    : phone;

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({required this.auth, required this.account, super.key});
  final DemoAuthStore auth;
  final DemoAccount account;

  void _manage(BuildContext context) {
    final stores = auth.stores.ownedStores(account.id);
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => stores.length == 1
            ? StoreManagementScreen(
                auth: auth,
                account: account,
                storeId: stores.single.id,
              )
            : StoreManagementSelectionScreen(auth: auth, account: account),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([auth.stores, auth.usage]),
    builder: (context, _) {
      final stores = auth.stores.ownedStores(account.id);
      final applications = auth.stores.latestApplicationsFor(account.id);
      return AuthPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '마이페이지',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 28),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6E8ED),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 49,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        key: const ValueKey('my-page-name'),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        account.email,
                        key: const ValueKey('my-page-email'),
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.7,
                          color: HantuckColors.muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayPhone(account.phoneNumber),
                        key: const ValueKey('my-page-phone'),
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.7,
                          color: HantuckColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            OutlinedButton.icon(
              key: const ValueKey('my-page-settings'),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) =>
                      AccountSettingsScreen(auth: auth, account: account),
                ),
              ),
              icon: const Icon(Icons.settings_outlined, size: 20),
              label: const Text('계정 설정'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              key: const ValueKey('my-page-apply-store'),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) =>
                      StoreApplicationScreen(auth: auth, account: account),
                ),
              ),
              icon: const Icon(Icons.add_business_outlined),
              label: const Text('가게 신청하기'),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              key: const ValueKey('my-page-prepaid-usage'),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) =>
                      UsageRequestsScreen(auth: auth, account: account),
                ),
              ),
              icon: const Icon(Icons.qr_code_rounded),
              label: const Text('선결제 이용 내역 · 결제 확인'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey('my-page-usage-notifications'),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) =>
                      UsageNotificationsScreen(auth: auth, account: account),
                ),
              ),
              icon: const Icon(Icons.notifications_none_rounded),
              label: Text(
                '선결제 사용 알림 ${auth.usage.notificationsForDonor(account.id).length}건',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey('my-page-thanks'),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) =>
                      ReceivedThanksScreen(auth: auth, account: account),
                ),
              ),
              icon: const Icon(Icons.mark_email_read_outlined),
              label: Text(
                '받은 감사 메시지 보기 ${auth.usage.thanksForDonor(account.id).length}건',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
            ),
            if (stores.isNotEmpty) ...[
              const SizedBox(height: 14),
              FilledButton.tonalIcon(
                key: const ValueKey('my-page-manage-store'),
                onPressed: () => _manage(context),
                icon: const Icon(Icons.storefront_outlined),
                label: Text('가게 관리 · ${stores.length}개'),
              ),
            ],
            if (auth.isAdmin(account.id)) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                key: const ValueKey('my-page-review-stores'),
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) =>
                        StoreReviewScreen(auth: auth, account: account),
                  ),
                ),
                icon: const Icon(Icons.fact_check_outlined),
                label: Text(
                  '가게 신청 심사 ${auth.stores.pendingApplications(account.id).length}건',
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                ),
              ),
            ],
            if (applications.isNotEmpty) ...[
              const SizedBox(height: 30),
              const Text(
                '내 가게 신청 내역',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 13),
              ...applications.map(
                (app) => Container(
                  key: ValueKey('my-store-application-${app.id}'),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: HantuckColors.border),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 7,
                        children: [
                          Text(
                            app.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            app.status.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: app.rejected
                                  ? rejectionColor
                                  : HantuckColors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${app.submissionNumber}차 신청',
                        style: const TextStyle(
                          fontSize: 11,
                          color: HantuckColors.muted,
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
                      if (app.rejected) ...[
                        const SizedBox(height: 15),
                        StoreRejectionNotice(application: app),
                        const SizedBox(height: 12),
                        if (auth.stores.canResubmit(app.id, account.id))
                          FilledButton.tonalIcon(
                            key: ValueKey('store-resubmit-${app.id}'),
                            onPressed: () => Navigator.of(context).push<void>(
                              MaterialPageRoute(
                                builder: (_) => StoreApplicationScreen(
                                  auth: auth,
                                  account: account,
                                  resubmissionOf: app.id,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('정보 수정 후 재신청'),
                          ),
                      ],
                      const SizedBox(height: 8),
                      TextButton(
                        key: ValueKey('store-history-${app.id}'),
                        onPressed: () => Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) => StoreApplicationHistoryScreen(
                              auth: auth,
                              account: account,
                              applicationId: app.id,
                            ),
                          ),
                        ),
                        child: const Text(
                          '신청 정보·이력 보기',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({
    required this.auth,
    required this.account,
    super.key,
  });
  final DemoAuthStore auth;
  final DemoAccount account;
  @override
  Widget build(BuildContext context) => AuthPage(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GroupPageHeader(title: '계정 설정', backKey: 'account-settings-back'),
        const SizedBox(height: 24),
        const Text(
          '가입 정보',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 20),
        for (final row in [
          ('아이디', account.id),
          ('이름', account.name),
          ('이메일', account.email),
          ('전화번호', displayPhone(account.phoneNumber)),
          (
            '생년월일',
            '${account.birthDate.year}.${account.birthDate.month.toString().padLeft(2, '0')}.${account.birthDate.day.toString().padLeft(2, '0')}',
          ),
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
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
                Text(row.$2, style: const TextStyle(fontSize: 14, height: 1.6)),
              ],
            ),
          ),
        const SizedBox(height: 25),
        OutlinedButton(
          key: const ValueKey('account-logout'),
          onPressed: () async {
            await remoteUiAction(context, auth.signOutRemote);
            if (!context.mounted) return;
            Navigator.of(context, rootNavigator: true).pushAndRemoveUntil<void>(
              MaterialPageRoute(builder: (_) => LoginScreen(auth: auth)),
              (_) => false,
            );
          },
          child: const Text('로그아웃'),
        ),
      ],
    ),
  );
}
