import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_typography.dart';
import 'app_spacing.dart';
import 'app_border_radius.dart';
import 'pockii_colors.dart';

/// Application theme configuration using Material Design 3.
///
/// Provides both light and dark themes with explicit ColorScheme
/// (NOT using ColorScheme.fromSeed for predictable colors).
///
/// Usage:
/// ```dart
/// MaterialApp(
///   theme: AppTheme.light(),
///   darkTheme: AppTheme.dark(), // Post-MVP
/// )
/// ```
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  /// Revolut-inspired dark theme (new design system).
  static ThemeData revolut() => _buildRevolutTheme();

  /// Revolut-inspired light theme.
  static ThemeData revolutLight() => _buildRevolutLightTheme();

  /// Light theme for the application (MVP default).
  ///
  /// Uses explicit colors from [AppColors] for consistent,
  /// predictable appearance across all devices.
  static ThemeData light() => _buildTheme(Brightness.light);

  /// Dark theme for the application (prepared for post-MVP).
  ///
  /// Structure is in place but not fully implemented.
  /// Colors will need adjustment for dark mode accessibility.
  static ThemeData dark() => _buildTheme(Brightness.dark);

  /// Internal theme builder.
  ///
  /// Creates a complete ThemeData with all component themes configured
  /// for consistent appearance throughout the app.
  static ThemeData _buildTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    // Build explicit ColorScheme (NOT fromSeed)
    final ColorScheme colorScheme = ColorScheme(
      brightness: brightness,
      // Primary
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      // Secondary
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      // Error
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      // Surface (adjusted for dark mode)
      surface: isDark ? const Color(0xFF1C1B1F) : AppColors.surface,
      onSurface: isDark ? const Color(0xFFE6E1E5) : AppColors.onSurface,
      surfaceContainerHighest: isDark
          ? const Color(0xFF49454F)
          : AppColors.surfaceVariant,
      onSurfaceVariant: isDark
          ? const Color(0xFFCAC4D0)
          : AppColors.onSurfaceVariant,
      // Outline
      outline: isDark ? const Color(0xFF938F99) : AppColors.outline,
      outlineVariant: isDark
          ? const Color(0xFF49454F)
          : AppColors.outlineVariant,
      // Inverse
      inverseSurface: isDark ? AppColors.surface : AppColors.inverseSurface,
      onInverseSurface: isDark
          ? AppColors.onSurface
          : AppColors.onInverseSurface,
      inversePrimary: AppColors.inversePrimary,
      // Scrim & Shadow
      scrim: AppColors.scrim,
      shadow: AppColors.shadow,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: AppTypography.fontFamily,

      // ============================================
      // Scaffold
      // ============================================
      scaffoldBackgroundColor: isDark
          ? colorScheme.surface
          : AppColors.background,

      // ============================================
      // App Bar
      // ============================================
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTypography.title.copyWith(
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: AppSpacing.iconSize,
        ),
      ),

      // ============================================
      // Card
      // ============================================
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: colorScheme.shadow.withOpacity(0.15),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.cardRadius),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // ============================================
      // Elevated Button
      // ============================================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          shadowColor: colorScheme.shadow.withOpacity(0.15),
          minimumSize: Size(double.infinity, AppSpacing.touchTarget),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.buttonRadius,
          ),
          textStyle: AppTypography.label,
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
        ),
      ),

      // ============================================
      // Text Button
      // ============================================
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: Size(AppSpacing.touchTarget, AppSpacing.touchTarget),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.buttonRadius,
          ),
          textStyle: AppTypography.label,
          foregroundColor: colorScheme.primary,
        ),
      ),

      // ============================================
      // Outlined Button
      // ============================================
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(double.infinity, AppSpacing.touchTarget),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.buttonRadius,
          ),
          side: BorderSide(color: colorScheme.outline),
          textStyle: AppTypography.label,
          foregroundColor: colorScheme.primary,
        ),
      ),

      // ============================================
      // Floating Action Button
      // ============================================
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        highlightElevation: 8,
        // Use stadium shape to support both regular and extended FABs
        shape: const StadiumBorder(),
        // Remove fixed size constraints to allow extended FAB to size properly
        // Regular FABs will use their default size
      ),

      // ============================================
      // Bottom Navigation Bar
      // ============================================
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: colorScheme.surface,
        elevation: 8,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
        selectedLabelStyle: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: AppTypography.caption,
        showUnselectedLabels: true,
      ),

      // ============================================
      // Navigation Bar (Material 3)
      // ============================================
      navigationBarTheme: NavigationBarThemeData(
        height: AppSpacing.bottomNavHeight,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.caption.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            );
          }
          return AppTypography.caption.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: colorScheme.onPrimaryContainer,
              size: AppSpacing.iconSize,
            );
          }
          return IconThemeData(
            color: colorScheme.onSurface.withOpacity(0.6),
            size: AppSpacing.iconSize,
          );
        }),
      ),

      // ============================================
      // Chip
      // ============================================
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface,
        selectedColor: colorScheme.primaryContainer,
        disabledColor: colorScheme.surface.withOpacity(0.38),
        labelStyle: AppTypography.label,
        secondaryLabelStyle: AppTypography.label,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.chipRadius,
          side: BorderSide(color: colorScheme.outline),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),

      // ============================================
      // Snackbar
      // ============================================
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: AppTypography.body.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.chipRadius),
        elevation: 6,
        actionTextColor: colorScheme.inversePrimary,
      ),

      // ============================================
      // Bottom Sheet
      // ============================================
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.bottomSheetRadius,
        ),
        elevation: 8,
        modalElevation: 16,
        showDragHandle: true,
        dragHandleColor: colorScheme.onSurface.withOpacity(0.4),
        dragHandleSize: const Size(32, 4),
      ),

      // ============================================
      // Dialog
      // ============================================
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.dialogRadius,
        ),
        titleTextStyle: AppTypography.title.copyWith(
          color: colorScheme.onSurface,
        ),
        contentTextStyle: AppTypography.body.copyWith(
          color: colorScheme.onSurface,
        ),
      ),

      // ============================================
      // Input Decoration
      // ============================================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: AppBorderRadius.chipRadius,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.chipRadius,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.chipRadius,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.chipRadius,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.chipRadius,
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        labelStyle: AppTypography.body.copyWith(
          color: colorScheme.onSurface.withOpacity(0.6),
        ),
        hintStyle: AppTypography.body.copyWith(
          color: colorScheme.onSurface.withOpacity(0.4),
        ),
        errorStyle: AppTypography.caption.copyWith(color: colorScheme.error),
      ),

      // ============================================
      // Divider
      // ============================================
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // ============================================
      // Icon
      // ============================================
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: AppSpacing.iconSize,
      ),

      // ============================================
      // List Tile
      // ============================================
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        minVerticalPadding: AppSpacing.sm,
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.chipRadius),
        titleTextStyle: AppTypography.body.copyWith(
          color: colorScheme.onSurface,
        ),
        subtitleTextStyle: AppTypography.caption.copyWith(
          color: colorScheme.onSurface.withOpacity(0.6),
        ),
        leadingAndTrailingTextStyle: AppTypography.label.copyWith(
          color: colorScheme.onSurface,
        ),
        iconColor: colorScheme.onSurface.withOpacity(0.6),
      ),

      // ============================================
      // Progress Indicator
      // ============================================
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primary.withOpacity(0.2),
        circularTrackColor: colorScheme.primary.withOpacity(0.2),
      ),
    );
  }

  // ============================================
  // Revolut Dark Theme
  // ============================================

  static ThemeData _buildRevolutTheme() {
    const ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.revolutBlue,
      onPrimary: AppColors.revolutOnDark,
      primaryContainer: AppColors.revolutBlueDark,
      onPrimaryContainer: AppColors.revolutOnDark,
      secondary: AppColors.revolutGreen,
      onSecondary: AppColors.revolutOnDark,
      secondaryContainer: Color(0xFF003D26),
      onSecondaryContainer: AppColors.revolutGreen,
      error: AppColors.revolutRed,
      onError: AppColors.revolutOnDark,
      errorContainer: Color(0xFF4A0015),
      onErrorContainer: AppColors.revolutRed,
      surface: AppColors.revolutSurface,
      onSurface: AppColors.revolutOnDark,
      surfaceContainerHighest: AppColors.revolutSurfaceElevated,
      onSurfaceVariant: AppColors.revolutOnDarkMuted,
      outline: AppColors.revolutBorder,
      outlineVariant: AppColors.revolutBorder,
      inverseSurface: AppColors.revolutOnDark,
      onInverseSurface: AppColors.revolutDark,
      inversePrimary: AppColors.revolutBlueLight,
      scrim: AppColors.scrim,
      shadow: AppColors.scrim,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      extensions: const [PockiiThemeColors.dark],
      fontFamily: AppTypography.bodyFont,
      textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme),
      scaffoldBackgroundColor: AppColors.revolutDark,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.revolutDark,
        foregroundColor: AppColors.revolutOnDark,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTypography.revolutTitle.copyWith(
          color: AppColors.revolutOnDark,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.revolutOnDark,
          size: 24,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.revolutSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.revolutBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTypography.revolutLabel,
          foregroundColor: AppColors.revolutOnDark,
          backgroundColor: AppColors.revolutBlue,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.revolutBlue,
        foregroundColor: AppColors.revolutOnDark,
        elevation: 0,
        highlightElevation: 0,
        shape: StadiumBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: AppColors.revolutSurface,
        elevation: 0,
        indicatorColor: AppColors.revolutBlue.withOpacity(0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.revolutMicro.copyWith(
              color: AppColors.revolutBlue,
            );
          }
          return AppTypography.revolutMicro.copyWith(
            color: AppColors.revolutOnDarkMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.revolutBlue, size: 24);
          }
          return const IconThemeData(
            color: AppColors.revolutOnDarkMuted,
            size: 24,
          );
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.revolutSurfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: AppColors.revolutBorder,
        dragHandleSize: const Size(36, 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.revolutSurfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.revolutBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.revolutBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.revolutBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: AppTypography.revolutBody.copyWith(
          color: AppColors.revolutOnDarkMuted,
        ),
        hintStyle: AppTypography.revolutBody.copyWith(
          color: AppColors.revolutOnDarkMuted,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.revolutBorder,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.revolutBlue,
        linearTrackColor: Color(0xFF1A3A5C),
        circularTrackColor: Color(0xFF1A3A5C),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.revolutSurfaceElevated,
        contentTextStyle: AppTypography.revolutBody.copyWith(
          color: AppColors.revolutOnDark,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        actionTextColor: AppColors.revolutBlue,
      ),
    );
  }

  // ============================================
  // Revolut Light Theme
  // ============================================

  static ThemeData _buildRevolutLightTheme() {
    const ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.revolutBlue,
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFD6E8FF),
      onPrimaryContainer: AppColors.revolutBlueDark,
      secondary: AppColors.revolutGreen,
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFB8F5D8),
      onSecondaryContainer: Color(0xFF003D26),
      error: AppColors.revolutRed,
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: AppColors.revolutRed,
      surface: AppColors.revolutLightSurface,
      onSurface: AppColors.revolutOnLight,
      surfaceContainerHighest: AppColors.revolutLightSurfaceElevated,
      onSurfaceVariant: AppColors.revolutOnLightMuted,
      outline: AppColors.revolutLightBorder,
      outlineVariant: AppColors.revolutLightBorder,
      inverseSurface: AppColors.revolutOnLight,
      onInverseSurface: AppColors.revolutLightSurface,
      inversePrimary: AppColors.revolutBlueLight,
      scrim: AppColors.scrim,
      shadow: AppColors.scrim,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      extensions: const [PockiiThemeColors.light],
      fontFamily: AppTypography.bodyFont,
      textTheme: GoogleFonts.dmSansTextTheme(ThemeData.light().textTheme),
      scaffoldBackgroundColor: AppColors.revolutLight,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.revolutLight,
        foregroundColor: AppColors.revolutOnLight,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTypography.revolutTitle.copyWith(
          color: AppColors.revolutOnLight,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.revolutOnLight,
          size: 24,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.revolutLightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.revolutLightBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTypography.revolutLabel,
          foregroundColor: Colors.white,
          backgroundColor: AppColors.revolutBlue,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.revolutBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        highlightElevation: 4,
        shape: StadiumBorder(),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.revolutLightSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        elevation: 4,
        modalElevation: 8,
        showDragHandle: true,
        dragHandleColor: AppColors.revolutLightBorder,
        dragHandleSize: const Size(36, 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.revolutLightSurfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.revolutLightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.revolutLightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.revolutBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: AppTypography.revolutBody.copyWith(
          color: AppColors.revolutOnLightMuted,
        ),
        hintStyle: AppTypography.revolutBody.copyWith(
          color: AppColors.revolutOnLightMuted,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.revolutLightBorder,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.revolutBlue,
        linearTrackColor: AppColors.revolutBlue.withValues(alpha: 0.15),
        circularTrackColor: AppColors.revolutBlue.withValues(alpha: 0.15),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.revolutOnLight,
        contentTextStyle: AppTypography.revolutBody.copyWith(
          color: AppColors.revolutLightSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        actionTextColor: AppColors.revolutBlueLight,
      ),
    );
  }
}
