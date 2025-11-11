# RevenueCat SDK Mocking Issues - Unit Testing

## Overview

This document outlines the challenges and known issues when attempting to mock the RevenueCat SDK (`purchases_flutter`) for unit testing in the BravoBall Flutter app.

## Architecture

Our app uses a **dependency injection pattern** to make RevenueCat testable:

```
RevenueCatService (interface)
    ↑
    ├── RevenueCatServiceImpl (production implementation)
    └── MockRevenueCatService (test implementation - TODO)
```

### Current Implementation

- **`lib/services/revenue_cat_service.dart`**: Abstract interface defining RevenueCat operations
- **`lib/services/revenue_cat_service_impl.dart`**: Production implementation wrapping static `Purchases` methods
- **`lib/services/unified_purchase_service.dart`**: Uses `RevenueCatService` via dependency injection

## Known Issues & Challenges

### 1. Static Methods Cannot Be Mocked Directly

**Problem:**
The RevenueCat SDK (`purchases_flutter`) uses static methods:
```dart
Purchases.getCustomerInfo()
Purchases.getOfferings()
Purchases.purchase(params)
```

**Impact:**
- Cannot use `mockito` to directly mock `Purchases` class
- Static methods bypass normal dependency injection patterns
- Requires wrapper pattern (which we've implemented)

**Status:** ✅ **Mitigated** - We wrap static methods in `RevenueCatServiceImpl`

### 2. Platform Channel Dependencies

**Problem:**
RevenueCat SDK relies on platform channels (native iOS/Android code) that don't exist in unit test environment.

**Impact:**
- Even with mocks, some initialization may fail
- Cannot test actual purchase flows without real device/simulator
- Platform-specific code paths are untestable in unit tests

**Status:** ⚠️ **Limitation** - Requires integration tests for full coverage

### 3. Complex Return Types

**Problem:**
RevenueCat returns complex objects (`CustomerInfo`, `Offerings`, `Package`) that are difficult to construct manually:

```dart
Future<CustomerInfo> getCustomerInfo();
Future<Offerings> getOfferings();
Future<CustomerInfo> purchase(PurchaseParams params);
```

**Impact:**
- Creating test doubles requires deep knowledge of RevenueCat's internal structure
- Many properties may be required even if not used in tests
- Risk of creating invalid test data that doesn't match production behavior

**Status:** ⚠️ **Challenging** - Requires careful mock implementation

### 4. Async Operations

**Problem:**
All RevenueCat operations are async and may involve network calls or platform channels.

**Impact:**
- Tests must properly handle async/await
- Mock implementations need to simulate async behavior
- Error scenarios are harder to test

**Status:** ✅ **Manageable** - Standard Dart async testing patterns apply

### 5. Initialization Requirements

**Problem:**
RevenueCat requires initialization before use:
```dart
await Purchases.configure(configuration);
```

**Impact:**
- Tests may fail if initialization isn't properly mocked
- Initialization state affects all subsequent calls
- Cannot test without proper setup

**Status:** ⚠️ **Requires Setup** - Tests need initialization mocks

## Current Testing Strategy

### What We Can Test (Without Mocks)

1. **Business Logic** - Purchase validation, treat amount calculations
   - ✅ `PurchaseConfig` tests (see `unit_test/config/purchase_config_test.dart`)
   - ✅ Store business rules validation
   - ✅ Package/product ID mapping

2. **Service Logic** - Error handling, state management
   - ✅ `StoreService` business logic (see `unit_test/services/store_service_test.dart`)
   - ✅ Purchase flow logic (when mocks are available)

### What Requires Mocks

1. **RevenueCat Integration** - Actual SDK calls
   - ❌ `UnifiedPurchaseService.purchaseProduct()` - needs `RevenueCatService` mock
   - ❌ `PremiumUtils.hasPremiumAccess()` - needs `RevenueCatService` mock
   - ❌ Purchase result handling - needs `CustomerInfo` mock

2. **Error Scenarios** - SDK error handling
   - ❌ Purchase cancellation
   - ❌ Network failures
   - ❌ Invalid package errors

## Recommended Solutions

### Solution 1: Manual Mock Implementation (Recommended)

Create a manual mock class implementing `RevenueCatService`:

```dart
// unit_test/mocks/mock_revenue_cat_service.dart
class MockRevenueCatService implements RevenueCatService {
  CustomerInfo? _customerInfo;
  Offerings? _offerings;
  bool _shouldThrowError = false;
  PurchasesError? _errorToThrow;

  void setCustomerInfo(CustomerInfo customerInfo) {
    _customerInfo = customerInfo;
  }

  void setOfferings(Offerings offerings) {
    _offerings = offerings;
  }

  void setShouldThrowError(bool shouldThrow, {PurchasesError? error}) {
    _shouldThrowError = shouldThrow;
    _errorToThrow = error;
  }

  @override
  Future<CustomerInfo> getCustomerInfo() async {
    if (_shouldThrowError) {
      throw _errorToThrow ?? PurchasesError(
        PurchasesErrorCode.storeProductNotAvailableError,
        'Mock error',
      );
    }
    return _customerInfo ?? _createMockCustomerInfo();
  }

  @override
  Future<Offerings> getOfferings() async {
    if (_shouldThrowError) {
      throw _errorToThrow ?? PurchasesError(
        PurchasesErrorCode.storeProductNotAvailableError,
        'Mock error',
      );
    }
    return _offerings ?? _createMockOfferings();
  }

  @override
  Future<CustomerInfo> purchase(PurchaseParams params) async {
    if (_shouldThrowError) {
      throw _errorToThrow ?? PurchasesError(
        PurchasesErrorCode.purchaseCancelledError,
        'Mock purchase cancelled',
      );
    }
    return _customerInfo ?? _createMockCustomerInfo();
  }

  // ... implement other methods

  CustomerInfo _createMockCustomerInfo() {
    // Create minimal CustomerInfo for testing
    // This is challenging - may need to use a builder pattern
  }

  Offerings _createMockOfferings() {
    // Create minimal Offerings for testing
    // This is challenging - may need to use a builder pattern
  }
}
```

**Pros:**
- Full control over test behavior
- No external dependencies
- Can simulate any scenario

**Cons:**
- Requires manual construction of complex objects
- Time-consuming to implement
- May not match production behavior exactly

### Solution 2: Integration Tests Instead

Focus on integration tests for RevenueCat-dependent code:

```dart
// integration_test/revenue_cat_integration_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Purchase flow works', (WidgetTester tester) async {
    // Test with real RevenueCat SDK
    // Requires test environment setup
  });
}
```

**Pros:**
- Tests real behavior
- Catches integration issues
- No mocking complexity

**Cons:**
- Requires test environment (sandbox accounts, etc.)
- Slower than unit tests
- May require manual intervention

### Solution 3: Extract Business Logic

Continue extracting pure business logic that doesn't require RevenueCat:

```dart
// Extract to pure functions
class PurchaseBusinessLogic {
  static bool canPurchase(int treats, int cost) {
    return treats >= cost;
  }

  static int calculateTreatAmount(String packageId) {
    return PurchaseConfig.getTreatAmountFromPackageId(packageId);
  }
}
```

**Pros:**
- Easy to test
- Fast execution
- High confidence

**Cons:**
- Doesn't test integration
- Requires refactoring

## Best Practices

### 1. Test Business Logic Separately

Focus unit tests on business logic that doesn't require RevenueCat:

```dart
// ✅ Good - Tests business logic
test('purchaseStreakFreeze returns false when insufficient treats', () {
  // Test treat validation logic
});

// ❌ Avoid - Requires RevenueCat mock
test('purchaseProduct calls RevenueCat', () {
  // This requires complex mocking
});
```

### 2. Use Dependency Injection

Always inject `RevenueCatService` for testability:

```dart
// ✅ Good - Injectable
class UnifiedPurchaseService {
  final RevenueCatService revenueCat;
  
  UnifiedPurchaseService({RevenueCatService? revenueCat})
    : revenueCat = revenueCat ?? RevenueCatServiceImpl();
}

// ❌ Bad - Hard-coded dependency
class UnifiedPurchaseService {
  Future<void> purchase() {
    return Purchases.purchase(...); // Cannot test
  }
}
```

### 3. Create Minimal Test Doubles

When creating mocks, focus on what's needed for the test:

```dart
// ✅ Good - Minimal mock
class MinimalCustomerInfo implements CustomerInfo {
  @override
  Set<String> get activeSubscriptions => {'premium_monthly'};
  
  // Only implement what's needed for tests
}

// ❌ Avoid - Over-engineering
class FullCustomerInfo implements CustomerInfo {
  // Implementing every property is unnecessary
}
```

### 4. Document Mock Limitations

When using mocks, document what they don't test:

```dart
test('purchaseProduct handles success', () {
  // Note: This test uses a mock RevenueCatService
  // It does NOT test:
  // - Actual SDK integration
  // - Platform channel communication
  // - Real purchase flows
  // See integration tests for those scenarios
});
```

## Current Status

### ✅ Completed

- [x] Dependency injection pattern implemented
- [x] `RevenueCatService` interface created
- [x] `RevenueCatServiceImpl` wraps static methods
- [x] Business logic tests (PurchaseConfig, StoreService)

### ⚠️ In Progress

- [ ] Mock implementation for `RevenueCatService`
- [ ] Unit tests for `UnifiedPurchaseService`
- [ ] Unit tests for `PremiumUtils`

### ❌ Blocked/Challenging

- [ ] Full RevenueCat SDK mocking (complex object construction)
- [ ] Error scenario testing (requires PurchasesError mocks)
- [ ] Integration test setup (requires sandbox environment)

## Workarounds

### For Now: Focus on Testable Code

1. **Test PurchaseConfig** - ✅ Already done
2. **Test StoreService business logic** - ✅ Already done
3. **Test treat calculations** - ✅ Already done
4. **Skip RevenueCat integration tests** - Use integration tests instead

### Future: Mock Implementation

When ready to test RevenueCat-dependent code:

1. Create `MockRevenueCatService` class
2. Implement minimal `CustomerInfo` and `Offerings` builders
3. Add unit tests for `UnifiedPurchaseService`
4. Document mock limitations

## References

- [RevenueCat Flutter SDK Documentation](https://docs.revenuecat.com/docs/flutter)
- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Unit Testing Strategy](./UNIT_TESTING_STRATEGY.md)

## Questions & Notes

- **Q:** Can we use `mockito` with `@GenerateMocks`?
  - **A:** Not directly for `Purchases` (static methods), but we can mock `RevenueCatService` interface
  
- **Q:** Should we test RevenueCat SDK itself?
  - **A:** No - only test our code that uses it
  
- **Q:** How do we test error scenarios?
  - **A:** Mock `RevenueCatService` to throw `PurchasesError` exceptions

---

**Last Updated:** 2024
**Status:** Active Issue - Mocking implementation pending

