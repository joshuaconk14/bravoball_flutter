# Quick Start: Testing Your Integration Tests

## 🚀 Step-by-Step Guide

### **Step 1: Install Dependencies**

```bash
# Make sure you're in the project root
cd /Users/Joshua/Coding/bravoball_flutter

# Install dependencies (including integration_test)
flutter pub get
```

### **Step 2: Start an Emulator/Simulator**

You need a running device to test on. Choose one:

#### **Option A: iOS Simulator (Recommended for Mac)**

```bash
# Open Simulator
open -a Simulator

# Or list available simulators
xcrun simctl list devices available

# Boot a specific simulator
xcrun simctl boot "iPhone 15 Pro"
```

#### **Option B: Android Emulator**

```bash
# List available emulators
emulator -list-avds

# Start an emulator (replace with your AVD name)
emulator -avd Pixel_7_API_33 &
```

### **Step 3: Verify Device is Running**

```bash
# Check available devices
flutter devices

# You should see something like:
# iPhone 15 Pro (simulator) • 12345678-1234-1234-1234-123456789ABC • ios
# Or
# Pixel 7 API 33 (emulator) • emulator-5554 • android
```

### **Step 4: Run Integration Tests**

```bash
# Run all integration tests
flutter test integration_test/

# Or run specific test files
flutter test integration_test/app_test.dart
flutter test integration_test/store_integration_test.dart
flutter test integration_test/auth_integration_test.dart

# Run with verbose output to see what's happening
flutter test integration_test/ --verbose
```

### **Step 5: Watch Tests Execute**

You'll see:
- ✅ App launches on your emulator/simulator
- ✅ Tests interact with the UI (taps, text input)
- ✅ Test results in the terminal
- ✅ Pass/fail status

### **Step 6: Test CI/CD (Optional - After Local Tests Work)**

Once local tests work:

1. **Commit your changes:**
   ```bash
   git add .
   git commit -m "Add integration tests and CI/CD"
   ```

2. **Push to GitHub:**
   ```bash
   git push origin your-branch-name
   ```

3. **Check GitHub Actions:**
   - Go to your GitHub repo
   - Click the "Actions" tab
   - Watch the workflow run
   - See test results

## 🔧 Troubleshooting

### **Problem: "No devices found"**

**Solution:**
```bash
# Make sure emulator/simulator is running
flutter devices

# If nothing shows, start one:
# iOS: open -a Simulator
# Android: emulator -avd YourAVDName
```

### **Problem: "Integration test binding not initialized"**

**Solution:**
Make sure your test file has:
```dart
IntegrationTestWidgetsFlutterBinding.ensureInitialized();
```

### **Problem: "Widget not found"**

**Solution:**
- Tests might be finding widgets that don't exist yet
- Update the test selectors to match your actual UI
- Use `find.byKey()` with keys in your widgets
- Check widget text/labels match exactly

### **Problem: Tests timeout**

**Solution:**
```bash
# Increase timeout
flutter test integration_test/ --timeout=600
```

## 📝 What to Test First

### **1. Start Simple**

Run the basic app test:
```bash
flutter test integration_test/app_test.dart
```

This should:
- ✅ Launch your app
- ✅ Verify basic app structure
- ✅ Take about 10-30 seconds

### **2. Test Store Features**

```bash
flutter test integration_test/store_integration_test.dart
```

This will test:
- Store page loading
- Streak reviver/freeze dialogs
- UI interactions

### **3. Test Authentication**

```bash
flutter test integration_test/auth_integration_test.dart
```

Note: You may need to update selectors to match your actual UI.

## ✅ Success Checklist

- [ ] Dependencies installed (`flutter pub get`)
- [ ] Emulator/simulator running (`flutter devices` shows device)
- [ ] App launches successfully in test
- [ ] At least one test passes
- [ ] Can see test interactions on device

## 🎯 Expected Output

When tests run successfully, you'll see:

```
Running "integration_test/app_test.dart"...
00:01 +1: BravoBall App Integration Tests App launches successfully
00:05 +2: BravoBall App Integration Tests App navigation works correctly
00:10 +3: BravoBall App Integration Tests App handles errors gracefully
00:15 +3: All tests passed!

Test completed successfully!
```

## 🚨 Important Notes

1. **Update Test Selectors**: The tests use placeholder selectors (`find.text('Store')`). You'll need to update them to match your actual UI.

2. **Login Required**: Some tests might require you to be logged in. You may need to:
   - Update tests to handle login
   - Use test accounts
   - Mock authentication

3. **API Calls**: Tests can make real API calls. Consider:
   - Using a test backend
   - Mocking API responses
   - Using environment variables for test mode

## 🎉 Next Steps

Once local tests work:

1. **Customize tests** for your specific UI
2. **Add more tests** for new features
3. **Push to GitHub** to test CI/CD
4. **Monitor CI/CD** results in GitHub Actions

---

**Ready? Start with Step 1!** 🚀
