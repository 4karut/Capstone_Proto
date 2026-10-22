import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../ui.dart';
import 'history.dart';
import 'qr.dart';

class MerchantPage extends StatefulWidget {
  const MerchantPage({super.key});
  @override
  State<MerchantPage> createState() => _MerchantPageState();
}

class _MerchantPageState extends State<MerchantPage> {
  String shopId = 's1';
  @override
  Widget build(BuildContext context) {
    final s = storeOf(context);
    if (!s.merchantAccess) {
      return const PageFrame(
        title: '가게 관리',
        child: EmptyState('가게 권한이 필요해요', '통합 데모 계정에서 체험할 수 있어요.'),
      );
    }
    final shop = s.shop(shopId), now = DateTime.now();
    final active = s.benefits
        .where((b) => b.shopId == shopId && b.state == 'active')
        .toList();
    final usages = s.usages.where((u) => u.shopId == shopId).toList();
    final today = usages
        .where((u) => dateLabel(u.date) == dateLabel(now))
        .fold(0, (n, u) => n + u.applied);
    return PageFrame(
      title: '사장님 · 가게 관리',
      child: paddedList([
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: shopId,
          decoration: const InputDecoration(labelText: '관리할 가게 · 통합 데모 권한'),
          items: s.shops
              .map((v) => DropdownMenuItem(value: v.id, child: Text(v.name)))
              .toList(),
          onChanged: (v) => setState(() => shopId = v!),
        ),
        SectionTitle('${shop.name}의 오늘', subtitle: '작은 마음이 쌓이는 우리 가게'),
        Surface(
          child: Column(
            children: [
              InfoRow(
                '진행 중인 선결제 총액',
                won(active.fold(0, (n, b) => n + b.total)),
              ),
              InfoRow(
                '남은 공동 잔액',
                won(active.fold(0, (n, b) => n + b.remaining)),
                accent: true,
              ),
              InfoRow('오늘 확인된 사용액', won(today)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Primary(
          'QR 확인 · 사용 처리',
          icon: Icons.qr_code_scanner,
          onTap: () => open(context, MerchantScanPage(shopId: shopId)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => open(context, SettlementPage(shopId: shopId)),
          icon: const Icon(Icons.account_balance_wallet_outlined, size: 19),
          label: const Padding(
            padding: EdgeInsets.all(12),
            child: Text('정산 관리'),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.edit_note_rounded),
          title: const Text('가게 정보 · 메뉴 관리', style: TextStyle(fontSize: 14)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => open(context, EditShopPage(shopId: shopId)),
        ),
        const SectionTitle('공동체별 선결제'),
        if (active.isEmpty)
          const EmptyState('진행 중인 한턱이 없어요', '새로운 마음이 도착하면 여기에 표시돼요.'),
        ...active.map(
          (b) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Surface(
              padding: const EdgeInsets.all(5),
              child: ListTile(
                title: Text(
                  s.group(b.communityId).name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '1인 ${won(b.limit)} · ~ ${shortDate(b.expiresAt)}',
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
                trailing: Text(
                  won(b.remaining),
                  style: const TextStyle(
                    color: coral,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () => open(context, DonationPage(id: b.id)),
              ),
            ),
          ),
        ),
        const SectionTitle('확인된 거래'),
        if (usages.isEmpty)
          const EmptyState('오늘의 첫 손님을 기다려요', '승인 완료된 거래가 표시됩니다.'),
        ...usages.map((u) => UsageTile(u)),
        note('운영 현황은 데모 데이터와 이 기기에서 완료한 거래를 기준으로 표시합니다.'),
      ]),
    );
  }
}

class MerchantScanPage extends StatefulWidget {
  final String shopId;
  const MerchantScanPage({super.key, required this.shopId});
  @override
  State<MerchantScanPage> createState() => _MerchantScanPageState();
}

class _MerchantScanPageState extends State<MerchantScanPage> {
  final code = TextEditingController();
  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = storeOf(context), r = storeOf(context).request;
    final current = r != null && s.benefit(r.benefitId).shopId == widget.shopId
        ? r
        : null;
    return PageFrame(
      title: 'QR 확인',
      child: paddedList([
        const SectionTitle('손님의 QR을 확인해 주세요'),
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: const Color(0xFFEDF3EB),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Center(
            child: Icon(Icons.qr_code_scanner, size: 100, color: green),
          ),
        ),
        note('카메라 스캔은 후속 연동 범위입니다. 현재 기기의 QR을 불러오거나 QR 문자열을 입력해 확인하는 데모예요.'),
        const FieldLabel('QR 문자열 입력'),
        TextField(
          controller: code,
          decoration: const InputDecoration(hintText: 'hantteok-demo:QR…'),
        ),
        const SizedBox(height: 16),
        Primary(
          '입력한 QR 확인',
          onTap: () {
            final value = code.text.trim().replaceFirst('hantteok-demo:', '');
            if (current == null ||
                value != current.id ||
                current.expired ||
                current.status != 'issued') {
              toast(context, '현재 가게의 유효한 QR이 아니에요.');
              return;
            }
            open(context, MerchantOrderPage(request: current));
          },
        ),
        const SizedBox(height: 12),
        if (current != null && current.status == 'issued' && !current.expired)
          OutlinedButton(
            onPressed: () => open(context, MerchantOrderPage(request: current)),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Text('현재 기기의 QR 불러오기'),
            ),
          ),
        if (current != null && current.status == 'pending' && !current.expired)
          OutlinedButton(
            onPressed: () => open(context, QrPage(request: current)),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Text('이용자 역할로 승인 화면 열기'),
            ),
          ),
        if (current == null || current.expired)
          note('홈 → 혜택 상세 → 혜택 사용하기에서 사용 QR을 먼저 발급해 주세요.'),
      ]),
    );
  }
}

class SettlementPage extends StatelessWidget {
  final String shopId;
  const SettlementPage({super.key, required this.shopId});
  @override
  Widget build(BuildContext context) {
    final s = storeOf(context);
    final usages = s.usages.where((u) => u.shopId == shopId).toList();
    final total = usages.fold(0, (n, u) => n + u.applied),
        done = usages
            .where((u) => s.settled.contains(u.id))
            .fold(0, (n, u) => n + u.applied);
    final days = usages.map((u) => dateLabel(u.date)).toSet();
    return PageFrame(
      title: '정산 관리',
      child: paddedList([
        SectionTitle(s.shop(shopId).name, subtitle: '실제 사용이 확인된 혜택 적용액 기준'),
        Surface(
          child: Column(
            children: [
              InfoRow('정산 대상 누적 금액', won(total)),
              InfoRow('정산 대기', won(total - done), accent: true),
              InfoRow('정산 완료', won(done)),
            ],
          ),
        ),
        note(
          '최초 선결제 금액 전체가 아닌, 이용자가 승인한 사용 금액을 정산 대상으로 계산합니다. 데모에서 수수료·송금은 처리하지 않습니다.',
        ),
        const SectionTitle('기간별 정산 목록'),
        if (days.isEmpty)
          const EmptyState('정산 대상 거래가 없어요', '사용 완료된 거래가 생기면 정산을 확인할 수 있어요.'),
        ...days.map((day) {
          final list = usages.where((u) => dateLabel(u.date) == day).toList();
          final complete = list.every((u) => s.settled.contains(u.id));
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Surface(
              padding: const EdgeInsets.all(6),
              child: ListTile(
                title: Text(day),
                subtitle: Text(
                  '${list.length}건 · ${complete ? '정산 완료' : '정산 대기'}',
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
                trailing: Text(
                  won(list.fold(0, (n, u) => n + u.applied)),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () => open(
                  context,
                  SettlementDetailPage(shopId: shopId, day: day),
                ),
              ),
            ),
          );
        }),
      ]),
    );
  }
}

class SettlementDetailPage extends StatelessWidget {
  final String shopId, day;
  const SettlementDetailPage({
    super.key,
    required this.shopId,
    required this.day,
  });
  @override
  Widget build(BuildContext context) {
    final s = storeOf(context);
    final list = s.usages
        .where((u) => u.shopId == shopId && dateLabel(u.date) == day)
        .toList();
    final complete = list.every((u) => s.settled.contains(u.id));
    return PageFrame(
      title: '정산 상세',
      child: paddedList([
        SectionTitle(day),
        Surface(
          child: Column(
            children: [
              InfoRow(
                '정산 금액',
                won(list.fold(0, (n, u) => n + u.applied)),
                accent: true,
              ),
              InfoRow('상태', complete ? '정산 완료' : '정산 대기'),
              InfoRow('포함 거래', '${list.length}건'),
              const InfoRow('취소·조정 금액', '0원'),
            ],
          ),
        ),
        const SectionTitle('포함된 거래'),
        ...list.map((u) => UsageTile(u)),
        if (!complete)
          OutlinedButton(
            onPressed: () {
              s.settled.addAll(list.map((u) => u.id));
              s.commit();
            },
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Text('데모 · 정산 완료 체험'),
            ),
          ),
        note(
          '실제 계좌 이체는 발생하지 않습니다. 선결제 잔액 환불은 미사용 금액을 대상으로 하므로 완료된 사용 거래의 정산에는 포함되지 않습니다.',
        ),
        TextButton(
          onPressed: () =>
              open(context, SupportPage(targetId: 'SET-$shopId-$day')),
          child: const Text('이 정산에 문의하기'),
        ),
      ]),
    );
  }
}

class EditShopPage extends StatefulWidget {
  final String shopId;
  const EditShopPage({super.key, required this.shopId});
  @override
  State<EditShopPage> createState() => _EditShopPageState();
}

class _EditShopPageState extends State<EditShopPage> {
  final description = TextEditingController(), hours = TextEditingController();
  final List<TextEditingController> prices = [], names = [];
  bool loaded = false;
  @override
  void dispose() {
    description.dispose();
    hours.dispose();
    for (final c in [...prices, ...names]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = storeOf(context), shop = storeOf(context).shop(widget.shopId);
    if (!loaded) {
      description.text = shop.description;
      hours.text = shop.hours;
      for (final m in shop.menu) {
        names.add(TextEditingController(text: m.name));
        prices.add(TextEditingController(text: '${m.price}'));
      }
      loaded = true;
    }
    return PageFrame(
      title: '가게 정보 관리',
      bottom: Primary(
        '변경사항 저장',
        onTap: () {
          if (description.text.trim().isEmpty ||
              hours.text.trim().isEmpty ||
              names.any((c) => c.text.trim().isEmpty) ||
              prices.any((c) => (int.tryParse(c.text) ?? 0) <= 0)) {
            toast(context, '소개, 영업시간, 메뉴명과 올바른 가격을 입력해 주세요.');
            return;
          }
          if (names.map((c) => c.text.trim()).toSet().length != names.length) {
            toast(context, '메뉴명이 중복되지 않도록 입력해 주세요.');
            return;
          }
          shop.description = description.text.trim();
          shop.hours = hours.text.trim();
          shop.menu = List.generate(
            names.length,
            (i) => MenuItem(names[i].text.trim(), int.parse(prices[i].text)),
          );
          s.commit();
          Navigator.pop(context);
        },
      ),
      child: paddedList([
        SectionTitle(shop.name),
        const FieldLabel('가게 소개'),
        TextField(controller: description, maxLines: 3, maxLength: 200),
        const FieldLabel('영업시간'),
        TextField(controller: hours),
        const SectionTitle('메뉴와 가격'),
        ...List.generate(
          prices.length,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: names[i],
                    decoration: const InputDecoration(labelText: '메뉴명'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: prices[i],
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(suffixText: '원'),
                  ),
                ),
              ],
            ),
          ),
        ),
        note('메뉴명을 변경하면 기존 선결제에서 지정한 메뉴와 달라질 수 있어요. 기존 혜택의 이용 조건도 함께 확인해 주세요.'),
      ]),
    );
  }
}
