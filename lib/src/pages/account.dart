import 'package:flutter/material.dart';

import '../models.dart';
import '../ui.dart';
import 'details.dart';
import 'history.dart';
import 'merchant.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      nickname = TextEditingController();
  bool signup = false, agree = false, hide = true;
  String? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    nickname.dispose();
    super.dispose();
  }

  void submit() {
    if (!form.currentState!.validate()) return;
    if (signup && !agree) {
      setState(() => error = '필수 이용약관과 개인정보 처리 안내에 동의해 주세요.');
      return;
    }
    final s = storeOf(context);
    if (!signup &&
        (email.text.trim() != 'demo@hantteok.app' ||
            password.text != 'demo1234')) {
      setState(() => error = '데모 계정 정보를 확인해 주세요.');
      return;
    }
    if (signup) {
      s.nickname = nickname.text.trim();
      s.verified.clear();
    }
    s.loginDemo(merchant: !signup);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
          children: [
            const Row(
              children: [
                Icon(Icons.rice_bowl_rounded, color: coral, size: 30),
                SizedBox(width: 9),
                Text(
                  '한턱',
                  style: TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 45),
            const Text(
              '한 끼에 담은 마음,\n누군가의 든든한 하루.',
              style: TextStyle(
                fontSize: 31,
                fontWeight: FontWeight.w900,
                height: 1.45,
                letterSpacing: -1.6,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '가까운 가게에서 시작되는 따뜻한 연결',
              style: TextStyle(fontSize: 13, color: muted),
            ),
            const SizedBox(height: 30),
            Surface(
              color: const Color(0xFFFFEEE6),
              child: Row(
                children: [
                  const Icon(Icons.rice_bowl_rounded, color: coral, size: 48),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          signup ? '우리 공동체와 함께해요' : '오늘의 한턱을 만나보세요',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          '작은 응원이 모여\n더 따뜻한 동네가 됩니다.',
                          style: TextStyle(
                            color: Color(0xFF9C7664),
                            fontSize: 12,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Text(
              signup ? '데모 회원가입' : '로그인',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            if (signup) ...[
              const FieldLabel('닉네임'),
              TextFormField(
                controller: nickname,
                maxLength: 12,
                decoration: const InputDecoration(hintText: '마음을 전할 이름'),
                validator: (v) => v!.trim().length < 2 ? '2자 이상 입력해 주세요' : null,
              ),
            ],
            const FieldLabel('이메일'),
            TextFormField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'demo@hantteok.app'),
              validator: (v) =>
                  !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v!.trim())
                  ? '이메일 형식을 확인해 주세요'
                  : null,
            ),
            const FieldLabel('비밀번호'),
            TextFormField(
              controller: password,
              obscureText: hide,
              decoration: InputDecoration(
                hintText: 'demo1234',
                suffixIcon: IconButton(
                  tooltip: '비밀번호 표시',
                  onPressed: () => setState(() => hide = !hide),
                  icon: Icon(
                    hide
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                ),
              ),
              validator: (v) => (v?.length ?? 0) < 6 ? '6자 이상 입력해 주세요' : null,
            ),
            if (signup)
              CheckboxListTile(
                value: agree,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setState(() => agree = v!),
                title: const Text(
                  '필수 약관 및 개인정보 처리 안내 동의',
                  style: TextStyle(fontSize: 12),
                ),
                subtitle: InkWell(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('프로토타입 이용 안내'),
                      content: const Text(
                        '가입 정보는 서버로 전송되지 않습니다. 닉네임과 앱 이용 데이터는 이 기기에 저장됩니다. 비밀번호는 저장하지 않으며, 재로그인은 제공된 데모 계정을 사용합니다. 실제 결제·이메일 인증·송금은 발생하지 않습니다.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('확인'),
                        ),
                      ],
                    ),
                  ),
                  child: const Text(
                    '안내 보기',
                    style: TextStyle(color: coral, fontSize: 11),
                  ),
                ),
              ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 22),
            Primary(signup ? '가입하고 공동체 만나기' : '로그인', onTap: submit),
            TextButton(
              onPressed: () => setState(() {
                signup = !signup;
                error = null;
              }),
              child: Text(signup ? '로그인으로 돌아가기' : '처음 오셨나요? 데모 회원가입'),
            ),
            if (!signup) ...[
              const Divider(height: 32),
              OutlinedButton.icon(
                onPressed: () => storeOf(context).loginDemo(merchant: true),
                icon: const Icon(Icons.play_circle_outline, size: 20),
                label: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text('입력 없이 통합 데모 체험하기'),
                ),
              ),
            ],
            note(
              '프로토타입 · 모든 가게와 공동체는 예시입니다.\n로그인: demo@hantteok.app / demo1234\n회원가입은 현재 기기의 체험 세션을 생성합니다.',
            ),
          ],
        ),
      ),
    ),
  );
}

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});
  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final search = TextEditingController(),
      input = TextEditingController(),
      otp = TextEditingController();
  String? selected, error;
  bool sent = false;
  @override
  void dispose() {
    search.dispose();
    input.dispose();
    otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = storeOf(context);
    final c = s.group(selected ?? s.communityId);
    return PageFrame(
      title: '나의 공동체',
      child: paddedList([
        const SectionTitle(
          '함께할 공동체를 찾아요',
          subtitle: '소속을 인증하면 우리 공동체의 한턱을 사용할 수 있어요.',
        ),
        TextField(
          controller: search,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: '학교 · 단체 검색',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 15),
        ...communities
            .where((c) => c.name.contains(search.text.trim()))
            .map(
              (g) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Surface(
                  padding: const EdgeInsets.all(6),
                  child: ListTile(
                    leading: Icon(
                      c.id == g.id
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: c.id == g.id ? coral : muted,
                    ),
                    selected: c.id == g.id,
                    onTap: () => setState(() {
                      selected = g.id;
                      sent = false;
                      error = null;
                      input.clear();
                      otp.clear();
                    }),
                    title: Text(
                      g.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      s.verified.contains(g.id) ? '인증 완료' : g.description,
                      style: const TextStyle(color: muted, fontSize: 11),
                    ),
                  ),
                ),
              ),
            ),
        if (!communities.any((g) => g.name.contains(search.text.trim())))
          const EmptyState('공동체를 찾지 못했어요', '다른 이름으로 검색해 보세요.'),
        SectionTitle(c.name),
        Text(c.description, style: const TextStyle(color: muted, fontSize: 13)),
        if (s.verified.contains(c.id)) ...[
          const SizedBox(height: 20),
          const Pill('소속 인증 완료'),
          const SizedBox(height: 18),
          Primary(
            '이 공동체로 변경',
            onTap: () {
              s.setCommunity(c.id);
              Navigator.pop(context);
            },
          ),
        ] else ...[
          note(
            c.emailDomain.isEmpty
                ? '초대 코드로 인증해요. 데모 코드: ${c.code}'
                : '학교 이메일 인증을 체험해요.\n예시: student@${c.emailDomain} · 인증번호: 123456',
          ),
          FieldLabel(c.emailDomain.isEmpty ? '초대 코드' : '학교 이메일'),
          TextField(
            controller: input,
            decoration: InputDecoration(
              hintText: c.emailDomain.isEmpty
                  ? c.code
                  : 'student@${c.emailDomain}',
            ),
          ),
          if (sent) ...[
            const FieldLabel('인증번호'),
            TextField(
              controller: otp,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '데모 인증번호 123456'),
            ),
          ],
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          const SizedBox(height: 20),
          Primary(
            c.emailDomain.isNotEmpty && !sent ? '모의 인증번호 요청' : '소속 인증 완료하기',
            onTap: () {
              if (c.emailDomain.isNotEmpty && !sent) {
                if (!RegExp('^[^\\s@]+@${RegExp.escape(c.emailDomain)}\$')
                    .hasMatch(input.text.trim())) {
                  setState(() => error = '학교 이메일 주소를 확인해 주세요.');
                  return;
                }
                setState(() {
                  sent = true;
                  error = null;
                });
                toast(context, '데모 인증번호는 123456입니다. 실제 메일은 발송되지 않아요.');
                return;
              }
              if ((c.emailDomain.isEmpty && input.text.trim() != c.code) ||
                  (c.emailDomain.isNotEmpty && otp.text.trim() != '123456')) {
                setState(() => error = '인증에 실패했어요. 코드를 확인하고 다시 시도해 주세요.');
                return;
              }
              s.verified.add(c.id);
              s.setCommunity(c.id);
              toast(context, '공동체 인증을 완료했어요.');
              Navigator.pop(context);
            },
          ),
        ],
      ]),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = storeOf(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SectionTitle('마이페이지'),
        Surface(
          child: Row(
            children: [
              const CircleAvatar(
                radius: 29,
                backgroundColor: Color(0xFFFFE8DD),
                child: Icon(Icons.person_rounded, color: coral, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.nickname,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '마음을 나누는 다정한 이웃',
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '프로필 수정',
                onPressed: () => open(context, const EditProfilePage()),
                icon: const Icon(Icons.edit_outlined, size: 20),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Surface(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.school_outlined),
                title: const Text('내 공동체'),
                subtitle: Text(
                  s.community.name,
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => open(context, const CommunityPage()),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_none),
                title: const Text('알림'),
                trailing: Badge(
                  isLabelVisible: s.unread > 0,
                  label: Text('${s.unread}'),
                  child: const Icon(Icons.chevron_right),
                ),
                onTap: () => open(context, const NoticesPage()),
              ),
              ListTile(
                leading: const Icon(Icons.tune),
                title: const Text('알림 설정'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => open(context, const NotificationSettingsPage()),
              ),
              ListTile(
                leading: const Icon(Icons.support_agent),
                title: const Text('신청·신고 현황'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => open(context, const TicketsPage()),
              ),
            ],
          ),
        ),
        if (s.merchantAccess) ...[
          const SectionTitle('사장님 메뉴'),
          Surface(
            color: const Color(0xFFEDF3EB),
            padding: const EdgeInsets.all(8),
            child: ListTile(
              leading: const Icon(Icons.storefront, color: green),
              title: const Text(
                '가게 관리 모드',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                '주문 요청부터 정산까지',
                style: TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_rounded),
              onTap: () => open(context, const MerchantPage()),
            ),
          ),
        ],
        const SizedBox(height: 30),
        TextButton(
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('로그아웃할까요?'),
                content: const Text('내역과 공동체 인증 정보는 이 기기에 남아 있어요.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('돌아가기'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('로그아웃'),
                  ),
                ],
              ),
            );
            if (ok == true) s.logout();
          },
          child: const Text('로그아웃', style: TextStyle(color: muted)),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'HANTTEOK',
            style: TextStyle(letterSpacing: 4, fontSize: 12, color: muted),
          ),
        ),
        note('v1.0 · 로컬 프로토타입\n결제·인증·QR 확인·정산은 데모 흐름으로 작동합니다.'),
      ],
    );
  }
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final nickname = TextEditingController(), name = TextEditingController();
  bool loaded = false;
  @override
  void dispose() {
    nickname.dispose();
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = storeOf(context);
    if (!loaded) {
      nickname.text = s.nickname;
      name.text = s.realName;
      loaded = true;
    }
    return PageFrame(
      title: '프로필 수정',
      bottom: Primary(
        '저장',
        onTap: () {
          if (nickname.text.trim().length < 2 || name.text.trim().length < 2) {
            toast(context, '이름과 닉네임은 2자 이상 입력해 주세요.');
            return;
          }
          s.nickname = nickname.text.trim();
          s.realName = name.text.trim();
          s.commit();
          Navigator.pop(context);
        },
      ),
      child: paddedList([
        const FieldLabel('닉네임'),
        TextField(controller: nickname, maxLength: 12),
        const FieldLabel('공개용 실명'),
        TextField(controller: name, maxLength: 20),
        note('선결제 시 실명 공개를 선택한 경우에만 이 이름이 표시돼요.'),
      ]),
    );
  }
}

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = storeOf(context);
    return PageFrame(
      title: '알림 설정',
      child: paddedList([
        note('이 기기 안에서 생성되는 알림의 수신 여부를 설정해요.'),
        ...s.notificationSettings.entries.map(
          (e) => SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(e.key),
            value: e.value,
            activeThumbColor: coral,
            onChanged: (v) {
              s.notificationSettings[e.key] = v;
              s.commit();
            },
          ),
        ),
      ]),
    );
  }
}

class NoticesPage extends StatelessWidget {
  const NoticesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = storeOf(context);
    return PageFrame(
      title: '알림',
      actions: [
        TextButton(
          onPressed: () {
            for (final n in s.notices) {
              n.read = true;
            }
            s.commit();
          },
          child: const Text('모두 읽음', style: TextStyle(fontSize: 12)),
        ),
      ],
      child: s.notices.isEmpty
          ? const EmptyState('아직 알림이 없어요', '새로운 마음이 도착하면 알려드릴게요.')
          : ListView.separated(
              itemCount: s.notices.length,
              separatorBuilder: (_, index) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final n = s.notices[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: n.read ? line : const Color(0xFFFFE8DD),
                    child: Icon(
                      Icons.favorite_outline,
                      color: n.read ? muted : coral,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    n.title,
                    style: TextStyle(
                      fontWeight: n.read ? FontWeight.w500 : FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    '${n.body}\n${dateLabel(n.date)}',
                    style: const TextStyle(
                      color: muted,
                      fontSize: 11,
                      height: 1.8,
                    ),
                  ),
                  onTap: () {
                    n.read = true;
                    s.commit();
                    if (s.benefits.any((b) => b.id == n.targetId)) {
                      open(context, BenefitPage(id: n.targetId));
                    } else if (s.usages.any((u) => u.id == n.targetId)) {
                      open(
                        context,
                        UsagePage(
                          usage: s.usages.firstWhere((u) => u.id == n.targetId),
                        ),
                      );
                    } else {
                      open(context, const TicketsPage());
                    }
                  },
                );
              },
            ),
    );
  }
}
