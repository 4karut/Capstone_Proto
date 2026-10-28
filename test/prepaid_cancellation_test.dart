import 'dart:io';

import 'package:capstone_proto_02/demo_auth_store.dart';
import 'package:capstone_proto_02/donation_store.dart';
import 'package:capstone_proto_02/group_store.dart';
import 'package:capstone_proto_02/main.dart';
import 'package:capstone_proto_02/prepaid_usage_store.dart';
import 'package:capstone_proto_02/thanks_screen.dart';
import 'package:capstone_proto_02/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'auth_test_helpers.dart';

DemoAuthStore sample({DateTime Function()? now}) => DemoAuthStore(
  groupStore: DemoGroupStore(now: now ?? () => DateTime.utc(2026, 10, 28, 3)),
);
PrepaidUsageReceipt spend(
  DemoAuthStore auth, {
  int amount = 9000,
  String offerId = 'example-store-1',
}) {
  final request = auth.usage.begin(
    offerId: offerId,
    userId: 'leader03',
    userName: '이용자',
  );
  auth.usage.requestAmount(
    requestId: request.id,
    storeId: request.storeId,
    ownerId: 'store01',
    amount: amount,
  );
  return auth.usage.approve(requestId: request.id, userId: 'leader03');
}

UsageCancellation reverse(
  DemoAuthStore auth,
  PrepaidUsageReceipt receipt, {
  String reason = '',
}) => auth.usage.reversePayment(
  receiptId: receipt.id,
  storeId: receipt.storeId,
  ownerId: 'store01',
  reason: reason,
);
int balance(DemoAuthStore auth) =>
    auth.groups.storePrepaidHistory('example-store-1').first.remainingAmount;
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

Future<void> openStoreUsage(WidgetTester tester) async {
  await tapKey(tester, 'my-page-manage-store');
  await tapKey(tester, 'store-manage-usage-notifications');
}

Widget page(Widget child) =>
    MaterialApp(key: UniqueKey(), theme: buildHantuckTheme(), home: child);

void main() {
  test('owner cancellation restores exactly the original allocation and preserves payment history', () {
    final auth = sample();
    final original = auth.groups.storePrepaidHistory('example-store-1').single;
    final receipt = spend(auth);
    expect(balance(auth), 56000);
    final result = reverse(auth, receipt, reason: '  금액 오입력  ');
    final restored = auth.groups.storePrepaidHistory('example-store-1').single;
    expect(restored.id, original.id);
    expect(restored.groupId, original.groupId);
    expect(restored.storeId, original.storeId);
    expect(restored.donorId, original.donorId);
    expect(restored.totalAmount, original.totalAmount);
    expect(restored.usedAmount, 35000);
    expect(restored.remainingAmount, 65000);
    expect(restored.startsOn, original.startsOn);
    expect(restored.expiresOn, original.expiresOn);
    expect(result.reason, '금액 오입력');
    expect(result.createdAt, auth.groups.currentTime);
    expect(result.remainingAmount, 65000);
    expect(receipt.amount, 9000);
    expect(receipt.remainingAmount, 56000);
    expect(
      auth.usage.statusLabel(
        auth.usage.requestForUser(receipt.requestId, 'leader03'),
      ),
      '결제 취소',
    );
    expect(auth.usage.notificationsForDonor('hantuck01'), [receipt]);
    expect(auth.usage.notificationsForStoreOwner('store01'), [receipt]);
  });

  test('canceling an earlier payment preserves later uses and separate donations at the same store', () {
    final auth = sample();
    final earlier = spend(auth);
    final later = spend(auth, amount: 10000);
    auth.donations.complete(
      checkoutId: auth.donations.beginCheckout(),
      type: DonationType.prepaid,
      groupId: 'group-3',
      donorId: 'leader02',
      donorName: '두 번째 후원자',
      amount: 20000,
      storeId: 'example-store-1',
      expiresOn: DateTime(2026, 12, 31),
    );
    final other = auth.groups.prepaidOffersFor('group-3', 'leader03').last;
    spend(auth, amount: 2000, offerId: other.id);
    reverse(auth, earlier);
    final offers = auth.groups.storePrepaidHistory('example-store-1');
    expect(offers.first.usedAmount, 45000);
    expect(offers.first.remainingAmount, 55000);
    expect(offers.last.remainingAmount, 18000);
    expect(later.cancelled, isFalse);
    expect(earlier.cancellation!.remainingAmount, 55000);
    reverse(auth, later);
    expect(balance(auth), 65000);
    expect(offers.last.remainingAmount, 18000);
  });

  test('only the matching store owner can reverse; donor, user and another owned store cannot', () {
    final auth = sample();
    final receipt = spend(auth);
    for (final actor in ['hantuck01', 'leader03', 'leader01', 'admin01']) {
      expect(
        () => auth.usage.reversePayment(
          receiptId: receipt.id,
          storeId: receipt.storeId,
          ownerId: actor,
        ),
        throwsStateError,
      );
    }
    final app = auth.stores.apply(
      ownerId: 'store01',
      ownerName: '사장님',
      name: '두 번째 가게',
      registrationNumber: '1234567890',
      address: '다른 주소',
      category: '한식',
      phoneNumber: '021234567',
    );
    final other = auth.stores.approve(
      applicationId: app.id,
      adminId: 'admin01',
    );
    expect(
      () => auth.usage.reversePayment(
        receiptId: receipt.id,
        storeId: other.id,
        ownerId: 'store01',
      ),
      throwsStateError,
    );
    expect(
      () => auth.usage.reversePayment(
        receiptId: 'not-paid',
        storeId: receipt.storeId,
        ownerId: 'store01',
      ),
      throwsStateError,
    );
    expect(balance(auth), 56000);
    expect(receipt.cancelled, isFalse);
    reverse(auth, receipt);
    expect(
      () => auth.usage.reversePayment(
        receiptId: receipt.id,
        storeId: receipt.storeId,
        ownerId: 'leader03',
      ),
      throwsStateError,
    );
  });

  test('reason is optional and at most 300 graphemes; repeated or reentrant cancellation restores once', () {
    final auth = sample();
    final receipt = spend(auth);
    expect(() => reverse(auth, receipt, reason: '가' * 301), throwsStateError);
    expect(receipt.cancelled, isFalse);
    var groupUpdates = 0;
    var usageUpdates = 0;
    UsageCancellation? reentrant;
    auth.groups.addListener(() {
      groupUpdates++;
      expect(receipt.cancelled, isTrue);
      expect(
        auth.usage.requestForUser(receipt.requestId, 'leader03').status,
        UsageRequestStatus.paymentCancelled,
      );
      reentrant = reverse(auth, receipt, reason: '두 번째 클릭');
    });
    auth.usage.addListener(() => usageUpdates++);
    final result = reverse(auth, receipt, reason: '🙂' * 300);
    expect(result.reason, '🙂' * 300);
    expect(reentrant, same(result));
    expect(reverse(auth, receipt, reason: '다른 사유'), same(result));
    expect(balance(auth), 65000);
    expect(groupUpdates, 1);
    expect(usageUpdates, 1);
    expect(auth.usage.notificationsForDonor('hantuck01'), hasLength(1));
    final blankAuth = sample();
    expect(reverse(blankAuth, spend(blankAuth), reason: ' \n ').reason, '');
  });

  test('cancellation has no age limit and restores expired funds without extending dates or availability', () {
    var now = DateTime.utc(2026, 10, 28, 3);
    final auth = sample(now: () => now);
    final receipt = spend(auth);
    now = DateTime.utc(2027, 2, 1);
    final result = reverse(auth, receipt);
    expect(result.createdAt, now);
    expect(result.expiresOn, DateTime(2026, 11, 27));
    expect(balance(auth), 65000);
    expect(auth.groups.prepaidOffersFor('group-3', 'leader03'), isEmpty);
    expect(
      auth.stores
          .managedPrepaidOffers(
            storeId: 'example-store-1',
            ownerId: 'store01',
            groups: auth.groups,
          )
          .single
          .remainingAmount,
      65000,
    );
  });

  test('fully spent funds become available after reversal but the old QR cannot charge again', () {
    final auth = sample();
    final receipt = spend(auth, amount: 65000);
    final request = auth.usage.requestForUser(receipt.requestId, 'leader03');
    expect(auth.groups.prepaidOffersFor('group-3', 'leader03'), isEmpty);
    reverse(auth, receipt);
    expect(
      auth.groups
          .prepaidOffersFor('group-3', 'leader03')
          .single
          .remainingAmount,
      65000,
    );
    expect(
      () => auth.usage.approve(requestId: request.id, userId: 'leader03'),
      throwsStateError,
    );
    expect(
      () => auth.usage.cancel(requestId: request.id, userId: 'leader03'),
      throwsStateError,
    );
    expect(
      () => auth.usage.findForStore(
        code: request.code,
        storeId: request.storeId,
        ownerId: 'store01',
      ),
      throwsStateError,
    );
    expect(
      () => auth.usage.sendThanks(
        receiptId: receipt.id,
        userId: 'leader03',
        message: '새 감사',
      ),
      throwsStateError,
    );
    final fresh = auth.usage.begin(
      offerId: receipt.offerId,
      userId: 'leader03',
      userName: '이용자',
    );
    expect(fresh.id, isNot(request.id));
    expect(fresh.code, isNot(request.code));
    expect(request.status, UsageRequestStatus.paymentCancelled);
    expect(balance(auth), 65000);
  });

  test('existing thank-you text and photo remain as cancelled history and new messages are blocked', () {
    final auth = sample();
    final receipt = spend(auth);
    final photo = UsagePhoto(
      name: '식사.png',
      bytes: File('assets/images/group-team.png').readAsBytesSync(),
    );
    auth.usage.sendThanks(
      receiptId: receipt.id,
      userId: 'leader03',
      message: '감사합니다.',
      photo: photo,
    );
    final message = receipt.thanks;
    reverse(auth, receipt);
    expect(receipt.thanks, same(message));
    expect(receipt.thanks!.photo, same(photo));
    expect(auth.usage.thanksForDonor('hantuck01'), [receipt]);
    expect(
      () => auth.usage.sendThanks(
        receiptId: receipt.id,
        userId: 'leader03',
        message: '감사합니다.',
        photo: photo,
      ),
      throwsStateError,
    );
  });

  testWidgets(
    'owner can dismiss then confirm cancellation; user and donor see restored cancelled history',
    (tester) async {
      final auth = sample();
      final receipt = spend(auth);
      await tester.pumpWidget(HantuckApp(authStore: auth));
      await login(tester, 'store01');
      await openStoreUsage(tester);
      await tapKey(tester, 'usage-reverse-${receipt.id}');
      await enter(
        tester,
        find.byKey(const ValueKey('usage-cancellation-reason')),
        '저장하지 않을 사유',
      );
      await tapKey(tester, 'usage-cancellation-dismiss');
      expect(balance(auth), 56000);
      expect(receipt.cancelled, isFalse);
      await tapKey(tester, 'usage-reverse-${receipt.id}');
      await enter(
        tester,
        find.byKey(const ValueKey('usage-cancellation-reason')),
        '이용 금액 오입력',
      );
      await tapKey(tester, 'usage-cancellation-confirm');
      expect(balance(auth), 65000);
      expect(find.text('선결제 사용 취소'), findsOneWidget);
      expect(find.text('복구 금액 9,000원'), findsOneWidget);
      expect(find.byKey(ValueKey('usage-reverse-${receipt.id}')), findsNothing);
      await logout(tester);
      await login(tester, 'leader03');
      await tapKey(tester, 'my-page-prepaid-usage');
      expect(find.text('결제 취소 · 9,000원'), findsOneWidget);
      await tapKey(tester, 'usage-request-${receipt.requestId}');
      expect(find.text('취소 후 해당 선결제 잔액 65,000원'), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
      expect(find.byKey(const ValueKey('usage-approve')), findsNothing);
      expect(find.byKey(const ValueKey('usage-open-thanks')), findsNothing);
      await tapKey(tester, 'nav-home');
      expect(find.text('65,000원'), findsOneWidget);
      await logout(tester);
      await login(tester, 'hantuck01');
      await tapKey(tester, 'my-page-usage-notifications');
      expect(find.text('취소 사유: 이용 금액 오입력'), findsOneWidget);
      expect(find.byKey(ValueKey('usage-reverse-${receipt.id}')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'optional reason can be blank and expired restoration is clearly marked on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      var now = DateTime.utc(2026, 10, 28, 3);
      final auth = sample(now: () => now);
      final receipt = spend(auth);
      now = DateTime.utc(2027, 1, 1);
      await tester.pumpWidget(HantuckApp(authStore: auth));
      await login(tester, 'store01');
      await openStoreUsage(tester);
      await tapKey(tester, 'usage-reverse-${receipt.id}');
      await tapKey(tester, 'usage-cancellation-confirm');
      expect(find.text('기한이 종료되어 복구된 잔액을 사용할 수 없어요.'), findsOneWidget);
      expect(find.text('취소 사유: 입력하지 않았어요.'), findsOneWidget);
      expect(auth.groups.prepaidOffersFor('group-3', 'leader03'), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'cancellation removes thank-you editing even if the compose screen is already open',
    (tester) async {
      final auth = sample();
      final receipt = spend(auth);
      final user = auth.signIn('leader03', DemoAuthStore.samplePassword)!;
      await tester.pumpWidget(
        page(
          ThanksComposeScreen(auth: auth, account: user, receiptId: receipt.id),
        ),
      );
      await enter(
        tester,
        find.byKey(const ValueKey('thanks-message')),
        '전송하지 않은 내용',
      );
      reverse(auth, receipt);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('thanks-payment-cancelled')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('thanks-send')), findsNothing);
      expect(find.byKey(const ValueKey('thanks-message')), findsNothing);
      expect(receipt.thanks, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'already sent photo and message remain visible to the donor with a cancellation label',
    (tester) async {
      final auth = sample();
      final receipt = spend(auth);
      auth.usage.sendThanks(
        receiptId: receipt.id,
        userId: 'leader03',
        message: '감사합니다.',
        photo: UsagePhoto(
          name: '식사.png',
          bytes: File('assets/images/group-team.png').readAsBytesSync(),
        ),
      );
      reverse(auth, receipt);
      final donor = auth.signIn('hantuck01', DemoAuthStore.samplePassword)!;
      await tester.pumpWidget(
        page(ReceivedThanksScreen(auth: auth, account: donor)),
      );
      expect(find.text('선결제 사용 취소'), findsOneWidget);
      expect(find.text('감사합니다.'), findsOneWidget);
      expect(
        find.byKey(ValueKey('received-thanks-photo-${receipt.id}')),
        findsOneWidget,
      );
      expect(find.byKey(ValueKey('usage-reverse-${receipt.id}')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
