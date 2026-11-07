import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import 'cart_screen.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

/// Kerangka utama dengan bottom navigation 4 tab.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: tabIndex,
      builder: (context, index, _) {
        return Scaffold(
          body: IndexedStack(
            index: index,
            children: const [
              HomeScreen(),
              FavoritesScreen(),
              CartScreen(),
              ProfileScreen(),
            ],
          ),
          bottomNavigationBar: ListenableBuilder(
            listenable: Listenable.merge([cartState, favoritesState]),
            builder: (context, _) {
              final cartCount = cartState.totalQuantity;
              final favCount = favoritesState.count;
              return NavigationBar(
                backgroundColor: AppColors.surface,
                indicatorColor: AppColors.lavender,
                selectedIndex: index,
                onDestinationSelected: (i) => tabIndex.value = i,
                destinations: [
                  const NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Beranda',
                  ),
                  NavigationDestination(
                    icon: Badge(
                      isLabelVisible: favCount > 0,
                      label: Text('$favCount'),
                      child: const Icon(Icons.favorite_border_rounded),
                    ),
                    selectedIcon: Badge(
                      isLabelVisible: favCount > 0,
                      label: Text('$favCount'),
                      child: const Icon(Icons.favorite_rounded),
                    ),
                    label: 'Favorit',
                  ),
                  NavigationDestination(
                    icon: Badge(
                      isLabelVisible: cartCount > 0,
                      label: Text('$cartCount'),
                      child: const Icon(Icons.shopping_cart_outlined),
                    ),
                    selectedIcon: Badge(
                      isLabelVisible: cartCount > 0,
                      label: Text('$cartCount'),
                      child: const Icon(Icons.shopping_cart_rounded),
                    ),
                    label: 'Keranjang',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.person_outline_rounded),
                    selectedIcon: Icon(Icons.person_rounded),
                    label: 'Profil',
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
