import 'package:capstone_proto_02/demo_auth_store.dart';
import 'package:capstone_proto_02/group_store.dart';
import 'package:capstone_proto_02/main.dart';
import 'package:capstone_proto_02/prepaid_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_helpers.dart';

DateTime sampleNow() => DateTime.utc(2026, 10, 28, 3);
DemoAuthStore sampleAuth() =>
    DemoAuthStore(groupStore: DemoGroupStore(now: sampleNow));

Future<void> enterDemoHome(WidgetTester tester, DemoAuthStore auth) async {
  await tester.pumpWidget(HantuckApp(authStore: auth));
  await tapKey(tester, 'login-demo-fill');
  await tapKey(tester, 'login-submit');
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;

  test('favorites are account specific and do not grant membership', () {
    final groups = DemoGroupStore();
    expect(groups.toggleFavorite('group-1', 'HANTUCK01'), isTrue);
    expect(groups.isFavorite('group-1', 'hantuck01'), isTrue);
    expect(groups.isFavorite('group-1', 'leader01'), isFalse);
    expect(groups.memberships('hantuck01'), isEmpty);
    expect(groups.toggleFavorite('group-1', 'hantuck01'), isFalse);
    expect(groups.isFavorite('group-1', 'hantuck01'), isFalse);
  });

  test('sample prepaid funds are only available to group 3 members', () {
    final groups = DemoGroupStore(now: sampleNow);
    expect(groups.prepaidOffersFor('group-3', 'hantuck01'), isEmpty);
    groups.joinWithInvitation(
      groupId: 'group-3',
      userId: 'hantuck01',
      code: '123456',
    );
    final offer = groups.prepaidOffersFor('group-3', 'hantuck01').single;
    expect(offer.totalAmount, 100000);
    expect(offer.usedAmount, 35000);
    expect(offer.remainingAmount, 65000);
    expect(offer.usageRatio, .35);
    expect(offer.daysRemaining(at: sampleNow()), 30);
    expect(groups.prepaidOffersFor('group-1', 'hantuck01'), isEmpty);
    expect(
      groups.prepaidOffersFor(
        'group-3',
        'hantuck01',
        at: DateTime.utc(2026, 11, 27, 15),
      ),
      isEmpty,
    );
  });

  test('prepaid availability includes expiration day in Seoul and excludes exhausted funds', () {
    final offer = PrepaidStoreOffer(
      id: 'test',
      groupId: 'group-3',
      storeName: '가게',
      totalAmount: 100000,
      usedAmount: 35000,
      startsOn: DateTime(2026, 10, 28),
      expiresOn: DateTime(2026, 11, 27),
    );
    expect(
      offer.isAvailable(at: DateTime.utc(2026, 10, 27, 14, 59, 59)),
      isFalse,
    );
    expect(offer.isAvailable(at: DateTime.utc(2026, 10, 27, 15)), isTrue);
    expect(
      offer.isAvailable(at: DateTime.utc(2026, 11, 27, 14, 59, 59)),
      isTrue,
    );
    expect(offer.daysRemaining(at: DateTime.utc(2026, 11, 27, 14)), 0);
    expect(offer.isAvailable(at: DateTime.utc(2026, 11, 27, 15)), isFalse);
    final exhausted = PrepaidStoreOffer(
      id: 'spent',
      groupId: 'group-3',
      storeName: '가게',
      totalAmount: 100000,
      usedAmount: 100000,
      startsOn: DateTime(2026, 10, 28),
      expiresOn: DateTime(2026, 11, 27),
    );
    expect(exhausted.isAvailable(at: sampleNow()), isFalse);
  });

  testWidgets(
    'favorite survives reopening detail and sponsorship opens method selection',
    (tester) async {
      final auth = sampleAuth();
      await enterDemoHome(tester, auth);
      await tapKey(tester, 'home-find-group');
      await enter(
        tester,
        find.byKey(const ValueKey('group-search-query')),
        'HG0001',
      );
      await tapKey(tester, 'group-search-submit');
      await tapKey(tester, 'group-card-group-1');
      await tapKey(tester, 'group-favorite-toggle');
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const ValueKey('group-favorite-toggle')),
            )
            .isSelected,
        isTrue,
      );
      await tapKey(tester, 'group-sponsor');
      expect(find.byKey(const ValueKey('donation-choice')), findsOneWidget);
      await tapKey(tester, 'donation-choice-back');
      await tapKey(tester, 'group-detail-back');
      await tapKey(tester, 'group-card-group-1');
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const ValueKey('group-favorite-toggle')),
            )
            .isSelected,
        isTrue,
      );
      await tapKey(tester, 'group-favorite-toggle');
      expect(
        auth.groups.isFavorite('group-1', DemoAuthStore.sampleId),
        isFalse,
      );
    },
  );

  testWidgets('membership list excludes pending and favorite only groups', (
    tester,
  ) async {
    final auth = sampleAuth();
    auth.groups.toggleFavorite('group-1', DemoAuthStore.sampleId);
    auth.groups.requestJoin(
      groupId: 'group-2',
      userId: DemoAuthStore.sampleId,
      userName: '한나눔',
      introduction: '',
    );
    await enterDemoHome(tester, auth);
    await tapKey(tester, 'home-all-groups');
    expect(find.text('소속 그룹 리스트'), findsOneWidget);
    expect(find.byKey(const ValueKey('member-groups-empty')), findsOneWidget);
    for (final id in ['group-1', 'group-2', 'group-3']) {
      expect(find.byKey(ValueKey('group-card-$id')), findsNothing);
    }
    await tapKey(tester, 'member-groups-find');
    expect(find.byKey(const ValueKey('group-card-group-1')), findsOneWidget);
  });

  testWidgets(
    'joined groups list shows descriptions and opens group specific prepaid benefits',
    (tester) async {
      final auth = sampleAuth();
      final application = auth.groups.requestJoin(
        groupId: 'group-1',
        userId: DemoAuthStore.sampleId,
        userName: '한나눔',
        introduction: '',
      );
      auth.groups.approve(applicationId: application.id, ownerId: 'leader01');
      auth.groups.joinWithInvitation(
        groupId: 'group-3',
        userId: DemoAuthStore.sampleId,
        code: '123456',
      );
      auth.groups.toggleFavorite('group-3', DemoAuthStore.sampleId);
      await enterDemoHome(tester, auth);
      await tapKey(tester, 'home-all-groups');
      expect(find.byKey(const ValueKey('group-card-group-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('group-card-group-2')), findsNothing);
      expect(find.byKey(const ValueKey('group-card-group-3')), findsOneWidget);
      expect(
        find.text(DemoGroupStore.allGroups[2].description),
        findsOneWidget,
      );
      await tapKey(tester, 'group-card-group-3');
      expect(find.text('소속 그룹'), findsOneWidget);
      expect(find.text('예시 가게 1'), findsOneWidget);
      expect(find.text('35,000원'), findsOneWidget);
      expect(find.text('65,000원'), findsOneWidget);
      expect(find.text('30일 남음'), findsOneWidget);
      expect(find.byKey(const ValueKey('group-apply')), findsNothing);
      await tapKey(tester, 'group-detail-back');
      await tapKey(tester, 'group-card-group-1');
      expect(
        find.byKey(const ValueKey('group-empty-prepaid-stores')),
        findsOneWidget,
      );
      expect(find.text('예시 가게 1'), findsNothing);
    },
  );

  testWidgets(
    'member list and prepaid amounts fit a small screen with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = sampleAuth();
      auth.groups.joinWithInvitation(
        groupId: 'group-3',
        userId: DemoAuthStore.sampleId,
        code: '123456',
      );
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, _) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.3)),
            child: HantuckApp(authStore: auth),
          ),
        ),
      );
      await tapKey(tester, 'login-demo-fill');
      await tapKey(tester, 'login-submit');
      expect(find.text('예시 가게 1'), findsOneWidget);
      await tapKey(tester, 'home-all-groups');
      await tapKey(tester, 'group-card-group-3');
      await tapKey(tester, 'group-favorite-toggle');
      await tester.ensureVisible(
        find.byKey(const ValueKey('prepaid-period-example-store-1')),
      );
      await tester.pumpAndSettle();
      expect(find.text('65,000원'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
