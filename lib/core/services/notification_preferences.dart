import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/daos/app_settings_dao.dart';
import '../database/database_provider.dart';

/// Settings keys for notification preferences.
abstract class NotificationPreferenceKeys {
  static const budgetWarningsEnabled = 'notification_budget_warnings';
  static const subscriptionRemindersEnabled = 'notification_subscription_reminders';
  static const streakCelebrationsEnabled = 'notification_streak_celebrations';
  static const plannedExpenseRemindersEnabled = 'notification_planned_expense_reminders';
  static const morningTipsEnabled = 'notification_morning_tips';
  static const spendingAnomalyEnabled = 'notification_spending_anomaly';
}

/// Model for notification preferences.
class NotificationPreferences {
  const NotificationPreferences({
    required this.budgetWarningsEnabled,
    required this.subscriptionRemindersEnabled,
    required this.streakCelebrationsEnabled,
    required this.plannedExpenseRemindersEnabled,
    required this.morningTipsEnabled,
    required this.spendingAnomalyEnabled,
  });

  /// Default preferences (all enabled).
  static const defaults = NotificationPreferences(
    budgetWarningsEnabled: true,
    subscriptionRemindersEnabled: true,
    streakCelebrationsEnabled: true,
    plannedExpenseRemindersEnabled: true,
    morningTipsEnabled: true,
    spendingAnomalyEnabled: true,
  );

  final bool budgetWarningsEnabled;
  final bool subscriptionRemindersEnabled;
  final bool streakCelebrationsEnabled;
  final bool plannedExpenseRemindersEnabled;
  final bool morningTipsEnabled;
  final bool spendingAnomalyEnabled;

  NotificationPreferences copyWith({
    bool? budgetWarningsEnabled,
    bool? subscriptionRemindersEnabled,
    bool? streakCelebrationsEnabled,
    bool? plannedExpenseRemindersEnabled,
    bool? morningTipsEnabled,
    bool? spendingAnomalyEnabled,
  }) {
    return NotificationPreferences(
      budgetWarningsEnabled: budgetWarningsEnabled ?? this.budgetWarningsEnabled,
      subscriptionRemindersEnabled:
          subscriptionRemindersEnabled ?? this.subscriptionRemindersEnabled,
      streakCelebrationsEnabled:
          streakCelebrationsEnabled ?? this.streakCelebrationsEnabled,
      plannedExpenseRemindersEnabled:
          plannedExpenseRemindersEnabled ?? this.plannedExpenseRemindersEnabled,
      morningTipsEnabled: morningTipsEnabled ?? this.morningTipsEnabled,
      spendingAnomalyEnabled: spendingAnomalyEnabled ?? this.spendingAnomalyEnabled,
    );
  }
}

/// Service for managing notification preferences.
///
/// Persists user preferences for which notification types are enabled.
/// All preferences default to true (enabled) for new users.
///
/// Covers: FR39, Story 4.7
class NotificationPreferencesService {
  NotificationPreferencesService({
    required AppSettingsDao settingsDao,
  }) : _settingsDao = settingsDao;

  final AppSettingsDao _settingsDao;

  /// Get all notification preferences.
  Future<NotificationPreferences> getPreferences() async {
    final budgetWarnings = await _getBool(
      NotificationPreferenceKeys.budgetWarningsEnabled,
      defaultValue: true,
    );
    final subscriptionReminders = await _getBool(
      NotificationPreferenceKeys.subscriptionRemindersEnabled,
      defaultValue: true,
    );
    final streakCelebrations = await _getBool(
      NotificationPreferenceKeys.streakCelebrationsEnabled,
      defaultValue: true,
    );
    final plannedExpenseReminders = await _getBool(
      NotificationPreferenceKeys.plannedExpenseRemindersEnabled,
      defaultValue: true,
    );
    final morningTips = await _getBool(
      NotificationPreferenceKeys.morningTipsEnabled,
      defaultValue: true,
    );
    final spendingAnomaly = await _getBool(
      NotificationPreferenceKeys.spendingAnomalyEnabled,
      defaultValue: true,
    );

    return NotificationPreferences(
      budgetWarningsEnabled: budgetWarnings,
      subscriptionRemindersEnabled: subscriptionReminders,
      streakCelebrationsEnabled: streakCelebrations,
      plannedExpenseRemindersEnabled: plannedExpenseReminders,
      morningTipsEnabled: morningTips,
      spendingAnomalyEnabled: spendingAnomaly,
    );
  }

  /// Check if budget warning notifications are enabled.
  Future<bool> areBudgetWarningsEnabled() async {
    return _getBool(
      NotificationPreferenceKeys.budgetWarningsEnabled,
      defaultValue: true,
    );
  }

  /// Check if subscription reminder notifications are enabled.
  Future<bool> areSubscriptionRemindersEnabled() async {
    return _getBool(
      NotificationPreferenceKeys.subscriptionRemindersEnabled,
      defaultValue: true,
    );
  }

  /// Check if streak celebration notifications are enabled.
  Future<bool> areStreakCelebrationsEnabled() async {
    return _getBool(
      NotificationPreferenceKeys.streakCelebrationsEnabled,
      defaultValue: true,
    );
  }

  /// Set budget warning notifications enabled/disabled.
  Future<void> setBudgetWarningsEnabled(bool enabled) async {
    await _setBool(NotificationPreferenceKeys.budgetWarningsEnabled, enabled);
  }

  /// Set subscription reminder notifications enabled/disabled.
  Future<void> setSubscriptionRemindersEnabled(bool enabled) async {
    await _setBool(
      NotificationPreferenceKeys.subscriptionRemindersEnabled,
      enabled,
    );
  }

  /// Set streak celebration notifications enabled/disabled.
  Future<void> setStreakCelebrationsEnabled(bool enabled) async {
    await _setBool(
      NotificationPreferenceKeys.streakCelebrationsEnabled,
      enabled,
    );
  }

  /// Check if planned expense reminder notifications are enabled.
  Future<bool> arePlannedExpenseRemindersEnabled() async {
    return _getBool(
      NotificationPreferenceKeys.plannedExpenseRemindersEnabled,
      defaultValue: true,
    );
  }

  /// Set planned expense reminder notifications enabled/disabled.
  Future<void> setPlannedExpenseRemindersEnabled(bool enabled) async {
    await _setBool(NotificationPreferenceKeys.plannedExpenseRemindersEnabled, enabled);
  }

  /// Check if morning tips notifications are enabled.
  Future<bool> areMorningTipsEnabled() async {
    return _getBool(
      NotificationPreferenceKeys.morningTipsEnabled,
      defaultValue: true,
    );
  }

  /// Set morning tips notifications enabled/disabled.
  Future<void> setMorningTipsEnabled(bool enabled) async {
    await _setBool(NotificationPreferenceKeys.morningTipsEnabled, enabled);
  }

  /// Check if spending anomaly notifications are enabled.
  Future<bool> areSpendingAnomalyEnabled() async {
    return _getBool(
      NotificationPreferenceKeys.spendingAnomalyEnabled,
      defaultValue: true,
    );
  }

  /// Set spending anomaly notifications enabled/disabled.
  Future<void> setSpendingAnomalyEnabled(bool enabled) async {
    await _setBool(NotificationPreferenceKeys.spendingAnomalyEnabled, enabled);
  }

  /// Reset all preferences to defaults.
  Future<void> resetToDefaults() async {
    await _setBool(NotificationPreferenceKeys.budgetWarningsEnabled, true);
    await _setBool(NotificationPreferenceKeys.subscriptionRemindersEnabled, true);
    await _setBool(NotificationPreferenceKeys.streakCelebrationsEnabled, true);
    await _setBool(NotificationPreferenceKeys.plannedExpenseRemindersEnabled, true);
    await _setBool(NotificationPreferenceKeys.morningTipsEnabled, true);
    await _setBool(NotificationPreferenceKeys.spendingAnomalyEnabled, true);
  }

  Future<bool> _getBool(String key, {required bool defaultValue}) async {
    final value = await _settingsDao.getValue(key);
    if (value == null) return defaultValue;
    return value == 'true';
  }

  Future<void> _setBool(String key, bool value) async {
    await _settingsDao.setValue(key, value.toString());
  }
}

/// Provider for the NotificationPreferencesService.
final notificationPreferencesServiceProvider =
    Provider<NotificationPreferencesService>((ref) {
  final settingsDao = ref.watch(appSettingsDaoProvider);
  return NotificationPreferencesService(settingsDao: settingsDao);
});

/// Provider for notification preferences state.
final notificationPreferencesProvider =
    FutureProvider<NotificationPreferences>((ref) {
  final service = ref.watch(notificationPreferencesServiceProvider);
  return service.getPreferences();
});

/// StateNotifier for managing notification preferences with UI updates.
class NotificationPreferencesNotifier extends StateNotifier<NotificationPreferences> {
  NotificationPreferencesNotifier(this._service)
      : super(NotificationPreferences.defaults);

  final NotificationPreferencesService _service;

  /// Load preferences from storage.
  Future<void> load() async {
    state = await _service.getPreferences();
  }

  /// Toggle budget warnings preference.
  Future<void> toggleBudgetWarnings() async {
    final newValue = !state.budgetWarningsEnabled;
    await _service.setBudgetWarningsEnabled(newValue);
    state = state.copyWith(budgetWarningsEnabled: newValue);
  }

  /// Toggle subscription reminders preference.
  Future<void> toggleSubscriptionReminders() async {
    final newValue = !state.subscriptionRemindersEnabled;
    await _service.setSubscriptionRemindersEnabled(newValue);
    state = state.copyWith(subscriptionRemindersEnabled: newValue);
  }

  /// Toggle streak celebrations preference.
  Future<void> toggleStreakCelebrations() async {
    final newValue = !state.streakCelebrationsEnabled;
    await _service.setStreakCelebrationsEnabled(newValue);
    state = state.copyWith(streakCelebrationsEnabled: newValue);
  }

  /// Set budget warnings preference directly.
  Future<void> setBudgetWarnings({required bool enabled}) async {
    await _service.setBudgetWarningsEnabled(enabled);
    state = state.copyWith(budgetWarningsEnabled: enabled);
  }

  /// Set subscription reminders preference directly.
  Future<void> setSubscriptionReminders({required bool enabled}) async {
    await _service.setSubscriptionRemindersEnabled(enabled);
    state = state.copyWith(subscriptionRemindersEnabled: enabled);
  }

  /// Set streak celebrations preference directly.
  Future<void> setStreakCelebrations({required bool enabled}) async {
    await _service.setStreakCelebrationsEnabled(enabled);
    state = state.copyWith(streakCelebrationsEnabled: enabled);
  }

  /// Set planned expense reminders preference directly.
  Future<void> setPlannedExpenseReminders({required bool enabled}) async {
    await _service.setPlannedExpenseRemindersEnabled(enabled);
    state = state.copyWith(plannedExpenseRemindersEnabled: enabled);
  }

  /// Set morning tips preference directly.
  Future<void> setMorningTips({required bool enabled}) async {
    await _service.setMorningTipsEnabled(enabled);
    state = state.copyWith(morningTipsEnabled: enabled);
  }

  /// Set spending anomaly preference directly.
  Future<void> setSpendingAnomaly({required bool enabled}) async {
    await _service.setSpendingAnomalyEnabled(enabled);
    state = state.copyWith(spendingAnomalyEnabled: enabled);
  }
}

/// Provider for the NotificationPreferencesNotifier.
final notificationPreferencesNotifierProvider =
    StateNotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>(
        (ref) {
  final service = ref.watch(notificationPreferencesServiceProvider);
  return NotificationPreferencesNotifier(service);
});
