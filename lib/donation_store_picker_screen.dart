import 'package:flutter/material.dart';

import 'demo_auth_store.dart';
import 'group_widgets.dart';
import 'store_catalog.dart';
import 'store_widgets.dart';
import 'theme.dart';

class DonationStorePickerScreen extends StatefulWidget {
  const DonationStorePickerScreen({
    required this.auth,
    required this.account,
    super.key,
  });
  final DemoAuthStore auth;
  final DemoAccount account;
  @override
  State<DonationStorePickerScreen> createState() =>
      _DonationStorePickerScreenState();
}

class _DonationStorePickerScreenState extends State<DonationStorePickerScreen> {
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

  Future<void> _favorites() async {
    final store = await Navigator.of(context).push<DemoStore>(
      MaterialPageRoute(
        builder: (_) => DonationFavoriteStoresScreen(
          auth: widget.auth,
          account: widget.account,
        ),
      ),
    );
    if (mounted && store != null) Navigator.of(context).pop(store);
  }

  @override
  Widget build(BuildContext context) {
    final results = widget.auth.stores.searchAll(query: _submittedQuery);
    return AuthPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GroupPageHeader(
            title: '선결제 가게 선택',
            backKey: 'donation-store-picker-back',
          ),
          const SizedBox(height: 22),
          const Text(
            '후원할 가게를 찾아보세요',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 9),
          const Text(
            '등록된 전체 가게에서 이름으로 검색할 수 있어요.',
            style: TextStyle(
              fontSize: 11,
              height: 1.7,
              color: HantuckColors.muted,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('donation-store-search-query'),
                  controller: _query,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '가게 이름으로 검색',
                    suffixIcon: IconButton(
                      key: const ValueKey('donation-store-search-submit'),
                      tooltip: '가게 검색',
                      onPressed: _search,
                      icon: const Icon(Icons.search_rounded, size: 22),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox.square(
                dimension: 54,
                child: IconButton.outlined(
                  key: const ValueKey('donation-store-favorites'),
                  tooltip: '즐겨찾기 가게에서 선택',
                  onPressed: _favorites,
                  icon: const Icon(Icons.favorite_border_rounded, size: 23),
                  style: IconButton.styleFrom(
                    foregroundColor: HantuckColors.orange,
                    backgroundColor: HantuckColors.orangeSoft,
                    side: const BorderSide(color: Color(0xFFF3D9CA)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            '${_submittedQuery.isEmpty ? '전체 가게' : '검색 결과'} ${results.length}개',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          if (results.isEmpty)
            const DiscoveryEmptyState(
              key: ValueKey('donation-store-search-empty'),
              icon: Icons.search_off_rounded,
              title: '검색 결과가 없어요',
              description: '가게 이름을 다시 확인해 주세요.',
            ),
          ...results.map(
            (store) => _StoreOption(
              store: store,
              onTap: () => Navigator.of(context).pop(store),
            ),
          ),
        ],
      ),
    );
  }
}

class DonationFavoriteStoresScreen extends StatelessWidget {
  const DonationFavoriteStoresScreen({
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
      final stores = auth.stores.favoritesFor(account.id);
      return AuthPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GroupPageHeader(
              title: '즐겨찾기 가게',
              backKey: 'donation-store-favorites-back',
            ),
            const SizedBox(height: 22),
            const Text(
              '후원할 가게를 선택해 주세요.',
              style: TextStyle(
                fontSize: 13,
                height: 1.7,
                color: HantuckColors.muted,
              ),
            ),
            const SizedBox(height: 22),
            if (stores.isEmpty)
              DiscoveryEmptyState(
                key: const ValueKey('donation-store-favorites-empty'),
                icon: Icons.favorite_border_rounded,
                title: '즐겨찾기한 가게가 없어요',
                description: '가게 검색에서 후원할 가게를 찾아보세요.',
                action: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('가게 검색으로 돌아가기'),
                ),
              ),
            ...stores.map(
              (store) => _StoreOption(
                store: store,
                onTap: () => Navigator.of(context).pop(store),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _StoreOption extends StatelessWidget {
  const _StoreOption({required this.store, required this.onTap});
  final DemoStore store;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: HantuckColors.border),
      ),
      child: InkWell(
        key: ValueKey('donation-store-option-${store.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  store.thumbnail,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  semanticLabel: '${store.name} 썸네일',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      store.address,
                      style: const TextStyle(
                        fontSize: 10,
                        height: 1.6,
                        color: HantuckColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: HantuckColors.muted,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
