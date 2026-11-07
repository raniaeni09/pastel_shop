import 'package:flutter/foundation.dart';

import 'auth_state.dart';
import 'cart_state.dart';
import 'favorites_state.dart';

/// State global aplikasi (satu instance untuk seluruh app).
final authState = AuthState();
final cartState = CartState();
final favoritesState = FavoritesState();

/// Tab aktif di bottom navigation: 0 Beranda, 1 Favorit, 2 Keranjang, 3 Profil.
final tabIndex = ValueNotifier<int>(0);

const tabHome = 0;
const tabFavorites = 1;
const tabCart = 2;
const tabProfile = 3;
