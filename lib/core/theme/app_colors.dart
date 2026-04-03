import 'package:flutter/material.dart';

/// Application color palette — Revolut-inspired dark design system.
///
/// Retains all original Material 3 colors for backward compatibility,
/// and adds Revolut-style colors for the redesign.
abstract class AppColors {
  // ============================================
  // Primary Colors (original — kept for compat)
  // ============================================

  /// Primary color: Trust green
  static const Color primary = Color(0xFF2E7D32);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFB8F5B0);
  static const Color onPrimaryContainer = Color(0xFF002204);

  // ============================================
  // Secondary Colors (original — kept for compat)
  // ============================================

  static const Color secondary = Color(0xFF1565C0);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFD3E4FF);
  static const Color onSecondaryContainer = Color(0xFF001C3B);

  // ============================================
  // Surface Colors (original — kept for compat)
  // ============================================

  static const Color surface = Color(0xFFF5F5F5);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color background = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF1C1B1F);
  static const Color surfaceVariant = Color(0xFFE7E0EC);
  static const Color onSurfaceVariant = Color(0xFF49454F);

  // ============================================
  // Status Colors
  // ============================================

  static const Color success = Color(0xFF43A047);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFB3261E);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFF9DEDC);
  static const Color onErrorContainer = Color(0xFF410E0B);

  // ============================================
  // Outline & Dividers
  // ============================================

  static const Color outline = Color(0xFF79747E);
  static const Color outlineVariant = Color(0xFFCAC4D0);

  // ============================================
  // Inverse Colors
  // ============================================

  static const Color inverseSurface = Color(0xFF313033);
  static const Color onInverseSurface = Color(0xFFF4EFF4);
  static const Color inversePrimary = Color(0xFF7DDC7A);

  // ============================================
  // Scrim & Shadow
  // ============================================

  static const Color scrim = Color(0xFF000000);
  static const Color shadow = Color(0xFF000000);

  // ============================================
  // Revolut Design System — Dark Palette
  // ============================================

  /// Deep dark background (Revolut-style near-black)
  static const Color revolutDark = Color(0xFF0D0D0D);

  /// Card/surface background in dark mode
  static const Color revolutSurface = Color(0xFF151515);

  /// Slightly elevated surface (modals, sheets)
  static const Color revolutSurfaceElevated = Color(0xFF1E1E1E);

  /// Revolut brand blue (primary accent)
  static const Color revolutBlue = Color(0xFF0075EB);

  /// Revolut brand blue lighter variant
  static const Color revolutBlueLight = Color(0xFF4DA3FF);

  /// Revolut brand blue darker variant
  static const Color revolutBlueDark = Color(0xFF0055AA);

  /// Revolut success/positive green
  static const Color revolutGreen = Color(0xFF00C97B);

  /// Revolut danger/negative red
  static const Color revolutRed = Color(0xFFFF4466);

  /// Revolut warning amber
  static const Color revolutAmber = Color(0xFFFFAB00);

  /// Revolut purple accent (premium feel)
  static const Color revolutPurple = Color(0xFF9B59F5);

  /// Revolut white text on dark
  static const Color revolutOnDark = Color(0xFFFFFFFF);

  /// Revolut muted text on dark
  static const Color revolutOnDarkMuted = Color(0xFF8A8A9A);

  /// Revolut divider/border on dark
  static const Color revolutBorder = Color(0xFF2A2A2A);

  /// Glassmorphic overlay (white with low opacity)
  static const Color glassOverlay = Color(0x1AFFFFFF);

  /// Glassmorphic border
  static const Color glassBorder = Color(0x33FFFFFF);

  // ============================================
  // Revolut Gradient Stops
  // ============================================

  /// Hero gradient — dark blue to blue
  static const List<Color> revolutHeroGradient = [
    Color(0xFF0A1628),
    Color(0xFF0D2040),
    Color(0xFF0075EB),
  ];

  /// Positive balance gradient
  static const List<Color> positiveGradient = [
    Color(0xFF00C97B),
    Color(0xFF00A85F),
  ];

  /// Negative balance gradient
  static const List<Color> negativeGradient = [
    Color(0xFFFF4466),
    Color(0xFFCC2244),
  ];

  /// Card shimmer gradient
  static const List<Color> cardGradient = [
    Color(0xFF1E2D4A),
    Color(0xFF152038),
  ];
}
