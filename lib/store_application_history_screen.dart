import 'package:flutter/material.dart';

import 'demo_auth_store.dart';
import 'group_widgets.dart';
import 'store_catalog.dart';
import 'theme.dart';

const rejectionColor = Color(0xFFB64540);

String formatApplicationTime(DateTime value) {
  final date = value.toUtc().add(const Duration(hours: 9));
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year}.${two(date.month)}.${two(date.day)} ${two(date.hour)}:${two(date.minute)}';
}

class StoreRejectionNotice extends StatelessWidget {
  const StoreRejectionNotice({required this.application, super.key});
  final StoreApplication application;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4F2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '반려 사유',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: rejectionColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          application.rejectionReason ?? '',
          key: ValueKey('store-rejection-reason-${application.id}'),
          style: const TextStyle(fontSize: 13, height: 1.8),
        ),
      ],
    ),
  );
}

class StoreApplicationHistoryScreen extends StatelessWidget {
  const StoreApplicationHistoryScreen({
    required this.auth,
    required this.account,
    required this.applicationId,
    super.key,
  });
  final DemoAuthStore auth;
  final DemoAccount account;
  final String applicationId;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: auth.stores,
    builder: (context, _) {
      List<StoreApplication> history;
      try {
        history = auth.stores.applicationHistory(applicationId, account.id);
      } on StateError {
        return const AuthPage(
          child: Column(
            children: [
              GroupPageHeader(title: '가게 신청 이력', backKey: 'store-history-back'),
              SizedBox(height: 24),
              Text(
                '이 신청 이력을 확인할 수 없어요.',
                key: ValueKey('store-history-denied'),
              ),
            ],
          ),
        );
      }
      return AuthPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GroupPageHeader(
              title: '가게 신청 이력',
              backKey: 'store-history-back',
            ),
            const SizedBox(height: 24),
            Text(
              '총 ${history.length}차 신청',
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const Text(
              '차수별 제출 정보와 심사 결과를 최신순으로 확인해요.',
              style: TextStyle(
                fontSize: 11,
                height: 1.8,
                color: HantuckColors.muted,
              ),
            ),
            const SizedBox(height: 24),
            for (final app in history.reversed)
              Container(
                key: ValueKey('store-application-record-${app.id}'),
                padding: const EdgeInsets.all(18),
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  border: Border.all(color: HantuckColors.border),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${app.submissionNumber}차 신청 · ${app.status.label}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: app.rejected
                            ? rejectionColor
                            : HantuckColors.orange,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      app.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    for (final row in [
                      ('사업자등록번호', app.registrationNumber),
                      ('주소', app.address),
                      ('카테고리', app.category),
                      ('가게 전화번호', app.phoneNumber),
                      (
                        '한 줄 소개',
                        app.description.isEmpty
                            ? '입력하지 않았어요.'
                            : app.description,
                      ),
                      (
                        '신청일시',
                        '${formatApplicationTime(app.createdAt)} (한국 시간)',
                      ),
                      if (app.reviewedAt != null)
                        (
                          '심사일시',
                          '${formatApplicationTime(app.reviewedAt!)} (한국 시간)',
                        ),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              row.$1,
                              style: const TextStyle(
                                fontSize: 10,
                                color: HantuckColors.muted,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              row.$2,
                              style: const TextStyle(fontSize: 12, height: 1.8),
                            ),
                          ],
                        ),
                      ),
                    if (app.rejected) StoreRejectionNotice(application: app),
                  ],
                ),
              ),
          ],
        ),
      );
    },
  );
}
