import 'package:flutter/material.dart';

import 'demo_auth_store.dart';
import 'group_detail_screen.dart';
import 'group_search_screen.dart';
import 'group_widgets.dart';
import 'theme.dart';

class GroupsOverviewScreen extends StatelessWidget {
  const GroupsOverviewScreen({
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
      final memberships = auth.groups.memberships(account.id);
      return AuthPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GroupPageHeader(
              title: '소속 그룹 리스트',
              backKey: 'groups-overview-back',
            ),
            const SizedBox(height: 22),
            Text(
              '내가 가입한 그룹 ${memberships.length}개',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -.7,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              '그룹을 눌러 소개와 선결제 가게를 확인해 보세요.',
              style: TextStyle(
                fontSize: 12,
                height: 1.8,
                color: HantuckColors.muted,
              ),
            ),
            const SizedBox(height: 24),
            if (memberships.isEmpty)
              Container(
                key: const ValueKey('member-groups-empty'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF8F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.groups_outlined,
                      size: 42,
                      color: HantuckColors.orange,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      '소속된 그룹이 없어요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 9),
                    const Text(
                      '그룹을 찾아 가입하면 여기에 표시돼요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.8,
                        color: HantuckColors.muted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      key: const ValueKey('member-groups-find'),
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) =>
                              GroupSearchScreen(auth: auth, account: account),
                        ),
                      ),
                      child: const Text('그룹 찾기'),
                    ),
                  ],
                ),
              ),
            ...memberships.map(
              (group) => GroupListCard(
                group: group,
                showDescription: true,
                favorite: auth.groups.isFavorite(group.id, account.id),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => GroupDetailScreen(
                      auth: auth,
                      account: account,
                      group: group,
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
