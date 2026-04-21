import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/fcfa_formatter.dart';
import '../../domain/models/savings_project_model.dart';
import '../providers/savings_projects_provider.dart';

/// Compact preview card for the home screen showing the priority project.
///
/// Displays the project closest to its goal that hasn't been reached yet.
/// Tapping navigates to the project detail screen.
class ProjectPreviewCard extends ConsumerWidget {
  const ProjectPreviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(priorityProjectProvider);

    // Don't show if no projects
    if (project == null) {
      return const SizedBox.shrink();
    }

    final color = project.color;
    final progress = project.progress.clamp(0.0, 1.0);
    final isGoalReached = project.isGoalReached;

    return GestureDetector(
      onTap: () => context.push('/projects/${project.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
            // Emoji icon with circular progress
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 4,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.revolutBorder.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  // Progress circle
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isGoalReached ? AppColors.revolutGreen : color,
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  // Emoji
                  Text(
                    project.emoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.revolutOnDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (project.autoContributionEnabled)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.autorenew,
                            size: 14,
                            color: color,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${FcfaFormatter.formatCompact(project.currentAmountFcfa)} / ${FcfaFormatter.formatCompact(project.targetAmountFcfa)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.revolutOnDarkMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Percentage
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isGoalReached
                    ? AppColors.revolutGreen.withValues(alpha: 0.1)
                    : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isGoalReached ? '100%' : '${project.progressPercentage}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isGoalReached ? AppColors.revolutGreen : color,
                ),
              ),
            ),

            // Arrow
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              color: AppColors.revolutOnDarkMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget showing all projects as mini cards in a horizontal scroll.
class ProjectsMiniList extends ConsumerWidget {
  const ProjectsMiniList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(activeProjectsProvider);

    return projectsAsync.when(
      data: (projects) {
        if (projects.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mes projets',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.revolutOnDark,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/projects'),
                    child: const Text('Voir tout'),
                  ),
                ],
              ),
            ),

            // Horizontal list
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: projects.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final project = projects[index];
                  return _MiniProjectCard(project: project);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Mini project card for horizontal list.
class _MiniProjectCard extends StatelessWidget {
  const _MiniProjectCard({required this.project});

  final SavingsProjectModel project;

  @override
  Widget build(BuildContext context) {
    final color = project.color;
    final progress = project.progress.clamp(0.0, 1.0);
    final isGoalReached = project.isGoalReached;

    return GestureDetector(
      onTap: () => context.push('/projects/${project.id}'),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with emoji and percentage
            Row(
              children: [
                Text(project.emoji, style: const TextStyle(fontSize: 20)),
                const Spacer(),
                Text(
                  '${project.progressPercentage}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isGoalReached ? AppColors.revolutGreen : color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Name
            Text(
              project.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.revolutOnDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const Spacer(),

            // Progress bar
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
    );
  }
}
