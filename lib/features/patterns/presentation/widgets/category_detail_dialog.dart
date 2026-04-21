import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/pattern_analysis_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Dialog showing detailed analysis for a category.
///
/// Displays:
/// - Category name and icon
/// - Total spending and percentage
/// - Average per month
/// - Trend indicator (↑↓→)
/// - Number of transactions
class CategoryDetailDialog extends ConsumerWidget {
  /// Creates a CategoryDetailDialog.
  const CategoryDetailDialog({
    required this.categoryId,
    super.key,
  });

  /// The category ID to show details for.
  final String categoryId;

  /// Shows the dialog.
  static Future<void> show(BuildContext context, String categoryId) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.revolutSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CategoryDetailDialog(categoryId: categoryId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(categoryDetailProvider(categoryId));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: detailAsync.when(
          data: (detail) => _DetailContent(detail: detail),
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox(
            height: 200,
            child: Center(child: Text('Erreur de chargement')),
          ),
        ),
      ),
    );
  }
}

/// Content of the detail dialog.
class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.detail});

  final CategoryDetail detail;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // Header with icon and name
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.revolutBlue.withOpacity( 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                detail.spending.categoryIcon,
                size: 32,
                color: AppColors.revolutBlue,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.spending.categoryLabel,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '${detail.spending.transactionCount} transactions',
                    style: TextStyle(
                      color: AppColors.revolutOnDarkMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.xl),

        // Stats grid
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total',
                value: _formatAmount(detail.spending.totalAmount),
                subValue:
                    '${(detail.spending.percentage * 100).toStringAsFixed(1)}% des depenses',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _StatCard(
                label: 'Moyenne/mois',
                value: _formatAmount(detail.averagePerMonth),
                subValue: 'sur ${detail.monthsOfData} mois',
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Trend card
        _TrendCard(detail: detail),

        const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
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

/// Stat card widget.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.subValue,
  });

  final String label;
  final String value;
  final String subValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.revolutSurfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.revolutOnDarkMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subValue,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.revolutOnDarkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Trend indicator card.
class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.detail});

  final CategoryDetail detail;

  @override
  Widget build(BuildContext context) {
    final trendText = _getTrendText(detail.trend);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: detail.trendColor.withOpacity( 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: detail.trendColor.withOpacity( 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: detail.trendColor.withOpacity( 0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              detail.trendArrow,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: detail.trendColor,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tendance',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.revolutOnDarkMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  trendText,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: detail.trendColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTrendText(String trend) {
    switch (trend) {
      case 'up':
        return 'En hausse ce mois';
      case 'down':
        return 'En baisse ce mois';
      default:
        return 'Stable';
    }
  }
}
