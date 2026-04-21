import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/finances/presentation/screens/finances_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/home/presentation/screens/revolut_home_screen.dart';
import '../../features/onboarding/presentation/providers/onboarding_provider.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/patterns/presentation/screens/patterns_locked_screen.dart';
import '../../features/planned_expenses/presentation/screens/planned_expenses_list_screen.dart';
import '../../features/settings/presentation/screens/notification_preferences_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/shell/presentation/screens/main_shell.dart';
import '../../features/savings_projects/presentation/screens/create_project_screen.dart';
import '../../features/savings_projects/presentation/screens/project_detail_screen.dart';
import '../../features/savings_projects/presentation/screens/projects_list_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/challenges/presentation/screens/challenges_screen.dart';
import '../../features/social/presentation/screens/social_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/subscriptions/presentation/screens/subscriptions_list_screen.dart';

/// Route paths as constants for type-safety.
abstract class AppRoutes {
  /// Splash screen route (initial)
  static const String splash = '/splash';

  /// Home screen route
  static const String home = '/';

  /// Onboarding route
  static const String onboarding = '/onboarding';

  /// History screen route
  static const String history = '/history';

  /// Finances screen route
  static const String finances = '/finances';

  /// Settings screen route
  static const String settings = '/settings';

  /// Patterns screen route
  static const String patterns = '/patterns';

  /// Subscriptions list screen route
  static const String subscriptions = '/subscriptions';

  /// Planned expenses list screen route
  static const String plannedExpenses = '/planned-expenses';

  /// Notification preferences screen route
  static const String notificationPreferences = '/settings/notifications';

  /// Savings projects list screen route
  static const String projects = '/projects';

  /// Create project screen route
  static const String createProject = '/projects/create';

  /// Project detail screen route (with id parameter)
  static const String projectDetail = '/projects/:id';

  /// Analytics screen route
  static const String analytics = '/analytics';

  /// Challenges screen route
  static const String challenges = '/challenges';

  /// Social screen route
  static const String social = '/social';
}

/// Provider for tracking if onboarding check is complete.
///
/// This prevents redirect loops during the initial onboarding check.
final _onboardingCheckCompleteProvider = StateProvider<bool>((ref) => false);

/// Provider for caching onboarding completed status.
final _onboardingCompletedCacheProvider = StateProvider<bool?>((ref) => null);

/// Provider for the app router.
///
/// Uses go_router for declarative routing with deep link support.
/// Handles redirect to onboarding if not completed.
/// Uses ShellRoute for persistent bottom navigation across main screens.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      final isSplashRoute = state.matchedLocation == AppRoutes.splash;
      final isOnboardingRoute = state.matchedLocation == AppRoutes.onboarding;

      // Don't redirect from splash - it handles its own navigation
      if (isSplashRoute) {
        return null;
      }

      // Check cached value first
      var onboardingCompleted = ref.read(_onboardingCompletedCacheProvider);

      if (onboardingCompleted == null) {
        // Need to fetch from database
        try {
          final completedAsync =
              await ref.read(onboardingCompletedProvider.future);
          onboardingCompleted = completedAsync;
          // Cache the result
          ref.read(_onboardingCompletedCacheProvider.notifier).state =
              completedAsync;
        } on Exception catch (_) {
          // If database not ready, assume onboarding not completed
          onboardingCompleted = false;
        }
      }

      // Mark check as complete
      if (!ref.read(_onboardingCheckCompleteProvider)) {
        ref.read(_onboardingCheckCompleteProvider.notifier).state = true;
      }

      // Redirect logic
      if (!onboardingCompleted && !isOnboardingRoute) {
        // Not completed and not on onboarding -> go to onboarding
        return AppRoutes.onboarding;
      }

      if (onboardingCompleted && isOnboardingRoute) {
        // Already completed but on onboarding -> go to home
        return AppRoutes.home;
      }

      // No redirect needed
      return null;
    },
    routes: [
      // Splash screen route (initial - shows daily tip)
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      // Onboarding route (no shell - standalone screen)
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      // Shell route for main tabs with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            pageBuilder: (context, state) => _buildTransitionPage(
              key: state.pageKey,
              child: const RevolutHomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.finances,
            name: 'finances',
            pageBuilder: (context, state) => _buildTransitionPage(
              key: state.pageKey,
              child: const FinancesScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.patterns,
            name: 'patterns',
            pageBuilder: (context, state) => _buildTransitionPage(
              key: state.pageKey,
              child: const PatternsLockedScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            pageBuilder: (context, state) => _buildTransitionPage(
              key: state.pageKey,
              child: const SettingsScreen(),
            ),
          ),
        ],
      ),
      // Standalone pages (full screen, no bottom nav)
      GoRoute(
        path: AppRoutes.history,
        name: 'history',
        pageBuilder: (context, state) => _buildTransitionPage(
          key: state.pageKey,
          child: const HistoryScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.subscriptions,
        name: 'subscriptions',
        pageBuilder: (context, state) => _buildTransitionPage(
          key: state.pageKey,
          child: const SubscriptionsListScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.plannedExpenses,
        name: 'planned-expenses',
        pageBuilder: (context, state) => _buildTransitionPage(
          key: state.pageKey,
          child: const PlannedExpensesListScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.notificationPreferences,
        name: 'notification-preferences',
        pageBuilder: (context, state) => _buildTransitionPage(
          key: state.pageKey,
          child: const NotificationPreferencesScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.projects,
        name: 'projects',
        pageBuilder: (context, state) => _buildTransitionPage(
          key: state.pageKey,
          child: const ProjectsListScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.createProject,
        name: 'create-project',
        pageBuilder: (context, state) => _buildTransitionPage(
          key: state.pageKey,
          child: const CreateProjectScreen(),
        ),
      ),
      GoRoute(
        path: '/projects/:id',
        name: 'project-detail',
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return _buildTransitionPage(
            key: state.pageKey,
            child: ProjectDetailScreen(projectId: id),
          );
        },
        routes: [
          GoRoute(
            path: 'edit',
            name: 'project-edit',
            pageBuilder: (context, state) {
              return _buildTransitionPage(
                key: state.pageKey,
                child: const CreateProjectScreen(),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.analytics,
        name: 'analytics',
        pageBuilder: (context, state) => _buildTransitionPage(
          key: state.pageKey,
          child: const AnalyticsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.challenges,
        name: 'challenges',
        pageBuilder: (context, state) => _buildTransitionPage(
          key: state.pageKey,
          child: const ChallengesScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.social,
        name: 'social',
        pageBuilder: (context, state) => _buildTransitionPage(
          key: state.pageKey,
          child: const SocialScreen(),
        ),
      ),
    ],
  );
});

/// Builds a page with slide transition (300ms as per NFR4).
CustomTransitionPage<void> _buildTransitionPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
        child: child,
      );
    },
    // NFR4: Screen transitions < 300ms (default is 300ms)
  );
}

/// Invalidates the onboarding cache, forcing a re-check.
///
/// Call this after completing onboarding to ensure redirect works.
void invalidateOnboardingCache(WidgetRef ref) {
  ref.invalidate(_onboardingCompletedCacheProvider);
  ref.invalidate(onboardingCompletedProvider);
}
