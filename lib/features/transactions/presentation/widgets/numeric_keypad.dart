import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// A custom numeric keypad for entering FCFA amounts.
///
/// Provides a 4x3 grid layout with digits 1-9, 0, and backspace.
/// Each key has a minimum 48dp touch target for accessibility.
/// Haptic feedback is provided on each key press.
class NumericKeypad extends StatelessWidget {
  /// Creates a NumericKeypad.
  const NumericKeypad({
    required this.onDigitPressed,
    required this.onBackspacePressed,
    super.key,
  });

  /// Callback when a digit (0-9) is pressed.
  final ValueChanged<String> onDigitPressed;

  /// Callback when the backspace key is pressed.
  final VoidCallback onBackspacePressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row 1: 1, 2, 3
        _buildRow(['1', '2', '3']),
        const SizedBox(height: AppSpacing.sm),
        // Row 2: 4, 5, 6
        _buildRow(['4', '5', '6']),
        const SizedBox(height: AppSpacing.sm),
        // Row 3: 7, 8, 9
        _buildRow(['7', '8', '9']),
        const SizedBox(height: AppSpacing.sm),
        // Row 4: empty, 0, backspace
        _buildBottomRow(),
      ],
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map(_buildDigitKey).toList(),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Empty space for symmetry
        const SizedBox(
          width: _keySize,
          height: _keySize,
        ),
        // Zero key
        _buildDigitKey('0'),
        // Backspace key
        _buildBackspaceKey(),
      ],
    );
  }

  Widget _buildDigitKey(String digit) {
    return _KeypadButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        onDigitPressed(digit);
      },
      child: Text(
        digit,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w500,
          color: AppColors.revolutOnDark,
        ),
      ),
    );
  }

  Widget _buildBackspaceKey() {
    return _KeypadButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        onBackspacePressed();
      },
      child: const Icon(
        Icons.backspace_outlined,
        size: 24,
        color: AppColors.revolutOnDarkMuted,
        semanticLabel: 'Effacer',
      ),
    );
  }

  static const double _keySize = 72;
}

/// Internal button widget for keypad keys.
///
/// Provides consistent styling and minimum touch target.
class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    required this.onPressed,
    required this.child,
  });

  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: NumericKeypad._keySize,
      height: NumericKeypad._keySize,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(36),
          child: Semantics(
            button: true,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
