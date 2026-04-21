import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/clock_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/fcfa_formatter.dart';
import '../../domain/models/planned_expense_model.dart';
import '../providers/planned_expenses_list_provider.dart';

/// Compact preview of the next upcoming planned expense.
///
/// Shows the closest pending planned expense with days until due.
/// Only displays if there are pending planned expenses.
class UpcomingExpensePreview extends ConsumerWidget {
  const UpcomingExpensePreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingExpensesAsync = ref.watch(pendingPlannedExpensesProvider);
    final clock = ref.watch(clockProvider);
    final now = clock.now();

    return pendingExpensesAsync.when(
      data: (expenses) {
        if (expenses.isEmpty) {
          return const SizedBox.shrink();
        }

        // Sort by expected date and get the closest one
        final sorted = List<PlannedExpenseModel>.from(expenses)
          ..sort((a, b) => a.expectedDate.compareTo(b.expectedDate));
        final nextExpense = sorted.first;
        final daysUntil = nextExpense.daysUntilDue(now);
        final isOverdue = daysUntil < 0;
        final isDueToday = daysUntil == 0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isOverdue
                ? AppColors.revolutRed.withValues(alpha: 0.1)
                : isDueToday
                    ? const Color(0xFFFF9800).withValues(alpha: 0.1)
                    : AppColors.revolutSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOverdue
                  ? AppColors.revolutRed.withValues(alpha: 0.3)
                  : isDueToday
                      ? const Color(0xFFFF9800).withValues(alpha: 0.3)
                      : AppColors.revolutBorder.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isOverdue
                      ? AppColors.revolutRed.withValues(alpha: 0.1)
                      : isDueToday
                          ? const Color(0xFFFF9800).withValues(alpha: 0.1)
                          : AppColors.revolutBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    isOverdue
                        ? Icons.warning_amber_rounded
                        : Icons.calendar_today,
                    size: 18,
                    color: isOverdue
                        ? AppColors.revolutRed
                        : isDueToday
                            ? const Color(0xFFFF9800)
                            : AppColors.revolutBlue,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      nextExpense.description,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.revolutOnDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _getDueDateText(daysUntil),
                      style: TextStyle(
                        fontSize: 10,
                        color: isOverdue
                            ? AppColors.revolutRed
                            : isDueToday
                                ? const Color(0xFFFF9800)
                                : AppColors.revolutOnDarkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Amount
              Text(
                FcfaFormatter.formatCompact(nextExpense.amountFcfa),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isOverdue
                      ? AppColors.revolutRed
                      : isDueToday
                          ? const Color(0xFFFF9800)
                          : AppColors.revolutOnDark,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _getDueDateText(int daysUntil) {
    if (daysUntil < 0) {
      final days = -daysUntil;
      return days == 1 ? 'En retard de 1 jour' : 'En retard de $days jours';
    } else if (daysUntil == 0) {
      return "Prévu aujourd'hui";
    } else if (daysUntil == 1) {
      return 'Dans 1 jour';
    } else {
      return 'Dans $daysUntil jours';
    }
  }
}
