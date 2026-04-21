import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/fcfa_formatter.dart';

/// Displays a formatted FCFA amount with animation.
///
/// Shows the amount with space separators (e.g., "350 000") and
/// a "FCFA" suffix label. When the amount is 0, shows a placeholder.
/// Amount changes animate with a short fade transition.
/// Optionally shows a validation error message below the amount.
class AmountDisplay extends StatelessWidget {
  /// Creates an AmountDisplay.
  const AmountDisplay({
    required this.amountFcfa,
    this.showError = false,
    this.errorMessage,
    super.key,
  });

  /// The amount to display in FCFA (integer only).
  final int amountFcfa;

  /// Whether to show an error state.
  final bool showError;

  /// The error message to display when [showError] is true.
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final displayText = amountFcfa == 0
        ? '0'
        : FcfaFormatter.formatCompact(amountFcfa);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              // Amount with animation
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: Text(
                    displayText,
                    key: ValueKey<String>(displayText),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w600,
                      color: showError
                          ? AppColors.revolutRed
                          : (amountFcfa == 0
                              ? AppColors.revolutOnDarkMuted
                              : AppColors.revolutOnDark),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Currency suffix
              Text(
                'FCFA',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: showError ? AppColors.revolutRed : AppColors.revolutOnDarkMuted,
                ),
              ),
            ],
          ),
        ),
        // Error message
        if (showError && errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              errorMessage!,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.revolutRed,
              ),
            ),
          ),
      ],
    );
  }
}
