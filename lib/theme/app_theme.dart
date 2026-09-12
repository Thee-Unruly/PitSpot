import 'package:flutter/material.dart';

/// Design system inspired by Velora Bible:
/// Deep obsidian backgrounds, warm champagne gold accents, glassmorphic surfaces,
/// and heirloom serif typography tokens.
class AppTheme {
  // ─── Primary Palettes ───
  static const Color primaryAmber = Color(0xFFF59E0B); // Champagne Warm Gold
  static const Color accentGold = Color(0xFFFCD34D); // Bright Gold Accent
  static const Color primaryBlue = Color(0xFF3A86EF); // Electric Blue
  static const Color obsidianVoid = Color(0xFF090A10); // Deepest Obsidian
  static const Color darkBackground = Color(0xFF0D0F1A); // Velora Dark Canvas
  static const Color darkSurface = Color(0xFF141728); // Elevated Surface
  static const Color darkCard = Color(0xFF1B1E34); // Glassmorphic Card
  static const Color darkCardBorder = Color(0x26FFFFFF); // Subtle Glass Border

  // ─── Velora Relay Classifications ───
  static const Color relayReference = Color(0xFF67E8F9); // Neon Cyan (Direct Bible Citations)
  static const Color relayTurnTo = Color(0xFF86EFAC); // Mint Green (Preacher "Turn-to" cues)
  static const Color relayQuote = Color(0xFFFCD34D); // Gold (Direct spoken verse quote)
  static const Color relaySuggestion = Color(0xFFD8B4FE); // Soft Lavender (AI Contextual Allusion)

  // ─── Transcript Tag Highlights ───
  static const Color tagKeyPoint = Color(0xFF2DD4BF); // Teal
  static const Color tagJoke = Color(0xFFFB923C); // Warm Orange
  static const Color tagScripture = Color(0xFF67E8F9); // Cyan
  static const Color tagAltarCall = Color(0xFFF43F5E); // Rose Red

  // ─── Typography Helpers ───
  static const TextStyle scriptureStyle = TextStyle(
    fontSize: 16,
    height: 1.65,
    color: Color(0xFFF1F5F9),
    fontFamily: 'serif',
    letterSpacing: 0.2,
  );

  static const TextStyle heirloomQuoteStyle = TextStyle(
    fontSize: 15,
    height: 1.5,
    fontStyle: FontStyle.italic,
    color: Color(0xFFE2E8F0),
    fontFamily: 'serif',
  );

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
        onSurface: Color(0xFFF8FAFC),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkCardBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkCardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkCardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryAmber, width: 1.5),
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
        elevation: 8,
      ),
    );
  }
}

