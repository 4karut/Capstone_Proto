import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstone_proto/src/app.dart';
import 'package:capstone_proto/src/store.dart';
import 'package:capstone_proto/src/pages/account.dart';
import 'package:capstone_proto/src/pages/details.dart';
import 'package:capstone_proto/src/pages/give.dart';
import 'package:capstone_proto/src/pages/history.dart';
import 'package:capstone_proto/src/pages/merchant.dart';

void main() {
  testWidgets('screens fit small phones with the bundled Korean font', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final font = FontLoader('NotoSansKR')
      ..addFont(rootBundle.load('assets/fonts/NotoSansKR.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    SharedPreferences.setMockInitialValues({});
    final s = AppStore();
    await s.load();
    s.loginDemo(merchant: true);
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: HantteokApp(store: s),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    Future<void> capture(String name) async {
      if (!const bool.fromEnvironment('CAPTURE_PREVIEWS')) return;
      await tester.runAsync(() async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final dir = Directory('build/previews');
        await dir.create(recursive: true);
        await File('${dir.path}/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('home');
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    final pages = <String, Widget>{
      'benefit': const BenefitPage(id: 'b1'),
      'shop': const ShopPage(id: 's1'),
      'give': const GivePage(),
      'community': const CommunityPage(),
      'merchant': const MerchantPage(),
      'settlement': const SettlementPage(shopId: 's1'),
      'support': const SupportPage(targetId: 'b3', allowRefund: true),
    };
    for (final entry in pages.entries) {
      navigator.push(MaterialPageRoute(builder: (_) => entry.value));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: entry.key);
      await capture(entry.key);
      navigator.pop();
      await tester.pumpAndSettle();
    }
  });
  testWidgets(
    'failed payment creates nothing; retry creates exactly one benefit',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final s = AppStore();
      await s.load();
      s.loginDemo(merchant: true);
      await tester.pumpWidget(HantteokApp(store: s));
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      navigator.push(
        MaterialPageRoute(
          builder: (_) => PaymentPage(
            draft: GiveDraft(
              's1',
              'school',
              50000,
              5000,
              DateTime.now().add(const Duration(days: 10)),
              '익명',
              '응원해요',
              [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(CheckboxListTile),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(SwitchListTile),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('50,000원 모의 결제'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(s.benefits.length, 4);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('50,000원 모의 결제'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(s.benefits.length, 5);
      expect(find.text('따뜻한 마음이\n잘 도착했어요!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
