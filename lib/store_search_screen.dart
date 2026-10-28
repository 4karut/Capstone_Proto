import 'package:flutter/material.dart';

import 'demo_auth_store.dart';
import 'store_detail_screen.dart';
import 'store_widgets.dart';
import 'theme.dart';

class StoreSearchScreen extends StatefulWidget {
  const StoreSearchScreen({
    required this.auth,
    required this.account,
    super.key,
  });
  final DemoAuthStore auth;
  final DemoAccount account;

  @override
  State<StoreSearchScreen> createState() => _StoreSearchScreenState();
}

class _StoreSearchScreenState extends State<StoreSearchScreen> {
  final _query = TextEditingController();
  String _submittedQuery = '';

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _search() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _submittedQuery = _query.text.trim());
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([widget.auth.groups, widget.auth.stores]),
    builder: (context, _) {
      final auth = widget.auth;
      final userId = widget.account.id;
      final allStores = auth.stores.searchAll();
      final results = auth.stores.searchAll(query: _submittedQuery);
      return AuthPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '가게 찾기',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              '마음에 드는 가게를 찾아보세요.',
              style: TextStyle(
                fontSize: 12,
                height: 1.7,
                color: HantuckColors.muted,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('store-search-query'),
                    controller: _query,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '가게 이름으로 검색',
                      prefixIcon: const Icon(Icons.search_rounded, size: 21),
                      suffixIcon: _query.text.isEmpty
                          ? null
                          : IconButton(
                              key: const ValueKey('store-search-clear'),
                              tooltip: '검색어 지우기',
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _query.clear();
                                _search();
                              },
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 54,
                  child: FilledButton(
                    key: const ValueKey('store-search-submit'),
                    onPressed: _search,
                    style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Text('검색', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              '그룹 가입 없이 가게를 둘러보고 즐겨찾기할 수 있어요.',
              style: TextStyle(
                fontSize: 10,
                height: 1.7,
                color: HantuckColors.muted,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _submittedQuery.isEmpty ? '전체 가게' : '검색 결과',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${results.length}개',
                  key: const ValueKey('store-search-count'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: HantuckColors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (allStores.isEmpty)
              const DiscoveryEmptyState(
                key: ValueKey('store-search-empty'),
                icon: Icons.storefront_outlined,
                title: '등록된 가게가 없어요',
                description: '가게가 등록되면 여기에서 찾아볼 수 있어요.',
              )
            else if (results.isEmpty)
              const DiscoveryEmptyState(
                key: ValueKey('store-search-no-results'),
                icon: Icons.search_off_rounded,
                title: '검색 결과가 없어요',
                description: '가게 이름을 다시 확인해 주세요.',
              ),
            ...results.map(
              (store) => StoreListCard(
                store: store,
                available: auth.stores
                    .offersFor(store.id, userId, auth.groups)
                    .isNotEmpty,
                favorite: auth.stores.isFavorite(store.id, userId),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => StoreDetailScreen(
                      auth: auth,
                      account: widget.account,
                      store: store,
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
