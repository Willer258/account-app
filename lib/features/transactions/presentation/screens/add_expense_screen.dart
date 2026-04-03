import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/utils/fcfa_formatter.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../../budget_rules/domain/enums/expense_category.dart';
import '../../../home/presentation/providers/budget_provider.dart';
import '../../data/transaction_repository.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/models/transaction_type.dart';

/// Full-screen add expense flow — Revolut-inspired design.
///
/// Features:
/// - Dark background with gradient accents
/// - Large numeric keypad with haptic feedback
/// - Animated amount display
/// - Category selection chips
/// - Budget impact preview
///
/// Covers: US-004 — Add Expense Flow
class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen>
    with SingleTickerProviderStateMixin {
  final _noteController = TextEditingController();
  String _amountStr = '';
  ExpenseCategory _selectedCategory = ExpenseCategory.needs;
  bool _isExpense = true;
  bool _isSubmitting = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  int get _amountFcfa => int.tryParse(_amountStr) ?? 0;

  void _onKey(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      if (key == '⌫') {
        if (_amountStr.isNotEmpty) {
          _amountStr = _amountStr.substring(0, _amountStr.length - 1);
        }
      } else if (key == '000') {
        if (_amountStr.isNotEmpty && _amountStr != '0') {
          _amountStr += '000';
        }
      } else {
        if (_amountStr == '0') return;
        if (_amountStr.length >= 9) return; // Max 9 digits
        _amountStr += key;
      }
    });
  }

  void _onSubmit() async {
    if (_amountFcfa <= 0) {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0);
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      final repo = ref.read(transactionRepositoryProvider);
      final now = DateTime.now();
      final tx = TransactionModel(
        id: 0,
        amountFcfa: _amountFcfa,
        type: _isExpense ? TransactionType.expense : TransactionType.income,
        category: _selectedCategory,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        date: now,
        createdAt: now,
      );
      await repo.createTransactionFromModel(tx);
      ref.invalidate(budgetStateProvider);

      if (mounted) {
        HapticFeedback.heavyImpact();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.revolutRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetState = ref.watch(budgetStateProvider);
    final remaining = budgetState.remainingBeforePlanned;
    final remainingAfter =
        remaining - (_isExpense ? _amountFcfa : -_amountFcfa);
    final impact = _amountFcfa > 0;

    return Scaffold(
      backgroundColor: AppColors.revolutDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.revolutSurfaceElevated,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.revolutOnDark,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TypeToggle(
                      isExpense: _isExpense,
                      onChanged: (val) => setState(() {
                        _isExpense = val;
                        HapticFeedback.selectionClick();
                      }),
                    ),
                  ),
                ],
              ),
            ),

            // ── Amount Display ────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Amount
                    AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(_shakeAnimation.value, 0),
                        child: child,
                      ),
                      child: Column(
                        children: [
                          Text(
                            _amountStr.isEmpty
                                ? '0'
                                : FcfaFormatter.formatCompact(
                                    int.parse(_amountStr),
                                  ),
                            style: AppTypography.revolutDisplay.copyWith(
                              color: _isExpense
                                  ? AppColors.revolutRed
                                  : AppColors.revolutGreen,
                              fontSize: 64,
                            ),
                          ),
                          Text(
                            'FCFA',
                            style: AppTypography.revolutSubtitle.copyWith(
                              color: AppColors.revolutOnDarkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Budget impact preview
                    if (impact && !budgetState.isLoading)
                      GlassmorphicCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        borderRadius: 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Après cette opération',
                              style: AppTypography.revolutMicro.copyWith(
                                color: AppColors.revolutOnDarkMuted,
                              ),
                            ),
                            Text(
                              FcfaFormatter.formatCompact(remainingAfter.abs()),
                              style: AppTypography.revolutLabel.copyWith(
                                color: remainingAfter >= 0
                                    ? AppColors.revolutGreen
                                    : AppColors.revolutRed,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Category chips
                    _CategorySelector(
                      selected: _selectedCategory,
                      isExpense: _isExpense,
                      onSelected: (cat) =>
                          setState(() => _selectedCategory = cat),
                    ),

                    const SizedBox(height: 12),

                    // Note field
                    TextField(
                      controller: _noteController,
                      style: AppTypography.revolutBody.copyWith(
                        color: AppColors.revolutOnDark,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Note (optionnel)',
                        hintStyle: AppTypography.revolutBody.copyWith(
                          color: AppColors.revolutOnDarkMuted,
                        ),
                        filled: true,
                        fillColor: AppColors.revolutSurfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.revolutBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.revolutBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.revolutBlue,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        prefixIcon: const Icon(
                          Icons.edit_note_rounded,
                          color: AppColors.revolutOnDarkMuted,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Numeric Keypad ────────────────────────────────
            _NumericKeypad(
              onKey: _onKey,
              onSubmit: _onSubmit,
              isSubmitting: _isSubmitting,
              canSubmit: _amountFcfa > 0,
              isExpense: _isExpense,
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Type Toggle (Expense / Income)
// ─────────────────────────────────────────────────────────────

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.isExpense, required this.onChanged});

  final bool isExpense;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.revolutSurfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.revolutBorder),
      ),
      child: Row(
        children: [
          _ToggleButton(
            label: 'Dépense',
            isActive: isExpense,
            activeColor: AppColors.revolutRed,
            onTap: () => onChanged(true),
          ),
          _ToggleButton(
            label: 'Revenu',
            isActive: !isExpense,
            activeColor: AppColors.revolutGreen,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: isActive
                ? Border.all(color: activeColor.withOpacity(0.5))
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.revolutLabel.copyWith(
              color: isActive ? activeColor : AppColors.revolutOnDarkMuted,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Category Selector
// ─────────────────────────────────────────────────────────────

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.selected,
    required this.isExpense,
    required this.onSelected,
  });

  final ExpenseCategory selected;
  final bool isExpense;
  final ValueChanged<ExpenseCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    final categories = ExpenseCategory.values;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final cat = categories[index];
          final isActive = cat == selected;

          return GestureDetector(
            onTap: () => onSelected(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.revolutBlue.withOpacity(0.15)
                    : AppColors.revolutSurfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? AppColors.revolutBlue
                      : AppColors.revolutBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat.icon,
                    size: 14,
                    color: isActive
                        ? AppColors.revolutBlue
                        : AppColors.revolutOnDarkMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat.displayName,
                    style: AppTypography.revolutMicro.copyWith(
                      color: isActive
                          ? AppColors.revolutBlue
                          : AppColors.revolutOnDarkMuted,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Numeric Keypad
// ─────────────────────────────────────────────────────────────

class _NumericKeypad extends StatelessWidget {
  const _NumericKeypad({
    required this.onKey,
    required this.onSubmit,
    required this.isSubmitting,
    required this.canSubmit,
    required this.isExpense,
  });

  final ValueChanged<String> onKey;
  final VoidCallback onSubmit;
  final bool isSubmitting;
  final bool canSubmit;
  final bool isExpense;

  static const _keys = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['000', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    final submitColor = isExpense
        ? AppColors.revolutRed
        : AppColors.revolutGreen;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ..._keys.map((row) {
            return Row(
              children: row.map((key) {
                if (key == '⌫') {
                  return _KeyButton(
                    key: ValueKey(key),
                    label: key,
                    icon: Icons.backspace_outlined,
                    onTap: () => onKey(key),
                    isDelete: true,
                  );
                }
                return _KeyButton(
                  key: ValueKey(key),
                  label: key,
                  onTap: () => onKey(key),
                );
              }).toList(),
            );
          }),
          const SizedBox(height: 8),
          // Submit button
          GestureDetector(
            onTap: canSubmit && !isSubmitting ? onSubmit : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 56,
              decoration: BoxDecoration(
                color: canSubmit ? submitColor : submitColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          AppColors.revolutOnDark,
                        ),
                      ),
                    )
                  : Text(
                      isExpense
                          ? 'Enregistrer la dépense'
                          : 'Enregistrer le revenu',
                      style: AppTypography.revolutLabel.copyWith(
                        color: AppColors.revolutOnDark,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    super.key,
    required this.label,
    this.icon,
    required this.onTap,
    this.isDelete = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isDelete;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isDelete
                ? AppColors.revolutSurfaceElevated
                : AppColors.revolutSurface,
            borderRadius: BorderRadius.circular(12),
            border: const Border.fromBorderSide(
              BorderSide(color: AppColors.revolutBorder, width: 1),
            ),
          ),
          alignment: Alignment.center,
          child: icon != null
              ? Icon(icon, color: AppColors.revolutOnDark, size: 22)
              : Text(
                  label,
                  style: AppTypography.revolutSubtitle.copyWith(
                    color: AppColors.revolutOnDark,
                    fontSize: 22,
                  ),
                ),
        ),
      ),
    );
  }
}
