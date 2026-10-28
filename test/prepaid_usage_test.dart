import 'dart:io';
import 'dart:typed_data';

import 'package:capstone_proto_02/demo_auth_store.dart';
import 'package:capstone_proto_02/donation_store.dart';
import 'package:capstone_proto_02/group_store.dart';
import 'package:capstone_proto_02/main.dart';
import 'package:capstone_proto_02/prepaid_usage_screen.dart';
import 'package:capstone_proto_02/prepaid_usage_store.dart';
import 'package:capstone_proto_02/store_cashier_screen.dart';
import 'package:capstone_proto_02/thanks_screen.dart';
import 'package:capstone_proto_02/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'auth_test_helpers.dart';

DemoAuthStore sample({
  DateTime Function()? now,
  Future<UsagePhoto?> Function()? picker,
}) => DemoAuthStore(
  groupStore: DemoGroupStore(now: now ?? () => DateTime.utc(2026, 10, 28, 3)),
  thanksPhotoPicker: picker,
);
UsagePhoto photo() => UsagePhoto(
  name: '식사.png',
  bytes: File('assets/images/group-team.png').readAsBytesSync(),
);
int balance(DemoAuthStore auth) =>
    auth.groups.storePrepaidHistory('example-store-1').first.remainingAmount;
PrepaidUsageRequest begin(
  DemoAuthStore auth, {
  String user = 'leader03',
  String offerId = 'example-store-1',
}) => auth.usage.begin(offerId: offerId, userId: user, userName: '이용자');
void requestAmount(
  DemoAuthStore auth,
  PrepaidUsageRequest request, [
  int amount = 9000,
]) => auth.usage.requestAmount(
  requestId: request.id,
  storeId: request.storeId,
  ownerId: 'store01',
  amount: amount,
);
PrepaidUsageReceipt use(DemoAuthStore auth, [int amount = 9000]) {
  final request = begin(auth);
  requestAmount(auth, request, amount);
  return auth.usage.approve(requestId: request.id, userId: 'leader03');
}

Future<void> login(WidgetTester tester, String id, {bool myPage = true}) async {
  await enter(tester, loginField('id'), id);
  await enter(tester, loginField('password'), DemoAuthStore.samplePassword);
  await tapKey(tester, 'login-submit');
  if (myPage) await tapKey(tester, 'nav-my-page');
}

Future<void> logout(WidgetTester tester) async {
  await tapKey(tester, 'nav-my-page');
  await tapKey(tester, 'my-page-settings');
  await tapKey(tester, 'account-logout');
}

Future<void> openCashier(WidgetTester tester) async {
  await tapKey(tester, 'my-page-manage-store');
  await tapKey(tester, 'store-manage-cashier');
}

Widget page(Widget child) =>
    MaterialApp(key: UniqueKey(), theme: buildHantuckTheme(), home: child);

void main() {
  test('QR creation and cashier request do not spend; only matching user approval charges once and notifies donor and store', () {
    final auth = sample();
    final request = begin(auth);
    expect(RegExp(r'^\d{6}$').hasMatch(request.code), isTrue);
    expect(request.qrData, 'hantuck:prepaid:${request.code}');
    expect(begin(auth), same(request));
    expect(balance(auth), 65000);
    expect(
      () => auth.usage.approve(requestId: request.id, userId: 'leader03'),
      throwsStateError,
    );
    requestAmount(auth, request);
    expect(balance(auth), 65000);
    expect(request.status, UsageRequestStatus.awaitingUser);
    expect(auth.usage.notificationsForDonor('hantuck01'), isEmpty);
    expect(
      () => auth.usage.approve(requestId: request.id, userId: 'hantuck01'),
      throwsStateError,
    );
    final receipt = auth.usage.approve(
      requestId: request.id,
      userId: ' LEADER03 ',
    );
    expect(balance(auth), 56000);
    expect(receipt.remainingAmount, 56000);
    expect(
      auth.usage.approve(requestId: request.id, userId: 'leader03'),
      same(receipt),
    );
    expect(balance(auth), 56000);
    expect(auth.usage.notificationsForDonor(' HANTUCK01 '), [receipt]);
    expect(auth.usage.notificationsForStoreOwner('store01'), [receipt]);
    expect(auth.usage.notificationsForDonor('leader03'), isEmpty);
    expect(auth.usage.notificationsForStoreOwner('leader03'), isEmpty);
    expect(
      () => auth.usage.findForStore(
        code: request.code,
        storeId: request.storeId,
        ownerId: 'store01',
      ),
      throwsStateError,
    );
    expect(() => requestAmount(auth, request), throwsStateError);
  });

  test(
    'membership, store ownership and amount bounds guard every payment stage',
    () {
      final auth = sample();
      expect(() => begin(auth, user: 'hantuck01'), throwsStateError);
      final request = begin(auth);
      expect(
        () => auth.usage.findForStore(
          code: request.code,
          storeId: request.storeId,
          ownerId: 'hantuck01',
        ),
        throwsStateError,
      );
      expect(
        () => auth.usage.findForStore(
          code: '000000',
          storeId: request.storeId,
          ownerId: 'store01',
        ),
        throwsStateError,
      );
      expect(
        () => auth.usage.requestAmount(
          requestId: request.id,
          storeId: request.storeId,
          ownerId: 'leader03',
          amount: 9000,
        ),
        throwsStateError,
      );
      for (final amount in [0, -1, 65001, 9007199254740992]) {
        expect(() => requestAmount(auth, request, amount), throwsStateError);
      }
      expect(request.amount, isNull);
      expect(balance(auth), 65000);
      requestAmount(auth, request);
      expect(() => requestAmount(auth, request, 10000), throwsStateError);
      expect(request.amount, 9000);
      expect(
        () => auth.usage.requestForUser(request.id, 'leader01'),
        throwsStateError,
      );
    },
  );

  test('cashier cannot read or charge a code for another owned store', () {
    final auth = sample();
    final application = auth.stores.apply(
      ownerId: 'store01',
      ownerName: '사장님',
      name: '두 번째 가게',
      registrationNumber: '1234567890',
      address: '다른 주소',
      category: '한식',
      phoneNumber: '021234567',
    );
    final other = auth.stores.approve(
      applicationId: application.id,
      adminId: 'admin01',
    );
    final request = begin(auth);
    expect(
      () => auth.usage.findForStore(
        code: request.code,
        storeId: other.id,
        ownerId: 'store01',
      ),
      throwsStateError,
    );
    expect(
      () => auth.usage.requestAmount(
        requestId: request.id,
        storeId: other.id,
        ownerId: 'store01',
        amount: 9000,
      ),
      throwsStateError,
    );
    expect(balance(auth), 65000);
  });

  test('cancelled and expired codes do not spend and can be replaced with a unique QR', () {
    var now = DateTime.utc(2026, 10, 28, 3);
    final auth = sample(now: () => now);
    final first = begin(auth);
    requestAmount(auth, first);
    expect(
      () => auth.usage.cancel(requestId: first.id, userId: 'leader01'),
      throwsStateError,
    );
    auth.usage.cancel(requestId: first.id, userId: 'leader03');
    expect(
      () => auth.usage.approve(requestId: first.id, userId: 'leader03'),
      throwsStateError,
    );
    final second = begin(auth);
    expect(second.code, isNot(first.code));
    requestAmount(auth, second);
    now = now.add(const Duration(minutes: 10));
    expect(auth.usage.isExpired(second), isTrue);
    expect(
      () => auth.usage.approve(requestId: second.id, userId: 'leader03'),
      throwsStateError,
    );
    final third = begin(auth);
    expect(third.code, isNot(second.code));
    expect(balance(auth), 65000);
    expect(auth.usage.notificationsForDonor('hantuck01'), isEmpty);
  });

  test('approval rechecks remaining balance when another member uses the same allocation', () {
    final auth = sample();
    auth.groups.joinWithInvitation(
      groupId: 'group-3',
      userId: 'hantuck01',
      code: '123456',
    );
    final first = begin(auth);
    final second = begin(auth, user: 'hantuck01');
    requestAmount(auth, first, 40000);
    requestAmount(auth, second, 40000);
    auth.usage.approve(requestId: first.id, userId: 'leader03');
    expect(balance(auth), 25000);
    expect(
      () => auth.usage.approve(requestId: second.id, userId: 'hantuck01'),
      throwsStateError,
    );
    expect(balance(auth), 25000);
    expect(auth.usage.notificationsForStoreOwner('store01'), hasLength(1));
  });

  test('approval rechecks KST prepaid expiry even when QR has not expired', () {
    var now = DateTime.utc(2026, 11, 27, 14, 55);
    final auth = sample(now: () => now);
    final request = begin(auth);
    requestAmount(auth, request);
    now = DateTime.utc(2026, 11, 27, 15);
    expect(auth.usage.isExpired(request), isFalse);
    expect(
      () => auth.usage.approve(requestId: request.id, userId: 'leader03'),
      throwsStateError,
    );
    expect(balance(auth), 65000);
  });

  test('each receipt goes to its actual donor and a fully spent allocation remains in owner history', () {
    final auth = sample();
    auth.donations.complete(
      checkoutId: auth.donations.beginCheckout(),
      type: DonationType.prepaid,
      groupId: 'group-1',
      donorId: 'leader02',
      donorName: '후원자2',
      amount: 12000,
      storeId: 'example-store-1',
      expiresOn: DateTime(2026, 12, 31),
    );
    final offer = auth.groups.prepaidOffersFor('group-1', 'leader01').single;
    expect(offer.donorId, 'leader02');
    final request = begin(auth, user: 'leader01', offerId: offer.id);
    requestAmount(auth, request, 12000);
    final receipt = auth.usage.approve(
      requestId: request.id,
      userId: 'leader01',
    );
    expect(auth.groups.prepaidOffersFor('group-1', 'leader01'), isEmpty);
    expect(
      auth.groups.storePrepaidHistory('example-store-1').last.usedAmount,
      12000,
    );
    expect(auth.usage.notificationsForDonor('leader02'), [receipt]);
    expect(auth.usage.notificationsForDonor('hantuck01'), isEmpty);
    expect(
      () => auth.usage.cancel(requestId: request.id, userId: 'leader01'),
      throwsStateError,
    );
  });

  test('thanks is optional, limited to 500 graphemes, scoped to donor, and cannot be duplicated or sent by another user', () {
    final auth = sample();
    final receipt = use(auth);
    expect(auth.usage.thanksForDonor('hantuck01'), isEmpty);
    expect(
      () => auth.usage.sendThanks(
        receiptId: receipt.id,
        userId: 'leader01',
        message: '감사합니다',
      ),
      throwsStateError,
    );
    for (final message in ['  ', '가' * 501]) {
      expect(
        () => auth.usage.sendThanks(
          receiptId: receipt.id,
          userId: 'leader03',
          message: message,
        ),
        throwsStateError,
      );
    }
    final attachment = photo();
    auth.usage.sendThanks(
      receiptId: receipt.id,
      userId: 'leader03',
      message: '🙂' * 500,
      photo: attachment,
    );
    auth.usage.sendThanks(
      receiptId: receipt.id,
      userId: 'leader03',
      message: '🙂' * 500,
      photo: attachment,
    );
    expect(auth.usage.thanksForDonor('hantuck01'), [receipt]);
    expect(auth.usage.thanksForDonor('store01'), isEmpty);
    expect(auth.usage.notificationsForDonor('hantuck01'), hasLength(1));
    expect(
      () => auth.usage.sendThanks(
        receiptId: receipt.id,
        userId: 'leader03',
        message: '바뀐 내용',
      ),
      throwsStateError,
    );
    final next = use(auth);
    auth.usage.sendThanks(
      receiptId: next.id,
      userId: 'leader03',
      message: '',
      photo: attachment,
    );
    expect(auth.usage.thanksForDonor('hantuck01'), hasLength(2));
  });

  test(
    'photo rejects oversized or unsupported files and defensively copies bytes',
    () {
      expect(
        () => UsagePhoto(name: 'empty.png', bytes: Uint8List(0)),
        throwsStateError,
      );
      expect(
        () => UsagePhoto(
          name: 'file.png',
          bytes: Uint8List.fromList('plain text'.codeUnits),
        ),
        throwsStateError,
      );
      expect(
        () => UsagePhoto(
          name: 'large.png',
          bytes: Uint8List(UsagePhoto.maxBytes + 1),
        ),
        throwsStateError,
      );
      final bytes = File('assets/images/group-team.png').readAsBytesSync();
      final image = UsagePhoto(name: '식사.png', bytes: bytes);
      bytes[0] = 0;
      expect(image.bytes[0], 137);
      expect(() => image.bytes[0] = 0, throwsUnsupportedError);
    },
  );

  testWidgets(
    'home selection -> QR -> store amount -> user approval -> photo thanks -> donor and store notifications',
    (tester) async {
      final attachment = photo();
      final auth = sample(picker: () async => attachment);
      await tester.pumpWidget(HantuckApp(authStore: auth));
      await login(tester, 'leader03', myPage: false);
      await tapKey(tester, 'prepaid-store-example-store-1');
      expect(
        find.byKey(const ValueKey('prepaid-use-example-store-1')),
        findsNothing,
      );
      await tapKey(tester, 'store-prepaid-offer-example-store-1');
      await tapKey(tester, 'prepaid-use-example-store-1');
      expect(find.byType(QrImageView), findsOneWidget);
      final request = auth.usage.requestsForUser('leader03').single;
      expect(balance(auth), 65000);
      await logout(tester);
      await login(tester, 'store01');
      await openCashier(tester);
      await enter(
        tester,
        find.byKey(const ValueKey('cashier-code')),
        request.code,
      );
      await tapKey(tester, 'cashier-find');
      await enter(
        tester,
        find.byKey(const ValueKey('cashier-amount')),
        '65001',
      );
      await tapKey(tester, 'cashier-request-amount');
      expect(find.byKey(const ValueKey('cashier-error')), findsOneWidget);
      await enter(tester, find.byKey(const ValueKey('cashier-amount')), '9000');
      await tapKey(tester, 'cashier-request-amount');
      expect(
        find.byKey(const ValueKey('cashier-request-result')),
        findsOneWidget,
      );
      expect(balance(auth), 65000);
      await logout(tester);
      await login(tester, 'leader03');
      await tapKey(tester, 'my-page-prepaid-usage');
      await tapKey(tester, 'usage-request-${request.id}');
      expect(find.text('9,000원'), findsOneWidget);
      await tapKey(tester, 'usage-approve');
      expect(find.byKey(const ValueKey('usage-complete')), findsOneWidget);
      expect(balance(auth), 56000);
      await enter(
        tester,
        find.byKey(const ValueKey('thanks-message')),
        '든든한 한 끼 감사합니다.',
      );
      await tapKey(tester, 'thanks-photo-pick');
      expect(
        find.byKey(const ValueKey('thanks-photo-preview')),
        findsOneWidget,
      );
      await tapKey(tester, 'thanks-send');
      expect(find.byKey(const ValueKey('thanks-sent')), findsOneWidget);
      await logout(tester);
      await login(tester, 'hantuck01');
      await tapKey(tester, 'my-page-thanks');
      expect(find.text('든든한 한 끼 감사합니다.'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('received-thanks-photo-usage-receipt-1')),
        findsOneWidget,
      );
      await tapKey(tester, 'received-thanks-back');
      await tapKey(tester, 'my-page-usage-notifications');
      expect(find.text('든든한 한 끼 감사합니다.'), findsOneWidget);
      await logout(tester);
      await login(tester, 'store01');
      await tapKey(tester, 'my-page-manage-store');
      await tapKey(tester, 'store-manage-usage-notifications');
      expect(find.text('9,000원'), findsOneWidget);
      expect(find.text('든든한 한 끼 감사합니다.'), findsNothing);
      expect(
        find.byKey(const ValueKey('received-thanks-photo-usage-receipt-1')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'skipping thanks preserves the usage alert and permits later writing from own history',
    (tester) async {
      final auth = sample();
      final request = begin(auth);
      requestAmount(auth, request);
      await tester.pumpWidget(HantuckApp(authStore: auth));
      await login(tester, 'leader03');
      await tapKey(tester, 'my-page-prepaid-usage');
      await tapKey(tester, 'usage-request-${request.id}');
      await tapKey(tester, 'usage-approve');
      await tapKey(tester, 'thanks-send');
      expect(find.byKey(const ValueKey('thanks-error')), findsOneWidget);
      await tapKey(tester, 'thanks-skip');
      expect(find.text('56,000원'), findsOneWidget);
      expect(auth.usage.notificationsForDonor('hantuck01'), hasLength(1));
      expect(auth.usage.thanksForDonor('hantuck01'), isEmpty);
      await tapKey(tester, 'nav-my-page');
      await tapKey(tester, 'my-page-prepaid-usage');
      await tapKey(tester, 'usage-request-${request.id}');
      await tapKey(tester, 'usage-open-thanks');
      await enter(
        tester,
        find.byKey(const ValueKey('thanks-message')),
        '뒤늦게 감사드려요.',
      );
      await tapKey(tester, 'thanks-send');
      expect(auth.usage.thanksForDonor('hantuck01'), hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'photo picker cancellation keeps selected photo, errors are shown, and attachment can be removed',
    (tester) async {
      var count = 0;
      final attachment = photo();
      final auth = sample(
        picker: () async {
          count++;
          if (count == 1) return attachment;
          if (count == 2) return null;
          throw StateError('사진을 읽을 수 없어요.');
        },
      );
      final receipt = use(auth);
      final account = auth.signIn('leader03', DemoAuthStore.samplePassword)!;
      await tester.pumpWidget(
        page(
          ThanksComposeScreen(
            auth: auth,
            account: account,
            receiptId: receipt.id,
          ),
        ),
      );
      await tapKey(tester, 'thanks-photo-pick');
      await tapKey(tester, 'thanks-photo-pick');
      expect(
        find.byKey(const ValueKey('thanks-photo-preview')),
        findsOneWidget,
      );
      await tapKey(tester, 'thanks-photo-pick');
      expect(find.text('사진을 읽을 수 없어요.'), findsOneWidget);
      await tapKey(tester, 'thanks-photo-remove');
      expect(find.byKey(const ValueKey('thanks-photo-preview')), findsNothing);
      await enter(
        tester,
        find.byKey(const ValueKey('thanks-message')),
        '가' * 501,
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('thanks-message')))
            .controller!
            .text
            .length,
        500,
      );
      await tapKey(tester, 'thanks-send');
      expect(
        auth.usage.thanksForDonor('hantuck01').single.thanks!.photo,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'unrelated accounts see neither QR nor cashier nor thanks from another donor',
    (tester) async {
      final auth = sample();
      final receipt = use(auth);
      auth.usage.sendThanks(
        receiptId: receipt.id,
        userId: 'leader03',
        message: '감사합니다.',
      );
      final outsider = auth.signIn('leader01', DemoAuthStore.samplePassword)!;
      await tester.pumpWidget(
        page(
          PrepaidQrScreen(auth: auth, account: outsider, requestId: 'usage-1'),
        ),
      );
      expect(
        find.byKey(const ValueKey('usage-request-denied')),
        findsOneWidget,
      );
      expect(find.byType(QrImageView), findsNothing);
      await tester.pumpWidget(
        page(
          StoreCashierScreen(
            auth: auth,
            account: outsider,
            storeId: 'example-store-1',
          ),
        ),
      );
      expect(find.byKey(const ValueKey('cashier-denied')), findsOneWidget);
      await tester.pumpWidget(
        page(ReceivedThanksScreen(auth: auth, account: outsider)),
      );
      expect(
        find.byKey(const ValueKey('received-thanks-empty')),
        findsOneWidget,
      );
      expect(find.text('감사합니다.'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'QR, cashier approval and photo thanks fit a 320px viewport with enlarged text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final auth = sample(picker: () async => photo());
      final request = begin(auth);
      final account = auth.signIn('leader03', DemoAuthStore.samplePassword)!;
      final owner = auth.signIn('store01', DemoAuthStore.samplePassword)!;
      await tester.pumpWidget(
        page(
          PrepaidQrScreen(auth: auth, account: account, requestId: request.id),
        ),
      );
      expect(find.byType(QrImageView), findsOneWidget);
      await tester.pumpWidget(
        page(
          StoreCashierScreen(
            auth: auth,
            account: owner,
            storeId: request.storeId,
          ),
        ),
      );
      await enter(
        tester,
        find.byKey(const ValueKey('cashier-code')),
        request.code,
      );
      await tapKey(tester, 'cashier-find');
      await enter(tester, find.byKey(const ValueKey('cashier-amount')), '9000');
      await tapKey(tester, 'cashier-request-amount');
      await tester.pumpWidget(
        page(
          PrepaidQrScreen(auth: auth, account: account, requestId: request.id),
        ),
      );
      await tapKey(tester, 'usage-approve');
      await tapKey(tester, 'thanks-photo-pick');
      await enter(
        tester,
        find.byKey(const ValueKey('thanks-message')),
        '감사합니다.',
      );
      await tapKey(tester, 'thanks-send');
      expect(find.byKey(const ValueKey('thanks-sent')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
