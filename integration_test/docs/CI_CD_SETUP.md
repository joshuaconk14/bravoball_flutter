# CI/CD Pipeline Setup Guide

## 🎯 Overview

This guide explains your complete CI/CD setup for automated testing and deployment. The pipeline runs automatically on every push/PR to ensure your app works correctly before merging.

## 📋 What Was Created

### 1. **Integration Tests** (`integration_test/`)
- `app_test.dart` - Main app lifecycle tests
- `store_integration_test.dart` - Store & Premium feature tests
- `auth_integration_test.dart` - Authentication flow tests
- `driver.dart` - Integration test driver

### 2. **GitHub Actions CI/CD** (`.github/workflows/ci.yml`)
- Code analysis (linting, formatting)
- Unit & widget tests with coverage
- Integration tests (Android & iOS)
- Build verification (APK & iOS)
- Security scanning

### 3. **Documentation**
- `INTEGRATION_TESTING_GUIDE.md` - Complete testing guide
- This file - CI/CD setup guide

## 🚀 How It Works

### When You Push Code

```
┌─────────────────────────────────────┐
│  You push to GitHub (push/PR)       │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  GitHub Actions Triggers            │
│  (.github/workflows/ci.yml)         │
└──────────────┬──────────────────────┘
               │
               ├──► Code Analysis
               │   ├─ Flutter analyze
               │   └─ Format check
               │
               ├──► Unit Tests
               │   ├─ Run test/unit/
               │   ├─ Generate coverage
               │   └─ Upload to Codecov
               │
               ├──► Integration Tests (Android)
               │   ├─ Launch Android emulator
               │   ├─ Run integration_test/
               │   └─ Upload results
               │
               ├──► Integration Tests (iOS)
               │   ├─ Launch iOS simulator
               │   ├─ Run integration_test/
               │   └─ Upload results
               │
               └──► Build Verification
                   ├─ Build Android APK
                   ├─ Build iOS app
                   └─ Upload artifacts
```

### Pipeline Jobs

#### 1. **Code Analysis** (`analyze`)
- ✅ Runs: `flutter analyze`
- ✅ Runs: `dart format --set-exit-if-changed`
- ⏱️ Duration: ~2 minutes

#### 2. **Unit Tests** (`unit-tests`)
- ✅ Runs: `flutter test test/unit/`
- ✅ Generates coverage report
- ✅ Uploads to Codecov
- ⏱️ Duration: ~5 minutes

#### 3. **Integration Tests** (`integration-tests-android`)
- ✅ Launches Android emulator (API 29)
- ✅ Runs: `flutter test integration_test/`
- ✅ Uploads test results
- ⏱️ Duration: ~15 minutes

#### 4. **Integration Tests** (`integration-tests-ios`)
- ✅ Launches iOS simulator (iPhone 15 Pro)
- ✅ Runs: `flutter test integration_test/`
- ✅ Uploads test results
- ⏱️ Duration: ~15 minutes

#### 5. **Build Verification** (`build-android`, `build-ios`)
- ✅ Builds release APK
- ✅ Builds iOS app
- ✅ Uploads build artifacts
- ⏱️ Duration: ~10 minutes each

## 🏃 Running Locally

### Before Committing

```bash
# 1. Install dependencies
flutter pub get

# 2. Run code analysis
flutter analyze
dart format --set-exit-if-changed .

# 3. Run unit tests
flutter test test/unit/

# 4. Run integration tests (requires emulator/simulator)
flutter test integration_test/

# 5. Build to verify
flutter build apk --release
flutter build ios --release --no-codesign
```

### Quick Test Commands

```bash
# Unit tests only
flutter test test/unit/

# Integration tests only
flutter test integration_test/

# All tests
flutter test

# With coverage
flutter test --coverage
```

## 📊 What Happens During Integration Tests

When you run `flutter test integration_test/`:

1. **App Launches**: Your full app starts on the emulator/simulator
2. **Test Execution**: Tests interact with the real UI (taps, text input, scrolling)
3. **Real Device Behavior**: Tests run on actual device environments
4. **API Calls**: Tests can make real API calls (or use test backends)
5. **Result Verification**: Tests check UI state, responses, and behavior

### Example: Store Integration Test

```dart
testWidgets('Store page loads and displays items', (tester) async {
  // 1. App launches
  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 5));

  // 2. Navigate to store
  await tester.tap(find.text('Store'));
  await tester.pumpAndSettle();

  // 3. Verify UI
  expect(find.text('My Items'), findsOneWidget);
  expect(find.text('Streak Revivers'), findsOneWidget);
});
```

## 🔧 Configuration

### GitHub Actions Secrets

If you need to use secrets (API keys, signing keys), add them in GitHub:

1. Go to: **Settings** → **Secrets and variables** → **Actions**
2. Add secrets:
   - `REVENUECAT_API_KEY` (if needed)
   - `ANDROID_KEYSTORE_PASSWORD` (for signing)
   - `IOS_SIGNING_KEY` (for signing)

### Customize Pipeline

Edit `.github/workflows/ci.yml` to:
- Change Flutter version
- Add more test jobs
- Modify build configurations
- Add deployment steps

### Test Triggers

Tests run automatically on:
- ✅ Push to `main` branch
- ✅ Push to `develop` branch
- ✅ Push to `pointsSystemTest*` branches
- ✅ Pull requests to any branch

## 📈 Monitoring CI/CD

### View Results

1. **GitHub Actions Tab**: Click "Actions" in your GitHub repo
2. **Check Status**: Green ✅ = passed, Red ❌ = failed
3. **View Logs**: Click any job to see detailed logs
4. **Download Artifacts**: APK/iOS builds available after successful runs

### Coverage Reports

- Coverage uploaded to Codecov (if configured)
- View coverage at: `https://codecov.io/gh/<your-repo>`
- Track coverage trends over time

## ✅ Success Checklist

Before your first CI/CD run:

- [ ] Push code to GitHub
- [ ] Check GitHub Actions tab
- [ ] Verify tests run successfully
- [ ] Review test results
- [ ] Download build artifacts
- [ ] Monitor coverage reports

## 🐛 Troubleshooting

### Tests Fail in CI But Pass Locally

**Solution**: 
- Check CI logs for specific errors
- Ensure environment variables are set
- Verify dependencies are installed correctly
- Check device/emulator availability

### Integration Tests Timeout

**Solution**:
- Increase timeout in workflow file
- Reduce test complexity
- Use faster emulators
- Run fewer tests per job

### Build Failures

**Solution**:
- Check signing certificates
- Verify build configuration
- Check dependency versions
- Review error logs

## 🎯 Next Steps

1. **Run Locally First**: Test everything locally before pushing
2. **Monitor First Run**: Watch the first CI/CD run carefully
3. **Fix Any Issues**: Address any failures immediately
4. **Iterate**: Add more tests as you add features
5. **Document**: Update tests when UI/features change

## 📚 Resources

- [Flutter Integration Tests](https://docs.flutter.dev/testing/integration-tests)
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [CI/CD Best Practices](https://docs.flutter.dev/deployment/cd)

---

**Your CI/CD pipeline is now set up!** 🎉

Every time you push code, the pipeline will:
- ✅ Verify code quality
- ✅ Run all tests
- ✅ Build release versions
- ✅ Catch bugs early

This ensures your app is always production-ready! 🚀
