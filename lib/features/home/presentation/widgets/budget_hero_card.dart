import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_border_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/budget_colors.dart';
import '../../../../shared/utils/fcfa_formatter.dart';
import '../../domain/models/budget_state.dart';
import '../providers/budget_provider.dart';
import 'budget_animation/budget_animation_widget.dart';

/// The hero card displaying the user's remaining budget.
///
/// This is the central visual element of the app, showing:
/// - The remaining budget amount in large 56sp font
/// - Color-coded status (green/orange/red)
/// - Current month label
/// - Progress bar showing remaining/total
///
/// Covers: FR1, FR3, FR4, UX-1, UX-11
class BudgetHeroCard extends ConsumerWidget {
  const BudgetHeroCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetState = ref.watch(budgetStateProvider);
    final monthLabel = ref.watch(currentMonthLabelProvider);

    if (budgetState.isLoading) {
      return const _LoadingCard();
    }

    if (budgetState.hasError) {
      return _ErrorCard(error: budgetState.error ?? 'Erreur inconnue');
    }

    return _BudgetCard(
      budgetState: budgetState,
      monthLabel: monthLabel,
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.budgetState,
    required this.monthLabel,
  });

  final BudgetState budgetState;
  final String monthLabel;

  @override
  Widget build(BuildContext context) {
    final statusColor = BudgetColors.forPercentage(
      budgetState.percentageRemaining,
    );

    // Show current balance (before planned expenses)
    final formattedAmount = FcfaFormatter.formatCompact(
      budgetState.remainingBeforePlanned,
    );
    final progressValue = budgetState.percentageRemaining.clamp(0.0, 1.0);
    final theme = Theme.of(context);

    return Semantics(
      label: _buildAccessibilityLabel(),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Compact header with month
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      monthLabel,
                      style: AppTypography.caption.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Animation + Amount in a row for compact display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated budget visualization (smaller)
                  BudgetAnimationWidget(
                    percentage: progressValue,
                    size: 100,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  // Amount column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Hero number
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: AppTypography.hero.copyWith(
                          color: statusColor,
                          fontSize: 36,
                        ),
                        child: Text(formattedAmount),
                      ),
                      // Currency
                      Text(
                        FcfaFormatter.symbol,
                        style: AppTypography.body.copyWith(
                          color: statusColor.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      // Projected if applicable
                      if (budgetState.hasPlannedExpenses) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.trending_down,
                              size: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${FcfaFormatter.formatCompact(budgetState.remainingBudget)} prévu',
                              style: AppTypography.caption.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Compact progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // Minimal budget summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '-${FcfaFormatter.formatCompact(budgetState.totalBudget - budgetState.remainingBeforePlanned)}',
                    style: AppTypography.caption.copyWith(
                      color: theme.colorScheme.error.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '/ ${FcfaFormatter.formatCompact(budgetState.totalBudget)}',
                    style: AppTypography.caption.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildAccessibilityLabel() {
    final status = BudgetColors.accessibilityLabel(
      budgetState.percentageRemaining,
    );
    final amount = FcfaFormatter.formatCompact(budgetState.remainingBeforePlanned);
    final projected = budgetState.hasPlannedExpenses
        ? ' Après engagements: ${FcfaFormatter.formatCompact(budgetState.remainingBudget)} francs CFA.'
        : '';

    return '$status. Reste à vivre: $amount francs CFA.$projected '
        '$monthLabel.';
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
      ),
      child: const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: AppSpacing.xl),
            CircularProgressIndicator(),
            SizedBox(height: AppSpacing.md),
            Text('Chargement...'),
            SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Erreur de chargement',
              style: AppTypography.title.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              style: AppTypography.caption.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
