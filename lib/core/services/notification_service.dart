import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Callback type for handling notification taps with navigation.
typedef NotificationTapCallback = void Function(String? payload);

/// Service for managing local notifications.
///
/// Handles initialization, permission requests, and sending notifications
/// for budget alerts, subscription reminders, and streak celebrations.
///
/// Covers: FR35-FR40, ARCH-9
class NotificationService {
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    NotificationTapCallback? onTap,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _onTap = onTap;

  final FlutterLocalNotificationsPlugin _plugin;
  NotificationTapCallback? _onTap;

  static const _channelId = 'pockii_notifications';
  static const _channelName = 'Pockii Notifications';
  static const _channelDescription = 'Notifications for budget alerts and reminders';

  /// High priority channel for critical budget alerts.
  static const _urgentChannelId = 'pockii_urgent';
  static const _urgentChannelName = 'Pockii Alertes';
  static const _urgentChannelDescription = 'Critical budget threshold notifications';

  bool _isInitialized = false;

  /// Set the notification tap callback for deep linking.
  void setOnTapCallback(NotificationTapCallback callback) {
    _onTap = callback;
  }

  /// Maps notification payloads to route paths for deep navigation.
  static const Map<String, String> payloadRoutes = {
    'budget_warning': '/',
    'budget_critical': '/',
    'subscription_reminder': '/subscriptions',
    'subscription_group': '/subscriptions',
    'streak_celebration': '/',
    'planned_expense_reminder': '/planned-expenses',
    'planned_expense_group': '/planned-expenses',
    'morning_notification': '/',
    'spending_anomaly': '/patterns',
    'spending_anomaly_multiple': '/patterns',
  };

  /// Initialize the notification service.
  ///
  /// Must be called before sending any notifications.
  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  /// Request notification permission (required on Android 13+).
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        return await androidPlugin.requestNotificationsPermission() ?? false;
      }
    } else if (Platform.isIOS) {
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        return await iosPlugin.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
    }
    return false;
  }

  /// Handle notification tap — navigates to the relevant screen.
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    _onTap?.call(payload);
  }

  /// Show a budget warning notification (remaining < 30%).
  ///
  /// Covers: FR35
  Future<void> showBudgetWarning({
    required int remainingFcfa,
  }) async {
    await _ensureInitialized();

    final formattedAmount = _formatFcfa(remainingFcfa);

    await _plugin.show(
      NotificationIds.budgetWarning,
      'Budget attention',
      'Il te reste $formattedAmount FCFA',
      _getWarningDetails(),
      payload: 'budget_warning',
    );
  }

  /// Show a critical budget alert notification (remaining < 10%).
  ///
  /// Covers: FR36
  Future<void> showBudgetCritical({
    required int remainingFcfa,
  }) async {
    await _ensureInitialized();

    final formattedAmount = _formatFcfa(remainingFcfa);

    await _plugin.show(
      NotificationIds.budgetCritical,
      'Budget critique',
      'Il te reste $formattedAmount FCFA',
      _getCriticalDetails(),
      payload: 'budget_critical',
    );
  }

  /// Show a subscription reminder notification.
  ///
  /// Covers: FR29, FR37
  Future<void> showSubscriptionReminder({
    required String subscriptionName,
    required int amountFcfa,
    required int daysUntilDue,
  }) async {
    await _ensureInitialized();

    final formattedAmount = _formatFcfa(amountFcfa);
    final String message;
    if (daysUntilDue == 0) {
      message = "$subscriptionName - $formattedAmount FCFA aujourd'hui";
    } else if (daysUntilDue == 1) {
      message = '$subscriptionName - $formattedAmount FCFA demain';
    } else {
      message = '$subscriptionName - $formattedAmount FCFA dans $daysUntilDue jours';
    }

    await _plugin.show(
      NotificationIds.subscriptionReminder + subscriptionName.hashCode,
      'Rappel abonnement',
      message,
      _getDefaultDetails(),
      payload: 'subscription_reminder',
    );
  }

  /// Show a grouped subscription reminder for multiple subscriptions.
  Future<void> showGroupedSubscriptionReminder({
    required int count,
    required int totalAmountFcfa,
  }) async {
    await _ensureInitialized();

    final formattedAmount = _formatFcfa(totalAmountFcfa);

    await _plugin.show(
      NotificationIds.subscriptionGroup,
      '$count abonnements',
      'Total $formattedAmount FCFA',
      _getDefaultDetails(),
      payload: 'subscription_group',
    );
  }

  /// Show a streak celebration notification.
  ///
  /// Covers: FR38, FR54
  Future<void> showStreakCelebration({
    required int streakDays,
  }) async {
    await _ensureInitialized();

    final String title;
    final String message;

    switch (streakDays) {
      case 7:
        title = '7 jours de suite!';
        message = 'Tu geres! Continue comme ca.';
      case 14:
        title = '14 jours!';
        message = 'Tu deviens un pro du budget!';
      case 30:
        title = '30 jours!';
        message = 'Maitre du budget! Incroyable!';
      case 60:
        title = '60 jours!';
        message = 'Deux mois de discipline!';
      case 90:
        title = '90 jours!';
        message = 'Trois mois! Tu es une legende!';
      case 180:
        title = '180 jours!';
        message = 'Six mois! Extraordinaire!';
      case 365:
        title = 'Une annee complete!';
        message = 'Tu es absolument incroyable!';
      default:
        title = '$streakDays jours!';
        message = 'Continue ta serie!';
    }

    await _plugin.show(
      NotificationIds.streakCelebration,
      title,
      message,
      _getCelebrationDetails(),
      payload: 'streak_celebration',
    );
  }

  /// Show a planned expense reminder notification.
  ///
  /// Notifies when a planned expense is due (today or overdue).
  Future<void> showPlannedExpenseReminder({
    required String description,
    required int amountFcfa,
    required int daysUntilDue,
  }) async {
    await _ensureInitialized();

    final formattedAmount = _formatFcfa(amountFcfa);
    final String message;
    if (daysUntilDue < 0) {
      message = "$description - $formattedAmount FCFA (en retard)";
    } else if (daysUntilDue == 0) {
      message = "$description - $formattedAmount FCFA aujourd'hui";
    } else if (daysUntilDue == 1) {
      message = '$description - $formattedAmount FCFA demain';
    } else {
      message = '$description - $formattedAmount FCFA dans $daysUntilDue jours';
    }

    final details = daysUntilDue <= 0 ? _getCriticalDetails() : _getWarningDetails();

    await _plugin.show(
      NotificationIds.plannedExpense + description.hashCode,
      'Dépense programmée',
      message,
      details,
      payload: 'planned_expense_reminder',
    );
  }

  /// Show a grouped planned expense reminder for multiple expenses.
  Future<void> showGroupedPlannedExpenseReminder({
    required int count,
    required int totalAmountFcfa,
  }) async {
    await _ensureInitialized();

    final formattedAmount = _formatFcfa(totalAmountFcfa);

    await _plugin.show(
      NotificationIds.plannedExpenseGroup,
      '$count dépenses programmées',
      'Total $formattedAmount FCFA',
      _getWarningDetails(),
      payload: 'planned_expense_group',
    );
  }

  /// Show a generic notification (used for queued notifications).
  ///
  /// Covers: FR40, Story 4.8
  Future<void> showGenericNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _ensureInitialized();

    await _plugin.show(
      NotificationIds.generic + title.hashCode,
      title,
      body,
      _getDefaultDetails(),
      payload: payload ?? 'generic',
    );
  }

  /// Cancel all pending notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Cancel a specific notification by ID.
  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  NotificationDetails _getDefaultDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  NotificationDetails _getWarningDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFFFF9800), // Orange warning color
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  NotificationDetails _getCriticalDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _urgentChannelId,
        _urgentChannelName,
        channelDescription: _urgentChannelDescription,
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFFF44336), // Red critical color
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  NotificationDetails _getCelebrationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF4CAF50), // Green celebration color
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  String _formatFcfa(int amount) {
    final absAmount = amount.abs();
    final formatted = absAmount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]} ',
        );
    return amount < 0 ? '-$formatted' : formatted;
  }
}

/// Notification IDs for different notification types.
abstract class NotificationIds {
  static const budgetWarning = 1;
  static const budgetCritical = 2;
  static const subscriptionReminder = 100; // Base ID, actual ID adds hash
  static const subscriptionGroup = 200;
  static const streakCelebration = 300;
  static const generic = 400; // Base ID for generic/queued notifications
  static const plannedExpense = 500; // Base ID for planned expense reminders
  static const plannedExpenseGroup = 600;
  static const morningNotification = 700; // Daily morning tip + budget
  static const spendingAnomaly = 800; // Unusual spending alerts
}

/// Provider for the NotificationService.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
