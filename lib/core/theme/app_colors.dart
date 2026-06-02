import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Obsidian Kinetic - Base surfaces
  static const Color background        = Color(0xFF121413);
  static const Color surface           = Color(0xFF121413);
  static const Color surfaceContainerLowest = Color(0xFF0D0E0E);
  static const Color surfaceContainerLow   = Color(0xFF1B1C1C);
  static const Color surfaceContainer      = Color(0xFF1F2020);
  static const Color surfaceContainerHigh  = Color(0xFF292A2A);
  static const Color surfaceContainerHighest = Color(0xFF343535);
  static const Color surfaceBright     = Color(0xFF393939);

  // Primary — lime green accent
  static const Color primary           = Color(0xFF7EFC00);
  static const Color primaryDim        = Color(0xFF6FE000);
  static const Color primaryText       = Color(0xFFF7FFEA);
  static const Color onPrimary         = Color(0xFF173800);
  static const Color primaryContainer  = Color(0xFF7EFC00);
  static const Color onPrimaryContainer = Color(0xFF357000);

  // On surfaces
  static const Color onSurface        = Color(0xFFE4E2E1);
  static const Color onSurfaceVariant = Color(0xFFBDCBAE);
  static const Color onBackground     = Color(0xFFE4E2E1);

  // Secondary
  static const Color secondary          = Color(0xFFC6C6C6);
  static const Color secondaryContainer = Color(0xFF454747);
  static const Color onSecondary        = Color(0xFF2F3131);

  // Borders
  static const Color outline        = Color(0xFF88957B);
  static const Color outlineVariant = Color(0xFF3F4A34);

  // Error
  static const Color error          = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);

  // Semantic
  static const Color success = Color(0xFF7EFC00);
  static const Color warning = Color(0xFFFFD700);

  // Glow effect (low opacity primary for inner glow)
  static Color primaryGlow = primary.withOpacity(0.15);
  static Color primaryGlowStrong = primary.withOpacity(0.30);
}
