import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../home/presentation/providers/budget_provider.dart';
import '../../../transactions/data/transaction_repository.dart';
import '../../../transactions/domain/models/transaction_model.dart';
import '../../../transactions/presentation/widgets/transaction_bottom_sheet.dart';
import '../providers/history_provider.dart';
import '../widgets/date_section_header.dart';
import '../widgets/transaction_tile.dart';

/// Revolut-style dark history screen.
///
/// Shows transactions grouped by date with dark theme styling.
class HistoryScreen extends ConsumerWidget {
  /// Creates a HistoryScreen.
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyTransactionsProvider);
    final categoryFilter = ref.watch(historyCategoryFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.revolutDark,
      appBar: AppBar(
        backgroundColor: AppColors.revolutDark,
        title: Text(
          categoryFilter != null ? 'Historique (filtré)' : 'Historique',
          style: AppTypography.revolutTitle.copyWith(
            color: AppColors.revolutOnDark,
            fontSize: 24,
          ),
        ),
        centerTitle: false,
        actions: [
          if (categoryFilter != null)
            IconButton(
              icon: const Icon(
                Icons.filter_alt_off_rounded,
                color: AppColors.revolutBlue,
              ),
              tooltip: 'Effacer le filtre',
              onPressed: () {
                ref.read(historyCategoryFilterProvider.notifier).state = null;
              },
            ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.revolutBlue),
        ),
        error: (error, _) => Center(
          child: Text(
            'Erreur: $error',
            style: AppTypography.revolutBody.copyWith(
              color: AppColors.revolutRed,
            ),
          ),
        ),
        data: (grouped) {
          if (grouped.totalCount == 0) {
            return Center(
              child: EmptyStateWidget.history(
                onAction: () => TransactionBottomSheet.show(context),
              ),
            );
          }

          return _TransactionListView(grouped: grouped);
        },
      ),
    );
  }
}

/// Builds flat list from grouped transactions.
class _TransactionListView extends ConsumerWidget {
  const _TransactionListView({required this.grouped});

  final GroupedTransactions grouped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Create flat list of items (headers + transactions)
    final items = <_ListItem>[];
    for (final header in grouped.headers) {
      items.add(_HeaderItem(header));
      for (final transaction in grouped.groups[header]!) {
        items.add(_TransactionItem(transaction));
      }
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return switch (item) {
          _HeaderItem(:final label) => DateSectionHeader(label: label),
          _TransactionItem(:final transaction) => TransactionTile(
              transaction: transaction,
              onEdit: () => _handleEdit(context, transaction),
              onDelete: () => _handleDelete(context, ref, transaction),
            ),
        };
      },
    );
  }

  /// Handles the edit action for a transaction.
  void _handleEdit(BuildContext context, TransactionModel transaction) {
    TransactionBottomSheet.showEdit(context, transaction);
  }

  /// Handles the delete action for a transaction with undo support.
  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    TransactionModel transaction,
  ) async {
    // Delete the transaction
    final repository = ref.read(transactionRepositoryProvider);
    await repository.deleteTransaction(transaction.id);

    // Refresh budget to reflect deletion
    await ref.read(budgetStateProvider.notifier).refresh();

    // Haptic feedback
    await HapticFeedback.mediumImpact();

    // Show snackbar with undo action
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Transaction supprimée',
            style: AppTypography.revolutBody.copyWith(
              color: AppColors.revolutOnDark,
            ),
          ),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Annuler',
            textColor: AppColors.revolutBlue,
            onPressed: () => _restoreTransaction(ref, transaction),
          ),
        ),
      );
    }
  }

  /// Restores a deleted transaction.
  Future<void> _restoreTransaction(
    WidgetRef ref,
    TransactionModel transaction,
  ) async {
    final repository = ref.read(transactionRepositoryProvider);

    // Re-create the transaction with same data
    await repository.createTransaction(
      amountFcfa: transaction.amountFcfa,
      category: transaction.category,
      type: transaction.type,
      date: transaction.date,
      note: transaction.note,
    );

    // Refresh budget
    await ref.read(budgetStateProvider.notifier).refresh();

    // Haptic feedback
    await HapticFeedback.lightImpact();
  }
}

/// Base class for list items.
sealed class _ListItem {}

/// Header item for date sections.
class _HeaderItem extends _ListItem {
  _HeaderItem(this.label);
  final String label;
}

/// Transaction item.
class _TransactionItem extends _ListItem {
  _TransactionItem(this.transaction);
  final TransactionModel transaction;
}
