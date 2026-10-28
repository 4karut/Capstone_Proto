import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth_field.dart';
import 'demo_auth_store.dart';
import 'signup_validation.dart';
import 'theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({required this.auth, super.key});
  final DemoAuthStore auth;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _form = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _name = TextEditingController();
  final _birthDate = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _idFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  final _nameFocus = FocusNode();
  final _birthDateFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _codeFocus = FocusNode();
  bool _hidePassword = true;
  bool _hideConfirm = true;
  bool _submitted = false;
  bool _completing = false;
  String? _checkedId;
  String? _idError;
  String? _sentEmail;
  String? _emailError;
  String? _codeError;
  bool _emailVerified = false;

  bool get _idVerified => _checkedId == _id.text && _checkedId != null;

  @override
  void dispose() {
    for (final controller in [
      _id,
      _password,
      _confirm,
      _name,
      _birthDate,
      _phone,
      _email,
      _code,
    ]) {
      controller.dispose();
    }
    for (final focus in [
      _idFocus,
      _passwordFocus,
      _confirmFocus,
      _nameFocus,
      _birthDateFocus,
      _phoneFocus,
      _emailFocus,
      _codeFocus,
    ]) {
      focus.dispose();
    }
    super.dispose();
  }

  String? _validateId(String? value) {
    final error = SignupValidation.id(value);
    if (error != null) return error;
    if (_idError != null) return _idError;
    if (!_idVerified) return '아이디 중복 확인을 해주세요.';
    if (!_completing && !widget.auth.isIdAvailable(value!)) {
      return '이미 사용 중인 아이디예요.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final error = SignupValidation.email(value);
    if (error != null) return error;
    if (_sentEmail == null) return '인증코드를 발송하고 이메일 인증을 완료해 주세요.';
    return null;
  }

  String? _validateCode(String? value) {
    if (_emailVerified) return null;
    if (value == null || value.isEmpty) return '이메일 인증코드를 입력해 주세요.';
    return _codeError ?? '인증하기를 눌러 이메일 인증을 완료해 주세요.';
  }

  Future<void> _checkId() async {
    final value = _id.text;
    var error = SignupValidation.id(value);
    if (error == null) {
      try {
        if (!await widget.auth.checkIdRemote(value)) error = '이미 사용 중인 아이디예요.';
      } on StateError catch (e) {
        error = e.message;
      }
    }
    if (!mounted || _id.text != value) return;
    setState(() {
      _idError = error;
      _checkedId = error == null ? value : null;
    });
  }

  void _idChanged(String _) => setState(() {
    _checkedId = null;
    _idError = null;
  });

  void _emailChanged(String _) => setState(() {
    _sentEmail = null;
    _emailVerified = false;
    _emailError = null;
    _codeError = null;
    _code.clear();
  });

  Future<void> _sendCode() async {
    final email = _email.text;
    var error = SignupValidation.email(email);
    if (error == null) {
      try {
        await widget.auth.sendEmailRemote(email);
      } on StateError catch (e) {
        error = e.message;
      }
    }
    if (!mounted || _email.text != email) return;
    setState(() {
      _emailError = error;
      if (error == null) {
        _sentEmail = email;
        _emailVerified = false;
        _codeError = null;
        _code.clear();
      }
    });
    if (error == null) {
      _codeFocus.requestFocus();
    } else {
      _emailFocus.requestFocus();
    }
  }

  Future<void> _verifyCode() async {
    if (_sentEmail == null || _sentEmail != _email.text) return;
    final email = _sentEmail;
    bool verified = false;
    String? error;
    try {
      verified = await widget.auth.verifyEmailRemote(_code.text);
      if (!verified) error = '인증코드가 일치하지 않아요. 다시 확인해 주세요.';
    } on StateError catch (e) {
      error = e.message;
    }
    if (!mounted || email != _sentEmail) return;
    setState(() {
      _emailVerified = verified;
      _codeError = error;
    });
    if (verified) _codeFocus.unfocus();
  }

  Future<void> _chooseBirthDate() async {
    final now = DateTime.now();
    var initial = DateTime(2000);
    if (SignupValidation.birthDate(_birthDate.text) == null) {
      final digits = _birthDate.text;
      initial = DateTime(
        int.parse(digits.substring(0, 4)),
        int.parse(digits.substring(4, 6)),
        int.parse(digits.substring(6, 8)),
      );
    }
    final selected = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: '생년월일을 선택해 주세요',
      initialDatePickerMode: DatePickerMode.year,
    );
    if (selected == null || !mounted) return;
    _birthDate.text =
        '${selected.year.toString().padLeft(4, '0')}${selected.month.toString().padLeft(2, '0')}${selected.day.toString().padLeft(2, '0')}';
    _phoneFocus.requestFocus();
  }

  Future<void> _submit() async {
    if (_completing) return;
    setState(() => _submitted = true);
    final valid = _form.currentState!.validate();
    if (!valid || !_emailVerified) {
      final checks = <(String?, FocusNode)>[
        (_validateId(_id.text), _idFocus),
        (SignupValidation.password(_password.text), _passwordFocus),
        (
          SignupValidation.passwordConfirmation(_confirm.text, _password.text),
          _confirmFocus,
        ),
        (SignupValidation.name(_name.text), _nameFocus),
        (SignupValidation.birthDate(_birthDate.text), _birthDateFocus),
        (SignupValidation.phone(_phone.text), _phoneFocus),
        (_validateEmail(_email.text), _emailFocus),
        (!_emailVerified ? _validateCode(_code.text) : null, _codeFocus),
      ];
      checks.firstWhere((entry) => entry.$1 != null).$2.requestFocus();
      return;
    }
    setState(() {
      _completing = true;
      _submitted = false;
    });
    final digits = _birthDate.text;
    try {
      final account = await widget.auth.registerRemote(
        id: _id.text,
        password: _password.text,
        name: _name.text,
        birthDate: DateTime(
          int.parse(digits.substring(0, 4)),
          int.parse(digits.substring(4, 6)),
          int.parse(digits.substring(6, 8)),
        ),
        email: _email.text,
        phoneNumber: _phone.text,
      );
      if (!mounted) return;
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.of(context).pop(account);
    } on StateError catch (e) {
      if (mounted) {
        setState(() {
          _completing = false;
          _idError = e.message;
        });
      }
    }
  }

  Widget _status(String text) => Semantics(
    liveRegion: true,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          size: 15,
          color: Color(0xFF26815C),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              height: 1.5,
              color: Color(0xFF26815C),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _action({
    required String keyName,
    required String label,
    required VoidCallback? onPressed,
  }) => OutlinedButton(
    key: ValueKey(keyName),
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 53),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: const BorderSide(color: HantuckColors.border),
      textStyle: const TextStyle(
        fontFamily: 'NotoSansKR',
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
    child: Text(label),
  );

  Widget _visibility(bool hidden, String label, VoidCallback onPressed) =>
      IconButton(
        tooltip: '$label ${hidden ? '보기' : '숨기기'}',
        onPressed: onPressed,
        icon: Icon(
          hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 19,
          color: HantuckColors.muted,
        ),
      );

  @override
  Widget build(BuildContext context) => AuthPage(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HantuckBrand(),
        const SizedBox(height: 14),
        TextButton.icon(
          key: const ValueKey('signup-back'),
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left_rounded, size: 18),
          label: const Text('로그인으로', style: TextStyle(fontSize: 12)),
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
        ),
        const SizedBox(height: 14),
        const Text(
          '회원가입',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: HantuckColors.orange,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '반가워요!\n한턱을 시작해 볼까요?',
          style: TextStyle(
            fontSize: 27,
            height: 1.4,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.1,
          ),
        ),
        const SizedBox(height: 9),
        const Text(
          '기본 정보와 이메일을 확인하고 함께 시작해요.',
          style: TextStyle(
            fontSize: 12,
            height: 1.6,
            color: HantuckColors.muted,
          ),
        ),
        const SizedBox(height: 22),
        const _SignupProgress(),
        const SizedBox(height: 24),
        const Align(
          alignment: Alignment.centerRight,
          child: Text(
            '모든 항목은 필수예요',
            style: TextStyle(fontSize: 10, color: HantuckColors.muted),
          ),
        ),
        const SizedBox(height: 12),
        Form(
          key: _form,
          autovalidateMode: _submitted
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            children: [
              AuthField(
                label: '아이디',
                fieldKey: 'signup-id',
                hint: '영문·숫자 4~20자',
                controller: _id,
                focusNode: _idFocus,
                validator: _validateId,
                errorText: _idError,
                onChanged: _idChanged,
                onSubmitted: (_) => _passwordFocus.requestFocus(),
                action: _action(
                  keyName: 'signup-check-id',
                  label: _idVerified ? '확인 완료' : '중복 확인',
                  onPressed: _idVerified ? null : _checkId,
                ),
                helper: _idVerified ? _status('사용 가능한 아이디예요.') : null,
              ),
              AuthField(
                label: '비밀번호',
                fieldKey: 'signup-password',
                hint: '영문·숫자를 포함한 8~32자',
                controller: _password,
                focusNode: _passwordFocus,
                validator: SignupValidation.password,
                obscureText: _hidePassword,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _confirmFocus.requestFocus(),
                suffixIcon: _visibility(
                  _hidePassword,
                  '비밀번호',
                  () => setState(() => _hidePassword = !_hidePassword),
                ),
              ),
              AuthField(
                label: '비밀번호 확인',
                fieldKey: 'signup-password-confirm',
                hint: '비밀번호를 한 번 더 입력해 주세요',
                controller: _confirm,
                focusNode: _confirmFocus,
                validator: (value) => SignupValidation.passwordConfirmation(
                  value,
                  _password.text,
                ),
                obscureText: _hideConfirm,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _nameFocus.requestFocus(),
                suffixIcon: _visibility(
                  _hideConfirm,
                  '비밀번호 확인',
                  () => setState(() => _hideConfirm = !_hideConfirm),
                ),
                helper:
                    _confirm.text.isNotEmpty && _confirm.text == _password.text
                    ? _status('비밀번호가 일치해요.')
                    : null,
              ),
              AuthField(
                label: '이름',
                fieldKey: 'signup-name',
                hint: '이름을 입력해 주세요',
                controller: _name,
                focusNode: _nameFocus,
                validator: SignupValidation.name,
                keyboardType: TextInputType.name,
                onSubmitted: (_) => _birthDateFocus.requestFocus(),
              ),
              AuthField(
                label: '생년월일',
                fieldKey: 'signup-birth-date',
                hint: '숫자 8자리 (예: 20010315)',
                controller: _birthDate,
                focusNode: _birthDateFocus,
                validator: SignupValidation.birthDate,
                keyboardType: TextInputType.number,
                onSubmitted: (_) => _phoneFocus.requestFocus(),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                suffixIcon: IconButton(
                  tooltip: '생년월일 달력 열기',
                  onPressed: _chooseBirthDate,
                  icon: const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: HantuckColors.muted,
                  ),
                ),
              ),
              AuthField(
                label: '전화번호',
                fieldKey: 'signup-phone',
                hint: '010-1234-5678',
                controller: _phone,
                focusNode: _phoneFocus,
                validator: SignupValidation.phone,
                keyboardType: TextInputType.phone,
                onSubmitted: (_) => _emailFocus.requestFocus(),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                  LengthLimitingTextInputFormatter(13),
                ],
              ),
              AuthField(
                label: '이메일',
                fieldKey: 'signup-email',
                hint: 'hello@example.com',
                controller: _email,
                focusNode: _emailFocus,
                validator: _validateEmail,
                errorText: _emailError,
                keyboardType: TextInputType.emailAddress,
                onChanged: _emailChanged,
                onSubmitted: (_) => _sendCode(),
                last: true,
                action: _action(
                  keyName: 'signup-send-email-code',
                  label: _sentEmail == null ? '인증코드 발송' : '재발송',
                  onPressed: _sendCode,
                ),
              ),
              if (_sentEmail != null)
                AuthField(
                  label: '이메일 인증코드',
                  fieldKey: 'signup-email-code',
                  hint: '숫자 6자리',
                  controller: _code,
                  focusNode: _codeFocus,
                  validator: _validateCode,
                  errorText: _codeError,
                  enabled: !_emailVerified,
                  keyboardType: TextInputType.number,
                  last: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: (_) => setState(() => _codeError = null),
                  onSubmitted: (_) => _verifyCode(),
                  action: _action(
                    keyName: 'signup-verify-email',
                    label: _emailVerified ? '인증 완료' : '인증하기',
                    onPressed: _emailVerified ? null : _verifyCode,
                  ),
                  helper: _emailVerified
                      ? _status('이메일 인증이 완료되었어요.')
                      : const Text(
                          '데모 인증코드: 123456\n프로토타입에서는 실제 이메일이 발송되지 않아요.',
                          style: TextStyle(
                            fontSize: 10,
                            height: 1.7,
                            color: HantuckColors.muted,
                          ),
                        ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        FilledButton(
          key: const ValueKey('signup-submit'),
          onPressed: _completing ? null : _submit,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('본인 인증하기'),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: 18),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Center(
          child: Text(
            '프로토타입에서는 본인 인증이 바로 완료돼요.',
            style: TextStyle(
              fontSize: 10,
              height: 1.6,
              color: HantuckColors.muted,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SignupProgress extends StatelessWidget {
  const _SignupProgress();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    decoration: BoxDecoration(
      color: HantuckColors.orangeSoft,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      children: [
        _StepNumber(number: '1', active: true),
        SizedBox(width: 8),
        Text(
          '기본 정보',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: HantuckColors.orange,
          ),
        ),
        Expanded(
          child: Divider(indent: 16, endIndent: 16, color: Color(0xFFE6CEBE)),
        ),
        _StepNumber(number: '2', active: false),
        SizedBox(width: 8),
        Text(
          '본인 인증',
          style: TextStyle(fontSize: 12, color: HantuckColors.muted),
        ),
      ],
    ),
  );
}

class _StepNumber extends StatelessWidget {
  const _StepNumber({required this.number, required this.active});
  final String number;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    height: 23,
    width: 23,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: active ? HantuckColors.orange : Colors.white,
      shape: BoxShape.circle,
    ),
    child: Text(
      number,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: active ? Colors.white : HantuckColors.muted,
      ),
    ),
  );
}
