import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/utils/fcfa_formatter.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../../../shared/widgets/smooth_progress_bar.dart';
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
      backgroundColor: AppColors.revolutDark,
      body: CustomScrollView(
        slivers: [
          // ── Hero Section ──────────────────────────────────────
          SliverToBoxAdapter(
            child: _HeroSection(
              budgetState: budgetState,
              monthLabel: monthLabel,
            ),
          ),

          // ── Quick Actions ─────────────────────────────────────
          const SliverToBoxAdapter(child: _QuickActionsRow()),

          // ── Spending Summary ──────────────────────────────────
          SliverToBoxAdapter(
            child: _SpendingSummarySection(budgetState: budgetState),
          ),

          // ── Bottom padding ────────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
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
    final formattedAmount = FcfaFormatter.formatCompact(remaining.abs());
    final prefix = isNegative ? '-' : '';
    final progress = budgetState.percentageRemaining.clamp(0.0, 1.0);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.revolutHeroGradient,
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
                          color: AppColors.revolutOnDarkMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        monthLabel,
                        style: AppTypography.revolutSubtitle.copyWith(
                          color: AppColors.revolutOnDark,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.revolutSurfaceElevated,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: AppColors.revolutBorder),
                        ),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.revolutOnDarkMuted,
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
                  color: AppColors.revolutOnDarkMuted,
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
                    color: AppColors.revolutBorder,
                    borderRadius: BorderRadius.circular(8),
                  ),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$prefix$formattedAmount',
                      style: AppTypography.revolutDisplay.copyWith(
                        color: amountColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'FCFA',
                      style: AppTypography.revolutSubtitle.copyWith(
                        color: AppColors.revolutOnDarkMuted,
                      ),
                    ),
                  ],
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
                  backgroundColor: AppColors.glassOverlay,
                ),

              if (!budgetState.isLoading) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dépensé: ${FcfaFormatter.formatCompact(budgetState.totalBudget - budgetState.remainingBeforePlanned)}',
                      style: AppTypography.revolutMicro.copyWith(
                        color: AppColors.revolutOnDarkMuted,
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}% restant',
                      style: AppTypography.revolutMicro.copyWith(
                        color: AppColors.revolutOnDark,
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
// Quick Actions Row
// ─────────────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _QuickActionButton(
            icon: Icons.add_rounded,
            label: 'Ajouter',
            color: AppColors.revolutBlue,
            onTap: () {},
          ),
          _QuickActionButton(
            icon: Icons.bar_chart_rounded,
            label: 'Analyses',
            color: AppColors.revolutPurple,
            onTap: () {},
          ),
          _QuickActionButton(
            icon: Icons.receipt_long_rounded,
            label: 'Dépenses',
            color: AppColors.revolutGreen,
            onTap: () {},
          ),
          _QuickActionButton(
            icon: Icons.settings_outlined,
            label: 'Réglages',
            color: AppColors.revolutOnDarkMuted,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
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
// Spending Summary Section
// ─────────────────────────────────────────────────────────────

class _SpendingSummarySection extends StatelessWidget {
  const _SpendingSummarySection({required this.budgetState});

  final BudgetState budgetState;

  @override
  Widget build(BuildContext context) {
    if (budgetState.isLoading) return const SizedBox.shrink();

    final total = budgetState.totalBudget;
    final remaining = budgetState.remainingBeforePlanned;
    final spent = total - remaining;
    final double spentRatio = total > 0 ? (spent / total).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RÉSUMÉ DU MOIS',
            style: AppTypography.revolutMicro.copyWith(
              color: AppColors.revolutOnDarkMuted,
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
                  color: AppColors.revolutOnDark,
                  icon: Icons.account_balance_wallet_rounded,
                  positive: true,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(color: AppColors.revolutBorder, height: 1),
                ),
                _SummaryRow(
                  label: 'Dépensé',
                  amount: spent.abs(),
                  color: AppColors.revolutAmber,
                  icon: Icons.trending_down_rounded,
                ),
                const SizedBox(height: 12),
                SmoothProgressBar(
                  value: spentRatio,
                  height: 4,
                  gradient: const LinearGradient(
                    colors: [AppColors.revolutAmber, AppColors.revolutRed],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(color: AppColors.revolutBorder, height: 1),
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
                color: AppColors.revolutOnDarkMuted,
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
