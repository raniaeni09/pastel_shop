import 'package:flutter/foundation.dart' show kIsWeb;

/// Alamat backend.
///
/// Otomatis menyesuaikan platform:
///   Web (Chrome)     : http://localhost:3000
///   Emulator Android : http://10.0.2.2:3000
///
/// Untuk HP asli (WiFi sama dengan laptop), isi lewat --dart-define:
///   flutter run --dart-define=API_URL=http://192.168.1.10:3000
class ApiConfig {
  ApiConfig._();

  static const _override = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    return kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';
  }
}