import 'package:flutter/material.dart';

/// Цвета по MOBILE_UI_SPEC — Dark (по умолчанию) и Light.
class AppColors {
  AppColors._();

  // Dark theme
  static const Color backgroundDark = Color(0xFF0A0B10);
  static const Color cardDark = Color(0xFF121420);
  static const Color foregroundDark = Color(0xFFF3F2EF);
  static const Color primaryDark = Color(0xFFEC4899);
  static const Color accentDark = Color(0xFFF97316);
  static const Color mutedForegroundDark = Color(0xFF858994);
  static const Color borderDark = Color(0xFF272A36);
  static const Color destructiveDark = Color(0xFFD63031);

  // Light theme
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color foregroundLight = Color(0xFF171717);
  static const Color primaryLight = Color(0xFFDB2777);
  static const Color mutedForegroundLight = Color(0xFF666666);
  static const Color borderLight = Color(0xFFDBDBDB);

  // Gradient (розовый → красный → оранжевый → жёлтый), направление 135°
  static const List<Color> gradientPrimary = [
    Color(0xFFEC4899),
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFFEAB308),
  ];
  static const LinearGradient gradientPrimaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: gradientPrimary,
  );
}
