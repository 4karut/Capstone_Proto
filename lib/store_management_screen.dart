import 'server_widgets.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'demo_auth_store.dart';
import 'donation_notifications_screen.dart';
import 'donation_store.dart';
import 'group_widgets.dart';
import 'prepaid_store.dart';
import 'store_catalog.dart';
import 'store_detail_screen.dart';
import 'store_owner_prepaid_screen.dart';
import 'store_widgets.dart';
import 'theme.dart';
import 'store_cashier_screen.dart';
import 'prepaid_usage_screen.dart';

class StoreManagementSelectionScreen extends StatelessWidget {
  const StoreManagementSelectionScreen({
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
      final stores = auth.stores.ownedStores(account.id);
      return AuthPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GroupPageHeader(
              title: '관리할 가게 선택',
              backKey: 'store-management-selection-back',
            ),
            const SizedBox(height: 24),
            Text(
              '내 가게 ${stores.length}개',
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 22),
            ...stores.map(
              (store) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Material(
                  color: Colors.white,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: HantuckColors.border),
                  ),
                  child: InkWell(
                    key: ValueKey('owned-store-${store.id}'),
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => StoreManagementScreen(
                          auth: auth,
                          account: account,
                          storeId: store.id,
                        ),
                      ),
                    ),
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
                                const SizedBox(height: 8),
                                Text(
                                  store.address,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    height: 1.7,
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
              ),
            ),
          ],
        ),
      );
    },
  );
}

class StoreManagementScreen extends StatelessWidget {
  const StoreManagementScreen({
    required this.auth,
    required this.account,
    required this.storeId,
    super.key,
  });
  final DemoAuthStore auth;
  final DemoAccount account;
  final String storeId;

  Future<void> _thumbnail(BuildContext context) async {
    final current = auth.stores.store(storeId);
    final picked = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text(
          '가게 썸네일 선택',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        children: [
          for (
            var index = 0;
            index < DemoStoreCatalog.thumbnailChoices.length;
            index++
          )
            ListTile(
              key: ValueKey('store-thumbnail-choice-$index'),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  DemoStoreCatalog.thumbnailChoices[index],
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(
                ['따뜻한 식사', '캠퍼스', '산책길'][index],
                style: const TextStyle(fontSize: 14),
              ),
              trailing:
                  current.thumbnail == DemoStoreCatalog.thumbnailChoices[index]
                  ? const Icon(Icons.check_rounded, color: HantuckColors.orange)
                  : null,
              onTap: () =>
                  Navigator.of(context)
                      .pop(DemoStoreCatalog.thumbnailChoices[index]),
            ),
        ],
      ),
    );
    if (picked == null || !context.mounted) return;
    await remoteUiAction(
      context,
      () => auth.stores.updateThumbnailRemote(
        storeId: storeId,
        ownerId: account.id,
        thumbnail: picked,
      ),
    );
  }

  Future<void> _removeMenu(BuildContext context, int index) async {
    final item = auth.stores.store(storeId).menu[index];
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('메뉴 삭제'),
        content: Text('${item.name} 메뉴를 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            key: const ValueKey('store-menu-remove-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (remove == true) {
      await remoteUiAction(
        context,
        () => auth.stores.removeMenuRemote(
          storeId: storeId,
          ownerId: account.id,
          index: index,
        ),
      );
    }
  }

  void _editMenu(BuildContext context, [int? index]) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => StoreMenuEditScreen(
            auth: auth,
            account: account,
            storeId: storeId,
            index: index,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([auth.stores, auth.donations, auth.usage]),
    builder: (context, _) {
      if (!auth.stores.ownsStore(storeId, account.id)) {
        return const AuthPage(
          child: Column(
            children: [
              GroupPageHeader(title: '가게 관리', backKey: 'store-management-back'),
              SizedBox(height: 24),
              Text(
                '본인 가게만 관리할 수 있어요.',
                key: ValueKey('store-management-denied'),
              ),
            ],
          ),
        );
      }
      final store = auth.stores.store(storeId);
      final notices = auth.donations
          .notificationsForStoreOwner(account.id)
          .where((donation) => donation.storeId == storeId)
          .length;
      return AuthPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GroupPageHeader(
              title: '가게 관리',
              backKey: 'store-management-back',
              trailing: TextButton(
                key: const ValueKey('store-manage-prepaid'),
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => StoreOwnerPrepaidScreen(
                      auth: auth,
                      account: account,
                      storeId: storeId,
                    ),
                  ),
                ),
                child: const Text(
                  '선결제 관리',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                store.thumbnail,
                height: 170,
                fit: BoxFit.cover,
                semanticLabel: '${store.name} 썸네일',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey('store-manage-thumbnail'),
              onPressed: () => _thumbnail(context),
              icon: const Icon(Icons.photo_outlined, size: 20),
              label: const Text('썸네일 변경'),
            ),
            const SizedBox(height: 22),
            Text(
              store.name,
              key: const ValueKey('managed-store-name'),
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              '${store.category}\n${store.address}',
              style: const TextStyle(
                fontSize: 12,
                height: 1.8,
                color: HantuckColors.muted,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const ValueKey('store-manage-cashier'),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => StoreCashierScreen(
                    auth: auth,
                    account: account,
                    storeId: storeId,
                  ),
                ),
              ),
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('QR 결제 처리'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey('store-manage-usage-notifications'),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => UsageNotificationsScreen(
                    auth: auth,
                    account: account,
                    forStore: true,
                    storeId: storeId,
                  ),
                ),
              ),
              icon: const Icon(Icons.receipt_long_outlined),
              label: Text(
                '선결제 사용 알림 ${auth.usage.notificationsForStoreOwner(account.id, storeId: storeId).length}건',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              key: const ValueKey('store-manage-notifications'),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => DonationNotificationsScreen(
                    auth: auth,
                    account: account,
                    forStore: true,
                    storeId: storeId,
                  ),
                ),
              ),
              icon: const Icon(Icons.notifications_none_rounded),
              label: Text('선결제 알림 $notices건'),
            ),
            const SizedBox(height: 12),
            TextButton(
              key: const ValueKey('store-manage-preview'),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => StoreDetailScreen(
                    auth: auth,
                    account: account,
                    store: store,
                  ),
                ),
              ),
              child: const Text('가게 미리보기'),
            ),
            const SizedBox(height: 20),
            const Text(
              '판매 메뉴 관리',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (store.menu.isEmpty)
              const DiscoveryEmptyState(
                key: ValueKey('store-manage-menu-empty'),
                icon: Icons.restaurant_menu_rounded,
                title: '등록된 메뉴가 없어요',
                description: '메뉴 이름과 가격을 등록해 주세요.',
              ),
            for (var index = 0; index < store.menu.length; index++)
              Container(
                key: ValueKey('managed-menu-$index'),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: HantuckColors.border),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (store.menu[index].recommended)
                      const Text(
                        '대표 메뉴',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: HantuckColors.orange,
                        ),
                      ),
                    const SizedBox(height: 5),
                    Text(
                      store.menu[index].name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatWon(store.menu[index].price),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (store.menu[index].description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        store.menu[index].description,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.7,
                          color: HantuckColors.muted,
                        ),
                      ),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          key: ValueKey('store-menu-edit-$index'),
                          onPressed: () => _editMenu(context, index),
                          child: const Text('수정'),
                        ),
                        IconButton(
                          key: ValueKey('store-menu-remove-$index'),
                          tooltip: '메뉴 삭제',
                          onPressed: () => _removeMenu(context, index),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 21,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const ValueKey('store-menu-add'),
              onPressed: () => _editMenu(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('메뉴 추가'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class StoreMenuEditScreen extends StatefulWidget {
  const StoreMenuEditScreen({
    required this.auth,
    required this.account,
    required this.storeId,
    this.index,
    super.key,
  });
  final DemoAuthStore auth;
  final DemoAccount account;
  final String storeId;
  final int? index;
  @override
  State<StoreMenuEditScreen> createState() => _StoreMenuEditScreenState();
}

class _StoreMenuEditScreenState extends State<StoreMenuEditScreen> {
  final _form = GlobalKey<FormState>();
  late final StoreMenuItem? _item = widget.index == null
      ? null
      : widget.auth.stores.store(widget.storeId).menu[widget.index!];
  late final _name = TextEditingController(text: _item?.name ?? '');
  late final _price = TextEditingController(
    text: _item?.price.toString() ?? '',
  );
  late final _description = TextEditingController(
    text: _item?.description ?? '',
  );
  late bool _recommended = _item?.recommended ?? false;
  bool _submitted = false;
  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    if (!_form.currentState!.validate()) return;
    try {
      await widget.auth.stores.saveMenuRemote(
        storeId: widget.storeId,
        ownerId: widget.account.id,
        index: widget.index,
        item: StoreMenuItem(
          name: _name.text,
          description: _description.text,
          price: parseDonationAmount(_price.text)!,
          recommended: _recommended,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) => AuthPage(
    child: Form(
      key: _form,
      autovalidateMode: _submitted
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GroupPageHeader(
            title: widget.index == null ? '메뉴 추가' : '메뉴 수정',
            backKey: 'store-menu-form-back',
          ),
          const SizedBox(height: 24),
          Text(
            widget.auth.stores.store(widget.storeId).name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: HantuckColors.orange,
            ),
          ),
          const SizedBox(height: 25),
          TextFormField(
            key: const ValueKey('store-menu-name'),
            controller: _name,
            maxLength: 50,
            decoration: const InputDecoration(labelText: '메뉴 이름'),
            validator: (value) => value == null || value.trim().isEmpty
                ? '메뉴 이름을 입력해 주세요.'
                : null,
          ),
          const SizedBox(height: 20),
          TextFormField(
            key: const ValueKey('store-menu-price'),
            controller: _price,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: '가격', suffixText: '원'),
            validator: (value) => parseDonationAmount(value ?? '') == null
                ? '1원 이상의 가격을 입력해 주세요.'
                : null,
          ),
          const SizedBox(height: 23),
          TextFormField(
            key: const ValueKey('store-menu-description'),
            controller: _description,
            maxLength: 150,
            maxLines: 3,
            decoration: const InputDecoration(labelText: '메뉴 설명 (선택)'),
          ),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              key: const ValueKey('store-menu-recommended'),
              contentPadding: EdgeInsets.zero,
              title: const Text('대표 메뉴', style: TextStyle(fontSize: 14)),
              value: _recommended,
              onChanged: (value) => setState(() => _recommended = value),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const ValueKey('store-menu-save'),
            onPressed: _save,
            child: const Text('저장하기'),
          ),
        ],
      ),
    ),
  );
}
