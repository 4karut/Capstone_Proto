import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder signupField(String name) => find.byKey(ValueKey('signup-$name'));
Finder loginField(String name) => find.byKey(ValueKey('login-$name'));

Future<void> tapKey(WidgetTester tester, String key) async {
  final button = find.byKey(ValueKey(key));
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> enter(WidgetTester tester, Finder field, String value) async {
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, value);
  await tester.pumpAndSettle();
}

Future<void> openSignup(WidgetTester tester) => tapKey(tester, 'login-signup');

Future<void> fillSignup(
  WidgetTester tester, {
  String id = 'newuser01',
  String email = 'newuser@example.com',
  bool checkId = true,
  bool verifyEmail = true,
}) async {
  await enter(tester, signupField('id'), id);
  if (checkId) await tapKey(tester, 'signup-check-id');
  await enter(tester, signupField('password'), 'welcome123!');
  await enter(tester, signupField('password-confirm'), 'welcome123!');
  await enter(tester, signupField('name'), '김한턱');
  await enter(tester, signupField('birth-date'), '20010315');
  await enter(tester, signupField('phone'), '010-1234-5678');
  await enter(tester, signupField('email'), email);
  if (verifyEmail) {
    await tapKey(tester, 'signup-send-email-code');
    await enter(tester, signupField('email-code'), '123456');
    await tapKey(tester, 'signup-verify-email');
  }
}
