import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';

/// Daftar produk favorit, disimpan lokal.
class FavoritesState extends ChangeNotifier {
  static const _kFavs = 'favorite_products';

  // LinkedHashMap (default) menjaga urutan penambahan.
  final Map<int, Product> _items = {};

  List<Product> get items => _items.values.toList().reversed.toList();
  int get count => _items.length;

  bool isFavorite(int productId) => _items.containsKey(productId);

  void toggle(Product product) {
    if (_items.containsKey(product.id)) {
      _items.remove(product.id);
    } else {
      _items[product.id] = product;
    }
    notifyListeners();
    _save();
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kFavs);
      if (raw == null) return;
      for (final e in jsonDecode(raw) as List) {
        final p = Product.fromJson(e as Map<String, dynamic>);
        _items[p.id] = p;
      }
      notifyListeners();
    } catch (_) {
      _items.clear();
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kFavs,
        jsonEncode(_items.values.map((p) => p.toJson()).toList()),
      );
    } catch (_) {}
  }
}
