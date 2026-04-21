import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/fcfa_formatter.dart';
import '../../domain/models/savings_project_model.dart';

/// Card widget displaying a savings project.
class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.project,
    this.onTap,
    this.compact = false,
  });

  final SavingsProjectModel project;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _CompactProjectCard(project: project, onTap: onTap);
    }
    return _FullProjectCard(project: project, onTap: onTap);
  }
}

/// Full-size project card with all details.
class _FullProjectCard extends StatelessWidget {
  const _FullProjectCard({
    required this.project,
    this.onTap,
  });

  final SavingsProjectModel project;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = project.color;
    final progress = project.progress.clamp(0.0, 1.0);
    final isGoalReached = project.isGoalReached;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Emoji icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      project.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Title and category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.revolutOnDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        project.category.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.revolutOnDarkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Goal reached badge
                if (isGoalReached)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.revolutGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: AppColors.revolutGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Atteint!',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.revolutGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Auto-contribution badge
                if (project.autoContributionEnabled && !isGoalReached)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.autorenew,
                      size: 16,
                      color: color,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Progress bar
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.revolutBorder.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isGoalReached ? AppColors.revolutGreen : color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
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
                      FcfaFormatter.format(project.currentAmountFcfa),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${project.progressPercentage}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isGoalReached ? AppColors.revolutGreen : color,
                  ),
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
                      FcfaFormatter.format(project.targetAmountFcfa),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Auto-contribution info
            if (project.autoContributionEnabled && !isGoalReached) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.revolutSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.autorenew,
                      size: 12,
                      color: AppColors.revolutOnDarkMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${FcfaFormatter.formatCompact(project.autoContributionAmountFcfa)}/${project.autoContributionFrequency?.displayName.toLowerCase() ?? 'mois'}',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.revolutOnDarkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact project card for home screen preview.
class _CompactProjectCard extends StatelessWidget {
  const _CompactProjectCard({
    required this.project,
    this.onTap,
  });

  final SavingsProjectModel project;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = project.color;
    final progress = project.progress.clamp(0.0, 1.0);
    final isGoalReached = project.isGoalReached;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Emoji
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  project.emoji,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    project.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.revolutOnDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Mini progress bar
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.revolutBorder.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isGoalReached ? AppColors.revolutGreen : color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Percentage
            Text(
              '${project.progressPercentage}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isGoalReached ? AppColors.revolutGreen : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
