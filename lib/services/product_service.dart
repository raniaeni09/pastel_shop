import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/product.dart';

/// Error dari backend dengan pesan yang siap ditampilkan ke pengguna.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

/// CRUD produk ke backend (lihat folder backend/).
class ProductService {
  static const _timeout = Duration(seconds: 15);
  static const _headers = {'Content-Type': 'application/json'};

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);

  /// READ (daftar + pencarian). Jika [query] kosong -> semua produk.
  Future<List<Product>> fetchProducts({String query = ''}) async {
    final q = query.trim();
    final res = await _send(
        () => http.get(_uri('/products', q.isEmpty ? null : {'q': q})));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['products'] as List)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// CREATE
  Future<Product> createProduct(Product p) async {
    final res = await _send(() =>
        http.post(_uri('/products'), headers: _headers, body: jsonEncode(p.toJson())));
    return Product.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// UPDATE
  Future<Product> updateProduct(Product p) async {
    final res = await _send(() => http.put(_uri('/products/${p.id}'),
        headers: _headers, body: jsonEncode(p.toJson())));
    return Product.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// DELETE
  Future<void> deleteProduct(int id) async {
    await _send(() => http.delete(_uri('/products/$id')));
  }

  /// Menjalankan request, menerjemahkan error jaringan & status non-2xx.
  Future<http.Response> _send(Future<http.Response> Function() request) async {
    http.Response res;
    try {
      res = await request().timeout(_timeout);
    } catch (_) {
      throw ApiException(
          'Tidak bisa terhubung ke server (${ApiConfig.baseUrl}).\n'
          'Pastikan backend sudah berjalan.');
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return res;

    var msg = 'Permintaan gagal (kode ${res.statusCode})';
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final errors = (body['errors'] as List?)?.join('\n');
      msg = errors ?? body['message'] as String? ?? msg;
    } catch (_) {}
    throw ApiException(msg);
  }
}
