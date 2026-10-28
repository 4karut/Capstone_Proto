import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstone_proto_02/api_client.dart';
import 'package:capstone_proto_02/demo_auth_store.dart';
import 'package:capstone_proto_02/main.dart';
import 'package:capstone_proto_02/main_screen.dart';
import 'package:capstone_proto_02/server_gateway.dart';

import 'auth_test_helpers.dart';

void main() {
  testWidgets(
    'server login failure cannot fall back to demo; session expiry returns to login',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      bool reject = true, expire = false;
      final calls = <http.Request>[];
      final account = {
        'id': 'hantuck01',
        'name': '서버 회원',
        'birthDate': '2001-03-15',
        'email': 'server@example.test',
        'phoneNumber': '01012345678',
      };
      final snapshot = {
        'account': account,
        'isAdmin': false,
        'revision': 1,
        'groups': <dynamic>[],
        'members': <String, dynamic>{},
        'groupApplications': <dynamic>[],
        'stores': <dynamic>[],
        'storeApplications': <dynamic>[],
        'offers': <dynamic>[],
        'donations': <dynamic>[],
        'requests': <dynamic>[],
        'receipts': <dynamic>[],
        'groupFavorites': <String>[],
        'storeFavorites': <String>[],
        'serverTime': DateTime.now().toUtc().toIso8601String(),
      };
      final client = MockClient((r) async {
        calls.add(r);
        dynamic result;
        var status = 200;
        if (r.url.path.endsWith('/health')) {
          result = {'demo': true};
        } else if (r.url.path.endsWith('/auth/login')) {
          if (reject) {
            status = 401;
            result = {'message': '서버 로그인 실패'};
          } else {
            result = {'accessToken': 'server-token', 'account': account};
          }
        } else if (r.url.path.endsWith('/snapshot')) {
          if (expire) {
            status = 401;
            result = {'message': '세션 만료'};
          } else {
            result = snapshot;
          }
        } else {
          status = 404;
          result = {'message': 'unknown route'};
        }
        return http.Response(
          jsonEncode(result),
          status,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final gateway = ServerGateway(
        api: ApiClient(baseUrl: 'http://fixture/api/v2', client: client),
      );
      final auth = DemoAuthStore(seedDemoAccount: false, gateway: gateway);
      await auth.initializeRemote();
      await tester.pumpWidget(HantuckApp(authStore: auth));
      await tapKey(tester, 'login-demo-fill');
      await tapKey(tester, 'login-submit');
      expect(find.byType(MainScreen), findsNothing);
      expect(find.text('서버 로그인 실패'), findsOneWidget);
      reject = false;
      await tapKey(tester, 'login-submit');
      expect(find.byType(MainScreen), findsOneWidget);
      expect(
        calls.any((r) => r.headers['Authorization'] == 'Bearer server-token'),
        isTrue,
      );
      await tapKey(tester, 'nav-my-page');
      expect(find.text('서버 회원'), findsOneWidget);
      expire = true;
      await expectLater(gateway.refresh(), throwsStateError);
      await tester.pumpAndSettle();
      expect(find.byType(MainScreen), findsNothing);
      expect(find.byKey(const ValueKey('login-submit')), findsOneWidget);
      expect(auth.groups.memberships('hantuck01'), isEmpty);
      expect(gateway.api.token, isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      gateway.dispose();
    },
  );
}
