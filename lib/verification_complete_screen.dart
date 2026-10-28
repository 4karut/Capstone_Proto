import 'package:flutter/material.dart';

import 'theme.dart';

class VerificationCompleteScreen extends StatelessWidget {
  const VerificationCompleteScreen({required this.name, super.key});
  final String name;

  @override
  Widget build(BuildContext context) => AuthPage(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HantuckBrand(),
        const SizedBox(height: 65),
        Center(
          child: Container(
            height: 100,
            width: 100,
            decoration: const BoxDecoration(
              color: HantuckColors.orangeSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 58,
              color: HantuckColors.orange,
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          '본인 인증이\n완료되었어요',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.45,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '$name님, 회원가입을 축하해요!\n이제 가입한 계정으로 로그인해 주세요.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.8,
            color: HantuckColors.muted,
          ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF8F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            children: [
              Text(
                '데모 인증 완료',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 5),
              Text(
                '실제 본인 인증은 진행되지 않았어요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: HantuckColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        FilledButton(
          key: const ValueKey('verification-confirm'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('로그인하러 가기'),
        ),
        const SizedBox(height: 20),
      ],
    ),
  );
}
