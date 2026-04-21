import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Adaptive color extension for Pockii.
///
/// Provides the right colors based on current brightness (light/dark).
/// Use via `context.pockii` extension.
class PockiiThemeColors extends ThemeExtension<PockiiThemeColors> {
  const PockiiThemeColors({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.border,
  });

  /// Dark variant.
  static const dark = PockiiThemeColors(
    background: AppColors.revolutDark,
    surface: AppColors.revolutSurface,
    surfaceElevated: AppColors.revolutSurfaceElevated,
    onSurface: AppColors.revolutOnDark,
    onSurfaceMuted: AppColors.revolutOnDarkMuted,
    border: AppColors.revolutBorder,
  );

  /// Light variant.
  static const light = PockiiThemeColors(
    background: AppColors.revolutLight,
    surface: AppColors.revolutLightSurface,
    surfaceElevated: AppColors.revolutLightSurfaceElevated,
    onSurface: AppColors.revolutOnLight,
    onSurfaceMuted: AppColors.revolutOnLightMuted,
    border: AppColors.revolutLightBorder,
  );

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color onSurface;
  final Color onSurfaceMuted;
  final Color border;

  @override
  PockiiThemeColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? onSurface,
    Color? onSurfaceMuted,
    Color? border,
  }) {
    return PockiiThemeColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceMuted: onSurfaceMuted ?? this.onSurfaceMuted,
      border: border ?? this.border,
    );
  }

  @override
  PockiiThemeColors lerp(covariant ThemeExtension<PockiiThemeColors>? other, double t) {
    if (other is! PockiiThemeColors) return this;
    return PockiiThemeColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onSurfaceMuted: Color.lerp(onSurfaceMuted, other.onSurfaceMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}

/// Quick access to adaptive Pockii colors.
extension PockiiThemeContext on BuildContext {
  PockiiThemeColors get pockii =>
      Theme.of(this).extension<PockiiThemeColors>() ?? PockiiThemeColors.dark;
}
