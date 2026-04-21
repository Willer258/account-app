import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/services/clock_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/pockii_colors.dart';
import '../../../../shared/utils/fcfa_formatter.dart';
import '../../../../shared/widgets/smooth_progress_bar.dart';
import '../../../budget_rules/presentation/providers/budget_rules_provider.dart';
import '../../../home/presentation/providers/budget_provider.dart';
import '../../../planned_expenses/domain/models/planned_expense_model.dart';
import '../../../planned_expenses/domain/services/planned_expense_conversion_service.dart';
import '../../../planned_expenses/presentation/dialogs/conversion_dialog.dart';
import '../../../planned_expenses/presentation/providers/planned_expenses_list_provider.dart';
import '../../../savings_projects/presentation/providers/savings_projects_provider.dart';
import '../../../subscriptions/presentation/providers/subscriptions_list_provider.dart';

/// Finances screen organized by user priority:
/// 1. Attention — urgent items
/// 2. Épargne — savings goals
/// 3. Prochaines dépenses — upcoming expenses
/// 4. Abonnements — recurring costs
class FinancesScreen extends ConsumerWidget {
  const FinancesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.pockii.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Text(
                  'Mes finances',
                  style: AppTypography.revolutTitle.copyWith(
                    color: context.pockii.onSurface,
                  ),
                ),
              ),
            ),

            // ── 1. Attention (urgent items) ───────────────────
            const SliverToBoxAdapter(child: _AttentionSection()),

            // ── 2. Épargne (savings goals) ────────────────────
            const SliverToBoxAdapter(child: _SavingsSection()),

            // ── 2b. Fonds d'urgence ──────────────────────────
            const SliverToBoxAdapter(child: _EmergencyFundSection()),

            // ── 3. Prochaines dépenses ────────────────────────
            const SliverToBoxAdapter(child: _UpcomingExpensesSection()),

            // ── 4. Abonnements ────────────────────────────────
            const SliverToBoxAdapter(child: _SubscriptionsSection()),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 1. ATTENTION — Urgent items that need action
// ═══════════════════════════════════════════════════════════════

class _AttentionSection extends ConsumerWidget {
  const _AttentionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(pendingPlannedExpensesProvider);
    final clock = ref.watch(clockProvider);
    final now = clock.now();

    return expensesAsync.when(
      data: (expenses) {
        // Filter for overdue or due today
        final urgent = expenses
            .where((e) => e.daysUntilDue(now) <= 0 && e.isPending)
            .toList();

        if (urgent.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...urgent.map((expense) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _UrgentBanner(expense: expense, now: now),
                  )),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _UrgentBanner extends ConsumerWidget {
  const _UrgentBanner({required this.expense, required this.now});

  final PlannedExpenseModel expense;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOverdue = expense.isOverdue(now);
    final color = isOverdue ? AppColors.revolutRed : AppColors.revolutAmber;
    final label = isOverdue
        ? 'En retard de ${-expense.daysUntilDue(now)} jour${-expense.daysUntilDue(now) > 1 ? 's' : ''}'
        : 'Aujourd\'hui';

    final banner = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            isOverdue ? Icons.warning_rounded : Icons.schedule_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.description,
                  style: AppTypography.revolutLabel.copyWith(
                    color: context.pockii.onSurface,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$label — ${FcfaFormatter.format(expense.amountFcfa)}',
                  style: AppTypography.revolutMicro.copyWith(
                    color: color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.swipe_right_rounded,
            color: AppColors.revolutGreen,
            size: 18,
          ),
        ],
      ),
    );

    return Dismissible(
      key: ValueKey('urgent_expense_${expense.id}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        await _markAsPaid(context, ref);
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppColors.revolutGreen,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              'Valider le paiement',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      child: banner,
    );
  }

  Future<void> _markAsPaid(BuildContext context, WidgetRef ref) async {
    final result = await ConversionDialog.show(context, expense);
    if (result == null || !result.confirmed) return;

    final conversionService = ref.read(plannedExpenseConversionServiceProvider);
    final clock = ref.read(clockProvider);

    final conversionResult = await conversionService.convertToTransaction(
      plannedExpenseId: expense.id,
      actualAmount: result.adjustedAmount,
      transactionDate: clock.now(),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            conversionResult.success
                ? 'Dépense validée'
                : conversionResult.errorMessage ?? 'Erreur',
          ),
          backgroundColor: conversionResult.success
              ? AppColors.revolutGreen
              : AppColors.revolutRed,
        ),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// 2. ÉPARGNE — Savings projects + emergency fund (horizontal)
// ═══════════════════════════════════════════════════════════════

class _SavingsSection extends ConsumerWidget {
  const _SavingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(activeProjectsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PROJETS D\'ÉPARGNE',
                style: AppTypography.revolutMicro.copyWith(
                  color: context.pockii.onSurfaceMuted,
                  letterSpacing: 1.2,
                ),
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.projects),
                child: Text(
                  'Tout voir',
                  style: AppTypography.revolutLabel.copyWith(
                    color: AppColors.revolutBlue,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 160,
          child: projectsAsync.when(
            data: (projects) {
              final items = <Widget>[];

              for (final project in projects) {
                items.add(_SavingsCard(
                  emoji: project.emoji ?? '💰',
                  name: project.name,
                  saved: project.currentAmountFcfa,
                  target: project.targetAmountFcfa,
                  progress: project.progress,
                  color: AppColors.revolutGreen,
                  onTap: () => context.push('/projects/${project.id}'),
                ));
              }

              items.add(_AddSavingsCard(
                onTap: () => context.push(AppRoutes.createProject),
              ));

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, index) => items[index],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.revolutBlue),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _SavingsCard extends StatelessWidget {
  const _SavingsCard({
    required this.emoji,
    required this.name,
    required this.saved,
    required this.target,
    required this.progress,
    required this.color,
    required this.onTap,
  });

  final String emoji;
  final String name;
  final int saved;
  final int target;
  final double progress;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 155,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.pockii.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 10),
            Text(
              name,
              style: AppTypography.revolutLabel.copyWith(
                color: context.pockii.onSurface,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                FcfaFormatter.formatCompact(saved),
                style: AppTypography.revolutSubtitle.copyWith(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            SmoothProgressBar(
              value: progress.clamp(0.0, 1.0),
              height: 4,
              foregroundColor: color,
              backgroundColor: context.pockii.border,
            ),
            const SizedBox(height: 4),
            Text(
              '${(progress * 100).round()}% de ${FcfaFormatter.formatCompact(target)}',
              style: AppTypography.revolutMicro.copyWith(
                color: context.pockii.onSurfaceMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddSavingsCard extends StatelessWidget {
  const _AddSavingsCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: context.pockii.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: context.pockii.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.revolutBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.revolutBlue,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nouveau\nprojet',
              textAlign: TextAlign.center,
              style: AppTypography.revolutMicro.copyWith(
                color: AppColors.revolutBlue,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 2b. FONDS D'URGENCE — Dedicated section
// ══════���════════════════════════════════════════════════════════

class _EmergencyFundSection extends ConsumerWidget {
  const _EmergencyFundSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(emergencyFundSettingsProvider);
    final budgetState = ref.watch(budgetStateProvider);

    final target = budgetState.totalBudget * settings.targetMonths;
    final progress = target > 0
        ? (settings.currentSavings / target).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FONDS D\'URGENCE',
            style: AppTypography.revolutMicro.copyWith(
              color: context.pockii.onSurfaceMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showEmergencyFundSheet(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.revolutPurple.withValues(alpha: 0.12),
                    context.pockii.surface,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.revolutPurple.withValues(alpha: 0.2),
                ),
              ),
              child: !settings.isEnabled
                  ? Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.revolutPurple.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.shield_rounded,
                            color: AppColors.revolutPurple,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Non configuré',
                                style: AppTypography.revolutLabel.copyWith(
                                  color: context.pockii.onSurface,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Protège-toi contre les imprévus',
                                style: AppTypography.revolutMicro.copyWith(
                                  color: context.pockii.onSurfaceMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Activer',
                          style: AppTypography.revolutLabel.copyWith(
                            color: AppColors.revolutPurple,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.revolutPurple.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.shield_rounded,
                                color: AppColors.revolutPurple,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    FcfaFormatter.format(settings.currentSavings),
                                    style: AppTypography.revolutSubtitle.copyWith(
                                      color: AppColors.revolutPurple,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    'Objectif: ${FcfaFormatter.formatCompact(target)} (${settings.targetMonths} mois)',
                                    style: AppTypography.revolutMicro.copyWith(
                                      color: context.pockii.onSurfaceMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${(progress * 100).round()}%',
                              style: AppTypography.revolutLabel.copyWith(
                                color: AppColors.revolutPurple,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SmoothProgressBar(
                          value: progress,
                          height: 6,
                          foregroundColor: AppColors.revolutPurple,
                          backgroundColor: context.pockii.border,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEmergencyFundSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.pockii.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _EmergencyFundBottomSheet(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 3. PROCHAINES DÉPENSES — Timeline of upcoming planned expenses
// ═══════════════════════════════════════════════════════════════

class _UpcomingExpensesSection extends ConsumerWidget {
  const _UpcomingExpensesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(pendingPlannedExpensesProvider);
    final clock = ref.watch(clockProvider);
    final now = clock.now();

    return expensesAsync.when(
      data: (expenses) {
        // Only future pending expenses (not overdue — those are in Attention)
        final upcoming = expenses
            .where((e) => e.daysUntilDue(now) > 0 && e.isPending)
            .toList()
          ..sort((a, b) => a.expectedDate.compareTo(b.expectedDate));

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PROCHAINES DÉPENSES',
                    style: AppTypography.revolutMicro.copyWith(
                      color: context.pockii.onSurfaceMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.plannedExpenses),
                    child: Text(
                      'Tout voir',
                      style: AppTypography.revolutLabel.copyWith(
                        color: AppColors.revolutBlue,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (upcoming.isEmpty)
                _EmptyCard(
                  icon: Icons.event_available_rounded,
                  text: 'Aucune dépense à venir',
                  actionText: 'Planifier',
                  onAction: () => context.push(AppRoutes.plannedExpenses),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: context.pockii.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.pockii.border),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < upcoming.take(3).length; i++) ...[
                        if (i > 0)
                          Divider(
                            color: context.pockii.border,
                            height: 1,
                            indent: 52,
                          ),
                        _ExpenseRow(
                          expense: upcoming[i],
                          now: now,
                        ),
                      ],
                      if (upcoming.length > 3)
                        GestureDetector(
                          onTap: () =>
                              context.push(AppRoutes.plannedExpenses),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              '+${upcoming.length - 3} autre${upcoming.length - 3 > 1 ? 's' : ''}',
                              style: AppTypography.revolutLabel.copyWith(
                                color: AppColors.revolutBlue,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ExpenseRow extends ConsumerWidget {
  const _ExpenseRow({required this.expense, required this.now});

  final PlannedExpenseModel expense;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = expense.daysUntilDue(now);
    final isUrgent = days <= 3;
    final dayColor = isUrgent ? AppColors.revolutAmber : context.pockii.onSurfaceMuted;

    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Days badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: dayColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$days',
                    style: AppTypography.revolutLabel.copyWith(
                      color: dayColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                  Text(
                    'j',
                    style: AppTypography.revolutMicro.copyWith(
                      color: dayColor,
                      fontSize: 9,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              expense.description,
              style: AppTypography.revolutBody.copyWith(
                color: context.pockii.onSurface,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            FcfaFormatter.formatCompact(expense.amountFcfa),
            style: AppTypography.revolutLabel.copyWith(
              color: context.pockii.onSurface,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );

    return Dismissible(
      key: ValueKey('finance_expense_${expense.id}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        await _markAsPaid(context, ref);
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppColors.revolutGreen,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 6),
            Text(
              'Payé',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      child: row,
    );
  }

  Future<void> _markAsPaid(BuildContext context, WidgetRef ref) async {
    final result = await ConversionDialog.show(context, expense);
    if (result == null || !result.confirmed) return;

    final conversionService = ref.read(plannedExpenseConversionServiceProvider);
    final clock = ref.read(clockProvider);

    final conversionResult = await conversionService.convertToTransaction(
      plannedExpenseId: expense.id,
      actualAmount: result.adjustedAmount,
      transactionDate: clock.now(),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            conversionResult.success
                ? 'Dépense validée'
                : conversionResult.errorMessage ?? 'Erreur',
          ),
          backgroundColor: conversionResult.success
              ? AppColors.revolutGreen
              : AppColors.revolutRed,
        ),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// 4. ABONNEMENTS — Recurring costs summary
// ═══════════════════════════════════════════════════════════════

class _SubscriptionsSection extends ConsumerWidget {
  const _SubscriptionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(activeSubscriptionsProvider);
    final totalAsync = ref.watch(totalMonthlyAmountProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ABONNEMENTS',
                style: AppTypography.revolutMicro.copyWith(
                  color: context.pockii.onSurfaceMuted,
                  letterSpacing: 1.2,
                ),
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.subscriptions),
                child: Text(
                  'Gérer',
                  style: AppTypography.revolutLabel.copyWith(
                    color: AppColors.revolutBlue,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          subscriptionsAsync.when(
            data: (subscriptions) {
              final total = totalAsync.valueOrNull ?? 0;

              if (subscriptions.isEmpty) {
                return _EmptyCard(
                  icon: Icons.repeat_rounded,
                  text: 'Aucun abonnement',
                  actionText: 'Ajouter',
                  onAction: () => context.push(AppRoutes.subscriptions),
                );
              }

              return GestureDetector(
                onTap: () => context.push(AppRoutes.subscriptions),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.pockii.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.pockii.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.revolutBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.repeat_rounded,
                          color: AppColors.revolutBlue,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${subscriptions.length} abonnement${subscriptions.length > 1 ? 's' : ''}',
                              style: AppTypography.revolutLabel.copyWith(
                                color: context.pockii.onSurface,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${FcfaFormatter.format(total)} / mois',
                              style: AppTypography.revolutMicro.copyWith(
                                color: AppColors.revolutBlue,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: context.pockii.onSurfaceMuted,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Shared Components
// ═══════════════════════════════════════════════════════════════

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.text,
    required this.actionText,
    required this.onAction,
  });

  final IconData icon;
  final String text;
  final String actionText;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAction,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.pockii.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.pockii.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: context.pockii.onSurfaceMuted, size: 28),
            const SizedBox(height: 8),
            Text(
              text,
              style: AppTypography.revolutBody.copyWith(
                color: context.pockii.onSurfaceMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              actionText,
              style: AppTypography.revolutLabel.copyWith(
                color: AppColors.revolutBlue,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Emergency Fund Bottom Sheet
// ═══════════════════════════════════════════════════════════════

class _EmergencyFundBottomSheet extends ConsumerStatefulWidget {
  const _EmergencyFundBottomSheet();

  @override
  ConsumerState<_EmergencyFundBottomSheet> createState() =>
      _EmergencyFundBottomSheetState();
}

class _EmergencyFundBottomSheetState
    extends ConsumerState<_EmergencyFundBottomSheet> {
  int _targetMonths = 6;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(emergencyFundSettingsProvider);
    _targetMonths = settings.targetMonths;
    _syncFromBudget();
  }

  void _syncFromBudget() {
    final budgetState = ref.read(budgetStateProvider);
    final allocation = ref.read(budgetAllocationProvider);
    final notifier = ref.read(emergencyFundSettingsProvider.notifier);

    if (budgetState.totalBudget > 0) {
      notifier.setMonthlySalary(budgetState.totalBudget);
    }
    if (allocation != null && allocation.savings.actualAmount > 0) {
      notifier.updateCurrentSavings(allocation.savings.actualAmount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(emergencyFundSettingsProvider);
    final budgetState = ref.watch(budgetStateProvider);
    final allocation = ref.watch(budgetAllocationProvider);

    final salary = budgetState.totalBudget;
    final savingsAmount = allocation?.savings.actualAmount ?? 0;
    final savingsTarget = allocation?.savings.targetAmount ?? 0;
    final target = salary * _targetMonths;
    final progress = target > 0
        ? (settings.currentSavings / target).clamp(0.0, 1.0)
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          const SizedBox(height: 20),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.revolutPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: AppColors.revolutPurple,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Fonds d\'urgence',
                style: AppTypography.revolutSubtitle.copyWith(
                  color: context.pockii.onSurface,
                ),
              ),
              const Spacer(),
              Switch.adaptive(
                value: settings.isEnabled,
                onChanged: (_) {
                  ref
                      .read(emergencyFundSettingsProvider.notifier)
                      .toggleEnabled();
                  if (!settings.isEnabled) _syncFromBudget();
                },
                activeColor: AppColors.revolutPurple,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Protège-toi contre les imprévus avec une réserve de plusieurs mois de budget.',
            style: AppTypography.revolutMicro.copyWith(
              color: context.pockii.onSurfaceMuted,
              fontSize: 12,
            ),
          ),

          if (settings.isEnabled) ...[
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.pockii.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        FcfaFormatter.format(settings.currentSavings),
                        style: AppTypography.revolutLabel.copyWith(
                          color: AppColors.revolutPurple,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${(progress * 100).round()}%',
                        style: AppTypography.revolutLabel.copyWith(
                          color: AppColors.revolutPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SmoothProgressBar(
                    value: progress,
                    height: 8,
                    foregroundColor: AppColors.revolutPurple,
                    backgroundColor: context.pockii.border,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'sur ${FcfaFormatter.format(target)}',
                      style: AppTypography.revolutMicro.copyWith(
                        color: context.pockii.onSurfaceMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Divider(color: context.pockii.border, height: 1),
                  const SizedBox(height: 14),
                  _InfoRow(
                    label: 'Budget mensuel',
                    value: FcfaFormatter.format(salary),
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppColors.revolutBlue,
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: 'Épargne ce mois',
                    value: '${FcfaFormatter.format(savingsAmount)} / ${FcfaFormatter.format(savingsTarget)}',
                    icon: Icons.savings_rounded,
                    color: AppColors.revolutGreen,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Objectif',
                  style: AppTypography.revolutLabel.copyWith(
                    color: context.pockii.onSurface,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$_targetMonths mois',
                  style: AppTypography.revolutLabel.copyWith(
                    color: AppColors.revolutPurple,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Slider(
              value: _targetMonths.toDouble(),
              min: 3,
              max: 12,
              divisions: 9,
              activeColor: AppColors.revolutPurple,
              inactiveColor: context.pockii.border,
              onChanged: (value) {
                setState(() => _targetMonths = value.round());
                ref
                    .read(emergencyFundSettingsProvider.notifier)
                    .setTargetMonths(_targetMonths);
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.revolutPurple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      settings.motivationalTip,
                      style: AppTypography.revolutMicro.copyWith(
                        color: AppColors.revolutPurple,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTypography.revolutMicro.copyWith(
              color: context.pockii.onSurfaceMuted,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.revolutLabel.copyWith(
            color: context.pockii.onSurface,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
