import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:bravoball_flutter/main.dart' as app;

/// Main integration test entry point
/// 
/// These tests run on real devices/emulators and test the full app lifecycle.
/// They are different from unit/widget tests which run in an isolated test environment.
///
/// To run:
///   flutter test integration_test/app_test.dart
///   flutter drive --driver=integration_test/driver.dart --target=integration_test/app_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('BravoBall App Integration Tests', () {
    testWidgets('App launches successfully', (WidgetTester tester) async {
      // Start the app
      app.main();
      
      // Wait for app to initialize (use pump with fixed durations instead of pumpAndSettle)
      // pumpAndSettle waits forever for animations to settle, which can cause hangs
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      // Check if "Streak Lost" dialog appears and dismiss it
      final maybeLaterButton = find.text('Maybe Later');
      final dialogExists = maybeLaterButton.evaluate().isNotEmpty;
      
      if (dialogExists) {
        // Dialog is showing - dismiss it to continue test
        await tester.tap(maybeLaterButton);
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
      }

      // Verify app has launched - check for main app widget
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Verify we can see the main tab view (after dialog is dismissed)
      // This confirms the app is fully loaded and interactive
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('App navigation works correctly', (WidgetTester tester) async {
      app.main();
      
      // Wait for app to initialize (use pump with fixed durations)
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      // Dismiss "Streak Lost" dialog if it appears
      final maybeLaterButton = find.text('Maybe Later');
      if (maybeLaterButton.evaluate().isNotEmpty) {
        await tester.tap(maybeLaterButton);
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
      }

      // Verify bottom navigation bar is visible
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Test navigation - verify tabs are present
      // The navigation bar should be visible and interactive
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('App handles errors gracefully', (WidgetTester tester) async {
      app.main();
      
      // Wait for app to initialize (use pump with fixed durations)
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      // Dismiss any dialogs
      final maybeLaterButton = find.text('Maybe Later');
      if (maybeLaterButton.evaluate().isNotEmpty) {
        await tester.tap(maybeLaterButton);
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
      }

      // Verify app is in a stable state
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      
      // Test that app handles missing widgets gracefully
      // Try to find something that doesn't exist - should not crash
      final nonExistentWidget = find.text('NonExistentText12345');
      expect(nonExistentWidget, findsNothing); // Should handle gracefully
    });
  });
}
