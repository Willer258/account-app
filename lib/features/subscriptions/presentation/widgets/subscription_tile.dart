import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/fcfa_formatter.dart';
import '../../domain/models/subscription_frequency.dart';
import '../../domain/models/subscription_model.dart';
import 'subscription_category_row.dart';

/// A list tile displaying subscription information.
///
/// Shows name, amount, frequency, next due date, and category icon.
/// Inactive subscriptions are displayed with reduced opacity.
class SubscriptionTile extends StatelessWidget {
  /// Creates a SubscriptionTile.
  const SubscriptionTile({
    required this.subscription,
    this.onTap,
    super.key,
  });

  /// The subscription to display.
  final SubscriptionModel subscription;

  /// Callback when the tile is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final category = _getCategoryData(subscription.category);
    final isInactive = !subscription.isActive;

    return Opacity(
      opacity: isInactive ? 0.5 : 1.0,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isInactive
                ? AppColors.revolutBorder
                : AppColors.revolutBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            category?.icon ?? Icons.credit_card,
            color: isInactive ? AppColors.revolutOnDarkMuted : AppColors.revolutBlue,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                subscription.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: isInactive ? TextDecoration.lineThrough : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isInactive)
              Container(
                margin: const EdgeInsets.only(left: AppSpacing.xs),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.revolutBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Inactif',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.revolutOnDarkMuted,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          _buildSubtitle(),
          style: TextStyle(
            color: AppColors.revolutOnDarkMuted,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              FcfaFormatter.format(subscription.amountFcfa),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isInactive ? AppColors.revolutOnDarkMuted : AppColors.revolutOnDark,
              ),
            ),
            Text(
              _getFrequencyShort(),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.revolutOnDarkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final dueDayText = _formatDueDay();
    return dueDayText;
  }

  String _formatDueDay() {
    switch (subscription.frequency) {
      case SubscriptionFrequency.weekly:
        const days = [
          'Lundi',
          'Mardi',
          'Mercredi',
          'Jeudi',
          'Vendredi',
          'Samedi',
          'Dimanche',
        ];
        return 'Chaque ${days[subscription.dueDay - 1]}';
      case SubscriptionFrequency.monthly:
        return 'Le ${subscription.dueDay} du mois';
      case SubscriptionFrequency.quarterly:
        return 'Le ${subscription.dueDay} (trimestre)';
      case SubscriptionFrequency.biannual:
        return 'Le ${subscription.dueDay} (semestre)';
      case SubscriptionFrequency.yearly:
        return 'Le ${subscription.dueDay} (annuel)';
    }
  }

  String _getFrequencyShort() {
    switch (subscription.frequency) {
      case SubscriptionFrequency.weekly:
        return '/semaine';
      case SubscriptionFrequency.monthly:
        return '/mois';
      case SubscriptionFrequency.quarterly:
        return '/trim.';
      case SubscriptionFrequency.biannual:
        return '/sem.';
      case SubscriptionFrequency.yearly:
        return '/an';
    }
  }

  SubscriptionCategory? _getCategoryData(String categoryId) {
    try {
      return subscriptionCategories.firstWhere((c) => c.id == categoryId);
    } catch (_) {
      return null;
    }
  }
}
