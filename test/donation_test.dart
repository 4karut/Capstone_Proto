import 'package:capstone_proto_02/demo_auth_store.dart';
import 'package:capstone_proto_02/donation_store.dart';
import 'package:capstone_proto_02/group_store.dart';
import 'package:capstone_proto_02/home_screen.dart';
import 'package:capstone_proto_02/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_helpers.dart';

DemoAuthStore sampleAuth({DateTime Function()? now}) => DemoAuthStore(
  groupStore: DemoGroupStore(now: now ?? () => DateTime.utc(2026, 10, 28, 3)),
);

DemoDonation donate(
  DemoAuthStore auth, {
  DonationType type = DonationType.money,
  String groupId = 'group-1',
  int amount = 50000,
  String? checkoutId,
  String? storeId = 'example-store-1',
  DateTime? deadline,
}) => auth.donations.complete(
  checkoutId: checkoutId ?? auth.donations.beginCheckout(),
  type: type,
  groupId: groupId,
  donorId: DemoAuthStore.sampleId,
  donorName: '한나눔',
  amount: amount,
  storeId: type == DonationType.prepaid ? storeId : null,
  expiresOn: type == DonationType.prepaid
      ? deadline ?? DateTime(2026, 11, 27)
      : null,
);

Future<void> login(
  WidgetTester tester, {
  String id = DemoAuthStore.sampleId,
}) async {
  await enter(tester, loginField('id'), id);
  await enter(tester, loginField('password'), DemoAuthStore.samplePassword);
  await tapKey(tester, 'login-submit');
}

Future<void> openDonation(
  WidgetTester tester,
  DemoAuthStore auth,
  DonationType type, {
  bool startApp = true,
}) async {
  if (startApp) {
    await tester.pumpWidget(HantuckApp(authStore: auth));
    await login(tester);
  }
  await tapKey(tester, 'home-find-group');
  await enter(
    tester,
    find.byKey(const ValueKey('group-search-query')),
    'HG0001',
  );
  await tapKey(tester, 'group-search-submit');
  await tapKey(tester, 'group-card-group-1');
  await tapKey(tester, 'group-sponsor');
  await tapKey(
    tester,
    type == DonationType.money
        ? 'donation-choose-money'
        : 'donation-choose-prepaid',
  );
}

Future<void> enterAmount(WidgetTester tester, String amount) =>
    enter(tester, find.byKey(const ValueKey('donation-amount')), amount);
Future<void> enterDeadline(WidgetTester tester, String date) =>
    enter(tester, find.byKey(const ValueKey('donation-deadline')), date);

void main() {
  test('amount and deadline parsing preserve whole won and reject invalid calendar dates', () {
    for (final input in ['', '0', '-1', '1.5', '1,000', '9007199254740992']) {
      expect(parseDonationAmount(input), isNull);
    }
    expect(parseDonationAmount(' 10000 '), 10000);
    expect(parseDonationDeadline('20261127'), DateTime(2026, 11, 27));
    expect(parseDonationDeadline('2026.11.27'), DateTime(2026, 11, 27));
    expect(parseDonationDeadline('2028-02-29'), DateTime(2028, 2, 29));
    for (final input in ['', '20260229', '20261301', '2026-1-01', '00000101']) {
      expect(parseDonationDeadline(input), isNull);
    }
  });

  test('cash donation notifies only target group owner without granting membership or store benefits', () {
    final auth = sampleAuth();
    donate(auth);
    expect(
      auth.donations.notificationsForGroupOwner(' LEADER01 ').single.amount,
      50000,
    );
    expect(auth.donations.notificationsForGroupOwner('leader02'), isEmpty);
    expect(
      auth.donations.notificationsForGroupOwner(DemoAuthStore.sampleId),
      isEmpty,
    );
    expect(auth.donations.notificationsForStoreOwner('store01'), isEmpty);
    expect(auth.groups.isMember('group-1', DemoAuthStore.sampleId), isFalse);
    expect(auth.groups.prepaidOffersFor('group-1', 'leader01'), isEmpty);
  });

  test('prepaid creates separate allocations and one store result with account-scoped notifications', () {
    final auth = sampleAuth();
    final receipt = donate(auth, type: DonationType.prepaid);
    donate(
      auth,
      type: DonationType.prepaid,
      amount: 30000,
      deadline: DateTime(2026, 12, 15),
    );
    final offers = auth.groups.prepaidOffersFor('group-1', 'leader01');
    expect(offers.map((offer) => offer.storeId), [
      'example-store-1',
      'example-store-1',
    ]);
    expect(offers.map((offer) => offer.remainingAmount), [50000, 30000]);
    expect(offers.every((offer) => offer.usedAmount == 0), isTrue);
    expect(offers.map((offer) => offer.expiresOn), [
      DateTime(2026, 11, 27),
      DateTime(2026, 12, 15),
    ]);
    expect(
      auth.stores.searchAvailable(userId: 'leader01', groups: auth.groups),
      hasLength(1),
    );
    expect(
      auth.stores.offersFor('example-store-1', 'leader01', auth.groups),
      hasLength(2),
    );
    expect(
      auth.stores.searchAvailable(
        userId: DemoAuthStore.sampleId,
        groups: auth.groups,
      ),
      isEmpty,
    );
    expect(
      auth.donations.notificationsForStoreOwner(' STORE01 ').last.id,
      receipt.id,
    );
    expect(auth.donations.notificationsForStoreOwner('leader01'), isEmpty);
    expect(auth.donations.notificationsForGroupOwner('leader02'), isEmpty);
    expect(
      sampleAuth().groups.prepaidOffersFor('group-1', 'leader01'),
      isEmpty,
    );
  });

  test('same checkout is idempotent and changed or invalid payment data cannot add funds or alerts', () {
    final auth = sampleAuth();
    final checkout = auth.donations.beginCheckout();
    final first = donate(
      auth,
      type: DonationType.prepaid,
      checkoutId: checkout,
    );
    expect(
      donate(auth, type: DonationType.prepaid, checkoutId: checkout),
      same(first),
    );
    expect(
      () => donate(
        auth,
        type: DonationType.prepaid,
        checkoutId: checkout,
        amount: 60000,
      ),
      throwsStateError,
    );
    expect(() => donate(auth, amount: 0), throwsStateError);
    expect(
      () => donate(
        auth,
        type: DonationType.prepaid,
        deadline: DateTime(2026, 10, 27),
      ),
      throwsStateError,
    );
    expect(
      () => donate(auth, type: DonationType.prepaid, storeId: null),
      throwsStateError,
    );
    expect(
      () => donate(auth, type: DonationType.prepaid, storeId: 'missing'),
      throwsStateError,
    );
    expect(auth.groups.prepaidOffersFor('group-1', 'leader01'), hasLength(1));
    expect(auth.donations.notificationsForGroupOwner('leader01'), hasLength(1));
    expect(auth.donations.notificationsForStoreOwner('store01'), hasLength(1));
  });

  test(
    'today is allowed through the final Korean calendar day then expires',
    () {
      var now = DateTime.utc(2026, 10, 28, 14, 59, 59);
      final auth = sampleAuth(now: () => now);
      donate(
        auth,
        type: DonationType.prepaid,
        deadline: DateTime(2026, 10, 28),
      );
      expect(auth.groups.prepaidOffersFor('group-1', 'leader01'), hasLength(1));
      now = DateTime.utc(2026, 10, 28, 15);
      expect(auth.groups.prepaidOffersFor('group-1', 'leader01'), isEmpty);
      expect(
        () => donate(
          auth,
          type: DonationType.prepaid,
          deadline: DateTime(2026, 10, 28),
        ),
        throwsStateError,
      );
      expect(
        auth.donations.notificationsForStoreOwner('store01'),
        hasLength(1),
      );
    },
  );

  testWidgets(
    'cash flow validates, completes once, returns home and appears in leader alerts only',
    (tester) async {
      final auth = sampleAuth();
      await openDonation(tester, auth, DonationType.money);
      expect(find.text('예시 그룹 1'), findsOneWidget);
      expect(find.byKey(const ValueKey('donation-store')), findsNothing);
      expect(find.byKey(const ValueKey('donation-deadline')), findsNothing);
      await tapKey(tester, 'donation-confirm');
      expect(find.text('1원 이상의 올바른 금액을 입력해 주세요.'), findsOneWidget);
      await enterAmount(tester, '50000');
      await tapKey(tester, 'donation-confirm');
      expect(find.text('결제가 완료됐습니다'), findsOneWidget);
      expect(find.text('50,000원'), findsOneWidget);
      await tapKey(tester, 'donation-complete-confirm');
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
      await tapKey(tester, 'home-logout');
      await login(tester, id: 'leader01');
      await tapKey(tester, 'home-donation-notifications');
      expect(find.text('도착한 후원 1건'), findsOneWidget);
      expect(find.text('금액 후원'), findsOneWidget);
      await tapKey(tester, 'donation-notifications-back');
      await tapKey(tester, 'home-logout');
      await login(tester, id: 'store01');
      await tapKey(tester, 'home-store-donation-notifications');
      expect(
        find.byKey(const ValueKey('donation-notifications-empty')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'prepaid selects from all stores, validates deadline and updates joined group home and store search',
    (tester) async {
      final auth = sampleAuth();
      final application = auth.groups.requestJoin(
        groupId: 'group-1',
        userId: DemoAuthStore.sampleId,
        userName: '한나눔',
        introduction: '',
      );
      auth.groups.approve(applicationId: application.id, ownerId: 'leader01');
      await openDonation(tester, auth, DonationType.prepaid);
      await tapKey(tester, 'donation-confirm');
      expect(find.text('선결제할 가게를 선택해 주세요.'), findsOneWidget);
      await tapKey(tester, 'donation-store');
      await enter(
        tester,
        find.byKey(const ValueKey('donation-store-search-query')),
        '마포구',
      );
      await tapKey(tester, 'donation-store-search-submit');
      expect(
        find.byKey(const ValueKey('donation-store-search-empty')),
        findsOneWidget,
      );
      await enter(
        tester,
        find.byKey(const ValueKey('donation-store-search-query')),
        '예시가게',
      );
      await tapKey(tester, 'donation-store-search-submit');
      await tapKey(tester, 'donation-store-option-example-store-1');
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('donation-store')))
            .controller!
            .text,
        '예시 가게 1',
      );
      await enterAmount(tester, '20000');
      await enterDeadline(tester, '20260229');
      await tapKey(tester, 'donation-confirm');
      expect(find.text('올바른 날짜를 입력해 주세요. 예: 20261127'), findsOneWidget);
      await enterDeadline(tester, '20261027');
      await tapKey(tester, 'donation-confirm');
      expect(find.text('오늘 또는 이후 날짜를 선택해 주세요.'), findsOneWidget);
      await enterDeadline(tester, '20261028');
      await tapKey(tester, 'donation-confirm');
      expect(find.text('결제가 완료됐습니다'), findsOneWidget);
      await tapKey(tester, 'donation-complete-confirm');
      expect(find.text('20,000원'), findsOneWidget);
      await tapKey(tester, 'nav-stores');
      expect(
        find.byKey(const ValueKey('store-card-example-store-1')),
        findsOneWidget,
      );
      await tapKey(tester, 'store-card-example-store-1');
      expect(find.text('예시 그룹 1 · 선결제 1'), findsOneWidget);
      expect(find.text('총 잔액 20,000원'), findsOneWidget);
      await tapKey(tester, 'nav-home');
      await tapKey(tester, 'home-logout');
      await login(tester, id: 'store01');
      await tapKey(tester, 'home-store-donation-notifications');
      expect(find.text('선결제 후원'), findsOneWidget);
      expect(find.text('20,000원'), findsOneWidget);
    },
  );

  testWidgets(
    'favorite picker fills selected store and cancellation preserves form without creating payment',
    (tester) async {
      final auth = sampleAuth();
      await openDonation(tester, auth, DonationType.prepaid);
      await enterAmount(tester, '30000');
      await enterDeadline(tester, '20261127');
      await tapKey(tester, 'donation-store');
      await tapKey(tester, 'donation-store-favorites');
      expect(
        find.byKey(const ValueKey('donation-store-favorites-empty')),
        findsOneWidget,
      );
      await tapKey(tester, 'donation-store-favorites-back');
      await tapKey(tester, 'donation-store-picker-back');
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('donation-amount')),
            )
            .controller!
            .text,
        '30000',
      );
      auth.stores.toggleFavorite('example-store-1', DemoAuthStore.sampleId);
      await tapKey(tester, 'donation-store');
      await tapKey(tester, 'donation-store-favorites');
      await tapKey(tester, 'donation-store-option-example-store-1');
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('donation-store')))
            .controller!
            .text,
        '예시 가게 1',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('donation-deadline')),
            )
            .controller!
            .text,
        '20261127',
      );
      await tapKey(tester, 'donation-form-back');
      expect(auth.donations.notificationsForGroupOwner('leader01'), isEmpty);
      expect(auth.groups.prepaidOffersFor('group-1', 'leader01'), isEmpty);
    },
  );

  testWidgets(
    'calendar, prepaid form and completion fit a small screen with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = sampleAuth();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, _) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.3)),
            child: HantuckApp(authStore: auth),
          ),
        ),
      );
      await login(tester);
      await openDonation(tester, auth, DonationType.prepaid, startApp: false);
      await tapKey(tester, 'donation-date-picker');
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.text('선택').last);
      await tester.pumpAndSettle();
      await tapKey(tester, 'donation-store');
      await tapKey(tester, 'donation-store-option-example-store-1');
      await enterAmount(tester, '10000');
      await tapKey(tester, 'donation-confirm');
      expect(find.text('결제가 완료됐습니다'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tapKey(tester, 'donation-complete-confirm');
      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );
}
