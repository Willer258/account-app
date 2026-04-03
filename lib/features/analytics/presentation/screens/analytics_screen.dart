import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/utils/fcfa_formatter.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../../../shared/widgets/smooth_progress_bar.dart';
import '../../../budget_rules/domain/enums/expense_category.dart';
import '../../../home/presentation/providers/budget_provider.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../transactions/domain/models/transaction_model.dart';
import '../../../transactions/domain/models/transaction_type.dart';
import '../widgets/spending_chart.dart';

/// Analytics dashboard — Revolut-inspired design.
///
/// Features:
/// - Spending by category (donut-style with CustomPaint)
/// - Daily spending bar chart (CustomPaint)
/// - Category breakdown cards
/// - Monthly stats summary
///
/// Covers: US-005 — Analytics Dashboard
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetState = ref.watch(budgetStateProvider);
    final historyAsync = ref.watch(historyTransactionsProvider);

    final allTransactions = historyAsync.maybeWhen(
      data: (grouped) => grouped.groups.values.expand((l) => l).toList(),
      orElse: () => <TransactionModel>[],
    );

    final expenses = allTransactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    final totalSpent = expenses.fold<int>(0, (s, t) => s + t.amountFcfa);

    final categoryTotals = <ExpenseCategory, int>{};
    for (final t in expenses) {
      categoryTotals[t.category] =
          (categoryTotals[t.category] ?? 0) + t.amountFcfa;
    }

    return Scaffold(
      backgroundColor: AppColors.revolutDark,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analyses',
                      style: AppTypography.revolutTitle.copyWith(
                        color: AppColors.revolutOnDark,
                      ),
                    ),
                    Text(
                      DateFormat('MMMM yyyy', 'fr_FR').format(DateTime.now()),
                      style: AppTypography.revolutMicro.copyWith(
                        color: AppColors.revolutOnDarkMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Monthly Summary Cards ─────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Dépensé',
                        value: FcfaFormatter.formatCompact(totalSpent),
                        color: AppColors.revolutRed,
                        icon: Icons.trending_down_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Budget restant',
                        value: FcfaFormatter.formatCompact(
                          budgetState.remainingBeforePlanned.abs(),
                        ),
                        color: budgetState.remainingBeforePlanned >= 0
                            ? AppColors.revolutGreen
                            : AppColors.revolutRed,
                        icon: Icons.savings_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Spending Chart ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: RevolutCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DÉPENSES PAR CATÉGORIE',
                        style: AppTypography.revolutMicro.copyWith(
                          color: AppColors.revolutOnDarkMuted,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (categoryTotals.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'Aucune dépense ce mois',
                              style: AppTypography.revolutBody.copyWith(
                                color: AppColors.revolutOnDarkMuted,
                              ),
                            ),
                          ),
                        )
                      else
                        SpendingDonutChart(
                          categoryTotals: categoryTotals,
                          total: totalSpent,
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Category Breakdown ────────────────────────────
            if (categoryTotals.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: RevolutCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DÉTAIL PAR CATÉGORIE',
                          style: AppTypography.revolutMicro.copyWith(
                            color: AppColors.revolutOnDarkMuted,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...ExpenseCategory.values.map((cat) {
                          final amount = categoryTotals[cat] ?? 0;
                          final ratio = totalSpent > 0
                              ? (amount / totalSpent).clamp(0.0, 1.0)
                              : 0.0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _CategoryRow(
                              category: cat,
                              amount: amount,
                              ratio: ratio,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Daily spending bars ───────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: RevolutCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DÉPENSES PAR JOUR',
                        style: AppTypography.revolutMicro.copyWith(
                          color: AppColors.revolutOnDarkMuted,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      DailySpendingChart(transactions: expenses),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Stat Card
// ─────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return RevolutCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.revolutMicro.copyWith(
                  color: AppColors.revolutOnDarkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.revolutSubtitle.copyWith(
              color: color,
              fontSize: 18,
            ),
          ),
          Text(
            'FCFA',
            style: AppTypography.revolutMicro.copyWith(
              color: AppColors.revolutOnDarkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Category Row
// ─────────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.amount,
    required this.ratio,
  });

  final ExpenseCategory category;
  final int amount;
  final double ratio;

  Color get _catColor {
    switch (category) {
      case ExpenseCategory.needs:
        return AppColors.revolutBlue;
      case ExpenseCategory.wants:
        return AppColors.revolutAmber;
      case ExpenseCategory.savings:
        return AppColors.revolutGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _catColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(category.icon, color: _catColor, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        category.displayName,
                        style: AppTypography.revolutBody.copyWith(
                          color: AppColors.revolutOnDark,
                        ),
                      ),
                      Text(
                        FcfaFormatter.formatCompact(amount),
                        style: AppTypography.revolutLabel.copyWith(
                          color: _catColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SmoothProgressBar(
                    value: ratio,
                    height: 3,
                    foregroundColor: _catColor,
                    backgroundColor: _catColor.withOpacity(0.1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
