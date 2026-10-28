import 'package:capstone_proto_02/demo_auth_store.dart';
import 'package:capstone_proto_02/donation_store.dart';
import 'package:capstone_proto_02/group_store.dart';
import 'package:capstone_proto_02/main.dart';
import 'package:capstone_proto_02/prepaid_store.dart';
import 'package:capstone_proto_02/prepaid_store_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_helpers.dart';

DemoAuthStore example({DateTime Function()? now}) {
  final auth = DemoAuthStore(
    groupStore: DemoGroupStore(now: now ?? () => DateTime.utc(2026, 10, 28, 3)),
  );
  auth.donations.complete(
    checkoutId: auth.donations.beginCheckout(),
    type: DonationType.prepaid,
    groupId: 'group-3',
    donorId: DemoAuthStore.sampleId,
    donorName: '한나눔',
    amount: 100000,
    storeId: 'example-store-1',
    expiresOn: DateTime(2026, 12, 31),
  );
  return auth;
}

Future<void> leaderLogin(WidgetTester tester) async {
  await enter(tester, loginField('id'), 'leader03');
  await enter(tester, loginField('password'), DemoAuthStore.samplePassword);
  await tapKey(tester, 'login-submit');
}

void main() {
  test('store summary sums funds while preserving allocations and separate group identities', () {
    final auth = example();
    final offers = auth.groups.prepaidOffersFor('group-3', 'leader03');
    final summary = summarizePrepaidStores(offers).single;
    expect(summary.totalAmount, 200000);
    expect(summary.usedAmount, 35000);
    expect(summary.remainingAmount, 165000);
    expect(summary.usageRatio, .175);
    expect(summary.offers.map((offer) => offer.remainingAmount), [
      65000,
      100000,
    ]);
    expect(summary.offers.map((offer) => offer.expiresOn), [
      DateTime(2026, 11, 27),
      DateTime(2026, 12, 31),
    ]);
    final otherGroup = PrepaidStoreOffer(
      id: 'other-group',
      storeId: summary.storeId,
      groupId: 'group-1',
      storeName: summary.storeName,
      totalAmount: 7000,
      usedAmount: 0,
      startsOn: DateTime(2026, 10, 28),
      expiresOn: DateTime(2026, 12, 31),
    );
    final otherStore = PrepaidStoreOffer(
      id: 'other-store',
      storeId: 'another-store',
      groupId: 'group-3',
      storeName: summary.storeName,
      totalAmount: 9000,
      usedAmount: 0,
      startsOn: DateTime(2026, 10, 28),
      expiresOn: DateTime(2026, 12, 31),
    );
    expect(
      summarizePrepaidStores([...offers, otherGroup, otherStore])
          .map((item) => item.remainingAmount),
      [165000, 7000, 9000],
    );
  });

  test('expired allocations leave the aggregate without losing the remaining store', () {
    var now = DateTime.utc(2026, 10, 28, 3);
    final auth = example(now: () => now);
    expect(
      summarizePrepaidStores(
        auth.groups.prepaidOffersFor('group-3', 'leader03'),
      ).single.remainingAmount,
      165000,
    );
    now = DateTime.utc(2026, 11, 27, 15);
    final summary = summarizePrepaidStores(
      auth.groups.prepaidOffersFor('group-3', 'leader03'),
    ).single;
    expect(summary.remainingAmount, 100000);
    expect(summary.offers, hasLength(1));
    expect(summary.offers.single.expiresOn, DateTime(2026, 12, 31));
  });

  testWidgets(
    'group 3 leader sees one store in home and group with two balances in detail',
    (tester) async {
      final auth = example();
      await tester.pumpWidget(HantuckApp(authStore: auth));
      await leaderLogin(tester);
      expect(find.byType(PrepaidStoreCard), findsOneWidget);
      expect(find.text('예시 가게 1'), findsOneWidget);
      expect(find.text('165,000원'), findsOneWidget);
      expect(find.text('그룹 전용 선결제 · 2건'), findsOneWidget);
      expect(find.text('가장 빠른 사용 기한 2026.11.27까지'), findsOneWidget);
      await tapKey(tester, 'prepaid-store-example-store-1');
      expect(find.text('총 잔액 165,000원'), findsOneWidget);
      expect(find.text('기한별 선결제 2건'), findsOneWidget);
      final original = find.byKey(
        const ValueKey('store-prepaid-offer-example-store-1'),
      );
      final added = find.byKey(
        const ValueKey('store-prepaid-offer-prepaid-donation-1'),
      );
      expect(
        find.descendant(of: original, matching: find.text('65,000원')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: original,
          matching: find.text('사용 기한 2026.11.27까지'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: added, matching: find.text('100,000원')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: added, matching: find.text('사용 기한 2026.12.31까지')),
        findsOneWidget,
      );
      await tapKey(tester, 'nav-home');
      await tapKey(tester, 'home-all-groups');
      await tapKey(tester, 'group-card-group-3');
      expect(find.byType(PrepaidStoreCard), findsOneWidget);
      expect(find.text('165,000원'), findsOneWidget);
      await tapKey(tester, 'prepaid-store-example-store-1');
      expect(find.text('예시 그룹 3의 선결제'), findsOneWidget);
      expect(original, findsOneWidget);
      expect(added, findsOneWidget);
    },
  );

  testWidgets(
    'group entry preserves selected group while discovery shows all eligible groups',
    (tester) async {
      final auth = example();
      final join = auth.groups.requestJoin(
        groupId: 'group-1',
        userId: 'leader03',
        userName: '그룹장',
        introduction: '',
      );
      auth.groups.approve(applicationId: join.id, ownerId: 'leader01');
      auth.donations.complete(
        checkoutId: auth.donations.beginCheckout(),
        type: DonationType.prepaid,
        groupId: 'group-1',
        donorId: DemoAuthStore.sampleId,
        donorName: '한나눔',
        amount: 7000,
        storeId: 'example-store-1',
        expiresOn: DateTime(2026, 12, 31),
      );
      await tester.pumpWidget(HantuckApp(authStore: auth));
      await leaderLogin(tester);
      await tapKey(tester, 'home-group-dropdown');
      await tester.tap(find.text('예시 그룹 3').last);
      await tester.pumpAndSettle();
      await tapKey(tester, 'prepaid-store-example-store-1');
      expect(find.text('총 잔액 165,000원'), findsOneWidget);
      expect(find.text('예시 그룹 1 · 선결제 3'), findsNothing);
      expect(
        find.byKey(const ValueKey('store-prepaid-offer-prepaid-donation-2')),
        findsNothing,
      );
      await tapKey(tester, 'nav-stores');
      await tapKey(tester, 'store-card-example-store-1');
      expect(find.text('총 잔액 172,000원'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('store-prepaid-offer-prepaid-donation-2')),
        findsOneWidget,
      );
      expect(find.text('기한별 선결제 3건'), findsOneWidget);
    },
  );

  testWidgets(
    'grouped card and per-allocation detail fit narrow screens with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = example();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, _) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.3)),
            child: HantuckApp(authStore: auth),
          ),
        ),
      );
      await leaderLogin(tester);
      expect(find.byType(PrepaidStoreCard), findsOneWidget);
      await tapKey(tester, 'prepaid-store-example-store-1');
      await tester.ensureVisible(
        find.byKey(const ValueKey('store-prepaid-offer-prepaid-donation-1')),
      );
      await tester.pumpAndSettle();
      expect(find.text('100,000원'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
