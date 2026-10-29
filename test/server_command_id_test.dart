import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:capstone_proto_02/api_client.dart';
import 'package:capstone_proto_02/server_gateway.dart';

void main() {
  test('command IDs are valid and independent on native and web runtimes', () {
    final ids = <String>{};
    for (var i = 0; i < 100; i++) {
      final id = ServerGateway.commandId();
      expect(id, matches(RegExp(r'^[0-9a-f]{8}(?:-[0-9a-f]{8}){3}$')));
      expect(ids.add(id), isTrue);
    }
  });

  test(
    'group application sends its generated command ID before publishing state',
    () async {
      final calls = <http.Request>[];
      final gateway = ServerGateway(
        api: ApiClient(
          client: MockClient((request) async {
            calls.add(request);
            return http.Response(
              jsonEncode({
                'result': {'id': 'application-browser-test'},
                'snapshot': {
                  'revision': 1,
                  'account': {'id': 'applicant'},
                  'isAdmin': false,
                  'serverTime': '2026-10-29T00:00:00Z',
                },
              }),
              200,
            );
          }),
        ),
      );
      addTearDown(gateway.dispose);
      final result = await gateway.command('group.join', {
        'groupId': 'group-1',
        'introduction': '가입 신청',
      });
      expect(result['id'], 'application-browser-test');
      expect(calls, hasLength(1));
      expect(calls.single.url.path, '/api/v2/groups/join');
      final body = jsonDecode(calls.single.body) as Map<String, dynamic>;
      expect(
        body['commandId'],
        matches(RegExp(r'^[0-9a-f]{8}(?:-[0-9a-f]{8}){3}$')),
      );
      expect(body['data']['groupId'], 'group-1');
      expect(gateway.revision, 1);
    },
  );
}
