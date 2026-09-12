import 'package:flutter/material.dart';

/// Design system crafted to match Velora Bible:
/// Deep obsidian canvas, rich moody glass cards, warm champagne gold accents,
/// glowing indicator nodes, and heirloom serif typography tokens.
class AppTheme {
  // ─── Primary Palettes ───
  static const Color obsidianVoid = Color(0xFF0A0C10); // True Obsidian Black
  static const Color darkBackground = Color(0xFF0F1117); // Velora Dark Canvas
  static const Color darkSurface = Color(0xFF151822); // Elevated Glass Surface
  static const Color darkCard = Color(0xFF1B1E2B); // Secondary Surface Card
  static const Color darkCardBorder = Color(0x1FFFFFFF); // Subtle Glass Border
  static const Color darkCardBorderHighlight = Color(0x33F59E0B); // Amber Glow Border

  // ─── Velora Brand Accents ───
  static const Color primaryAmber = Color(0xFFF59E0B); // Champagne Warm Gold
  static const Color accentGold = Color(0xFFFBBF24); // Radiant Gold Accent
  static const Color mutedGold = Color(0xFFD97706); // Deep Gold
  static const Color goldBronzePill = Color(0xFF2A2016); // Verse Tag Pill

  // ─── Velora Relay Classifications ───
  static const Color relayQuote = Color(0xFFFBBF24); // Warm Gold [99]
  static const Color relaySuggestion = Color(0xFFC084FC); // Soft Purple/Lavender [💡]
  static const Color relayTurnTo = Color(0xFF4ADE80); // Mint Emerald [📖]
  static const Color relayReference = Color(0xFF38BDF8); // Electric Cyan [•]
  static const Color relayPrayer = Color(0xFF818CF8); // Indigo/Purple [☗]
  static const Color relaySinging = Color(0xFFF472B6); // Rose Pink [♫]

  // ─── Transcript Tag Highlights ───
  static const Color tagKeyPoint = Color(0xFF2DD4BF); // Teal
  static const Color tagJoke = Color(0xFFFB923C); // Warm Orange
  static const Color tagScripture = Color(0xFF38BDF8); // Cyan
  static const Color tagAltarCall = Color(0xFFF43F5E); // Rose Red

  // ─── Typography Helpers ───
  static const TextStyle brandHeaderStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 6.0,
    color: Colors.white,
  );

  static const TextStyle sermonTitleStyle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: -0.5,
    height: 1.25,
  );

  static const TextStyle scriptureStyle = TextStyle(
    fontSize: 18,
    height: 1.65,
    color: Color(0xFFF8FAFC),
    fontFamily: 'serif',
    letterSpacing: 0.2,
  );

  static const TextStyle scriptureItalicStyle = TextStyle(
    fontSize: 16,
    height: 1.6,
    fontStyle: FontStyle.italic,
    color: Color(0xFFE2E8F0),
    fontFamily: 'serif',
  );

  static const TextStyle commentaryStyle = TextStyle(
    fontSize: 14,
    height: 1.5,
    color: Color(0xFF94A3B8),
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryAmber,
        secondary: relaySuggestion,
        surface: darkSurface,
        onPrimary: Colors.black,
        onSurface: Color(0xFFF8FAFC),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Colors.white70),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: darkCardBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkCardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkCardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryAmber, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0D0F16),
        selectedItemColor: primaryAmber,
        unselectedItemColor: Color(0xFF64748B),
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
    );
  }
}

