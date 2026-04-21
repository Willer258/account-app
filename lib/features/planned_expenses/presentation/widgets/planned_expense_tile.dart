import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/clock_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/budget_colors.dart';
import '../../../../shared/utils/fcfa_formatter.dart';
import '../../domain/models/planned_expense_model.dart';
import '../../domain/models/planned_expense_status.dart';

/// A list tile displaying planned expense information.
///
/// Shows description, amount, expected date, and days until due.
/// Completed expenses are displayed with reduced opacity.
class PlannedExpenseTile extends ConsumerWidget {
  /// Creates a PlannedExpenseTile.
  const PlannedExpenseTile({
    required this.expense,
    this.onTap,
    this.onMarkAsPaid,
    this.onCancel,
    super.key,
  });

  /// The planned expense to display.
  final PlannedExpenseModel expense;

  /// Callback when the tile is tapped.
  final VoidCallback? onTap;

  /// Callback when "Mark as paid" is tapped.
  final VoidCallback? onMarkAsPaid;

  /// Callback when "Cancel" is tapped.
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clock = ref.watch(clockProvider);
    final now = clock.now();
    final daysUntil = expense.daysUntilDue(now);
    final isCompleted = !expense.isPending;

    final tile = Opacity(
      opacity: isCompleted ? 0.5 : 1.0,
      child: ListTile(
        onTap: onTap,
        leading: _LeadingIcon(
          expense: expense,
          daysUntil: daysUntil,
          isCompleted: isCompleted,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                expense.description,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isCompleted)
              _StatusBadge(status: expense.status),
          ],
        ),
        subtitle: _DaysUntilLabel(
          daysUntil: daysUntil,
          isCompleted: isCompleted,
          status: expense.status,
        ),
        trailing: Text(
          FcfaFormatter.format(expense.amountFcfa),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isCompleted
                ? AppColors.revolutOnDarkMuted
                : AppColors.revolutOnDark,
          ),
        ),
      ),
    );

    // No swipe actions for completed expenses
    if (isCompleted || (onMarkAsPaid == null && onCancel == null)) {
      return tile;
    }

    return Dismissible(
      key: ValueKey('expense_${expense.id}'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd && onMarkAsPaid != null) {
          onMarkAsPaid!();
          return false; // Don't remove — dialog handles it
        } else if (direction == DismissDirection.endToStart &&
            onCancel != null) {
          onCancel!();
          return false; // Don't remove — dialog handles it
        }
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        color: AppColors.revolutGreen,
        child: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Payé',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppColors.revolutRed,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Annuler',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.cancel_rounded, color: Colors.white, size: 24),
          ],
        ),
      ),
      child: tile,
    );
  }
}

/// Leading icon with color based on urgency.
class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({
    required this.expense,
    required this.daysUntil,
    required this.isCompleted,
  });

  final PlannedExpenseModel expense;
  final int daysUntil;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color iconColor;
    IconData icon;

    if (isCompleted) {
      backgroundColor = AppColors.revolutBorder;
      iconColor = AppColors.revolutOnDarkMuted;
      icon = expense.isConverted ? Icons.check_circle : Icons.cancel;
    } else if (daysUntil < 0) {
      // Overdue
      backgroundColor = AppColors.revolutRed.withValues(alpha: 0.1);
      iconColor = AppColors.revolutRed;
      icon = Icons.warning;
    } else if (daysUntil <= 3) {
      // Soon (within 3 days)
      backgroundColor = BudgetColors.warning.withValues(alpha: 0.1);
      iconColor = BudgetColors.warning;
      icon = Icons.schedule;
    } else {
      // Normal
      backgroundColor = AppColors.revolutBlue.withValues(alpha: 0.1);
      iconColor = AppColors.revolutBlue;
      icon = Icons.event;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: iconColor),
    );
  }
}

/// Status badge for completed/postponed expenses.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final PlannedExpenseStatus status;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case PlannedExpenseStatus.converted:
        backgroundColor = AppColors.revolutGreen.withValues(alpha: 0.1);
        textColor = AppColors.revolutGreen;
      case PlannedExpenseStatus.postponed:
        backgroundColor = BudgetColors.warning.withValues(alpha: 0.1);
        textColor = BudgetColors.warning;
      case PlannedExpenseStatus.cancelled:
      case PlannedExpenseStatus.pending:
        backgroundColor = AppColors.revolutBorder;
        textColor = AppColors.revolutOnDarkMuted;
    }

    return Container(
      margin: const EdgeInsets.only(left: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 10,
          color: textColor,
        ),
      ),
    );
  }
}

/// Label showing days until due.
class _DaysUntilLabel extends StatelessWidget {
  const _DaysUntilLabel({
    required this.daysUntil,
    required this.isCompleted,
    required this.status,
  });

  final int daysUntil;
  final bool isCompleted;
  final PlannedExpenseStatus status;

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;

    if (isCompleted) {
      switch (status) {
        case PlannedExpenseStatus.converted:
          text = 'Payé';
          color = AppColors.revolutOnDarkMuted;
        case PlannedExpenseStatus.cancelled:
          text = 'Annulé';
          color = AppColors.revolutOnDarkMuted;
        case PlannedExpenseStatus.postponed:
          text = 'Reporté';
          color = BudgetColors.warning;
        case PlannedExpenseStatus.pending:
          text = '';
          color = AppColors.revolutOnDarkMuted;
      }
    } else if (daysUntil < 0) {
      text = 'En retard de ${-daysUntil} jour${-daysUntil > 1 ? 's' : ''}';
      color = AppColors.revolutRed;
    } else if (daysUntil == 0) {
      text = 'Aujourd\'hui';
      color = BudgetColors.warning;
    } else if (daysUntil == 1) {
      text = 'Demain';
      color = BudgetColors.warning;
    } else if (daysUntil <= 7) {
      text = 'Dans $daysUntil jours';
      color = BudgetColors.warning;
    } else {
      text = 'Dans $daysUntil jours';
      color = AppColors.revolutOnDarkMuted;
    }

    return Text(
      text,
      style: TextStyle(color: color),
    );
  }
}

