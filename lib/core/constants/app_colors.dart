import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Theme Colors (Stitch "Cadastral Precision" Emerald & Gold)
  static const Color primaryGreen = Color(0xFF004126);
  static const Color primaryGreenDark = Color(0xFF002111);
  static const Color primaryContainer = Color(0xFF0F5A38);
  static const Color primaryGreenLight = Color(0xFFE9F7EF);

  static const Color secondaryGold = Color(0xFFC29015);
  static const Color accentGold = Color(0xFFFFC64D);
  static const Color secondaryGoldDark = Color(0xFF7A5900);
  static const Color secondaryGoldLight = Color(0xFFFFDEA3);

  // Accent & Domain Specific Highlights
  static const Color accentNavy = Color(0xFF283044);
  static const Color accentTeal = Color(0xFF00537F);
  static const Color accentPurple = Color(0xFF6B21A8); // Faraiz
  static const Color accentCrimson = Color(0xFFBA1A1A); // Discrepancies/Alerts
  static const Color accentOrange = Color(0xFFC2410C); // Warning/Average method comparison

  // Stitch Porcelain Neutral Background & Tonal Surfaces
  static const Color backgroundLight = Color(0xFFFAF8FF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F3FF);
  static const Color surfaceContainer = Color(0xFFEAEDFF);
  static const Color surfaceContainerHigh = Color(0xFFE2E7FF);
  static const Color cardBorderLight = Color(0xFFD2D9F4);

  static const Color textPrimary = Color(0xFF131B2E);
  static const Color textSecondary = Color(0xFF404942);
  static const Color textMuted = Color(0xFF707971);

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
