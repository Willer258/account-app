import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'animations/battery_animation.dart';
import 'animations/cat_animation.dart';
import 'animations/planet_animation.dart';
import 'animations/tree_animation.dart';
import 'animations/water_tank_animation.dart';
import 'budget_animation_type.dart';

/// Provider for the selected budget animation type.
final budgetAnimationTypeProvider = StateProvider<BudgetAnimationType>((ref) {
  return BudgetAnimationType.cat;
});

/// Main widget that displays the selected budget animation.
class BudgetAnimationWidget extends ConsumerWidget {
  const BudgetAnimationWidget({
    required this.percentage,
    this.size = 150,
    super.key,
  });

  /// Budget percentage (0.0 to 1.0).
  final double percentage;

  /// Size of the animation widget.
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animationType = ref.watch(budgetAnimationTypeProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: _buildAnimation(animationType),
    );
  }

  Widget _buildAnimation(BudgetAnimationType type) {
    switch (type) {
      case BudgetAnimationType.cat:
        return CatAnimation(
          key: const ValueKey('cat'),
          percentage: percentage,
          size: size,
        );
      case BudgetAnimationType.waterTank:
        return WaterTankAnimation(
          key: const ValueKey('waterTank'),
          percentage: percentage,
          size: size,
        );
      case BudgetAnimationType.battery:
        return BatteryAnimation(
          key: const ValueKey('battery'),
          percentage: percentage,
          size: size,
        );
      case BudgetAnimationType.planet:
        return PlanetAnimation(
          key: const ValueKey('planet'),
          percentage: percentage,
          size: size,
        );
      case BudgetAnimationType.tree:
        return TreeAnimation(
          key: const ValueKey('tree'),
          percentage: percentage,
          size: size,
        );
    }
  }
}

/// Widget for selecting budget animation type in settings.
/// Compact design with small circular icon buttons.
class BudgetAnimationSelector extends ConsumerWidget {
  const BudgetAnimationSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = ref.watch(budgetAnimationTypeProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Style d\'animation',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Icon buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: BudgetAnimationType.values.map((type) {
              final isSelected = type == selectedType;
              return _AnimationIconButton(
                type: type,
                isSelected: isSelected,
                onTap: () {
                  ref.read(budgetAnimationTypeProvider.notifier).state = type;
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Selected animation name
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                selectedType.displayName,
                key: ValueKey(selectedType),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact circular icon button for animation type selection.
class _AnimationIconButton extends StatelessWidget {
  const _AnimationIconButton({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  final BudgetAnimationType type;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: AnimatedScale(
            duration: const Duration(milliseconds: 200),
            scale: isSelected ? 1.1 : 1.0,
            child: Icon(
              type.icon,
              size: isSelected ? 24 : 22,
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
