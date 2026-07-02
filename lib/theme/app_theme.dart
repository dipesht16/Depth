import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette Definitions
  static const Color primaryBg = Color(0xFF000000);       // Pure Black
  static const Color secondaryBg = Color(0xFF121212);     // Dark Gray
  static const Color accentColor = Color(0xFFFFD700);     // Yellow/Gold
  static const Color textPrimary = Color(0xFFFFFFFF);     // White
  static const Color textSecondary = Color(0xFFB0B0B0);   // Light Gray
  static const Color inactiveColor = Color(0xFF424242);   // Darker Gray

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryBg,
      colorScheme: const ColorScheme.dark(
        primary: accentColor,
        secondary: accentColor,
        surface: secondaryBg,
        onPrimary: primaryBg,
        onSecondary: primaryBg,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: primaryBg,
        elevation: 4,
        shape: CircleBorder(),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: accentColor,
        unselectedLabelColor: textSecondary,
        indicatorColor: accentColor,
        dividerColor: Colors.transparent,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: secondaryBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
