import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/pattern_analysis_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Medal emojis for ranking.
const List<String> _medals = ['🥇', '🥈', '🥉'];

/// Card showing the top 3 expense categories.
///
/// Displays categories ranked by total spending with:
/// - Medal emoji for ranking (🥇🥈🥉)
/// - Category icon and name
/// - Total amount spent
/// - Tap navigation to filtered history
///
/// Covers: FR20
class TopCategoriesCard extends ConsumerWidget {
  /// Creates a TopCategoriesCard.
  const TopCategoriesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryBreakdownProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return const SizedBox.shrink();
        }

        // Take top 3 (or less if fewer categories)
        final topCategories = categories.take(3).toList();

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.revolutSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.revolutBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: AppColors.revolutBlue,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Top ${topCategories.length} Categories',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Top categories list
              ...List.generate(
                topCategories.length,
                (index) => _TopCategoryItem(
                  rank: index,
                  category: topCategories[index],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

}

/// Individual top category item.
class _TopCategoryItem extends StatelessWidget {
  const _TopCategoryItem({
    required this.rank,
    required this.category,
  });

  final int rank;
  final CategorySpending category;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xs,
      ),
      child: Row(
        children: [
          // Medal
          Text(
            _medals[rank],
            style: const TextStyle(fontSize: 24),
          ),

          const SizedBox(width: AppSpacing.sm),

          // Category icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getRankColor(rank).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              category.categoryIcon,
              size: 20,
              color: _getRankColor(rank),
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // Category name
          Expanded(
            child: Text(
              category.categoryLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),

          // Amount
          Text(
            _formatAmount(category.totalAmount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.revolutOnDark,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 0:
        return const Color(0xFFFFD700); // Gold
      case 1:
        return const Color(0xFFC0C0C0); // Silver
      case 2:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppColors.revolutBlue;
    }
  }

  String _formatAmount(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M FCFA';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K FCFA';
    }
    return '$amount FCFA';
  }
}
