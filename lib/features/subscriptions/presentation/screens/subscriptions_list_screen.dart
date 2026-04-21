import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/fcfa_formatter.dart';
import '../../data/subscription_repository.dart';
import '../../domain/models/subscription_model.dart';
import '../providers/subscriptions_list_provider.dart';
import '../widgets/subscription_tile.dart';
import 'subscription_form_screen.dart';

/// Screen displaying the list of subscriptions.
///
/// Shows all active subscriptions with option to show inactive ones.
/// Displays total monthly recurring expenses at the top.
class SubscriptionsListScreen extends ConsumerWidget {
  /// Creates a SubscriptionsListScreen.
  const SubscriptionsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(subscriptionsListStateProvider);
    final subscriptionsAsync = ref.watch(filteredSubscriptionsProvider);
    final totalMonthlyAsync = ref.watch(totalMonthlyAmountProvider);
    final activeCountAsync = ref.watch(activeSubscriptionCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Abonnements'),
        actions: [
          // Toggle for showing inactive subscriptions
          IconButton(
            onPressed: () {
              ref
                  .read(subscriptionsListStateProvider.notifier)
                  .toggleShowInactive();
            },
            icon: Icon(
              listState.showInactive
                  ? Icons.visibility_off
                  : Icons.visibility,
            ),
            tooltip: listState.showInactive
                ? 'Masquer inactifs'
                : 'Afficher inactifs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Total monthly summary card
          _TotalMonthlyCard(
            totalMonthlyAsync: totalMonthlyAsync,
            activeCountAsync: activeCountAsync,
          ),

          // Subscriptions list
          Expanded(
            child: subscriptionsAsync.when(
              data: (subscriptions) {
                if (subscriptions.isEmpty) {
                  return _EmptyState(
                    showInactive: listState.showInactive,
                    onAddPressed: () => _navigateToAddSubscription(context),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.sm,
                    bottom: 72,
                  ),
                  itemCount: subscriptions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final subscription = subscriptions[index];
                    return SubscriptionTile(
                      subscription: subscription,
                      onTap: () => _navigateToEditSubscription(
                        context,
                        subscription,
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.revolutRed,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Erreur de chargement',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: () {
                        ref.invalidate(allSubscriptionsProvider);
                        ref.invalidate(activeSubscriptionsProvider);
                      },
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddSubscription(context),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }

  Future<void> _navigateToAddSubscription(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const SubscriptionFormScreen(),
      ),
    );

    // If subscription was added, the providers will automatically update
    if (result == true && context.mounted) {
      // Optional: Show feedback or scroll to new item
    }
  }

  Future<void> _navigateToEditSubscription(
    BuildContext context,
    SubscriptionModel subscription,
  ) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => SubscriptionFormScreen(subscription: subscription),
      ),
    );

    // If subscription was updated, the providers will automatically update
    if (result == true && context.mounted) {
      // Optional: Show feedback
    }
  }
}

/// Card showing total monthly recurring expenses.
class _TotalMonthlyCard extends StatelessWidget {
  const _TotalMonthlyCard({
    required this.totalMonthlyAsync,
    required this.activeCountAsync,
  });

  final AsyncValue<int> totalMonthlyAsync;
  final AsyncValue<int> activeCountAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.revolutBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.revolutBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.repeat,
              color: AppColors.onPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total mensuel',
                  style: TextStyle(
                    color: AppColors.revolutOnDarkMuted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                totalMonthlyAsync.when(
                  data: (total) => Text(
                    FcfaFormatter.format(total),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  loading: () => const SizedBox(
                    height: 24,
                    width: 100,
                    child: LinearProgressIndicator(),
                  ),
                  error: (_, __) => const Text(
                    'Erreur',
                    style: TextStyle(color: AppColors.revolutRed),
                  ),
                ),
              ],
            ),
          ),
          activeCountAsync.when(
            data: (count) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.revolutBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$count actif${count > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Empty state when no subscriptions exist.
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.showInactive,
    required this.onAddPressed,
  });

  final bool showInactive;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card_off,
              size: 64,
              color: AppColors.revolutBorder,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              showInactive
                  ? 'Aucun abonnement'
                  : 'Aucun abonnement actif',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.revolutOnDarkMuted,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ajoutez vos abonnements récurrents pour\nmieux gérer votre budget.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.revolutOnDarkMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un abonnement'),
            ),
          ],
        ),
      ),
    );
  }
}
