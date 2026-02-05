# Integration Testing Guide for BravoBall Flutter

## 🧪 Overview

This guide explains how to run integration tests for the BravoBall Flutter app. Integration tests verify that the entire app works correctly on real devices/emulators, including user interactions, API calls, and complete user flows.

## 📁 Test Structure

```
integration_test/
├── app_test.dart              # Main app integration tests
├── store_integration_test.dart # Store & Premium feature tests
├── auth_integration_test.dart  # Authentication flow tests
└── driver.dart                # Integration test driver
```

## 🚀 Running Integration Tests

### Prerequisites

1. **Install Flutter** (3.24.0 or higher)
2. **Set up Android Emulator** or **iOS Simulator**
3. **Ensure device is running** before starting tests

### Running Tests Locally

#### Option 1: Using `flutter test` (Recommended)

```bash
# Run all integration tests
flutter test integration_test/

# Run specific test file
flutter test integration_test/store_integration_test.dart

# Run with verbose output
flutter test integration_test/ --verbose
```

#### Option 2: Using `flutter drive` (Legacy)

```bash
# Run on Android emulator
flutter drive \
  --driver=integration_test/driver.dart \
  --target=integration_test/app_test.dart \
  -d <device-id>

# Run on iOS simulator
flutter drive \
  --driver=integration_test/driver.dart \
  --target=integration_test/app_test.dart \
  -d <device-id>
```

#### Find Device IDs

```bash
# List all available devices
flutter devices

# Example output:
# iPhone 15 Pro (simulator) • 12345678-1234-1234-1234-123456789ABC • ios • com.apple.CoreSimulator.SimRuntime.iOS-17-0
# Pixel 7 API 33 (emulator)  • emulator-5554                         • android
```

### Running Tests in CI/CD

The CI/CD pipeline automatically runs integration tests on every push/PR:

```yaml
# .github/workflows/ci.yml handles:
- Unit tests
- Integration tests (Android & iOS)
- Code analysis
- Build verification
```

## 📝 Writing Integration Tests

### Basic Test Structure

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:bravoball_flutter/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test description', (WidgetTester tester) async {
    // 1. Launch app
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // 2. Interact with UI
    await tester.tap(find.text('Button'));
    await tester.pumpAndSettle();

    // 3. Verify results
    expect(find.text('Expected Result'), findsOneWidget);
  });
}
```

### Best Practices

#### ✅ DO:
- **Wait for animations**: Use `await tester.pumpAndSettle()` after interactions
- **Use meaningful timeouts**: Set appropriate durations for async operations
- **Find widgets reliably**: Use keys or semantic labels when possible
- **Test user flows**: Focus on complete user journeys, not isolated components
- **Handle errors gracefully**: Test error scenarios and recovery

#### ❌ DON'T:
- **Don't use exact pixel positions**: Widgets can move between devices
- **Don't hardcode delays**: Use `pumpAndSettle()` instead of `Future.delayed()`
- **Don't test internal implementation**: Focus on user-visible behavior
- **Don't rely on external services**: Mock or use test backends when possible

### Common Patterns

#### Navigating Between Screens

```dart
// Find navigation tab
final storeTab = find.text('Store');
if (storeTab.evaluate().isNotEmpty) {
  await tester.tap(storeTab);
  await tester.pumpAndSettle(const Duration(seconds: 3));
}
```

#### Entering Text

```dart
// Find text field
final emailField = find.byType(TextField).first;
await tester.enterText(emailField, 'test@example.com');
await tester.pumpAndSettle();
```

#### Tapping Buttons

```dart
// Find button by text
final loginButton = find.text('Login');
await tester.tap(loginButton);
await tester.pumpAndSettle();
```

#### Verifying UI State

```dart
// Check if widget exists
expect(find.text('Success!'), findsOneWidget);

// Check if widget doesn't exist
expect(find.text('Error'), findsNothing);

// Check widget count
expect(find.byType(Text), findsNWidgets(3));
```

## 🎯 Test Coverage Areas

### Store & Premium Features
- ✅ Store page loads and displays items
- ✅ Streak reviver confirmation flow
- ✅ Streak freeze confirmation flow
- ✅ Item count updates after usage
- ✅ Premium purchase flow
- ✅ Calendar displays correctly
- ✅ Calendar shows correct colors (green/blue/orange)

### Authentication
- ✅ Login flow
- ✅ Logout flow
- ✅ Invalid credentials handling
- ✅ Session persistence

### App Lifecycle
- ✅ App launches successfully
- ✅ Navigation works correctly
- ✅ Error handling
- ✅ App state persistence

## 🔧 Troubleshooting

### Tests Fail with "Unable to find widget"

**Problem**: Test can't find a widget you expect to be there.

**Solutions**:
1. Increase `pumpAndSettle()` timeout
2. Use `find.byKey()` with explicit keys in your widgets
3. Check if widget is actually visible (not hidden/off-screen)
4. Use `find.bySemanticsLabel()` for accessibility

### Tests Run Too Slowly

**Problem**: Integration tests take a long time.

**Solutions**:
1. Reduce animation durations in test builds
2. Use `pump()` instead of `pumpAndSettle()` when appropriate
3. Skip unnecessary waits
4. Run tests on faster emulators

### Flaky Tests (Intermittent Failures)

**Problem**: Tests sometimes pass, sometimes fail.

**Solutions**:
1. Add explicit waits before critical assertions
2. Increase timeouts for slow operations
3. Avoid race conditions by using proper `pump()` calls
4. Isolate tests - each test should be independent

### Device Not Found

**Problem**: `flutter devices` shows no devices.

**Solutions**:
- **Android**: Start Android Studio and launch an emulator
- **iOS**: Open Xcode → Window → Devices and Simulators → Start a simulator
- Verify device with: `flutter devices`

## 📊 CI/CD Integration

### GitHub Actions Workflow

The CI pipeline (`.github/workflows/ci.yml`) automatically:

1. **Analyzes code** on every push/PR
2. **Runs unit tests** with coverage
3. **Runs integration tests** on Android & iOS
4. **Builds release versions** if tests pass
5. **Uploads artifacts** for manual testing

### Running Tests Locally Like CI

```bash
# Run exactly what CI runs
flutter test test/unit/                    # Unit tests
flutter test integration_test/           # Integration tests
flutter analyze                           # Code analysis
flutter build apk --release              # Build Android
flutter build ios --release --no-codesign # Build iOS
```

## 🎓 Learning Resources

- [Flutter Integration Testing Docs](https://docs.flutter.dev/testing/integration-tests)
- [Widget Testing Guide](https://docs.flutter.dev/testing/widget-tests)
- [CI/CD Best Practices](https://docs.flutter.dev/deployment/cd)

## 📝 Checklist for Adding New Integration Tests

When adding a new feature:

- [ ] Create test file in `integration_test/`
- [ ] Test happy path (successful flow)
- [ ] Test error scenarios
- [ ] Test edge cases
- [ ] Verify tests pass locally
- [ ] Verify tests pass in CI
- [ ] Update this guide if needed

## 🚀 Next Steps

1. **Run existing tests**: `flutter test integration_test/`
2. **Add feature-specific tests**: Create new test files for new features
3. **Maintain tests**: Update tests when UI/features change
4. **Monitor CI**: Check GitHub Actions for test results

---

**Remember**: Integration tests verify that your app works as users expect. Focus on user-visible behavior, not implementation details!
