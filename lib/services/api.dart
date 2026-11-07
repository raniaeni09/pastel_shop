import 'dart:convert';

import 'package:http/http.dart' as http;

const apiBase = 'https://dummyjson.com';

/// Error dari backend / jaringan dengan pesan yang siap ditampilkan.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  bool get isUnauthorized => statusCode == 401 || statusCode == 403;

  @override
  String toString() => message;
}

/// Klien HTTP tipis untuk backend DummyJSON.
class Api {
  Api._();

  static const _timeout = Duration(seconds: 20);

  static Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    String? token,
  }) async {
    final uri = Uri.parse('$apiBase$path').replace(queryParameters: query);
    final res =
        await http.get(uri, headers: _headers(token)).timeout(_timeout);
    return _decode(res);
  }

  static Future<dynamic> post(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final res = await http
        .post(
          Uri.parse('$apiBase$path'),
          headers: _headers(token),
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    return _decode(res);
  }

  static dynamic _decode(http.Response res) {
    dynamic data;
    try {
      data = jsonDecode(res.body);
    } catch (_) {
      data = null;
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final msg = data is Map ? data['message'] as String? : null;
      throw ApiException(
        msg ?? 'Terjadi kesalahan (kode ${res.statusCode})',
        res.statusCode,
      );
    }
    return data;
  }
}
