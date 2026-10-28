import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiError implements Exception {
  final int status;
  final String message;
  final String code;
  const ApiError(this.status, this.message, [this.code = '']);
  @override
  String toString() => message;
}

class ApiClient {
  static const defaultUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8081/api/v2',
  );
  final String baseUrl;
  final http.Client client;
  String? token;
  Future<void> Function()? onUnauthorized;
  ApiClient({this.baseUrl = defaultUrl, http.Client? client})
    : client = client ?? http.Client();

  Future<dynamic> call(String method, String path, [Object? body]) async {
    final sentToken = token;
    final headers = {
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json; charset=utf-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    late http.Response response;
    try {
      final request = http.Request(
        method,
        Uri.parse('${baseUrl.replaceFirst(RegExp(r'/+$'), '')}$path'),
      )..headers.addAll(headers);
      if (body != null) request.bodyBytes = utf8.encode(jsonEncode(body));
      response = await client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const ApiError(0, '서버 응답 시간이 초과됐어요. 결제·승인 결과는 새로고침 후 확인해 주세요.');
    } on http.ClientException {
      throw const ApiError(0, '서버에 연결할 수 없어요. 서버 실행 상태와 접속 주소를 확인해 주세요.');
    }
    dynamic data;
    if (response.bodyBytes.isNotEmpty) {
      try {
        data = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        throw ApiError(response.statusCode, '서버 응답 형식을 확인할 수 없어요.');
      }
    }
    if (response.statusCode >= 400) {
      if (response.statusCode == 401 && token != null && token == sentToken) {
        await onUnauthorized?.call();
      }
      throw ApiError(
        response.statusCode,
        data is Map
            ? data['message'] as String? ?? '요청을 처리하지 못했어요.'
            : '요청을 처리하지 못했어요.',
        data is Map ? data['code'] as String? ?? '' : '',
      );
    }
    return data;
  }

  void close() => client.close();
}
