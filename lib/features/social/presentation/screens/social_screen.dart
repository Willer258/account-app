import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/utils/fcfa_formatter.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../../../shared/widgets/smooth_progress_bar.dart';
import '../../domain/models/budget_buddy.dart';

/// Social screen — Budget Buddies feature.
///
/// Shows anonymous peers' savings progress to motivate the user.
/// Uses demo data for MVP (no backend required).
///
/// Covers: US-007 — Social Features
class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final challenge = BuddyChallenge(
      id: 'monthly-save',
      title: 'Défi Épargne de Janvier',
      description: 'Économisez 50 000 FCFA ensemble',
      targetAmount: 200000,
      currentAmount: 143000,
      participants: ['aissatou', 'moussa', 'fatima', 'kofi'],
      endsAt: DateTime.now().add(const Duration(days: 8)),
    );

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
                      'Budget Buddies',
                      style: AppTypography.revolutTitle.copyWith(
                        color: AppColors.revolutOnDark,
                      ),
                    ),
                    Text(
                      'Économisez mieux ensemble',
                      style: AppTypography.revolutMicro.copyWith(
                        color: AppColors.revolutOnDarkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Group Challenge Card ───────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: _GroupChallengeCard(challenge: challenge),
              ),
            ),

            // ── Section title ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'VOS AMIS',
                  style: AppTypography.revolutMicro.copyWith(
                    color: AppColors.revolutOnDarkMuted,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

            // ── Buddy List ────────────────────────────────────
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final buddy = BudgetBuddy.demoBuddies[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: _BuddyCard(buddy: buddy),
                );
              }, childCount: BudgetBuddy.demoBuddies.length),
            ),

            // ── Invite Banner ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _InviteBanner(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Group Challenge Card
// ─────────────────────────────────────────────────────────────

class _GroupChallengeCard extends StatelessWidget {
  const _GroupChallengeCard({required this.challenge});

  final BuddyChallenge challenge;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2D4A), Color(0xFF0D2040)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.revolutBorder),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.revolutBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.revolutBlue.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  '${challenge.daysLeft}j restants',
                  style: AppTypography.revolutMicro.copyWith(
                    color: AppColors.revolutBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.group_rounded,
                color: AppColors.revolutOnDarkMuted,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                '${challenge.participants.length} participants',
                style: AppTypography.revolutMicro.copyWith(
                  color: AppColors.revolutOnDarkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            challenge.title,
            style: AppTypography.revolutSubtitle.copyWith(
              color: AppColors.revolutOnDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            challenge.description,
            style: AppTypography.revolutBody.copyWith(
              color: AppColors.revolutOnDarkMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                FcfaFormatter.formatCompact(challenge.currentAmount),
                style: AppTypography.revolutSubtitle.copyWith(
                  color: AppColors.revolutGreen,
                  fontSize: 18,
                ),
              ),
              Text(
                '/ ${FcfaFormatter.formatCompact(challenge.targetAmount)} FCFA',
                style: AppTypography.revolutMicro.copyWith(
                  color: AppColors.revolutOnDarkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SmoothProgressBar(
            value: challenge.progress,
            height: 6,
            gradient: const LinearGradient(colors: AppColors.positiveGradient),
          ),
          const SizedBox(height: 4),
          Text(
            '${(challenge.progress * 100).round()}% de l\'objectif atteint',
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
// Buddy Card
// ─────────────────────────────────────────────────────────────

class _BuddyCard extends StatelessWidget {
  const _BuddyCard({required this.buddy});

  final BudgetBuddy buddy;

  Color get _progressColor {
    if (buddy.savingsPercent >= 75) return AppColors.revolutGreen;
    if (buddy.savingsPercent >= 50) return AppColors.revolutAmber;
    return AppColors.revolutRed;
  }

  @override
  Widget build(BuildContext context) {
    return RevolutCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.revolutSurfaceElevated,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.revolutBorder),
                ),
                alignment: Alignment.center,
                child: Text(
                  buddy.avatarEmoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              if (buddy.isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.revolutGreen,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.revolutSurface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      buddy.name,
                      style: AppTypography.revolutBody.copyWith(
                        color: AppColors.revolutOnDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      buddy.badge,
                      style: AppTypography.revolutMicro.copyWith(
                        color: AppColors.revolutOnDarkMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '🔥 ${buddy.streak} jours de streak',
                  style: AppTypography.revolutMicro.copyWith(
                    color: AppColors.revolutOnDarkMuted,
                  ),
                ),
                const SizedBox(height: 8),
                SmoothProgressBar(
                  value: buddy.savingsPercent / 100,
                  height: 4,
                  foregroundColor: _progressColor,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Savings %
          Column(
            children: [
              Text(
                '${buddy.savingsPercent}%',
                style: AppTypography.revolutSubtitle.copyWith(
                  color: _progressColor,
                  fontSize: 18,
                ),
              ),
              Text(
                'épargné',
                style: AppTypography.revolutMicro.copyWith(
                  color: AppColors.revolutOnDarkMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Invite Banner
// ─────────────────────────────────────────────────────────────

class _InviteBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fonctionnalité bientôt disponible ! 🚀'),
            backgroundColor: AppColors.revolutBlue,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.revolutBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.revolutBlue.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.person_add_rounded,
              color: AppColors.revolutBlue,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inviter des amis',
                    style: AppTypography.revolutSubtitle.copyWith(
                      color: AppColors.revolutOnDark,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Économisez ensemble et restez motivés',
                    style: AppTypography.revolutMicro.copyWith(
                      color: AppColors.revolutOnDarkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.revolutBlue,
            ),
          ],
        ),
      ),
    );
  }
}
