import 'dart:io';
import 'dart:ui' as ui;

import 'package:capstone_proto_02/demo_auth_store.dart';
import 'package:capstone_proto_02/donation_store.dart';
import 'package:capstone_proto_02/group_store.dart';
import 'package:capstone_proto_02/main.dart';
import 'package:capstone_proto_02/my_page_screen.dart';
import 'package:capstone_proto_02/store_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/auth_test_helpers.dart';

void main() {
  testWidgets(
    'capture store application approval and owner management screens',
    (tester) async {
      final font = FontLoader('NotoSansKR')
        ..addFont(rootBundle.load('assets/fonts/NotoSansKR.ttf'));
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await font.load();
      await icons.load();
      tester.view.physicalSize = const Size(390, 940);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = DemoAuthStore(
        groupStore: DemoGroupStore(now: () => DateTime.utc(2026, 10, 28, 3)),
      );
      for (final groupId in ['group-1', 'group-3']) {
        auth.donations.complete(
          checkoutId: auth.donations.beginCheckout(),
          type: DonationType.prepaid,
          groupId: groupId,
          donorId: DemoAuthStore.sampleId,
          donorName: '한나눔',
          amount: groupId == 'group-1' ? 50000 : 100000,
          storeId: 'example-store-1',
          expiresOn: DateTime(2026, 12, 31),
        );
      }
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: HantuckApp(authStore: auth),
        ),
      );
      await tester.pumpAndSettle();

      Future<void> login(String id) async {
        await enter(tester, loginField('id'), id);
        await enter(
          tester,
          loginField('password'),
          DemoAuthStore.samplePassword,
        );
        await tapKey(tester, 'login-submit');
        await tapKey(tester, 'nav-my-page');
      }

      Future<void> logout() async {
        await tapKey(tester, 'nav-my-page');
        await tapKey(tester, 'my-page-settings');
        await tapKey(tester, 'account-logout');
      }

      Future<void> capture(String name, {double height = 940}) async {
        FocusManager.instance.primaryFocus?.unfocus();
        tester.view.physicalSize = Size(390, height);
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

      await login('store01');
      await tester.runAsync(() async {
        final context = tester.element(find.byType(MyPageScreen));
        for (final photo in DemoStoreCatalog.thumbnailChoices) {
          await precacheImage(AssetImage(photo), context);
        }
      });
      await capture('my-page');
      await tapKey(tester, 'my-page-settings');
      await capture('account-settings');
      await tapKey(tester, 'account-settings-back');
      await tapKey(tester, 'my-page-apply-store');
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
        '서울특별시 마포구 나눔로 20, 1층',
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
      await capture('store-application', height: 1480);
      await tapKey(tester, 'store-application-submit');
      await capture('store-application-complete', height: 844);
      await tapKey(tester, 'store-application-complete-confirm');
      await capture('my-page-store-pending');
      await logout();
      await login('admin01');
      await tapKey(tester, 'my-page-review-stores');
      await capture('store-review-list', height: 844);
      await tapKey(tester, 'store-review-store-application-1');
      await capture('store-review-detail', height: 1220);
      await tapKey(tester, 'store-reject-store-application-1');
      await enter(
        tester,
        find.byKey(const ValueKey('store-rejection-reason-input')),
        '상세 주소에 층·호수를 입력해 주세요.',
      );
      await capture('store-rejection-dialog', height: 844);
      await tapKey(tester, 'store-rejection-submit');
      await logout();
      await login('store01');
      await capture('my-page-store-rejected', height: 1100);
      await tapKey(tester, 'store-resubmit-store-application-1');
      await enter(
        tester,
        find.byKey(const ValueKey('store-application-address')),
        '서울특별시 마포구 나눔로 20, 1층 101호',
      );
      await capture('store-resubmission', height: 1580);
      await tapKey(tester, 'store-application-submit');
      await capture('store-resubmission-complete', height: 844);
      await tapKey(tester, 'store-application-complete-confirm');
      await capture('my-page-store-resubmitted', height: 1040);
      await tapKey(tester, 'store-history-store-application-2');
      await capture('store-application-history', height: 1800);
      await logout();
      await login('admin01');
      await tapKey(tester, 'my-page-review-stores');
      await capture('store-review-resubmitted', height: 844);
      await tapKey(tester, 'store-review-store-application-2');
      await capture('store-review-resubmission-detail', height: 1280);
      await tapKey(tester, 'store-approve-store-application-2');
      await logout();
      await login('store01');
      await capture('my-page-store-approved');
      await tapKey(tester, 'my-page-manage-store');
      await capture('store-management-selection', height: 844);
      await tapKey(tester, 'owned-store-example-store-1');
      await capture('store-management', height: 1560);
      await tapKey(tester, 'store-manage-thumbnail');
      await capture('store-thumbnail-picker', height: 844);
      await tapKey(tester, 'store-thumbnail-choice-0');
      await tapKey(tester, 'store-menu-edit-0');
      await capture('store-menu-edit', height: 1040);
      await tapKey(tester, 'store-menu-form-back');
      await tapKey(tester, 'store-manage-prepaid');
      await capture('store-owner-prepaid', height: 1020);
      await tapKey(tester, 'managed-prepaid-group-group-3');
      await capture('store-owner-group-prepaid', height: 1110);
      await tapKey(tester, 'store-owner-group-prepaid-back');
      await tapKey(tester, 'store-owner-prepaid-back');
      await tapKey(tester, 'store-manage-notifications');
      await capture('store-owner-notifications', height: 1150);
      expect(tester.takeException(), isNull);
    },
  );
}
