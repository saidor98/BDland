import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Theme Colors (Forest & Land Survey Aesthetics)
  static const Color primaryGreen = Color(0xFF0F5A38);
  static const Color primaryGreenDark = Color(0xFF0A3D26);
  static const Color primaryGreenLight = Color(0xFFE8F5E9);

  static const Color secondaryGold = Color(0xFFC29015);
  static const Color secondaryGoldDark = Color(0xFF8E680E);
  static const Color secondaryGoldLight = Color(0xFFFFF8E7);

  // Accent & Domain Specific Highlights
  static const Color accentNavy = Color(0xFF1A365D);
  static const Color accentTeal = Color(0xFF0D9488);
  static const Color accentPurple = Color(0xFF6B21A8); // Faraiz
  static const Color accentCrimson = Color(0xFFB91C1C); // Discrepancies/Alerts
  static const Color accentOrange = Color(0xFFC2410C); // Warning/Average method comparison

  // Neutral Background & Surface
  static const Color backgroundLight = Color(0xFFF6F8F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardBorderLight = Color(0xFFE2E8F0);

  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Gradients
  static const LinearGradient greenHeaderGradient = LinearGradient(
    colors: [primaryGreenDark, primaryGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldAccentGradient = LinearGradient(
    colors: [secondaryGold, secondaryGoldDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardSoftGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF9FBF8)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
