import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// A single onboarding intro page with icon, title, and description.
///
/// Used for screens 1 and 2 of the onboarding flow.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    super.key,
  });

  /// Icon to display at the top
  final IconData icon;

  /// Title text
  final String title;

  /// Description text
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 60, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Title
          Text(
            title,
            style: AppTypography.headline.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),

          // Description
          Text(
            description,
            style: AppTypography.body.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
