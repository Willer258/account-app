import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/tip.dart';
import '../providers/daily_tip_provider.dart';

/// A card widget displaying the daily financial tip.
///
/// Shows contextual tips based on the user's budget percentage.
/// Users can tap "Suivant" to see another tip.
class TipCard extends ConsumerWidget {
  const TipCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tipAsync = ref.watch(currentTipProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      decoration: BoxDecoration(
        color: AppColors.revolutSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.revolutBorder,
          width: 1,
        ),
      ),
      child: tipAsync.when(
        data: (tip) => _TipContent(tip: tip),
        loading: () => const _TipLoading(),
        error: (_, __) => const _TipError(),
      ),
    );
  }
}

/// Content of the tip card when loaded successfully.
class _TipContent extends ConsumerWidget {
  const _TipContent({required this.tip});

  final Tip tip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row with icon and category
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.revolutBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tip.category.emoji,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Conseil du jour',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.revolutAmber,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              // Category badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.revolutBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tip.category.displayName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.revolutBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Tip content
          Text(
            tip.content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.revolutOnDark,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Action row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  ref.read(currentTipProvider.notifier).nextTip();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Suivant'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.revolutBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Loading state for the tip card.
class _TipLoading extends StatelessWidget {
  const _TipLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.revolutBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.lightbulb_rounded, size: 16, color: AppColors.revolutAmber),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: 100,
                  decoration: BoxDecoration(
                    color: AppColors.revolutBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.revolutBorder.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
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

/// Error state for the tip card.
class _TipError extends StatelessWidget {
  const _TipError();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.revolutBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.lightbulb_rounded, size: 16, color: AppColors.revolutAmber),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text(
              'Les conseils arrivent bientôt...',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.revolutOnDarkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact version of the tip card for smaller spaces.
class TipCardCompact extends ConsumerWidget {
  const TipCardCompact({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tipAsync = ref.watch(currentTipProvider);

    return tipAsync.when(
      data: (tip) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.revolutSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(tip.category.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                tip.content,
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
