import 'package:flutter/material.dart';

class PeacockTheme {
  // Peacock-inspired color palette
  static const Color peacockBlue = Color(0xFF005DAA);
  static const Color peacockGreen = Color(0xFF00A896);
  static const Color deepTeal = Color(0xFF028090);
  static const Color vibrantOrange = Color(0xFFF4A261);
  static const Color softCream = Color(0xFFF7F3E9);
  static const Color ink = Color(0xFF1F2A2E);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'NotoSansTamil',
      fontFamilyFallback: const ['NotoSansHindi', 'NotoSansTamil'],
      colorScheme: ColorScheme.fromSeed(
        seedColor: peacockBlue,
        primary: peacockBlue,
        secondary: peacockGreen,
        surface: softCream,
        error: vibrantOrange,
      ),
      scaffoldBackgroundColor: softCream,
      appBarTheme: const AppBarTheme(
        backgroundColor: peacockBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: peacockBlue,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: peacockGreen.withAlpha(40),
        labelStyle: const TextStyle(color: ink, fontWeight: FontWeight.w600),
        side: BorderSide(color: peacockGreen.withAlpha(120)),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16, height: 1.35),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: vibrantOrange,
        linearTrackColor: Color(0xFFE0E0E0),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'NotoSansTamil',
      fontFamilyFallback: const ['NotoSansHindi', 'NotoSansTamil'],
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: peacockGreen,
        primary: peacockGreen,
        secondary: peacockBlue,
        error: vibrantOrange,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF142026),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: peacockGreen,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: peacockGreen.withAlpha(30),
        labelStyle: const TextStyle(color: Colors.white),
        side: BorderSide(color: peacockGreen.withAlpha(80)),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16, height: 1.35),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: vibrantOrange,
      ),
    );
  }
}
