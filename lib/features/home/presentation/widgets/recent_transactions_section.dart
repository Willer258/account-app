import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../history/presentation/widgets/transaction_tile.dart';
import '../../../transactions/domain/models/transaction_model.dart';

/// Provider for recent transactions (last 5).
final recentTransactionsProvider =
    Provider.autoDispose<List<TransactionModel>>((ref) {
  final groupedAsync = ref.watch(historyTransactionsProvider);
  return groupedAsync.maybeWhen(
    data: (grouped) {
      // Flatten all transactions and take the first 5
      final allTransactions = <TransactionModel>[];
      for (final group in grouped.groups.values) {
        allTransactions.addAll(group);
      }
      // Already sorted by date desc from repository
      return allTransactions.take(5).toList();
    },
    orElse: () => [],
  );
});

/// Section displaying recent transactions on the home screen.
///
/// Shows the last 5 transactions with a "Voir tout" button to navigate
/// to the full history screen.
class RecentTransactionsSection extends ConsumerWidget {
  /// Creates a RecentTransactionsSection.
  const RecentTransactionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(recentTransactionsProvider);

    if (transactions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transactions récentes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.history),
                child: Text(
                  'Voir tout',
                  style: TextStyle(
                    color: AppColors.revolutBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Transaction list
        Container(
          decoration: BoxDecoration(
            color: AppColors.revolutSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.revolutBorder.withValues(alpha: 0.5),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                for (int i = 0; i < transactions.length; i++) ...[
                  TransactionTile(transaction: transactions[i]),
                  if (i < transactions.length - 1)
                    Divider(
                      height: 1,
                      indent: 72,
                      color: AppColors.revolutBorder.withValues(alpha: 0.5),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
