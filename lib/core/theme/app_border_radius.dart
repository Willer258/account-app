import 'package:flutter/material.dart';

/// Application border radius constants for consistent rounded corners.
///
/// Consistent border radii create visual harmony and help users
/// understand component relationships:
/// - Cards and containers: 16dp (prominent, contained content)
/// - Buttons: 12dp (actionable elements)
/// - Chips and small elements: 8dp (compact, inline elements)
/// - Circular: Full round for FABs and avatars
///
/// Both raw values (double) and pre-built BorderRadius objects
/// are provided for convenience.
abstract class AppBorderRadius {
  // ============================================
  // Raw Values (double)
  // ============================================

  /// Border radius for cards and containers (16dp).
  /// Use for: Cards, dialogs, modal sheets
  static const double card = 16.0;

  /// Border radius for buttons (12dp).
  /// Use for: ElevatedButton, OutlinedButton, TextButton
  static const double button = 12.0;

  /// Border radius for chips and small elements (8dp).
  /// Use for: Chips, badges, snackbars, input fields
  static const double chip = 8.0;

  /// Border radius for very small elements (4dp).
  /// Use for: Tooltips, small indicators
  static const double small = 4.0;

  /// Full circular radius (100dp).
  /// Use for: FABs, avatars, circular buttons
  static const double circular = 100.0;

  // ============================================
  // Pre-built BorderRadius Objects
  // ============================================

  /// BorderRadius for cards and containers.
  static final BorderRadius cardRadius = BorderRadius.circular(card);

  /// BorderRadius for buttons.
  static final BorderRadius buttonRadius = BorderRadius.circular(button);

  /// BorderRadius for chips and small elements.
  static final BorderRadius chipRadius = BorderRadius.circular(chip);

  /// BorderRadius for very small elements.
  static final BorderRadius smallRadius = BorderRadius.circular(small);

  /// BorderRadius for circular elements (FABs, avatars).
  static final BorderRadius circularRadius = BorderRadius.circular(circular);

  /// BorderRadius for bottom sheets (rounded top corners only).
  static final BorderRadius bottomSheetRadius = BorderRadius.only(
    topLeft: Radius.circular(card),
    topRight: Radius.circular(card),
  );

  /// BorderRadius for modal dialogs (slightly more rounded).
  static final BorderRadius dialogRadius = BorderRadius.circular(28.0);

  /// BorderRadius for top navigation elements.
  static final BorderRadius topNavRadius = BorderRadius.only(
    bottomLeft: Radius.circular(card),
    bottomRight: Radius.circular(card),
  );

  // ============================================
  // Helper Methods
  // ============================================

  /// Creates a BorderRadius with the same radius on all corners.
  static BorderRadius all(double radius) => BorderRadius.circular(radius);

  /// Creates a BorderRadius with only top corners rounded.
  static BorderRadius top(double radius) => BorderRadius.only(
    topLeft: Radius.circular(radius),
    topRight: Radius.circular(radius),
  );

  /// Creates a BorderRadius with only bottom corners rounded.
  static BorderRadius bottom(double radius) => BorderRadius.only(
    bottomLeft: Radius.circular(radius),
    bottomRight: Radius.circular(radius),
  );

  /// Creates a BorderRadius with only left corners rounded.
  static BorderRadius left(double radius) => BorderRadius.only(
    topLeft: Radius.circular(radius),
    bottomLeft: Radius.circular(radius),
  );

  /// Creates a BorderRadius with only right corners rounded.
  static BorderRadius right(double radius) => BorderRadius.only(
    topRight: Radius.circular(radius),
    bottomRight: Radius.circular(radius),
  );
}
