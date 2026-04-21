import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/services/simulation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/pockii_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/currency_preference.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/utils/fcfa_formatter.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../../budget/data/repositories/budget_period_repository.dart';
import '../../../budget_rules/presentation/providers/budget_rules_provider.dart';
import '../../../budget_rules/presentation/widgets/budget_allocation_card.dart';
import '../../../home/presentation/providers/budget_provider.dart';
import '../../../tutorials/presentation/widgets/tutorial_bottom_sheet.dart';
import '../../../tutorials/tutorial_content.dart';
import '../dialogs/budget_edit_dialog.dart';

/// Revolut-style dark settings screen.
///
/// Shows budget, appearance, rules, notifications, and about sections
/// in dark cards with colored accents.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.pockii.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Text(
                  'Paramètres',
                  style: AppTypography.revolutTitle.copyWith(
                    color: context.pockii.onSurface,
                  ),
                ),
              ),
            ),

            // ── Sections ───────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Simulation button prominent at top (debug only)
                  if (kDebugMode) ...[
                    _SimulationButton(),
                    const SizedBox(height: 12),
                  ],
                  _BudgetSection(),
                  const SizedBox(height: 12),
                  _ThemeSection(),
                  const SizedBox(height: 12),
                  _CurrencySection(),
                  const SizedBox(height: 12),
                  _BudgetRulesSection(),
                  const SizedBox(height: 12),
                  _NotificationsSection(),
                  const SizedBox(height: 12),
                  _ChallengesSection(),
                  const SizedBox(height: 12),
                  _AboutSection(),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Prominent simulation button for debug mode.
class _SimulationButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SimulationButton> createState() => _SimulationButtonState();
}

class _SimulationButtonState extends ConsumerState<_SimulationButton> {
  bool _isSimulating = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isSimulating ? null : _runSimulation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.revolutPurple.withOpacity(0.2),
              AppColors.revolutBlue.withOpacity(0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.revolutPurple.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.revolutPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isSimulating
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.revolutPurple,
                      ),
                    )
                  : const Icon(
                      Icons.science_rounded,
                      color: AppColors.revolutPurple,
                      size: 22,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Simulation 3 mois',
                    style: AppTypography.revolutLabel.copyWith(
                      color: context.pockii.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isSimulating
                        ? 'Generation en cours...'
                        : 'Generer des donnees de demo',
                    style: AppTypography.revolutMicro.copyWith(
                      color: context.pockii.onSurfaceMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.revolutPurple,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runSimulation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.pockii.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Simulation',
          style: AppTypography.revolutSubtitle.copyWith(
            color: context.pockii.onSurface,
          ),
        ),
        content: Text(
          'Cette action va supprimer toutes les donnees existantes et les remplacer par 3 mois de donnees de demo.\n\nContinuer?',
          style: AppTypography.revolutBody.copyWith(
            color: context.pockii.onSurfaceMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: AppTypography.revolutLabel.copyWith(
                color: context.pockii.onSurfaceMuted,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.revolutPurple,
            ),
            child: Text(
              'Simuler',
              style: AppTypography.revolutLabel.copyWith(
                color: context.pockii.onSurface,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSimulating = true);

    try {
      final service = ref.read(simulationServiceProvider);
      await service.runSimulation();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Simulation terminee! Redemarrage recommande.',
              style: AppTypography.revolutBody.copyWith(
                color: context.pockii.onSurface,
              ),
            ),
            backgroundColor: AppColors.revolutGreen.withOpacity(0.9),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur: $e',
              style: AppTypography.revolutBody.copyWith(
                color: context.pockii.onSurface,
              ),
            ),
            backgroundColor: AppColors.revolutRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSimulating = false);
    }
  }
}

/// Budget section showing current monthly budget with edit option.
class _BudgetSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodAsync = ref.watch(_currentPeriodProvider);

    return _SettingsSection(
      title: 'BUDGET MENSUEL',
      icon: Icons.account_balance_wallet_rounded,
      iconColor: AppColors.revolutBlue,
      child: periodAsync.when(
        data: (period) {
          final budget = period.monthlyBudgetFcfa;
          return _SettingsTile(
            title: FcfaFormatter.format(budget),
            subtitle: 'Budget pour ce mois',
            trailing: GestureDetector(
              onTap: () => _showBudgetEditDialog(context, ref, budget),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.revolutBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Modifier',
                  style: AppTypography.revolutLabel.copyWith(
                    color: AppColors.revolutBlue,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const _SettingsTile(
          title: 'Chargement...',
          subtitle: 'Budget pour ce mois',
        ),
        error: (_, __) => const _SettingsTile(
          title: 'Erreur',
          subtitle: 'Impossible de charger le budget',
        ),
      ),
    );
  }

  Future<void> _showBudgetEditDialog(
    BuildContext context,
    WidgetRef ref,
    int currentBudget,
  ) async {
    final newBudget = await BudgetEditDialog.show(context, currentBudget);

    if (newBudget != null && newBudget != currentBudget) {
      final repository = ref.read(budgetPeriodRepositoryProvider);
      final period = await repository.getCurrentPeriod();

      if (period != null) {
        await repository.updatePeriodBudget(period.id, newBudget);
        ref.invalidate(_currentPeriodProvider);
        await ref.read(budgetStateProvider.notifier).refresh();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Budget mis à jour',
                style: AppTypography.revolutBody.copyWith(
                  color: context.pockii.onSurface,
                ),
              ),
            ),
          );
        }
      }
    }
  }
}

/// Theme selection section.
class _ThemeSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeModeProvider);

    return _SettingsSection(
      title: 'APPARENCE',
      icon: Icons.palette_rounded,
      iconColor: AppColors.revolutPurple,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _ThemeOption(
              icon: Icons.brightness_auto_rounded,
              label: 'Auto',
              isSelected: currentMode == AppThemeMode.system,
              onTap: () => ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(AppThemeMode.system),
            ),
            const SizedBox(width: 10),
            _ThemeOption(
              icon: Icons.light_mode_rounded,
              label: 'Clair',
              isSelected: currentMode == AppThemeMode.light,
              onTap: () => ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(AppThemeMode.light),
            ),
            const SizedBox(width: 10),
            _ThemeOption(
              icon: Icons.dark_mode_rounded,
              label: 'Sombre',
              isSelected: currentMode == AppThemeMode.dark,
              onTap: () => ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(AppThemeMode.dark),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.revolutBlue : context.pockii.onSurfaceMuted;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.revolutBlue.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.revolutBlue.withValues(alpha: 0.3)
                  : context.pockii.border,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTypography.revolutMicro.copyWith(
                  color: color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Currency display format section.
class _CurrencySection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currencyFormatProvider);

    return _SettingsSection(
      title: 'DEVISE',
      icon: Icons.paid_rounded,
      iconColor: AppColors.revolutGreen,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CurrencyFormat.values.map((format) {
            final isSelected = current == format;
            return GestureDetector(
              onTap: () => ref
                  .read(currencyFormatProvider.notifier)
                  .setFormat(format),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.revolutGreen.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.revolutGreen.withValues(alpha: 0.3)
                        : context.pockii.border,
                  ),
                ),
                child: Text(
                  '100 000 ${format.symbol}',
                  style: AppTypography.revolutLabel.copyWith(
                    color: isSelected
                        ? AppColors.revolutGreen
                        : context.pockii.onSurfaceMuted,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Notifications section with link to preferences.
class _NotificationsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: 'NOTIFICATIONS',
      icon: Icons.notifications_rounded,
      iconColor: AppColors.revolutAmber,
      child: _SettingsTile(
        title: 'Préférences',
        subtitle: 'Gérer les alertes et rappels',
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: context.pockii.onSurfaceMuted,
          size: 20,
        ),
        onTap: () => context.push(AppRoutes.notificationPreferences),
      ),
    );
  }
}

/// Challenges section with link to weekly challenges.
class _ChallengesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: 'DÉFIS',
      icon: Icons.emoji_events_rounded,
      iconColor: AppColors.revolutAmber,
      child: _SettingsTile(
        title: 'Défis de la semaine',
        subtitle: 'Relève des challenges pour mieux gérer ton budget',
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: context.pockii.onSurfaceMuted,
          size: 20,
        ),
        onTap: () => context.push(AppRoutes.challenges),
      ),
    );
  }
}

/// About section with app information and simulation button.
class _AboutSection extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends ConsumerState<_AboutSection> {
  bool _isSimulating = false;

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: 'À PROPOS',
      icon: Icons.info_outline_rounded,
      iconColor: context.pockii.onSurfaceMuted,
      child: Column(
        children: [
          const _SettingsTile(
            title: 'Pockii',
            subtitle: 'Version 1.0.0',
          ),
          Container(
            height: 0.5,
            color: context.pockii.border,
          ),
          const _SettingsTile(
            title: 'Ton budget, simplifié',
            subtitle: 'Gestion de budget simple et efficace',
          ),
          // Simulation only in debug mode
          if (kDebugMode) ...[
            Container(
              height: 0.5,
              color: context.pockii.border,
            ),
            _SettingsTile(
              title: 'Simulation 3 mois',
              subtitle: 'Générer des données de démonstration',
              trailing: _isSimulating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.revolutBlue,
                      ),
                    )
                  : Icon(
                      Icons.science_outlined,
                      color: context.pockii.onSurfaceMuted,
                      size: 20,
                    ),
              onTap: _isSimulating ? null : _runSimulation,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _runSimulation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.pockii.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Simulation',
          style: AppTypography.revolutSubtitle.copyWith(
            color: context.pockii.onSurface,
          ),
        ),
        content: Text(
          'Cette action va supprimer toutes les données existantes et les remplacer par des données de simulation sur 3 mois.\n\nContinuer?',
          style: AppTypography.revolutBody.copyWith(
            color: context.pockii.onSurfaceMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: AppTypography.revolutLabel.copyWith(
                color: context.pockii.onSurfaceMuted,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.revolutBlue,
            ),
            child: Text(
              'Simuler',
              style: AppTypography.revolutLabel.copyWith(
                color: context.pockii.onSurface,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSimulating = true;
    });

    try {
      final service = ref.read(simulationServiceProvider);
      await service.runSimulation();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Simulation terminée! Redémarrage recommandé.',
              style: AppTypography.revolutBody.copyWith(
                color: context.pockii.onSurface,
              ),
            ),
            backgroundColor: context.pockii.surfaceElevated,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur: $e',
              style: AppTypography.revolutBody.copyWith(
                color: context.pockii.onSurface,
              ),
            ),
            backgroundColor: context.pockii.surfaceElevated,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSimulating = false;
        });
      }
    }
  }
}

/// Revolut-style settings section container.
class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
    this.action,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.revolutMicro.copyWith(
                    color: iconColor,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              if (action != null) action!,
            ],
          ),
        ),
        RevolutCard(
          padding: EdgeInsets.zero,
          child: child,
        ),
      ],
    );
  }
}

/// Revolut-style settings tile.
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: AppColors.glassOverlay,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.revolutLabel.copyWith(
                      color: context.pockii.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.revolutMicro.copyWith(
                      color: context.pockii.onSurfaceMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// Budget Rules section (50/30/20 rule).
class _BudgetRulesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(budgetRuleSettingsProvider);

    return _SettingsSection(
      title: 'RÈGLE 50/30/20',
      icon: Icons.pie_chart_rounded,
      iconColor: AppColors.revolutGreen,
      action: TutorialHelpButton(tutorial: TutorialContent.rule503020, size: 18),
      child: Column(
        children: [
          _SettingsTile(
            title: settings.isEnabled ? 'Activée' : 'Désactivée',
            subtitle: 'Répartir ton budget: Besoins, Envies, Épargne',
            trailing: Switch(
              value: settings.isEnabled,
              onChanged: (_) {
                ref.read(budgetRuleSettingsProvider.notifier).toggleEnabled();
              },
              activeColor: AppColors.revolutGreen,
              activeTrackColor: AppColors.revolutGreen.withOpacity(0.3),
              inactiveTrackColor: context.pockii.border,
              inactiveThumbColor: context.pockii.onSurfaceMuted,
            ),
          ),
          if (settings.isEnabled) ...[
            Container(
              height: 0.5,
              color: context.pockii.border,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const BudgetAllocationPreview(),
                  const SizedBox(height: 8),
                  Text(
                    '${settings.needsPercentage}% Besoins • ${settings.wantsPercentage}% Envies • ${settings.savingsPercentage}% Épargne',
                    style: AppTypography.revolutMicro.copyWith(
                      color: context.pockii.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Provider for current budget period.
final _currentPeriodProvider = FutureProvider.autoDispose((ref) {
  final repository = ref.watch(budgetPeriodRepositoryProvider);
  return repository.ensureCurrentPeriodExists();
});
