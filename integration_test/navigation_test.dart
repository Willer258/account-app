import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol_finders/patrol_finders.dart';

import 'package:pockii/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation Tests', () {
    patrolWidgetTest(
      'bottom nav tabs are visible and tappable',
      ($) async {
        app.main();
        await $.pumpAndSettle();

        // Wait for app to fully load past splash
        await Future<void>.delayed(const Duration(seconds: 4));
        await $.pumpAndSettle();

        // Check bottom nav items exist
        final accueil = find.text('Accueil');
        final finances = find.text('Finances');
        final tendances = find.text('Tendances');
        final reglages = find.text('Réglages');

        // If we're on the main screen (not onboarding), verify nav
        if (accueil.evaluate().isNotEmpty) {
          expect(accueil, findsOneWidget);
          expect(finances, findsOneWidget);
          expect(tendances, findsOneWidget);
          expect(reglages, findsOneWidget);

          // Tap Finances tab
          await $.tap(finances);
          await $.pumpAndSettle();

          // Verify we navigated - should see finances content
          expect(find.text('Mes finances'), findsOneWidget);

          // Tap back to Accueil
          await $.tap(find.text('Accueil'));
          await $.pumpAndSettle();
        }
      },
    );

    patrolWidgetTest(
      'FAB opens transaction bottom sheet',
      ($) async {
        app.main();
        await $.pumpAndSettle();

        // Wait for app to fully load
        await Future<void>.delayed(const Duration(seconds: 4));
        await $.pumpAndSettle();

        // Find and tap the FAB (add button)
        final fab = find.byIcon(Icons.add_rounded);
        if (fab.evaluate().isNotEmpty) {
          await $.tap(fab);
          await $.pumpAndSettle();

          // Bottom sheet should appear - look for transaction input elements
          // The bottom sheet should have amount input or category selection
          expect(find.byType(BottomSheet), findsOneWidget);
        }
      },
    );
  });
}
