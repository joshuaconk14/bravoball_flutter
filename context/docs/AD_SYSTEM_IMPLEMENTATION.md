# Ad System Implementation Guide

## Overview

This document describes the Duolingo-style ad system implemented in BravoBall. The system shows interstitial ads after session completions and every 3 app opens, with intelligent frequency controls to maintain a good user experience.

## 🎯 Ad Display Triggers

### 1. Session Completion Ads
- **Training Sessions**: Ad shows after user completes a training session and taps "Back to Home"
- **Mental Training Sessions**: Ad shows after user completes a mental training session and taps "Back to Home"

### 2. Drill Completion Ads (NEW)
- **Individual Drills**: Ad shows when user exits a completed drill via any exit button
- **Trigger**: User clicks "Exit Drill" (blue), "Completed!" (green), or close button (X) on a completed drill
- **NOT Triggered**: When drills auto-complete from finishing all sets
- **Frequency**: Subject to 3-minute minimum interval between ads

### 3. App Open Ads
- **Frequency**: Ad shows every 3rd app open (3rd, 6th, 9th, 12th, etc.)
- **Trigger**: App lifecycle changes (background → foreground)

## ⏰ Frequency Controls

### Minimum Time Between Ads
- **Setting**: 3 minutes (180 seconds)
- **Purpose**: Prevents overwhelming users with too many ads
- **Logic**: Even if multiple sessions are completed rapidly, ads won't show more frequently than every 3 minutes

### App Open Counter
- **Setting**: Every 3 app opens
- **Purpose**: Creates predictable ad rhythm
- **Logic**: Counter increments on each app resume, ad shows when count is divisible by 3

## 🏗️ Architecture

### Core Components

#### 1. AdService (`lib/services/ad_service.dart`)
- **Singleton service** managing all ad operations
- **Handles**: Ad loading, showing, frequency checks, timing logic
- **Key methods**:
  - `showAdAfterSession()` - Triggers ad after session completion
  - `showAdAfterMentalTraining()` - Triggers ad after mental training completion
  - `showAdOnAppOpenIfAppropriate()` - Checks and shows ad on app open

#### 2. AdConfig (`lib/config/ad_config.dart`)
- **Centralized configuration** for all ad settings
- **Easy to modify**: Frequency, timing, ad unit IDs, enable/disable flags
- **Environment aware**: Different IDs for debug vs production

#### 3. Integration Points
- **Session Completion**: `session_generator_home_field_view.dart`, `mental_training_timer_view.dart`
- **App Lifecycle**: `main.dart` with `WidgetsBindingObserver`
- **Ad Display**: Google Mobile Ads SDK integration

### Data Flow

```
User Action → Integration Point → AdService → Frequency Check → Ad Display
     ↓              ↓              ↓           ↓           ↓
Complete Session → onBackToHome → showAdAfterSession() → _canShowAdNow() → InterstitialAd.show()
Exit Completed Drill → onDrillCompleted → showAdAfterDrillCompletion() → _canShowAdNow() → InterstitialAd.show()
App Resume → didChangeAppLifecycleState → showAdOnAppOpenIfAppropriate() → shouldShowAdOnAppOpen() → Ad Display
```

## 🔧 Configuration

### AdConfig Settings

```dart
class AdConfig {
  // Frequency settings
  static const int adsAfterEveryNOpens = 3;        // Show ad every 3 app opens
  static const int minTimeBetweenAds = 180;        // 3 minutes between ads (seconds)
  
  // Enable/disable flags
  static bool get adsEnabled => true;              // Master switch for ads
  static bool get showAdsInDebugMode => true;      // Show test ads in development
  
  // Ad unit IDs (replace with your actual IDs for production)
  static const String androidProductionAdUnitId = 'YOUR_ANDROID_ID';
  static const String iosProductionAdUnitId = 'YOUR_IOS_ID';
}
```

### Platform Configuration

#### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="YOUR_ANDROID_APP_ID" />
```

#### iOS (`ios/Runner/Info.plist`)
```xml
<key>GADApplicationIdentifier</key>
<string>YOUR_IOS_APP_ID</string>
```

## 🧪 Testing

### Testing Session Completion Ads
1. Complete a training session → Tap "Back to Home" → Ad should show
2. Complete a mental training session → Tap "Back to Home" → Ad should show

### Testing Drill Completion Ads (NEW)
1. **Manual Completion Button**: Tap the complete button on play/pause button → Ad should show immediately
2. **Exit Button (Green)**: When drill is completed, tap "Completed!" button → Ad should show immediately
3. **Exit Button (Blue)**: When drill is NOT completed, tap "Exit Drill" button → NO ad should show
4. **Close Button (X)**: When drill is completed, tap X button → Ad should show immediately
5. **Auto-Completion**: Complete all sets of a drill → NO ad should show (auto-completion doesn't trigger ads)
6. **Frequency Check**: Manually exit multiple completed drills rapidly → Only first ad should show (3-minute rule)

### Testing App Open Ads
1. **Hot Restart Method** (Fastest for development):
   - Run app → First open (no ad)
   - Hot restart (⌘R) → Second open (no ad)
   - Hot restart (⌘R) → Third open → Ad should show ✅

2. **Background/Foreground Method** (More realistic):
   - Run app → First open (no ad)
   - Press home → App backgrounds
   - Return to app → Second open (no ad)
   - Press home → App backgrounds
   - Return to app → Third open → Ad should show ✅

### Testing Frequency Controls
1. Complete session → Ad shows ✅
2. Complete another session immediately → No ad (3-minute rule) ❌
3. Wait 3+ minutes → Complete session → Ad shows ✅

## 📊 Debug Logging

The system provides comprehensive logging in debug mode:

```
🚀 Initializing AdService...
✅ Google Mobile Ads SDK initialized
✅ Interstitial ad loaded successfully
📱 App resumed - checking for ads
📱 App open count: 0 → 1
📱 Should show ad? NO (every 3 opens)
⏰ Ad timing check:
   • Last ad shown: [timestamp]
   • Current time: [timestamp]
   • Time since last ad: X seconds
   • Min time required: 180 seconds
   • Can show ad? YES
📱 Showing interstitial ad (trigger: app_open)
```

## 🚨 Troubleshooting

### Common Issues

#### Ads Not Showing
1. **Check console logs** - Look for error messages
2. **Verify AdConfig.adsEnabled** - Ensure ads are not disabled
3. **Check ad unit IDs** - Verify IDs are correct for your platform
4. **Check frequency controls** - Ads might be blocked by timing rules

#### App Open Ads Not Working
1. **Verify lifecycle detection** - Check if `didChangeAppLifecycleState` is firing
2. **Check app open counter** - Look for "App open count" logs
3. **Verify timing** - Check if 3-minute rule is blocking ads

#### Test Ads Not Loading
1. **Check internet connection** - Test ads require network access
2. **Verify AdMob setup** - Ensure test app IDs are configured
3. **Check platform** - Different test IDs for Android vs iOS

### Debug Commands

```bash
# Check for compilation errors
flutter analyze

# Clean and rebuild
flutter clean
flutter pub get

# Run with verbose logging
flutter run --verbose
```

## 🔄 Maintenance

### Adding New Ad Triggers
1. **Import AdService** in the new file
2. **Call appropriate method**:
   ```dart
   await AdService.instance.showAdAfterSession();
   // or
   await AdService.instance.showAdAfterMentalTraining();
   // or
   await AdService.instance.showAdAfterDrillCompletion(); // NEW
   ```
3. **Test thoroughly** - Ensure ads show at the right time

### Modifying Frequency
1. **Update AdConfig**:
   ```dart
   static const int adsAfterEveryNOpens = 4;        // Change to every 4 opens
   static const int minTimeBetweenAds = 600;        // Change to 10 minutes
   ```
2. **Test changes** - Verify new frequency works as expected

### Production Deployment
1. **Replace test IDs** with your actual AdMob IDs
2. **Update AdConfig** with production ad unit IDs
3. **Test in release mode** - Ensure ads work in production builds
4. **Monitor performance** - Track ad fill rates and user engagement

## 📱 Production Considerations

### Performance
- **Ad loading** happens in background during user activity
- **Frequency controls** prevent performance impact from too many ads
- **Error handling** ensures app continues working even if ads fail

### User Experience
- **Predictable timing** - Users know when to expect ads
- **Natural placement** - Ads appear at completion points, not during gameplay
- **Frequency limits** - Prevents overwhelming users

### Monetization
- **Optimal frequency** - Balances user experience with revenue
- **Session-based** - Higher engagement when users complete activities
- **App open rhythm** - Consistent ad exposure without being intrusive

## 🤝 Team Collaboration

### For Developers
- **Read this document** before modifying ad-related code
- **Test changes** using the testing methods described above
- **Update documentation** when making significant changes

### For Product Managers
- **Understand frequency controls** - Know when and why ads appear
- **Monitor metrics** - Track ad performance and user engagement
- **Plan changes** - Coordinate ad frequency adjustments with development

### For QA Testers
- **Use testing methods** - Verify ads appear at correct times
- **Test edge cases** - Rapid session completion, app backgrounding
- **Report issues** - Document any unexpected ad behavior

---

## 📝 Change Log

- **Initial Implementation** - Duolingo-style ad system with session completion and app open triggers
- **Frequency Controls** - 3-minute minimum between ads, every 3 app opens
- **Drill Completion Ads** - NEW: Ads now show after completing individual drills
- **Debug Logging** - Comprehensive logging for troubleshooting
- **Documentation** - Complete implementation guide for team reference

---

*Last updated: [Current Date]*
*Maintained by: [Your Team]*
