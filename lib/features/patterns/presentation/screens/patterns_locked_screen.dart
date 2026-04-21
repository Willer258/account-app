import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/pattern_analysis_service.dart';
import '../../../../core/theme/pockii_colors.dart';
import '../../../../core/services/pattern_unlock_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/utils/fcfa_formatter.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../../../shared/widgets/smooth_progress_bar.dart';
import '../../../analytics/presentation/widgets/spending_chart.dart';
import '../../../budget_rules/domain/enums/expense_category.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../transactions/domain/models/transaction_model.dart';
import '../../../transactions/domain/models/transaction_type.dart';
import '../widgets/day_of_week_spending_card.dart';
import '../widgets/income_expense_overview_card.dart';
import '../widgets/month_comparison_card.dart';
import '../widgets/top_categories_card.dart';

/// Revolut-style dark patterns screen.
///
/// Shows either locked state with progress or full patterns when unlocked.
class PatternsLockedScreen extends ConsumerStatefulWidget {
  /// Creates a PatternsLockedScreen.
  const PatternsLockedScreen({super.key});

  @override
  ConsumerState<PatternsLockedScreen> createState() =>
      _PatternsLockedScreenState();
}

class _PatternsLockedScreenState extends ConsumerState<PatternsLockedScreen> {
  bool _showingCelebration = false;

  @override
  void initState() {
    super.initState();
    _checkForCelebration();
  }

  Future<void> _checkForCelebration() async {
    final service = ref.read(patternUnlockServiceProvider);
    final shouldShow = await service.shouldShowCelebration();
    if (shouldShow && mounted) {
      setState(() => _showingCelebration = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          service.markCelebrationShown();
          setState(() => _showingCelebration = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlockedAsync = ref.watch(patternUnlockedProvider);
    final daysRemainingAsync = ref.watch(patternDaysRemainingProvider);
    final progressAsync = ref.watch(patternProgressProvider);

    return Scaffold(
      backgroundColor: context.pockii.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                'Tes Tendances',
                style: AppTypography.revolutTitle.copyWith(
                  color: context.pockii.onSurface,
                ),
              ),
            ),
            Expanded(
              child: unlockedAsync.when(
                data: (isUnlocked) {
                  if (_showingCelebration) {
                    return _UnlockCelebration();
                  }

                  if (isUnlocked) {
                    return _PatternsContent();
                  }

                  return daysRemainingAsync.when(
                    data: (daysRemaining) => progressAsync.when(
                      data: (progress) => _LockedState(
                        daysRemaining: daysRemaining,
                        progress: progress,
                      ),
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: AppColors.revolutBlue),
                      ),
                      error: (_, __) => EmptyStateWidget.patternsLocked(daysRemaining: 30),
                    ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.revolutBlue),
                    ),
                    error: (_, __) => EmptyStateWidget.patternsLocked(daysRemaining: 30),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.revolutBlue),
                ),
                error: (_, __) => EmptyStateWidget.patternsLocked(daysRemaining: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Locked state showing progress toward unlock.
class _LockedState extends StatelessWidget {
  const _LockedState({
    required this.daysRemaining,
    required this.progress,
  });

  final int daysRemaining;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lock icon with progress ring
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: context.pockii.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.revolutBlue),
                ),
              ),
              Icon(
                Icons.lock_outline_rounded,
                size: 48,
                color: context.pockii.onSurfaceMuted,
              ),
            ],
          ),

          const SizedBox(height: 32),

          Text(
            'Tendances verrouillées',
            style: AppTypography.revolutSubtitle.copyWith(
              color: context.pockii.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            daysRemaining == 1
                ? 'Encore 1 jour avant de débloquer'
                : 'Encore $daysRemaining jours avant de débloquer',
            style: AppTypography.revolutBody.copyWith(
              color: context.pockii.onSurfaceMuted,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            '${(progress * 100).toInt()}% complété',
            style: AppTypography.revolutLabel.copyWith(
              color: AppColors.revolutBlue,
            ),
          ),

          const SizedBox(height: 32),

          RevolutCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.revolutAmber,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  'Pourquoi 30 jours?',
                  style: AppTypography.revolutLabel.copyWith(
                    color: context.pockii.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'On a besoin de suffisamment de données pour te montrer des analyses vraiment utiles sur tes habitudes.',
                  style: AppTypography.revolutMicro.copyWith(
                    color: context.pockii.onSurfaceMuted,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Unlock celebration animation.
class _UnlockCelebration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.revolutBlue.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_open_rounded,
                      size: 64,
                      color: AppColors.revolutBlue,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(opacity: value, child: child);
              },
              child: Column(
                children: [
                  Text(
                    'Tes tendances sont prêtes !',
                    style: AppTypography.revolutSubtitle.copyWith(
                      color: AppColors.revolutBlue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Découvre tes habitudes de dépenses',
                    style: AppTypography.revolutBody.copyWith(
                      color: context.pockii.onSurfaceMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full patterns screen with category analysis, analytics, and month navigation.
class _PatternsContent extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PatternsContent> createState() => _PatternsContentState();
}

class _PatternsContentState extends ConsumerState<_PatternsContent> {
  int _selectedMonthOffset = 0; // 0 = current, -1 = last month, etc.

  DateTime get _selectedMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + _selectedMonthOffset);
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyTransactionsProvider);
    final categoryBreakdownAsync = ref.watch(categoryBreakdownProvider);

    // Get all transactions and filter by selected month
    final allTransactions = historyAsync.maybeWhen(
      data: (grouped) => grouped.groups.values.expand((l) => l).toList(),
      orElse: () => <TransactionModel>[],
    );

    final monthTransactions = allTransactions.where((t) {
      return t.date.year == _selectedMonth.year &&
          t.date.month == _selectedMonth.month;
    }).toList();

    final expenses = monthTransactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    final incomes = monthTransactions
        .where((t) => t.type == TransactionType.income)
        .toList();

    final totalSpent = expenses.fold<int>(0, (s, t) => s + t.amountFcfa);
    final totalIncome = incomes.fold<int>(0, (s, t) => s + t.amountFcfa);

    // Build category totals
    final categoryTotals = <ExpenseCategory, int>{};
    for (final t in expenses) {
      final cat = DefaultCategoryMappings.guessCategory(t.category);
      categoryTotals[cat] = (categoryTotals[cat] ?? 0) + t.amountFcfa;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Month Selector ─────────────────────────
          _MonthSelector(
            selectedOffset: _selectedMonthOffset,
            onSelected: (offset) =>
                setState(() => _selectedMonthOffset = offset),
          ),

          const SizedBox(height: 16),

          // ── Summary Cards ──────────────────────────
          Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  label: 'Revenus',
                  value: FcfaFormatter.formatCompact(totalIncome),
                  color: AppColors.revolutGreen,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStatCard(
                  label: 'Dépensé',
                  value: FcfaFormatter.formatCompact(totalSpent),
                  color: AppColors.revolutRed,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
          if (totalIncome > 0) ...[
            const SizedBox(height: 10),
            _MiniStatCard(
              label: 'Solde net',
              value: '${totalIncome >= totalSpent ? '+' : ''}${FcfaFormatter.formatCompact(totalIncome - totalSpent)}',
              color: totalIncome >= totalSpent
                  ? AppColors.revolutGreen
                  : AppColors.revolutRed,
              icon: Icons.balance_rounded,
            ),
          ],

          const SizedBox(height: 16),

          // ── Category Donut ─────────────────────────
          if (categoryTotals.isNotEmpty) ...[
            RevolutCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DÉPENSES PAR CATÉGORIE',
                    style: AppTypography.revolutMicro.copyWith(
                      color: context.pockii.onSurfaceMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SpendingDonutChart(
                    categoryTotals: categoryTotals,
                    total: totalSpent,
                  ),
                  const SizedBox(height: 16),
                  // Category rows
                  ...ExpenseCategory.values.map((cat) {
                    final amount = categoryTotals[cat] ?? 0;
                    final ratio = totalSpent > 0
                        ? (amount / totalSpent).clamp(0.0, 1.0)
                        : 0.0;
                    if (amount == 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CategoryBreakdownRow(
                        category: cat,
                        amount: amount,
                        ratio: ratio,
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Existing pattern widgets (only for current month) ──
          if (_selectedMonthOffset == 0) ...[
            categoryBreakdownAsync.when(
              data: (categories) => Column(
                children: [
                  const TopCategoriesCard(),
                  const SizedBox(height: 12),
                  const MonthComparisonCard(),
                  const SizedBox(height: 12),
                  const IncomeExpenseOverviewCard(),
                  const SizedBox(height: 12),
                  const DayOfWeekSpendingCard(),
                ],
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.revolutBlue,
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ] else ...[
            // For past months, show a message
            if (categoryTotals.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 48,
                        color: context.pockii.onSurfaceMuted.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Aucune donnée pour ce mois',
                        style: AppTypography.revolutBody.copyWith(
                          color: context.pockii.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Month selector with horizontal scrollable chips.
class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.selectedOffset,
    required this.onSelected,
  });

  final int selectedOffset;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 6, // Current month + 5 previous months
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final offset = -index;
          final month = DateTime(
            DateTime.now().year,
            DateTime.now().month + offset,
          );
          final label = DateFormat('MMM yyyy', 'fr_FR').format(month);
          final isSelected = offset == selectedOffset;

          return GestureDetector(
            onTap: () => onSelected(offset),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.revolutBlue
                    : context.pockii.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.revolutBlue
                      : context.pockii.border,
                ),
              ),
              child: Text(
                label,
                style: AppTypography.revolutLabel.copyWith(
                  color: isSelected
                      ? context.pockii.onSurface
                      : context.pockii.onSurfaceMuted,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Mini stat card for the tendances summary.
class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.revolutMicro.copyWith(
                  color: context.pockii.onSurfaceMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.revolutSubtitle.copyWith(
              color: color,
              fontSize: 17,
            ),
          ),
          Text(
            FcfaFormatter.symbol,
            style: AppTypography.revolutMicro.copyWith(
              color: context.pockii.onSurfaceMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// Category breakdown row with progress bar.
class _CategoryBreakdownRow extends StatelessWidget {
  const _CategoryBreakdownRow({
    required this.category,
    required this.amount,
    required this.ratio,
  });

  final ExpenseCategory category;
  final int amount;
  final double ratio;

  Color get _color {
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
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(category.icon, color: _color, size: 16),
        ),
        const SizedBox(width: 10),
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
                      color: context.pockii.onSurface,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    FcfaFormatter.formatCompact(amount),
                    style: AppTypography.revolutLabel.copyWith(
                      color: _color,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SmoothProgressBar(
                value: ratio,
                height: 3,
                foregroundColor: _color,
                backgroundColor: _color.withOpacity(0.1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
