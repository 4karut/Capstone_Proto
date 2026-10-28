import 'package:capstone_proto_02/demo_auth_store.dart';
import 'package:capstone_proto_02/group_detail_screen.dart';
import 'package:capstone_proto_02/group_search_screen.dart';
import 'package:capstone_proto_02/home_screen.dart';
import 'package:capstone_proto_02/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_helpers.dart';

Future<void> login(
  WidgetTester tester, {
  String id = DemoAuthStore.sampleId,
}) async {
  await enter(tester, loginField('id'), id);
  await enter(tester, loginField('password'), DemoAuthStore.samplePassword);
  await tapKey(tester, 'login-submit');
}

Future<void> search(WidgetTester tester, String value) async {
  await enter(tester, find.byKey(const ValueKey('group-search-query')), value);
  await tapKey(tester, 'group-search-submit');
}

Future<void> openGroup(WidgetTester tester, String id) async {
  await tapKey(tester, 'home-find-group');
  await search(
    tester,
    id == 'group-1'
        ? 'HG0001'
        : id == 'group-2'
        ? 'HG0002'
        : 'HG0003',
  );
  await tapKey(tester, 'group-card-$id');
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets(
    'search supports group name, public code, tags, filters, and no results',
    (tester) async {
      await tester.pumpWidget(const HantuckApp());
      await login(tester);
      await tapKey(tester, 'home-find-group');
      for (final id in ['group-1', 'group-2', 'group-3']) {
        expect(find.byKey(ValueKey('group-card-$id')), findsOneWidget);
      }
      await search(tester, '예시그룹1');
      expect(find.byKey(const ValueKey('group-card-group-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('group-card-group-2')), findsNothing);
      await search(tester, 'hg0002');
      expect(find.byKey(const ValueKey('group-card-group-2')), findsOneWidget);
      await search(tester, '#산책');
      expect(find.byKey(const ValueKey('group-card-group-3')), findsOneWidget);
      await search(tester, '');
      await tapKey(tester, 'group-search-category');
      await tester.tap(find.text('직장·팀').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('group-card-group-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('group-card-group-1')), findsNothing);
      await search(tester, '캠퍼스');
      expect(find.text('검색 결과가 없어요'), findsOneWidget);
    },
  );

  testWidgets(
    'normal application popup limits 100 characters, notifies owner, and returns home pending',
    (tester) async {
      final auth = DemoAuthStore();
      await tester.pumpWidget(HantuckApp(authStore: auth));
      await login(tester);
      await openGroup(tester, 'group-1');
      expect(find.byType(GroupDetailScreen), findsOneWidget);
      expect(find.text('그룹 코드 · HG0001'), findsOneWidget);
      await tapKey(tester, 'group-apply');
      final input = find.byKey(const ValueKey('group-introduction'));
      await enter(tester, input, '가' * 101);
      expect(
        tester.widget<TextFormField>(input).controller!.text.characters.length,
        100,
      );
      await tapKey(tester, 'group-request-submit');
      expect(find.text('신청이 완료되었어요'), findsOneWidget);
      expect(auth.groups.notificationsForOwner('leader01'), hasLength(1));
      expect(auth.groups.memberships(DemoAuthStore.sampleId), isEmpty);
      await tapKey(tester, 'group-complete-confirm');
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(GroupSearchScreen), findsNothing);
      expect(find.text('승인 대기'), findsOneWidget);
      await openGroup(tester, 'group-1');
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('group-apply')))
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets('introduction is optional and cancelling does not submit', (
    tester,
  ) async {
    final auth = DemoAuthStore();
    await tester.pumpWidget(HantuckApp(authStore: auth));
    await login(tester);
    await openGroup(tester, 'group-2');
    await tapKey(tester, 'group-apply');
    await tapKey(tester, 'group-request-cancel');
    expect(auth.groups.pendingForUser(DemoAuthStore.sampleId), isEmpty);
    await tapKey(tester, 'group-apply');
    await tapKey(tester, 'group-request-submit');
    expect(
      auth.groups.notificationsForOwner('leader02').single.introduction,
      isEmpty,
    );
    await tapKey(tester, 'group-complete-confirm');
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets(
    'locked group validates invitation and immediately appears in home dropdown',
    (tester) async {
      final auth = DemoAuthStore();
      await tester.pumpWidget(HantuckApp(authStore: auth));
      await login(tester);
      await openGroup(tester, 'group-3');
      await tapKey(tester, 'group-apply');
      expect(
        find.byKey(const ValueKey('group-invitation-dialog')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('group-introduction')), findsNothing);
      await enter(
        tester,
        find.byKey(const ValueKey('group-invite-code')),
        '000000',
      );
      await tapKey(tester, 'group-invite-submit');
      expect(find.text('초대 코드가 일치하지 않아요.'), findsOneWidget);
      expect(auth.groups.isMember('group-3', DemoAuthStore.sampleId), isFalse);
      await enter(
        tester,
        find.byKey(const ValueKey('group-invite-code')),
        '123456',
      );
      await tapKey(tester, 'group-invite-submit');
      expect(find.text('그룹에 가입되었어요'), findsOneWidget);
      await tapKey(tester, 'group-complete-confirm');
      final dropdown = tester.widget<DropdownButton<String>>(
        find.byKey(const ValueKey('home-group-dropdown')),
      );
      expect(dropdown.value, 'group-3');
      expect(dropdown.onChanged, isNotNull);
      expect(find.text('승인 대기'), findsNothing);
      expect(auth.groups.notificationsForOwner('leader03'), isEmpty);
    },
  );

  testWidgets(
    'group owner sees notification and approves before member can select the group',
    (tester) async {
      final auth = DemoAuthStore();
      await tester.pumpWidget(HantuckApp(authStore: auth));
      await login(tester);
      await openGroup(tester, 'group-1');
      await tapKey(tester, 'group-apply');
      await enter(
        tester,
        find.byKey(const ValueKey('group-introduction')),
        '함께 응원하고 싶어요.',
      );
      await tapKey(tester, 'group-request-submit');
      await tapKey(tester, 'group-complete-confirm');
      await tapKey(tester, 'home-logout');
      await login(tester, id: 'leader01');
      expect(find.text('그룹 신청 알림 1건'), findsOneWidget);
      await tapKey(tester, 'home-group-notifications');
      expect(find.text('함께 응원하고 싶어요.'), findsOneWidget);
      await tapKey(tester, 'group-approve-application-1');
      expect(find.text('대기 중인 신청이 없어요'), findsOneWidget);
      await tapKey(tester, 'group-notifications-back');
      await tapKey(tester, 'home-logout');
      await login(tester);
      var dropdown = tester.widget<DropdownButton<String>>(
        find.byKey(const ValueKey('home-group-dropdown')),
      );
      expect(dropdown.value, 'group-1');
      expect(find.text('승인 대기'), findsNothing);
      auth.groups.joinWithInvitation(
        groupId: 'group-3',
        userId: DemoAuthStore.sampleId,
        code: '123456',
      );
      await tester.pumpAndSettle();
      await tapKey(tester, 'home-group-dropdown');
      await tester.tap(find.text('예시 그룹 3').last);
      await tester.pumpAndSettle();
      dropdown = tester.widget<DropdownButton<String>>(
        find.byKey(const ValueKey('home-group-dropdown')),
      );
      expect(dropdown.value, 'group-3');
    },
  );

  testWidgets(
    'search detail and invite popup work on a small screen with keyboard and large text',
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
      await login(tester);
      await openGroup(tester, 'group-3');
      await tapKey(tester, 'group-apply');
      tester.view.viewInsets = const FakeViewPadding(bottom: 270);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await enter(
        tester,
        find.byKey(const ValueKey('group-invite-code')),
        '123456',
      );
      await tapKey(tester, 'group-invite-submit');
      await tapKey(tester, 'group-complete-confirm');
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
