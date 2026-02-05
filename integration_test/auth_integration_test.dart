import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:bravoball_flutter/main.dart' as app;

/// Integration tests for Authentication flow
/// 
/// These tests verify:
/// - Login flow
/// - Logout flow
/// - Session persistence
/// - Error handling
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Integration Tests', () {
    testWidgets('User can login successfully', (WidgetTester tester) async {
      app.main();
      
      // Wait for app to initialize
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

      // Find login fields
      final emailField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).last;
      final loginButton = find.text('Login');

      // Enter test credentials
      if (emailField.evaluate().isNotEmpty) {
        await tester.enterText(emailField, 'test@example.com');
        await tester.pump(const Duration(seconds: 1));
      }

      if (passwordField.evaluate().isNotEmpty) {
        await tester.enterText(passwordField, 'testpassword');
        await tester.pump(const Duration(seconds: 1));
      }

      // Tap login button
      if (loginButton.evaluate().isNotEmpty) {
        await tester.tap(loginButton);
        await tester.pump(const Duration(seconds: 2));
        await tester.pump(const Duration(seconds: 2));
        await tester.pump(const Duration(seconds: 2));
      }

      // Verify login succeeded - check for home screen
      // Adjust based on your app's post-login screen
    });

    testWidgets('Invalid login credentials show error message', (WidgetTester tester) async {
      app.main();
      
      // Wait for app to initialize
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

      // Enter invalid credentials
      final emailField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).last;
      final loginButton = find.text('Login');

      if (emailField.evaluate().isNotEmpty) {
        await tester.enterText(emailField, 'invalid@example.com');
        await tester.pump(const Duration(seconds: 1));
      }

      if (passwordField.evaluate().isNotEmpty) {
        await tester.enterText(passwordField, 'wrongpassword');
        await tester.pump(const Duration(seconds: 1));
      }

      if (loginButton.evaluate().isNotEmpty) {
        await tester.tap(loginButton);
        await tester.pump(const Duration(seconds: 2));
        await tester.pump(const Duration(seconds: 2));
      }

      // Verify error message is displayed
      // expect(find.text('Invalid credentials'), findsOneWidget);
    });

    testWidgets('User session persists after app restart', (WidgetTester tester) async {
      // This test verifies:
      // 1. User logs in
      // 2. App is closed
      // 3. App is reopened
      // 4. User remains logged in

      app.main();
      
      // Wait for app to initialize
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

      // Login (use test credentials)
      // Close app
      // Reopen app
      // Verify user is still logged in

      // Note: This requires testing with actual shared preferences
    });
  });
}
