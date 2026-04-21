import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Application typography — dual font system.
///
/// **Space Grotesk** — Headlines, numbers, amounts (geometric, fintech feel)
/// **DM Sans** — Body text, labels, captions (clean, readable)
///
/// Typography scale optimized for budget tracking:
/// - Hero (56sp): Budget number display
/// - Headline (32sp): Screen titles
/// - Title (24sp): Section headers
/// - Body (16sp): Default text
/// - Label (14sp): Buttons, chips
/// - Caption (12sp): Secondary information
abstract class AppTypography {
  // ============================================
  // Font Configuration
  // ============================================

  /// Display font — Space Grotesk (geometric, great numerals)
  static String get displayFont => GoogleFonts.spaceGrotesk().fontFamily!;

  /// Body font — DM Sans (clean, readable)
  static String get bodyFont => GoogleFonts.dmSans().fontFamily!;

  /// Legacy fontFamily for backward compatibility
  static String get fontFamily => bodyFont;

  // ============================================
  // Size Constants (in logical pixels)
  // ============================================

  static const double heroSize = 56.0;
  static const double headlineSize = 32.0;
  static const double titleSize = 24.0;
  static const double titleSmallSize = 20.0;
  static const double bodyLargeSize = 18.0;
  static const double bodySize = 16.0;
  static const double labelSize = 14.0;
  static const double captionSize = 12.0;

  // ============================================
  // Display Font Styles (Space Grotesk)
  // ============================================

  /// Hero text style for budget number display.
  static TextStyle get hero => GoogleFonts.spaceGrotesk(
    fontSize: heroSize,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -0.5,
  );

  /// Headline style for screen titles.
  static TextStyle get headline => GoogleFonts.spaceGrotesk(
    fontSize: headlineSize,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.25,
  );

  /// Title style for section headers.
  static TextStyle get title => GoogleFonts.spaceGrotesk(
    fontSize: titleSize,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0,
  );

  /// Title small variant for subsections.
  static TextStyle get titleSmall => GoogleFonts.spaceGrotesk(
    fontSize: titleSmallSize,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0,
  );

  // ============================================
  // Body Font Styles (DM Sans)
  // ============================================

  /// Body large for emphasized text.
  static TextStyle get bodyLarge => GoogleFonts.dmSans(
    fontSize: bodyLargeSize,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.15,
  );

  /// Default body text style.
  static TextStyle get body => GoogleFonts.dmSans(
    fontSize: bodySize,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.15,
  );

  /// Body medium variant with medium weight.
  static TextStyle get bodyMedium => GoogleFonts.dmSans(
    fontSize: bodySize,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.15,
  );

  /// Label style for buttons and chips.
  static TextStyle get label => GoogleFonts.dmSans(
    fontSize: labelSize,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );

  /// Label large variant for prominent buttons.
  static TextStyle get labelLarge => GoogleFonts.dmSans(
    fontSize: labelSize,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.1,
  );

  /// Caption style for secondary text.
  static TextStyle get caption => GoogleFonts.dmSans(
    fontSize: captionSize,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.4,
  );

  /// Caption medium variant.
  static TextStyle get captionMedium => GoogleFonts.dmSans(
    fontSize: captionSize,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.4,
  );

  // ============================================
  // Revolut-style text styles (Space Grotesk)
  // ============================================

  /// Revolut display — massive hero number (72sp, ultra-bold)
  static TextStyle get revolutDisplay => GoogleFonts.spaceGrotesk(
    fontSize: 72.0,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: -2.0,
  );

  /// Revolut title — screen-level heading (28sp, bold)
  static TextStyle get revolutTitle => GoogleFonts.spaceGrotesk(
    fontSize: 28.0,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  /// Revolut subtitle — section/card heading (20sp, semibold)
  static TextStyle get revolutSubtitle => GoogleFonts.spaceGrotesk(
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.25,
  );

  /// Revolut body — standard readable text (15sp, regular)
  static TextStyle get revolutBody => GoogleFonts.dmSans(
    fontSize: 15.0,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.0,
  );

  /// Revolut label — button/chip text (14sp, semibold)
  static TextStyle get revolutLabel => GoogleFonts.dmSans(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.1,
  );

  /// Revolut micro — timestamps and hints (11sp, medium)
  static TextStyle get revolutMicro => GoogleFonts.dmSans(
    fontSize: 11.0,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.3,
  );

  // ============================================
  // Mono style for numbers in data displays
  // ============================================

  /// Mono number style for tabular data
  static TextStyle get mono => GoogleFonts.spaceGrotesk(
    fontSize: bodySize,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  // ============================================
  // Helper Methods
  // ============================================

  /// Returns a TextStyle with the specified color applied.
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }
}
