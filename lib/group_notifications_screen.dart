import 'package:flutter/material.dart';

import 'demo_auth_store.dart';
import 'group_widgets.dart';
import 'theme.dart';

class GroupNotificationsScreen extends StatelessWidget {
  const GroupNotificationsScreen({
    required this.auth,
    required this.account,
    super.key,
  });
  final DemoAuthStore auth;
  final DemoAccount account;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: auth.groups,
    builder: (context, _) {
      final notifications = auth.groups.notificationsForOwner(account.id);
      return AuthPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GroupPageHeader(
              title: '그룹 신청 알림',
              backKey: 'group-notifications-back',
            ),
            const SizedBox(height: 22),
            Text(
              '새로운 가입 신청 ${notifications.length}건',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 9),
            const Text(
              '자기소개를 확인하고 그룹원으로 승인해 주세요.',
              style: TextStyle(
                fontSize: 12,
                height: 1.7,
                color: HantuckColors.muted,
              ),
            ),
            const SizedBox(height: 24),
            if (notifications.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 42,
                  horizontal: 18,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF8F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 40,
                      color: HantuckColors.orange,
                    ),
                    SizedBox(height: 16),
                    Text(
                      '대기 중인 신청이 없어요',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ...notifications.map(
              (application) => Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  border: Border.all(color: HantuckColors.border),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      auth.groups.group(application.groupId).name,
                      style: const TextStyle(
                        fontSize: 11,
                        color: HantuckColors.orange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      '${application.userName}님의 가입 신청',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      application.userId,
                      style: const TextStyle(
                        fontSize: 11,
                        color: HantuckColors.muted,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF8F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        application.introduction.isEmpty
                            ? '자기소개를 작성하지 않았어요.'
                            : application.introduction,
                        style: const TextStyle(fontSize: 13, height: 1.8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: ValueKey('group-approve-${application.id}'),
                      onPressed: () {
                        auth.groups.approve(
                          applicationId: application.id,
                          ownerId: account.id,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${application.userName}님을 그룹원으로 승인했어요.',
                            ),
                          ),
                        );
                      },
                      child: const Text('승인하기'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
