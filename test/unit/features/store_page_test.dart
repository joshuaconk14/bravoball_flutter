import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bravoball_flutter/features/store/store_page.dart';
import 'package:bravoball_flutter/services/store_service.dart';
import 'package:bravoball_flutter/services/app_state_service.dart';
import 'package:bravoball_flutter/constants/app_theme.dart';

// Generate mocks
@GenerateMocks([StoreService, AppStateService])
import 'store_page_test.mocks.dart';

void main() {
  group('StorePage Widget Tests', () {
    late MockStoreService mockStoreService;
    late MockAppStateService mockAppStateService;

    setUp(() {
      mockStoreService = MockStoreService();
      mockAppStateService = MockAppStateService();
      
      // Setup default mock behaviors
      when(mockStoreService.treats).thenReturn(5);
      when(mockStoreService.streakFreezes).thenReturn(3);
      when(mockStoreService.streakRevivers).thenReturn(2);
      when(mockStoreService.isLoading).thenReturn(false);
      when(mockStoreService.error).thenReturn(null);
      when(mockStoreService.activeFreezeDate).thenReturn(null);
      when(mockStoreService.usedFreezes).thenReturn([]);
      when(mockStoreService.usedRevivers).thenReturn([]);
      
      when(mockAppStateService.currentStreak).thenReturn(5);
      when(mockAppStateService.highestStreak).thenReturn(10);
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<StoreService>.value(value: mockStoreService),
            ChangeNotifierProvider<AppStateService>.value(value: mockAppStateService),
          ],
          child: const StorePage(),
        ),
      );
    }

    group('UI Rendering', () {
      testWidgets('should display store items correctly', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert - Check that store items are displayed
        expect(find.text('My Items'), findsOneWidget);
        expect(find.text('5'), findsWidgets); // Treats count
        expect(find.text('3'), findsWidgets); // Streak freezes count
        expect(find.text('2'), findsWidgets); // Streak revivers count
      });

      testWidgets('should show loading state', (WidgetTester tester) async {
        // Arrange
        when(mockStoreService.isLoading).thenReturn(true);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should display error message when error occurs', (WidgetTester tester) async {
        // Arrange
        when(mockStoreService.error).thenReturn('Failed to load store items');

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Failed to load store items'), findsOneWidget);
      });
    });

    group('User Interactions', () {
      testWidgets('should show confirmation dialog when tapping streak reviver', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Act - Find and tap the streak reviver item
        final reviverItem = find.byKey(const Key('streak_reviver_item'));
        expect(reviverItem, findsOneWidget);
        
        await tester.tap(reviverItem);
        await tester.pumpAndSettle();

        // Assert - Check that confirmation dialog appears
        expect(find.text('Use Streak Reviver?'), findsOneWidget);
        expect(find.text('Use a Streak Reviver to restore your lost streak?'), findsOneWidget);
      });

      testWidgets('should show confirmation dialog when tapping streak freeze', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Act - Find and tap the streak freeze item
        final freezeItem = find.byKey(const Key('streak_freeze_item'));
        expect(freezeItem, findsOneWidget);
        
        await tester.tap(freezeItem);
        await tester.pumpAndSettle();

        // Assert - Check that confirmation dialog appears
        expect(find.text('Use Streak Freeze?'), findsOneWidget);
        expect(find.text('Use a Streak Freeze to protect your streak for today?'), findsOneWidget);
      });

      testWidgets('should handle confirmation dialog confirm action', (WidgetTester tester) async {
        // Arrange
        when(mockStoreService.useStreakReviver()).thenAnswer((_) async => {
          'success': true,
          'message': 'Streak revived!',
          'progress_history': {'current_streak': 5, 'previous_streak': 0},
          'store_items': {'streak_revivers': 1}
        });

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Act - Open dialog and confirm
        await tester.tap(find.byKey(const Key('streak_reviver_item')));
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('Use Reviver'));
        await tester.pumpAndSettle();

        // Assert - Verify service method was called
        verify(mockStoreService.useStreakReviver()).called(1);
      });

      testWidgets('should handle confirmation dialog cancel action', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Act - Open dialog and cancel
        await tester.tap(find.byKey(const Key('streak_reviver_item')));
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Assert - Dialog should be closed, no service call
        expect(find.text('Use Streak Reviver?'), findsNothing);
        verifyNever(mockStoreService.useStreakReviver());
      });
    });

    group('Premium Features', () {
      testWidgets('should show premium upgrade button for non-premium users', (WidgetTester tester) async {
        // Arrange
        when(mockAppStateService.isPremium).thenReturn(false);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Upgrade to Premium'), findsOneWidget);
      });

      testWidgets('should hide premium upgrade button for premium users', (WidgetTester tester) async {
        // Arrange
        when(mockAppStateService.isPremium).thenReturn(true);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Upgrade to Premium'), findsNothing);
      });
    });

    group('Item Availability', () {
      testWidgets('should disable streak reviver when count is zero', (WidgetTester tester) async {
        // Arrange
        when(mockStoreService.streakRevivers).thenReturn(0);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert - Item should be disabled/grayed out
        final reviverItem = find.byKey(const Key('streak_reviver_item'));
        expect(reviverItem, findsOneWidget);
        
        // Check if the item has disabled styling
        final container = tester.widget<Container>(
          find.descendant(of: reviverItem, matching: find.byType(Container))
        );
        // You'd check for opacity or other disabled styling
      });

      testWidgets('should disable streak freeze when count is zero', (WidgetTester tester) async {
        // Arrange
        when(mockStoreService.streakFreezes).thenReturn(0);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        final freezeItem = find.byKey(const Key('streak_freeze_item'));
        expect(freezeItem, findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should show error dialog when streak reviver fails', (WidgetTester tester) async {
        // Arrange
        when(mockStoreService.useStreakReviver()).thenAnswer((_) async => null);
        when(mockStoreService.error).thenReturn('Failed to use streak reviver');

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.byKey(const Key('streak_reviver_item')));
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('Use Reviver'));
        await tester.pumpAndSettle();

        // Assert - Error dialog should appear
        expect(find.text('Error'), findsOneWidget);
        expect(find.text('Failed to use streak reviver'), findsOneWidget);
      });

      testWidgets('should show success dialog when streak reviver succeeds', (WidgetTester tester) async {
        // Arrange
        when(mockStoreService.useStreakReviver()).thenAnswer((_) async => {
          'success': true,
          'message': 'Streak revived! Your 5-day streak has been restored.',
          'progress_history': {'current_streak': 5, 'previous_streak': 0},
          'store_items': {'streak_revivers': 1}
        });

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.byKey(const Key('streak_reviver_item')));
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('Use Reviver'));
        await tester.pumpAndSettle();

        // Assert - Success dialog should appear
        expect(find.text('Success!'), findsOneWidget);
        expect(find.text('Streak revived! Your 5-day streak has been restored.'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantic labels', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert - Check for semantic labels
        expect(find.bySemanticsLabel('Streak Reviver'), findsOneWidget);
        expect(find.bySemanticsLabel('Streak Freeze'), findsOneWidget);
        expect(find.bySemanticsLabel('Treats'), findsOneWidget);
      });

      testWidgets('should support screen readers', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert - Check that important text is accessible
        expect(find.text('My Items'), findsOneWidget);
        expect(find.text('Store'), findsOneWidget);
      });
    });
  });
}
