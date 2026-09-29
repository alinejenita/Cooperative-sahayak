import 'package:flutter/material.dart';

class KioskColors {
  // Color Palette matching exact Raspberry Pi Kiosk Deck slides:
  static const Color background = Color(0xFFEAEFE6); // Soft Mint Sage Background
  static const Color primaryForestGreen = Color(0xFF1E4D2B); // Dark Forest Green Header/Borders/Footer
  static const Color accentTerracotta = Color(0xFFD04829); // Accent Red/Terracotta Highlight
  static const Color lightMintTint = Color(0xFFF3F7F1); // Light Card Tint
  static const Color secondaryTeal = Color(0xFF2E7D78); // Secondary Accent
  static const Color darkCharcoal = Color(0xFF1E2825); // Main Body Text
  static const Color mutedCharcoal = Color(0xFF4A5854); // Muted Subtitles
  static const Color lightSurface = Color(0xFFFFFFFF); // White Card Surface
  static const Color cardBorder = Color(0xFF1E4D2B); // 2px Dark Forest Green Border

  // Legacy aliases
  static const Color primaryTeal = primaryForestGreen;
  static const Color primaryGreen = primaryForestGreen;
  static const Color secondaryTealLight = lightMintTint;
  static const Color accentSaffron = accentTerracotta;

  // Status Colors
  static const Color successGreen = Color(0xFF1E4D2B);
  static const Color successBg = Color(0xFFE5EFE7);
  static const Color warningAmber = Color(0xFFD04829);
  static const Color warningBg = Color(0xFFFDF0ED);
  static const Color errorRed = Color(0xFFD04829);

  // Keypad Simulation Colors
  static const Color keypadBlueKey = Color(0xFF2563EB);
  static const Color keypadRedKey = Color(0xFFDC2626);
  static const Color keypadGreenKey = Color(0xFF16A34A);
  static const Color keypadDarkBody = Color(0xFF1F2937);
}

class KioskTheme {
  static const List<String> indicFontFallbacks = [
    'NotoSansDevanagari',
    'NotoSansTamil',
    'NotoSansTelugu',
    'NotoSansMalayalam',
    'NotoSansKannada',
    'Roboto',
    'sans-serif',
  ];

  static const List<String> serifFontFallbacks = [
    'NotoSerif',
    ...indicFontFallbacks,
  ];

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: KioskColors.background,
      colorScheme: const ColorScheme.light(
        primary: KioskColors.primaryForestGreen,
        secondary: KioskColors.secondaryTeal,
        surface: KioskColors.lightSurface,
        onSurface: KioskColors.darkCharcoal,
        error: KioskColors.errorRed,
      ),
      fontFamily: 'NotoSerif',
      fontFamilyFallback: indicFontFallbacks,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: KioskColors.primaryForestGreen,
          height: 1.25,
          fontFamily: 'NotoSerif',
          fontFamilyFallback: serifFontFallbacks,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: KioskColors.primaryForestGreen,
          height: 1.3,
          fontFamily: 'NotoSerif',
          fontFamilyFallback: serifFontFallbacks,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: KioskColors.darkCharcoal,
          height: 1.3,
          fontFamily: 'NotoSerif',
          fontFamilyFallback: serifFontFallbacks,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: KioskColors.darkCharcoal,
          height: 1.4,
          fontFamily: 'NotoSerif',
          fontFamilyFallback: serifFontFallbacks,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: KioskColors.darkCharcoal,
          height: 1.5,
          fontFamily: 'Roboto',
          fontFamilyFallback: indicFontFallbacks,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: KioskColors.mutedCharcoal,
          height: 1.5,
          fontFamily: 'Roboto',
          fontFamilyFallback: indicFontFallbacks,
        ),
      ),
      cardTheme: CardThemeData(
        color: KioskColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: KioskColors.primaryForestGreen, width: 2),
        ),
      ),
    );
  }

  // Accessible focus outline decoration matching deck slides (Thick dark green or red outline)
  static BoxDecoration focusDecoration({bool isFocused = false, double borderRadius = 16, bool isRedHighlight = false}) {
    return BoxDecoration(
      color: isFocused ? KioskColors.lightMintTint : KioskColors.lightSurface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isFocused
            ? (isRedHighlight ? KioskColors.accentTerracotta : KioskColors.primaryForestGreen)
            : KioskColors.primaryForestGreen,
        width: isFocused ? 3.5 : 1.8,
      ),
      boxShadow: isFocused
          ? [
              BoxShadow(
                color: (isRedHighlight ? KioskColors.accentTerracotta : KioskColors.primaryForestGreen).withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1,
              )
            ]
          : [],
    );
  }
}
