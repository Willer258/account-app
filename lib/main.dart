import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/database/app_database.dart';
import 'core/database/database_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/background_task_manager.dart';
import 'core/services/notification_service.dart';
import 'core/theme/theme.dart';
import 'core/theme/theme_provider.dart';
import 'shared/utils/fcfa_formatter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLCipher before any database access
  await setupSqlCipher();

  // Initialize French locale for date formatting
  await initializeDateFormatting('fr_FR', null);

  // Initialize WorkManager for background tasks (ARCH-9)
  final backgroundTaskManager = BackgroundTaskManager();
  await backgroundTaskManager.initialize();

  // Initialize notification service and request permission
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermission();

  // Register periodic background task
  await backgroundTaskManager.registerPeriodicTask();

  runApp(
    ProviderScope(
      overrides: [
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const PockiiApp(),
    ),
  );
}

/// Root widget for the Pockii application.
class PockiiApp extends ConsumerStatefulWidget {
  const PockiiApp({super.key});

  @override
  ConsumerState<PockiiApp> createState() => _PockiiAppState();
}

class _PockiiAppState extends ConsumerState<PockiiApp> {
  bool _notificationCallbackSet = false;

  @override
  Widget build(BuildContext context) {
    // Watch database initialization
    final dbAsync = ref.watch(databaseProvider);
    final router = ref.watch(routerProvider);

    // Wire notification tap to GoRouter — once only
    if (!_notificationCallbackSet) {
      _notificationCallbackSet = true;
      final notifService = ref.read(notificationServiceProvider);
      notifService.setOnTapCallback((payload) {
        if (payload == null) return;
        final basePayload = payload.startsWith('spending_anomaly')
            ? 'spending_anomaly'
            : payload;
        final route = NotificationService.payloadRoutes[basePayload];
        if (route != null) {
          router.go(route);
        }
      });
    }

    final appThemeMode = ref.watch(themeModeProvider);
    final flutterThemeMode = toFlutterThemeMode(appThemeMode);

    // Sync currency symbol
    ref.watch(currencySymbolSyncProvider);

    return dbAsync.when(
      data: (_) => MaterialApp.router(
        title: 'Pockii',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.revolutLight(),
        darkTheme: AppTheme.revolut(),
        themeMode: flutterThemeMode,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fr', 'FR'),
          Locale('en', 'US'),
        ],
        locale: const Locale('fr', 'FR'),
        routerConfig: router,
      ),
      loading: () => MaterialApp(
        title: 'Pockii',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const _LoadingScreen(),
      ),
      error: (error, stack) => MaterialApp(
        title: 'Pockii',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: _ErrorScreen(error: error),
      ),
    );
  }
}

/// Loading screen shown during database initialization.
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Chargement...',
              style: AppTypography.body,
            ),
          ],
        ),
      ),
    );
  }
}

/// Error screen shown when database initialization fails.
class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: BudgetColors.danger,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Erreur d\'initialisation',
                style: AppTypography.title,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
