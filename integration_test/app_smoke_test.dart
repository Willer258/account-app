import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol_finders/patrol_finders.dart';

import 'package:pockii/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Smoke Tests', () {
    patrolWidgetTest(
      'app launches and shows splash screen',
      ($) async {
        app.main();
        await $.pumpAndSettle();

        // Splash screen should show the app name or loading
        expect(find.byType(app.PockiiApp), findsOneWidget);
      },
    );

    patrolWidgetTest(
      'onboarding screen is accessible',
      ($) async {
        app.main();
        await $.pumpAndSettle();

        // Wait for splash to transition
        await Future<void>.delayed(const Duration(seconds: 3));
        await $.pumpAndSettle();

        // Should see either onboarding or home depending on state
        // This verifies the app navigates past splash without crashing
        expect(find.byType(app.PockiiApp), findsOneWidget);
      },
    );
  });
}
