import 'package:capstone_proto_02/demo_auth_store.dart';
import 'package:capstone_proto_02/donation_notifications_screen.dart';
import 'package:capstone_proto_02/donation_store.dart';
import 'package:capstone_proto_02/group_store.dart';
import 'package:capstone_proto_02/main.dart';
import 'package:capstone_proto_02/store_catalog.dart';
import 'package:capstone_proto_02/store_detail_screen.dart';
import 'package:capstone_proto_02/store_management_screen.dart';
import 'package:capstone_proto_02/store_owner_prepaid_screen.dart';
import 'package:capstone_proto_02/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_helpers.dart';

DemoAuthStore sample({DateTime Function()? now}) => DemoAuthStore(
  groupStore: DemoGroupStore(now: now ?? () => DateTime.utc(2026, 10, 28, 3)),
);

StoreApplication applyStore(
  DemoAuthStore auth, {
  String owner = DemoAuthStore.sampleId,
  String name = '나눔 카페',
  String number = '123-45-67890',
  String address = '서울특별시 마포구 나눔로 20',
}) => auth.stores.apply(
  ownerId: owner,
  ownerName: '신청자',
  name: name,
  registrationNumber: number,
  address: address,
  category: '카페·디저트',
  phoneNumber: '02-123-4567',
  description: '커피 한 잔의 여유를 나눠요.',
);

DemoStore approvedStore(
  DemoAuthStore auth, {
  String owner = DemoAuthStore.sampleId,
}) => auth.stores.approve(
  applicationId: applyStore(auth, owner: owner).id,
  adminId: 'admin01',
);

void donate(
  DemoAuthStore auth,
  String storeId, {
  String groupId = 'group-1',
  int amount = 30000,
}) {
  auth.donations.complete(
    checkoutId: auth.donations.beginCheckout(),
    type: DonationType.prepaid,
    groupId: groupId,
    donorId: 'leader02',
    donorName: '후원자',
    amount: amount,
    storeId: storeId,
    expiresOn: DateTime(2026, 12, 31),
  );
}

Future<void> login(WidgetTester tester, String id) async {
  await enter(tester, loginField('id'), id);
  await enter(tester, loginField('password'), DemoAuthStore.samplePassword);
  await tapKey(tester, 'login-submit');
}

Future<void> logout(WidgetTester tester) async {
  await tapKey(tester, 'nav-my-page');
  await tapKey(tester, 'my-page-settings');
  await tapKey(tester, 'account-logout');
}

Future<void> fillApplication(WidgetTester tester) async {
  await enter(
    tester,
    find.byKey(const ValueKey('store-application-name')),
    '나눔 카페',
  );
  await enter(
    tester,
    find.byKey(const ValueKey('store-application-number')),
    '123-45-67890',
  );
  await enter(
    tester,
    find.byKey(const ValueKey('store-application-address')),
    '서울특별시 마포구 나눔로 20',
  );
  await tapKey(tester, 'store-application-category');
  await tester.tap(find.text('카페·디저트').last);
  await tester.pumpAndSettle();
  await enter(
    tester,
    find.byKey(const ValueKey('store-application-phone')),
    '02-123-4567',
  );
  await enter(
    tester,
    find.byKey(const ValueKey('store-application-description')),
    '커피 한 잔의 여유를 나눠요.',
  );
}

Widget page(Widget screen) =>
    MaterialApp(key: UniqueKey(), theme: buildHantuckTheme(), home: screen);

void main() {
  test('only seeded admin reviews applications; public catalog changes only on approval', () {
    final auth = sample();
    final app = applyStore(auth);
    expect(auth.stores.searchAll(query: '나눔'), isEmpty);
    expect(auth.stores.ownedStores(DemoAuthStore.sampleId), isEmpty);
    expect(auth.stores.applicationsFor(' HANTUCK01 ').single, app);
    expect(auth.stores.applicationsFor('store01'), isEmpty);
    expect(() => auth.stores.pendingApplications('store01'), throwsStateError);
    expect(
      () => auth.stores.approve(applicationId: app.id, adminId: 'hantuck01'),
      throwsStateError,
    );
    expect(auth.stores.pendingApplications(' ADMIN01 ').single, app);
    final store = auth.stores.approve(
      applicationId: app.id,
      adminId: 'admin01',
    );
    expect(app.approved, isTrue);
    expect(app.storeId, store.id);
    expect(auth.stores.searchAll(query: '나눔 카페').single, store);
    expect(auth.stores.pendingApplications('admin01'), isEmpty);
    expect(auth.stores.ownedStores(' HANTUCK01 ').single.id, store.id);
    expect(
      auth.stores.approve(applicationId: app.id, adminId: 'admin01'),
      same(store),
    );
    expect(auth.stores.searchAll(), hasLength(2));
    final unseeded = DemoAuthStore(seedDemoAccount: false);
    unseeded.register(
      id: 'admin01',
      password: 'test',
      name: '관리자',
      birthDate: DateTime(1990),
      email: 'a@b.c',
      phoneNumber: '01012345678',
    );
    expect(unseeded.isAdmin('admin01'), isFalse);
  });

  test('store application validates business details and rejects duplicate pending or approved application', () {
    final auth = sample();
    expect(() => applyStore(auth, number: '123'), throwsStateError);
    expect(() => applyStore(auth, name: '   '), throwsStateError);
    expect(() => applyStore(auth, address: ''), throwsStateError);
    final app = applyStore(auth);
    expect(app.registrationNumber, '1234567890');
    expect(app.phoneNumber, '021234567');
    expect(
      () => applyStore(auth, number: '1234567890', address: ' 서울특별시마포구나눔로20 '),
      throwsStateError,
    );
    auth.stores.approve(applicationId: app.id, adminId: 'admin01');
    expect(() => applyStore(auth), throwsStateError);
    final branch = applyStore(
      auth,
      name: '나눔 카페 2호점',
      address: '서울특별시 마포구 나눔로 21',
    );
    auth.stores.approve(applicationId: branch.id, adminId: 'admin01');
    expect(auth.stores.ownedStores(DemoAuthStore.sampleId), hasLength(2));
  });

  test('only owner edits existing thumbnail assets and valid menus; catalog and favorites read latest values', () {
    final auth = sample();
    final store = approvedStore(auth);
    auth.stores.toggleFavorite(store.id, 'leader01');
    expect(
      () => auth.stores.updateThumbnail(
        storeId: store.id,
        ownerId: 'leader01',
        thumbnail: DemoStoreCatalog.thumbnailChoices[1],
      ),
      throwsStateError,
    );
    expect(
      () => auth.stores.updateThumbnail(
        storeId: store.id,
        ownerId: store.ownerId,
        thumbnail: 'unapproved-photo.png',
      ),
      throwsStateError,
    );
    auth.stores.updateThumbnail(
      storeId: store.id,
      ownerId: store.ownerId,
      thumbnail: DemoStoreCatalog.thumbnailChoices[1],
    );
    const item = StoreMenuItem(
      name: '아메리카노',
      description: '따뜻한 커피',
      price: 3500,
      recommended: true,
    );
    expect(
      () => auth.stores.saveMenu(
        storeId: store.id,
        ownerId: 'leader01',
        item: item,
      ),
      throwsStateError,
    );
    expect(
      () => auth.stores.saveMenu(
        storeId: store.id,
        ownerId: store.ownerId,
        item: const StoreMenuItem(name: '커피', description: '', price: 0),
      ),
      throwsStateError,
    );
    auth.stores.saveMenu(storeId: store.id, ownerId: store.ownerId, item: item);
    expect(
      () => auth.stores.saveMenu(
        storeId: store.id,
        ownerId: store.ownerId,
        item: item,
      ),
      throwsStateError,
    );
    auth.stores.saveMenu(
      storeId: store.id,
      ownerId: store.ownerId,
      index: 0,
      item: const StoreMenuItem(
        name: '아메리카노',
        description: '원두 변경',
        price: 4000,
      ),
    );
    final current = auth.stores.favoritesFor('leader01').single;
    expect(current.thumbnail, DemoStoreCatalog.thumbnailChoices[1]);
    expect(current.menu.single.price, 4000);
    expect(
      () => auth.stores.removeMenu(
        storeId: store.id,
        ownerId: 'leader01',
        index: 0,
      ),
      throwsStateError,
    );
    auth.stores.removeMenu(storeId: store.id, ownerId: store.ownerId, index: 0);
    expect(auth.stores.store(store.id).menu, isEmpty);
  });

  test('new approved store accepts donations and owner history without group membership; expired records remain', () {
    var now = DateTime.utc(2026, 10, 28, 3);
    final auth = sample(now: () => now);
    final app = applyStore(auth);
    expect(() => donate(auth, 'registered-${app.id}'), throwsStateError);
    final store = auth.stores.approve(
      applicationId: app.id,
      adminId: 'admin01',
    );
    donate(auth, store.id);
    donate(auth, store.id, amount: 100000);
    expect(auth.groups.isMember('group-1', store.ownerId), isFalse);
    expect(
      auth.stores.offersFor(store.id, store.ownerId, auth.groups),
      isEmpty,
    );
    final offers = auth.stores.managedPrepaidOffers(
      storeId: store.id,
      ownerId: store.ownerId,
      groups: auth.groups,
    );
    expect(offers.map((offer) => offer.remainingAmount), [30000, 100000]);
    expect(
      auth.donations.notificationsForStoreOwner(store.ownerId),
      hasLength(2),
    );
    expect(auth.donations.notificationsForStoreOwner('store01'), isEmpty);
    expect(
      () => auth.stores.managedPrepaidOffers(
        storeId: store.id,
        ownerId: 'store01',
        groups: auth.groups,
      ),
      throwsStateError,
    );
    now = DateTime.utc(2026, 12, 31, 15);
    expect(
      auth.stores.managedPrepaidOffers(
        storeId: store.id,
        ownerId: store.ownerId,
        groups: auth.groups,
      ),
      hasLength(2),
    );
    expect(
      offers.where((offer) => offer.isAvailable(at: auth.groups.currentTime)),
      isEmpty,
    );
    expect(auth.stores.searchAll(query: store.name), hasLength(1));
  });

  testWidgets(
    'my page application -> admin approval -> applicant management and public discovery',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = sample();
      await tester.pumpWidget(HantuckApp(authStore: auth));
      await login(tester, DemoAuthStore.sampleId);
      await tapKey(tester, 'nav-my-page');
      expect(find.text('demo@hantuck.example'), findsOneWidget);
      expect(find.text('010-0000-0000'), findsOneWidget);
      expect(find.byKey(const ValueKey('my-page-manage-store')), findsNothing);
      await tapKey(tester, 'my-page-apply-store');
      await tapKey(tester, 'store-application-submit');
      expect(auth.stores.applicationsFor(DemoAuthStore.sampleId), isEmpty);
      await fillApplication(tester);
      await tapKey(tester, 'store-application-submit');
      expect(
        find.byKey(const ValueKey('store-application-complete')),
        findsOneWidget,
      );
      await tapKey(tester, 'store-application-complete-confirm');
      expect(find.text('심사 대기'), findsOneWidget);
      expect(find.byKey(const ValueKey('my-page-manage-store')), findsNothing);
      expect(auth.stores.searchAll(query: '나눔 카페'), isEmpty);
      await logout(tester);
      await login(tester, 'admin01');
      await tapKey(tester, 'nav-my-page');
      await tapKey(tester, 'my-page-review-stores');
      await tapKey(tester, 'store-review-store-application-1');
      expect(find.text('1234567890'), findsOneWidget);
      await tapKey(tester, 'store-approve-store-application-1');
      expect(find.byKey(const ValueKey('store-review-empty')), findsOneWidget);
      await logout(tester);
      await login(tester, DemoAuthStore.sampleId);
      await tapKey(tester, 'nav-my-page');
      expect(find.text('승인 완료'), findsOneWidget);
      await tapKey(tester, 'my-page-manage-store');
      expect(find.byType(StoreManagementScreen), findsOneWidget);
      expect(find.byType(StoreManagementSelectionScreen), findsNothing);
      await tapKey(tester, 'store-manage-preview');
      expect(find.byType(StoreDetailScreen), findsOneWidget);
      expect(find.text('메뉴를 준비하고 있어요.'), findsOneWidget);
      await tapKey(tester, 'nav-stores');
      expect(find.text('나눔 카페'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'multiple stores require selection and notifications stay within selected store',
    (tester) async {
      final auth = sample();
      final other = approvedStore(auth, owner: 'store01');
      donate(auth, other.id);
      donate(auth, 'example-store-1', amount: 50000);
      await tester.pumpWidget(HantuckApp(authStore: auth));
      await login(tester, 'store01');
      await tapKey(tester, 'nav-my-page');
      await tapKey(tester, 'my-page-manage-store');
      expect(find.byType(StoreManagementSelectionScreen), findsOneWidget);
      await tapKey(tester, 'owned-store-${other.id}');
      expect(find.text('나눔 카페'), findsOneWidget);
      await tapKey(tester, 'store-manage-notifications');
      expect(find.byType(DonationNotificationsScreen), findsOneWidget);
      expect(find.text('30,000원'), findsOneWidget);
      expect(find.text('50,000원'), findsNothing);
      await tapKey(tester, 'donation-notifications-back');
      await tapKey(tester, 'store-manage-prepaid');
      await tapKey(tester, 'managed-prepaid-group-group-1');
      expect(find.text('30,000원'), findsOneWidget);
      expect(find.text('예시 그룹 1'), findsOneWidget);
      expect(find.text('사용 기한 2026.12.31까지'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'owner changes photo and adds edits deletes menu with public detail updating',
    (tester) async {
      final auth = sample();
      await tester.pumpWidget(HantuckApp(authStore: auth));
      await login(tester, 'store01');
      await tapKey(tester, 'nav-my-page');
      await tapKey(tester, 'my-page-manage-store');
      await tapKey(tester, 'store-manage-thumbnail');
      await tapKey(tester, 'store-thumbnail-choice-2');
      expect(
        auth.stores.store('example-store-1').thumbnail,
        DemoStoreCatalog.thumbnailChoices[2],
      );
      await tapKey(tester, 'store-menu-add');
      await tapKey(tester, 'store-menu-save');
      expect(find.text('메뉴 이름을 입력해 주세요.'), findsOneWidget);
      await enter(
        tester,
        find.byKey(const ValueKey('store-menu-name')),
        '새 메뉴',
      );
      await enter(
        tester,
        find.byKey(const ValueKey('store-menu-price')),
        '11000',
      );
      await enter(
        tester,
        find.byKey(const ValueKey('store-menu-description')),
        '따뜻한 메뉴',
      );
      await tapKey(tester, 'store-menu-recommended');
      await tapKey(tester, 'store-menu-save');
      expect(
        auth.stores.store('example-store-1').menu.last.recommended,
        isTrue,
      );
      await tapKey(tester, 'store-menu-edit-3');
      await enter(
        tester,
        find.byKey(const ValueKey('store-menu-price')),
        '12000',
      );
      await tapKey(tester, 'store-menu-save');
      await tapKey(tester, 'store-manage-preview');
      expect(find.text('새 메뉴'), findsOneWidget);
      expect(find.text('12,000원'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  DemoStoreCatalog.thumbnailChoices[2],
        ),
        findsWidgets,
      );
      await tapKey(tester, 'store-detail-back');
      await tapKey(tester, 'store-menu-remove-3');
      await tapKey(tester, 'store-menu-remove-confirm');
      expect(auth.stores.store('example-store-1').menu, hasLength(3));
      expect(find.text('새 메뉴'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'owner prepaid shows separate allocations and expired history; unrelated account denied',
    (tester) async {
      var now = DateTime.utc(2026, 10, 28, 3);
      final auth = sample(now: () => now);
      donate(auth, 'example-store-1', groupId: 'group-3', amount: 100000);
      final owner = auth.signIn('store01', DemoAuthStore.samplePassword)!;
      await tester.pumpWidget(
        page(
          StoreOwnerPrepaidScreen(
            auth: auth,
            account: owner,
            storeId: 'example-store-1',
          ),
        ),
      );
      expect(find.text('남은 선결제 165,000원'), findsOneWidget);
      await tapKey(tester, 'managed-prepaid-group-group-3');
      expect(find.text('65,000원'), findsOneWidget);
      expect(find.text('100,000원'), findsOneWidget);
      expect(find.text('총 100,000원 · 사용 35,000원'), findsOneWidget);
      now = DateTime.utc(2027, 1, 1);
      await tester.pumpWidget(
        page(
          StoreOwnerGroupPrepaidScreen(
            auth: auth,
            account: owner,
            storeId: 'example-store-1',
            groupId: 'group-3',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('기간이 종료된 잔액은 사용할 수 없어요.'), findsNWidgets(2));
      final outsider = auth.signIn('leader03', DemoAuthStore.samplePassword)!;
      await tester.pumpWidget(
        page(
          StoreOwnerPrepaidScreen(
            auth: auth,
            account: outsider,
            storeId: 'example-store-1',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('store-prepaid-denied')),
        findsOneWidget,
      );
      expect(find.text('65,000원'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'small viewport and enlarged text support my page application management and prepaid detail',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final auth = sample();
      await tester.pumpWidget(HantuckApp(authStore: auth));
      await login(tester, 'store01');
      await tapKey(tester, 'nav-my-page');
      await tapKey(tester, 'my-page-apply-store');
      await fillApplication(tester);
      await tapKey(tester, 'store-application-submit');
      await tapKey(tester, 'store-application-complete-confirm');
      await tapKey(tester, 'my-page-manage-store');
      await tapKey(tester, 'store-manage-thumbnail');
      await tapKey(tester, 'store-thumbnail-choice-1');
      await tapKey(tester, 'store-menu-add');
      await tapKey(tester, 'store-menu-form-back');
      await tapKey(tester, 'store-manage-prepaid');
      await tapKey(tester, 'managed-prepaid-group-group-3');
      expect(find.text('65,000원'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
