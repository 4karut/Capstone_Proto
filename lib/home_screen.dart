import 'package:flutter/material.dart';

import 'demo_auth_store.dart';
import 'donation_notifications_screen.dart';
import 'group_notifications_screen.dart';
import 'group_search_screen.dart';
import 'groups_overview_screen.dart';
import 'login_screen.dart';
import 'prepaid_store.dart';
import 'prepaid_store_card.dart';
import 'store_detail_screen.dart';
import 'theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.auth, required this.account, super.key});
  final DemoAuthStore auth;
  final DemoAccount account;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    final groups = widget.auth.groups.memberships(widget.account.id);
    _selectedGroupId = groups.isEmpty ? null : groups.first.id;
    widget.auth.groups.addListener(_groupsChanged);
    widget.auth.donations.addListener(_groupsChanged);
  }

  void _groupsChanged() {
    if (!mounted) return;
    final groups = widget.auth.groups.memberships(widget.account.id);
    setState(() {
      if (!groups.any((group) => group.id == _selectedGroupId)) {
        _selectedGroupId = groups.isEmpty ? null : groups.first.id;
      }
    });
  }

  @override
  void dispose() {
    widget.auth.groups.removeListener(_groupsChanged);
    widget.auth.donations.removeListener(_groupsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.auth;
    final account = widget.account;
    final memberships = auth.groups.memberships(account.id);
    final pending = auth.groups.pendingForUser(account.id);
    final notifications = auth.groups.notificationsForOwner(account.id);
    final offers = _selectedGroupId == null
        ? const <PrepaidStoreOffer>[]
        : auth.groups.prepaidOffersFor(_selectedGroupId!, account.id);
    final stores = summarizePrepaidStores(offers);
    return AuthPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            key: const ValueKey('home-find-group'),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => GroupSearchScreen(auth: auth, account: account),
              ),
            ),
            icon: const Icon(Icons.search_rounded, size: 22),
            label: const Text('그룹 찾기'),
          ),
          const SizedBox(height: 28),
          _SectionTitle(title: '내 소속 그룹', count: '${memberships.length}개'),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCFBFA),
                    border: Border.all(color: HantuckColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      key: const ValueKey('home-group-dropdown'),
                      value: _selectedGroupId,
                      isExpanded: true,
                      hint: const Text(
                        '소속 그룹이 없어요',
                        style: TextStyle(
                          fontSize: 13,
                          color: HantuckColors.muted,
                        ),
                      ),
                      items: memberships
                          .map(
                            (group) => DropdownMenuItem(
                              value: group.id,
                              child: Text(
                                group.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: HantuckColors.ink,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: memberships.isEmpty
                          ? null
                          : (value) => setState(() => _selectedGroupId = value),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox.square(
                dimension: 54,
                child: IconButton.outlined(
                  key: const ValueKey('home-all-groups'),
                  tooltip: '소속 그룹 리스트 보기',
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) =>
                          GroupsOverviewScreen(auth: auth, account: account),
                    ),
                  ),
                  icon: const Icon(Icons.grid_view_rounded, size: 22),
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
          const SizedBox(height: 10),
          Text(
            memberships.isEmpty
                ? '그룹을 찾아 가입하면 여기에서 선택할 수 있어요.'
                : '선택한 그룹에서 이용할 수 있는 가게를 확인해요.',
            style: const TextStyle(
              fontSize: 11,
              height: 1.6,
              color: HantuckColors.muted,
            ),
          ),
          if (auth.groups.ownsAnyGroup(account.id)) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              key: const ValueKey('home-group-notifications'),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) =>
                      GroupNotificationsScreen(auth: auth, account: account),
                ),
              ),
              icon: const Icon(Icons.notifications_none_rounded, size: 20),
              label: Text(
                '그룹 신청 알림 ${notifications.length}건',
                style: const TextStyle(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
          for (final forStore in [false, true])
            if (forStore
                ? auth.stores.ownsAnyStore(account.id)
                : auth.groups.ownsAnyGroup(account.id)) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: ValueKey(
                  forStore
                      ? 'home-store-donation-notifications'
                      : 'home-donation-notifications',
                ),
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => DonationNotificationsScreen(
                      auth: auth,
                      account: account,
                      forStore: forStore,
                    ),
                  ),
                ),
                icon: Icon(
                  forStore
                      ? Icons.storefront_outlined
                      : Icons.volunteer_activism_outlined,
                  size: 20,
                ),
                label: Text(
                  forStore
                      ? '가게 선결제 알림 ${auth.donations.notificationsForStoreOwner(account.id).length}건'
                      : '그룹 후원 알림 ${auth.donations.notificationsForGroupOwner(account.id).length}건',
                  style: const TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          if (pending.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              '가입 신청',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 9),
            ...pending.map(
              (application) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: HantuckColors.orangeSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        auth.groups.group(application.groupId).name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Text(
                      '승인 대기',
                      style: TextStyle(
                        fontSize: 11,
                        color: HantuckColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 30),
          _SectionTitle(title: '이용 가능한 가게', count: '${stores.length}개'),
          const SizedBox(height: 14),
          if (offers.isEmpty)
            Container(
              key: const ValueKey('home-empty-stores'),
              constraints: const BoxConstraints(minHeight: 290),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              decoration: BoxDecoration(
                color: const Color(0xFFFCFBF9),
                border: Border.all(color: HantuckColors.border),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 74,
                    width: 74,
                    decoration: const BoxDecoration(
                      color: HantuckColors.orangeSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.storefront_outlined,
                      color: HantuckColors.orange,
                      size: 35,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    '이용 가능한 가게가 없어요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    memberships.isEmpty
                        ? '먼저 그룹을 찾아 가입해 주세요.\n소속 그룹의 가게가 여기에 표시돼요.'
                        : '선택한 그룹에서 이용할 수 있는\n가게가 아직 없어요.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.8,
                      color: HantuckColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ...stores.map(
            (summary) => PrepaidStoreCard(
              summary: summary,
              now: auth.groups.currentTime,
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => StoreDetailScreen(
                    auth: auth,
                    account: account,
                    store: auth.stores.store(summary.storeId),
                    groupId: summary.groupId,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Divider(height: 1, color: HantuckColors.border),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.account_circle_outlined,
                size: 27,
                color: HantuckColors.muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${account.name}님',
                      key: const ValueKey('home-greeting'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      account.id,
                      key: const ValueKey('home-account-id'),
                      style: const TextStyle(
                        fontSize: 10,
                        color: HantuckColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                key: const ValueKey('home-logout'),
                onPressed: () => Navigator.of(context, rootNavigator: true)
                    .pushAndRemoveUntil<void>(
                      MaterialPageRoute(
                        builder: (_) => LoginScreen(auth: auth),
                      ),
                      (_) => false,
                    ),
                style: TextButton.styleFrom(
                  foregroundColor: HantuckColors.muted,
                ),
                child: const Text('로그아웃', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.count});
  final String title;
  final String count;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      Text(
        count,
        style: const TextStyle(fontSize: 12, color: HantuckColors.muted),
      ),
    ],
  );
}
