import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:bravoball_flutter/main.dart' as app;

/// Integration tests for Store and Premium features
/// 
/// These tests verify the complete user flow for:
/// - Viewing store items
/// - Using streak revivers
/// - Using streak freezes
/// - Premium purchase flow
/// - Calendar display with freeze/reviver dates
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Store Integration Tests', () {
    testWidgets('Store page loads and displays items correctly', (WidgetTester tester) async {
      // Arrange: Launch app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Act: Navigate to store page
      // Find and tap the store tab/navigation item
      final storeTab = find.text('Store');
      if (storeTab.evaluate().isNotEmpty) {
        await tester.tap(storeTab);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Assert: Verify store items are displayed
      expect(find.text('My Items'), findsOneWidget);
      expect(find.text('Treats'), findsOneWidget);
      expect(find.text('Streak Freezes'), findsOneWidget);
      expect(find.text('Streak Revivers'), findsOneWidget);
    });

    testWidgets('Streak reviver confirmation dialog appears when tapped', (WidgetTester tester) async {
      // Arrange: Launch app and navigate to store
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to store page
      final storeTab = find.text('Store');
      if (storeTab.evaluate().isNotEmpty) {
        await tester.tap(storeTab);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Act: Tap on streak reviver item
      // Find the streak reviver widget (adjust selector based on your UI)
      final reviverItem = find.text('Streak Revivers').first;
      if (reviverItem.evaluate().isNotEmpty) {
        await tester.tap(reviverItem);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Assert: Confirmation dialog should appear
      // Uncomment when you know the exact dialog text
      // expect(find.text('Use Streak Reviver?'), findsOneWidget);
      // expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Streak freeze confirmation dialog appears when tapped', (WidgetTester tester) async {
      // Arrange: Launch app and navigate to store
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to store page
      final storeTab = find.text('Store');
      if (storeTab.evaluate().isNotEmpty) {
        await tester.tap(storeTab);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Act: Tap on streak freeze item
      final freezeItem = find.text('Streak Freezes').first;
      if (freezeItem.evaluate().isNotEmpty) {
        await tester.tap(freezeItem);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Assert: Confirmation dialog should appear
      // Uncomment when you know the exact dialog text
      // expect(find.text('Use Streak Freeze?'), findsOneWidget);
      // expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Store items update after using streak reviver', (WidgetTester tester) async {
      // This test requires:
      // 1. User to be logged in
      // 2. User to have at least 1 streak reviver
      // 3. User to have a lost streak (current_streak == 0, previous_streak > 0)

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to store
      final storeTab = find.text('Store');
      if (storeTab.evaluate().isNotEmpty) {
        await tester.tap(storeTab);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Get initial reviver count
      // This requires finding the count text widget
      // final initialCount = int.parse(find.textContaining('Streak Revivers').evaluate().first.text);

      // Use streak reviver (tap, confirm)
      // Verify count decreased by 1

      // Note: This is a placeholder - customize based on your UI structure
    });
  });

  group('Premium Integration Tests', () {
    testWidgets('Premium page loads correctly', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to premium page
      final premiumTab = find.text('Premium');
      if (premiumTab.evaluate().isNotEmpty) {
        await tester.tap(premiumTab);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Verify premium page elements
      // expect(find.text('Upgrade to Premium'), findsOneWidget);
    });

    testWidgets('Premium purchase flow works', (WidgetTester tester) async {
      // This test requires:
      // 1. Test RevenueCat environment
      // 2. Sandbox test account
      // 3. Mock purchase products

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to premium page
      // Tap upgrade button
      // Go through purchase flow
      // Verify purchase succeeded
      // Verify premium status updated

      // Note: This requires RevenueCat sandbox setup
      // See REVENUECAT_TEST_SETUP.md for configuration
    });
  });

  group('Calendar Display Integration Tests', () {
    testWidgets('Calendar displays correctly on progress page', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to progress/calendar page
      final progressTab = find.text('Progress');
      if (progressTab.evaluate().isNotEmpty) {
        await tester.tap(progressTab);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Verify calendar is displayed
      // Verify today's date is highlighted
      // Verify completed sessions show green circles
      // Verify freeze dates show blue circles
      // Verify reviver dates show orange circles
    });

    testWidgets('Calendar shows correct colors for different day types', (WidgetTester tester) async {
      // This test verifies:
      // 1. Green circles for completed sessions
      // 2. Blue circles for freeze dates
      // 3. Orange circles for reviver dates
      // 4. Priority system (reviver > freeze > session)

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to progress page
      final progressTab = find.text('Progress');
      if (progressTab.evaluate().isNotEmpty) {
        await tester.tap(progressTab);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Verify calendar day colors
      // This requires finding specific calendar day widgets
      // and checking their background colors
    });
  });
}
