import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../services/api.dart';
import '../services/auth_service.dart';

/// Status login. Sesi disimpan lokal supaya user tetap masuk setelah
/// aplikasi ditutup, lalu divalidasi ke backend di latar belakang.
class AuthState extends ChangeNotifier {
  static const _kSession = 'auth_session';

  AppUser? _user;
  String? _accessToken;
  String? _refreshToken;

  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;

  /// Memuat sesi tersimpan (tanpa jaringan) agar UI langsung benar.
  Future<void> loadCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kSession);
      if (raw == null) return;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      _accessToken = m['accessToken'] as String?;
      _refreshToken = m['refreshToken'] as String?;
      _user = AppUser.fromJson(m['user'] as Map<String, dynamic>);
      notifyListeners();
    } catch (_) {
      // Data rusak -> anggap belum login.
    }
  }

  /// Cek token ke backend (/auth/me). Jika kedaluwarsa, coba refresh token.
  /// Gagal karena jaringan -> sesi tersimpan tetap dipakai.
  Future<void> validateSession() async {
    final token = _accessToken;
    if (token == null) return;
    try {
      _user = await AuthService.me(token);
      await _persist();
      notifyListeners();
    } on ApiException catch (e) {
      if (e.isUnauthorized) await _tryRefresh();
    } catch (_) {
      // offline: pertahankan sesi tersimpan
    }
  }

  Future<void> _tryRefresh() async {
    final rt = _refreshToken;
    if (rt == null || rt.isEmpty) {
      await logout();
      return;
    }
    try {
      final t = await AuthService.refresh(rt);
      _accessToken = t.access;
      _refreshToken = t.refresh;
      _user = await AuthService.me(t.access);
      await _persist();
      notifyListeners();
    } on ApiException {
      await logout();
    } catch (_) {
      // offline: biarkan
    }
  }

  /// Melempar [ApiException] jika kredensial salah / jaringan bermasalah.
  Future<void> login(String username, String password) async {
    final r = await AuthService.login(username.trim(), password);
    _user = r.user;
    _accessToken = r.access;
    _refreshToken = r.refresh;
    await _persist();
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    _accessToken = null;
    _refreshToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kSession);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kSession,
        jsonEncode({
          'accessToken': _accessToken,
          'refreshToken': _refreshToken,
          'user': _user?.toJson(),
        }),
      );
    } catch (_) {}
  }
}
