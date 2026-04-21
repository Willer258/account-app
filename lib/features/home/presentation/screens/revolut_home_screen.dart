import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/pockii_colors.dart';
import '../../../../shared/utils/fcfa_formatter.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../../../shared/widgets/smooth_progress_bar.dart';
import '../../../budget_rules/domain/enums/expense_category.dart';
import '../../../budget_rules/domain/models/budget_allocation.dart';
import '../../../budget_rules/presentation/providers/budget_rules_provider.dart';
import '../../domain/models/budget_state.dart';
import '../providers/budget_provider.dart';

/// Revolut-inspired home screen redesign.
///
/// Features:
/// - Dark gradient hero section with balance display
/// - Quick action buttons (Send, Receive, etc.)
/// - Revolut-style card with glassmorphism
/// - Spending summary with smooth progress bars
///
/// Covers: US-003 — Home Screen Redesign
class RevolutHomeScreen extends ConsumerWidget {
  const RevolutHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetState = ref.watch(budgetStateProvider);
    final monthLabel = ref.watch(currentMonthLabelProvider);

    return Scaffold(
      backgroundColor: context.pockii.background,
      body: RefreshIndicator(
        onRefresh: () => ref.read(budgetStateProvider.notifier).refresh(),
        color: AppColors.revolutBlue,
        backgroundColor: context.pockii.surface,
        child: CustomScrollView(
          slivers: [
            // ── Hero Section ──────────────────────────────────────
            SliverToBoxAdapter(
              child: _HeroSection(
                budgetState: budgetState,
                monthLabel: monthLabel,
              ),
            ),

            // ── 50/30/20 Budget Rules ─────────────────────────────
            const SliverToBoxAdapter(child: _BudgetRulesSection()),

            // ── Spending Summary ──────────────────────────────────
            SliverToBoxAdapter(
              child: _SpendingSummarySection(budgetState: budgetState),
            ),

            // ── Bottom padding ────────────────────────────────────
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Hero Section
// ─────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.budgetState, required this.monthLabel});

  final BudgetState budgetState;
  final String monthLabel;

  @override
  Widget build(BuildContext context) {
    final remaining = budgetState.remainingBeforePlanned;
    final isNegative = remaining < 0;
    final amountColor = isNegative
        ? AppColors.revolutRed
        : AppColors.revolutGreen;
    final prefix = isNegative ? '-' : '';
    final progress = budgetState.percentageRemaining.clamp(0.0, 1.0);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heroColors = isDark
        ? AppColors.revolutHeroGradient
        : AppColors.revolutHeroGradientLight;
    final heroTextColor = isDark
        ? AppColors.revolutOnDark
        : AppColors.revolutOnLight;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: heroColors,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: greeting + avatar ───────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(),
                        style: AppTypography.revolutMicro.copyWith(
                          color: isDark
                              ? AppColors.revolutOnDarkMuted
                              : AppColors.revolutOnLightMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        monthLabel,
                        style: AppTypography.revolutSubtitle.copyWith(
                          color: heroTextColor,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.challenges),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.revolutAmber.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.revolutAmber.withOpacity(0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: AppColors.revolutAmber,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Balance label ────────────────────────────────
              Text(
                'Budget restant',
                style: AppTypography.revolutMicro.copyWith(
                  color: isDark
                      ? AppColors.revolutOnDarkMuted
                      : AppColors.revolutOnLightMuted,
                  letterSpacing: 1.0,
                ),
              ),

              const SizedBox(height: 6),

              // ── Big balance number ───────────────────────────
              if (budgetState.isLoading)
                Container(
                  height: 72,
                  width: 200,
                  decoration: BoxDecoration(
                    color: context.pockii.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                )
              else
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: remaining.abs()),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          final animated = FcfaFormatter.formatCompact(value);
                          return Text(
                            '$prefix$animated',
                            style: AppTypography.revolutDisplay.copyWith(
                              color: amountColor,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        FcfaFormatter.symbol,
                        style: AppTypography.revolutSubtitle.copyWith(
                          color: isDark
                              ? AppColors.revolutOnDarkMuted
                              : AppColors.revolutOnLightMuted,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // ── Progress bar ─────────────────────────────────
              if (!budgetState.isLoading)
                SmoothProgressBar(
                  value: progress,
                  height: 5,
                  gradient: LinearGradient(
                    colors: isNegative
                        ? AppColors.negativeGradient
                        : AppColors.positiveGradient,
                  ),
                  backgroundColor: isDark
                      ? AppColors.glassOverlay
                      : AppColors.revolutBlue.withValues(alpha: 0.15),
                ),

              if (!budgetState.isLoading) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dépensé: ${FcfaFormatter.formatCompact(budgetState.totalBudget - budgetState.remainingBeforePlanned)}',
                      style: AppTypography.revolutMicro.copyWith(
                        color: isDark
                            ? AppColors.revolutOnDarkMuted
                            : AppColors.revolutOnLightMuted,
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}% restant',
                      style: AppTypography.revolutMicro.copyWith(
                        color: heroTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'BONJOUR';
    if (hour < 18) return 'BONNE APRÈS-MIDI';
    return 'BONSOIR';
  }
}

// ─────────────────────────────────────────────────────────────
// Spending Summary Section
// ─────────────────────────────────────────────────────────────

class _SpendingSummarySection extends ConsumerWidget {
  const _SpendingSummarySection({required this.budgetState});

  final BudgetState budgetState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (budgetState.isLoading) return const SizedBox.shrink();

    final total = budgetState.totalBudget;
    final remaining = budgetState.remainingBeforePlanned;
    final spent = budgetState.totalExpenses;
    final subscriptions = budgetState.totalSubscriptions;
    final double spentRatio =
        total > 0 ? ((spent + subscriptions) / total).clamp(0.0, 1.0) : 0.0;

    final allocation = ref.watch(budgetAllocationProvider);
    final incomeAsync = ref.watch(monthlyIncomeProvider);
    final income = incomeAsync.valueOrNull ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RÉSUMÉ DU MOIS',
            style: AppTypography.revolutMicro.copyWith(
              color: context.pockii.onSurfaceMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          RevolutCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Budget total',
                  amount: total,
                  color: context.pockii.onSurface,
                  icon: Icons.account_balance_wallet_rounded,
                  positive: true,
                ),
                if (income > 0) ...[
                  const SizedBox(height: 10),
                  _SummaryRow(
                    label: 'Entrées',
                    amount: income,
                    color: AppColors.revolutGreen,
                    icon: Icons.arrow_downward_rounded,
                    positive: true,
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Divider(color: context.pockii.border, height: 1),
                ),
                _SummaryRow(
                  label: 'Dépenses',
                  amount: spent,
                  color: AppColors.revolutAmber,
                  icon: Icons.trending_down_rounded,
                ),
                if (subscriptions > 0) ...[
                  const SizedBox(height: 10),
                  _SummaryRow(
                    label: 'Abonnements',
                    amount: subscriptions,
                    color: AppColors.revolutBlue,
                    icon: Icons.autorenew_rounded,
                  ),
                ],
                const SizedBox(height: 12),
                SmoothProgressBar(
                  value: spentRatio,
                  height: 4,
                  gradient: const LinearGradient(
                    colors: [AppColors.revolutAmber, AppColors.revolutRed],
                  ),
                ),

                // ── Needs / Wants / Savings breakdown ──
                if (allocation != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Divider(color: context.pockii.border, height: 1),
                  ),
                  _CategorySpendRow(
                    label: 'Besoins',
                    amount: allocation.needs.actualAmount,
                    target: allocation.needs.targetAmount,
                    color: AppColors.revolutBlue,
                    icon: Icons.home_rounded,
                  ),
                  const SizedBox(height: 10),
                  _CategorySpendRow(
                    label: 'Envies',
                    amount: allocation.wants.actualAmount,
                    target: allocation.wants.targetAmount,
                    color: AppColors.revolutAmber,
                    icon: Icons.shopping_bag_rounded,
                  ),
                  const SizedBox(height: 10),
                  _CategorySpendRow(
                    label: 'Épargne',
                    amount: allocation.savings.actualAmount,
                    target: allocation.savings.targetAmount,
                    color: AppColors.revolutGreen,
                    icon: Icons.savings_rounded,
                  ),
                ],

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Divider(color: context.pockii.border, height: 1),
                ),
                _SummaryRow(
                  label: 'Restant',
                  amount: remaining,
                  color: remaining >= 0
                      ? AppColors.revolutGreen
                      : AppColors.revolutRed,
                  icon: Icons.savings_rounded,
                  positive: remaining >= 0,
                ),

                // ── Voir l'historique ──
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.history),
                    icon: const Icon(Icons.receipt_long_rounded, size: 18),
                    label: const Text('Voir tout l\'historique'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.revolutBlue,
                      side: BorderSide(
                        color: AppColors.revolutBlue.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    this.positive = false,
  });

  final String label;
  final int amount;
  final Color color;
  final IconData icon;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: AppTypography.revolutBody.copyWith(
                color: context.pockii.onSurfaceMuted,
              ),
            ),
          ],
        ),
        Text(
          FcfaFormatter.formatCompact(amount.abs()),
          style: AppTypography.revolutSubtitle.copyWith(
            color: color,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _CategorySpendRow extends StatelessWidget {
  const _CategorySpendRow({
    required this.label,
    required this.amount,
    required this.target,
    required this.color,
    required this.icon,
  });

  final String label;
  final int amount;
  final int target;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (amount / target).clamp(0.0, 1.0) : 0.0;
    final isOver = amount > target;

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: AppTypography.revolutBody.copyWith(
                  color: context.pockii.onSurface,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              FcfaFormatter.formatCompact(amount),
              style: AppTypography.revolutLabel.copyWith(
                color: isOver ? AppColors.revolutRed : color,
                fontSize: 13,
              ),
            ),
            Text(
              ' / ${FcfaFormatter.formatCompact(target)}',
              style: AppTypography.revolutMicro.copyWith(
                color: context.pockii.onSurfaceMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SmoothProgressBar(
          value: progress,
          height: 3,
          foregroundColor: isOver ? AppColors.revolutRed : color,
          backgroundColor: color.withValues(alpha: 0.1),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Budget Rules Section (50/30/20)
// ─────────────────────────────────────────────────────────────

class _BudgetRulesSection extends ConsumerWidget {
  const _BudgetRulesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allocation = ref.watch(budgetAllocationProvider);

    // Don't show if not enabled or no data
    if (allocation == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RÉPARTITION 50/30/20',
            style: AppTypography.revolutMicro.copyWith(
              color: context.pockii.onSurfaceMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _BudgetCategoryTile(
                  categoryAllocation: allocation.needs,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BudgetCategoryTile(
                  categoryAllocation: allocation.wants,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BudgetCategoryTile(
                  categoryAllocation: allocation.savings,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetCategoryTile extends StatelessWidget {
  const _BudgetCategoryTile({required this.categoryAllocation});

  final CategoryAllocation categoryAllocation;

  @override
  Widget build(BuildContext context) {
    final category = categoryAllocation.category;
    final progress = categoryAllocation.progress.clamp(0.0, 1.0);
    final isOver = categoryAllocation.isOverBudget;
    final percentage = (categoryAllocation.progress * 100).clamp(0, 999).toInt();
    final color = isOver ? AppColors.revolutRed : category.color;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.pockii.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOver
              ? AppColors.revolutRed.withOpacity(0.3)
              : context.pockii.border,
        ),
      ),
      child: Column(
        children: [
          // Circular progress
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  backgroundColor: context.pockii.border,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
                Icon(category.icon, size: 18, color: color),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Category name
          Text(
            category.displayName,
            style: AppTypography.revolutMicro.copyWith(
              color: context.pockii.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // Percentage + remaining
          Text(
            '$percentage%',
            style: AppTypography.revolutMicro.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          Text(
            isOver
                ? '-${FcfaFormatter.formatCompact(-categoryAllocation.remaining)}'
                : '${FcfaFormatter.formatCompact(categoryAllocation.remaining)} rest.',
            style: AppTypography.revolutMicro.copyWith(
              color: isOver ? AppColors.revolutRed : context.pockii.onSurfaceMuted,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

