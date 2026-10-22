import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models.dart';
import '../ui.dart';
import 'history.dart';

class QrPage extends StatefulWidget {
  final UseRequest request;
  const QrPage({super.key, required this.request});
  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {
  late UseRequest r;
  late Timer timer;
  @override
  void initState() {
    super.initState();
    r = widget.request;
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = storeOf(context), b = storeOf(context).benefit(r.benefitId);
    final valid = !r.expired && !['cancelled', 'completed'].contains(r.status);
    final applied = min(s.allowance(b), r.orderAmount);
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && r.status != 'completed') s.cancelRequest(r);
      },
      child: PageFrame(
        title: '한턱 사용하기',
        bottom: r.status == 'pending' && valid
            ? Primary(
                '내용 확인 · 사용 승인',
                onTap: () {
                  try {
                    final u = s.approve(r);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) =>
                            UsagePage(usage: u, justCompleted: true),
                      ),
                    );
                  } on StateError catch (e) {
                    toast(context, e.message.toString());
                  }
                },
              )
            : Primary(
                valid
                    ? '가게의 확인을 기다리고 있어요'
                    : r.status == 'completed'
                    ? '사용 완료'
                    : 'QR 다시 발급하기',
                onTap: valid || r.status == 'completed'
                    ? null
                    : () {
                        try {
                          setState(() => r = s.issue(b));
                        } on StateError catch (e) {
                          toast(context, e.message.toString());
                        }
                      },
              ),
        child: paddedList([
          const SizedBox(height: 20),
          Text(
            s.shop(b.shopId).name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 9),
          Text(
            s.group(b.communityId).name,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 25),
          Surface(
            child: Column(
              children: [
                Text(
                  valid ? '이 QR을 가게에 보여주세요' : 'QR이 만료되었거나 처리되었어요',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 15),
                Opacity(
                  opacity: valid ? 1 : .15,
                  child: QrImageView(
                    data: 'hantteok-demo:${r.id}',
                    size: 220,
                    backgroundColor: Colors.white,
                    semanticsLabel: '한턱 데모 사용 QR',
                  ),
                ),
                const SizedBox(height: 14),
                Pill(
                  valid
                      ? '남은 시간  ${r.seconds ~/ 60}:${(r.seconds % 60).toString().padLeft(2, '0')}'
                      : '만료 · 재발급 필요',
                  color: valid ? coral : muted,
                ),
                const SizedBox(height: 14),
                Text(
                  '개인 이용 가능 금액 ${won(s.allowance(b))}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  r.id,
                  style: const TextStyle(fontSize: 10, color: muted),
                ),
              ],
            ),
          ),
          if (r.status == 'pending' && valid) ...[
            const SectionTitle('가게에서 확인을 요청했어요'),
            Surface(
              color: const Color(0xFFEDF3EB),
              child: Column(
                children: [
                  InfoRow('주문 메뉴', r.menu),
                  InfoRow('주문 금액', won(r.orderAmount)),
                  InfoRow('혜택 적용액', won(applied), accent: true),
                  const Divider(),
                  InfoRow(
                    '현장 추가 결제',
                    won(r.orderAmount - applied),
                    accent: true,
                  ),
                ],
              ),
            ),
            note('내용을 확인한 뒤 승인해 주세요. 추가 결제는 가게에서 직접 진행해요.'),
            TextButton(
              onPressed: () {
                s.cancelRequest(r);
                toast(context, '사용 요청을 취소했어요. 잔액은 차감되지 않았어요.');
              },
              child: const Text('이 요청 취소'),
            ),
          ] else if (valid) ...[
            note('가게에서 메뉴와 금액을 입력하면 여기에 표시돼요. 내 승인 전에는 공동 잔액이 차감되지 않아요.'),
            if (s.merchantAccess)
              OutlinedButton.icon(
                onPressed: () => open(context, MerchantOrderPage(request: r)),
                icon: const Icon(Icons.storefront_outlined, size: 19),
                label: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    '가게 역할로 QR 확인 체험',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            note(
              '데모에서는 같은 기기에서 가게 역할로 전환해 주문 요청을 만들 수 있어요. 실제 카메라 스캔·서버 검증은 연결하지 않았습니다.',
            ),
          ],
        ]),
      ),
    );
  }
}

class MerchantOrderPage extends StatefulWidget {
  final UseRequest request;
  const MerchantOrderPage({super.key, required this.request});
  @override
  State<MerchantOrderPage> createState() => _MerchantOrderPageState();
}

class _MerchantOrderPageState extends State<MerchantOrderPage> {
  String? menu;
  final amount = TextEditingController();
  bool sent = false;
  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = storeOf(context),
        r = widget.request,
        b = storeOf(context).benefit(widget.request.benefitId);
    final shop = s.shop(b.shopId);
    final eligible = shop.menu
        .where((m) => b.menus.isEmpty || b.menus.contains(m.name))
        .toList();
    if (menu == null && eligible.isNotEmpty) {
      menu = eligible.first.name;
      amount.text = eligible.first.price.toString();
    }
    final total = int.tryParse(amount.text) ?? 0,
        applied = min(s.allowance(b), int.tryParse(amount.text) ?? 0);
    return PageFrame(
      title: '가게 · 주문 확인',
      bottom: Primary(
        sent || r.status == 'pending' ? '이용자 승인 대기 중' : '이용자에게 확인 요청',
        onTap: sent || r.status != 'issued' || eligible.isEmpty
            ? null
            : () {
                try {
                  s.submitOrder(r, menu!, total);
                  setState(() => sent = true);
                  toast(context, '이용자 확인 요청을 보냈어요.');
                  Navigator.pop(context);
                } on StateError catch (e) {
                  toast(context, e.message.toString());
                }
              },
      ),
      child: paddedList([
        const SectionTitle('QR 확인 완료', subtitle: '공동체 인증과 이용 조건을 확인했어요.'),
        Surface(
          child: Column(
            children: [
              InfoRow('가게', shop.name),
              InfoRow('공동체', s.group(b.communityId).name),
              InfoRow('개인 사용 가능 금액', won(s.allowance(b)), accent: true),
              InfoRow(
                'QR 상태',
                r.expired
                    ? '만료'
                    : r.status == 'issued'
                    ? '유효'
                    : '이미 요청됨',
              ),
            ],
          ),
        ),
        if (eligible.isEmpty)
          const EmptyState('사용 가능한 메뉴가 없어요', '가게 메뉴가 변경되었어요. 다른 혜택을 이용해 주세요.')
        else ...[
          const FieldLabel('제공할 메뉴'),
          DropdownButtonFormField<String>(
            initialValue: menu,
            items: eligible
                .map(
                  (m) => DropdownMenuItem(value: m.name, child: Text(m.name)),
                )
                .toList(),
            onChanged: r.status != 'issued'
                ? null
                : (v) => setState(() {
                    menu = v;
                    amount.text = eligible
                        .firstWhere((m) => m.name == v)
                        .price
                        .toString();
                  }),
          ),
          const FieldLabel('실제 주문 금액'),
          TextField(
            controller: amount,
            enabled: r.status == 'issued',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(suffixText: '원'),
            onChanged: (_) => setState(() {}),
          ),
          const SectionTitle('적용 금액 미리 보기'),
          Surface(
            color: const Color(0xFFEDF3EB),
            child: Column(
              children: [
                InfoRow('혜택 적용액', won(applied), accent: true),
                InfoRow('현장 추가 결제', won(max(0, total - applied)), accent: true),
              ],
            ),
          ),
        ],
        note('QR을 확인하는 것만으로 잔액을 차감하지 않아요. 이용자 승인 후에 거래가 완료됩니다.'),
      ]),
    );
  }
}
