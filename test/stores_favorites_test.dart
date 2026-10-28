import 'package:capstone_proto_02/demo_auth_store.dart';
import 'package:capstone_proto_02/group_detail_screen.dart';
import 'package:capstone_proto_02/group_store.dart';
import 'package:capstone_proto_02/home_screen.dart';
import 'package:capstone_proto_02/login_screen.dart';
import 'package:capstone_proto_02/main.dart';
import 'package:capstone_proto_02/store_catalog.dart';
import 'package:capstone_proto_02/store_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_helpers.dart';

DemoAuthStore sampleAuth({DateTime? at}) => DemoAuthStore(
  groupStore: DemoGroupStore(now: () => at ?? DateTime.utc(2026, 10, 28, 3)),
);

void joinStoreGroup(DemoAuthStore auth) => auth.groups.joinWithInvitation(
  groupId: 'group-3',
  userId: DemoAuthStore.sampleId,
  code: '123456',
);

Future<void> openApp(WidgetTester tester, DemoAuthStore auth) async {
  await tester.pumpWidget(HantuckApp(authStore: auth));
  await tapKey(tester, 'login-demo-fill');
  await tapKey(tester, 'login-submit');
}

Future<void> storeSearch(WidgetTester tester, String query) async {
  await enter(tester, find.byKey(const ValueKey('store-search-query')), query);
  await tapKey(tester, 'store-search-submit');
}

void main() {
  test('catalog search includes all stores while prepaid eligibility requires membership', () {
    final auth = sampleAuth();
    List<DemoStore> search([String query = '']) =>
        auth.stores.searchAll(query: query);
    expect(search().map((store) => store.id), ['example-store-1']);
    expect(
      auth.stores.searchAvailable(
        userId: DemoAuthStore.sampleId,
        groups: auth.groups,
      ),
      isEmpty,
    );
    auth.groups.toggleFavorite('group-3', DemoAuthStore.sampleId);
    auth.groups.requestJoin(
      groupId: 'group-1',
      userId: DemoAuthStore.sampleId,
      userName: '한나눔',
      introduction: '',
    );
    expect(search(), hasLength(1));
    joinStoreGroup(auth);
    expect(
      auth.stores.searchAvailable(
        userId: DemoAuthStore.sampleId,
        groups: auth.groups,
      ),
      hasLength(1),
    );
    expect(search().map((store) => store.id), ['example-store-1']);
    expect(search('  예시가게 1  '), hasLength(1));
    for (final query in ['마포구', '나눔로', '한식', '따뜻한 마음', 'unknown']) {
      expect(
        search(query),
        isEmpty,
        reason: 'Only store names are searchable.',
      );
    }
    expect(
      auth.stores.searchAvailable(userId: 'leader01', groups: auth.groups),
      isEmpty,
    );
  });

  test('expired prepaid loses eligibility while the store remains discoverable and saved', () {
    final auth = sampleAuth(at: DateTime.utc(2026, 11, 27, 15));
    joinStoreGroup(auth);
    auth.stores.toggleFavorite('example-store-1', DemoAuthStore.sampleId);
    expect(
      auth.stores.searchAvailable(
        userId: DemoAuthStore.sampleId,
        groups: auth.groups,
      ),
      isEmpty,
    );
    expect(auth.stores.favoritesFor(DemoAuthStore.sampleId), hasLength(1));
    expect(auth.stores.searchAll(query: '예시가게'), hasLength(1));
    expect(
      auth.stores.offersFor(
        'example-store-1',
        DemoAuthStore.sampleId,
        auth.groups,
      ),
      isEmpty,
    );
  });

  test(
    'store and group favorites are separate and scoped to normalized user IDs',
    () {
      final auth = sampleAuth();
      expect(
        auth.stores.toggleFavorite('example-store-1', ' HANTUCK01 '),
        isTrue,
      );
      expect(auth.stores.favoritesFor('hantuck01'), hasLength(1));
      expect(auth.stores.favoritesFor('leader03'), isEmpty);
      expect(auth.groups.favoritesFor('hantuck01'), isEmpty);
      auth.groups.toggleFavorite('group-1', 'hantuck01');
      expect(auth.groups.favoritesFor(' HANTUCK01 ').single.id, 'group-1');
      expect(
        auth.stores.toggleFavorite('example-store-1', 'hantuck01'),
        isFalse,
      );
      expect(auth.stores.favoritesFor('hantuck01'), isEmpty);
    },
  );

  testWidgets(
    'first user can browse and bookmark stores without joining a group',
    (tester) async {
      final auth = sampleAuth();
      await openApp(tester, auth);
      await tapKey(tester, 'nav-stores');
      expect(find.byKey(const ValueKey('store-search-empty')), findsNothing);
      expect(
        find.byKey(const ValueKey('store-card-example-store-1')),
        findsOneWidget,
      );
      expect(find.text('현재 이용 가능한 선결제가 없어요'), findsOneWidget);
      await tapKey(tester, 'nav-favorites');
      expect(
        find.byKey(const ValueKey('favorites-groups-empty')),
        findsOneWidget,
      );
      await tapKey(tester, 'favorites-stores-tab');
      expect(
        find.byKey(const ValueKey('favorites-stores-empty')),
        findsOneWidget,
      );
      await tapKey(tester, 'favorites-find-store');
      await storeSearch(tester, '예시가게');
      await tapKey(tester, 'store-card-example-store-1');
      expect(find.byType(StoreDetailScreen), findsOneWidget);
      expect(find.text('현재 이용 가능한 선결제가 없어요'), findsOneWidget);
      await tapKey(tester, 'store-favorite-toggle');
      await tapKey(tester, 'nav-favorites');
      expect(
        find.byKey(const ValueKey('store-card-example-store-1')),
        findsOneWidget,
      );
      expect(
        auth.stores.isFavorite('example-store-1', DemoAuthStore.sampleId),
        isTrue,
      );
      expect(auth.groups.memberships(DemoAuthStore.sampleId), isEmpty);
      await tapKey(tester, 'nav-home');
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('home-empty-stores')), findsOneWidget);
      final barY = tester.getBottomRight(find.byType(NavigationBar)).dy;
      await tester.ensureVisible(find.byKey(const ValueKey('home-logout')));
      await tester.pumpAndSettle();
      expect(tester.getBottomRight(find.byType(NavigationBar)).dy, barY);
      await tapKey(tester, 'home-logout');
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    },
  );

  testWidgets(
    'available stores search by name, open details, save, reopen and remove',
    (tester) async {
      final auth = sampleAuth();
      joinStoreGroup(auth);
      await openApp(tester, auth);
      await tapKey(tester, 'nav-stores');
      await storeSearch(tester, '마포구');
      expect(
        find.byKey(const ValueKey('store-search-no-results')),
        findsOneWidget,
      );
      await storeSearch(tester, '예시가게');
      await tapKey(tester, 'store-card-example-store-1');
      expect(find.byType(StoreDetailScreen), findsOneWidget);
      expect(
        find.text(DemoStoreCatalog.allStores.single.address),
        findsOneWidget,
      );
      expect(find.text('따뜻한 집밥 정식'), findsOneWidget);
      expect(find.text('9,000원'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      await tapKey(tester, 'store-favorite-toggle');
      expect(
        auth.stores.isFavorite('example-store-1', DemoAuthStore.sampleId),
        isTrue,
      );
      await tapKey(tester, 'nav-favorites');
      expect(find.byType(StoreDetailScreen), findsNothing);
      await tapKey(tester, 'favorites-stores-tab');
      await tapKey(tester, 'store-card-example-store-1');
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const ValueKey('store-favorite-toggle')),
            )
            .isSelected,
        isTrue,
      );
      await tapKey(tester, 'store-favorite-toggle');
      await tapKey(tester, 'store-detail-back');
      expect(
        find.byKey(const ValueKey('favorites-stores-empty')),
        findsOneWidget,
      );
      await tapKey(tester, 'nav-home');
      await tapKey(tester, 'prepaid-store-example-store-1');
      expect(find.byType(StoreDetailScreen), findsOneWidget);
    },
  );

  testWidgets(
    'favorite group opens shared detail and application returns to home tab',
    (tester) async {
      final auth = sampleAuth();
      auth.groups.toggleFavorite('group-1', DemoAuthStore.sampleId);
      await openApp(tester, auth);
      await tapKey(tester, 'nav-favorites');
      expect(
        find.text(DemoGroupStore.allGroups.first.description),
        findsOneWidget,
      );
      await tapKey(tester, 'group-card-group-1');
      expect(find.byType(GroupDetailScreen), findsOneWidget);
      await tapKey(tester, 'group-apply');
      await tapKey(tester, 'group-request-submit');
      await tapKey(tester, 'group-complete-confirm');
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
      expect(find.text('승인 대기'), findsOneWidget);
    },
  );

  testWidgets('store detail and favorite tabs fit 320px with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = sampleAuth();
    joinStoreGroup(auth);
    auth.groups.toggleFavorite('group-1', DemoAuthStore.sampleId);
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
    await tapKey(tester, 'nav-stores');
    await tapKey(tester, 'store-card-example-store-1');
    await tapKey(tester, 'store-favorite-toggle');
    await tester.ensureVisible(find.byKey(const ValueKey('store-menu-채소 비빔밥')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tapKey(tester, 'nav-favorites');
    await tapKey(tester, 'favorites-stores-tab');
    await tapKey(tester, 'favorites-groups-tab');
    expect(find.byKey(const ValueKey('group-card-group-1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
