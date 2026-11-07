import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../services/api.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/qty_stepper.dart';
import 'login_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _busy = false;

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<void> _checkout() async {
    if (!authState.isLoggedIn) {
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (ok != true || !authState.isLoggedIn || !mounted) return;
    }

    setState(() => _busy = true);
    try {
      final result = await cartState.checkout(userId: authState.user!.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          icon: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
                color: AppColors.mint, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded,
                size: 32, color: AppColors.textDark),
          ),
          title: const Text('Pesanan berhasil!'),
          content: Text(
            'Pesanan #${result.orderId} (${result.totalQuantity} barang) '
            'sudah diterima server.\n'
            'Total: \$${result.total.toStringAsFixed(2)}',
            textAlign: TextAlign.center,
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Oke'),
            ),
          ],
        ),
      );
    } on ApiException catch (e) {
      if (mounted) _snack('Checkout gagal: ${e.message}');
    } catch (_) {
      if (mounted) {
        _snack('Checkout gagal. Periksa koneksi internet kamu.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([cartState, authState]),
          builder: (context, _) {
            final items = cartState.items;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Text('Keranjang',
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800)),
                ),
                Expanded(
                  child: items.isEmpty
                      ? EmptyState(
                          icon: Icons.shopping_cart_outlined,
                          color: AppColors.sky,
                          text: 'Keranjangmu masih kosong.',
                          actionLabel: 'Mulai belanja',
                          onAction: () => tabIndex.value = tabHome,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) =>
                              _CartTile(item: items[i], index: i),
                        ),
                ),
                if (items.isNotEmpty) _buildSummary(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.lavender.withOpacity(0.8),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('${cartState.totalQuantity} barang',
                  style: const TextStyle(color: AppColors.textSoft)),
              const Spacer(),
              const Text('Total  ',
                  style: TextStyle(color: AppColors.textSoft)),
              Text(
                '\$${cartState.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
              onPressed: _busy ? null : _checkout,
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      authState.isLoggedIn
                          ? 'Checkout'
                          : 'Masuk & Checkout',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartTile extends StatelessWidget {
  final CartItem item;
  final int index;

  const _CartTile({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final p = item.product;
    final bg = AppColors.cardColor(index);
    return Dismissible(
      key: ValueKey('cart-${p.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => cartState.remove(p.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.pink,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.textDark),
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: bg.withOpacity(0.6),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.network(
                p.thumbnail,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.textSoft),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${p.finalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSoft),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      QtyStepper(
                        value: item.quantity,
                        onMinus: () => cartState.setQuantity(
                            p.id, item.quantity - 1),
                        onPlus: item.quantity < p.stock
                            ? () => cartState.setQuantity(
                                p.id, item.quantity + 1)
                            : null,
                      ),
                      const Spacer(),
                      Text(
                        '\$${item.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
