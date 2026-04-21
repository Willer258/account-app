import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/clock_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/fcfa_formatter.dart';
import '../../domain/models/planned_expense_model.dart';
import '../../domain/services/planned_expense_conversion_service.dart';
import '../dialogs/conversion_dialog.dart';
import '../providers/planned_expenses_list_provider.dart';
import '../widgets/planned_expense_tile.dart';
import 'planned_expense_form_screen.dart';

/// Screen displaying the list of planned expenses.
///
/// Shows all pending planned expenses with option to show completed ones.
/// Displays total pending amount at the top.
class PlannedExpensesListScreen extends ConsumerWidget {
  /// Creates a PlannedExpensesListScreen.
  const PlannedExpensesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(plannedExpensesListStateProvider);
    final expensesAsync = ref.watch(filteredPlannedExpensesProvider);
    final totalPendingAsync = ref.watch(totalPendingAmountProvider);
    final pendingCountAsync = ref.watch(pendingPlannedExpenseCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dépenses prévues'),
        actions: [
          // Toggle for showing completed expenses
          IconButton(
            onPressed: () {
              ref
                  .read(plannedExpensesListStateProvider.notifier)
                  .toggleShowCompleted();
            },
            icon: Icon(
              listState.showCompleted
                  ? Icons.visibility_off
                  : Icons.visibility,
            ),
            tooltip: listState.showCompleted
                ? 'Masquer terminées'
                : 'Afficher terminées',
          ),
        ],
      ),
      body: Column(
        children: [
          // Total pending summary card
          _TotalPendingCard(
            totalPendingAsync: totalPendingAsync,
            pendingCountAsync: pendingCountAsync,
          ),

          // Planned expenses list
          Expanded(
            child: expensesAsync.when(
              data: (expenses) {
                if (expenses.isEmpty) {
                  return _EmptyState(
                    showCompleted: listState.showCompleted,
                    onAddPressed: () => _navigateToAddExpense(context),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.sm,
                    bottom: 72,
                  ),
                  itemCount: expenses.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return PlannedExpenseTile(
                      expense: expense,
                      onTap: () => _navigateToEditExpense(context, expense),
                      onMarkAsPaid: expense.isPending
                          ? () => _showMarkAsPaidDialog(context, ref, expense)
                          : null,
                      onCancel: expense.isPending
                          ? () => _showCancelDialog(context, ref, expense)
                          : null,
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.revolutRed,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Erreur de chargement',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: () {
                        ref.invalidate(allPlannedExpensesProvider);
                        ref.invalidate(pendingPlannedExpensesProvider);
                      },
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddExpense(context),
        icon: const Icon(Icons.add),
        label: const Text('Planifier'),
      ),
    );
  }

  Future<void> _navigateToAddExpense(BuildContext context) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.revolutSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const PlannedExpenseFormScreen(),
    );
  }

  Future<void> _navigateToEditExpense(
    BuildContext context,
    PlannedExpenseModel expense,
  ) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.revolutSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PlannedExpenseFormScreen(expense: expense),
    );
  }

  Future<void> _showMarkAsPaidDialog(
    BuildContext context,
    WidgetRef ref,
    PlannedExpenseModel expense,
  ) async {
    // Show conversion dialog with amount adjustment
    final result = await ConversionDialog.show(context, expense);

    if (result == null || !result.confirmed) {
      return;
    }

    // Convert to transaction using the service
    final conversionService = ref.read(plannedExpenseConversionServiceProvider);
    final clock = ref.read(clockProvider);

    final conversionResult = await conversionService.convertToTransaction(
      plannedExpenseId: expense.id,
      actualAmount: result.adjustedAmount,
      transactionDate: clock.now(),
    );

    if (context.mounted) {
      if (conversionResult.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dépense convertie en transaction'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(conversionResult.errorMessage ?? 'Erreur'),
            backgroundColor: AppColors.revolutRed,
          ),
        );
      }
    }
  }

  Future<void> _showCancelDialog(
    BuildContext context,
    WidgetRef ref,
    PlannedExpenseModel expense,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la dépense'),
        content: Text(
          'Voulez-vous annuler "${expense.description}" ?\n\n'
          'Le budget réservé (${FcfaFormatter.format(expense.amountFcfa)}) '
          'sera libéré.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Non'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.revolutRed,
            ),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final conversionService = ref.read(plannedExpenseConversionServiceProvider);
      final success = await conversionService.cancelPlannedExpense(expense.id);

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dépense annulée - budget libéré'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'annulation'),
              backgroundColor: AppColors.revolutRed,
            ),
          );
        }
      }
    }
  }
}

/// Card showing total pending planned expenses.
class _TotalPendingCard extends StatelessWidget {
  const _TotalPendingCard({
    required this.totalPendingAsync,
    required this.pendingCountAsync,
  });

  final AsyncValue<int> totalPendingAsync;
  final AsyncValue<int> pendingCountAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.event_note,
              color: AppColors.onSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total prévu',
                  style: TextStyle(
                    color: AppColors.revolutOnDarkMuted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                totalPendingAsync.when(
                  data: (total) => Text(
                    FcfaFormatter.format(total),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  loading: () => const SizedBox(
                    height: 24,
                    width: 100,
                    child: LinearProgressIndicator(),
                  ),
                  error: (_, __) => const Text(
                    'Erreur',
                    style: TextStyle(color: AppColors.revolutRed),
                  ),
                ),
              ],
            ),
          ),
          pendingCountAsync.when(
            data: (count) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$count prévu${count > 1 ? 'es' : 'e'}',
                style: const TextStyle(
                  color: AppColors.onSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Empty state when no planned expenses exist.
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.showCompleted,
    required this.onAddPressed,
  });

  final bool showCompleted;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: AppColors.revolutBorder,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              showCompleted
                  ? 'Aucune dépense prévue'
                  : 'Aucune dépense en attente',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.revolutOnDarkMuted,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Planifiez vos dépenses futures pour\nmieux gérer votre budget.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.revolutOnDarkMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add),
              label: const Text('Planifier une dépense'),
            ),
          ],
        ),
      ),
    );
  }
}
