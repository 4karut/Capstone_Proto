import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'demo_auth_store.dart';
import 'donation_choice_screen.dart';
import 'group_store.dart';
import 'group_widgets.dart';
import 'main_navigation.dart';
import 'prepaid_store.dart';
import 'prepaid_store_card.dart';
import 'store_detail_screen.dart';
import 'theme.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({
    required this.auth,
    required this.account,
    required this.group,
    super.key,
  });
  final DemoAuthStore auth;
  final DemoAccount account;
  final DemoGroup group;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  bool _working = false;

  void _sponsor() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => DonationChoiceScreen(
        auth: widget.auth,
        account: widget.account,
        group: widget.group,
      ),
    ),
  );

  Future<void> _apply() async {
    if (_working) return;
    setState(() => _working = true);
    try {
      if (widget.group.locked) {
        final joined = await showDialog<bool>(
          context: context,
          builder: (_) => _InvitationDialog(
            auth: widget.auth,
            account: widget.account,
            group: widget.group,
          ),
        );
        if (joined != true || !mounted) return;
      } else {
        final introduction = await showDialog<String>(
          context: context,
          builder: (_) => _ApplicationDialog(
            group: widget.group,
            requiredIntroduction: widget.auth.groups.introductionRequired,
          ),
        );
        if (introduction == null || !mounted) return;
        widget.auth.groups.requestJoin(
          groupId: widget.group.id,
          userId: widget.account.id,
          userName: widget.account.name,
          introduction: introduction,
        );
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => PopScope(
          canPop: false,
          child: AlertDialog(
            key: const ValueKey('group-application-complete'),
            title: Text(
              widget.group.locked ? '그룹에 가입되었어요' : '신청이 완료되었어요',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            content: Text(
              widget.group.locked
                  ? '${widget.group.name}의 그룹원이 되었어요.\n별도의 승인 없이 바로 가입되었어요.'
                  : '그룹장에게 신청 알림을 보냈어요.\n승인되면 그룹원이 될 수 있어요.',
              style: const TextStyle(fontSize: 13, height: 1.8),
            ),
            actions: [
              TextButton(
                key: const ValueKey('group-complete-confirm'),
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        ),
      );
      if (mounted) {
        final navigation = MainNavigation.maybeOf(context);
        if (navigation != null) {
          navigation.select(0);
        } else {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } on StateError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.auth.groups,
    builder: (context, _) {
      final group = widget.group;
      final status = widget.auth.groups.joinStatus(group.id, widget.account.id);
      final member = status == GroupJoinStatus.member;
      final favorite = widget.auth.groups.isFavorite(
        group.id,
        widget.account.id,
      );
      final offers = widget.auth.groups.prepaidOffersFor(
        group.id,
        widget.account.id,
      );
      final stores = summarizePrepaidStores(offers);
      final label = switch (status) {
        GroupJoinStatus.pending => '승인 대기 중',
        GroupJoinStatus.member =>
          widget.auth.groups.isOwner(group.id, widget.account.id)
              ? '관리 중인 그룹'
              : '가입한 그룹',
        GroupJoinStatus.notApplied => '그룹 신청',
      };
      return AuthPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GroupPageHeader(
              title: member ? '소속 그룹' : '그룹 상세',
              backKey: 'group-detail-back',
              trailing: IconButton(
                key: const ValueKey('group-favorite-toggle'),
                tooltip: favorite ? '즐겨찾기 그룹 해제' : '즐겨찾기 그룹으로 지정',
                isSelected: favorite,
                icon: const Icon(
                  Icons.favorite_border_rounded,
                  color: HantuckColors.muted,
                ),
                selectedIcon: const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFE54958),
                ),
                onPressed: () => widget.auth.groups.toggleFavorite(
                  group.id,
                  widget.account.id,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            group.name,
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.7,
                            ),
                          ),
                          GroupTags(tags: group.tags.take(1).toList()),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        group.description,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.9,
                          color: HantuckColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                GroupThumbnail(group: group, size: 90),
              ],
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: HantuckColors.orangeSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    group.category,
                    style: const TextStyle(
                      fontSize: 11,
                      color: HantuckColors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GroupTags(tags: group.tags.skip(1).toList()),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              '그룹 코드 · ${group.code}',
              key: const ValueKey('group-public-code'),
              style: const TextStyle(fontSize: 12, color: HantuckColors.muted),
            ),
            if (member) ...[
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: HantuckColors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (!member)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF8F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      group.locked
                          ? Icons.lock_outline_rounded
                          : Icons.person_add_alt_1_rounded,
                      color: HantuckColors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        group.locked
                            ? '초대 전용 그룹이에요.\n그룹장이 전달한 초대 코드가 필요해요.'
                            : '신청 후 그룹장이 승인하면\n그룹원이 될 수 있어요.',
                        style: const TextStyle(fontSize: 12, height: 1.8),
                      ),
                    ),
                  ],
                ),
              ),
            if (!member) const SizedBox(height: 24),
            FilledButton.tonal(
              key: const ValueKey('group-sponsor'),
              onPressed: _sponsor,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: HantuckColors.orangeSoft,
                foregroundColor: HantuckColors.orange,
              ),
              child: const Text('후원하기'),
            ),
            if (!member) ...[
              const SizedBox(height: 12),
              FilledButton(
                key: const ValueKey('group-apply'),
                onPressed: status == GroupJoinStatus.notApplied && !_working
                    ? _apply
                    : null,
                child: Text(label),
              ),
              const SizedBox(height: 12),
              Text(
                group.locked
                    ? '초대 코드는 검색에 쓰는 그룹 코드와 달라요.'
                    : '자기소개는 100자 이내로 작성할 수 있어요.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.7,
                  color: HantuckColors.muted,
                ),
              ),
            ] else ...[
              const SizedBox(height: 28),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '이용 가능한 선결제 가게',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${stores.length}개',
                    style: const TextStyle(
                      fontSize: 12,
                      color: HantuckColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (offers.isEmpty)
                Container(
                  key: const ValueKey('group-empty-prepaid-stores'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 30,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF8F5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        size: 35,
                        color: HantuckColors.muted,
                      ),
                      SizedBox(height: 14),
                      Text(
                        '이용 가능한 선결제 가게가 없어요',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
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
                  now: widget.auth.groups.currentTime,
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => StoreDetailScreen(
                        auth: widget.auth,
                        account: widget.account,
                        store: widget.auth.stores.store(summary.storeId),
                        groupId: summary.groupId,
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

class _ApplicationDialog extends StatefulWidget {
  const _ApplicationDialog({
    required this.group,
    required this.requiredIntroduction,
  });
  final DemoGroup group;
  final bool requiredIntroduction;
  @override
  State<_ApplicationDialog> createState() => _ApplicationDialogState();
}

class _ApplicationDialogState extends State<_ApplicationDialog> {
  final _intro = TextEditingController();
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    key: const ValueKey('group-application-dialog'),
    insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
    title: Text(
      '${widget.group.name} 신청',
      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
    ),
    content: SizedBox(
      width: 340,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '자기소개 (${widget.requiredIntroduction ? '필수' : '선택'})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 9),
              TextFormField(
                key: const ValueKey('group-introduction'),
                controller: _intro,
                minLines: 3,
                maxLines: 4,
                maxLength: 100,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                style: const TextStyle(fontSize: 13, height: 1.6),
                decoration: const InputDecoration(
                  hintText: '그룹장에게 간단히 자신을 소개해 주세요.',
                ),
                validator: (value) =>
                    widget.requiredIntroduction &&
                        (value == null || value.trim().isEmpty)
                    ? '자기소개를 작성해 주세요.'
                    : null,
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const ValueKey('group-request-submit'),
                onPressed: () {
                  if (_form.currentState!.validate()) {
                    Navigator.of(context).pop(_intro.text.trim());
                  }
                },
                child: const Text('신청하기'),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        key: const ValueKey('group-request-cancel'),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('취소'),
      ),
    ],
  );
}

class _InvitationDialog extends StatefulWidget {
  const _InvitationDialog({
    required this.auth,
    required this.account,
    required this.group,
  });
  final DemoAuthStore auth;
  final DemoAccount account;
  final DemoGroup group;
  @override
  State<_InvitationDialog> createState() => _InvitationDialogState();
}

class _InvitationDialogState extends State<_InvitationDialog> {
  final _code = TextEditingController();
  String? _error;
  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _join() {
    try {
      widget.auth.groups.joinWithInvitation(
        groupId: widget.group.id,
        userId: widget.account.id,
        code: _code.text,
      );
      Navigator.of(context).pop(true);
    } on StateError catch (error) {
      setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    key: const ValueKey('group-invitation-dialog'),
    insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
    title: const Text(
      '초대 코드 입력',
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    ),
    content: SizedBox(
      width: 340,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '그룹장이 전달한 초대 코드를 입력해 주세요.\n코드가 확인되면 바로 그룹원이 돼요.',
              style: TextStyle(
                fontSize: 12,
                height: 1.8,
                color: HantuckColors.muted,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              key: const ValueKey('group-invite-code'),
              controller: _code,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _join(),
              decoration: InputDecoration(
                hintText: '초대 코드 6자리',
                errorText: _error,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              key: const ValueKey('group-invite-submit'),
              onPressed: _join,
              child: const Text('초대 코드로 가입하기'),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        key: const ValueKey('group-invite-cancel'),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('취소'),
      ),
    ],
  );
}
