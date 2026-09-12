import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryAmber = Color(0xFFFFB703);
  static const Color primaryBlue = Color(0xFF3A86EF);
  static const Color darkBackground = Color(0xFF0F101C);
  static const Color darkSurface = Color(0xFF191B2E);
  static const Color darkCard = Color(0xFF22253F);
  static const Color accentPurple = Color(0xFF8338EC);
  static const Color tagKeyPoint = Color(0xFF2A9D8F);
  static const Color tagJoke = Color(0xFFF4A261);
  static const Color tagScripture = Color(0xFFE76F51);
  static const Color tagAltarCall = Color(0xFFE63946);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryAmber,
        secondary: primaryBlue,
        surface: darkSurface,
        onPrimary: Colors.black,
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryAmber,
        foregroundColor: Colors.black,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: primaryAmber,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
