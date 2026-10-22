import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../ui.dart';
import 'history.dart';

class GivePage extends StatefulWidget {
  final String? shopId;
  const GivePage({super.key, this.shopId});
  @override
  State<GivePage> createState() => _GivePageState();
}

class _GivePageState extends State<GivePage> {
  final form = GlobalKey<FormState>();
  final amount = TextEditingController(text: '50000'),
      limit = TextEditingController(text: '5000'),
      message = TextEditingController();
  String? shopId, communityId;
  String identity = '닉네임';
  DateTime expiry = DateTime.now().add(const Duration(days: 30));
  Set<String> menus = {};
  @override
  void dispose() {
    amount.dispose();
    limit.dispose();
    message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = storeOf(context);
    shopId ??= widget.shopId ?? s.shops.first.id;
    communityId ??= s.communityId;
    final shop = s.shop(shopId!);
    return PageFrame(
      title: '한턱 쏘기',
      bottom: Primary(
        '마음 확인하기',
        onTap: () {
          if (!form.currentState!.validate()) return;
          final total = int.parse(amount.text),
              perPerson = int.parse(limit.text);
          if (perPerson > total) {
            toast(context, '1인당 한도는 총금액 이하로 입력해 주세요.');
            return;
          }
          final draft = GiveDraft(
            shopId!,
            communityId!,
            total,
            perPerson,
            expiry,
            identity == '익명'
                ? '익명의 이웃'
                : identity == '실명'
                ? s.realName
                : s.nickname,
            message.text.trim(),
            menus.toList(),
          );
          open(context, PaymentPage(draft: draft));
        },
      ),
      child: Form(
        key: form,
        child: paddedList([
          const SectionTitle(
            '누군가의 하루에\n따뜻한 한 끼를 선물해요',
            subtitle: '한턱의 금액과 이용 조건을 정해 주세요.',
          ),
          const FieldLabel('1. 마음을 전할 가게'),
          DropdownButtonFormField<String>(
            initialValue: shopId,
            items: s.shops
                .map((v) => DropdownMenuItem(value: v.id, child: Text(v.name)))
                .toList(),
            onChanged: (v) => setState(() {
              shopId = v;
              menus.clear();
            }),
          ),
          const FieldLabel('2. 함께할 공동체'),
          DropdownButtonFormField<String>(
            initialValue: communityId,
            items: communities
                .map((v) => DropdownMenuItem(value: v.id, child: Text(v.name)))
                .toList(),
            onChanged: (v) => setState(() => communityId = v),
          ),
          const FieldLabel('3. 한턱 금액'),
          TextFormField(
            controller: amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              suffixText: '원',
              hintText: '1,000원 이상',
            ),
            validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1000
                ? '1,000원 이상 입력해 주세요'
                : (int.tryParse(v!) ?? 0) > 10000000
                ? '데모에서는 최대 1,000만원까지 가능해요'
                : null,
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            children: [30000, 50000, 100000]
                .map(
                  (v) => ActionChip(
                    label: Text(won(v), style: const TextStyle(fontSize: 12)),
                    onPressed: () => setState(() => amount.text = v.toString()),
                  ),
                )
                .toList(),
          ),
          const FieldLabel('4. 이용 조건'),
          TextFormField(
            controller: limit,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: '1인당 전체 기간 사용 한도',
              suffixText: '원',
            ),
            validator: (v) =>
                (int.tryParse(v ?? '') ?? 0) <= 0 ? '0원보다 큰 한도를 입력해 주세요' : null,
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: expiry,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                helpText: '이용 종료일',
              );
              if (d != null) {
                setState(
                  () => expiry = DateTime(d.year, d.month, d.day, 23, 59, 59),
                );
              }
            },
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: Text('이용 종료일  ${dateLabel(expiry)}'),
          ),
          note('오늘부터 종료일 자정까지 이용할 수 있어요.'),
          const FieldLabel('사용 가능 메뉴'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: shop.menu
                .map(
                  (m) => FilterChip(
                    label: Text(m.name, style: const TextStyle(fontSize: 12)),
                    selected: menus.contains(m.name),
                    onSelected: (v) => setState(() {
                      v ? menus.add(m.name) : menus.remove(m.name);
                    }),
                  ),
                )
                .toList(),
          ),
          note(
            menus.isEmpty
                ? '선택하지 않으면 모든 메뉴에서 사용할 수 있어요.'
                : '${menus.length}개 메뉴에 혜택을 적용해요.',
          ),
          const FieldLabel('5. 공개할 이름'),
          SegmentedButton<String>(
            segments: [
              '익명',
              '닉네임',
              '실명',
            ].map((v) => ButtonSegment(value: v, label: Text(v))).toList(),
            selected: {identity},
            onSelectionChanged: (v) => setState(() => identity = v.first),
          ),
          note(
            '공개 이름: ${identity == '익명'
                ? '익명의 이웃'
                : identity == '실명'
                ? s.realName
                : s.nickname}',
          ),
          const FieldLabel('함께 전할 한마디'),
          TextField(
            controller: message,
            maxLines: 3,
            maxLength: 150,
            decoration: const InputDecoration(hintText: '든든하게 먹고, 오늘도 힘내요!'),
          ),
        ]),
      ),
    );
  }
}

class GiveDraft {
  final String shopId, communityId, donor, message;
  final int amount, limit;
  final DateTime expiry;
  final List<String> menus;
  GiveDraft(
    this.shopId,
    this.communityId,
    this.amount,
    this.limit,
    this.expiry,
    this.donor,
    this.message,
    this.menus,
  );
}

class PaymentPage extends StatefulWidget {
  final GiveDraft draft;
  const PaymentPage({super.key, required this.draft});
  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool agree = false, failure = false, busy = false, completed = false;
  String? error;
  @override
  Widget build(BuildContext context) {
    final d = widget.draft, s = storeOf(context);
    return PageFrame(
      title: '마음 확인하기',
      bottom: Primary(
        busy ? '마음을 전하고 있어요…' : '${won(d.amount)} 모의 결제',
        onTap: busy || completed
            ? null
            : () async {
                if (!agree) {
                  setState(() => error = '취소·잔액 처리 안내에 동의해 주세요.');
                  return;
                }
                setState(() {
                  busy = true;
                  error = null;
                });
                await Future<void>.delayed(const Duration(milliseconds: 600));
                if (!context.mounted) return;
                if (failure) {
                  setState(() {
                    busy = false;
                    error = '모의 결제에 실패했어요. 실패 체험을 끄고 다시 시도해 주세요.';
                  });
                  return;
                }
                try {
                  final b = s.pay(
                    shopId: d.shopId,
                    target: d.communityId,
                    amount: d.amount,
                    limit: d.limit,
                    expiry: d.expiry,
                    donor: d.donor,
                    message: d.message,
                    menus: d.menus,
                  );
                  setState(() {
                    completed = true;
                    busy = false;
                  });
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => PaymentDonePage(benefit: b),
                    ),
                  );
                } on StateError catch (e) {
                  setState(() {
                    busy = false;
                    error = e.message.toString();
                  });
                }
              },
      ),
      child: paddedList([
        const SectionTitle('이 마음으로 전할까요?', subtitle: '결제 전 한 번 더 확인해 주세요.'),
        ShopArt(s.shop(d.shopId), height: 150),
        const SizedBox(height: 20),
        Surface(
          child: Column(
            children: [
              InfoRow('가게', s.shop(d.shopId).name),
              InfoRow('대상 공동체', s.group(d.communityId).name),
              InfoRow('한턱 금액', won(d.amount), accent: true),
              const Divider(),
              InfoRow('1인당 사용 한도', won(d.limit)),
              InfoRow('이용 종료일', dateLabel(d.expiry)),
              InfoRow('메뉴', d.menus.isEmpty ? '모든 메뉴' : d.menus.join(', ')),
              InfoRow('공개 이름', d.donor),
            ],
          ),
        ),
        if (d.message.isNotEmpty) ...[
          const SectionTitle('함께 전할 메시지'),
          Text(d.message, style: const TextStyle(height: 1.8)),
        ],
        const SectionTitle('취소와 남은 잔액 안내'),
        const Text(
          '사용 후에는 남은 공동 잔액에 대해 환불을 신청할 수 있어요. 기간이 끝나도 잔액은 자동 기부되지 않아요.\n\n프로토타입에서는 신청 → 검토 중 → 처리 완료 흐름만 모의 처리하며, 실제 환불 범위와 지급 시점은 서비스 정책 확정 후 적용됩니다.',
          style: TextStyle(fontSize: 12, color: muted, height: 1.8),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: agree,
          onChanged: busy ? null : (v) => setState(() => agree = v!),
          title: const Text(
            '안내를 확인하고 모의 결제에 동의해요',
            style: TextStyle(fontSize: 12),
          ),
        ),
        const Divider(),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('결제 실패 체험', style: TextStyle(fontSize: 12)),
          value: failure,
          onChanged: busy ? null : (v) => setState(() => failure = v),
        ),
        note('실제 결제는 발생하지 않습니다. 성공한 경우에만 혜택이 생성됩니다.'),
        if (error != null)
          Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
      ]),
    );
  }
}

class PaymentDonePage extends StatelessWidget {
  final Benefit benefit;
  const PaymentDonePage({super.key, required this.benefit});
  @override
  Widget build(BuildContext context) => PageFrame(
    title: '한턱 도착',
    bottom: Primary(
      '선결제 내역 확인',
      onTap: () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => DonationPage(id: benefit.id)),
      ),
    ),
    child: paddedList([
      const SizedBox(height: 64),
      const Center(
        child: CircleAvatar(
          radius: 48,
          backgroundColor: Color(0xFFFFE8DD),
          child: Icon(Icons.favorite_rounded, color: coral, size: 43),
        ),
      ),
      const SizedBox(height: 30),
      const Text(
        '따뜻한 마음이\n잘 도착했어요!',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w900,
          height: 1.4,
        ),
      ),
      const SizedBox(height: 20),
      Text(
        '${storeOf(context).group(benefit.communityId).name}에\n${won(benefit.total)}의 한턱을 전했어요.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: muted, height: 1.8),
      ),
      const SizedBox(height: 30),
      const Center(child: Pill('모의 결제 완료')),
    ]),
  );
}
