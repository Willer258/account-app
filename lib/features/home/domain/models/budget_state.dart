import 'package:flutter/foundation.dart';

/// Budget status for visual color coding
enum BudgetStatus {
  /// Budget is healthy (>30% remaining) - Green
  ok,

  /// Budget needs attention (10-30% remaining) - Orange
  warning,

  /// Budget is critical (<10% or negative) - Red
  danger,
}

/// Represents the current state of the user's budget for a period.
///
/// All monetary values are in FCFA (int, no decimals).
@immutable
class BudgetState {
  const BudgetState({
    required this.totalBudget,
    required this.remainingBudget,
    required this.periodStart,
    required this.periodEnd,
    this.totalExpenses = 0,
    this.totalSubscriptions = 0,
    this.pendingPlannedExpenses = 0,
    this.isLoading = false,
    this.error,
    this.hasTimeInconsistency = false,
  });

  /// Initial loading state
  ///
  /// [now] is optional and defaults to a placeholder date.
  /// The actual dates will be set when budget data loads.
  factory BudgetState.initial({DateTime? now}) {
    // Use placeholder dates - real dates come from BudgetCalculationResult
    final date = now ?? DateTime(2000);
    return BudgetState(
      totalBudget: 0,
      remainingBudget: 0,
      periodStart: DateTime(date.year, date.month),
      periodEnd: DateTime(date.year, date.month + 1, 0),
      isLoading: true,
    );
  }

  /// Empty state (no budget configured)
  ///
  /// [now] should be provided from Clock.now() for testability.
  factory BudgetState.empty({DateTime? now}) {
    final date = now ?? DateTime(2000);
    return BudgetState(
      totalBudget: 0,
      remainingBudget: 0,
      periodStart: DateTime(date.year, date.month),
      periodEnd: DateTime(date.year, date.month + 1, 0),
    );
  }

  /// Error state
  ///
  /// [now] should be provided from Clock.now() for testability.
  factory BudgetState.withError(String errorMessage, {DateTime? now}) {
    final date = now ?? DateTime(2000);
    return BudgetState(
      totalBudget: 0,
      remainingBudget: 0,
      periodStart: DateTime(date.year, date.month),
      periodEnd: DateTime(date.year, date.month + 1, 0),
      error: errorMessage,
    );
  }

  /// Total budget for the period (in FCFA)
  final int totalBudget;

  /// Remaining budget after all expenses (in FCFA)
  /// Can be negative if overspent
  final int remainingBudget;

  /// Start date of the budget period
  final DateTime periodStart;

  /// End date of the budget period
  final DateTime periodEnd;

  /// Total transaction expenses (type = expense) in FCFA
  final int totalExpenses;

  /// Total active subscriptions monthly amount in FCFA
  final int totalSubscriptions;

  /// Whether budget data is currently loading
  final bool isLoading;

  /// Error message if loading failed
  final String? error;

  /// Whether a time inconsistency was detected (clock moved backward)
  final bool hasTimeInconsistency;

  /// Total amount of pending planned expenses (in FCFA)
  final int pendingPlannedExpenses;

  /// Remaining budget before planned expenses are deducted.
  /// This is the "current" balance before future commitments.
  int get remainingBeforePlanned => remainingBudget + pendingPlannedExpenses;

  /// Whether there are pending planned expenses.
  bool get hasPlannedExpenses => pendingPlannedExpenses > 0;

  /// Percentage of budget remaining (0.0 to 1.0+)
  ///
  /// Returns 0 if total budget is zero or negative.
  /// Can return values > 1.0 if remaining > total (overfunded).
  /// Can return negative values if overspent.
  double get percentageRemaining {
    if (totalBudget <= 0) return 0;
    return remainingBudget / totalBudget;
  }

  /// Budget status for color coding
  ///
  /// - [BudgetStatus.ok]: >30% remaining (green)
  /// - [BudgetStatus.warning]: 10-30% remaining (orange)
  /// - [BudgetStatus.danger]: <10% remaining or negative (red)
  BudgetStatus get status {
    if (remainingBudget < 0) return BudgetStatus.danger;
    final percentage = percentageRemaining;
    if (percentage > 0.30) return BudgetStatus.ok;
    if (percentage > 0.10) return BudgetStatus.warning;
    return BudgetStatus.danger;
  }

  /// Check if budget is negative (overspent)
  bool get isOverspent => remainingBudget < 0;

  /// Check if budget data has an error
  bool get hasError => error != null;

  /// Create a copy with updated fields
  BudgetState copyWith({
    int? totalBudget,
    int? remainingBudget,
    DateTime? periodStart,
    DateTime? periodEnd,
    int? totalExpenses,
    int? totalSubscriptions,
    int? pendingPlannedExpenses,
    bool? isLoading,
    String? error,
    bool? hasTimeInconsistency,
  }) {
    return BudgetState(
      totalBudget: totalBudget ?? this.totalBudget,
      remainingBudget: remainingBudget ?? this.remainingBudget,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      totalSubscriptions: totalSubscriptions ?? this.totalSubscriptions,
      pendingPlannedExpenses:
          pendingPlannedExpenses ?? this.pendingPlannedExpenses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasTimeInconsistency: hasTimeInconsistency ?? this.hasTimeInconsistency,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BudgetState &&
        other.totalBudget == totalBudget &&
        other.remainingBudget == remainingBudget &&
        other.periodStart == periodStart &&
        other.periodEnd == periodEnd &&
        other.totalExpenses == totalExpenses &&
        other.totalSubscriptions == totalSubscriptions &&
        other.pendingPlannedExpenses == pendingPlannedExpenses &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.hasTimeInconsistency == hasTimeInconsistency;
  }

  @override
  int get hashCode {
    return Object.hash(
      totalBudget,
      remainingBudget,
      periodStart,
      periodEnd,
      totalExpenses,
      totalSubscriptions,
      pendingPlannedExpenses,
      isLoading,
      error,
      hasTimeInconsistency,
    );
  }

  @override
  String toString() {
    final timeWarning = hasTimeInconsistency ? ', timeWarning: true' : '';
    return 'BudgetState('
        'totalBudget: $totalBudget, '
        'remainingBudget: $remainingBudget, '
        'status: $status, '
        'isLoading: $isLoading'
        '$timeWarning)';
  }
}
