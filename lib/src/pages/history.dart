import 'package:flutter/material.dart';

import '../models.dart';
import '../ui.dart';
import 'details.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  int tab = 0, days = 0;
  String status = '전체';
  @override
  Widget build(BuildContext context) {
    final s = storeOf(context);
    final cutoff = days == 0
        ? DateTime(2000)
        : DateTime.now().subtract(Duration(days: days));
    final donations = s.benefits
        .where(
          (b) =>
              b.mine &&
              b.createdAt.isAfter(cutoff) &&
              (status == '전체' || b.stateLabel == status),
        )
        .toList();
    final usages = s.usages.where((u) => u.date.isAfter(cutoff)).toList();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SectionTitle('마음이 오간 내역', subtitle: '전한 마음과 받은 응원을 모아봤어요.'),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('내가 쏜 한턱')),
            ButtonSegment(value: 1, label: Text('내가 받은 한턱')),
          ],
          selected: {tab},
          onSelectionChanged: (v) => setState(() => tab = v.first),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            if (tab == 0) ...[
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(
                    labelText: '상태',
                    contentPadding: EdgeInsets.all(12),
                  ),
                  items: ['전체', '진행 중', '소진', '기간 만료', '환불 검토 중', '취소']
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(v, style: const TextStyle(fontSize: 12)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => status = v!),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: days,
                decoration: const InputDecoration(
                  labelText: '조회 기간',
                  contentPadding: EdgeInsets.all(12),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 0,
                    child: Text('전체 기간', style: TextStyle(fontSize: 12)),
                  ),
                  DropdownMenuItem(
                    value: 7,
                    child: Text('최근 7일', style: TextStyle(fontSize: 12)),
                  ),
                  DropdownMenuItem(
                    value: 30,
                    child: Text('최근 30일', style: TextStyle(fontSize: 12)),
                  ),
                ],
                onChanged: (v) => setState(() => days = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (tab == 0) ...[
          if (donations.isEmpty)
            const EmptyState('아직 전한 마음이 없어요', '홈에서 첫 한턱을 쏴보세요.'),
          ...donations.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Surface(
                padding: const EdgeInsets.all(6),
                child: ListTile(
                  leading: Icon(
                    foodIcon(s.shop(b.shopId)),
                    size: 28,
                    color: coral,
                  ),
                  title: Text(
                    s.shop(b.shopId).name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${s.group(b.communityId).name}\n${dateLabel(b.createdAt)} · ${b.stateLabel}',
                    style: const TextStyle(
                      color: muted,
                      fontSize: 11,
                      height: 1.7,
                    ),
                  ),
                  trailing: Text(
                    won(b.total),
                    style: const TextStyle(
                      color: coral,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  onTap: () => open(context, DonationPage(id: b.id)),
                ),
              ),
            ),
          ),
        ] else ...[
          if (usages.isEmpty)
            const EmptyState('아직 받은 한턱이 없어요', '혜택 상세에서 QR 사용을 체험해 보세요.'),
          ...usages.map((u) => UsageTile(u)),
        ],
      ],
    );
  }
}

class UsageTile extends StatelessWidget {
  final Usage usage;
  const UsageTile(this.usage, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Surface(
      padding: const EdgeInsets.all(4),
      child: ListTile(
        leading: const Icon(Icons.receipt_long_outlined, color: green),
        title: Text(
          storeOf(context).shop(usage.shopId).name,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Text(
          '${usage.menu}\n${dateLabel(usage.date)} · 사용 완료',
          style: const TextStyle(fontSize: 11, color: muted, height: 1.7),
        ),
        trailing: Text(
          won(usage.applied),
          style: const TextStyle(color: green, fontWeight: FontWeight.w700),
        ),
        onTap: () => open(context, UsagePage(usage: usage)),
      ),
    ),
  );
}

class DonationPage extends StatelessWidget {
  final String id;
  const DonationPage({super.key, required this.id});
  @override
  Widget build(BuildContext context) {
    final s = storeOf(context), b = storeOf(context).benefit(id);
    final usages = s.usages.where((u) => u.benefitId == id).toList();
    final earlier =
        b.total - b.remaining - usages.fold<int>(0, (n, u) => n + u.applied);
    return PageFrame(
      title: '선결제 내역 상세',
      child: paddedList([
        const SectionTitle('내가 전한 따뜻한 마음'),
        ShopArt(s.shop(b.shopId), height: 150),
        const SizedBox(height: 20),
        Surface(
          child: Column(
            children: [
              InfoRow('가게', s.shop(b.shopId).name),
              InfoRow('공동체', s.group(b.communityId).name),
              InfoRow('상태', b.stateLabel),
              InfoRow('최초 금액', won(b.total)),
              InfoRow('누적 사용액', won(b.total - b.remaining)),
              InfoRow('남은 공동 잔액', won(b.remaining), accent: true),
              InfoRow('1인당 한도', won(b.limit)),
              InfoRow('이용 종료일', dateLabel(b.expiresAt)),
              InfoRow('결제일', dateLabel(b.createdAt)),
              InfoRow('공개 이름', b.donor),
            ],
          ),
        ),
        TextButton(
          onPressed: () => open(context, BenefitPage(id: id)),
          child: const Text('혜택 상세 보기'),
        ),
        const SectionTitle('사용 기록'),
        note('수혜자의 이메일과 개인정보는 공개되지 않습니다.'),
        if (earlier > 0)
          Surface(child: InfoRow('체험 시작 전 예시 사용액', won(earlier))),
        ...usages.map(
          (u) => Surface(
            child: Column(
              children: [
                InfoRow('익명 이용자 · ${shortDate(u.date)}', won(u.applied)),
                InfoRow('사용 메뉴', u.menu),
              ],
            ),
          ),
        ),
        if (usages.isEmpty && earlier <= 0)
          const EmptyState('아직 사용 기록이 없어요', '누군가의 하루에 마음이 닿길 기다리고 있어요.'),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () => open(
            context,
            SupportPage(
              targetId: id,
              allowRefund: b.mine && b.remaining > 0 && b.status == 'active',
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Text('취소·환불 / 문제 신고'),
          ),
        ),
      ]),
    );
  }
}

class UsagePage extends StatelessWidget {
  final Usage usage;
  final bool justCompleted;
  const UsagePage({super.key, required this.usage, this.justCompleted = false});
  @override
  Widget build(BuildContext context) {
    final s = storeOf(context), u = usage;
    return PageFrame(
      title: justCompleted ? '한턱 사용 완료' : '사용 내역 상세',
      child: paddedList([
        const SizedBox(height: 25),
        const Center(
          child: CircleAvatar(
            radius: 35,
            backgroundColor: Color(0xFFEDF3EB),
            child: Icon(Icons.check_rounded, color: green, size: 40),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          justCompleted ? '든든한 한 끼 되세요!' : '한턱을 잘 받았어요',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 26),
        Surface(
          child: Column(
            children: [
              InfoRow('거래번호', u.id),
              InfoRow('가게', s.shop(u.shopId).name),
              InfoRow(
                '사용 일시',
                '${dateLabel(u.date)} ${u.date.hour.toString().padLeft(2, '0')}:${u.date.minute.toString().padLeft(2, '0')}',
              ),
              InfoRow('메뉴', u.menu),
              InfoRow('주문 금액', won(u.orderAmount)),
              InfoRow('혜택 적용액', won(u.applied), accent: true),
              const Divider(),
              InfoRow('현장 추가 결제', won(u.extra), accent: true),
              const InfoRow('거래 상태', '사용 완료'),
            ],
          ),
        ),
        note('추가 결제는 가게에서 직접 결제해 주세요. 한턱 앱에서는 혜택 적용액만 처리합니다.'),
        TextButton(
          onPressed: () => open(context, SupportPage(targetId: u.id)),
          child: const Text('이 거래에 문제 신고'),
        ),
        const SizedBox(height: 15),
        OutlinedButton(
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          child: const Padding(
            padding: EdgeInsets.all(13),
            child: Text('홈으로 돌아가기'),
          ),
        ),
      ]),
    );
  }
}

class SupportPage extends StatefulWidget {
  final String targetId;
  final bool allowRefund;
  const SupportPage({
    super.key,
    required this.targetId,
    this.allowRefund = false,
  });
  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  String type = '신고', category = '거래 오류';
  final reason = TextEditingController(), evidence = TextEditingController();
  @override
  void dispose() {
    reason.dispose();
    evidence.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = storeOf(context);
    return PageFrame(
      title: '취소·환불·신고',
      bottom: Primary(
        '신청 접수하기',
        onTap: () {
          if (reason.text.trim().length < 5) {
            toast(context, '사유를 5자 이상 입력해 주세요.');
            return;
          }
          try {
            final t = s.submitTicket(
              widget.targetId,
              type,
              type == '신고' ? '[$category] ${reason.text.trim()}' : reason.text,
              evidence.text,
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => TicketPage(ticket: t)),
            );
          } on StateError catch (e) {
            toast(context, e.message.toString());
          }
        },
      ),
      child: paddedList([
        const SectionTitle('어떤 도움이 필요하세요?'),
        InfoRow('대상 번호', widget.targetId),
        if (s.benefits.any((b) => b.id == widget.targetId)) ...[
          InfoRow(
            '기존 사용액',
            won(
              s.benefit(widget.targetId).total -
                  s.benefit(widget.targetId).remaining,
            ),
          ),
          InfoRow(
            '남은 잔액',
            won(s.benefit(widget.targetId).remaining),
            accent: true,
          ),
        ],
        if (widget.allowRefund)
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: '신고', label: Text('문제 신고')),
              ButtonSegment(value: '취소·환불', label: Text('취소·환불')),
            ],
            selected: {type},
            onSelectionChanged: (v) => setState(() => type = v.first),
          ),
        if (type == '신고') ...[
          const FieldLabel('신고 유형'),
          DropdownButtonFormField<String>(
            initialValue: category,
            items: [
              '거래 오류',
              '부정 사용 의심',
              '가게 이용 문제',
              '정산 문의',
              '기타',
            ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) => setState(() => category = v!),
          ),
        ],
        const FieldLabel('상세 사유'),
        TextField(
          controller: reason,
          maxLines: 5,
          maxLength: 1000,
          decoration: const InputDecoration(hintText: '상황을 5자 이상 자세히 알려주세요.'),
        ),
        const FieldLabel('증빙 링크 (선택)'),
        TextField(
          controller: evidence,
          decoration: const InputDecoration(hintText: '영수증·사진의 공유 링크 또는 참고 번호'),
        ),
        note(
          type == '취소·환불'
              ? '환불은 남은 잔액을 기준으로 검토해요. 접수되면 해당 혜택의 신규 사용이 중지됩니다. 실제 환불은 발생하지 않으며 처리 상태만 체험합니다.'
              : '파일 업로드는 후속 연동 범위입니다. 데모에서는 증빙 링크나 참고 번호를 기록할 수 있어요.',
        ),
      ]),
    );
  }
}

class TicketsPage extends StatelessWidget {
  const TicketsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = storeOf(context);
    return PageFrame(
      title: '신청·신고 현황',
      child: s.tickets.isEmpty
          ? const EmptyState('접수한 신청이 없어요', '내역 상세에서 환불 신청이나 문제 신고를 할 수 있어요.')
          : paddedList(
              s.tickets
                  .map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Surface(
                        padding: const EdgeInsets.all(5),
                        child: ListTile(
                          title: Text(t.type),
                          subtitle: Text(
                            '${dateLabel(t.date)} · ${t.id}',
                            style: const TextStyle(color: muted, fontSize: 10),
                          ),
                          trailing: Pill(t.status),
                          onTap: () => open(context, TicketPage(ticket: t)),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class TicketPage extends StatelessWidget {
  final SupportTicket ticket;
  const TicketPage({super.key, required this.ticket});
  @override
  Widget build(BuildContext context) {
    final s = storeOf(context), t = ticket;
    return PageFrame(
      title: '신청 처리 현황',
      child: paddedList([
        const SectionTitle('신청이 접수되었어요'),
        Surface(
          child: Column(
            children: [
              InfoRow('접수번호', t.id),
              InfoRow('신청 종류', t.type),
              InfoRow('접수일', dateLabel(t.date)),
              InfoRow('대상 번호', t.targetId),
              InfoRow('처리 상태', t.status),
            ],
          ),
        ),
        const SectionTitle('상세 사유'),
        Text(t.reason, style: const TextStyle(height: 1.8)),
        if (t.evidence.isNotEmpty) ...[
          const SectionTitle('증빙 정보'),
          SelectableText(t.evidence),
        ],
        const SectionTitle('처리 단계'),
        ...['접수', '검토 중', '처리 완료'].map(
          (v) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              ['접수', '검토 중', '처리 완료'].indexOf(v) <=
                      ['접수', '검토 중', '처리 완료'].indexOf(t.status)
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: green,
            ),
            title: Text(v, style: const TextStyle(fontSize: 14)),
          ),
        ),
        if (t.status != '처리 완료')
          OutlinedButton(
            onPressed: () => s.advanceTicket(t),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Text('데모 · 다음 처리 상태 체험'),
            ),
          ),
        note('운영자 검토 과정의 모의 체험입니다. 실제 환불이나 외부 접수는 발생하지 않습니다.'),
      ]),
    );
  }
}
