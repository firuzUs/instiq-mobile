import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.backgroundDark,
        onSurface: AppColors.foregroundDark,
        primary: AppColors.primaryDark,
        onPrimary: AppColors.backgroundDark,
        error: AppColors.destructiveDark,
        outline: AppColors.borderDark,
      ),
      cardTheme: CardTheme(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E2129),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: TextStyle(color: AppColors.mutedForegroundDark),
      ),
      textTheme: _textTheme(AppColors.foregroundDark, AppColors.mutedForegroundDark),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.foregroundDark,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.foregroundDark,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xEE121420),
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: AppColors.mutedForegroundDark,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: const ColorScheme.light(
        surface: AppColors.backgroundLight,
        onSurface: AppColors.foregroundLight,
        primary: AppColors.primaryLight,
        onPrimary: Colors.white,
        error: AppColors.destructiveDark,
        outline: AppColors.borderLight,
      ),
      cardTheme: CardTheme(
        color: AppColors.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: TextStyle(color: AppColors.mutedForegroundLight),
      ),
      textTheme: _textTheme(AppColors.foregroundLight, AppColors.mutedForegroundLight),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.foregroundLight,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.foregroundLight,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.mutedForegroundLight,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static TextTheme _textTheme(Color foreground, Color muted) {
    return TextTheme(
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: foreground,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: foreground,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: foreground,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: foreground,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: foreground,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: foreground,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: muted,
      ),
    );
  }
}
