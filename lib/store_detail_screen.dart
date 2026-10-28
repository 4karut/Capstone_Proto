import 'package:flutter/material.dart';

import 'demo_auth_store.dart';
import 'group_widgets.dart';
import 'prepaid_store.dart';
import 'store_catalog.dart';
import 'store_prepaid_section.dart';
import 'theme.dart';

class StoreDetailScreen extends StatelessWidget {
  const StoreDetailScreen({
    required this.auth,
    required this.account,
    required this.store,
    this.groupId,
    super.key,
  });
  final DemoAuthStore auth;
  final DemoAccount account;
  final DemoStore store;
  final String? groupId;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([auth.groups, auth.stores]),
    builder: (context, _) {
      final store = auth.stores.store(this.store.id);
      final favorite = auth.stores.isFavorite(store.id, account.id);
      final offers = auth.stores
          .offersFor(store.id, account.id, auth.groups)
          .where((offer) => groupId == null || offer.groupId == groupId)
          .toList();
      return AuthPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GroupPageHeader(
              title: '가게 상세',
              backKey: 'store-detail-back',
              trailing: IconButton(
                key: const ValueKey('store-favorite-toggle'),
                tooltip: favorite ? '즐겨찾기 가게 해제' : '즐겨찾기 가게 지정',
                isSelected: favorite,
                onPressed: () =>
                    auth.stores.toggleFavorite(store.id, account.id),
                icon: const Icon(
                  Icons.favorite_border_rounded,
                  color: HantuckColors.muted,
                ),
                selectedIcon: const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFE54958),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                store.thumbnail,
                height: 190,
                fit: BoxFit.cover,
                semanticLabel: '${store.name} 대표 사진',
              ),
            ),
            const SizedBox(height: 24),
            Text(
              store.name,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              store.description,
              style: const TextStyle(fontSize: 13, height: 1.7),
            ),
            const SizedBox(height: 12),
            GroupTags(tags: store.tags),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 17,
                  color: HantuckColors.muted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    store.address,
                    key: const ValueKey('store-address'),
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.7,
                      color: HantuckColors.muted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            StorePrepaidSection(
              auth: auth,
              account: account,
              offers: offers,
              groupId: groupId,
            ),
            const SizedBox(height: 30),
            const Divider(color: HantuckColors.border, height: 1),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '판매 메뉴',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '${store.menu.length}개',
                  style: const TextStyle(
                    fontSize: 12,
                    color: HantuckColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              '마음을 담아 준비한 한 끼',
              style: TextStyle(fontSize: 11, color: HantuckColors.muted),
            ),
            const SizedBox(height: 6),
            ...store.menu.map(
              (item) => Container(
                key: ValueKey('store-menu-${item.name}'),
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: HantuckColors.border),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.recommended) ...[
                      const Text(
                        '대표 메뉴',
                        style: TextStyle(
                          fontSize: 10,
                          color: HantuckColors.orange,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.7,
                        color: HantuckColors.muted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      formatWon(item.price),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (store.menu.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  '메뉴를 준비하고 있어요.',
                  style: TextStyle(fontSize: 12, color: HantuckColors.muted),
                ),
              ),
            const SizedBox(height: 18),
            const Text(
              '메뉴와 가격은 예시 정보예요.',
              style: TextStyle(fontSize: 10, color: HantuckColors.muted),
            ),
          ],
        ),
      );
    },
  );
}
