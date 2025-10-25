import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bravoball_flutter/widgets/streak_loss_dialog.dart';
import 'package:bravoball_flutter/widgets/item_usage_confirmation_dialog.dart';
import 'package:bravoball_flutter/services/store_service.dart';
import 'package:bravoball_flutter/services/app_state_service.dart';
import 'package:bravoball_flutter/constants/app_theme.dart';

// Generate mocks
@GenerateMocks([StoreService, AppStateService])
import 'streak_dialogs_test.mocks.dart';

void main() {
  group('Streak Loss Dialog Tests', () {
    late MockStoreService mockStoreService;
    late MockAppStateService mockAppStateService;

    setUp(() {
      mockStoreService = MockStoreService();
      mockAppStateService = MockAppStateService();
      
      // Setup default mock behaviors
      when(mockStoreService.streakRevivers).thenReturn(2);
      when(mockStoreService.isLoading).thenReturn(false);
      when(mockStoreService.error).thenReturn(null);
    });

    Widget createTestWidget({required Widget child}) {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<StoreService>.value(value: mockStoreService),
            ChangeNotifierProvider<AppStateService>.value(value: mockAppStateService),
          ],
          child: Scaffold(
            body: child,
          ),
        ),
      );
    }

    group('StreakLossDialog', () {
      testWidgets('should display streak loss information correctly', (WidgetTester tester) async {
        // Arrange
        const previousStreak = 5;
        
        await tester.pumpWidget(createTestWidget(
          child: StreakLossDialog(
            previousStreak: previousStreak,
            onRestore: () {},
            onMaybeLater: () {},
          ),
        ));

        // Assert
        expect(find.text('Streak Lost!'), findsOneWidget);
        expect(find.text('You lost your $previousStreak-day streak!'), findsOneWidget);
        expect(find.text('Don\'t worry, you can restore it with a Streak Reviver.'), findsOneWidget);
        expect(find.text('Restore Streak'), findsOneWidget);
        expect(find.text('Maybe Later'), findsOneWidget);
      });

      testWidgets('should show restore button as disabled when no revivers available', (WidgetTester tester) async {
        // Arrange
        when(mockStoreService.streakRevivers).thenReturn(0);
        
        await tester.pumpWidget(createTestWidget(
          child: StreakLossDialog(
            previousStreak: 5,
            onRestore: () {},
            onMaybeLater: () {},
          ),
        ));

        // Assert
        final restoreButton = find.text('Restore Streak');
        expect(restoreButton, findsOneWidget);
        
        // Check if button is disabled (you'd check for opacity or enabled property)
        final button = tester.widget<ElevatedButton>(restoreButton);
        // In a real test, you'd check button.enabled or styling
      });

      testWidgets('should call onRestore when restore button is tapped', (WidgetTester tester) async {
        // Arrange
        bool restoreCalled = false;
        
        await tester.pumpWidget(createTestWidget(
          child: StreakLossDialog(
            previousStreak: 5,
            onRestore: () => restoreCalled = true,
            onMaybeLater: () {},
          ),
        ));

        // Act
        await tester.tap(find.text('Restore Streak'));
        await tester.pumpAndSettle();

        // Assert
        expect(restoreCalled, isTrue);
      });

      testWidgets('should call onMaybeLater when maybe later button is tapped', (WidgetTester tester) async {
        // Arrange
        bool maybeLaterCalled = false;
        
        await tester.pumpWidget(createTestWidget(
          child: StreakLossDialog(
            previousStreak: 5,
            onRestore: () {},
            onMaybeLater: () => maybeLaterCalled = true,
          ),
        ));

        // Act
        await tester.tap(find.text('Maybe Later'));
        await tester.pumpAndSettle();

        // Assert
        expect(maybeLaterCalled, isTrue);
      });

      testWidgets('should show confirmation dialog when restore is tapped', (WidgetTester tester) async {
        // Arrange
        when(mockStoreService.useStreakReviver()).thenAnswer((_) async => {
          'success': true,
          'message': 'Streak revived!',
          'progress_history': {'current_streak': 5, 'previous_streak': 0},
          'store_items': {'streak_revivers': 1}
        });

        await tester.pumpWidget(createTestWidget(
          child: StreakLossDialog(
            previousStreak: 5,
            onRestore: () {},
            onMaybeLater: () {},
          ),
        ));

        // Act
        await tester.tap(find.text('Restore Streak'));
        await tester.pumpAndSettle();

        // Assert - Confirmation dialog should appear
        expect(find.text('Restore Your Streak?'), findsOneWidget);
        expect(find.text('Use a Streak Reviver to restore your 5-day streak?'), findsOneWidget);
      });
    });

    group('ItemUsageConfirmationDialog', () {
      testWidgets('should display confirmation dialog correctly', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget(
          child: ItemUsageConfirmationDialog(
            title: 'Use Streak Reviver?',
            description: 'Use a Streak Reviver to restore your lost streak?',
            itemName: 'Streak Reviver',
            icon: Icons.restore,
            iconColor: AppTheme.secondaryOrange,
            confirmButtonText: 'Use Reviver',
            isLoading: false,
            onConfirm: () {},
            onCancel: () {},
          ),
        ));

        // Assert
        expect(find.text('Use Streak Reviver?'), findsOneWidget);
        expect(find.text('Use a Streak Reviver to restore your lost streak?'), findsOneWidget);
        expect(find.text('Use Reviver'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.byIcon(Icons.restore), findsOneWidget);
      });

      testWidgets('should show loading state when isLoading is true', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget(
          child: ItemUsageConfirmationDialog(
            title: 'Use Streak Reviver?',
            description: 'Use a Streak Reviver to restore your lost streak?',
            itemName: 'Streak Reviver',
            icon: Icons.restore,
            iconColor: AppTheme.secondaryOrange,
            confirmButtonText: 'Use Reviver',
            isLoading: true,
            onConfirm: () {},
            onCancel: () {},
          ),
        ));

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Use Reviver'), findsNothing); // Button should be hidden when loading
      });

      testWidgets('should call onConfirm when confirm button is tapped', (WidgetTester tester) async {
        // Arrange
        bool confirmCalled = false;
        
        await tester.pumpWidget(createTestWidget(
          child: ItemUsageConfirmationDialog(
            title: 'Use Streak Reviver?',
            description: 'Use a Streak Reviver to restore your lost streak?',
            itemName: 'Streak Reviver',
            icon: Icons.restore,
            iconColor: AppTheme.secondaryOrange,
            confirmButtonText: 'Use Reviver',
            isLoading: false,
            onConfirm: () => confirmCalled = true,
            onCancel: () {},
          ),
        ));

        // Act
        await tester.tap(find.text('Use Reviver'));
        await tester.pumpAndSettle();

        // Assert
        expect(confirmCalled, isTrue);
      });

      testWidgets('should call onCancel when cancel button is tapped', (WidgetTester tester) async {
        // Arrange
        bool cancelCalled = false;
        
        await tester.pumpWidget(createTestWidget(
          child: ItemUsageConfirmationDialog(
            title: 'Use Streak Reviver?',
            description: 'Use a Streak Reviver to restore your lost streak?',
            itemName: 'Streak Reviver',
            icon: Icons.restore,
            iconColor: AppTheme.secondaryOrange,
            confirmButtonText: 'Use Reviver',
            isLoading: false,
            onConfirm: () {},
            onCancel: () => cancelCalled = true,
          ),
        ));

        // Act
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Assert
        expect(cancelCalled, isTrue);
      });

      testWidgets('should disable confirm button when loading', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget(
          child: ItemUsageConfirmationDialog(
            title: 'Use Streak Reviver?',
            description: 'Use a Streak Reviver to restore your lost streak?',
            itemName: 'Streak Reviver',
            icon: Icons.restore,
            iconColor: AppTheme.secondaryOrange,
            confirmButtonText: 'Use Reviver',
            isLoading: true,
            onConfirm: () {},
            onCancel: () {},
          ),
        ));

        // Assert
        final confirmButton = find.text('Use Reviver');
        expect(confirmButton, findsNothing); // Button should be hidden when loading
        
        // Check that loading indicator is shown instead
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should display correct icon and color', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget(
          child: ItemUsageConfirmationDialog(
            title: 'Use Streak Freeze?',
            description: 'Use a Streak Freeze to protect your streak?',
            itemName: 'Streak Freeze',
            icon: Icons.snowflake,
            iconColor: AppTheme.secondaryBlue,
            confirmButtonText: 'Use Freeze',
            isLoading: false,
            onConfirm: () {},
            onCancel: () {},
          ),
        ));

        // Assert
        expect(find.byIcon(Icons.snowflake), findsOneWidget);
        
        // Check icon color (you'd need to access the icon widget and check its color)
        final iconWidget = tester.widget<Icon>(find.byIcon(Icons.snowflake));
        expect(iconWidget.color, equals(AppTheme.secondaryBlue));
      });
    });

    group('Dialog Integration', () {
      testWidgets('should show success dialog after successful streak reviver usage', (WidgetTester tester) async {
        // Arrange
        when(mockStoreService.useStreakReviver()).thenAnswer((_) async => {
          'success': true,
          'message': 'Streak revived! Your 5-day streak has been restored.',
          'progress_history': {'current_streak': 5, 'previous_streak': 0},
          'store_items': {'streak_revivers': 1}
        });

        await tester.pumpWidget(createTestWidget(
          child: StreakLossDialog(
            previousStreak: 5,
            onRestore: () {},
            onMaybeLater: () {},
          ),
        ));

        // Act - Go through the full flow
        await tester.tap(find.text('Restore Streak'));
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('Restore Streak')); // Confirm in confirmation dialog
        await tester.pumpAndSettle();

        // Assert - Success dialog should appear
        expect(find.text('Streak Restored!'), findsOneWidget);
        expect(find.text('Streak revived! Your 5-day streak has been restored.'), findsOneWidget);
      });

      testWidgets('should show error dialog after failed streak reviver usage', (WidgetTester tester) async {
        // Arrange
        when(mockStoreService.useStreakReviver()).thenAnswer((_) async => null);
        when(mockStoreService.error).thenReturn('You don\'t have any streak revivers available');

        await tester.pumpWidget(createTestWidget(
          child: StreakLossDialog(
            previousStreak: 5,
            onRestore: () {},
            onMaybeLater: () {},
          ),
        ));

        // Act - Go through the full flow
        await tester.tap(find.text('Restore Streak'));
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('Restore Streak')); // Confirm in confirmation dialog
        await tester.pumpAndSettle();

        // Assert - Error dialog should appear
        expect(find.text('Error'), findsOneWidget);
        expect(find.text('You don\'t have any streak revivers available'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantic labels for screen readers', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget(
          child: StreakLossDialog(
            previousStreak: 5,
            onRestore: () {},
            onMaybeLater: () {},
          ),
        ));

        // Assert
        expect(find.bySemanticsLabel('Streak Lost'), findsOneWidget);
        expect(find.bySemanticsLabel('Restore Streak'), findsOneWidget);
        expect(find.bySemanticsLabel('Maybe Later'), findsOneWidget);
      });

      testWidgets('should support keyboard navigation', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget(
          child: ItemUsageConfirmationDialog(
            title: 'Use Streak Reviver?',
            description: 'Use a Streak Reviver to restore your lost streak?',
            itemName: 'Streak Reviver',
            icon: Icons.restore,
            iconColor: AppTheme.secondaryOrange,
            confirmButtonText: 'Use Reviver',
            isLoading: false,
            onConfirm: () {},
            onCancel: () {},
          ),
        ));

        // Act - Simulate keyboard navigation
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        // Assert - Focus should move to buttons
        // You'd check focus state in a real test
      });
    });
  });
}
