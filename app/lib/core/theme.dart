import 'package:flutter/material.dart';

/// MyPA brand colors — kept consistent with the color palette used across
/// the project's documentation (navy/accent blue, per BRD & Architecture docs).
class MyPAColors {
  MyPAColors._();

  static const navy = Color(0xFF1F3864);
  static const accent = Color(0xFF2E74B5);
}

ThemeData buildMyPATheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: MyPAColors.accent,
    primary: MyPAColors.accent,
    onPrimary: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: const Color(0xFFF7F8FA),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: MyPAColors.navy,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF0F1F3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: MyPAColors.accent.withValues(alpha: 0.15),
    ),
  );
}
