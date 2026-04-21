import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Category data for subscription categories.
class SubscriptionCategory {
  const SubscriptionCategory({
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

/// Predefined subscription categories.
///
/// These are specific to recurring expenses like subscriptions,
/// tontines, and family obligations (as per PRD FR24).
const List<SubscriptionCategory> subscriptionCategories = [
  SubscriptionCategory(
    id: 'entertainment',
    label: 'Divertissement',
    icon: Icons.movie_outlined,
  ),
  SubscriptionCategory(
    id: 'utilities',
    label: 'Services',
    icon: Icons.electrical_services,
  ),
  SubscriptionCategory(
    id: 'tontine',
    label: 'Tontine',
    icon: Icons.groups,
  ),
  SubscriptionCategory(
    id: 'family',
    label: 'Famille',
    icon: Icons.family_restroom,
  ),
  SubscriptionCategory(
    id: 'insurance',
    label: 'Assurance',
    icon: Icons.shield_outlined,
  ),
  SubscriptionCategory(
    id: 'other',
    label: 'Autre',
    icon: Icons.more_horiz,
  ),
];

/// A horizontally scrollable row of subscription category chips.
///
/// Allows single selection from predefined subscription categories.
/// Provides visual feedback with scale animation on selection.
class SubscriptionCategoryRow extends StatelessWidget {
  /// Creates a SubscriptionCategoryRow.
  const SubscriptionCategoryRow({
    required this.selectedCategory,
    required this.onCategorySelected,
    super.key,
  });

  /// Currently selected category ID, or null if none selected.
  final String? selectedCategory;

  /// Callback when a category is selected.
  final ValueChanged<String> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: subscriptionCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final category = subscriptionCategories[index];
          final isSelected = selectedCategory == category.id;
          return _SubscriptionCategoryChip(
            category: category,
            isSelected: isSelected,
            onTap: () => onCategorySelected(category.id),
          );
        },
      ),
    );
  }
}

/// Individual subscription category chip with animation.
class _SubscriptionCategoryChip extends StatefulWidget {
  const _SubscriptionCategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final SubscriptionCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_SubscriptionCategoryChip> createState() =>
      _SubscriptionCategoryChipState();
}

class _SubscriptionCategoryChipState extends State<_SubscriptionCategoryChip>
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
                    ? AppColors.onPrimary
                    : AppColors.revolutOnDarkMuted,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                widget.category.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: widget.isSelected
                      ? AppColors.onPrimary
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
