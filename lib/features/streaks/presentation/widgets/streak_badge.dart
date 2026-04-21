import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/streak_celebration_tracker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../budget_rules/domain/models/budget_allocation.dart';
import '../../../budget_rules/presentation/providers/budget_rules_provider.dart';
import '../../domain/services/streak_service.dart';
import '../providers/streak_provider.dart';

/// Badge displaying the user's current streak.
///
/// Shows "🔥 X jours" with a pulse animation when streak > 0.
/// When streak is 0, shows muted styling with a helpful tooltip.
/// Tapping the badge shows streak details dialog.
/// Also checks for pending milestone celebrations and shows celebration dialog.
///
/// Covers: FR53 (view current streak count), FR54 (streak celebration), UX-8
class StreakBadge extends ConsumerStatefulWidget {
  const StreakBadge({super.key});

  @override
  ConsumerState<StreakBadge> createState() => _StreakBadgeState();
}

class _StreakBadgeState extends ConsumerState<StreakBadge> {
  bool _celebrationShown = false;

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(streakStatusProvider);
    final pendingCelebrationAsync = ref.watch(pendingCelebrationProvider);

    // Check for pending celebration
    pendingCelebrationAsync.whenData((milestone) {
      if (milestone != null && !_celebrationShown && mounted) {
        _celebrationShown = true;
        // Show celebration dialog after the frame is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showCelebrationDialog(context, milestone);
          }
        });
      }
    });

    return statusAsync.when(
      data: (status) => _StreakBadgeContent(status: status),
      loading: () => const _StreakBadgePlaceholder(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showCelebrationDialog(BuildContext context, int milestone) {
    final clearCelebration = ref.read(clearPendingCelebrationProvider);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _StreakCelebrationDialog(
        milestone: milestone,
        onDismiss: () {
          Navigator.of(context).pop();
          clearCelebration();
        },
      ),
    );
  }
}

/// Content of the streak badge when data is available.
class _StreakBadgeContent extends StatefulWidget {
  const _StreakBadgeContent({required this.status});

  final StreakStatus status;

  @override
  State<_StreakBadgeContent> createState() => _StreakBadgeContentState();
}

class _StreakBadgeContentState extends State<_StreakBadgeContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 1, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Only animate when streak > 0
    if (widget.status.currentStreak > 0) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_StreakBadgeContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update animation state when streak changes
    if (widget.status.currentStreak > 0 && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (widget.status.currentStreak == 0 &&
        _pulseController.isAnimating) {
      _pulseController
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasStreak = widget.status.currentStreak > 0;
    final streakCount = widget.status.currentStreak == 1
        ? '1 jour'
        : '${widget.status.currentStreak} jours';

    Widget badge = GestureDetector(
      onTap: () => _showStreakDetails(context),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: hasStreak ? _pulseAnimation.value : 1.0,
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: hasStreak
                ? AppColors.revolutAmber.withOpacity(0.15)
                : AppColors.revolutSurfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasStreak
                  ? AppColors.revolutAmber.withOpacity(0.3)
                  : AppColors.revolutBorder,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                size: 16,
                color: hasStreak
                    ? AppColors.revolutAmber
                    : AppColors.revolutOnDarkMuted,
              ),
              const SizedBox(width: 4),
              Text(
                streakCount,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: hasStreak
                      ? AppColors.revolutAmber
                      : AppColors.revolutOnDarkMuted,
                ),
              ),
              if (!hasStreak) ...[
                const SizedBox(width: AppSpacing.xs),
                const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: AppColors.revolutOnDarkMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    // Add tooltip for zero streak
    if (!hasStreak) {
      badge = Tooltip(
        message: 'Ajoute une dépense pour démarrer',
        child: badge,
      );
    }

    return badge;
  }

  void _showStreakDetails(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => StreakDetailsDialog(status: widget.status),
    );
  }
}

/// Placeholder shown while loading streak data.
class _StreakBadgePlaceholder extends StatelessWidget {
  const _StreakBadgePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.revolutSurfaceElevated,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 60,
            height: 14,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.revolutBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog showing streak details.
class StreakDetailsDialog extends ConsumerWidget {
  const StreakDetailsDialog({
    required this.status,
    super.key,
  });

  final StreakStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allocation = ref.watch(budgetAllocationProvider);
    final budgetRuleSettings = ref.watch(budgetRuleSettingsProvider);

    // Determine budget health
    final bool isBudgetHealthy = allocation != null && !allocation.hasOverspending;
    final bool showBudgetStatus = budgetRuleSettings.isEnabled && allocation != null;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.local_fire_department_rounded, size: 28, color: AppColors.revolutAmber),
          const SizedBox(width: AppSpacing.sm),
          const Text('Ta série'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DetailRow(
            label: 'Série actuelle',
            value: _formatDays(status.currentStreak),
            isHighlighted: true,
          ),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(
            label: 'Meilleure série',
            value: _formatDays(status.longestStreak),
            isHighlighted: false,
          ),

          // Budget health indicator (50/30/20)
          if (showBudgetStatus) ...[
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            _BudgetHealthRow(
              isHealthy: isBudgetHealthy,
              allocation: allocation,
            ),
          ],

          const SizedBox(height: AppSpacing.lg),
          if (status.currentStreak == 0)
            const _InfoCard(
              icon: Icons.lightbulb_outline,
              message: 'Ajoute une transaction aujourd\'hui pour commencer une nouvelle série!',
              color: AppColors.revolutBlue,
            )
          else if (!status.hasActivityToday && status.streakIsActive)
            const _InfoCard(
              icon: Icons.warning_amber_outlined,
              message: 'N\'oublie pas de logger une transaction aujourd\'hui pour maintenir ta série!',
              color: AppColors.revolutAmber,
            )
          else if (status.hasActivityToday)
            _InfoCard(
              icon: isBudgetHealthy ? Icons.star : Icons.check_circle_outline,
              message: isBudgetHealthy
                  ? 'Excellent! Tu respectes ton budget 50/30/20. Continue comme ça!'
                  : 'Super! Tu as déjà logé une transaction aujourd\'hui. Reviens demain!',
              color: isBudgetHealthy ? AppColors.revolutAmber : AppColors.revolutGreen,
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  String _formatDays(int days) {
    if (days == 0) return '0 jour';
    if (days == 1) return '1 jour';
    return '$days jours';
  }
}

/// Row displaying a streak statistic.
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.isHighlighted,
  });

  final String label;
  final String value;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.revolutOnDarkMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
            color: isHighlighted ? AppColors.revolutBlue : AppColors.revolutOnDark,
          ),
        ),
      ],
    );
  }
}

/// Info card with icon and message.
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Row showing budget health status (50/30/20 compliance).
class _BudgetHealthRow extends StatelessWidget {
  const _BudgetHealthRow({
    required this.isHealthy,
    required this.allocation,
  });

  final bool isHealthy;
  final BudgetAllocation? allocation;

  @override
  Widget build(BuildContext context) {
    if (allocation == null) return const SizedBox.shrink();

    final needsProgress = (allocation!.needs.progress * 100).clamp(0, 200).toInt();
    final wantsProgress = (allocation!.wants.progress * 100).clamp(0, 200).toInt();
    final savingsProgress = (allocation!.savings.progress * 100).clamp(0, 200).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isHealthy ? Icons.auto_awesome_rounded : Icons.warning_amber_rounded,
              size: 18,
              color: isHealthy ? AppColors.revolutGreen : AppColors.revolutRed,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Respect 50/30/20',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isHealthy ? AppColors.revolutGreen : AppColors.revolutRed,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Mini progress bars for each category
        Row(
          children: [
            Expanded(
              child: _MiniProgressBar(
                icon: Icons.home_outlined,
                progress: needsProgress,
                isOver: needsProgress > 100,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MiniProgressBar(
                icon: Icons.celebration_outlined,
                progress: wantsProgress,
                isOver: wantsProgress > 100,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MiniProgressBar(
                icon: Icons.savings_outlined,
                progress: savingsProgress,
                isOver: false, // Savings over is good!
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Mini progress bar for budget category.
class _MiniProgressBar extends StatelessWidget {
  const _MiniProgressBar({
    required this.icon,
    required this.progress,
    required this.isOver,
  });

  final IconData icon;
  final int progress;
  final bool isOver;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 14, color: AppColors.revolutOnDarkMuted),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (progress / 100).clamp(0.0, 1.0),
            backgroundColor: AppColors.revolutBorder.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              isOver ? AppColors.revolutRed : AppColors.revolutGreen,
            ),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$progress%',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isOver ? AppColors.revolutRed : AppColors.revolutOnDarkMuted,
          ),
        ),
      ],
    );
  }
}

/// Dialog celebrating a streak milestone.
///
/// Shows a celebratory message with emoji and animation.
/// Covers: FR54 (visual celebration), Story 4.6
class _StreakCelebrationDialog extends StatefulWidget {
  const _StreakCelebrationDialog({
    required this.milestone,
    required this.onDismiss,
  });

  final int milestone;
  final VoidCallback onDismiss;

  @override
  State<_StreakCelebrationDialog> createState() =>
      _StreakCelebrationDialogState();
}

class _StreakCelebrationDialogState extends State<_StreakCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.bounceOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final celebrationIcon = _getCelebrationIcon(widget.milestone);
    final message = getCelebrationMessage(widget.milestone);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.xl),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -20 * (1 - _bounceAnimation.value)),
                  child: child,
                );
              },
              child: Icon(
                celebrationIcon,
                size: 72,
                color: AppColors.revolutAmber,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Felicitations!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.revolutBlue,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.revolutOnDark,
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: widget.onDismiss,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
              ),
              child: const Text('Super!'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCelebrationIcon(int milestone) {
    switch (milestone) {
      case 7:
        return Icons.celebration_rounded;
      case 14:
        return Icons.local_fire_department_rounded;
      case 30:
        return Icons.workspace_premium_rounded;
      case 60:
        return Icons.fitness_center_rounded;
      case 90:
        return Icons.emoji_events_rounded;
      case 180:
        return Icons.star_rounded;
      case 365:
        return Icons.celebration_rounded;
      default:
        return Icons.local_fire_department_rounded;
    }
  }
}
