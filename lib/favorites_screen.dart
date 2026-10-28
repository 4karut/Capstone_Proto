import 'package:flutter/material.dart';

import 'demo_auth_store.dart';
import 'group_detail_screen.dart';
import 'group_search_screen.dart';
import 'group_widgets.dart';
import 'main_navigation.dart';
import 'store_detail_screen.dart';
import 'store_widgets.dart';
import 'theme.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({required this.auth, required this.account, super.key});
  final DemoAuthStore auth;
  final DemoAccount account;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([widget.auth.groups, widget.auth.stores]),
    builder: (context, _) {
      final auth = widget.auth;
      final account = widget.account;
      final groups = auth.groups.favoritesFor(account.id);
      final stores = auth.stores.favoritesFor(account.id);
      return AuthPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '즐겨찾기',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              '마음에 담아 둔 그룹과 가게를 모았어요.',
              style: TextStyle(
                fontSize: 12,
                height: 1.7,
                color: HantuckColors.muted,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: HantuckColors.canvas,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  for (var index = 0; index < 2; index++)
                    Expanded(
                      child: Semantics(
                        selected: _selectedIndex == index,
                        child: TextButton(
                          key: ValueKey(
                            index == 0
                                ? 'favorites-groups-tab'
                                : 'favorites-stores-tab',
                          ),
                          onPressed: () =>
                              setState(() => _selectedIndex = index),
                          style: TextButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 12,
                            ),
                            backgroundColor: _selectedIndex == index
                                ? Colors.white
                                : Colors.transparent,
                            foregroundColor: _selectedIndex == index
                                ? HantuckColors.orange
                                : HantuckColors.muted,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            index == 0
                                ? '즐겨찾기 그룹 ${groups.length}'
                                : '즐겨찾기 가게 ${stores.length}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_selectedIndex == 0) ...[
              if (groups.isEmpty)
                DiscoveryEmptyState(
                  key: const ValueKey('favorites-groups-empty'),
                  icon: Icons.favorite_border_rounded,
                  title: '즐겨찾기한 그룹이 없어요',
                  description: '그룹 상세의 하트를 눌러\n관심 있는 그룹을 담아 보세요.',
                  action: TextButton(
                    key: const ValueKey('favorites-find-group'),
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) =>
                            GroupSearchScreen(auth: auth, account: account),
                      ),
                    ),
                    child: const Text('그룹 찾기'),
                  ),
                ),
              ...groups.map(
                (group) => GroupListCard(
                  group: group,
                  showDescription: true,
                  favorite: true,
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
            ] else ...[
              if (stores.isEmpty)
                DiscoveryEmptyState(
                  key: const ValueKey('favorites-stores-empty'),
                  icon: Icons.storefront_outlined,
                  title: '즐겨찾기한 가게가 없어요',
                  description: '가게 상세의 하트를 눌러\n다시 찾고 싶은 가게를 담아 보세요.',
                  action: TextButton(
                    key: const ValueKey('favorites-find-store'),
                    onPressed: () => MainNavigation.maybeOf(context)?.select(1),
                    child: const Text('가게 찾기'),
                  ),
                ),
              ...stores.map(
                (store) => StoreListCard(
                  store: store,
                  favorite: true,
                  available: auth.stores
                      .offersFor(store.id, account.id, auth.groups)
                      .isNotEmpty,
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => StoreDetailScreen(
                        auth: auth,
                        account: account,
                        store: store,
                      ),
                    ),
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
