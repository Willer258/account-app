import 'package:flutter/foundation.dart';

/// Represents the state of the onboarding flow.
@immutable
class OnboardingState {
  const OnboardingState({
    this.currentPage = 0,
    this.budgetAmount = 0,
    this.isCompleting = false,
    this.error,
  });

  /// Current page index (0-2)
  final int currentPage;

  /// Budget amount entered by user (in FCFA)
  final int budgetAmount;

  /// Whether onboarding completion is in progress
  final bool isCompleting;

  /// Error message if any
  final String? error;

  /// Total number of onboarding pages
  static const int totalPages = 5;

  /// Check if on last page (budget setup)
  bool get isLastPage => currentPage == totalPages - 1;

  /// Check if budget amount is valid
  bool get isBudgetValid => budgetAmount > 0;

  /// Check if can proceed to next page
  bool get canProceed => !isLastPage || isBudgetValid;

  /// Check if has error
  bool get hasError => error != null;

  OnboardingState copyWith({
    int? currentPage,
    int? budgetAmount,
    bool? isCompleting,
    String? error,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      isCompleting: isCompleting ?? this.isCompleting,
      error: error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OnboardingState &&
        other.currentPage == currentPage &&
        other.budgetAmount == budgetAmount &&
        other.isCompleting == isCompleting &&
        other.error == error;
  }

  @override
  int get hashCode {
    return Object.hash(currentPage, budgetAmount, isCompleting, error);
  }
}
