import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstone_proto/src/app.dart';
import 'package:capstone_proto/src/store.dart';
import 'package:capstone_proto/src/pages/qr.dart';

void main() {
  testWidgets('demo login, home and bottom tabs render on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final s = AppStore();
    await s.load();
    await tester.pumpWidget(HantteokApp(store: s));
    await tester.scrollUntilVisible(
      find.text('입력 없이 통합 데모 체험하기'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('입력 없이 통합 데모 체험하기'));
    await tester.pumpAndSettle();
    expect(find.text('오늘 한 끼,\n제가 쏠게요.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    for (final label in ['가게 찾기', '내역', '마이페이지', '홈']) {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets(
    'benefit QR request, merchant request and user approval complete one transaction',
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
      await tester.scrollUntilVisible(
        find.text('온기 식탁').first,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('온기 식탁').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('혜택 사용하기'));
      await tester.pumpAndSettle();
      expect(find.byType(QrPage), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('가게 역할로 QR 확인 체험'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('가게 역할로 QR 확인 체험'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('이용자에게 확인 요청'));
      await tester.pumpAndSettle();
      expect(s.benefit('b1').remaining, 145000);
      await tester.tap(find.text('내용 확인 · 사용 승인'));
      await tester.pumpAndSettle();
      expect(s.usages.length, 1);
      expect(s.benefit('b1').remaining, 140000);
      expect(find.text('든든한 한 끼 되세요!'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
