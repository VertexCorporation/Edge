import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// Vertex Design System - Theme Configuration
/// Derived from vertexishere.com CSS variables
class VertexTheme {
  // ─── DARK THEME ───
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: VertexColors.bgDark,
      primaryColor: VertexColors.primaryDark,
      colorScheme: const ColorScheme.dark(
        primary: VertexColors.primaryDark,
        onPrimary: VertexColors.btnTextDark,
        secondary: VertexColors.accentDark,
        surface: VertexColors.bgCardDark,
        onSurface: VertexColors.textMainDark,
        outline: VertexColors.borderDark,
      ),
      textTheme: _buildTextTheme(Brightness.dark),
      inputDecorationTheme: _buildInputTheme(Brightness.dark),
      cardTheme: CardThemeData(
        color: VertexColors.bgCardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: VertexColors.borderDark),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: VertexColors.primaryDark,
        unselectedItemColor: VertexColors.textMutedDark,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dividerColor: VertexColors.borderDark,
      useMaterial3: true,
    );
  }

  // ─── LIGHT THEME ───
  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: VertexColors.bgLight,
      primaryColor: VertexColors.primaryLight,
      colorScheme: const ColorScheme.light(
        primary: VertexColors.primaryLight,
        onPrimary: VertexColors.btnTextLight,
        secondary: VertexColors.accentLight,
        surface: VertexColors.bgCardLight,
        onSurface: VertexColors.textMainLight,
        outline: VertexColors.borderLight,
      ),
      textTheme: _buildTextTheme(Brightness.light),
      inputDecorationTheme: _buildInputTheme(Brightness.light),
      cardTheme: CardThemeData(
        color: VertexColors.bgCardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: VertexColors.borderLight),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: VertexColors.primaryLight,
        unselectedItemColor: VertexColors.textMutedLight,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dividerColor: VertexColors.borderLight,
      useMaterial3: true,
    );
  }

  // ─── Typography ───
  static TextTheme _buildTextTheme(Brightness brightness) {
    final color = brightness == Brightness.dark
        ? VertexColors.textMainDark
        : VertexColors.textMainLight;
    final mutedColor = brightness == Brightness.dark
        ? VertexColors.textMutedDark
        : VertexColors.textMutedLight;

    return GoogleFonts.interTextTheme(
      TextTheme(
        displayLarge: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: -1.5,
          height: 1.1,
        ),
        displayMedium: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: -0.5,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: color,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: color,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: color,
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: mutedColor,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: mutedColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ─── Input Decoration ───
  static InputDecorationTheme _buildInputTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final borderColor =
        isDark ? VertexColors.borderDark : VertexColors.borderLight;
    final fillColor = isDark
        ? VertexColors.bgCardDark.withValues(alpha: 0.5)
        : VertexColors.bgSecondaryLight.withValues(alpha: 0.5);
    final hintColor =
        isDark ? VertexColors.textMutedDark : VertexColors.textMutedLight;

    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      hintStyle: GoogleFonts.inter(
        color: hintColor.withValues(alpha: 0.5),
        fontSize: 14,
      ),
      labelStyle: GoogleFonts.inter(color: hintColor, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? VertexColors.primaryDark : VertexColors.primaryLight,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
    );
  }
}
