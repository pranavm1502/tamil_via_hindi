import 'package:flutter/material.dart';

class PeacockTheme {
  // Peacock-inspired color palette
  static const Color peacockBlue = Color(0xFF005DAA);
  static const Color peacockGreen = Color(0xFF00A896);
  static const Color deepTeal = Color(0xFF028090);
  static const Color vibrantOrange = Color(0xFFF4A261); // For progress & highlights
  static const Color softCream = Color(0xFFFDFCF0); // For light mode background

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: peacockBlue,
        primary: peacockBlue,
        secondary: peacockGreen,
        surface: softCream,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: peacockBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      // FIX: Using 'const' and ensuring standard Material 3 parameters
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: peacockBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
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
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: peacockGreen,
        primary: peacockGreen,
        secondary: peacockBlue,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),
    );
  }
}