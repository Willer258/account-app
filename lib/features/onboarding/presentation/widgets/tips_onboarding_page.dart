import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../tips/data/tips_data.dart';
import '../../../tips/domain/models/tip.dart';

/// Onboarding page showcasing financial tips feature.
///
/// Displays a carousel of sample tips to introduce users
/// to the financial advice they'll receive in the app.
class TipsOnboardingPage extends StatefulWidget {
  const TipsOnboardingPage({super.key});

  @override
  State<TipsOnboardingPage> createState() => _TipsOnboardingPageState();
}

class _TipsOnboardingPageState extends State<TipsOnboardingPage> {
  late PageController _pageController;
  int _currentTip = 0;

  // Sample tips to showcase in onboarding
  late final List<Tip> _sampleTips;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Get one tip from each category for variety
    _sampleTips = [
      TipsData.allTips[0], // Investment
      TipsData.allTips[5], // Savings
      TipsData.allTips[10], // Optimization
      TipsData.allTips[15], // Economy
      TipsData.allTips[20], // Survival
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Header icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lightbulb_outline,
              size: 40,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Title
          Text(
            'Des conseils pour toi',
            style: AppTypography.headline.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Subtitle
          Text(
            'Pockii te donne des conseils financiers adaptés',
            style: AppTypography.body.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Tips carousel
          SizedBox(
            height: 180,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _sampleTips.length,
              onPageChanged: (index) => setState(() => _currentTip = index),
              itemBuilder: (context, index) {
                final tip = _sampleTips[index];
                return _TipCard(tip: tip);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Page indicator dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _sampleTips.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: index == _currentTip ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: index == _currentTip
                      ? AppColors.primary
                      : AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Swipe hint
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.swipe,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 4),
              Text(
                'Glisse pour voir plus',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A single tip card for the onboarding carousel.
class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});

  final Tip tip;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryContainer.withValues(alpha: 0.8),
            AppColors.primaryContainer.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tip.category.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  tip.category.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Tip content
          Expanded(
            child: Text(
              tip.content,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.onSurface,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Source (if available)
          if (tip.source != null)
            Text(
              '- ${tip.source}',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppColors.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
