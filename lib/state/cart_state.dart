import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/api.dart';

class CheckoutResult {
  final int orderId;
  final int totalQuantity;
  final double total;

  CheckoutResult({
    required this.orderId,
    required this.totalQuantity,
    required this.total,
  });
}

/// Keranjang belanja. Disimpan lokal dan dikirim ke backend saat checkout.
class CartState extends ChangeNotifier {
  static const _kCart = 'cart_items';

  final Map<int, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();
  bool get isEmpty => _items.isEmpty;

  int get totalQuantity =>
      _items.values.fold(0, (sum, it) => sum + it.quantity);

  double get total => _items.values.fold(0.0, (sum, it) => sum + it.subtotal);

  int quantityOf(int productId) => _items[productId]?.quantity ?? 0;

  /// Menambah produk. Jumlah dibatasi oleh stok.
  /// Mengembalikan jumlah yang benar-benar ditambahkan (0 = stok maksimal).
  int add(Product product, {int quantity = 1}) {
    final current = quantityOf(product.id);
    final room = product.stock - current;
    final toAdd = quantity < room ? quantity : room;
    if (toAdd <= 0) return 0;
    final existing = _items[product.id];
    if (existing != null) {
      existing.quantity += toAdd;
    } else {
      _items[product.id] = CartItem(product: product, quantity: toAdd);
    }
    _changed();
    return toAdd;
  }

  void setQuantity(int productId, int quantity) {
    final item = _items[productId];
    if (item == null) return;
    if (quantity <= 0) {
      _items.remove(productId);
    } else {
      item.quantity =
          quantity > item.product.stock ? item.product.stock : quantity;
    }
    _changed();
  }

  void remove(int productId) {
    if (_items.remove(productId) != null) _changed();
  }

  void clear() {
    _items.clear();
    _changed();
  }

  /// Mengirim keranjang ke backend (POST /carts/add).
  /// Keranjang lokal dikosongkan hanya jika backend menerima.
  Future<CheckoutResult> checkout({required int userId}) async {
    final data = await Api.post('/carts/add', {
      'userId': userId,
      'products': [
        for (final it in _items.values)
          {'id': it.product.id, 'quantity': it.quantity},
      ],
    }) as Map<String, dynamic>;

    final result = CheckoutResult(
      orderId: (data['id'] as num?)?.toInt() ?? 0,
      totalQuantity:
          (data['totalQuantity'] as num?)?.toInt() ?? totalQuantity,
      total: (data['discountedTotal'] as num?)?.toDouble() ?? total,
    );
    clear();
    return result;
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCart);
      if (raw == null) return;
      final list = jsonDecode(raw) as List;
      for (final e in list) {
        final item = CartItem.fromJson(e as Map<String, dynamic>);
        _items[item.product.id] = item;
      }
      notifyListeners();
    } catch (_) {
      _items.clear();
    }
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kCart,
        jsonEncode(_items.values.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }
}
