import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../data/remote/supabase_config.dart';

class CgeApiException implements Exception {
  final String message;
  final int? statusCode;
  final Object? details;

  const CgeApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() => message;
}

/// Authenticated client for server-owned CGE operations.
///
/// Native builds should point this at the deployed website API. Local builds
/// can override it with:
/// `--dart-define=CGE_API_BASE_URL=http://10.0.2.2:3000`
class CgeApiClient {
  CgeApiClient._();

  static const String baseUrl = String.fromEnvironment(
    'CGE_API_BASE_URL',
    defaultValue: 'https://cgelounge.com',
  );

  static Future<Map<String, dynamic>> get(String path) {
    return _request('GET', path);
  }

  static Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) {
    return _request('POST', path, body: body);
  }

  static Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final token = SupabaseConfig.client.auth.currentSession?.accessToken;
    if ((token == null || token.isEmpty) && method != 'GET') {
      throw const CgeApiException(
        'Please sign in to continue',
        statusCode: 401,
      );
    }

    final request = http.Request(method, Uri.parse('$baseUrl$path'))
      ..headers.addAll({
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      });
    if (method != 'GET' || body != null) {
      request.body = jsonEncode(body ?? const <String, dynamic>{});
    }
    final response = await http.Response.fromStream(await request.send());

    Map<String, dynamic> decoded = const {};
    if (response.body.isNotEmpty) {
      final value = jsonDecode(response.body);
      if (value is Map<String, dynamic>) decoded = value;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CgeApiException(
        decoded['error'] as String? ?? 'Request failed',
        statusCode: response.statusCode,
        details: decoded['details'],
      );
    }

    return decoded;
  }
}
