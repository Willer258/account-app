import 'package:flutter/material.dart';

/// Application typography using Inter font family.
///
/// Typography scale follows Material Design 3 with custom sizes
/// optimized for budget tracking use cases:
/// - Hero (56sp): Budget number display - the most important element
/// - Headline (32sp): Screen titles
/// - Title (24sp): Section headers
/// - Body (16sp): Default text
/// - Label (14sp): Buttons, chips
/// - Caption (12sp): Secondary information
///
/// All text styles use const constructors for performance.
abstract class AppTypography {
  // ============================================
  // Font Configuration
  // ============================================

  /// Primary font family for the application.
  /// Inter is chosen for excellent readability at all sizes.
  static const String fontFamily = 'Inter';

  // ============================================
  // Size Constants (in logical pixels)
  // ============================================

  /// Hero size for budget number (56sp)
  static const double heroSize = 56.0;

  /// Headline size for screen titles (32sp)
  static const double headlineSize = 32.0;

  /// Title size for section headers (24sp)
  static const double titleSize = 24.0;

  /// Title small variant (20sp)
  static const double titleSmallSize = 20.0;

  /// Body large for emphasized text (18sp)
  static const double bodyLargeSize = 18.0;

  /// Body default size (16sp)
  static const double bodySize = 16.0;

  /// Label size for buttons, chips (14sp)
  static const double labelSize = 14.0;

  /// Caption size for secondary text (12sp)
  static const double captionSize = 12.0;

  // ============================================
  // Text Styles
  // ============================================

  /// Hero text style for budget number display.
  ///
  /// 56sp, Bold (700), tight line height.
  /// Used exclusively for the main budget number on home screen.
  static const TextStyle hero = TextStyle(
    fontFamily: fontFamily,
    fontSize: heroSize,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -0.5,
  );

  /// Headline style for screen titles.
  ///
  /// 32sp, SemiBold (600).
  /// Used for main screen titles in app bar or page headers.
  static const TextStyle headline = TextStyle(
    fontFamily: fontFamily,
    fontSize: headlineSize,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.25,
  );

  /// Title style for section headers.
  ///
  /// 24sp, SemiBold (600).
  /// Used for card titles, dialog titles, section headers.
  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    fontSize: titleSize,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0,
  );

  /// Title small variant for subsections.
  ///
  /// 20sp, SemiBold (600).
  /// Used for subsection headers, list group titles.
  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: titleSmallSize,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0,
  );

  /// Body large for emphasized text.
  ///
  /// 18sp, Regular (400).
  /// Used for important body text that needs emphasis.
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: bodyLargeSize,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.15,
  );

  /// Default body text style.
  ///
  /// 16sp, Regular (400).
  /// Used for most body text, descriptions, notes.
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: bodySize,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.15,
  );

  /// Body medium variant with medium weight.
  ///
  /// 16sp, Medium (500).
  /// Used for slightly emphasized body text.
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: bodySize,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.15,
  );

  /// Label style for buttons and chips.
  ///
  /// 14sp, Medium (500).
  /// Used for button text, chip labels, tabs.
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: labelSize,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );

  /// Label large variant for prominent buttons.
  ///
  /// 14sp, SemiBold (600).
  /// Used for primary action buttons.
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: labelSize,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.1,
  );

  /// Caption style for secondary text.
  ///
  /// 12sp, Regular (400).
  /// Used for timestamps, hints, secondary information.
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: captionSize,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.4,
  );

  /// Caption medium variant.
  ///
  /// 12sp, Medium (500).
  /// Used for slightly emphasized captions.
  static const TextStyle captionMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: captionSize,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.4,
  );

  // ============================================
  // Revolut-style text styles
  // ============================================

  /// Revolut display — massive hero number (72sp, ultra-bold)
  static const TextStyle revolutDisplay = TextStyle(
    fontFamily: fontFamily,
    fontSize: 72.0,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: -2.0,
  );

  /// Revolut title — screen-level heading (28sp, bold)
  static const TextStyle revolutTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28.0,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  /// Revolut subtitle — section/card heading (20sp, semibold)
  static const TextStyle revolutSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.25,
  );

  /// Revolut body — standard readable text (15sp, regular)
  static const TextStyle revolutBody = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15.0,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.0,
  );

  /// Revolut label — button/chip text (14sp, semibold)
  static const TextStyle revolutLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.1,
  );

  /// Revolut micro — timestamps and hints (11sp, medium)
  static const TextStyle revolutMicro = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11.0,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.3,
  );

  // ============================================
  // Helper Methods
  // ============================================

  /// Returns a TextStyle with the specified color applied.
  ///
  /// Useful for applying theme colors to text styles.
  /// ```dart
  /// Text('Hello', style: AppTypography.withColor(AppTypography.body, Colors.red))
  /// ```
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }
}
