import 'dart:io';
import 'dart:ui' as ui;

import 'package:capstone_proto_02/demo_auth_store.dart';
import 'package:capstone_proto_02/group_store.dart';
import 'package:capstone_proto_02/main.dart';
import 'package:capstone_proto_02/prepaid_usage_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/auth_test_helpers.dart';

void main() {
  testWidgets(
    'capture QR cashier approval and photo gratitude with actual ledger flow',
    (tester) async {
      await (FontLoader(
        'NotoSansKR',
      )..addFont(rootBundle.load('assets/fonts/NotoSansKR.ttf'))).load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      tester.view.physicalSize = const Size(390, 940);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final photoData = await rootBundle.load('assets/images/group-team.png');
      final attachment = UsagePhoto(
        name: '식사.png',
        bytes: photoData.buffer.asUint8List(),
      );
      final auth = DemoAuthStore(
        groupStore: DemoGroupStore(now: () => DateTime.utc(2026, 10, 28, 3)),
        thanksPhotoPicker: () async => attachment,
      );
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: HantuckApp(authStore: auth),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => precacheImage(
          MemoryImage(attachment.bytes),
          tester.element(find.byType(HantuckApp)),
        ),
      );
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

      Future<void> login(String id) async {
        await enter(tester, loginField('id'), id);
        await enter(
          tester,
          loginField('password'),
          DemoAuthStore.samplePassword,
        );
        await tapKey(tester, 'login-submit');
      }

      Future<void> logout() async {
        await tapKey(tester, 'nav-my-page');
        await tapKey(tester, 'my-page-settings');
        await tapKey(tester, 'account-logout');
      }

      await login('leader03');
      await tapKey(tester, 'prepaid-store-example-store-1');
      await tapKey(tester, 'store-prepaid-offer-example-store-1');
      await capture('usage-select-offer', height: 1540);
      await tapKey(tester, 'prepaid-use-example-store-1');
      final request = auth.usage.requestsForUser('leader03').single;
      await capture('usage-qr', height: 1000);
      await logout();
      await login('store01');
      await tapKey(tester, 'nav-my-page');
      await tapKey(tester, 'my-page-manage-store');
      await tapKey(tester, 'store-manage-cashier');
      await enter(
        tester,
        find.byKey(const ValueKey('cashier-code')),
        request.code,
      );
      await tapKey(tester, 'cashier-find');
      await enter(tester, find.byKey(const ValueKey('cashier-amount')), '9000');
      await capture('usage-cashier-amount', height: 1000);
      await tapKey(tester, 'cashier-request-amount');
      await capture('usage-cashier-requested', height: 940);
      await logout();
      await login('leader03');
      await tapKey(tester, 'nav-my-page');
      await tapKey(tester, 'my-page-prepaid-usage');
      await capture('usage-request-list', height: 844);
      await tapKey(tester, 'usage-request-${request.id}');
      await capture('usage-approve', height: 1200);
      await tapKey(tester, 'usage-approve');
      await enter(
        tester,
        find.byKey(const ValueKey('thanks-message')),
        '따뜻한 한 끼 덕분에 오늘도 힘을 냈어요. 함께 나누어 주셔서 감사합니다!',
      );
      await tapKey(tester, 'thanks-photo-pick');
      await capture('usage-thanks-compose', height: 1530);
      await tapKey(tester, 'thanks-send');
      await capture('usage-thanks-sent', height: 1200);
      await logout();
      await login('hantuck01');
      await tapKey(tester, 'nav-my-page');
      await capture('usage-donor-my-page', height: 1040);
      await tapKey(tester, 'my-page-thanks');
      await capture('usage-received-thanks', height: 1180);
      await tapKey(tester, 'received-thanks-back');
      await tapKey(tester, 'my-page-usage-notifications');
      await capture('usage-donor-notification', height: 1180);
      await logout();
      await login('store01');
      await tapKey(tester, 'nav-my-page');
      await tapKey(tester, 'my-page-manage-store');
      await tapKey(tester, 'store-manage-usage-notifications');
      await capture('usage-store-notification', height: 844);
      await tapKey(tester, 'usage-notifications-back');
      await tapKey(tester, 'store-manage-prepaid');
      await tapKey(tester, 'managed-prepaid-group-group-3');
      await capture('usage-updated-prepaid', height: 844);
      await tapKey(tester, 'store-owner-group-prepaid-back');
      await tapKey(tester, 'store-owner-prepaid-back');
      await tapKey(tester, 'store-manage-usage-notifications');
      await tapKey(tester, 'usage-reverse-usage-receipt-1');
      await enter(
        tester,
        find.byKey(const ValueKey('usage-cancellation-reason')),
        '이용 금액을 잘못 입력해 취소합니다.',
      );
      await capture('usage-cancellation-dialog', height: 940);
      await tapKey(tester, 'usage-cancellation-confirm');
      await capture('usage-cancelled-store', height: 1120);
      await tapKey(tester, 'usage-notifications-back');
      await tapKey(tester, 'store-manage-prepaid');
      await tapKey(tester, 'managed-prepaid-group-group-3');
      await capture('usage-cancelled-balance', height: 844);
      await logout();
      await login('leader03');
      await tapKey(tester, 'nav-my-page');
      await tapKey(tester, 'my-page-prepaid-usage');
      await capture('usage-cancelled-user-list', height: 844);
      await tapKey(tester, 'usage-request-${request.id}');
      await capture('usage-cancelled-user-detail', height: 1180);
      await logout();
      await login('hantuck01');
      await tapKey(tester, 'nav-my-page');
      await tapKey(tester, 'my-page-thanks');
      await capture('usage-cancelled-thanks', height: 1460);
      expect(tester.takeException(), isNull);
    },
  );
}
