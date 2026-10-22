import 'package:flutter/material.dart';

import '../models.dart';
import '../ui.dart';
import 'home.dart';
import 'account.dart';
import 'give.dart';
import 'qr.dart';
import 'history.dart';

class ShopPage extends StatelessWidget {
  final String id;
  const ShopPage({super.key, required this.id});
  @override
  Widget build(BuildContext context) {
    final s = storeOf(context);
    final shop = s.shop(id);
    final benefits = s.benefits
        .where((b) => b.shopId == id && b.state == 'active')
        .toList();
    return PageFrame(
      title: shop.name,
      bottom: Primary(
        '이 가게에 한턱 쏘기',
        icon: Icons.favorite_border,
        onTap: () => open(context, GivePage(shopId: id)),
      ),
      child: paddedList([
        ShopArt(shop, height: 215),
        const SizedBox(height: 23),
        Row(
          children: [
            Expanded(
              child: Text(
                shop.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 27,
                ),
              ),
            ),
            Pill(shop.category),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          shop.description,
          style: const TextStyle(color: muted, fontSize: 13, height: 1.8),
        ),
        const SizedBox(height: 14),
        InfoRow('위치', shop.address),
        InfoRow('영업시간', shop.hours),
        const SectionTitle('정성껏 준비한 메뉴'),
        Surface(
          child: Column(
            children: shop.menu
                .map((m) => InfoRow(m.name, won(m.price)))
                .toList(),
          ),
        ),
        SectionTitle('이 가게에 도착한 마음', subtitle: '${benefits.length}개의 공동체 선결제'),
        if (benefits.isEmpty)
          const EmptyState('첫 한턱을 기다려요', '이 가게에 따뜻한 응원을 전해보세요.'),
        ...benefits.map(
          (b) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    s.group(b.communityId).name,
                    style: const TextStyle(
                      color: green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                BenefitCard(b),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class BenefitPage extends StatelessWidget {
  final String id;
  const BenefitPage({super.key, required this.id});
  @override
  Widget build(BuildContext context) {
    final s = storeOf(context), b = storeOf(context).benefit(id);
    final shop = s.shop(b.shopId);
    final verified = s.verified.contains(b.communityId);
    final allowance = s.allowance(b);
    final reason = b.state != 'active'
        ? '${b.stateLabel} 상태인 한턱이에요.'
        : !verified
        ? '대상 공동체의 소속 인증이 필요해요.'
        : allowance == 0
        ? '이 한턱의 1인당 사용 한도를 모두 이용했어요.'
        : '공동체 인증 완료 · 지금 이용할 수 있어요.';
    return PageFrame(
      title: '따뜻한 한턱',
      bottom: Primary(
        !verified
            ? '공동체 인증하고 이용하기'
            : allowance > 0
            ? '혜택 사용하기'
            : b.stateLabel == '진행 중'
            ? '이용 한도 소진'
            : b.stateLabel,
        icon: !verified ? Icons.verified_outlined : Icons.qr_code_rounded,
        onTap: !verified
            ? () => open(context, const CommunityPage())
            : allowance > 0
            ? () {
                try {
                  final r = s.issue(b);
                  open(context, QrPage(request: r));
                } on StateError catch (e) {
                  toast(context, e.message.toString());
                }
              }
            : null,
      ),
      child: paddedList([
        ShopArt(shop, height: 180),
        const SizedBox(height: 17),
        Row(
          children: [
            Pill(s.group(b.communityId).name),
            const Spacer(),
            Pill(b.stateLabel, color: b.state == 'active' ? green : muted),
          ],
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => open(context, ShopPage(id: shop.id)),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  shop.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: muted),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Surface(
          color: const Color(0xFFFFF0E8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.format_quote_rounded, color: coral, size: 28),
              const SizedBox(height: 7),
              Text(
                b.message.isEmpty ? '오늘도 든든한 하루 보내세요.' : b.message,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.8,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 13),
              Text(
                '— ${b.donor}님이 전하는 마음',
                style: const TextStyle(color: Color(0xFFA47D68), fontSize: 12),
              ),
            ],
          ),
        ),
        const SectionTitle('함께 나누는 잔액'),
        Surface(
          child: Column(
            children: [
              InfoRow('남은 공동 잔액', won(b.remaining), accent: true),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: b.remaining / b.total,
                  minHeight: 7,
                  color: coral,
                  backgroundColor: line,
                ),
              ),
              const SizedBox(height: 12),
              InfoRow('처음 전한 금액', won(b.total)),
              InfoRow('지금까지 나눈 금액', won(b.total - b.remaining)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Surface(
          color: const Color(0xFFEDF3EB),
          child: Column(
            children: [
              InfoRow('내가 사용할 수 있는 금액', won(allowance), accent: true),
              Text(
                reason,
                style: const TextStyle(fontSize: 11, color: green, height: 1.6),
              ),
            ],
          ),
        ),
        const SectionTitle('이용 전 확인해 주세요'),
        InfoRow(
          '이용 기간',
          '${dateLabel(b.createdAt)} ~\n${dateLabel(b.expiresAt)}',
        ),
        InfoRow('1인당 전체 기간 한도', won(b.limit)),
        InfoRow('내가 이미 사용한 금액', won(s.usedByMe(b))),
        InfoRow('사용 가능한 메뉴', b.menus.isEmpty ? '모든 메뉴' : b.menus.join(', ')),
        note('주문 금액 중 혜택 적용액만 공동 잔액에서 차감돼요. 초과 금액은 가게에서 직접 결제해 주세요.'),
        TextButton(
          onPressed: () => open(
            context,
            SupportPage(
              targetId: b.id,
              allowRefund: b.mine && b.remaining > 0 && b.status == 'active',
            ),
          ),
          child: const Text(
            '이 한턱에 문의·신고하기',
            style: TextStyle(color: muted, fontSize: 12),
          ),
        ),
      ]),
    );
  }
}
