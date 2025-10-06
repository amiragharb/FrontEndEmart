// lib/config/api.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

class ApiConfig {
  // 1) Peut être forcé au build: --dart-define=API_BASE=...
  static const String _env =
      String.fromEnvironment('API_BASE', defaultValue: '');

  /// Base URL finale
  static String get baseUrl {
    if (_env.isNotEmpty) return _env;

    // 2) Auto par plateforme (utile en dev)
    if (kIsWeb) {
      // Flutter Web tourne dans le navigateur
      // -> si le backend est sur ta machine: utilise l'IP LAN
      return 'http://127.0.0.1:3001';
    }

    if (Platform.isAndroid) {
      // Émulateur Android: 10.0.2.2 pointe vers l’hôte
      return 'http://10.0.2.2:3001';
    }

    if (Platform.isIOS) {
      // Simulateur iOS: localhost ok
      return 'http://127.0.0.1:3001';
    }

    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      return 'http://127.0.0.1:3001';
    }

    // 3) Default (rarement utilisé)
    return kReleaseMode
        ? 'https://api.example.com' // prod fallback
        : 'http://127.0.0.1:3001';   // dev fallback
  }
}
