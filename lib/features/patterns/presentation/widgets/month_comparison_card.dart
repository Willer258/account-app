import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/pattern_analysis_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Card showing month-over-month spending comparison.
///
/// Displays:
/// - Current month vs last month spending
/// - Percentage change with color indicator
/// - Encouraging message when spending is lower
/// - "Not enough data" state when < 2 months
///
/// Covers: FR21
class MonthComparisonCard extends ConsumerWidget {
  /// Creates a MonthComparisonCard.
  const MonthComparisonCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comparisonAsync = ref.watch(monthComparisonProvider);

    return comparisonAsync.when(
      data: (comparison) {
        if (!comparison.hasEnoughData) {
          return _NotEnoughDataState();
        }

        return _ComparisonContent(comparison: comparison);
      },
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Comparison content when enough data exists.
class _ComparisonContent extends StatelessWidget {
  const _ComparisonContent({required this.comparison});

  final MonthComparison comparison;

  @override
  Widget build(BuildContext context) {
    final changeColor = comparison.isImprovement
        ? AppColors.revolutGreen
        : comparison.isWorse
            ? AppColors.revolutRed
            : AppColors.revolutOnDarkMuted;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.revolutSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.revolutBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.compare_arrows,
                color: AppColors.revolutBlue,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Comparaison mensuelle',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Comparison row
          Row(
            children: [
              // Current month
              Expanded(
                child: _MonthColumn(
                  label: comparison.currentMonthName,
                  amount: comparison.currentMonthSpending,
                  isCurrent: true,
                ),
              ),

              // VS divider with change
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: changeColor.withOpacity( 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        comparison.changePercentFormatted,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: changeColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'vs',
                      style: TextStyle(
                        color: AppColors.revolutOnDarkMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Last month
              Expanded(
                child: _MonthColumn(
                  label: comparison.lastMonthName,
                  amount: comparison.lastMonthSpending,
                  isCurrent: false,
                ),
              ),
            ],
          ),

          // Encouraging message when improved
          if (comparison.isImprovement) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.revolutGreen.withOpacity( 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_rounded, size: 20, color: AppColors.revolutAmber),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Tu depenses moins ce mois!',
                      style: TextStyle(
                        color: AppColors.revolutGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Warning message when spending more
          if (comparison.isWorse &&
              comparison.changePercent > 0.2) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.revolutRed.withOpacity( 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: AppColors.revolutRed,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Attention aux depenses ce mois',
                      style: TextStyle(
                        color: AppColors.revolutRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Column showing month name and amount.
class _MonthColumn extends StatelessWidget {
  const _MonthColumn({
    required this.label,
    required this.amount,
    required this.isCurrent,
  });

  final String label;
  final int amount;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isCurrent ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.revolutOnDarkMuted,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatAmount(amount),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isCurrent ? AppColors.revolutOnDark : AppColors.revolutOnDarkMuted,
          ),
        ),
      ],
    );
  }

  String _formatAmount(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return '$amount';
  }
}

/// State shown when not enough data for comparison.
class _NotEnoughDataState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.revolutSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.revolutBorder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.hourglass_empty,
            color: AppColors.revolutOnDarkMuted,
            size: 32,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pas encore assez de donnees',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.revolutOnDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Continue a suivre tes depenses pour voir la comparaison mensuelle',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.revolutOnDarkMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
