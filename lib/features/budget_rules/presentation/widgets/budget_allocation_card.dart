import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/fcfa_formatter.dart';
import '../../domain/enums/expense_category.dart';
import '../../domain/models/budget_allocation.dart';
import '../providers/budget_rules_provider.dart';

/// Card displaying the 50/30/20 budget allocation breakdown.
class BudgetAllocationCard extends ConsumerWidget {
  const BudgetAllocationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allocation = ref.watch(budgetAllocationProvider);

    if (allocation == null) {
      return const SizedBox.shrink();
    }

    final settings = allocation.settings;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.revolutSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.revolutBorder,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Règle 50/30/20',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Allocation bars with real spending
          _AllocationBarWithProgress(
            categoryAllocation: allocation.needs,
          ),
          const SizedBox(height: AppSpacing.sm),
          _AllocationBarWithProgress(
            categoryAllocation: allocation.wants,
          ),
          const SizedBox(height: AppSpacing.sm),
          _AllocationBarWithProgress(
            categoryAllocation: allocation.savings,
          ),

          // Warning if overspending
          if (allocation.hasOverspending) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.revolutRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Attention: dépassement de budget détecté',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.error,
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

/// Individual allocation bar with progress indicator.
class _AllocationBarWithProgress extends StatelessWidget {
  const _AllocationBarWithProgress({
    required this.categoryAllocation,
  });

  final CategoryAllocation categoryAllocation;

  @override
  Widget build(BuildContext context) {
    final category = categoryAllocation.category;
    final progress = categoryAllocation.progress.clamp(0.0, 1.5);
    final isOver = categoryAllocation.isOverBudget;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row: emoji, name, amounts
        Row(
          children: [
            Text(category.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                category.displayName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Actual / Target
            Text(
              FcfaFormatter.formatCompact(categoryAllocation.actualAmount),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isOver ? AppColors.error : category.color,
              ),
            ),
            Text(
              ' / ${FcfaFormatter.formatCompact(categoryAllocation.targetAmount)}',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.revolutOnDarkMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: AppColors.revolutBorder,
            valueColor: AlwaysStoppedAnimation<Color>(
              isOver ? AppColors.error : category.color,
            ),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 2),
        // Status text
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${categoryAllocation.targetPercentage}% du budget',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.revolutOnDarkMuted,
              ),
            ),
            Text(
              isOver
                  ? 'Dépassé de ${FcfaFormatter.formatCompact(-categoryAllocation.remaining)}'
                  : 'Reste ${FcfaFormatter.formatCompact(categoryAllocation.remaining)}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isOver ? AppColors.error : AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Compact version for settings preview.
class BudgetAllocationPreview extends ConsumerWidget {
  const BudgetAllocationPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(budgetRuleSettingsProvider);

    return Row(
      children: [
        _PreviewChip(
          label: 'Besoins',
          percentage: settings.needsPercentage,
          color: ExpenseCategory.needs.color,
        ),
        const SizedBox(width: AppSpacing.xs),
        _PreviewChip(
          label: 'Envies',
          percentage: settings.wantsPercentage,
          color: ExpenseCategory.wants.color,
        ),
        const SizedBox(width: AppSpacing.xs),
        _PreviewChip(
          label: 'Épargne',
          percentage: settings.savingsPercentage,
          color: ExpenseCategory.savings.color,
        ),
      ],
    );
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({
    required this.label,
    required this.percentage,
    required this.color,
  });

  final String label;
  final int percentage;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$percentage%',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
