# Unit Testing Strategy - BravoBall Flutter

## 🎯 Overview
This document outlines the unit testing approach for BravoBall. Focus on business logic, pure functions, and critical calculations.

## 📋 Testing Priorities

### Phase 1: Foundation (Week 1-2)
**Priority: Pure Utility Functions** ⭐ Highest ROI
- `lib/utils/skill_utils.dart` - String transformations
- `lib/utils/encryption_utils.dart` - Security-critical
- `lib/utils/preference_utils.dart` - Data transformations
- `lib/utils/haptic_utils.dart` - Simple logic

**Why First:** No dependencies to mock, fast, high confidence

### Phase 2: Business Logic (Week 3-4)
**Priority: Critical Calculations**
- `StoreService` - Business logic validation (treat requirements, item availability checks)
- Date calculations - Freeze/reviver date rules and validation
- Purchase validation logic - Checking if purchases are valid before API calls

**Why Second:** Business-critical, bug-prone, deterministic

**Strategy:** Extract pure business logic functions that can be tested without mocks

### Phase 3: Service Layer (Week 5-6)
**Priority: Services with External Dependencies**
- `UserManagerService` - Auth state
- `StoreService` - Store items
- `AuthenticationService` - Login/logout flows
- `ApiService` - HTTP handling

**Strategy:** Use dependency injection + mocking (need to add DI still)

### Phase 4: Models & Widgets (Week 7+)
**Priority: Data Validation & Complex Widgets**
- Model serialization/deserialization
- Complex widgets with business logic
- Form validators

## 🏗️ Test Structure

```
test/
├── utils/
│   ├── skill_utils_test.dart
│   ├── encryption_utils_test.dart
│   └── preference_utils_test.dart
├── services/
│   ├── store_service_test.dart
│   ├── user_manager_service_test.dart
│   └── authentication_service_test.dart
├── models/
│   ├── drill_model_test.dart
│   └── auth_models_test.dart
└── mocks/  # Generated mocks
    └── *.mocks.dart
```

## ✅ Best Practices

### Test Naming
```dart
// Good: Descriptive what + when
test('calculates streak correctly when user has consecutive sessions', () {...});
test('returns error when API request fails', () {...});

// Bad: Vague
test('test1', () {...});
```

### AAA Pattern
```dart
test('description', () {
  // Arrange - Set up test data
  final service = StoreService(...);
  
  // Act - Execute code
  final result = service.calculatePoints(...);
  
  // Assert - Verify results
  expect(result, 100);
});
```

### Dependency Injection for Testability
```dart
// Refactor singletons to accept dependencies
class StoreService {
  final ApiService _apiService;
  final UserManagerService _userManager;
  
  StoreService(this._apiService, this._userManager);
  
  // Factory for singleton
  static StoreService? _instance;
  static StoreService get instance => _instance ??= StoreService(
    ApiService.shared,
    UserManagerService.instance,
  );
  
  // For testing
  StoreService.test(this._apiService, this._userManager);
}
```

### Mocking Strategy
- Use `mockito` for external dependencies (API, SharedPreferences, RevenueCat)
- Mock only what you need
- Don't over-mock - test real logic when possible
- Use `@GenerateMocks([ApiService, UserManagerService])`

## 🎯 Coverage Goals

- **70-80%** coverage on business logic
- **100%** coverage on pure utility functions
- **60-70%** coverage on services
- Don't chase 100% overall (diminishing returns)

## 🚀 Quick Wins (Start Here)

1. **SkillUtils** - ~30 min, 5-6 tests
2. **EncryptionUtils** - ~1 hour, security-critical
3. **Streak calculation logic** - ~2 hours, business-critical
4. **Model validation** - ~1 hour per model

## ⚠️ Common Pitfalls

1. ❌ Testing implementation details → ✅ Test behavior
2. ❌ Over-mocking → ✅ Mock only external dependencies
3. ❌ Slow tests → ✅ Keep tests fast (<1s each)
4. ❌ Flaky tests → ✅ Mock time-dependent logic
5. ❌ Testing third-party code → ✅ Don't test Flutter/Dart framework

## 📝 Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/utils/skill_utils_test.dart

# Generate coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Watch mode (auto-rerun on changes)
flutter test --reporter expanded
```

## 📊 Success Metrics

- ✅ 70%+ test coverage on business logic
- ✅ All utility functions have tests
- ✅ All critical calculations have tests
- ✅ Tests run in < 5 seconds total
- ✅ Zero flaky tests
- ✅ Tests serve as documentation

## 🔄 Workflow

1. **Week 1:** Utility functions (SkillUtils, EncryptionUtils)
2. **Week 2:** Business logic (streak calculations, store logic)
3. **Week 3:** Refactor services for testability
4. **Week 4:** Service layer tests with mocks
5. **Week 5:** Model tests
6. **Week 6+:** Widget tests as needed

---

**Remember:** Focus on business logic and critical paths. Don't test framework code or pure UI.

