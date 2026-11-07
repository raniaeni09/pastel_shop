import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Keluar?'),
        content: const Text('Kamu harus masuk lagi untuk checkout.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ok == true) await authState.logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable:
              Listenable.merge([authState, cartState, favoritesState]),
          builder: (context, _) {
            final user = authState.user;
            if (user == null) {
              return EmptyState(
                icon: Icons.person_outline_rounded,
                color: AppColors.lavender,
                text: 'Kamu belum masuk.\nMasuk untuk checkout pesananmu.',
                actionLabel: 'Masuk',
                onAction: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('Profil',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.lavender,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: Colors.white,
                        backgroundImage: user.image.isEmpty
                            ? null
                            : NetworkImage(user.image),
                        onBackgroundImageError:
                            user.image.isEmpty ? null : (_, __) {},
                        child: user.image.isEmpty
                            ? Text(
                                user.firstName.isEmpty
                                    ? '?'
                                    : user.firstName[0].toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.fullName,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800)),
                            Text('@${user.username}',
                                style: const TextStyle(
                                    color: AppColors.textDark)),
                            const SizedBox(height: 2),
                            Text(user.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textDark)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _StatTile(
                  icon: Icons.favorite_rounded,
                  color: AppColors.pink,
                  label: 'Produk favorit',
                  value: '${favoritesState.count}',
                  onTap: () => tabIndex.value = tabFavorites,
                ),
                const SizedBox(height: 12),
                _StatTile(
                  icon: Icons.shopping_cart_rounded,
                  color: AppColors.sky,
                  label: 'Barang di keranjang',
                  value: '${cartState.totalQuantity}',
                  onTap: () => tabIndex.value = tabCart,
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textDark,
                    minimumSize: const Size.fromHeight(52),
                    side: const BorderSide(color: AppColors.accent, width: 2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Keluar'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _StatTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textDark),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Text(value,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textDark),
            ],
          ),
        ),
      ),
    );
  }
}
