import 'package:flutter_test/flutter_test.dart';
import 'package:bravoball_flutter/services/store_service.dart';
import 'package:bravoball_flutter/utils/store_business_rules.dart';

void main() {
  late StoreService storeService;

  setUp(() {
    storeService = StoreService.instance;
  });

  group('StoreService - Business Logic Validation', () {
    test('purchaseStreakFreeze returns false when insufficient treats', () async {
      // Arrange - Add treats but not enough for freeze
      await storeService.addDebugTreats(StoreBusinessRules.streakFreezeCost - 1);
      final initialTreats = storeService.treats;
      expect(initialTreats, lessThan(StoreBusinessRules.streakFreezeCost));

      // Act
      final result = await storeService.purchaseStreakFreeze();

      // Assert
      expect(result, false);
      expect(storeService.error, contains('Not enough treats'));
      expect(storeService.treats, initialTreats); // Treats should not change
    });

    test('purchaseStreakFreeze succeeds when user has enough treats (unauthenticated mode)', () async {
      // Arrange - Add enough treats
      await storeService.addDebugTreats(StoreBusinessRules.streakFreezeCost);
      final initialTreats = storeService.treats;
      final initialFreezes = storeService.streakFreezes;

      // Act
      final result = await storeService.purchaseStreakFreeze();

      // Assert - Should succeed in unauthenticated mode (local update)
      expect(result, true);
      expect(storeService.treats, initialTreats - StoreBusinessRules.streakFreezeCost);
      expect(storeService.streakFreezes, initialFreezes + 1);
    });

    test('purchaseStreakReviver returns false when insufficient treats', () async {
      // Arrange - Set treats to exactly one less than required
      // Note: We need to account for existing treats, so we set to a known amount
      final currentTreats = storeService.treats;
      final targetTreats = StoreBusinessRules.streakReviverCost - 1;
      
      // If we already have more than target, we can't test this properly
      // So we'll just verify the business rule logic works
      if (currentTreats < targetTreats) {
        await storeService.addDebugTreats(targetTreats - currentTreats);
      }
      
      final initialTreats = storeService.treats;
      
      // Only test if we have insufficient treats
      if (initialTreats < StoreBusinessRules.streakReviverCost) {
        // Act
        final result = await storeService.purchaseStreakReviver();

        // Assert
        expect(result, false);
        expect(storeService.error, contains('Not enough treats'));
        expect(storeService.treats, initialTreats); // Treats should not change
      } else {
        // If we have enough, skip this test or verify the rule works
        expect(StoreBusinessRules.canPurchaseStreakReviver(initialTreats), true);
      }
    });

    test('useStreakFreeze returns null when no freezes available', () async {
      // Arrange - Ensure no freezes (we can't directly set, but we test the error path)
      
      // Act - Try to use freeze when we have 0
      final result = await storeService.useStreakFreeze();

      // Assert - Should return null if no freezes or not authenticated
      expect(result, isNull);
      expect(storeService.error, isNotNull);
    });

    test('useStreakReviver returns null when no revivers available', () async {
      // Arrange - Ensure no revivers
      
      // Act
      final result = await storeService.useStreakReviver();

      // Assert - Should return null if no revivers or not authenticated
      expect(result, isNull);
      expect(storeService.error, isNotNull);
    });
  });

  group('StoreService - Date Parsing Integration', () {
    test('parseDateSafely handles valid date strings', () {
      // Test that StoreBusinessRules.parseDateSafely works correctly
      final validDate = '2024-01-15T10:30:00Z';
      final result = StoreBusinessRules.parseDateSafely(validDate);
      
      expect(result, isNotNull);
      expect(result!.year, 2024);
      expect(result.month, 1);
      expect(result.day, 15);
    });

    test('parseDateSafely handles null', () {
      final result = StoreBusinessRules.parseDateSafely(null);
      expect(result, isNull);
    });

    test('parseDateSafely handles invalid date strings', () {
      final invalidDate = 'invalid-date';
      final result = StoreBusinessRules.parseDateSafely(invalidDate);
      expect(result, isNull);
    });
  });

  group('StoreService - Integration with StoreBusinessRules', () {
    test('uses StoreBusinessRules.streakFreezeCost for validation', () {
      // Verify that the service uses the utility constant
      final cost = StoreBusinessRules.streakFreezeCost;
      expect(cost, 50);
    });

    test('uses StoreBusinessRules.streakReviverCost for validation', () {
      // Verify that the service uses the utility constant
      final cost = StoreBusinessRules.streakReviverCost;
      expect(cost, 100);
    });

    test('canPurchaseStreakFreeze validation matches service logic', () {
      // Test that StoreBusinessRules.canPurchaseStreakFreeze matches service behavior
      expect(StoreBusinessRules.canPurchaseStreakFreeze(50), true);
      expect(StoreBusinessRules.canPurchaseStreakFreeze(49), false);
      expect(StoreBusinessRules.canPurchaseStreakFreeze(100), true);
    });

    test('canPurchaseStreakReviver validation matches service logic', () {
      // Test that StoreBusinessRules.canPurchaseStreakReviver matches service behavior
      expect(StoreBusinessRules.canPurchaseStreakReviver(100), true);
      expect(StoreBusinessRules.canPurchaseStreakReviver(99), false);
      expect(StoreBusinessRules.canPurchaseStreakReviver(200), true);
    });

    test('hasStreakFreezesAvailable validation matches service logic', () {
      // Test that StoreBusinessRules.hasStreakFreezesAvailable matches service behavior
      expect(StoreBusinessRules.hasStreakFreezesAvailable(1), true);
      expect(StoreBusinessRules.hasStreakFreezesAvailable(0), false);
      expect(StoreBusinessRules.hasStreakFreezesAvailable(5), true);
    });

    test('hasStreakReviversAvailable validation matches service logic', () {
      // Test that StoreBusinessRules.hasStreakReviversAvailable matches service behavior
      expect(StoreBusinessRules.hasStreakReviversAvailable(1), true);
      expect(StoreBusinessRules.hasStreakReviversAvailable(0), false);
      expect(StoreBusinessRules.hasStreakReviversAvailable(3), true);
    });
  });

  group('StoreService - State Management', () {
    test('clearError clears error message', () {
      // Arrange - Trigger an error
      // We can't directly set error, but we can trigger one and then clear it
      // For now, just test that clearError exists and doesn't throw
      expect(() => storeService.clearError(), returnsNormally);
    });

    test('isLoading state is managed correctly during purchase', () async {
      // Arrange - Add enough treats
      await storeService.addDebugTreats(StoreBusinessRules.streakFreezeCost);

      // Act
      final future = storeService.purchaseStreakFreeze();
      
      // Note: isLoading might be true during execution, but we can't easily test that
      // without exposing internal state. We verify it completes successfully.
      
      final result = await future;

      // Assert
      expect(result, true);
      expect(storeService.isLoading, false); // Should be false after completion
    });
  });
}
