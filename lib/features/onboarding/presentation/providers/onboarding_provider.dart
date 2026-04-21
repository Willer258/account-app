import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/services/clock_service.dart';
import '../../domain/models/onboarding_state.dart';

/// Key used to store onboarding completion status in app_settings
const String kOnboardingCompletedKey = 'onboarding_completed';

/// Provider for checking if onboarding has been completed.
///
/// Returns true if the user has completed onboarding, false otherwise.
/// This is used by the router to determine initial route.
final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final settingsDao = ref.watch(appSettingsDaoProvider);
  final value = await settingsDao.getValue(kOnboardingCompletedKey);
  return value == 'true';
});

/// Provider for onboarding state management.
final onboardingStateProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>(
      OnboardingNotifier.new,
    );

/// Notifier for managing onboarding flow state.
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier(this._ref) : super(const OnboardingState());

  final Ref _ref;

  /// Navigate to the next page
  void nextPage() {
    if (!state.isLastPage) {
      state = state.copyWith(currentPage: state.currentPage + 1);
    }
  }

  /// Navigate to the previous page
  void previousPage() {
    if (state.currentPage > 0) {
      state = state.copyWith(currentPage: state.currentPage - 1);
    }
  }

  /// Skip intro and go directly to budget setup (page 3)
  void skipToSetup() {
    state = state.copyWith(currentPage: 3);
  }

  /// Update the budget amount
  void setBudgetAmount(int amount) {
    state = state.copyWith(budgetAmount: amount);
  }

  /// Clear any error
  void clearError() {
    state = state.copyWith();
  }

  /// Complete onboarding and create first budget period.
  ///
  /// Returns true if successful, false otherwise.
  Future<bool> completeOnboarding() async {
    if (!state.isBudgetValid) {
      state = state.copyWith(error: 'Montant requis');
      return false;
    }

    state = state.copyWith(isCompleting: true);

    try {
      final settingsDao = _ref.read(appSettingsDaoProvider);
      final budgetPeriodsDao = _ref.read(budgetPeriodsDaoProvider);
      final clock = _ref.read(clockProvider);

      final now = clock.now();
      final periodStart = DateTime(now.year, now.month, 1);
      // Last day of current month
      final periodEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // Create first budget period
      await budgetPeriodsDao.createBudgetPeriod(
        BudgetPeriodsCompanion.insert(
          monthlyBudgetFcfa: state.budgetAmount,
          startDate: periodStart,
          endDate: periodEnd,
        ),
      );

      // Mark onboarding as completed
      await settingsDao.setValue(kOnboardingCompletedKey, 'true');

      // Reset completing state (no error means success)
      state = OnboardingState(
        currentPage: state.currentPage,
        budgetAmount: state.budgetAmount,
      );
      return true;
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('Onboarding error: $e');
      // ignore: avoid_print
      print('Stack trace: $stackTrace');
      state = OnboardingState(
        currentPage: state.currentPage,
        budgetAmount: state.budgetAmount,
        error: 'Erreur: $e',
      );
      return false;
    }
  }
}
