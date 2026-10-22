import 'package:flutter/material.dart';

import '../models.dart';
import '../ui.dart';
import 'account.dart';
import 'details.dart';
import 'give.dart';

class HomePage extends StatelessWidget {
  final VoidCallback onExplore;
  const HomePage({super.key, required this.onExplore});
  @override
  Widget build(BuildContext context) {
    final s = storeOf(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
      children: [
        Row(
          children: [
            const Text(
              '한턱',
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
              ),
            ),
            const SizedBox(width: 9),
            const Text(
              '마음을 나누는 한 끼',
              style: TextStyle(fontSize: 11, color: muted),
            ),
            const Spacer(),
            IconButton(
              tooltip: '알림',
              onPressed: () => open(context, const NoticesPage()),
              icon: Badge(
                isLabelVisible: s.unread > 0,
                backgroundColor: coral,
                child: const Icon(Icons.notifications_none_rounded),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: () => open(context, const CommunityPage()),
          child: Surface(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: green.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school_outlined,
                    color: green,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '나의 공동체',
                        style: TextStyle(color: muted, fontSize: 10),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.community.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Pill(
                  s.isVerified ? '인증 완료' : '인증 필요',
                  color: s.isVerified ? green : coral,
                ),
                const SizedBox(width: 4),
                const Icon(Icons.expand_more, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Container(
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE8DD),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '작은 마음이 모여, 든든한 하루',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9D5B44),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 13),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '오늘 한 끼,\n제가 쏠게요.',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          height: 1.35,
                          letterSpacing: -1.6,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .52),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.ramen_dining_rounded,
                        size: 64,
                        color: Color(0xFFC78360),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                '우리 공동체에 따뜻한 마음을 전해보세요.',
                style: TextStyle(fontSize: 12, color: Color(0xFF906855)),
              ),
              const SizedBox(height: 20),
              Primary(
                '한턱 쏘기',
                icon: Icons.favorite_border_rounded,
                onTap: () => open(context, const GivePage()),
              ),
            ],
          ),
        ),
        SectionTitle(
          '도착한 따뜻한 마음',
          subtitle: '우리 공동체를 위한 ${s.available.length}개의 한턱',
          trailing: TextButton(
            onPressed: onExplore,
            child: const Text('전체 보기', style: TextStyle(fontSize: 12)),
          ),
        ),
        if (s.available.isEmpty)
          const EmptyState('아직 도착한 한턱이 없어요', '첫 번째 따뜻한 마음을 전해보세요.'),
        ...s.available.map(
          (b) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: BenefitCard(b),
          ),
        ),
        const SizedBox(height: 15),
        const Center(
          child: Text(
            '한 끼의 온기가, 다음 한 끼로 이어지도록.',
            style: TextStyle(color: muted, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class BenefitCard extends StatelessWidget {
  final Benefit b;
  const BenefitCard(this.b, {super.key});
  @override
  Widget build(BuildContext context) {
    final s = storeOf(context);
    final shop = s.shop(b.shopId);
    return InkWell(
      borderRadius: BorderRadius.circular(21),
      onTap: () => open(context, BenefitPage(id: b.id)),
      child: Surface(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: Color(shop.color),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Icon(
                      foodIcon(shop),
                      size: 34,
                      color: const Color(0xFF8C6949),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${shop.category} · ${shop.distance}',
                        style: const TextStyle(color: muted, fontSize: 11),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${b.donor}님이 전한 한턱',
                        style: const TextStyle(fontSize: 11, color: muted),
                      ),
                    ],
                  ),
                ),
                Pill('최대 ${won(b.limit)}', color: coral),
              ],
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: canvas,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.favorite_rounded, color: coral, size: 13),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      b.message.replaceAll('\n', ' '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF77796E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text(
                  '남은 공동 잔액',
                  style: TextStyle(fontSize: 11, color: muted),
                ),
                const SizedBox(width: 8),
                Text(
                  won(b.remaining),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: coral,
                  ),
                ),
                const Spacer(),
                Text(
                  '~ ${shortDate(b.expiresAt)}',
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: b.remaining / b.total,
                minHeight: 4,
                color: coral.withValues(alpha: .75),
                backgroundColor: line,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});
  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final search = TextEditingController();
  String category = '전체', group = 'mine';
  bool onlyBenefits = false;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = storeOf(context);
    final q = search.text.trim().toLowerCase();
    final selectedGroup = group == 'mine' ? s.communityId : group;
    final matches = s.benefits
        .where(
          (b) =>
              b.state == 'active' &&
              (selectedGroup == 'all' || b.communityId == selectedGroup),
        )
        .toList();
    bool textMatches(Benefit b) =>
        '${s.shop(b.shopId).name} ${s.group(b.communityId).name} ${b.message} ${b.donor}'
            .toLowerCase()
            .contains(q);
    final shops = s.shops
        .where(
          (shop) =>
              (category == '전체' || shop.category == category) &&
              (shop.name.toLowerCase().contains(q) ||
                  shop.category.contains(q) ||
                  matches.any((b) => b.shopId == shop.id && textMatches(b))) &&
              (!onlyBenefits || matches.any((b) => b.shopId == shop.id)),
        )
        .toList();
    final benefits = matches
        .where(
          (b) =>
              textMatches(b) &&
              (category == '전체' || s.shop(b.shopId).category == category),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
      children: [
        const Text(
          '동네에서 만나는\n다정한 한턱',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w900,
            height: 1.4,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: '가게, 공동체, 혜택을 검색해 보세요',
            prefixIcon: const Icon(Icons.search, size: 21),
            suffixIcon: search.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () => setState(() => search.clear()),
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
        const SizedBox(height: 18),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['전체', '한식', '카페', '베이커리', '샐러드']
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: category == c,
                      onSelected: (_) => setState(() => category = c),
                      showCheckmark: false,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: group,
          decoration: const InputDecoration(labelText: '공동체'),
          items: [
            const DropdownMenuItem(value: 'mine', child: Text('내 공동체')),
            const DropdownMenuItem(value: 'all', child: Text('모든 공동체')),
            ...communities.map(
              (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
            ),
          ],
          onChanged: (v) => setState(() => group = v!),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('이용 가능한 혜택이 있는 가게', style: TextStyle(fontSize: 12)),
          value: onlyBenefits,
          activeThumbColor: coral,
          onChanged: (v) => setState(() => onlyBenefits = v),
        ),
        SectionTitle('함께하는 가게', subtitle: '${shops.length}곳의 다정한 이웃'),
        if (shops.isEmpty)
          EmptyState(
            '검색 결과가 없어요',
            '다른 검색어나 조건으로 찾아보세요.',
            reset: () => setState(() {
              search.clear();
              category = '전체';
              onlyBenefits = false;
              group = 'all';
            }),
          ),
        ...shops.map(
          (shop) => Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => open(context, ShopPage(id: shop.id)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShopArt(shop),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          shop.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      if (matches.any((b) => b.shopId == shop.id))
                        const Pill('한턱 도착'),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${shop.category} · ${shop.distance} · ${shop.address}',
                    style: const TextStyle(color: muted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (benefits.isNotEmpty) ...[
          SectionTitle('찾은 한턱', subtitle: '${benefits.length}개의 마음이 기다리고 있어요'),
          ...benefits.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: BenefitCard(b),
            ),
          ),
        ],
      ],
    );
  }
}
