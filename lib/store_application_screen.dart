import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'demo_auth_store.dart';
import 'group_widgets.dart';
import 'signup_validation.dart';
import 'store_application_history_screen.dart';
import 'store_catalog.dart';
import 'theme.dart';

class StoreApplicationScreen extends StatefulWidget {
  const StoreApplicationScreen({
    required this.auth,
    required this.account,
    this.resubmissionOf,
    super.key,
  });
  final DemoAuthStore auth;
  final DemoAccount account;
  final String? resubmissionOf;
  @override
  State<StoreApplicationScreen> createState() => _StoreApplicationScreenState();
}

class _StoreApplicationScreenState extends State<StoreApplicationScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _number = TextEditingController();
  final _address = TextEditingController();
  final _description = TextEditingController();
  late final _phone = TextEditingController(text: widget.account.phoneNumber);
  String? _category;
  bool _submitted = false;
  bool _working = false;
  StoreApplication? _complete;
  StoreApplication? _previous;
  @override
  void initState() {
    super.initState();
    final id = widget.resubmissionOf;
    if (id != null && widget.auth.stores.canResubmit(id, widget.account.id)) {
      final app = widget.auth.stores.application(id, widget.account.id);
      _previous = app;
      _name.text = app.name;
      _number.text = app.registrationNumber;
      _address.text = app.address;
      _description.text = app.description;
      _phone.text = app.phoneNumber;
      _category = app.category;
    }
  }

  @override
  void dispose() {
    for (final controller in [_name, _number, _address, _description, _phone]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _apply() {
    if (_working) return;
    setState(() => _submitted = true);
    if (!_form.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _working = true);
    try {
      final app = widget.auth.stores.apply(
        ownerId: widget.account.id,
        ownerName: widget.account.name,
        name: _name.text,
        registrationNumber: _number.text,
        address: _address.text,
        category: _category!,
        phoneNumber: _phone.text,
        description: _description.text,
        resubmissionOf: widget.resubmissionOf,
      );
      setState(() => _complete = app);
    } on StateError catch (error) {
      setState(() => _working = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_complete == null &&
        widget.resubmissionOf != null &&
        !widget.auth.stores.canResubmit(
          widget.resubmissionOf!,
          widget.account.id,
        )) {
      return const AuthPage(
        child: Column(
          children: [
            GroupPageHeader(title: '가게 재신청', backKey: 'store-application-back'),
            SizedBox(height: 24),
            Text(
              '본인의 반려된 최신 신청만 다시 신청할 수 있어요.',
              key: ValueKey('store-resubmission-denied'),
            ),
          ],
        ),
      );
    }
    if (_complete != null) {
      return AuthPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 35),
            const Icon(
              Icons.check_circle_rounded,
              size: 76,
              color: HantuckColors.orange,
            ),
            const SizedBox(height: 24),
            Text(
              _previous == null ? '가게 신청이 완료됐어요' : '가게 재신청이 완료됐어요',
              key: const ValueKey('store-application-complete'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Text(
              '${_complete!.name}\n관리자 승인 후 가게 찾기와 선결제 후원에 표시돼요.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.9,
                color: HantuckColors.muted,
              ),
            ),
            const SizedBox(height: 30),
            FilledButton(
              key: const ValueKey('store-application-complete-confirm'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
    return AuthPage(
      child: Form(
        key: _form,
        autovalidateMode: _submitted
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GroupPageHeader(
              title: _previous == null ? '가게 신청하기' : '가게 재신청',
              backKey: 'store-application-back',
            ),
            const SizedBox(height: 24),
            const Text(
              '우리 가게를 한턱에 소개해요',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const Text(
              '가게 정보 입력 → 관리자 심사 → 승인 후 공개',
              style: TextStyle(
                fontSize: 11,
                height: 1.8,
                color: HantuckColors.orange,
              ),
            ),
            const SizedBox(height: 26),
            if (_previous != null) ...[
              StoreRejectionNotice(application: _previous!),
              const SizedBox(height: 12),
              Text(
                '이전 정보를 불러왔어요. 수정 후 ${_previous!.submissionNumber + 1}차 신청을 제출해 주세요.',
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.8,
                  color: HantuckColors.muted,
                ),
              ),
              const SizedBox(height: 24),
            ],
            TextFormField(
              key: const ValueKey('store-application-name'),
              controller: _name,
              maxLength: 50,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                labelText: '가게 이름',
                hintText: '상호명을 입력해 주세요',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? '가게 이름을 입력해 주세요.'
                  : null,
            ),
            const SizedBox(height: 17),
            TextFormField(
              key: const ValueKey('store-application-number'),
              controller: _number,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                LengthLimitingTextInputFormatter(12),
              ],
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                labelText: '사업자등록번호',
                hintText: '숫자 10자리 또는 000-00-00000',
                helperText: '프로토타입에서는 번호 형식만 확인해요.',
                helperMaxLines: 2,
              ),
              validator: (value) =>
                  !RegExp(r'^\d{10}$')
                      .hasMatch((value ?? '').replaceAll('-', '').trim())
                  ? '사업자등록번호 10자리를 확인해 주세요.'
                  : null,
            ),
            const SizedBox(height: 22),
            TextFormField(
              key: const ValueKey('store-application-address'),
              controller: _address,
              maxLength: 150,
              maxLines: 2,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                labelText: '가게 주소',
                hintText: '도로명 주소와 상세 주소를 입력해 주세요',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? '가게 주소를 입력해 주세요.'
                  : null,
            ),
            const SizedBox(height: 17),
            DropdownButtonFormField<String>(
              key: const ValueKey('store-application-category'),
              initialValue: _category,
              isExpanded: true,
              decoration: const InputDecoration(labelText: '카테고리'),
              hint: const Text('가게 카테고리 선택', style: TextStyle(fontSize: 13)),
              items: DemoStoreCatalog.categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(
                        category,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _category = value),
              validator: (value) => value == null ? '카테고리를 선택해 주세요.' : null,
            ),
            const SizedBox(height: 22),
            TextFormField(
              key: const ValueKey('store-application-phone'),
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
              ],
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(labelText: '가게 전화번호'),
              validator: SignupValidation.phone,
            ),
            const SizedBox(height: 22),
            TextFormField(
              key: const ValueKey('store-application-description'),
              controller: _description,
              maxLength: 100,
              maxLines: 2,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                labelText: '한 줄 소개 (선택)',
                hintText: '가게의 특징을 소개해 주세요',
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '신청자: ${widget.account.name}\n승인된 가게는 이 계정에서 관리할 수 있어요.',
              style: const TextStyle(
                fontSize: 11,
                height: 1.8,
                color: HantuckColors.muted,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const ValueKey('store-application-submit'),
              onPressed: _working ? null : _apply,
              child: Text(_previous == null ? '신청하기' : '다시 신청하기'),
            ),
          ],
        ),
      ),
    );
  }
}
