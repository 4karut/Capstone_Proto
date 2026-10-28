import 'package:flutter/material.dart';

import 'auth_field.dart';
import 'demo_auth_store.dart';
import 'main_screen.dart';
import 'signup_screen.dart';
import 'theme.dart';
import 'verification_complete_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.auth, super.key});
  final DemoAuthStore auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  var _form = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _password = TextEditingController();
  final _idFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _hidePassword = true;
  bool _submitted = false;
  bool _openingSignup = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _id.dispose();
    _password.dispose();
    _idFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _clearError(String _) {
    if (_error != null) setState(() => _error = null);
  }

  void _login() {
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (!_form.currentState!.validate()) {
      (_id.text.trim().isEmpty ? _idFocus : _passwordFocus).requestFocus();
      return;
    }
    final account = widget.auth.signIn(_id.text, _password.text);
    if (account == null) {
      setState(() => _error = '아이디 또는 비밀번호를 확인해 주세요.');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute(
        builder: (_) => MainScreen(auth: widget.auth, account: account),
      ),
    );
  }

  Future<void> _openSignup() async {
    if (_openingSignup) return;
    setState(() => _openingSignup = true);
    FocusManager.instance.primaryFocus?.unfocus();
    final account = await Navigator.of(context).push<DemoAccount>(
      MaterialPageRoute(builder: (_) => SignupScreen(auth: widget.auth)),
    );
    if (!mounted) return;
    setState(() {
      _openingSignup = false;
      if (account != null) {
        _id.text = account.id;
        _password.clear();
        _submitted = false;
        _form = GlobalKey<FormState>();
        _error = null;
        _notice = '회원가입이 완료되었어요. 로그인해 주세요.';
      }
    });
    if (account == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => VerificationCompleteScreen(name: account.name),
      ),
    );
    if (mounted) _passwordFocus.requestFocus();
  }

  void _fillDemo() {
    setState(() {
      _id.text = DemoAuthStore.sampleId;
      _password.text = DemoAuthStore.samplePassword;
      _error = null;
      _notice = null;
    });
  }

  @override
  Widget build(BuildContext context) => AuthPage(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HantuckBrand(),
        const SizedBox(height: 48),
        const Text(
          '함께 나누는 한턱',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: HantuckColors.orange,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '우리의 마음이 모여\n따뜻한 한턱이 돼요.',
          style: TextStyle(
            fontSize: 28,
            height: 1.4,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.1,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '로그인하고 우리 그룹의 한턱을 만나보세요.',
          style: TextStyle(
            fontSize: 12,
            height: 1.6,
            color: HantuckColors.muted,
          ),
        ),
        const SizedBox(height: 34),
        if (_notice != null) ...[
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: HantuckColors.orangeSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _notice!,
              style: const TextStyle(fontSize: 12, height: 1.5),
            ),
          ),
          const SizedBox(height: 18),
        ],
        Form(
          key: _form,
          autovalidateMode: _submitted
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            children: [
              AuthField(
                label: '아이디',
                fieldKey: 'login-id',
                hint: '아이디를 입력해 주세요',
                controller: _id,
                focusNode: _idFocus,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? '아이디를 입력해 주세요.' : null,
                onChanged: _clearError,
                onSubmitted: (_) => _passwordFocus.requestFocus(),
              ),
              AuthField(
                label: '비밀번호',
                fieldKey: 'login-password',
                hint: '비밀번호를 입력해 주세요',
                controller: _password,
                focusNode: _passwordFocus,
                obscureText: _hidePassword,
                validator: (v) =>
                    v == null || v.isEmpty ? '비밀번호를 입력해 주세요.' : null,
                onChanged: _clearError,
                onSubmitted: (_) => _login(),
                last: true,
                suffixIcon: IconButton(
                  tooltip: _hidePassword ? '비밀번호 보기' : '비밀번호 숨기기',
                  onPressed: () =>
                      setState(() => _hidePassword = !_hidePassword),
                  icon: Icon(
                    _hidePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 19,
                    color: HantuckColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          Semantics(
            liveRegion: true,
            child: Text(
              _error!,
              key: const ValueKey('login-error'),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        FilledButton(
          key: const ValueKey('login-submit'),
          onPressed: _login,
          child: const Text('로그인'),
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              '한턱이 처음이신가요?',
              style: TextStyle(fontSize: 12, color: HantuckColors.muted),
            ),
            TextButton(
              key: const ValueKey('login-signup'),
              onPressed: _openingSignup ? null : _openSignup,
              child: const Text(
                '회원가입',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF8F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '먼저 둘러보고 싶다면',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                '체험용 계정으로 로그인해 보세요.',
                style: TextStyle(fontSize: 11, color: HantuckColors.muted),
              ),
              const SizedBox(height: 7),
              TextButton.icon(
                key: const ValueKey('login-demo-fill'),
                onPressed: _fillDemo,
                icon: const Icon(Icons.person_outline_rounded, size: 17),
                label: const Text('데모 계정 채우기', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '가입한 데모 계정은 새로고침하거나 앱을 다시 시작하면 초기화돼요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            height: 1.6,
            color: HantuckColors.muted,
          ),
        ),
      ],
    ),
  );
}
