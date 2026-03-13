import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF080C14);
  static const Color surface = Color(0xFF0F1623);
  static const Color surfaceElevated = Color(0xFF161E2E);
  static const Color card = Color(0xFF1A2235);
  static const Color border = Color(0xFF252D3F);
  static const Color primary = Color(0xFF00D4FF);
  static const Color primaryDark = Color(0xFF0099CC);
  static const Color accent = Color(0xFFFF6B35);
  static const Color accentGold = Color(0xFFFFB800);
  static const Color textPrimary = Color(0xFFEEF2FF);
  static const Color textSecondary = Color(0xFF7C8DB0);
  static const Color textMuted = Color(0xFF3D4F6B);
  static const Color success = Color(0xFF00E676);
  static const Color error = Color(0xFFFF3D57);
  static const Color live = Color(0xFFFF2D55);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: primary,
        secondary: accent,
        error: error,
        onSurface: textPrimary,
        onPrimary: background,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
