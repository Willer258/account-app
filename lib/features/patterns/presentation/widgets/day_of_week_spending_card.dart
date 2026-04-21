import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/pattern_analysis_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Card showing day-of-week spending distribution.
///
/// Displays:
/// - Bar chart with spending by day (Mon-Sun)
/// - Highest day highlighted
/// - Insight message about spending patterns
/// - Tap interaction for day details
///
/// Covers: FR23, Story 5.6
class DayOfWeekSpendingCard extends ConsumerWidget {
  /// Creates a DayOfWeekSpendingCard.
  const DayOfWeekSpendingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distributionAsync = ref.watch(dayOfWeekDistributionProvider);

    return distributionAsync.when(
      data: (distribution) {
        if (!distribution.hasData) {
          return _NoDataState();
        }

        return _DistributionContent(distribution: distribution);
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Distribution content when data exists.
class _DistributionContent extends StatefulWidget {
  const _DistributionContent({required this.distribution});

  final DayOfWeekDistribution distribution;

  @override
  State<_DistributionContent> createState() => _DistributionContentState();
}

class _DistributionContentState extends State<_DistributionContent> {
  int? _selectedDayIndex;

  @override
  Widget build(BuildContext context) {
    final maxAmount = widget.distribution.days
        .map((d) => d.totalAmount)
        .reduce((a, b) => a > b ? a : b);

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
                Icons.calendar_view_week,
                color: AppColors.revolutBlue,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Depenses par jour',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Insight message
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: widget.distribution.isEvenlyDistributed
                  ? AppColors.revolutGreen.withOpacity( 0.1)
                  : AppColors.revolutBlue.withOpacity( 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  widget.distribution.isEvenlyDistributed
                      ? Icons.balance
                      : Icons.insights,
                  color: widget.distribution.isEvenlyDistributed
                      ? AppColors.revolutGreen
                      : AppColors.revolutBlue,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    widget.distribution.insightMessage,
                    style: TextStyle(
                      color: widget.distribution.isEvenlyDistributed
                          ? AppColors.revolutGreen
                          : AppColors.revolutBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Bar chart
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: widget.distribution.days.map((day) {
                final isHighest =
                    day.dayIndex == widget.distribution.highestDayIndex;
                final isSelected = _selectedDayIndex == day.dayIndex;
                final barHeight = maxAmount > 0
                    ? (day.totalAmount / maxAmount * 80).clamp(4.0, 80.0)
                    : 4.0;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDayIndex =
                          _selectedDayIndex == day.dayIndex ? null : day.dayIndex;
                    });
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Bar
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 32,
                        height: day.totalAmount > 0 ? barHeight : 4,
                        decoration: BoxDecoration(
                          color: isHighest
                              ? AppColors.revolutBlue
                              : isSelected
                                  ? AppColors.revolutBlue.withOpacity( 0.7)
                                  : AppColors.revolutSurfaceElevated,
                          borderRadius: BorderRadius.circular(4),
                          border: isSelected
                              ? Border.all(color: AppColors.revolutBlue, width: 2)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Day label
                      Text(
                        day.dayShortName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isHighest ? FontWeight.bold : FontWeight.normal,
                          color: isHighest
                              ? AppColors.revolutBlue
                              : AppColors.revolutOnDarkMuted,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Selected day detail
          if (_selectedDayIndex != null) ...[
            const SizedBox(height: AppSpacing.md),
            _DayDetailPanel(
              day: widget.distribution.days
                  .firstWhere((d) => d.dayIndex == _selectedDayIndex),
            ),
          ],
        ],
      ),
    );
  }
}

/// Panel showing details for a selected day.
class _DayDetailPanel extends StatelessWidget {
  const _DayDetailPanel({required this.day});

  final DaySpending day;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.revolutSurfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            day.dayName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.revolutOnDark,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: _DetailItem(
                  label: 'Total',
                  value: _formatAmount(day.totalAmount),
                ),
              ),
              Expanded(
                child: _DetailItem(
                  label: 'Moyenne',
                  value: _formatAmount(day.averageAmount),
                ),
              ),
              Expanded(
                child: _DetailItem(
                  label: 'Transactions',
                  value: '${day.transactionCount}',
                ),
              ),
            ],
          ),
          if (day.topCategoryLabel != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Text(
                  'Top catégorie: ',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.revolutOnDarkMuted,
                  ),
                ),
                Text(
                  day.topCategoryLabel!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.revolutBlue,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
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

/// Single detail item in the panel.
class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.revolutOnDarkMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.revolutOnDark,
          ),
        ),
      ],
    );
  }
}

/// State shown when no spending data exists.
class _NoDataState extends StatelessWidget {
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
          Row(
            children: [
              Icon(
                Icons.calendar_view_week,
                color: AppColors.revolutBlue,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Dépenses par jour',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Icon(
            Icons.bar_chart,
            color: AppColors.revolutOnDarkMuted,
            size: 32,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pas encore de données',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.revolutOnDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Ajoute des dépenses pour voir la répartition par jour',
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
