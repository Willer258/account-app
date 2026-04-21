import 'package:pockii/core/database/daos/app_settings_dao.dart';
import 'package:pockii/core/services/notification_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppSettingsDao extends Mock implements AppSettingsDao {}

void main() {
  late MockAppSettingsDao mockSettingsDao;
  late NotificationPreferencesService service;

  setUp(() {
    mockSettingsDao = MockAppSettingsDao();
    service = NotificationPreferencesService(settingsDao: mockSettingsDao);

    // Default: no existing settings (defaults will apply)
    when(() => mockSettingsDao.getValue(any())).thenAnswer((_) async => null);
    when(() => mockSettingsDao.setValue(any(), any()))
        .thenAnswer((_) async => 1);
  });

  group('NotificationPreferencesService', () {
    group('getPreferences', () {
      test('returns defaults when no settings exist', () async {
        final prefs = await service.getPreferences();

        expect(prefs.budgetWarningsEnabled, isTrue);
        expect(prefs.subscriptionRemindersEnabled, isTrue);
        expect(prefs.streakCelebrationsEnabled, isTrue);
      });

      test('returns saved preferences', () async {
        when(() => mockSettingsDao.getValue(
                NotificationPreferenceKeys.budgetWarningsEnabled))
            .thenAnswer((_) async => 'false');
        when(() => mockSettingsDao.getValue(
                NotificationPreferenceKeys.subscriptionRemindersEnabled))
            .thenAnswer((_) async => 'true');
        when(() => mockSettingsDao.getValue(
                NotificationPreferenceKeys.streakCelebrationsEnabled))
            .thenAnswer((_) async => 'false');

        final prefs = await service.getPreferences();

        expect(prefs.budgetWarningsEnabled, isFalse);
        expect(prefs.subscriptionRemindersEnabled, isTrue);
        expect(prefs.streakCelebrationsEnabled, isFalse);
      });
    });

    group('areBudgetWarningsEnabled', () {
      test('returns true by default', () async {
        final result = await service.areBudgetWarningsEnabled();

        expect(result, isTrue);
      });

      test('returns false when disabled', () async {
        when(() => mockSettingsDao.getValue(
                NotificationPreferenceKeys.budgetWarningsEnabled))
            .thenAnswer((_) async => 'false');

        final result = await service.areBudgetWarningsEnabled();

        expect(result, isFalse);
      });
    });

    group('areSubscriptionRemindersEnabled', () {
      test('returns true by default', () async {
        final result = await service.areSubscriptionRemindersEnabled();

        expect(result, isTrue);
      });

      test('returns false when disabled', () async {
        when(() => mockSettingsDao.getValue(
                NotificationPreferenceKeys.subscriptionRemindersEnabled))
            .thenAnswer((_) async => 'false');

        final result = await service.areSubscriptionRemindersEnabled();

        expect(result, isFalse);
      });
    });

    group('areStreakCelebrationsEnabled', () {
      test('returns true by default', () async {
        final result = await service.areStreakCelebrationsEnabled();

        expect(result, isTrue);
      });

      test('returns false when disabled', () async {
        when(() => mockSettingsDao.getValue(
                NotificationPreferenceKeys.streakCelebrationsEnabled))
            .thenAnswer((_) async => 'false');

        final result = await service.areStreakCelebrationsEnabled();

        expect(result, isFalse);
      });
    });

    group('setBudgetWarningsEnabled', () {
      test('saves true value', () async {
        await service.setBudgetWarningsEnabled(true);

        verify(() => mockSettingsDao.setValue(
              NotificationPreferenceKeys.budgetWarningsEnabled,
              'true',
            )).called(1);
      });

      test('saves false value', () async {
        await service.setBudgetWarningsEnabled(false);

        verify(() => mockSettingsDao.setValue(
              NotificationPreferenceKeys.budgetWarningsEnabled,
              'false',
            )).called(1);
      });
    });

    group('setSubscriptionRemindersEnabled', () {
      test('saves true value', () async {
        await service.setSubscriptionRemindersEnabled(true);

        verify(() => mockSettingsDao.setValue(
              NotificationPreferenceKeys.subscriptionRemindersEnabled,
              'true',
            )).called(1);
      });

      test('saves false value', () async {
        await service.setSubscriptionRemindersEnabled(false);

        verify(() => mockSettingsDao.setValue(
              NotificationPreferenceKeys.subscriptionRemindersEnabled,
              'false',
            )).called(1);
      });
    });

    group('setStreakCelebrationsEnabled', () {
      test('saves true value', () async {
        await service.setStreakCelebrationsEnabled(true);

        verify(() => mockSettingsDao.setValue(
              NotificationPreferenceKeys.streakCelebrationsEnabled,
              'true',
            )).called(1);
      });

      test('saves false value', () async {
        await service.setStreakCelebrationsEnabled(false);

        verify(() => mockSettingsDao.setValue(
              NotificationPreferenceKeys.streakCelebrationsEnabled,
              'false',
            )).called(1);
      });
    });

    group('resetToDefaults', () {
      test('sets all preferences to true', () async {
        await service.resetToDefaults();

        verify(() => mockSettingsDao.setValue(
              NotificationPreferenceKeys.budgetWarningsEnabled,
              'true',
            )).called(1);
        verify(() => mockSettingsDao.setValue(
              NotificationPreferenceKeys.subscriptionRemindersEnabled,
              'true',
            )).called(1);
        verify(() => mockSettingsDao.setValue(
              NotificationPreferenceKeys.streakCelebrationsEnabled,
              'true',
            )).called(1);
      });
    });
  });

  group('NotificationPreferences', () {
    test('defaults has all enabled', () {
      const defaults = NotificationPreferences.defaults;

      expect(defaults.budgetWarningsEnabled, isTrue);
      expect(defaults.subscriptionRemindersEnabled, isTrue);
      expect(defaults.streakCelebrationsEnabled, isTrue);
      expect(defaults.plannedExpenseRemindersEnabled, isTrue);
      expect(defaults.morningTipsEnabled, isTrue);
      expect(defaults.spendingAnomalyEnabled, isTrue);
    });

    test('copyWith updates specified fields', () {
      const original = NotificationPreferences(
        budgetWarningsEnabled: true,
        subscriptionRemindersEnabled: true,
        streakCelebrationsEnabled: true,
        plannedExpenseRemindersEnabled: true,
        morningTipsEnabled: true,
        spendingAnomalyEnabled: true,
      );

      final updated = original.copyWith(budgetWarningsEnabled: false);

      expect(updated.budgetWarningsEnabled, isFalse);
      expect(updated.subscriptionRemindersEnabled, isTrue);
      expect(updated.streakCelebrationsEnabled, isTrue);
      expect(updated.plannedExpenseRemindersEnabled, isTrue);
      expect(updated.morningTipsEnabled, isTrue);
      expect(updated.spendingAnomalyEnabled, isTrue);
    });

    test('copyWith preserves unspecified fields', () {
      const original = NotificationPreferences(
        budgetWarningsEnabled: false,
        subscriptionRemindersEnabled: false,
        streakCelebrationsEnabled: false,
        plannedExpenseRemindersEnabled: false,
        morningTipsEnabled: false,
        spendingAnomalyEnabled: false,
      );

      final updated = original.copyWith(streakCelebrationsEnabled: true);

      expect(updated.budgetWarningsEnabled, isFalse);
      expect(updated.subscriptionRemindersEnabled, isFalse);
      expect(updated.streakCelebrationsEnabled, isTrue);
      expect(updated.plannedExpenseRemindersEnabled, isFalse);
      expect(updated.morningTipsEnabled, isFalse);
      expect(updated.spendingAnomalyEnabled, isFalse);
    });
  });

  group('NotificationPreferencesNotifier', () {
    late NotificationPreferencesNotifier notifier;

    setUp(() {
      notifier = NotificationPreferencesNotifier(service);
    });

    test('initial state is defaults', () {
      expect(notifier.state.budgetWarningsEnabled, isTrue);
      expect(notifier.state.subscriptionRemindersEnabled, isTrue);
      expect(notifier.state.streakCelebrationsEnabled, isTrue);
    });

    test('load updates state from service', () async {
      when(() => mockSettingsDao.getValue(
              NotificationPreferenceKeys.budgetWarningsEnabled))
          .thenAnswer((_) async => 'false');
      when(() => mockSettingsDao.getValue(
              NotificationPreferenceKeys.subscriptionRemindersEnabled))
          .thenAnswer((_) async => 'false');
      when(() => mockSettingsDao.getValue(
              NotificationPreferenceKeys.streakCelebrationsEnabled))
          .thenAnswer((_) async => 'true');

      await notifier.load();

      expect(notifier.state.budgetWarningsEnabled, isFalse);
      expect(notifier.state.subscriptionRemindersEnabled, isFalse);
      expect(notifier.state.streakCelebrationsEnabled, isTrue);
    });

    test('toggleBudgetWarnings toggles state and saves', () async {
      expect(notifier.state.budgetWarningsEnabled, isTrue);

      await notifier.toggleBudgetWarnings();

      expect(notifier.state.budgetWarningsEnabled, isFalse);
      verify(() => mockSettingsDao.setValue(
            NotificationPreferenceKeys.budgetWarningsEnabled,
            'false',
          )).called(1);
    });

    test('toggleSubscriptionReminders toggles state and saves', () async {
      expect(notifier.state.subscriptionRemindersEnabled, isTrue);

      await notifier.toggleSubscriptionReminders();

      expect(notifier.state.subscriptionRemindersEnabled, isFalse);
      verify(() => mockSettingsDao.setValue(
            NotificationPreferenceKeys.subscriptionRemindersEnabled,
            'false',
          )).called(1);
    });

    test('toggleStreakCelebrations toggles state and saves', () async {
      expect(notifier.state.streakCelebrationsEnabled, isTrue);

      await notifier.toggleStreakCelebrations();

      expect(notifier.state.streakCelebrationsEnabled, isFalse);
      verify(() => mockSettingsDao.setValue(
            NotificationPreferenceKeys.streakCelebrationsEnabled,
            'false',
          )).called(1);
    });

    test('setBudgetWarnings sets specific value', () async {
      await notifier.setBudgetWarnings(enabled: false);

      expect(notifier.state.budgetWarningsEnabled, isFalse);
      verify(() => mockSettingsDao.setValue(
            NotificationPreferenceKeys.budgetWarningsEnabled,
            'false',
          )).called(1);
    });
  });
}
