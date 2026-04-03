import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../../../shared/widgets/smooth_progress_bar.dart';
import '../../domain/models/weekly_challenge.dart';

/// Weekly Challenges screen — Revolut-inspired gamification.
///
/// Displays active challenges with progress, difficulty badges,
/// and rewards to motivate better budget habits.
///
/// Covers: US-008 — Weekly Challenges
class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final challenges = WeeklyChallenge.currentChallenges();
    final completed = challenges.where((c) => c.isCompleted).length;
    final total = challenges.length;

    return Scaffold(
      backgroundColor: AppColors.revolutDark,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Défis Hebdo',
                      style: AppTypography.revolutTitle.copyWith(
                        color: AppColors.revolutOnDark,
                      ),
                    ),
                    Text(
                      '$completed/$total défis complétés cette semaine',
                      style: AppTypography.revolutMicro.copyWith(
                        color: AppColors.revolutOnDarkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Weekly Progress Summary ───────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: _WeekProgressCard(completed: completed, total: total),
              ),
            ),

            // ── Section: Active ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'EN COURS',
                  style: AppTypography.revolutMicro.copyWith(
                    color: AppColors.revolutOnDarkMuted,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final active = challenges.where((c) => !c.isCompleted).toList();
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: _ChallengeCard(challenge: active[index]),
                );
              }, childCount: challenges.where((c) => !c.isCompleted).length),
            ),

            // ── Section: Completed ────────────────────────────
            if (completed > 0) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    'COMPLÉTÉS ✅',
                    style: AppTypography.revolutMicro.copyWith(
                      color: AppColors.revolutOnDarkMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final done = challenges.where((c) => c.isCompleted).toList();
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    child: _ChallengeCard(challenge: done[index]),
                  );
                }, childCount: completed),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Weekly Progress Card
// ─────────────────────────────────────────────────────────────

class _WeekProgressCard extends StatelessWidget {
  const _WeekProgressCard({required this.completed, required this.total});

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;
    final pointsEarned = completed * 100;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.revolutPurple.withOpacity(0.3),
            AppColors.revolutBlue.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.revolutPurple.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'POINTS DE LA SEMAINE',
                    style: AppTypography.revolutMicro.copyWith(
                      color: AppColors.revolutOnDarkMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$pointsEarned pts',
                    style: AppTypography.revolutTitle.copyWith(
                      color: AppColors.revolutPurple,
                      fontSize: 28,
                    ),
                  ),
                ],
              ),
              // Trophy / stars
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.revolutPurple.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.revolutPurple.withOpacity(0.4),
                  ),
                ),
                child: const Center(
                  child: Text('🏆', style: TextStyle(fontSize: 28)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SmoothProgressBar(
            value: progress,
            height: 6,
            gradient: LinearGradient(
              colors: [AppColors.revolutPurple, AppColors.revolutBlue],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$completed défi${completed > 1 ? 's' : ''} sur $total accompli${completed > 1 ? 's' : ''}',
            style: AppTypography.revolutMicro.copyWith(
              color: AppColors.revolutOnDarkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Challenge Card
// ─────────────────────────────────────────────────────────────

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.challenge});

  final WeeklyChallenge challenge;

  Color get _difficultyColor {
    switch (challenge.difficulty) {
      case ChallengeDifficulty.easy:
        return AppColors.revolutGreen;
      case ChallengeDifficulty.medium:
        return AppColors.revolutAmber;
      case ChallengeDifficulty.hard:
        return AppColors.revolutRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = challenge.isCompleted;

    return Opacity(
      opacity: isCompleted ? 0.7 : 1.0,
      child: RevolutCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(challenge.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              challenge.title,
                              style: AppTypography.revolutSubtitle.copyWith(
                                color: AppColors.revolutOnDark,
                                fontSize: 15,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          // Difficulty badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _difficultyColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _difficultyColor.withOpacity(0.4),
                              ),
                            ),
                            child: Text(
                              challenge.difficulty.label,
                              style: AppTypography.revolutMicro.copyWith(
                                color: _difficultyColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        challenge.description,
                        style: AppTypography.revolutMicro.copyWith(
                          color: AppColors.revolutOnDarkMuted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (isCompleted)
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.revolutGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    challenge.reward,
                    style: AppTypography.revolutMicro.copyWith(
                      color: AppColors.revolutGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            else ...[
              SmoothProgressBar(
                value: challenge.progress,
                height: 4,
                foregroundColor: AppColors.revolutBlue,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _progressLabel(),
                    style: AppTypography.revolutMicro.copyWith(
                      color: AppColors.revolutOnDarkMuted,
                    ),
                  ),
                  Text(
                    '🎁 ${challenge.reward}',
                    style: AppTypography.revolutMicro.copyWith(
                      color: AppColors.revolutOnDarkMuted,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _progressLabel() {
    switch (challenge.type) {
      case ChallengeType.savingsTarget:
        return '${challenge.currentValue.round()} / ${challenge.targetValue.round()} FCFA';
      case ChallengeType.dailyLog:
      case ChallengeType.avoidCategory:
        return '${challenge.currentValue.round()} / ${challenge.targetValue.round()} jours';
      default:
        return '${(challenge.progress * 100).round()}%';
    }
  }
}
