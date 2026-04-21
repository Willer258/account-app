import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../features/tips/services/morning_notification_service.dart';
import '../../features/tips/services/spending_anomaly_service.dart';
import '../database/app_database.dart';
import '../database/daos/app_settings_dao.dart';
import '../database/daos/budget_periods_dao.dart';
import '../database/daos/planned_expenses_dao.dart';
import '../database/daos/streaks_dao.dart';
import '../database/daos/subscriptions_dao.dart';
import '../database/daos/transactions_dao.dart';
import 'budget_notification_tracker.dart';
import 'clock_service.dart';
import 'encryption_service.dart';
import 'notification_limiter.dart';
import 'notification_preferences.dart';
import 'notification_service.dart';
import 'planned_expense_reminder_tracker.dart';
import 'streak_celebration_tracker.dart';
import 'subscription_reminder_tracker.dart';

/// Task identifiers for WorkManager background tasks.
abstract class BackgroundTasks {
  static const periodicTask = 'com.pockii.periodic_task';
  static const streakCheck = 'streak_check';
  static const budgetCheck = 'budget_check';
  static const subscriptionReminder = 'subscription_reminder';
  static const plannedExpenseReminder = 'planned_expense_reminder';
}

/// Manager for background tasks using WorkManager.
///
/// Handles scheduling and execution of periodic background tasks for:
/// - Streak verification
/// - Budget threshold checks
/// - Subscription reminders
///
/// Covers: ARCH-9, NFR7
class BackgroundTaskManager {
  BackgroundTaskManager({
    Workmanager? workmanager,
  }) : _workmanager = workmanager ?? Workmanager();

  final Workmanager _workmanager;

  /// Initialize WorkManager and register the callback dispatcher.
  ///
  /// Must be called once during app startup.
  Future<void> initialize() async {
    await _workmanager.initialize(
      callbackDispatcher,
      isInDebugMode: false, // Set to true for debugging
    );
  }

  /// Register the periodic background task.
  ///
  /// Runs every 15 minutes (minimum interval allowed by Android).
  /// Tasks include: streak check, budget threshold check, subscription reminders.
  Future<void> registerPeriodicTask() async {
    await _workmanager.registerPeriodicTask(
      BackgroundTasks.periodicTask,
      BackgroundTasks.periodicTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 5),
    );
  }

  /// Cancel all registered background tasks.
  Future<void> cancelAllTasks() async {
    await _workmanager.cancelAll();
  }

  /// Cancel a specific task by unique name.
  Future<void> cancelTask(String uniqueName) async {
    await _workmanager.cancelByUniqueName(uniqueName);
  }
}

/// Top-level callback function for WorkManager.
///
/// This must be a top-level function (not a method) for WorkManager to work.
/// It is called in an isolate, so it must re-initialize services.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    AppDatabase? db;
    try {
      // Initialize services in the background isolate
      final clock = SystemClock();

      // Get encryption key from secure storage
      final encryptionService = EncryptionService();
      final encryptionKey = await encryptionService.getOrCreateKey();

      // Initialize encrypted database
      db = AppDatabase(encryptionKey: encryptionKey);

      // Initialize DAOs
      final streaksDao = StreaksDao(db, clock: clock);
      final transactionsDao = TransactionsDao(db);
      final budgetPeriodsDao = BudgetPeriodsDao(db);
      final subscriptionsDao = SubscriptionsDao(db);
      final plannedExpensesDao = PlannedExpensesDao(db);
      final appSettingsDao = AppSettingsDao(db, clock: clock);

      // Initialize notification service and trackers
      final notificationService = NotificationService();
      await notificationService.initialize();
      final budgetTracker = BudgetNotificationTracker(settingsDao: appSettingsDao);
      final subscriptionTracker = SubscriptionReminderTracker(
        settingsDao: appSettingsDao,
        clock: clock,
      );
      final plannedExpenseTracker = PlannedExpenseReminderTracker(
        settingsDao: appSettingsDao,
        clock: clock,
      );
      final streakTracker = StreakCelebrationTracker(settingsDao: appSettingsDao);
      final notificationPrefs = NotificationPreferencesService(settingsDao: appSettingsDao);
      final notificationLimiter = NotificationLimiter(
        settingsDao: appSettingsDao,
        clock: clock,
      );

      // Process any queued notifications from previous days (FR40)
      await _processQueuedNotifications(notificationService, notificationLimiter);

      // Execute all background checks (respecting user preferences and daily limit)
      if (await notificationPrefs.areStreakCelebrationsEnabled()) {
        await _executeStreakCheck(
          streaksDao,
          clock,
          notificationService,
          streakTracker,
          notificationLimiter,
        );
      }
      if (await notificationPrefs.areBudgetWarningsEnabled()) {
        await _executeBudgetCheck(
          budgetPeriodsDao,
          transactionsDao,
          subscriptionsDao,
          clock,
          notificationService,
          budgetTracker,
          notificationLimiter,
        );
      }
      if (await notificationPrefs.areSubscriptionRemindersEnabled()) {
        await _executeSubscriptionReminder(
          subscriptionsDao,
          clock,
          notificationService,
          subscriptionTracker,
          notificationLimiter,
        );
      }
      // Planned expense reminders
      if (await notificationPrefs.arePlannedExpenseRemindersEnabled()) {
        await _executePlannedExpenseReminder(
          plannedExpensesDao,
          clock,
          notificationService,
          plannedExpenseTracker,
          notificationLimiter,
        );
      }

      // Morning tip notification (daily at 8 AM)
      if (await notificationPrefs.areMorningTipsEnabled()) {
        await _executeMorningNotification(
          budgetPeriodsDao,
          transactionsDao,
          subscriptionsDao,
          clock,
          notificationService,
          notificationLimiter,
        );
      }

      // Spending anomaly detection (daily)
      if (await notificationPrefs.areSpendingAnomalyEnabled()) {
        await _executeSpendingAnomalyCheck(
          transactionsDao,
          clock,
          notificationService,
          notificationLimiter,
        );
      }

      return true;
    } catch (e) {
      // Silently fail - return true to prevent retry spam
      return true;
    } finally {
      await db?.close();
    }
  });
}

/// Process queued notifications from previous days.
///
/// Sends queued notifications up to the daily limit.
///
/// Covers: FR40, Story 4.8
Future<void> _processQueuedNotifications(
  NotificationService notificationService,
  NotificationLimiter limiter,
) async {
  try {
    final queued = await limiter.getAndClearQueuedNotifications();
    for (final notification in queued) {
      // Check if we can still send (respecting limit)
      final canSend = await limiter.canSendNotification();
      if (canSend != NotificationLimitResult.allowed) break;

      // Send the queued notification
      await notificationService.showGenericNotification(
        title: notification.title,
        body: notification.body,
      );
      await limiter.recordNotificationSent();
    }
  } catch (e) {
    // Silently fail - don't crash the background task
  }
}

/// Check streak status and send notification if milestone reached.
///
/// Uses [StreakCelebrationTracker] to prevent duplicate notifications
/// and manage in-app celebrations.
///
/// Covers: FR38, FR54, Story 4.6
Future<void> _executeStreakCheck(
  StreaksDao streaksDao,
  Clock clock,
  NotificationService notificationService,
  StreakCelebrationTracker streakTracker,
  NotificationLimiter limiter,
) async {
  try {
    final streak = await streaksDao.getStreak();
    if (streak == null) return;

    final currentStreak = streak.currentStreak;

    // If streak is 0, reset the tracker so milestones can be celebrated again
    if (currentStreak == 0) {
      await streakTracker.resetOnStreakBroken();
      return;
    }

    // Check if this is a milestone we should celebrate
    final milestoneToNotify = await streakTracker.checkAndMarkMilestone(currentStreak);

    if (milestoneToNotify != null) {
      // Check notification limit (FR40)
      final canSend = await limiter.canSendNotification();
      if (canSend == NotificationLimitResult.allowed) {
        await notificationService.showStreakCelebration(
          streakDays: milestoneToNotify,
        );
        await limiter.recordNotificationSent();
      } else {
        // Queue for later
        await limiter.queueNotification(
          type: 'streak_celebration',
          title: _getStreakTitle(milestoneToNotify),
          body: _getStreakBody(milestoneToNotify),
        );
      }
    }
  } catch (e) {
    // Silently fail - don't crash the background task
  }
}

String _getStreakTitle(int days) {
  switch (days) {
    case 7:
      return '7 jours de suite!';
    case 14:
      return '14 jours!';
    case 30:
      return '30 jours!';
    case 60:
      return '60 jours!';
    case 90:
      return '90 jours!';
    case 180:
      return '180 jours!';
    case 365:
      return '1 an!';
    default:
      return '$days jours!';
  }
}

String _getStreakBody(int days) {
  switch (days) {
    case 7:
      return 'Tu gères! Continue comme ça.';
    case 14:
      return 'Tu deviens un pro!';
    case 30:
      return 'Maître du budget!';
    case 60:
      return 'Incroyable discipline!';
    case 90:
      return 'Tu es une légende!';
    case 180:
      return 'Demi-année de succès!';
    case 365:
      return 'Champion absolu!';
    default:
      return 'Félicitations pour ta série!';
  }
}

/// Check budget threshold and send warning/critical notifications.
///
/// Uses [BudgetNotificationTracker] to prevent duplicate notifications
/// and handle threshold recovery/re-crossing correctly.
///
/// Covers: FR35, FR36, Story 4.4
Future<void> _executeBudgetCheck(
  BudgetPeriodsDao budgetPeriodsDao,
  TransactionsDao transactionsDao,
  SubscriptionsDao subscriptionsDao,
  Clock clock,
  NotificationService notificationService,
  BudgetNotificationTracker budgetTracker,
  NotificationLimiter limiter,
) async {
  try {
    final now = clock.now();

    // Get current budget period
    final budgetPeriod = await budgetPeriodsDao.getCurrentBudgetPeriod(now);
    if (budgetPeriod == null) return;

    // Calculate remaining budget
    final monthStart = DateTime(now.year, now.month);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final transactions = await transactionsDao.getTransactionsByDateRange(
      monthStart,
      monthEnd,
    );

    // Sum expenses (type = 'expense')
    var totalExpenses = 0;
    var totalIncome = 0;
    for (final tx in transactions) {
      if (tx.type == 'expense') {
        totalExpenses += tx.amountFcfa;
      } else {
        totalIncome += tx.amountFcfa;
      }
    }

    // Get active subscriptions and calculate monthly impact
    final subscriptions = await subscriptionsDao.getActiveSubscriptions();
    var totalSubscriptions = 0;
    for (final sub in subscriptions) {
      if (sub.frequency == 'monthly') {
        totalSubscriptions += sub.amountFcfa;
      } else if (sub.frequency == 'weekly') {
        // Approximate 4 weeks per month
        totalSubscriptions += sub.amountFcfa * 4;
      } else if (sub.frequency == 'yearly') {
        // Prorate to monthly
        totalSubscriptions += (sub.amountFcfa / 12).round();
      }
    }

    // Calculate remaining
    final remaining = budgetPeriod.monthlyBudgetFcfa +
        totalIncome -
        totalExpenses -
        totalSubscriptions;
    final total = budgetPeriod.monthlyBudgetFcfa;
    final percentRemaining = total > 0 ? (remaining / total * 100) : 0.0;

    // Use tracker to determine if notification should be sent
    final result = await budgetTracker.checkAndUpdateState(percentRemaining);

    switch (result) {
      case BudgetNotificationResult.critical:
        // Critical alerts (budget <10%) can bypass normal limit (FR40)
        final canSend = await limiter.canSendNotification(
          priority: NotificationPriority.critical,
        );
        if (canSend == NotificationLimitResult.criticalAllowed ||
            canSend == NotificationLimitResult.allowed) {
          await notificationService.showBudgetCritical(remainingFcfa: remaining);
          await limiter.recordNotificationSent();
        } else {
          // Even critical alerts queue if absolute limit reached
          await limiter.queueNotification(
            type: 'budget_critical',
            title: 'Budget critique',
            body: 'Il te reste $remaining FCFA',
          );
        }
      case BudgetNotificationResult.warning:
        // Warning notifications respect normal limit
        final canSend = await limiter.canSendNotification();
        if (canSend == NotificationLimitResult.allowed) {
          await notificationService.showBudgetWarning(remainingFcfa: remaining);
          await limiter.recordNotificationSent();
        } else {
          await limiter.queueNotification(
            type: 'budget_warning',
            title: 'Budget attention',
            body: 'Il te reste $remaining FCFA',
          );
        }
      case BudgetNotificationResult.none:
        // No notification needed
        break;
    }
  } catch (e) {
    // Silently fail - don't crash the background task
  }
}

/// Check for upcoming subscriptions and send reminders.
///
/// Uses [SubscriptionReminderTracker] to prevent duplicate notifications
/// within the same month.
///
/// Covers: FR29, FR37, Story 4.5
Future<void> _executeSubscriptionReminder(
  SubscriptionsDao subscriptionsDao,
  Clock clock,
  NotificationService notificationService,
  SubscriptionReminderTracker reminderTracker,
  NotificationLimiter limiter,
) async {
  try {
    final now = clock.now();
    final today = now.day;

    final subscriptions = await subscriptionsDao.getActiveSubscriptions();
    if (subscriptions.isEmpty) return;

    // Find subscriptions due in the next 2 days
    final dueSoon = <({int id, String name, int amount, int daysUntil})>[];

    for (final sub in subscriptions) {
      if (sub.frequency != 'monthly') continue;

      final dueDay = sub.dueDay;
      int daysUntil;
      if (dueDay == today) {
        daysUntil = 0;
      } else if (dueDay == today + 1 || (today == 28 && dueDay == 1)) {
        daysUntil = 1;
      } else if (dueDay == today + 2 || (today == 27 && dueDay == 1)) {
        daysUntil = 2;
      } else {
        continue; // Not due soon
      }

      dueSoon.add((
        id: sub.id,
        name: sub.name,
        amount: sub.amountFcfa,
        daysUntil: daysUntil,
      ));
    }

    if (dueSoon.isEmpty) return;

    // Filter out subscriptions that were already reminded this month
    final subscriptionIds = dueSoon.map((s) => s.id).toList();
    final unremindedIds = await reminderTracker.filterUnreminded(subscriptionIds);

    if (unremindedIds.isEmpty) return;

    // Filter dueSoon to only include unreminded subscriptions
    final toRemind = dueSoon.where((s) => unremindedIds.contains(s.id)).toList();

    if (toRemind.isEmpty) return;

    // Check notification limit (FR40)
    final canSend = await limiter.canSendNotification();

    // If only one subscription, send individual notification
    if (toRemind.length == 1) {
      final sub = toRemind.first;
      if (canSend == NotificationLimitResult.allowed) {
        await notificationService.showSubscriptionReminder(
          subscriptionName: sub.name,
          amountFcfa: sub.amount,
          daysUntilDue: sub.daysUntil,
        );
        await limiter.recordNotificationSent();
        await reminderTracker.markAsReminded(sub.id);
      } else {
        // Queue for later
        final dueText = sub.daysUntil == 0
            ? "aujourd'hui"
            : 'dans ${sub.daysUntil} jour${sub.daysUntil > 1 ? 's' : ''}';
        await limiter.queueNotification(
          type: 'subscription_reminder',
          title: sub.name,
          body: '${sub.amount} FCFA $dueText',
        );
        // Still mark as reminded so we don't try again
        await reminderTracker.markAsReminded(sub.id);
      }
    } else {
      // Multiple subscriptions - send grouped notification
      final total = toRemind.fold<int>(0, (sum, sub) => sum + sub.amount);
      if (canSend == NotificationLimitResult.allowed) {
        await notificationService.showGroupedSubscriptionReminder(
          count: toRemind.length,
          totalAmountFcfa: total,
        );
        await limiter.recordNotificationSent();
        await reminderTracker.markMultipleAsReminded(
          toRemind.map((s) => s.id).toList(),
        );
      } else {
        // Queue for later
        await limiter.queueNotification(
          type: 'subscription_reminder_grouped',
          title: '${toRemind.length} abonnements',
          body: 'Total: $total FCFA',
        );
        // Still mark as reminded so we don't try again
        await reminderTracker.markMultipleAsReminded(
          toRemind.map((s) => s.id).toList(),
        );
      }
    }
  } catch (e) {
    // Silently fail - don't crash the background task
  }
}

/// Check for upcoming planned expenses and send reminders.
///
/// Sends notifications for planned expenses due today or overdue.
Future<void> _executePlannedExpenseReminder(
  PlannedExpensesDao plannedExpensesDao,
  Clock clock,
  NotificationService notificationService,
  PlannedExpenseReminderTracker reminderTracker,
  NotificationLimiter limiter,
) async {
  try {
    final now = clock.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get pending planned expenses
    final pendingExpenses = await plannedExpensesDao.getPendingPlannedExpenses();
    if (pendingExpenses.isEmpty) return;

    // Find expenses due today or overdue (within 1 day window)
    final dueSoon = <({int id, String description, int amount, int daysUntil})>[];

    for (final expense in pendingExpenses) {
      final dueDate = DateTime(
        expense.expectedDate.year,
        expense.expectedDate.month,
        expense.expectedDate.day,
      );
      final daysUntil = dueDate.difference(today).inDays;

      // Notify for expenses due today, tomorrow, or overdue
      if (daysUntil <= 1) {
        dueSoon.add((
          id: expense.id,
          description: expense.description,
          amount: expense.amountFcfa,
          daysUntil: daysUntil,
        ));
      }
    }

    if (dueSoon.isEmpty) return;

    // Filter out expenses that were already reminded today
    final expenseIds = dueSoon.map((e) => e.id).toList();
    final unremindedIds = await reminderTracker.filterUnreminded(expenseIds);

    if (unremindedIds.isEmpty) return;

    // Filter dueSoon to only include unreminded expenses
    final toRemind = dueSoon.where((e) => unremindedIds.contains(e.id)).toList();

    if (toRemind.isEmpty) return;

    // Check notification limit
    final canSend = await limiter.canSendNotification();

    // If only one expense, send individual notification
    if (toRemind.length == 1) {
      final expense = toRemind.first;
      if (canSend == NotificationLimitResult.allowed) {
        await notificationService.showPlannedExpenseReminder(
          description: expense.description,
          amountFcfa: expense.amount,
          daysUntilDue: expense.daysUntil,
        );
        await limiter.recordNotificationSent();
        await reminderTracker.markAsReminded(expense.id);
      } else {
        // Queue for later
        final dueText = expense.daysUntil <= 0
            ? 'maintenant'
            : 'dans ${expense.daysUntil} jour${expense.daysUntil > 1 ? 's' : ''}';
        await limiter.queueNotification(
          type: 'planned_expense_reminder',
          title: expense.description,
          body: '${expense.amount} FCFA $dueText',
        );
        await reminderTracker.markAsReminded(expense.id);
      }
    } else {
      // Multiple expenses - send grouped notification
      final total = toRemind.fold<int>(0, (sum, e) => sum + e.amount);
      if (canSend == NotificationLimitResult.allowed) {
        await notificationService.showGroupedPlannedExpenseReminder(
          count: toRemind.length,
          totalAmountFcfa: total,
        );
        await limiter.recordNotificationSent();
        await reminderTracker.markMultipleAsReminded(
          toRemind.map((e) => e.id).toList(),
        );
      } else {
        // Queue for later
        await limiter.queueNotification(
          type: 'planned_expense_reminder_grouped',
          title: '${toRemind.length} dépenses programmées',
          body: 'Total: $total FCFA',
        );
        await reminderTracker.markMultipleAsReminded(
          toRemind.map((e) => e.id).toList(),
        );
      }
    }
  } catch (e) {
    // Silently fail - don't crash the background task
  }
}

/// Send morning notification with budget summary and tip.
///
/// Sends once per day at 8 AM with remaining budget info and a contextual tip.
Future<void> _executeMorningNotification(
  BudgetPeriodsDao budgetPeriodsDao,
  TransactionsDao transactionsDao,
  SubscriptionsDao subscriptionsDao,
  Clock clock,
  NotificationService notificationService,
  NotificationLimiter limiter,
) async {
  try {
    final now = clock.now();

    // Initialize SharedPreferences for the morning notification service
    final prefs = await SharedPreferences.getInstance();
    final morningService = MorningNotificationService(
      notificationService: notificationService,
      prefs: prefs,
    );

    // Check if it's time to send (8 AM + not already sent today)
    if (!morningService.shouldSendMorningNotification(now)) return;

    // Check notification limit
    final canSend = await limiter.canSendNotification();
    if (canSend != NotificationLimitResult.allowed) return;

    // Calculate budget data
    final budgetPeriod = await budgetPeriodsDao.getCurrentBudgetPeriod(now);
    if (budgetPeriod == null) return;

    final monthStart = DateTime(now.year, now.month);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final transactions = await transactionsDao.getTransactionsByDateRange(
      monthStart,
      monthEnd,
    );

    var totalExpenses = 0;
    for (final tx in transactions) {
      if (tx.type == 'expense') {
        totalExpenses += tx.amountFcfa;
      }
    }

    // Account for subscriptions
    final subscriptions = await subscriptionsDao.getActiveSubscriptions();
    var totalSubscriptions = 0;
    for (final sub in subscriptions) {
      if (sub.frequency == 'monthly') {
        totalSubscriptions += sub.amountFcfa;
      } else if (sub.frequency == 'weekly') {
        totalSubscriptions += sub.amountFcfa * 4;
      } else if (sub.frequency == 'yearly') {
        totalSubscriptions += (sub.amountFcfa / 12).round();
      }
    }

    final remaining = budgetPeriod.monthlyBudgetFcfa - totalExpenses - totalSubscriptions;
    final total = budgetPeriod.monthlyBudgetFcfa;
    final percentage = total > 0 ? remaining / total : 0.0;

    // Days remaining in the month
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = lastDay - now.day;

    await morningService.sendMorningNotification(
      remainingBudget: remaining,
      budgetPercentage: percentage,
      daysRemaining: daysRemaining,
    );
    await limiter.recordNotificationSent();
  } catch (e) {
    // Silently fail - don't crash the background task
  }
}

/// Detect spending anomalies by comparing current vs previous week by category.
///
/// Sends a notification when a category shows >50% increase week-over-week.
Future<void> _executeSpendingAnomalyCheck(
  TransactionsDao transactionsDao,
  Clock clock,
  NotificationService notificationService,
  NotificationLimiter limiter,
) async {
  try {
    final now = clock.now();

    // Initialize SharedPreferences for the anomaly service
    final prefs = await SharedPreferences.getInstance();
    final anomalyService = SpendingAnomalyService(
      notificationService: notificationService,
      prefs: prefs,
    );

    // Check if we should run today (once per day)
    if (!anomalyService.shouldCheckToday(now)) return;

    // Check notification limit
    final canSend = await limiter.canSendNotification();
    if (canSend != NotificationLimitResult.allowed) return;

    // Calculate current week (Mon-Sun) and previous week date ranges
    final today = DateTime(now.year, now.month, now.day);
    final currentWeekStart = today.subtract(Duration(days: today.weekday - 1));
    final previousWeekStart = currentWeekStart.subtract(const Duration(days: 7));
    final previousWeekEnd = currentWeekStart.subtract(const Duration(seconds: 1));

    // Get transactions for both weeks
    final currentWeekTx = await transactionsDao.getTransactionsByDateRange(
      currentWeekStart,
      today.add(const Duration(hours: 23, minutes: 59, seconds: 59)),
    );
    final previousWeekTx = await transactionsDao.getTransactionsByDateRange(
      previousWeekStart,
      previousWeekEnd,
    );

    // Aggregate by category
    final currentByCategory = <String, int>{};
    for (final tx in currentWeekTx) {
      if (tx.type == 'expense') {
        currentByCategory[tx.category] =
            (currentByCategory[tx.category] ?? 0) + tx.amountFcfa;
      }
    }

    final previousByCategory = <String, int>{};
    for (final tx in previousWeekTx) {
      if (tx.type == 'expense') {
        previousByCategory[tx.category] =
            (previousByCategory[tx.category] ?? 0) + tx.amountFcfa;
      }
    }

    // Detect anomalies
    final anomalies = anomalyService.detectAnomalies(
      currentWeekByCategory: currentByCategory,
      previousWeekByCategory: previousByCategory,
    );

    if (anomalies.isEmpty) return;

    // Send notification for significant anomalies
    final significant = anomalies.where((a) => a.isSignificant).toList();
    if (significant.isNotEmpty) {
      await anomalyService.notifyMultipleAnomalies(significant);
      await limiter.recordNotificationSent();
    }
  } catch (e) {
    // Silently fail - don't crash the background task
  }
}

/// Provider for the BackgroundTaskManager.
final backgroundTaskManagerProvider = Provider<BackgroundTaskManager>((ref) {
  return BackgroundTaskManager();
});
