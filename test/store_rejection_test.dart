import 'package:capstone_proto_02/demo_auth_store.dart';
import 'package:capstone_proto_02/group_store.dart';
import 'package:capstone_proto_02/main.dart';
import 'package:capstone_proto_02/store_application_screen.dart';
import 'package:capstone_proto_02/store_application_history_screen.dart';
import 'package:capstone_proto_02/store_catalog.dart';
import 'package:capstone_proto_02/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_helpers.dart';

DemoAuthStore sample() => DemoAuthStore(
  groupStore: DemoGroupStore(now: () => DateTime.utc(2026, 10, 28, 3)),
);

StoreApplication apply(
  DemoAuthStore auth, {
  String? previousId,
  String owner = 'hantuck01',
  String address = '서울특별시 마포구 나눔로 20',
  String number = '1234567890',
  String name = '나눔 카페',
}) => auth.stores.apply(
  ownerId: owner,
  ownerName: '한나눔',
  name: name,
  registrationNumber: number,
  address: address,
  category: '카페·디저트',
  phoneNumber: '021234567',
  description: '커피를 함께 나눠요.',
  resubmissionOf: previousId,
);

void reject(
  DemoAuthStore auth,
  StoreApplication app, {
  String reason = '상세 주소에 층·호수를 입력해 주세요.',
}) => auth.stores.reject(
  applicationId: app.id,
  adminId: 'admin01',
  reason: reason,
);

Future<void> login(WidgetTester tester, String id) async {
  await enter(tester, loginField('id'), id);
  await enter(tester, loginField('password'), DemoAuthStore.samplePassword);
  await tapKey(tester, 'login-submit');
  await tapKey(tester, 'nav-my-page');
}

Future<void> logout(WidgetTester tester) async {
  await tapKey(tester, 'nav-my-page');
  await tapKey(tester, 'my-page-settings');
  await tapKey(tester, 'account-logout');
}

Future<void> review(WidgetTester tester, String id) async {
  await tapKey(tester, 'my-page-review-stores');
  await tapKey(tester, 'store-review-$id');
}

void main() {
  test('rejection requires admin and a nonblank reason of at most 300 graphemes; no store is published', () {
    final auth = sample();
    final app = apply(auth);
    expect(
      () => auth.stores.reject(
        applicationId: app.id,
        adminId: 'hantuck01',
        reason: '수정 필요',
      ),
      throwsStateError,
    );
    for (final reason in ['', '   \n', '가' * 301]) {
      expect(() => reject(auth, app, reason: reason), throwsStateError);
      expect(app.status, StoreApplicationStatus.pending);
    }
    reject(auth, app, reason: '  ${'🙂' * 300}  ');
    expect(app.status, StoreApplicationStatus.rejected);
    expect(app.rejectionReason, '🙂' * 300);
    expect(app.reviewedAt, DateTime.utc(2026, 10, 28, 3));
    expect(auth.stores.pendingApplications('admin01'), isEmpty);
    expect(auth.stores.searchAll(query: '나눔'), isEmpty);
    expect(auth.stores.ownedStores('hantuck01'), isEmpty);
    expect(
      () => auth.stores.approve(applicationId: app.id, adminId: 'admin01'),
      throwsStateError,
    );
    expect(() => reject(auth, app), throwsStateError);
    expect(formatApplicationTime(app.createdAt), '2026.10.28 12:00');
  });

  test('resubmission preserves original fields and reason, changes latest attempt and stays private until approved', () {
    final auth = sample();
    final original = apply(auth);
    reject(auth, original);
    final revised = apply(
      auth,
      previousId: original.id,
      address: '서울특별시 마포구 나눔로 20, 1층 101호',
    );
    expect(revised.id, isNot(original.id));
    expect(revised.rootApplicationId, original.id);
    expect(revised.previousApplicationId, original.id);
    expect(revised.submissionNumber, 2);
    expect(revised.status, StoreApplicationStatus.pending);
    expect(revised.rejectionReason, isNull);
    expect(original.address, '서울특별시 마포구 나눔로 20');
    expect(original.rejectionReason, '상세 주소에 층·호수를 입력해 주세요.');
    expect(original.resubmissionId, revised.id);
    expect(auth.stores.applicationHistory(revised.id, ' HANTUCK01 '), [
      original,
      revised,
    ]);
    expect(auth.stores.applicationHistory(original.id, 'admin01'), [
      original,
      revised,
    ]);
    expect(auth.stores.latestApplicationsFor('hantuck01'), [revised]);
    expect(auth.stores.pendingApplications('admin01'), [revised]);
    expect(auth.stores.searchAll(query: revised.name), isEmpty);
    final store = auth.stores.approve(
      applicationId: revised.id,
      adminId: 'admin01',
    );
    expect(store.address, revised.address);
    expect(auth.stores.searchAll(query: revised.name), hasLength(1));
    expect(auth.stores.ownedStores('hantuck01'), [store]);
    expect(
      auth.stores.applicationHistory(revised.id, 'hantuck01').first.status,
      StoreApplicationStatus.rejected,
    );
  });

  test('only latest rejected attempt can resubmit; repeated rejection forms one history without branches', () {
    final auth = sample();
    final original = apply(auth);
    expect(() => apply(auth, previousId: original.id), throwsStateError);
    reject(auth, original);
    expect(
      () => apply(auth, previousId: original.id, owner: 'store01'),
      throwsStateError,
    );
    expect(
      () => apply(auth, previousId: original.id, owner: 'admin01'),
      throwsStateError,
    );
    expect(
      () => auth.stores.applicationHistory(original.id, 'leader01'),
      throwsStateError,
    );
    final second = apply(auth, previousId: original.id);
    expect(() => apply(auth, previousId: original.id), throwsStateError);
    expect(() => apply(auth, previousId: second.id), throwsStateError);
    reject(auth, second, reason: '가게 전화번호를 다시 확인해 주세요.');
    final third = apply(auth, previousId: second.id);
    expect(
      auth.stores
          .applicationHistory(third.id, 'hantuck01')
          .map((app) => app.submissionNumber),
      [1, 2, 3],
    );
    expect(auth.stores.latestApplicationsFor('hantuck01'), [third]);
    expect(auth.stores.pendingApplications('admin01'), [third]);
    expect(original.rejectionReason, isNot(second.rejectionReason));
    auth.stores.approve(applicationId: third.id, adminId: 'admin01');
    expect(() => apply(auth, previousId: third.id), throwsStateError);
    expect(() => reject(auth, third), throwsStateError);
  });

  test('invalid or conflicting resubmission leaves rejected source available; same chain duplicate is allowed', () {
    final auth = sample();
    final app = apply(auth);
    reject(auth, app);
    expect(
      () => apply(auth, previousId: app.id, number: '123'),
      throwsStateError,
    );
    final other = apply(
      auth,
      owner: 'store01',
      number: '9999999999',
      address: '다른 가게 주소',
    );
    auth.stores.approve(applicationId: other.id, adminId: 'admin01');
    expect(
      () => apply(
        auth,
        previousId: app.id,
        number: '9999999999',
        address: '다른 가게 주소',
      ),
      throwsStateError,
    );
    expect(app.resubmissionId, isNull);
    expect(auth.stores.canResubmit(app.id, 'hantuck01'), isTrue);
    expect(auth.stores.applicationHistory(app.id, 'hantuck01'), [app]);
    expect(() => apply(auth), throwsStateError);
    final second = apply(auth, previousId: app.id);
    expect(second.submissionNumber, 2);
    expect(auth.stores.canResubmit(app.id, 'hantuck01'), isFalse);
  });

  testWidgets(
    'admin rejects, applicant edits prefilled data and resubmits, admin checks history then approves revised store',
    (tester) async {
      final auth = sample();
      final original = apply(auth);
      await tester.pumpWidget(HantuckApp(authStore: auth));
      await login(tester, 'admin01');
      await review(tester, original.id);
      await tapKey(tester, 'store-reject-${original.id}');
      await tapKey(tester, 'store-rejection-submit');
      expect(find.text('반려 사유를 1~300자로 입력해 주세요.'), findsOneWidget);
      expect(original.status, StoreApplicationStatus.pending);
      await enter(
        tester,
        find.byKey(const ValueKey('store-rejection-reason-input')),
        '상세 주소에 층·호수를 입력해 주세요.',
      );
      await tapKey(tester, 'store-rejection-submit');
      expect(find.byKey(const ValueKey('store-review-empty')), findsOneWidget);
      await logout(tester);
      await login(tester, 'hantuck01');
      expect(find.text('반려'), findsOneWidget);
      expect(find.text('상세 주소에 층·호수를 입력해 주세요.'), findsOneWidget);
      expect(find.byKey(const ValueKey('my-page-manage-store')), findsNothing);
      await tapKey(tester, 'store-resubmit-${original.id}');
      for (final row in [
        ('name', '나눔 카페'),
        ('number', '1234567890'),
        ('address', original.address),
        ('phone', '021234567'),
        ('description', '커피를 함께 나눠요.'),
      ]) {
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(ValueKey('store-application-${row.$1}')),
              )
              .controller!
              .text,
          row.$2,
        );
      }
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(
              find.byKey(const ValueKey('store-application-category')),
            )
            .initialValue,
        '카페·디저트',
      );
      await enter(
        tester,
        find.byKey(const ValueKey('store-application-address')),
        '${original.address}, 1층 101호',
      );
      await tapKey(tester, 'store-application-submit');
      expect(find.text('가게 재신청이 완료됐어요'), findsOneWidget);
      await tapKey(tester, 'store-application-complete-confirm');
      final revised = auth.stores.latestApplicationsFor('hantuck01').single;
      expect(
        find.byKey(ValueKey('my-store-application-${original.id}')),
        findsNothing,
      );
      expect(find.text('2차 신청'), findsOneWidget);
      expect(find.text('심사 대기'), findsOneWidget);
      await tapKey(tester, 'store-history-${revised.id}');
      expect(find.text('1차 신청 · 반려'), findsOneWidget);
      expect(find.text('2차 신청 · 심사 대기'), findsOneWidget);
      expect(find.text('상세 주소에 층·호수를 입력해 주세요.'), findsOneWidget);
      await logout(tester);
      await login(tester, 'admin01');
      await review(tester, revised.id);
      expect(find.text('${original.address}, 1층 101호'), findsOneWidget);
      await tapKey(tester, 'store-review-history');
      expect(find.text(original.address), findsOneWidget);
      await tapKey(tester, 'store-history-back');
      await tapKey(tester, 'store-approve-${revised.id}');
      await logout(tester);
      await login(tester, 'hantuck01');
      expect(find.text('승인 완료'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('my-page-manage-store')),
        findsOneWidget,
      );
      await tapKey(tester, 'nav-stores');
      expect(find.text('나눔 카페'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'canceling rejection or resubmission edits does not alter submitted records',
    (tester) async {
      final auth = sample();
      final app = apply(auth);
      await tester.pumpWidget(HantuckApp(authStore: auth));
      await login(tester, 'admin01');
      await review(tester, app.id);
      await tapKey(tester, 'store-reject-${app.id}');
      await enter(
        tester,
        find.byKey(const ValueKey('store-rejection-reason-input')),
        '취소할 사유',
      );
      await tapKey(tester, 'store-rejection-cancel');
      expect(app.status, StoreApplicationStatus.pending);
      expect(app.rejectionReason, isNull);
      reject(auth, app);
      await tester.pumpAndSettle();
      await logout(tester);
      await login(tester, 'hantuck01');
      await tapKey(tester, 'store-resubmit-${app.id}');
      await enter(
        tester,
        find.byKey(const ValueKey('store-application-name')),
        '저장하지 않은 변경',
      );
      await tapKey(tester, 'store-application-back');
      expect(auth.stores.applicationHistory(app.id, 'hantuck01'), [app]);
      expect(app.name, '나눔 카페');
      await tapKey(tester, 'store-resubmit-${app.id}');
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('store-application-name')),
            )
            .controller!
            .text,
        '나눔 카페',
      );
      await enter(
        tester,
        find.byKey(const ValueKey('store-application-name')),
        '',
      );
      await tapKey(tester, 'store-application-submit');
      expect(find.text('가게 이름을 입력해 주세요.'), findsOneWidget);
      expect(auth.stores.applicationHistory(app.id, 'hantuck01'), [app]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('history and resubmission screens deny unrelated accounts', (
    tester,
  ) async {
    final auth = sample();
    final app = apply(auth);
    reject(auth, app);
    final outsider = auth.signIn('store01', DemoAuthStore.samplePassword)!;
    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        theme: buildHantuckTheme(),
        home: StoreApplicationHistoryScreen(
          auth: auth,
          account: outsider,
          applicationId: app.id,
        ),
      ),
    );
    expect(find.byKey(const ValueKey('store-history-denied')), findsOneWidget);
    expect(find.text('나눔 카페'), findsNothing);
    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        theme: buildHantuckTheme(),
        home: StoreApplicationScreen(
          auth: auth,
          account: outsider,
          resubmissionOf: app.id,
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('store-resubmission-denied')),
      findsOneWidget,
    );
    expect(find.byType(TextFormField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'rejection dialog and long reason history fit a small viewport with enlarged text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final auth = sample();
      final app = apply(auth);
      await tester.pumpWidget(HantuckApp(authStore: auth));
      await login(tester, 'admin01');
      await review(tester, app.id);
      await tapKey(tester, 'store-reject-${app.id}');
      await enter(
        tester,
        find.byKey(const ValueKey('store-rejection-reason-input')),
        '사' * 301,
      );
      final field = tester.widget<TextFormField>(
        find.byKey(const ValueKey('store-rejection-reason-input')),
      );
      expect(field.controller!.text.length, 300);
      await tapKey(tester, 'store-rejection-submit');
      await logout(tester);
      await login(tester, 'hantuck01');
      await tapKey(tester, 'store-history-${app.id}');
      expect(find.text('사' * 300), findsOneWidget);
      await tapKey(tester, 'store-history-back');
      await tapKey(tester, 'store-resubmit-${app.id}');
      await tapKey(tester, 'store-application-submit');
      await tapKey(tester, 'store-application-complete-confirm');
      expect(find.text('2차 신청'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
