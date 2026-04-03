import 'package:flutter/services.dart';

/// Centralized haptic feedback service for Revolut-style interactions.
///
/// Provides semantic haptic patterns mapped to user actions,
/// making the app feel responsive and polished.
///
/// All methods are safe to call on any platform — they silently
/// no-op on platforms without haptic support.
///
/// Covers: US-009 — Haptic & Sound
abstract class HapticService {
  // ─────────────────────────────────────────────────────────────
  // Interaction Haptics
  // ─────────────────────────────────────────────────────────────

  /// Light tap — for key presses, chip selections, list item taps.
  static Future<void> tap() => HapticFeedback.selectionClick();

  /// Medium impact — for toggle switches, mode changes.
  static Future<void> toggle() => HapticFeedback.mediumImpact();

  /// Heavy impact — for destructive actions, error states.
  static Future<void> impact() => HapticFeedback.heavyImpact();

  /// Light vibration — for subtle confirmations.
  static Future<void> light() => HapticFeedback.lightImpact();

  // ─────────────────────────────────────────────────────────────
  // Semantic Haptics
  // ─────────────────────────────────────────────────────────────

  /// Success pattern — used after saving a transaction or completing a challenge.
  ///
  /// Sequence: medium → short delay → heavy
  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.heavyImpact();
  }

  /// Error pattern — used when validation fails or budget is exceeded.
  ///
  /// Sequence: heavy → short delay → heavy
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.heavyImpact();
  }

  /// Warning pattern — used when approaching budget limit.
  ///
  /// Sequence: medium → delay → medium → delay → medium
  static Future<void> warning() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
  }

  /// Celebration pattern — used for streak milestones and challenge completions.
  ///
  /// Long sequence to feel festive.
  static Future<void> celebrate() async {
    for (var i = 0; i < 3; i++) {
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 60));
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 100));
    }
    await HapticFeedback.heavyImpact();
  }

  /// Keypad press — very light, used for numeric keypad buttons.
  static Future<void> keyPress() => HapticFeedback.selectionClick();

  /// Delete press — slightly heavier than key press.
  static Future<void> deletePress() => HapticFeedback.lightImpact();

  /// Submit — used when submitting a form or confirming an action.
  static Future<void> submit() => HapticFeedback.mediumImpact();

  /// Navigation — used when switching tabs or navigating between screens.
  static Future<void> navigate() => HapticFeedback.selectionClick();

  /// Swipe action — used for swipe-to-delete or swipe gestures.
  static Future<void> swipe() => HapticFeedback.lightImpact();

  // ─────────────────────────────────────────────────────────────
  // Budget-specific Haptics
  // ─────────────────────────────────────────────────────────────

  /// Called when budget is in safe zone (>50% remaining).
  static Future<void> budgetSafe() => HapticFeedback.lightImpact();

  /// Called when budget enters warning zone (20-50% remaining).
  static Future<void> budgetWarning() => warning();

  /// Called when budget enters danger zone (<20% remaining).
  static Future<void> budgetDanger() => error();

  /// Called when a transaction is successfully saved.
  static Future<void> transactionSaved() => success();

  /// Called when a challenge is completed.
  static Future<void> challengeCompleted() => celebrate();

  /// Called when a streak milestone is reached.
  static Future<void> streakMilestone() => celebrate();
}
