import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/services/clock_service.dart';
import '../../../planned_expenses/data/planned_expense_repository.dart';
import '../../../subscriptions/data/subscription_repository.dart';
import '../../../transactions/data/transaction_repository.dart';
import '../../data/repositories/budget_period_repository.dart';

/// Result of a budget calculation.
class BudgetCalculationResult {
  const BudgetCalculationResult({
    required this.totalBudget,
    required this.totalExpenses,
    required this.totalSubscriptions,
    required this.totalPlannedExpenses,
    required this.remainingBudget,
    required this.periodStart,
    required this.periodEnd,
    this.hasTimeInconsistency = false,
  });

  /// Total budget for the period (in FCFA)
  final int totalBudget;

  /// Sum of all expenses in the period (in FCFA)
  final int totalExpenses;

  /// Sum of all active subscriptions due in the period (in FCFA)
  final int totalSubscriptions;

  /// Sum of all planned expenses in the period (in FCFA)
  final int totalPlannedExpenses;

  /// Remaining budget: totalBudget - totalExpenses - totalSubscriptions - totalPlannedExpenses
  final int remainingBudget;

  /// Start date of the current period
  final DateTime periodStart;

  /// End date of the current period
  final DateTime periodEnd;

  /// True if a time inconsistency was detected (clock moved backward)
  final bool hasTimeInconsistency;

  /// Remaining budget before planned expenses are deducted.
  /// This is the "current" balance the user actually has available.
  int get remainingBeforePlanned => remainingBudget + totalPlannedExpenses;

  /// Whether there are pending planned expenses affecting the budget.
  bool get hasPlannedExpenses => totalPlannedExpenses > 0;

  /// Percentage of budget remaining (0.0 to 1.0)
  double get percentageRemaining {
    if (totalBudget <= 0) return 0;
    return (remainingBudget / totalBudget).clamp(0.0, 1.0);
  }

  /// Whether the budget is overspent (negative remaining)
  bool get isOverspent => remainingBudget < 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BudgetCalculationResult &&
        other.totalBudget == totalBudget &&
        other.totalExpenses == totalExpenses &&
        other.totalSubscriptions == totalSubscriptions &&
        other.totalPlannedExpenses == totalPlannedExpenses &&
        other.remainingBudget == remainingBudget &&
        other.periodStart == periodStart &&
        other.periodEnd == periodEnd &&
        other.hasTimeInconsistency == hasTimeInconsistency;
  }

  @override
  int get hashCode {
    return Object.hash(
      totalBudget,
      totalExpenses,
      totalSubscriptions,
      totalPlannedExpenses,
      remainingBudget,
      periodStart,
      periodEnd,
      hasTimeInconsistency,
    );
  }
}

/// Service for calculating the remaining budget.
///
/// Implements the formula:
/// Remaining = Monthly Budget - Σ(Expenses) - Σ(Subscriptions) - Σ(Planned Expenses)
///
/// Covers: FR5 (budget calculation formula)
class BudgetCalculationService {
  BudgetCalculationService({
    required BudgetPeriodRepository budgetPeriodRepository,
    required TransactionRepository transactionRepository,
    required SubscriptionRepository subscriptionRepository,
    required PlannedExpenseRepository plannedExpenseRepository,
    required Clock clock,
  })  : _budgetPeriodRepository = budgetPeriodRepository,
        _transactionRepository = transactionRepository,
        _subscriptionRepository = subscriptionRepository,
        _plannedExpenseRepository = plannedExpenseRepository,
        _clock = clock;

  final BudgetPeriodRepository _budgetPeriodRepository;
  final TransactionRepository _transactionRepository;
  final SubscriptionRepository _subscriptionRepository;
  final PlannedExpenseRepository _plannedExpenseRepository;
  final Clock _clock;

  /// Timestamp of the last calculation, used for time inconsistency detection
  DateTime? _lastCalculationTime;

  /// Calculates the current remaining budget.
  ///
  /// Creates a new period if one doesn't exist for the current month.
  /// Returns a [BudgetCalculationResult] with all budget details.
  Future<BudgetCalculationResult> calculateRemainingBudget() async {
    // Check for time inconsistency
    var hasTimeInconsistency = false;
    if (_lastCalculationTime != null) {
      hasTimeInconsistency =
          _budgetPeriodRepository.detectTimeInconsistency(_lastCalculationTime!);
    }
    _lastCalculationTime = _clock.now();

    // Ensure we have a current period
    final period = await _budgetPeriodRepository.ensureCurrentPeriodExists();

    // Calculate totals
    final totalExpenses = await _calculateTotalExpenses(period);
    final totalIncome = await _calculateTotalIncome(period);
    final totalSubscriptions = await _calculateTotalSubscriptions(period);
    final totalPlannedExpenses = await _calculateTotalPlannedExpenses(period);

    final remaining = period.monthlyBudgetFcfa +
        totalIncome -
        totalExpenses -
        totalSubscriptions -
        totalPlannedExpenses;

    return BudgetCalculationResult(
      totalBudget: period.monthlyBudgetFcfa,
      totalExpenses: totalExpenses,
      totalSubscriptions: totalSubscriptions,
      totalPlannedExpenses: totalPlannedExpenses,
      remainingBudget: remaining,
      periodStart: period.startDate,
      periodEnd: period.endDate,
      hasTimeInconsistency: hasTimeInconsistency,
    );
  }

  /// Calculates total expenses for the period.
  ///
  /// Queries transactions table for expenses in [period] date range
  /// and sums amounts where type = expense.
  Future<int> _calculateTotalExpenses(BudgetPeriod period) async {
    assert(period.id > 0); // Verify period is valid
    // Use the period's start date to calculate the month's expenses
    return _transactionRepository.getExpensesSumForMonth(period.startDate);
  }

  /// Calculates total income for the period.
  ///
  /// Queries transactions table for income in [period] date range
  /// and sums amounts where type = income.
  Future<int> _calculateTotalIncome(BudgetPeriod period) async {
    assert(period.id > 0);
    return _transactionRepository.getIncomeSumForMonth(period.startDate);
  }

  /// Calculates total subscriptions due in the period.
  ///
  /// Queries active subscriptions and calculates the total monthly equivalent
  /// amount using prorated values:
  /// - Monthly subscriptions: full amount
  /// - Weekly subscriptions: amount × 4.33 (average weeks per month)
  /// - Yearly subscriptions: amount ÷ 12
  Future<int> _calculateTotalSubscriptions(BudgetPeriod period) async {
    assert(period.id > 0);
    return _subscriptionRepository.getTotalMonthlyAmount();
  }

  /// Calculates total planned expenses in the period.
  ///
  /// Queries pending planned expenses for the current period and sums their amounts.
  /// Only pending expenses are counted - converted expenses are already reflected
  /// in the transactions sum.
  Future<int> _calculateTotalPlannedExpenses(BudgetPeriod period) async {
    assert(period.id > 0);
    return _plannedExpenseRepository.getTotalPendingAmountForMonth(
      period.startDate,
    );
  }

  /// Gets the current period without creating one if it doesn't exist.
  Future<BudgetPeriod?> getCurrentPeriod() async {
    return _budgetPeriodRepository.getCurrentPeriod();
  }

  /// Checks if the month has changed since [lastKnownDate].
  ///
  /// Used to trigger period transitions.
  bool hasMonthChanged(DateTime lastKnownDate) {
    return _budgetPeriodRepository.hasMonthChanged(lastKnownDate);
  }

  /// Resets the time inconsistency detection.
  ///
  /// Call this after the user acknowledges the time warning.
  void resetTimeInconsistencyDetection() {
    _lastCalculationTime = null;
  }
}

/// Provider for BudgetCalculationService.
final budgetCalculationServiceProvider = Provider<BudgetCalculationService>((ref) {
  final budgetPeriodRepository = ref.watch(budgetPeriodRepositoryProvider);
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  final subscriptionRepository = ref.watch(subscriptionRepositoryProvider);
  final plannedExpenseRepository = ref.watch(plannedExpenseRepositoryProvider);
  final clock = ref.watch(clockProvider);

  return BudgetCalculationService(
    budgetPeriodRepository: budgetPeriodRepository,
    transactionRepository: transactionRepository,
    subscriptionRepository: subscriptionRepository,
    plannedExpenseRepository: plannedExpenseRepository,
    clock: clock,
  );
});
