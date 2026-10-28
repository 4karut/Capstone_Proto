import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'demo_auth_store.dart';
import 'donation_complete_screen.dart';
import 'donation_store.dart';
import 'donation_store_picker_screen.dart';
import 'donation_widgets.dart';
import 'group_store.dart';
import 'group_widgets.dart';
import 'prepaid_store.dart';
import 'store_catalog.dart';
import 'theme.dart';

class DonationFormScreen extends StatefulWidget {
  const DonationFormScreen({
    required this.auth,
    required this.account,
    required this.group,
    required this.type,
    super.key,
  });
  final DemoAuthStore auth;
  final DemoAccount account;
  final DemoGroup group;
  final DonationType type;
  @override
  State<DonationFormScreen> createState() => _DonationFormScreenState();
}

class _DonationFormScreenState extends State<DonationFormScreen> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _storeName = TextEditingController();
  final _deadline = TextEditingController();
  DemoStore? _store;
  late final String _checkoutId = widget.auth.donations.beginCheckout();
  bool _submitted = false;
  bool _submitting = false;
  bool get _prepaid => widget.type == DonationType.prepaid;

  @override
  void dispose() {
    _amount.dispose();
    _storeName.dispose();
    _deadline.dispose();
    super.dispose();
  }

  Future<void> _pickStore() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final store = await Navigator.of(context).push<DemoStore>(
      MaterialPageRoute(
        builder: (_) => DonationStorePickerScreen(
          auth: widget.auth,
          account: widget.account,
        ),
      ),
    );
    if (!mounted || store == null) return;
    setState(() {
      _store = store;
      _storeName.text = store.name;
    });
    if (_submitted) _form.currentState?.validate();
  }

  Future<void> _pickDeadline() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final today = seoulCalendarDate(widget.auth.groups.currentTime);
    final entered = parseDonationDeadline(_deadline.text);
    final selected = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: DateTime(9999, 12, 31),
      initialDate: entered != null && !entered.isBefore(today)
          ? entered
          : today.add(const Duration(days: 30)),
      helpText: '선결제 사용 기한',
      cancelText: '취소',
      confirmText: '선택',
    );
    if (mounted && selected != null) {
      setState(() => _deadline.text = formatOfferDate(selected));
      if (_submitted) _form.currentState?.validate();
    }
  }

  void _confirm() {
    if (_submitting) return;
    setState(() => _submitted = true);
    if (!_form.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _submitting = true);
    try {
      final donation = widget.auth.donations.complete(
        checkoutId: _checkoutId,
        type: widget.type,
        groupId: widget.group.id,
        donorId: widget.account.id,
        donorName: widget.account.name,
        amount: parseDonationAmount(_amount.text)!,
        storeId: _prepaid ? _store!.id : null,
        expiresOn: _prepaid ? parseDonationDeadline(_deadline.text) : null,
      );
      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute(
          builder: (_) =>
              DonationCompleteScreen(auth: widget.auth, donation: donation),
        ),
      );
    } on StateError catch (error) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) => AuthPage(
    child: Form(
      key: _form,
      autovalidateMode: _submitted
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GroupPageHeader(
            title: _prepaid ? '선결제 후원' : '금액 후원',
            backKey: 'donation-form-back',
          ),
          const SizedBox(height: 22),
          DonationGroupSummary(group: widget.group),
          const SizedBox(height: 30),
          Text(
            _prepaid ? '한 끼를 미리 선물해요' : '그룹에 응원을 전해요',
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 9),
          Text(
            _prepaid ? '가게와 금액, 사용할 수 있는 기한을 정해 주세요.' : '후원할 금액을 입력해 주세요.',
            style: const TextStyle(
              fontSize: 12,
              height: 1.7,
              color: HantuckColors.muted,
            ),
          ),
          const SizedBox(height: 26),
          if (_prepaid) ...[
            TextFormField(
              key: const ValueKey('donation-store'),
              controller: _storeName,
              readOnly: true,
              onTap: _pickStore,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                labelText: '선결제 가게',
                hintText: '후원할 가게를 선택해 주세요',
                suffixIcon: Icon(Icons.search_rounded),
              ),
              validator: (_) => _store == null ? '선결제할 가게를 선택해 주세요.' : null,
            ),
            const SizedBox(height: 22),
          ],
          TextFormField(
            key: const ValueKey('donation-amount'),
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: _prepaid
                ? TextInputAction.next
                : TextInputAction.done,
            onFieldSubmitted: _prepaid ? null : (_) => _confirm(),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              labelText: '결제 금액',
              hintText: '후원할 금액',
              suffixText: '원',
              helperText: '1원 이상, 원 단위로 입력해 주세요.',
            ),
            validator: (value) => parseDonationAmount(value ?? '') == null
                ? '1원 이상의 올바른 금액을 입력해 주세요.'
                : null,
          ),
          if (_prepaid) ...[
            const SizedBox(height: 22),
            TextFormField(
              key: const ValueKey('donation-deadline'),
              controller: _deadline,
              keyboardType: TextInputType.datetime,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
                LengthLimitingTextInputFormatter(10),
              ],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _confirm(),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                labelText: '선결제 사용 기한',
                hintText: '예: 20261127',
                helperText: '종료일 23:59까지 사용 가능해요. (한국 시간)',
                helperMaxLines: 2,
                suffixIcon: IconButton(
                  key: const ValueKey('donation-date-picker'),
                  tooltip: '사용 기한 달력에서 선택',
                  onPressed: _pickDeadline,
                  icon: const Icon(Icons.calendar_today_outlined, size: 21),
                ),
              ),
              validator: (value) {
                final date = parseDonationDeadline(value ?? '');
                if (date == null) return '올바른 날짜를 입력해 주세요. 예: 20261127';
                return date.isBefore(
                      seoulCalendarDate(widget.auth.groups.currentTime),
                    )
                    ? '오늘 또는 이후 날짜를 선택해 주세요.'
                    : null;
              },
            ),
          ],
          const SizedBox(height: 30),
          const Text(
            '프로토타입에서는 실제 결제 없이\n확인을 누르면 결제가 완료돼요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.8,
              color: HantuckColors.muted,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            key: const ValueKey('donation-confirm'),
            onPressed: _submitting ? null : _confirm,
            child: const Text('확인'),
          ),
        ],
      ),
    ),
  );
}
