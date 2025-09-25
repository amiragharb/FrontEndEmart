// lib/models/app_theme.dart
import 'package:flutter/material.dart';
import 'package:frontendemart/models/ciConfig_model.dart';

Color parseHexColor(String? hex, {Color fallback = const Color(0xFF0B1E6D)}) {
  if (hex == null) return fallback;
  var s = hex.trim();
  if (s.isEmpty) return fallback;
  s = s.replaceAll('#', '');
  if (s.toLowerCase().startsWith('0x')) s = s.substring(2);
  if (s.length == 6) s = 'FF$s';
  final v = int.tryParse(s, radix: 16);
  return v != null ? Color(v) : fallback;
}

class AppTheme {
  final Color primary;
  final Color secondary;
  final String? logoUrl;
  final ThemeData material;

  AppTheme._(this.primary, this.secondary, this.logoUrl, this.material);

  /// Fallback si pas de config
  factory AppTheme.fallback() {
    const p = Color(0xFF0B1E6D);
    const s = Colors.white;
    return AppTheme._(p, s, null, _buildTheme(p, s));
  }

  factory AppTheme.fromConfig(CiconfigModel c) {
    final p = parseHexColor(c.ciPrimaryColor);
    final s = parseHexColor(c.ciSecondaryColor, fallback: Colors.white);
    return AppTheme._(p, s, c.ciLogo, _buildTheme(p, s));
  }

  static ThemeData _buildTheme(Color p, Color s) {
    final scheme = ColorScheme.fromSeed(
      seedColor: p,
      brightness: Brightness.light,
    ).copyWith(
      primary: p,
      secondary: s,
    );

    // Définir la forme des Dialogs
    const dialogShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF6F6F8),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: p,
        elevation: 0,
        centerTitle: true,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p,
          side: BorderSide(color: p.withOpacity(.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p, width: 1.4),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: p,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      dividerTheme: const DividerThemeData(space: 24, thickness: 1),

      dialogTheme: const DialogThemeData(
        shape: dialogShape,
      ),
    );
  }
}