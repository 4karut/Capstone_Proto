import 'dart:io';
import 'dart:ui' as ui;

import 'package:capstone_proto_02/main.dart';
import 'package:capstone_proto_02/demo_auth_store.dart';
import 'package:capstone_proto_02/group_store.dart';
import 'package:capstone_proto_02/donation_store.dart';
import 'package:capstone_proto_02/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/auth_test_helpers.dart';

void main() {
  testWidgets(
    'capture authentication group search applications and owner approval',
    (tester) async {
      final font = FontLoader('NotoSansKR')
        ..addFont(rootBundle.load('assets/fonts/NotoSansKR.ttf'));
      await font.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      tester.view.physicalSize = const Size(390, 940);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundaryKey = GlobalKey();
      final auth = DemoAuthStore(
        groupStore: DemoGroupStore(now: () => DateTime.utc(2026, 10, 28, 3)),
      );
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: HantuckApp(authStore: auth),
        ),
      );
      await tester.pumpAndSettle();

      Future<void> capture(String name) async {
        for (final state in tester.stateList<ScrollableState>(
          find.byType(Scrollable),
        )) {
          state.position.jumpTo(0);
        }
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('build/previews/$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }

      await capture('login');
      tester.view.physicalSize = const Size(390, 1440);
      await tester.pumpAndSettle();
      await openSignup(tester);
      await capture('signup');
      await fillSignup(tester);
      await capture('signup-verified');
      await tapKey(tester, 'signup-submit');
      tester.view.physicalSize = const Size(390, 940);
      await tester.pumpAndSettle();
      await capture('verification-complete');
      await tapKey(tester, 'verification-confirm');
      await enter(tester, loginField('password'), 'welcome123!');
      await tapKey(tester, 'login-submit');
      await tester.runAsync(() async {
        final context = tester.element(find.byType(HomeScreen));
        for (final group in DemoGroupStore.allGroups) {
          await precacheImage(AssetImage(group.thumbnail), context);
        }
      });
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      await capture('home');
      await tapKey(tester, 'nav-stores');
      await capture('store-search-first-user');
      await tapKey(tester, 'nav-favorites');
      await capture('favorites-empty');
      await tapKey(tester, 'nav-home');
      await tapKey(tester, 'home-all-groups');
      await capture('member-groups-empty');
      await tapKey(tester, 'groups-overview-back');
      await tapKey(tester, 'home-find-group');
      tester.view.physicalSize = const Size(390, 940);
      await tester.pumpAndSettle();
      await capture('group-search');
      await enter(
        tester,
        find.byKey(const ValueKey('group-search-query')),
        'HG0001',
      );
      await tapKey(tester, 'group-search-submit');
      await tapKey(tester, 'group-card-group-1');
      await tapKey(tester, 'group-favorite-toggle');
      await capture('group-detail');
      await tapKey(tester, 'group-sponsor');
      await capture('donation-choice');
      await tapKey(tester, 'donation-choice-back');
      await tapKey(tester, 'group-apply');
      await capture('group-request-popup');
      await enter(
        tester,
        find.byKey(const ValueKey('group-introduction')),
        '함께 응원하고 나누고 싶어요.',
      );
      await tapKey(tester, 'group-request-submit');
      await capture('group-request-complete');
      await tapKey(tester, 'group-complete-confirm');
      await capture('home-pending');
      await tapKey(tester, 'home-find-group');
      await enter(
        tester,
        find.byKey(const ValueKey('group-search-query')),
        'HG0003',
      );
      await tapKey(tester, 'group-search-submit');
      await tapKey(tester, 'group-card-group-3');
      await tapKey(tester, 'group-apply');
      await capture('group-invitation-popup');
      await enter(
        tester,
        find.byKey(const ValueKey('group-invite-code')),
        '123456',
      );
      await tapKey(tester, 'group-invite-submit');
      await tapKey(tester, 'group-complete-confirm');
      await capture('home-joined');
      await tapKey(tester, 'home-logout');
      await enter(tester, loginField('id'), 'leader01');
      await enter(tester, loginField('password'), 'welcome123!');
      await tapKey(tester, 'login-submit');
      await tapKey(tester, 'home-group-notifications');
      await capture('group-owner-notifications');
      await tapKey(tester, 'group-approve-application-1');
      await tapKey(tester, 'group-notifications-back');
      await tapKey(tester, 'home-logout');
      await enter(tester, loginField('id'), 'newuser01');
      await enter(tester, loginField('password'), 'welcome123!');
      await tapKey(tester, 'login-submit');
      await capture('home-approved');
      await tapKey(tester, 'home-all-groups');
      await capture('member-groups');
      await tapKey(tester, 'group-card-group-3');
      await tapKey(tester, 'group-favorite-toggle');
      tester.view.physicalSize = const Size(390, 1060);
      await tester.pumpAndSettle();
      await capture('member-group-detail');
      await tapKey(tester, 'nav-stores');
      tester.view.physicalSize = const Size(390, 940);
      await tester.pumpAndSettle();
      await capture('store-search');
      await tapKey(tester, 'store-card-example-store-1');
      await tapKey(tester, 'store-favorite-toggle');
      tester.view.physicalSize = const Size(390, 1460);
      await tester.pumpAndSettle();
      await capture('store-detail');
      tester.view.physicalSize = const Size(390, 940);
      await tester.pumpAndSettle();
      await tapKey(tester, 'nav-favorites');
      await capture('favorites-groups');
      await tapKey(tester, 'favorites-stores-tab');
      await capture('favorites-stores');
      await tapKey(tester, 'nav-home');
      await tapKey(tester, 'home-find-group');
      await enter(
        tester,
        find.byKey(const ValueKey('group-search-query')),
        'HG0001',
      );
      await tapKey(tester, 'group-search-submit');
      await tapKey(tester, 'group-card-group-1');
      await tapKey(tester, 'group-sponsor');
      await tapKey(tester, 'donation-choose-money');
      await enter(
        tester,
        find.byKey(const ValueKey('donation-amount')),
        '50000',
      );
      await capture('donation-money');
      await tapKey(tester, 'donation-confirm');
      await capture('donation-money-complete');
      await tapKey(tester, 'donation-complete-confirm');
      await tapKey(tester, 'home-find-group');
      await enter(
        tester,
        find.byKey(const ValueKey('group-search-query')),
        'HG0001',
      );
      await tapKey(tester, 'group-search-submit');
      await tapKey(tester, 'group-card-group-1');
      await tapKey(tester, 'group-sponsor');
      await tapKey(tester, 'donation-choose-prepaid');
      await tapKey(tester, 'donation-store');
      await capture('donation-store-picker');
      await tapKey(tester, 'donation-store-favorites');
      await capture('donation-favorite-stores');
      await tapKey(tester, 'donation-store-option-example-store-1');
      await enter(
        tester,
        find.byKey(const ValueKey('donation-amount')),
        '30000',
      );
      await enter(
        tester,
        find.byKey(const ValueKey('donation-deadline')),
        '20261231',
      );
      tester.view.physicalSize = const Size(390, 1120);
      await tester.pumpAndSettle();
      await capture('donation-prepaid');
      await tapKey(tester, 'donation-confirm');
      tester.view.physicalSize = const Size(390, 940);
      await tester.pumpAndSettle();
      await capture('donation-prepaid-complete');
      await tapKey(tester, 'donation-complete-confirm');
      await capture('home-after-donation');
      await tapKey(tester, 'home-logout');
      await enter(tester, loginField('id'), 'leader01');
      await enter(tester, loginField('password'), 'welcome123!');
      await tapKey(tester, 'login-submit');
      await tapKey(tester, 'home-donation-notifications');
      tester.view.physicalSize = const Size(390, 1120);
      await tester.pumpAndSettle();
      await capture('donation-group-notifications');
      await tapKey(tester, 'donation-notifications-back');
      await tapKey(tester, 'home-logout');
      await enter(tester, loginField('id'), 'store01');
      await enter(tester, loginField('password'), 'welcome123!');
      await tapKey(tester, 'login-submit');
      await tapKey(tester, 'home-store-donation-notifications');
      tester.view.physicalSize = const Size(390, 940);
      await tester.pumpAndSettle();
      await capture('donation-store-notifications');
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
      await tester.pumpAndSettle();
      await tapKey(tester, 'donation-notifications-back');
      await tapKey(tester, 'home-logout');
      await enter(tester, loginField('id'), 'leader03');
      await enter(tester, loginField('password'), 'welcome123!');
      await tapKey(tester, 'login-submit');
      await capture('grouped-prepaid-home');
      await tapKey(tester, 'home-all-groups');
      await tapKey(tester, 'group-card-group-3');
      tester.view.physicalSize = const Size(390, 1060);
      await tester.pumpAndSettle();
      await capture('grouped-prepaid-group');
      await tapKey(tester, 'prepaid-store-example-store-1');
      tester.view.physicalSize = const Size(390, 1580);
      await tester.pumpAndSettle();
      await capture('grouped-prepaid-detail');
      expect(tester.takeException(), isNull);
    },
  );
}
