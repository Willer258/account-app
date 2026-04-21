import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/fcfa_formatter.dart';
import '../../domain/models/emergency_fund.dart';
import '../providers/budget_rules_provider.dart';

/// Card displaying emergency fund progress.
class EmergencyFundCard extends ConsumerWidget {
  const EmergencyFundCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(emergencyFundSettingsProvider);

    if (!settings.isEnabled || settings.monthlySalary == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.revolutGreen.withOpacity(0.15),
            AppColors.revolutSurface,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.revolutBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.revolutGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shield_rounded, size: 16, color: AppColors.revolutGreen),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fonds d\'urgence',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.revolutGreen,
                      ),
                    ),
                    Text(
                      'Objectif: ${settings.targetMonths} mois de salaire',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.revolutOnDarkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Goal badge
              if (settings.isGoalReached)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.revolutGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Atteint!',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Progress bar
          _ProgressBar(
            progress: settings.progressPercentage,
            targetMonths: settings.targetMonths,
            monthsSaved: settings.monthsSaved,
          ),

          const SizedBox(height: AppSpacing.sm),

          // Amounts row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Épargné',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.revolutOnDarkMuted,
                    ),
                  ),
                  Text(
                    FcfaFormatter.format(settings.currentSavings),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.revolutGreen,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Objectif',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.revolutOnDarkMuted,
                    ),
                  ),
                  Text(
                    FcfaFormatter.format(settings.targetAmount),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Motivational tip
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.revolutSurfaceElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  '💡',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    settings.motivationalTip,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.revolutOnDarkMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom progress bar with month markers.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.progress,
    required this.targetMonths,
    required this.monthsSaved,
  });

  final double progress;
  final int targetMonths;
  final double monthsSaved;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress bar
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.revolutBorder,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Stack(
            children: [
              // Progress fill
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.revolutGreen,
                        AppColors.success,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              // Month markers
              ...List.generate(targetMonths - 1, (index) {
                final position = (index + 1) / targetMonths;
                return Positioned(
                  left: MediaQuery.of(context).size.width * position * 0.7,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 1,
                    color: AppColors.revolutSurfaceElevated,
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Percentage label
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${(progress * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.revolutGreen,
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact version for settings.
class EmergencyFundPreview extends ConsumerWidget {
  const EmergencyFundPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(emergencyFundSettingsProvider);

    if (!settings.isEnabled || settings.monthlySalary == 0) {
      return Text(
        'Non configuré',
        style: TextStyle(
          fontSize: 13,
          color: AppColors.revolutOnDarkMuted,
        ),
      );
    }

    return Row(
      children: [
        // Mini progress bar
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.revolutBorder,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: settings.progressPercentage.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.revolutGreen,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '${settings.monthsSaved.toStringAsFixed(1)}/${settings.targetMonths} mois',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.revolutGreen,
          ),
        ),
      ],
    );
  }
}
