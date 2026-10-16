import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Material 3 window size classes, the app's single source of truth for
/// responsive decisions. Screens ask [AppBreakpoints.of] instead of inventing
/// their own width thresholds, so phones (≤600), small tablets (600–1024) and
/// full-size tablets/desktops (>1024) get consistent layouts everywhere.
enum WindowSize { compact, medium, expanded }

class AppBreakpoints {
  AppBreakpoints._();

  static const double compactMax = 600;
  static const double mediumMax = 1024;

  /// Width above which the persistent sidebar chrome is shown instead of the
  /// drawer (HomeScreen). Kept coarser than the window classes: even a small
  /// tablet in landscape has room for the sidebar, but a phone in any
  /// orientation does not.
  static const double wideChromeAt = 800;

  /// Width above which the POS screen shows its cart as a side rail instead
  /// of the bottom bar. 760 sits just below iPad portrait (768/810/820), so
  /// every iPad orientation gets the split grid|rail; phones still fall
  /// through to the bottom bar. Must stay above [wideChromeAt] so the
  /// sidebar switch and the rail have room together.
  static const double posRailAt = 760;

  static WindowSize classify(double width) {
    if (width > mediumMax) return WindowSize.expanded;
    if (width > compactMax) return WindowSize.medium;
    return WindowSize.compact;
  }

  static WindowSize of(BuildContext context) =>
      classify(MediaQuery.sizeOf(context).width);

  /// Clamps a preferred dialog width to the window so dialogs never run off
  /// small screens (a phone in portrait is ~360 logical px wide, narrower
  /// than most of the app's fixed 400–500px dialogs).
  static double dialogWidth(BuildContext context, double preferred) {
    final screen = MediaQuery.sizeOf(context).width;
    return math.min(preferred, screen - 32);
  }
}

class AppTheme {
  // Elegant Luxury Color Palette
  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color secondaryGold = Color(0xFFC5A028);
  static const Color lightGold = Color(0xFFF5E6C8);
  static const Color goldAccent = Color(0xFFFFD700);

  static const Color deepPurple = Color(0xFF2D1B4E);
  static const Color darkPurple = Color(0xFF1A0F2E);
  static const Color mediumPurple = Color(0xFF4A3266);
  static const Color lightPurple = Color(0xFF6B4C8A);

  static const Color cream = Color(0xFFFFFBF5);
  static const Color ivory = Color(0xFFFFFFF0);
  static const Color darkText = Color(0xFF1A1A2E);
  static const Color subtleText = Color(0xFF666666);

  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);

  // ── Dark palette ─────────────────────────────────────────────────────────
  // Deep purple-black surfaces with the same gold accents; gold stays
  // identical so brand elements (badges, buttons, decorations) carry over.
  static const Color darkBackground = Color(0xFF151021);
  static const Color darkSurface = Color(0xFF221A33);
  static const Color darkRaised = Color(0xFF2C2242);
  static const Color darkTextLight = Color(0xFFF3EDE0);
  static const Color darkMutedText = Color(0xFFA79FC0);
  static const Color darkHairline = Color(0xFF3F2E5C);

  // ── Brightness-tracking mode ─────────────────────────────────────────────
  // Screens consume these adaptive getters instead of the fixed constants
  // above; ThemeProvider sets this on mode/system changes.
  static bool _isDark = false;
  static bool get isDark => _isDark;
  static void setDarkMode(bool value) => _isDark = value;

  static Color get background => _isDark ? darkBackground : cream;
  static Color get surfaceColor => _isDark ? darkSurface : Colors.white;
  static Color get raisedColor => _isDark ? darkRaised : ivory;
  static Color get textColor => _isDark ? darkTextLight : darkText;
  static Color get mutedText => _isDark ? darkMutedText : subtleText;
  static Color get hairline => _isDark ? darkHairline : lightGold;

  // ThemeData
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGold,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: cream,
      appBarTheme: AppBarTheme(
        backgroundColor: deepPurple,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: darkPurple.withOpacity(0.3),
        titleTextStyle: const TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 4,
        shadowColor: darkPurple.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: lightGold.withOpacity(0.3), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: darkText,
          elevation: 3,
          shadowColor: primaryGold.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryGold,
        foregroundColor: darkText,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightGold),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightGold.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGold, width: 2),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Montserrat',
          color: subtleText,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: darkText,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: darkText,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: darkText,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: darkText,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: subtleText,
        ),
      ),
    );
  }

  // Decorations
  static BoxDecoration goldBorderDecoration({
    double radius = 16,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? primaryGold.withOpacity(0.3),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: _isDark ? const Color(0xFF000000) : darkPurple.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration gradientDecoration({
    double radius = 16,
  }) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          deepPurple,
          mediumPurple,
        ],
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: deepPurple.withOpacity(0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration goldGradientDecoration({
    double radius = 16,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primaryGold,
          secondaryGold,
          primaryGold,
        ],
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: primaryGold.withOpacity(0.4),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  // ThemeData
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGold,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkPurple,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Color(0x66000000),
        titleTextStyle: TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 4,
        shadowColor: const Color(0x99000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: darkHairline, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: darkText,
          elevation: 3,
          shadowColor: Colors.black.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGold,
        foregroundColor: darkText,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkRaised,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkHairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkHairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGold, width: 2),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Montserrat',
          color: darkMutedText,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: darkTextLight,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: darkTextLight,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: darkTextLight,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkTextLight,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: darkTextLight,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: darkTextLight,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: darkTextLight,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: darkMutedText,
        ),
      ),
    );
  }
}