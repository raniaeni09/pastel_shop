import '../models/app_user.dart';
import 'api.dart';

/// Endpoint autentikasi DummyJSON (JWT).
class AuthService {
  AuthService._();

  static const _expiresInMins = 60;

  static Future<({AppUser user, String access, String refresh})> login(
    String username,
    String password,
  ) async {
    final data = await Api.post('/auth/login', {
      'username': username,
      'password': password,
      'expiresInMins': _expiresInMins,
    }) as Map<String, dynamic>;
    final access = (data['accessToken'] ?? data['token']) as String?;
    if (access == null) {
      throw ApiException('Respons login tidak valid.');
    }
    return (
      user: AppUser.fromJson(data),
      access: access,
      refresh: data['refreshToken'] as String? ?? '',
    );
  }

  /// Profil user yang sedang login (butuh access token).
  static Future<AppUser> me(String accessToken) async {
    final data =
        await Api.get('/auth/me', token: accessToken) as Map<String, dynamic>;
    return AppUser.fromJson(data);
  }

  static Future<({String access, String refresh})> refresh(
    String refreshToken,
  ) async {
    final data = await Api.post('/auth/refresh', {
      'refreshToken': refreshToken,
      'expiresInMins': _expiresInMins,
    }) as Map<String, dynamic>;
    return (
      access: data['accessToken'] as String,
      refresh: data['refreshToken'] as String? ?? refreshToken,
    );
  }
}
