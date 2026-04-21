import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Category data for expense categories.
class ExpenseCategory {
  const ExpenseCategory({
    required this.id,
    required this.label,
    required this.icon,
  });

  /// Category identifier (stored in database).
  final String id;

  /// Display label in French.
  final String label;

  /// Material icon for this category.
  final IconData icon;
}

/// Predefined expense categories.
const List<ExpenseCategory> expenseCategories = [
  ExpenseCategory(id: 'transport', label: 'Transport', icon: Icons.directions_car),
  ExpenseCategory(id: 'food', label: 'Repas', icon: Icons.restaurant),
  ExpenseCategory(id: 'leisure', label: 'Loisirs', icon: Icons.celebration),
  ExpenseCategory(id: 'family', label: 'Famille', icon: Icons.family_restroom),
  ExpenseCategory(id: 'subscriptions', label: 'Abonnements', icon: Icons.credit_card),
  ExpenseCategory(id: 'savings', label: 'Épargne', icon: Icons.savings),
  ExpenseCategory(id: 'other', label: 'Autre', icon: Icons.inventory_2),
];

/// Predefined income categories.
const List<ExpenseCategory> incomeCategories = [
  ExpenseCategory(id: 'salary', label: 'Salaire', icon: Icons.account_balance_wallet),
  ExpenseCategory(id: 'freelance', label: 'Freelance', icon: Icons.laptop_mac),
  ExpenseCategory(id: 'reimbursement', label: 'Remboursement', icon: Icons.receipt_long),
  ExpenseCategory(id: 'gift', label: 'Cadeau', icon: Icons.card_giftcard),
  ExpenseCategory(id: 'other', label: 'Autre', icon: Icons.more_horiz),
];

/// A horizontally scrollable row of category chips.
///
/// Allows single selection from predefined categories.
/// Supports both expense and income categories based on [isIncome].
/// Provides visual feedback with scale animation on selection.
class CategoryChipRow extends StatelessWidget {
  /// Creates a CategoryChipRow.
  const CategoryChipRow({
    required this.selectedCategory,
    required this.onCategorySelected,
    this.isIncome = false,
    super.key,
  });

  /// Currently selected category ID, or null if none selected.
  final String? selectedCategory;

  /// Callback when a category is selected.
  final ValueChanged<String> onCategorySelected;

  /// Whether to show income categories instead of expense categories.
  final bool isIncome;

  /// Returns the appropriate category list based on transaction type.
  List<ExpenseCategory> get _categories =>
      isIncome ? incomeCategories : expenseCategories;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = selectedCategory == category.id;
          return _CategoryChip(
            category: category,
            isSelected: isSelected,
            onTap: () => onCategorySelected(category.id),
          );
        },
      ),
    );
  }
}

/// Individual category chip with animation.
class _CategoryChip extends StatefulWidget {
  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final ExpenseCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.selectionClick();
    _controller.forward().then((_) {
      _controller.reverse();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected ? AppColors.revolutBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.revolutBlue
                  : AppColors.revolutBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.category.icon,
                size: 20,
                color: widget.isSelected
                    ? AppColors.revolutOnDark
                    : AppColors.revolutOnDarkMuted,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                widget.category.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: widget.isSelected
                      ? AppColors.revolutOnDark
                      : AppColors.revolutOnDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
