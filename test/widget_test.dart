import 'package:capstone_proto_02/demo_auth_store.dart';
import 'package:capstone_proto_02/groups_overview_screen.dart';
import 'package:capstone_proto_02/group_search_screen.dart';
import 'package:capstone_proto_02/home_screen.dart';
import 'package:capstone_proto_02/login_screen.dart';
import 'package:capstone_proto_02/main.dart';
import 'package:capstone_proto_02/signup_screen.dart';
import 'package:capstone_proto_02/verification_complete_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_helpers.dart';

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets('app starts on empty login and signup navigation works', (
    tester,
  ) async {
    await tester.pumpWidget(const HantuckApp());
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    await openSignup(tester);
    expect(find.byType(SignupScreen), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(7));
    await tapKey(tester, 'signup-back');
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('empty and incorrect login cannot open home', (tester) async {
    await tester.pumpWidget(const HantuckApp());
    await tapKey(tester, 'login-submit');
    expect(find.text('아이디를 입력해 주세요.'), findsOneWidget);
    await enter(tester, loginField('id'), DemoAuthStore.sampleId);
    await enter(tester, loginField('password'), 'wrongPassword1');
    await tapKey(tester, 'login-submit');
    expect(find.text('아이디 또는 비밀번호를 확인해 주세요.'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('demo login opens temporary home and logout returns to login', (
    tester,
  ) async {
    await tester.pumpWidget(const HantuckApp());
    await tapKey(tester, 'login-demo-fill');
    await tapKey(tester, 'login-submit');
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('hantuck01'), findsOneWidget);
    final communityDropdown = tester.widget<DropdownButton<String>>(
      find.byKey(const ValueKey('home-group-dropdown')),
    );
    expect(communityDropdown.onChanged, isNull);
    expect(find.text('소속 그룹이 없어요'), findsOneWidget);
    expect(find.text('이용 가능한 가게가 없어요'), findsOneWidget);
    await tapKey(tester, 'home-logout');
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(
      tester.widget<TextFormField>(loginField('password')).controller!.text,
      isEmpty,
    );
  });

  testWidgets('ID duplicate check rejects demo ID and invalidates on editing', (
    tester,
  ) async {
    await tester.pumpWidget(const HantuckApp());
    await openSignup(tester);
    await enter(tester, signupField('id'), 'HANTUCK01');
    await tapKey(tester, 'signup-check-id');
    expect(find.text('이미 사용 중인 아이디예요.'), findsOneWidget);
    await enter(tester, signupField('id'), 'available01');
    await tapKey(tester, 'signup-check-id');
    expect(find.text('사용 가능한 아이디예요.'), findsOneWidget);
    await enter(tester, signupField('id'), 'available02');
    expect(find.text('사용 가능한 아이디예요.'), findsNothing);
    await tapKey(tester, 'signup-submit');
    expect(find.text('아이디 중복 확인을 해주세요.'), findsOneWidget);
  });

  testWidgets(
    'password mismatch blocks signup and both visibility toggles work',
    (tester) async {
      await tester.pumpWidget(const HantuckApp());
      await openSignup(tester);
      await fillSignup(tester);
      await enter(tester, signupField('password-confirm'), 'different123');
      await tapKey(tester, 'signup-submit');
      expect(find.text('비밀번호가 일치하지 않아요.'), findsOneWidget);
      for (final entry in [
        ('password', '비밀번호 보기'),
        ('password-confirm', '비밀번호 확인 보기'),
      ]) {
        final editable = find.descendant(
          of: signupField(entry.$1),
          matching: find.byType(EditableText),
        );
        expect(tester.widget<EditableText>(editable).obscureText, isTrue);
        await tester.ensureVisible(find.byTooltip(entry.$2));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip(entry.$2));
        await tester.pump();
        expect(tester.widget<EditableText>(editable).obscureText, isFalse);
      }
      expect(find.byType(VerificationCompleteScreen), findsNothing);
    },
  );

  testWidgets(
    'email format, send, wrong code, correct code and edit invalidation',
    (tester) async {
      await tester.pumpWidget(const HantuckApp());
      await openSignup(tester);
      await enter(tester, signupField('email'), 'invalid');
      await tapKey(tester, 'signup-send-email-code');
      expect(find.textContaining('이메일 주소를 확인해 주세요.'), findsOneWidget);
      expect(signupField('email-code'), findsNothing);
      await enter(tester, signupField('email'), 'person@example.com');
      await tapKey(tester, 'signup-send-email-code');
      expect(signupField('email-code'), findsOneWidget);
      await enter(tester, signupField('email-code'), '000000');
      await tapKey(tester, 'signup-verify-email');
      expect(find.text('인증코드가 일치하지 않아요. 다시 확인해 주세요.'), findsOneWidget);
      await enter(tester, signupField('email-code'), '123456');
      await tapKey(tester, 'signup-verify-email');
      expect(find.text('이메일 인증이 완료되었어요.'), findsOneWidget);
      await enter(tester, signupField('email'), 'another@example.com');
      expect(find.text('이메일 인증이 완료되었어요.'), findsNothing);
      expect(signupField('email-code'), findsNothing);
    },
  );

  testWidgets(
    'email authentication is mandatory even when all other data is valid',
    (tester) async {
      final auth = DemoAuthStore();
      await tester.pumpWidget(HantuckApp(authStore: auth));
      await openSignup(tester);
      await fillSignup(tester, verifyEmail: false);
      await tapKey(tester, 'signup-submit');
      expect(find.byType(VerificationCompleteScreen), findsNothing);
      expect(auth.isIdAvailable('newuser01'), isTrue);
      expect(find.text('인증코드를 발송하고 이메일 인증을 완료해 주세요.'), findsOneWidget);
      await tapKey(tester, 'signup-send-email-code');
      await enter(tester, signupField('email-code'), '123456');
      await tapKey(tester, 'signup-submit');
      expect(auth.isIdAvailable('newuser01'), isTrue);
      expect(find.text('인증하기를 눌러 이메일 인증을 완료해 주세요.'), findsOneWidget);
    },
  );

  testWidgets('resending email code removes previous verification', (
    tester,
  ) async {
    await tester.pumpWidget(const HantuckApp());
    await openSignup(tester);
    await fillSignup(tester);
    await tapKey(tester, 'signup-send-email-code');
    expect(find.text('이메일 인증이 완료되었어요.'), findsNothing);
    expect(
      tester.widget<TextFormField>(signupField('email-code')).controller!.text,
      isEmpty,
    );
    await tapKey(tester, 'signup-submit');
    expect(find.byType(VerificationCompleteScreen), findsNothing);
  });

  testWidgets('phone number and real birth date are required', (tester) async {
    await tester.pumpWidget(const HantuckApp());
    await openSignup(tester);
    await fillSignup(tester);
    await enter(tester, signupField('phone'), '123');
    await enter(tester, signupField('birth-date'), '20010230');
    await tapKey(tester, 'signup-submit');
    expect(find.textContaining('전화번호를 확인해 주세요.'), findsOneWidget);
    expect(find.text('실제 생년월일을 확인해 주세요.'), findsOneWidget);
  });

  testWidgets(
    'full signup completion login home logout duplicate and relogin flow',
    (tester) async {
      final auth = DemoAuthStore();
      await tester.pumpWidget(HantuckApp(authStore: auth));
      await openSignup(tester);
      await fillSignup(tester);
      await tapKey(tester, 'signup-submit');
      expect(find.byType(VerificationCompleteScreen), findsOneWidget);
      expect(find.text('데모 인증 완료'), findsOneWidget);
      expect(auth.isIdAvailable('newuser01'), isFalse);
      await tapKey(tester, 'verification-confirm');
      expect(
        tester.widget<TextFormField>(loginField('id')).controller!.text,
        'newuser01',
      );
      expect(
        tester.widget<TextFormField>(loginField('password')).controller!.text,
        isEmpty,
      );
      await enter(tester, loginField('password'), 'welcome123!');
      await tapKey(tester, 'login-submit');
      expect(find.text('김한턱님'), findsOneWidget);
      expect(find.text('소속 그룹이 없어요'), findsOneWidget);
      expect(find.text('이용 가능한 가게가 없어요'), findsOneWidget);
      await tapKey(tester, 'home-logout');
      await openSignup(tester);
      await enter(tester, signupField('id'), 'newuser01');
      await tapKey(tester, 'signup-check-id');
      expect(find.text('이미 사용 중인 아이디예요.'), findsOneWidget);
      await tapKey(tester, 'signup-back');
      await enter(tester, loginField('id'), 'NEWUSER01');
      await enter(tester, loginField('password'), 'welcome123!');
      await tapKey(tester, 'login-submit');
      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );

  testWidgets('group search and overview return to the unchanged empty home', (
    tester,
  ) async {
    await tester.pumpWidget(const HantuckApp());
    await tapKey(tester, 'login-demo-fill');
    await tapKey(tester, 'login-submit');
    await tapKey(tester, 'home-all-groups');
    expect(find.byType(GroupsOverviewScreen), findsOneWidget);
    expect(find.text('소속 그룹 리스트'), findsOneWidget);
    await tapKey(tester, 'groups-overview-back');
    expect(find.byType(HomeScreen), findsOneWidget);
    await tapKey(tester, 'home-find-group');
    expect(find.byType(GroupSearchScreen), findsOneWidget);
    await tapKey(tester, 'group-search-back');
    expect(find.text('소속 그룹이 없어요'), findsOneWidget);
    expect(find.text('이용 가능한 가게가 없어요'), findsOneWidget);
  });

  testWidgets(
    'small screen and keyboard support signup authentication and login',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, _) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.3)),
            child: const HantuckApp(),
          ),
        ),
      );
      await openSignup(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 270);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();
      await fillSignup(tester);
      await tapKey(tester, 'signup-submit');
      expect(find.byType(VerificationCompleteScreen), findsOneWidget);
      await tapKey(tester, 'verification-confirm');
      await enter(tester, loginField('password'), 'welcome123!');
      await tapKey(tester, 'login-submit');
      expect(find.byType(HomeScreen), findsOneWidget);
      await tapKey(tester, 'home-all-groups');
      expect(find.byType(GroupsOverviewScreen), findsOneWidget);
      await tapKey(tester, 'groups-overview-back');
      await tapKey(tester, 'home-find-group');
      expect(find.byType(GroupSearchScreen), findsOneWidget);
      await tapKey(tester, 'group-search-back');
      expect(tester.takeException(), isNull);
    },
  );
}
