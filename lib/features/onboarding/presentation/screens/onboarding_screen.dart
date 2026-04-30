import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/pockii_colors.dart';
import '../../domain/models/onboarding_state.dart';
import '../providers/onboarding_provider.dart';
import '../../../../shared/utils/fcfa_formatter.dart';
import '../../../../shared/utils/money_input_formatter.dart';

/// Onboarding screen — Revolut-inspired redesign (US-010).
///
/// Pages:
///   0 — Welcome & Pockii branding
///   1 — 50/30/20 rule explained (visual cards)
///   2 — Emergency fund goal setup
///   3 — Budget setup (monthly income)
///   4 — First expense tutorial
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const int _totalPages = 4;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextPage() {
    final current = ref.read(onboardingStateProvider).currentPage;
    if (current < _totalPages - 1) {
      _fadeController.reverse().then((_) {
        ref.read(onboardingStateProvider.notifier).nextPage();
        _pageController.nextPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
        );
        _fadeController.forward();
      });
    }
  }

  void _previousPage() {
    final current = ref.read(onboardingStateProvider).currentPage;
    if (current > 0) {
      _fadeController.reverse().then((_) {
        ref.read(onboardingStateProvider.notifier).previousPage();
        _pageController.previousPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
        );
        _fadeController.forward();
      });
    }
  }

  Future<void> _handleComplete() async {
    HapticFeedback.mediumImpact();
    final success = await ref
        .read(onboardingStateProvider.notifier)
        .completeOnboarding();
    if (success && mounted) {
      invalidateOnboardingCache(ref);
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingStateProvider);

    return Scaffold(
      backgroundColor: context.pockii.background,
      body: Stack(
        children: [
          // Gradient background
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.revolutHeroGradient,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                _TopBar(
                  currentPage: state.currentPage,
                  totalPages: _totalPages,
                  onSkip: state.currentPage < 2
                      ? () {
                          _pageController.animateToPage(
                            2,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOutCubic,
                          );
                          ref
                              .read(onboardingStateProvider.notifier)
                              .skipToSetup();
                        }
                      : null,
                  onBack: state.currentPage > 0 ? _previousPage : null,
                ),

                // Page content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _WelcomePage(fadeAnimation: _fadeAnimation),
                      _FeaturesPage(fadeAnimation: _fadeAnimation),
                      _BudgetSetupPage(
                        fadeAnimation: _fadeAnimation,
                        value: state.budgetAmount,
                        onChanged: (amount) {
                          ref
                              .read(onboardingStateProvider.notifier)
                              .setBudgetAmount(amount);
                        },
                      ),
                      _TutorialPage(fadeAnimation: _fadeAnimation),
                    ],
                  ),
                ),

                // Bottom actions
                _BottomActions(
                  state: state,
                  totalPages: _totalPages,
                  onNext: _nextPage,
                  onComplete: _handleComplete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Top bar with progress dots and back/skip
// ─────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.currentPage,
    required this.totalPages,
    this.onSkip,
    this.onBack,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback? onSkip;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Back button
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              color: context.pockii.onSurface,
            )
          else
            const SizedBox(width: 48),

          // Progress dots
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalPages, (i) {
                final isActive = i == currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 24 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: isActive
                        ? AppColors.revolutBlue
                        : context.pockii.onSurfaceMuted.withOpacity(0.4),
                  ),
                );
              }),
            ),
          ),

          // Skip button
          if (onSkip != null)
            TextButton(
              onPressed: onSkip,
              child: Text(
                'Passer',
                style: AppTypography.revolutLabel.copyWith(
                  color: context.pockii.onSurfaceMuted,
                ),
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Page 0 — Welcome
// ─────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.fadeAnimation});

  final Animation<double> fadeAnimation;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo / brand mark
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.revolutBlue, AppColors.revolutPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.revolutBlue.withOpacity(0.4),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            Text(
              'Pockii',
              style: AppTypography.revolutDisplay.copyWith(
                color: context.pockii.onSurface,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.5,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            Text(
              'Ton argent, maîtrisé.',
              style: AppTypography.revolutSubtitle.copyWith(
                color: AppColors.revolutBlue,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            Text(
              'Pockii t\'aide à gérer ton budget intelligemment avec la méthode 50/30/20 — sans effort.',
              textAlign: TextAlign.center,
              style: AppTypography.revolutBody.copyWith(
                color: context.pockii.onSurfaceMuted,
                height: 1.6,
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Feature chips
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: const [
                _FeatureChip(icon: Icons.flash_on_rounded, label: 'Rapide'),
                _FeatureChip(icon: Icons.lock_rounded, label: 'Sécurisé'),
                _FeatureChip(
                  icon: Icons.insights_rounded,
                  label: 'Intelligent',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.glassOverlay,
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.revolutBlue, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.revolutLabel.copyWith(color: context.pockii.onSurface),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Page 1 — Features Overview
// ─────────────────────────────────────────────

class _FeaturesPage extends StatelessWidget {
  const _FeaturesPage({required this.fadeAnimation});

  final Animation<double> fadeAnimation;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xl),

            Text(
              'Tout ce que\nPockii fait pour toi',
              style: AppTypography.revolutTitle.copyWith(
                color: context.pockii.onSurface,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            _FeatureTile(
              icon: Icons.pie_chart_rounded,
              color: AppColors.revolutBlue,
              title: 'Règle 50/30/20',
              description: 'Répartis ton budget automatiquement entre besoins, envies et épargne.',
            ),
            const SizedBox(height: AppSpacing.md),
            _FeatureTile(
              icon: Icons.trending_up_rounded,
              color: AppColors.revolutGreen,
              title: 'Suivi en temps réel',
              description: 'Visualise tes dépenses, revenus et solde restant d\'un coup d\'œil.',
            ),
            const SizedBox(height: AppSpacing.md),
            _FeatureTile(
              icon: Icons.event_note_rounded,
              color: AppColors.revolutAmber,
              title: 'Dépenses prévues',
              description: 'Planifie tes futures dépenses pour ne jamais être pris au dépourvu.',
            ),
            const SizedBox(height: AppSpacing.md),
            _FeatureTile(
              icon: Icons.repeat_rounded,
              color: AppColors.revolutPurple,
              title: 'Abonnements',
              description: 'Garde un œil sur tes charges récurrentes mensuelles.',
            ),
            const SizedBox(height: AppSpacing.md),
            _FeatureTile(
              icon: Icons.savings_rounded,
              color: AppColors.revolutGreen,
              title: 'Projets d\'épargne',
              description: 'Crée des cagnottes et suis ta progression vers tes objectifs.',
            ),
            const SizedBox(height: AppSpacing.md),
            _FeatureTile(
              icon: Icons.shield_rounded,
              color: AppColors.revolutBlue,
              title: 'Fonds d\'urgence',
              description: 'Constitue une réserve de 3 à 6 mois pour les imprévus.',
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.revolutLabel.copyWith(
                  color: context.pockii.onSurface,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTypography.revolutMicro.copyWith(
                  color: context.pockii.onSurfaceMuted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.revolutMicro.copyWith(
                color: context.pockii.onSurfaceMuted,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Page 3 — Budget Setup
// ─────────────────────────────────────────────

class _BudgetSetupPage extends StatefulWidget {
  const _BudgetSetupPage({
    required this.fadeAnimation,
    required this.value,
    required this.onChanged,
  });

  final Animation<double> fadeAnimation;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_BudgetSetupPage> createState() => _BudgetSetupPageState();
}

class _BudgetSetupPageState extends State<_BudgetSetupPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value > 0 ? FcfaFormatter.formatCompact(widget.value) : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.fadeAnimation,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.xl,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xxl),

            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.revolutBlue.withOpacity(0.15),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.revolutBlue,
                size: 32,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            Text(
              'Ton budget\nmensuel',
              style: AppTypography.revolutTitle.copyWith(
                color: context.pockii.onSurface,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            Text(
              'Saisis tes revenus mensuels nets. Pockii calculera automatiquement tes limites 50/30/20.',
              style: AppTypography.revolutBody.copyWith(
                color: context.pockii.onSurfaceMuted,
                height: 1.6,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: context.pockii.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [MoneyInputFormatter()],
                      style: AppTypography.revolutSubtitle.copyWith(
                        color: context.pockii.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        hintText: '150 000',
                        hintStyle: AppTypography.revolutSubtitle.copyWith(
                          color: context.pockii.onSurfaceMuted,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (val) {
                        widget.onChanged(MoneyInputFormatter.parse(val));
                      },
                    ),
                  ),
                  Text(
                    FcfaFormatter.symbol,
                    style: AppTypography.revolutBody.copyWith(
                      color: AppColors.revolutBlue,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            _InfoTile(
              icon: Icons.info_outline_rounded,
              color: AppColors.revolutBlue,
              text:
                  'Tu pourras modifier ce montant à tout moment dans tes paramètres.',
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Page 4 — First Expense Tutorial
// ─────────────────────────────────────────────

class _TutorialPage extends StatelessWidget {
  const _TutorialPage({required this.fadeAnimation});

  final Animation<double> fadeAnimation;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ajoute ta\npremière dépense',
              style: AppTypography.revolutTitle.copyWith(
                color: context.pockii.onSurface,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            Text(
              'C\'est aussi simple que ça :',
              style: AppTypography.revolutBody.copyWith(
                color: context.pockii.onSurfaceMuted,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            _TutorialStep(
              step: 1,
              icon: Icons.add_circle_rounded,
              color: AppColors.revolutBlue,
              title: 'Appuie sur le + en bas',
              description: 'Le bouton flottant sur l\'écran principal.',
            ),
            const SizedBox(height: AppSpacing.md),
            _TutorialStep(
              step: 2,
              icon: Icons.edit_rounded,
              color: AppColors.revolutPurple,
              title: 'Saisis le montant',
              description: 'Choisis la catégorie et décris la dépense.',
            ),
            const SizedBox(height: AppSpacing.md),
            _TutorialStep(
              step: 3,
              icon: Icons.check_circle_rounded,
              color: AppColors.revolutGreen,
              title: 'C\'est enregistré !',
              description: 'Ton budget se met à jour en temps réel.',
            ),

            const SizedBox(height: AppSpacing.xl),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    AppColors.revolutBlue.withOpacity(0.2),
                    AppColors.revolutPurple.withOpacity(0.1),
                  ],
                ),
                border: Border.all(
                  color: AppColors.revolutBlue.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.rocket_launch_rounded,
                    color: AppColors.revolutBlue,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Tu es prêt·e ! Lance-toi et prends le contrôle de ton argent. 🚀',
                      style: AppTypography.revolutBody.copyWith(
                        color: context.pockii.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialStep extends StatelessWidget {
  const _TutorialStep({
    required this.step,
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  final int step;
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: context.pockii.surface,
        border: Border.all(color: context.pockii.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.revolutSubtitle.copyWith(
                    color: context.pockii.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTypography.revolutMicro.copyWith(
                    color: context.pockii.onSurfaceMuted,
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

// ─────────────────────────────────────────────
// Bottom Actions
// ─────────────────────────────────────────────

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.state,
    required this.totalPages,
    required this.onNext,
    required this.onComplete,
  });

  final OnboardingState state;
  final int totalPages;
  final VoidCallback onNext;
  final VoidCallback onComplete;

  bool get _isLastPage => state.currentPage == totalPages - 1;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                state.error!,
                style: AppTypography.revolutMicro.copyWith(
                  color: AppColors.revolutRed,
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: _isLastPage && !state.isBudgetValid
                      ? [
                          context.pockii.onSurfaceMuted.withOpacity(0.3),
                          context.pockii.onSurfaceMuted.withOpacity(0.3),
                        ]
                      : [AppColors.revolutBlue, AppColors.revolutBlueDark],
                ),
                boxShadow: _isLastPage && !state.isBudgetValid
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.revolutBlue.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: ElevatedButton(
                onPressed: _isLastPage
                    ? (state.isBudgetValid && !state.isCompleting
                          ? onComplete
                          : null)
                    : onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: state.isCompleting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        _isLastPage ? 'Commencer 🚀' : 'Continuer',
                        style: AppTypography.revolutLabel.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
