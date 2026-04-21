import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/clock_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/fcfa_formatter.dart';
import '../../../planned_expenses/domain/models/planned_expense_model.dart';
import '../../../planned_expenses/presentation/providers/planned_expenses_list_provider.dart';

/// Provider for upcoming expenses (due within the next 7 days).
final upcomingExpensesProvider =
    Provider.autoDispose<AsyncValue<List<PlannedExpenseModel>>>((ref) {
  final pendingAsync = ref.watch(pendingPlannedExpensesProvider);
  final clock = ref.watch(clockProvider);
  final now = clock.now();

  return pendingAsync.whenData((expenses) {
    // Filter for expenses due within 7 days (including overdue)
    return expenses.where((e) => e.daysUntilDue(now) <= 7).toList();
  });
});

/// Section showing upcoming planned expenses on the home screen.
///
/// Displays pending expenses due within the next 7 days.
/// Tapping the section navigates to the full planned expenses list.
class UpcomingExpensesSection extends ConsumerWidget {
  const UpcomingExpensesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(upcomingExpensesProvider);

    return upcomingAsync.when(
      data: (expenses) {
        if (expenses.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'À venir',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context.push('/planned-expenses'),
                  child: const Text('Voir tout'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Expense cards
            ...expenses.take(3).map((expense) => _UpcomingExpenseCard(
                  expense: expense,
                  onTap: () => context.push('/planned-expenses'),
                )),

            // Show count if more than 3
            if (expenses.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Center(
                  child: Text(
                    '+${expenses.length - 3} autres',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.revolutOnDarkMuted,
                        ),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Card displaying a single upcoming expense.
class _UpcomingExpenseCard extends ConsumerWidget {
  const _UpcomingExpenseCard({
    required this.expense,
    this.onTap,
  });

  final PlannedExpenseModel expense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clock = ref.watch(clockProvider);
    final now = clock.now();
    final daysUntil = expense.daysUntilDue(now);

    // Determine urgency color
    Color urgencyColor;
    String urgencyLabel;
    if (daysUntil < 0) {
      urgencyColor = AppColors.revolutRed;
      urgencyLabel = 'En retard';
    } else if (daysUntil == 0) {
      urgencyColor = AppColors.revolutRed;
      urgencyLabel = "Aujourd'hui";
    } else if (daysUntil == 1) {
      urgencyColor = Colors.orange;
      urgencyLabel = 'Demain';
    } else {
      urgencyColor = AppColors.revolutBlue;
      urgencyLabel = 'Dans $daysUntil jours';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              // Urgency indicator
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: urgencyColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.description,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      urgencyLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: urgencyColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Amount
              Text(
                FcfaFormatter.format(expense.amountFcfa),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
