import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Dialog to celebrate streak milestones.
///
/// Shows a celebratory animation and message when the user reaches
/// a milestone (7, 14, 30, 60, 90, 180, 365 days).
///
/// Covers: FR54 (visual celebration upon achieving streak), UX-8
class MilestoneCelebrationDialog extends StatefulWidget {
  const MilestoneCelebrationDialog({
    required this.milestone,
    required this.currentStreak,
    super.key,
  });

  /// The milestone reached (7, 14, 30, etc.)
  final int milestone;

  /// The current streak count.
  final int currentStreak;

  /// Shows the celebration dialog.
  static Future<void> show(
    BuildContext context, {
    required int milestone,
    required int currentStreak,
  }) {
    // Haptic feedback for celebration
    HapticFeedback.heavyImpact();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => MilestoneCelebrationDialog(
        milestone: milestone,
        currentStreak: currentStreak,
      ),
    );
  }

  @override
  State<MilestoneCelebrationDialog> createState() =>
      _MilestoneCelebrationDialogState();
}

class _MilestoneCelebrationDialogState extends State<MilestoneCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _bounceAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.bounceOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData get _milestoneIcon {
    switch (widget.milestone) {
      case 7:
        return Icons.celebration_rounded;
      case 14:
        return Icons.emoji_events_rounded;
      case 30:
        return Icons.workspace_premium_rounded;
      case 60:
        return Icons.diamond_rounded;
      case 90:
        return Icons.star_rounded;
      case 180:
        return Icons.local_fire_department_rounded;
      case 365:
        return Icons.military_tech_rounded;
      default:
        return Icons.celebration_rounded;
    }
  }

  String get _congratsMessage {
    switch (widget.milestone) {
      case 7:
        return 'Une semaine complète!';
      case 14:
        return 'Deux semaines de suite!';
      case 30:
        return 'Un mois entier!';
      case 60:
        return 'Deux mois incroyables!';
      case 90:
        return 'Trois mois de discipline!';
      case 180:
        return 'Six mois légendaires!';
      case 365:
        return 'Une année complète!';
      default:
        return 'Nouveau record!';
    }
  }

  String get _encouragementMessage {
    switch (widget.milestone) {
      case 7:
        return 'Tu as pris une excellente habitude!';
      case 14:
        return 'Ta régularité est impressionnante!';
      case 30:
        return 'Tu es un vrai pro de la gestion!';
      case 60:
        return 'Ta discipline est exemplaire!';
      case 90:
        return 'Tu es devenu un maître!';
      case 180:
        return 'Tu es une légende!';
      case 365:
        return 'Tu es absolument incroyable!';
      default:
        return 'Continue comme ça!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.revolutDark,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated icon
                Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Icon(
                    _milestoneIcon,
                    size: 72,
                    color: AppColors.revolutAmber,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Fire streak badge
                Transform.scale(
                  scale: _bounceAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B00), Color(0xFFFF9500)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.currentStreak} jours',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Congrats message
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        _congratsMessage,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.revolutOnDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _encouragementMessage,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.revolutOnDarkMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Close button
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Continuer'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
