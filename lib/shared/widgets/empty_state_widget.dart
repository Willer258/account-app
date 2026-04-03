import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A reusable widget for displaying empty states with supportive messaging.
///
/// Provides consistent empty state presentation across the app with:
/// - An illustrative icon
/// - A title and subtitle
/// - An optional call-to-action button
/// - Support for pointing animation toward FAB
///
/// Use the factory constructors for predefined variants:
/// - [EmptyStateWidget.home] for home screen
/// - [EmptyStateWidget.history] for history screen
/// - [EmptyStateWidget.patternsLocked] for patterns screen (locked state)
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.showFabPointer = false,
    super.key,
  });

  /// Creates an empty state for the home screen.
  ///
  /// Displays an encouraging message to start tracking expenses
  /// with a visual cue pointing toward the FAB button.
  factory EmptyStateWidget.home({VoidCallback? onAction}) {
    return EmptyStateWidget(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Commence à suivre tes dépenses',
      subtitle: 'Ajoute ta première dépense pour voir ton budget évoluer',
      actionLabel: onAction != null ? 'Ajouter une dépense' : null,
      onAction: onAction,
      showFabPointer: true,
    );
  }

  /// Creates an empty state for the history screen.
  ///
  /// Displays when no transactions exist for the current month.
  factory EmptyStateWidget.history({VoidCallback? onAction}) {
    return EmptyStateWidget(
      icon: Icons.receipt_long_outlined,
      title: 'Aucune transaction ce mois',
      subtitle: 'Tes transactions apparaîtront ici',
      actionLabel: 'Ajouter une dépense',
      onAction: onAction,
    );
  }

  /// Creates an empty state for the patterns screen (locked state).
  ///
  /// Displays when the patterns feature is not yet unlocked.
  /// Handles French singular/plural: "1 jour" vs "X jours".
  factory EmptyStateWidget.patternsLocked({required int daysRemaining}) {
    final dayWord = daysRemaining == 1 ? 'jour' : 'jours';
    return EmptyStateWidget(
      icon: Icons.lock_outline,
      title: 'Tes tendances arrivent bientôt',
      subtitle:
          'Encore $daysRemaining $dayWord de données pour débloquer cette fonctionnalité',
    );
  }

  /// Creates an empty state for when patterns are unlocked but no data exists.
  factory EmptyStateWidget.patternsNoData() {
    return const EmptyStateWidget(
      icon: Icons.insights_outlined,
      title: 'Pas encore de données',
      subtitle: 'Continue à noter tes dépenses pour voir tes tendances',
    );
  }

  /// The icon to display at the top.
  final IconData icon;

  /// The main title text (encouraging, supportive tone).
  final String title;

  /// The subtitle text providing additional context.
  final String subtitle;

  /// Optional label for the call-to-action button.
  final String? actionLabel;

  /// Optional callback when the action button is pressed.
  final VoidCallback? onAction;

  /// Whether to show a pointer animation toward the FAB.
  final bool showFabPointer;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title. $subtitle',
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            _EmptyStateIcon(icon: icon),
            const SizedBox(height: AppSpacing.lg),

            // Title
            Text(
              title,
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Subtitle
            Text(
              subtitle,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            // FAB Pointer
            if (showFabPointer) ...[
              const SizedBox(height: AppSpacing.lg),
              const _FabPointer(),
            ],

            // Action Button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.tonal(
                onPressed: onAction,
                // Ensure minimum touch target of 48x48dp per AC3
                style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Icon container for the empty state.
class _EmptyStateIcon extends StatelessWidget {
  const _EmptyStateIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 40, color: AppColors.onSurfaceVariant),
    );
  }
}

/// Animated pointer that guides the user toward the FAB button.
class _FabPointer extends StatefulWidget {
  const _FabPointer();

  @override
  State<_FabPointer> createState() => _FabPointerState();
}

class _FabPointerState extends State<_FabPointer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(
      begin: 0,
      end: 8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: child,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.arrow_downward_rounded,
            size: 28,
            color: AppColors.primary,
            semanticLabel: 'Appuie sur le bouton + en bas',
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Appuie sur +',
            style: AppTypography.label.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
