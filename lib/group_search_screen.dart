import 'package:flutter/material.dart';

import 'demo_auth_store.dart';
import 'group_detail_screen.dart';
import 'group_store.dart';
import 'group_widgets.dart';
import 'theme.dart';

class GroupSearchScreen extends StatefulWidget {
  const GroupSearchScreen({
    required this.auth,
    required this.account,
    super.key,
  });
  final DemoAuthStore auth;
  final DemoAccount account;

  @override
  State<GroupSearchScreen> createState() => _GroupSearchScreenState();
}

class _GroupSearchScreenState extends State<GroupSearchScreen> {
  final _query = TextEditingController();
  String _category = '전체';
  String _searchedQuery = '';
  late List<DemoGroup> _results = widget.auth.groups.search();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _search() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _searchedQuery = _query.text.trim();
      _results = widget.auth.groups.search(
        query: _query.text,
        category: _category,
      );
    });
  }

  String? _status(DemoGroup group) =>
      switch (widget.auth.groups.joinStatus(group.id, widget.account.id)) {
        GroupJoinStatus.member => '가입한 그룹',
        GroupJoinStatus.pending => '승인 대기 중',
        GroupJoinStatus.notApplied => group.locked ? '초대 전용' : null,
      };

  @override
  Widget build(BuildContext context) => AuthPage(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GroupPageHeader(title: '그룹 찾기', backKey: 'group-search-back'),
        const SizedBox(height: 20),
        const Text(
          '함께할 그룹을 찾아보세요',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            letterSpacing: -.7,
          ),
        ),
        const SizedBox(height: 9),
        const Text(
          '그룹 이름, 그룹 코드, 태그로 검색할 수 있어요.',
          style: TextStyle(
            fontSize: 12,
            height: 1.7,
            color: HantuckColors.muted,
          ),
        ),
        const SizedBox(height: 22),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('group-search-query'),
                controller: _query,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: '이름 · 코드 · #태그',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _query.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: '검색어 지우기',
                          onPressed: () {
                            _query.clear();
                            _search();
                          },
                          icon: const Icon(Icons.close_rounded, size: 17),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            FilledButton(
              key: const ValueKey('group-search-submit'),
              onPressed: _search,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 53),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('검색', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          '카테고리',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 7),
        DropdownButtonFormField<String>(
          key: const ValueKey('group-search-category'),
          initialValue: _category,
          isExpanded: true,
          items: DemoGroupStore.categories
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(value, style: const TextStyle(fontSize: 13)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              _category = value;
              _search();
            }
          },
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                _searchedQuery.isEmpty ? '랜덤으로 만나는 그룹' : '검색 결과',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${_results.length}개',
              style: const TextStyle(fontSize: 12, color: HantuckColors.muted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_searchedQuery.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              '검색어를 비우고 검색하면 랜덤으로 보여드려요.',
              style: TextStyle(
                fontSize: 10,
                height: 1.6,
                color: HantuckColors.muted,
              ),
            ),
          ),
        ListenableBuilder(
          listenable: widget.auth.groups,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _results
                .map(
                  (group) => GroupListCard(
                    group: group,
                    favorite: widget.auth.groups.isFavorite(
                      group.id,
                      widget.account.id,
                    ),
                    status: _status(group),
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => GroupDetailScreen(
                          auth: widget.auth,
                          account: widget.account,
                          group: group,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        if (_results.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF8F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 36,
                  color: HantuckColors.muted,
                ),
                SizedBox(height: 14),
                Text(
                  '검색 결과가 없어요',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text(
                  '검색어나 카테고리를 바꿔보세요.',
                  style: TextStyle(fontSize: 12, color: HantuckColors.muted),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
