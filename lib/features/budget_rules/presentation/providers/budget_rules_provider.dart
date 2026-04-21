import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/clock_service.dart';
import '../../../home/presentation/providers/budget_provider.dart';
import '../../../transactions/data/transaction_repository.dart';
import '../../../transactions/domain/models/transaction_type.dart';
import '../../data/budget_rules_repository.dart';
import '../../domain/enums/expense_category.dart';
import '../../domain/models/budget_allocation.dart';
import '../../domain/models/emergency_fund.dart';

/// State notifier for budget rule settings (50/30/20).
class BudgetRuleNotifier extends StateNotifier<BudgetRuleSettings> {
  BudgetRuleNotifier(this._ref)
      : super(BudgetRuleSettings.default503020());

  final Ref _ref;
  BudgetRulesRepository? _repository;

  /// Load settings from repository.
  void loadFromRepository(BudgetRulesRepository repo) {
    _repository = repo;
    state = repo.getBudgetRuleSettings();
  }

  /// Toggle the budget rule on/off.
  Future<void> toggleEnabled() async {
    final newSettings = state.copyWith(isEnabled: !state.isEnabled);
    await _repository?.saveBudgetRuleSettings(newSettings);
    state = newSettings;
  }

  /// Update the percentage allocations.
  Future<void> updatePercentages({
    int? needs,
    int? wants,
    int? savings,
  }) async {
    final newSettings = state.copyWith(
      needsPercentage: needs,
      wantsPercentage: wants,
      savingsPercentage: savings,
    );
    await _repository?.saveBudgetRuleSettings(newSettings);
    state = newSettings;
  }

  /// Reset to default 50/30/20.
  Future<void> resetToDefault() async {
    final newSettings = state.copyWith(
      needsPercentage: 50,
      wantsPercentage: 30,
      savingsPercentage: 20,
    );
    await _repository?.saveBudgetRuleSettings(newSettings);
    state = newSettings;
  }
}

/// State notifier for emergency fund settings.
class EmergencyFundNotifier extends StateNotifier<EmergencyFundSettings> {
  EmergencyFundNotifier(this._ref)
      : super(EmergencyFundSettings.defaultSettings());

  final Ref _ref;
  BudgetRulesRepository? _repository;

  /// Load settings from repository.
  void loadFromRepository(BudgetRulesRepository repo) {
    _repository = repo;
    state = repo.getEmergencyFundSettings();
  }

  /// Toggle the emergency fund feature on/off.
  Future<void> toggleEnabled() async {
    final newSettings = state.copyWith(isEnabled: !state.isEnabled);
    await _repository?.saveEmergencyFundSettings(newSettings);
    state = newSettings;
  }

  /// Set the monthly salary.
  Future<void> setMonthlySalary(int salary) async {
    final newSettings = state.copyWith(
      monthlySalary: salary,
      isEnabled: true,
    );
    await _repository?.saveEmergencyFundSettings(newSettings);
    state = newSettings;
  }

  /// Set the target number of months.
  Future<void> setTargetMonths(int months) async {
    final newSettings = state.copyWith(targetMonths: months);
    await _repository?.saveEmergencyFundSettings(newSettings);
    state = newSettings;
  }

  /// Update the current savings amount.
  Future<void> updateCurrentSavings(int amount) async {
    final newSettings = state.copyWith(currentSavings: amount);
    await _repository?.saveEmergencyFundSettings(newSettings);
    state = newSettings;
  }

  /// Add to current savings.
  Future<void> addToSavings(int amount) async {
    final newSettings = state.copyWith(
      currentSavings: state.currentSavings + amount,
    );
    await _repository?.saveEmergencyFundSettings(newSettings);
    state = newSettings;
  }
}

/// Async provider for budget rule settings.
final budgetRuleSettingsAsyncProvider =
    FutureProvider<BudgetRuleSettings>((ref) async {
  final repo = await ref.watch(budgetRulesRepositoryProvider.future);
  return repo.getBudgetRuleSettings();
});

/// Provider for budget rule settings with notifier.
final budgetRuleSettingsProvider =
    StateNotifierProvider<BudgetRuleNotifier, BudgetRuleSettings>((ref) {
  final notifier = BudgetRuleNotifier(ref);

  // Load settings eagerly
  Future<void> loadSettings() async {
    try {
      final repo = await ref.read(budgetRulesRepositoryProvider.future);
      notifier.loadFromRepository(repo);
    } catch (_) {
      // Will retry on next access
    }
  }

  loadSettings();

  return notifier;
});

/// Async provider for emergency fund settings.
final emergencyFundSettingsAsyncProvider =
    FutureProvider<EmergencyFundSettings>((ref) async {
  final repo = await ref.watch(budgetRulesRepositoryProvider.future);
  return repo.getEmergencyFundSettings();
});

/// Provider for emergency fund settings with notifier.
final emergencyFundSettingsProvider =
    StateNotifierProvider<EmergencyFundNotifier, EmergencyFundSettings>((ref) {
  final notifier = EmergencyFundNotifier(ref);

  // Load settings eagerly
  Future<void> loadSettings() async {
    try {
      final repo = await ref.read(budgetRulesRepositoryProvider.future);
      notifier.loadFromRepository(repo);
    } catch (_) {
      // Will retry on next access
    }
  }

  loadSettings();

  return notifier;
});

/// Spending breakdown by ExpenseCategory for current month.
class CategorySpending {
  const CategorySpending({
    required this.needsSpent,
    required this.wantsSpent,
    required this.savingsSpent,
  });

  /// Total spent on needs (essential expenses).
  final int needsSpent;

  /// Total spent on wants (lifestyle/entertainment).
  final int wantsSpent;

  /// Total saved/invested.
  final int savingsSpent;

  /// Total spending across all categories.
  int get totalSpent => needsSpent + wantsSpent + savingsSpent;

  /// Empty spending.
  static const empty = CategorySpending(
    needsSpent: 0,
    wantsSpent: 0,
    savingsSpent: 0,
  );
}

/// Provider for current month spending by ExpenseCategory.
///
/// Watches transactions for the current month and calculates
/// how much was spent in each 50/30/20 category.
final categorySpendingProvider = StreamProvider<CategorySpending>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  final clock = ref.watch(clockProvider);
  final now = clock.now();

  return repository.watchTransactionsForMonth(now).map((transactions) {
    int needsSpent = 0;
    int wantsSpent = 0;
    int savingsSpent = 0;

    for (final transaction in transactions) {
      // Only count expenses, not income
      if (transaction.type == TransactionType.income) {
        continue;
      }

      final category = transaction.budgetCategory;
      switch (category) {
        case ExpenseCategory.needs:
          needsSpent += transaction.amountFcfa;
        case ExpenseCategory.wants:
          wantsSpent += transaction.amountFcfa;
        case ExpenseCategory.savings:
          savingsSpent += transaction.amountFcfa;
      }
    }

    return CategorySpending(
      needsSpent: needsSpent,
      wantsSpent: wantsSpent,
      savingsSpent: savingsSpent,
    );
  });
});

/// Provider for the full budget allocation with real spending data.
///
/// Combines budget settings, current budget, and actual spending
/// to provide a complete 50/30/20 breakdown.
final budgetAllocationProvider = Provider<BudgetAllocation?>((ref) {
  final settings = ref.watch(budgetRuleSettingsProvider);

  if (!settings.isEnabled) {
    return null;
  }

  final budgetState = ref.watch(budgetStateProvider);
  final spendingAsync = ref.watch(categorySpendingProvider);

  return spendingAsync.when(
    data: (spending) => BudgetAllocation.calculate(
      totalBudget: budgetState.totalBudget,
      needsSpent: spending.needsSpent,
      wantsSpent: spending.wantsSpent,
      savingsSpent: spending.savingsSpent,
      settings: settings,
    ),
    loading: () => null,
    error: (_, __) => null,
  );
});
