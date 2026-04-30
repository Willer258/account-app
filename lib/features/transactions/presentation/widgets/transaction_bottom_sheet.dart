import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/services/clock_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/utils/fcfa_formatter.dart';
import '../../../../shared/widgets/money_input_field.dart';
import '../../../budget_rules/domain/enums/expense_category.dart';
import '../../../budget_rules/presentation/providers/budget_rules_provider.dart';
import '../../../home/presentation/providers/budget_provider.dart';
import '../../../streaks/domain/services/streak_service.dart';
import '../../../streaks/presentation/providers/streak_provider.dart';
import '../../../streaks/presentation/widgets/milestone_celebration_dialog.dart';
import '../../data/transaction_repository.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/models/transaction_type.dart';
import '../providers/transaction_form_provider.dart';
import 'category_chip_row.dart';
import '../../../../shared/utils/money_input_formatter.dart';

/// A bottom sheet for adding or editing a transaction (expense or income).
///
/// Provides a quick 3-tap flow: FAB → Amount+Category → Submit.
/// Supports toggling between expense and income modes.
/// In edit mode, pre-fills with existing transaction data.
/// The form auto-disposes when closed, resetting state automatically.
class TransactionBottomSheet extends ConsumerStatefulWidget {
  /// Creates a TransactionBottomSheet.
  ///
  /// If [editTransaction] is provided, the sheet opens in edit mode
  /// with pre-filled data.
  const TransactionBottomSheet({
    this.editTransaction,
    super.key,
  });

  /// The transaction to edit, if in edit mode.
  final TransactionModel? editTransaction;

  /// Whether this sheet is in edit mode.
  bool get isEditMode => editTransaction != null;

  /// Shows the transaction bottom sheet for adding a new transaction.
  ///
  /// Returns when the sheet is dismissed.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.revolutSurfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const TransactionBottomSheet(),
    );
  }

  /// Shows the transaction bottom sheet for editing an existing transaction.
  ///
  /// Returns when the sheet is dismissed.
  static Future<void> showEdit(
    BuildContext context,
    TransactionModel transaction,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.revolutSurfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) =>
          TransactionBottomSheet(editTransaction: transaction),
    );
  }

  @override
  ConsumerState<TransactionBottomSheet> createState() =>
      _TransactionBottomSheetState();
}

class _TransactionBottomSheetState
    extends ConsumerState<TransactionBottomSheet> {
  final _noteController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isSubmitting = false;
  DateTime? _selectedDate;
  bool _addToEmergencyFund = true; // Default to adding savings to emergency fund

  @override
  void initState() {
    super.initState();
    // In edit mode, pre-fill the form with existing transaction data
    if (widget.isEditMode) {
      final tx = widget.editTransaction!;
      _noteController.text = tx.note ?? '';
      _amountController.text =
          tx.amountFcfa > 0 ? tx.amountFcfa.toString() : '';
      _selectedDate = tx.date;

      // Initialize the form provider with existing data after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final formNotifier = ref.read(transactionFormProvider.notifier);
        formNotifier.initializeForEdit(
          amountFcfa: tx.amountFcfa,
          category: tx.category,
          type: tx.type,
          note: tx.note,
        );
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    final formState = ref.read(transactionFormProvider);
    if (!formState.isValid) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get current date via clockProvider (ARCH-6)
      final clock = ref.read(clockProvider);
      final now = clock.now();

      // Default category to 'other' if not selected
      final category = formState.category ?? 'other';

      // Use selected date if set (for backdating), otherwise current time
      final transactionDate = _selectedDate ?? now;

      final repository = ref.read(transactionRepositoryProvider);

      StreakResult? streakResult;

      if (widget.isEditMode) {
        // Update existing transaction
        final updatedTransaction = widget.editTransaction!.copyWith(
          amountFcfa: formState.amountFcfa,
          category: category,
          type: formState.transactionType,
          note: formState.note,
          date: transactionDate,
        );
        await repository.updateTransaction(updatedTransaction);
      } else {
        // Create new transaction
        await repository.createTransaction(
          amountFcfa: formState.amountFcfa,
          category: category,
          type: formState.transactionType,
          note: formState.note,
          date: transactionDate,
        );

        // Record streak activity for new transactions (FR52)
        final streakService = ref.read(streakRecorderProvider);
        streakResult = await streakService.recordTransactionActivity();

        // Invalidate streak provider to refresh UI
        ref.invalidate(streakStatusProvider);

        // Add to emergency fund if savings category and checkbox is checked
        if (category == 'savings' && _addToEmergencyFund) {
          final emergencyFundSettings = ref.read(emergencyFundSettingsProvider);
          if (emergencyFundSettings.isEnabled) {
            await ref.read(emergencyFundSettingsProvider.notifier)
                .addToSavings(formState.amountFcfa);
          }
        }
      }

      // Refresh budget to reflect changes (NFR2: <100ms)
      await ref.read(budgetStateProvider.notifier).refresh();

      // Haptic feedback on success (UX-12)
      await HapticFeedback.mediumImpact();

      // Close bottom sheet
      if (mounted) {
        Navigator.of(context).pop();

        // Show success snackbar with appropriate message
        final String message;
        if (widget.isEditMode) {
          message = 'Transaction modifiée';
        } else {
          message = formState.isIncome ? 'Revenu ajouté' : 'Dépense ajoutée';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Show milestone celebration if reached (FR54)
        if (streakResult != null &&
            streakResult.isNewMilestone &&
            streakResult.milestoneReached != null) {
          // Small delay to let the snackbar appear first
          await Future<void>.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            await MilestoneCelebrationDialog.show(
              context,
              milestone: streakResult.milestoneReached!,
              currentStreak: streakResult.currentStreak,
            );
          }
        }
      }
    } on AppException catch (e) {
      // Show error snackbar for app-specific exceptions
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.message}'),
            backgroundColor: AppColors.revolutRed,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// Opens a date picker for backdating the transaction.
  Future<void> _selectDate() async {
    final clock = ref.read(clockProvider);
    final now = clock.now();

    // Allow backdating only within the current month
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: firstDayOfMonth,
      lastDate: now,
      helpText: 'Sélectionner une date',
      cancelText: 'Annuler',
      confirmText: 'OK',
    );

    if (picked != null) {
      setState(() {
        // Preserve the time from the original date or use current time
        final time = _selectedDate ?? now;
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(transactionFormProvider);
    final formNotifier = ref.read(transactionFormProvider.notifier);
    final isEditMode = widget.isEditMode;

    // Format selected date for display
    final dateFormat = DateFormat('dd/MM/yyyy');
    final displayDate = _selectedDate != null
        ? dateFormat.format(_selectedDate!)
        : "Aujourd'hui";

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ListView(
            controller: scrollController,
            children: [
              // Drag handle

              // Title with animated transition
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    isEditMode
                        ? (formState.isIncome
                            ? 'Modifier le revenu'
                            : 'Modifier la dépense')
                        : (formState.isIncome
                            ? 'Nouveau revenu'
                            : 'Nouvelle dépense'),
                    key: ValueKey('${formState.transactionType}_$isEditMode'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),

              // Transaction type toggle (expense/income)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment(
                      value: TransactionType.expense,
                      label: Text('Dépense'),
                      icon: Icon(Icons.remove_circle_outline),
                    ),
                    ButtonSegment(
                      value: TransactionType.income,
                      label: Text('Revenu'),
                      icon: Icon(Icons.add_circle_outline),
                    ),
                  ],
                  selected: {formState.transactionType},
                  onSelectionChanged: (selected) {
                    HapticFeedback.selectionClick();
                    formNotifier.setTransactionType(selected.first);
                  },
                  showSelectedIcon: false,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Amount input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.revolutSurfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: formState.showAmountError
                        ? Border.all(color: AppColors.revolutRed)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          inputFormatters: [MoneyInputFormatter()],
                          style: AppTypography.revolutTitle.copyWith(
                            color: AppColors.revolutOnDark,
                          ),
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.revolutOnDarkMuted.withOpacity(0.5),
                            ),
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            formNotifier.setAmount(MoneyInputFormatter.parse(value));
                          },
                        ),
                      ),
                      Text(
                        FcfaFormatter.symbol,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.revolutOnDarkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Quick amount chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final amount in const [500, 1000, 2000, 5000, 10000, 25000])
                      _QuickAmountChip(
                        amount: amount,
                        onTap: () {
                          _amountController.text = amount.toString();
                          formNotifier.setAmount(amount);
                          HapticFeedback.selectionClick();
                        },
                      ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Category chips (different categories for expense vs income)
              CategoryChipRow(
                selectedCategory: formState.category,
                onCategorySelected: formNotifier.setCategory,
                isIncome: formState.isIncome,
              ),

              // Budget category feedback (50/30/20)
              if (!formState.isIncome && formState.category != null)
                _BudgetCategoryFeedback(
                  category: formState.category!,
                  amount: formState.amountFcfa,
                ),

              // Emergency fund option for savings
              if (formState.category == 'savings')
                _EmergencyFundOption(
                  isChecked: _addToEmergencyFund,
                  onChanged: (value) {
                    setState(() {
                      _addToEmergencyFund = value ?? false;
                    });
                  },
                ),

              const SizedBox(height: AppSpacing.md),

              // Note field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (optionnel)',
                    hintText: 'Ajouter un commentaire...',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 200,
                  textInputAction: TextInputAction.done,
                  onChanged: formNotifier.setNote,
                ),
              ),

              // Date picker (for backdating)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: OutlinedButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    'Date: $displayDate',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Submit button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: FilledButton(
                  onPressed: formState.isValid && !_isSubmitting
                      ? _handleSubmit
                      : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppSpacing.touchTarget),
                    backgroundColor: AppColors.revolutBlue,
                    disabledBackgroundColor: AppColors.revolutBorder,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.revolutOnDark,
                          ),
                        )
                      : Text(
                          isEditMode ? 'Modifier' : 'Ajouter',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}


/// Widget for adding savings to emergency fund.
class _EmergencyFundOption extends ConsumerWidget {
  const _EmergencyFundOption({
    required this.isChecked,
    required this.onChanged,
  });

  final bool isChecked;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(emergencyFundSettingsProvider);

    // Only show if emergency fund is enabled
    if (!settings.isEnabled || settings.monthlySalary == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: InkWell(
        onTap: () => onChanged(!isChecked),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.revolutGreen.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.revolutGreen.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Checkbox(
                value: isChecked,
                onChanged: onChanged,
                activeColor: AppColors.revolutGreen,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.shield_rounded, size: 18, color: AppColors.revolutGreen),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ajouter au fonds d\'urgence',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${settings.monthsSaved.toStringAsFixed(1)}/${settings.targetMonths} mois épargnés',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.revolutOnDarkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget showing which 50/30/20 category this expense belongs to.
class _BudgetCategoryFeedback extends ConsumerWidget {
  const _BudgetCategoryFeedback({
    required this.category,
    required this.amount,
  });

  final String category;
  final int amount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(budgetRuleSettingsProvider);

    // Only show if 50/30/20 is enabled
    if (!settings.isEnabled) {
      return const SizedBox.shrink();
    }

    final allocation = ref.watch(budgetAllocationProvider);
    if (allocation == null) {
      return const SizedBox.shrink();
    }

    // Determine which budget category this transaction category belongs to
    final budgetCategory = DefaultCategoryMappings.guessCategory(category);
    final categoryAllocation = allocation.forCategory(budgetCategory);

    // Calculate what happens if we add this amount
    final currentSpent = categoryAllocation.actualAmount;
    final newTotal = currentSpent + amount;
    final target = categoryAllocation.targetAmount;
    final willExceed = newTotal > target;
    final remainingAfter = target - newTotal;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: willExceed
              ? AppColors.revolutRed.withOpacity(0.15)
              : budgetCategory.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: willExceed
                ? AppColors.revolutRed.withOpacity(0.3)
                : budgetCategory.color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Category icon
            Icon(
              budgetCategory.icon,
              size: 20,
              color: budgetCategory.color,
            ),
            const SizedBox(width: AppSpacing.sm),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    budgetCategory.displayName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: willExceed ? AppColors.revolutRed : budgetCategory.color,
                    ),
                  ),
                  Text(
                    willExceed
                        ? 'Dépassera le budget de ${FcfaFormatter.formatCompact(-remainingAfter)}'
                        : 'Reste après: ${FcfaFormatter.formatCompact(remainingAfter)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: willExceed
                          ? AppColors.revolutRed
                          : AppColors.revolutOnDarkMuted,
                    ),
                  ),
                ],
              ),
            ),
            // Progress indicator
            SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: (newTotal / target).clamp(0.0, 1.0),
                    strokeWidth: 4,
                    backgroundColor: AppColors.revolutBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      willExceed ? AppColors.revolutRed : budgetCategory.color,
                    ),
                  ),
                  Text(
                    '${((newTotal / target) * 100).clamp(0, 999).toInt()}%',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: willExceed ? AppColors.revolutRed : budgetCategory.color,
                    ),
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

/// Quick amount selection chip.
class _QuickAmountChip extends StatelessWidget {
  const _QuickAmountChip({
    required this.amount,
    required this.onTap,
  });

  final int amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = amount >= 1000 ? '${amount ~/ 1000}K' : amount.toString();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.revolutBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.revolutBlue.withOpacity(0.25)),
        ),
        child: Text(
          '$label F',
          style: AppTypography.revolutLabel.copyWith(
            color: AppColors.revolutBlue,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
