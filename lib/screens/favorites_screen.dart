import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/product_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: favoritesState,
          builder: (context, _) {
            final items = favoritesState.items;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Text(
                    items.isEmpty ? 'Favorit' : 'Favorit (${items.length})',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? EmptyState(
                          icon: Icons.favorite_border_rounded,
                          color: AppColors.pink,
                          text: 'Belum ada produk favorit.\n'
                              'Ketuk ikon hati pada produk untuk menyimpannya.',
                          actionLabel: 'Lihat produk',
                          onAction: () => tabIndex.value = tabHome,
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, i) => ProductCard(
                            key: ValueKey('fav-${items[i].id}'),
                            product: items[i],
                            index: i,
                            heroPrefix: 'fav',
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
