# BravoBall Flutter - Deployment Guide

## Overview
This guide covers deploying BravoBall Flutter (v2.0.0+20) to both App Store and Google Play Store.

## Prerequisites

### Development Environment
- Flutter SDK (latest stable)
- Xcode (for iOS deployment)
- Android Studio (for Android deployment)
- Valid Apple Developer Account ($99/year)
- Google Play Console Account ($25 one-time fee)

### App Configuration
✅ Bundle ID updated to match existing Swift app: `ConklinOfficial.BravoBall`
✅ Version configured: 2.0.0 (Build 20)
✅ Android signing configuration set up
✅ iOS versioning properly configured

---

## iOS App Store Deployment

### 1. App Store Connect Setup
Since you already have the Swift version published:

1. **Navigate to App Store Connect**
   - Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
   - Select your existing BravoBall app

2. **Create New Version**
   - Click "+" next to iOS App
   - Select "2.0.0" as the new version number
   - This will be your Flutter version replacing the Swift version

### 2. Build Configuration
The project is already configured with:
- Bundle ID: `ConklinOfficial.BravoBall` (matches your existing app)
- Development Team: `J36CXA7LCG`
- Version: Uses `$(FLUTTER_BUILD_NAME)` and `$(FLUTTER_BUILD_NUMBER)`

### 3. Build for App Store

```bash
# Navigate to project directory
cd bravoball_flutter

# Clean previous builds
flutter clean
flutter pub get

# Build iOS release
flutter build ios --release --no-codesign

# Open in Xcode for signing and upload
open ios/Runner.xcworkspace
```

### 4. In Xcode
1. Select "Runner" scheme
2. Select "Any iOS Device (arm64)"
3. Product → Archive
4. Distribute App → App Store Connect
5. Upload

### 5. App Store Connect Submission
1. Fill out app information for v2.0.0
2. Upload screenshots (required: 6.7", 6.5", 5.5", 12.9")
3. Add release notes mentioning it's a complete Flutter rewrite
4. Submit for review

---

## Google Play Store Deployment

### 1. Google Play Console Setup
Since this is your first Android release:

1. **Create Google Play Console Account**
   - Go to [play.google.com/console](https://play.google.com/console)
   - Pay $25 one-time registration fee

2. **Create New App**
   - Click "Create app"
   - App name: "BravoBall"
   - Default language: English (US)
   - App type: App
   - Free or paid: (your choice)

### 2. Android Signing Setup

#### Generate Upload Keystore
```bash
# Navigate to android/app directory
cd bravoball_flutter/android/app

# Generate keystore (do this once)
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias bravoball-upload-key
```

#### Configure Key Properties
Update `android/key.properties` with your actual values:
```properties
storePassword=your_actual_keystore_password
keyPassword=your_actual_key_password
keyAlias=bravoball-upload-key
storeFile=../app/upload-keystore.jks
```

### 3. Build Android App Bundle

```bash
# Clean and build
flutter clean
flutter pub get

# Build release AAB
flutter build appbundle --release

# AAB file will be at: build/app/outputs/bundle/release/app-release.aab
```

### 4. Upload to Google Play Console

1. **Upload App Bundle**
   - Go to Release → Production
   - Create new release
   - Upload `app-release.aab`

2. **Complete Store Listing**
   - App details (description, screenshots)
   - Content rating questionnaire
   - Target audience and content
   - Privacy policy (required)

3. **Release**
   - Review and rollout to production

---

## Important Notes

### Version Management
- **Current Setup**: v2.0.0+20
- **Next Release**: Increment build number (+21, +22, etc.)
- **Major Updates**: Increment version (2.1.0, 3.0.0, etc.)

### Bundle Identifier Consistency
- iOS: `ConklinOfficial.BravoBall` (matches existing Swift app)
- Android: `com.bravoball.app.bravoball_flutter` (new package)

### Required Assets

#### App Icons
Current configuration uses default Flutter icons. Update:
- iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- Android: `android/app/src/main/res/mipmap-*/ic_launcher.png`

#### Screenshots Needed
- **iOS**: 6.7", 6.5", 5.5", 12.9" (multiple per size)
- **Android**: Phone, 7" tablet, 10" tablet

### Privacy & Permissions
Both stores configured with permissions for:
- Internet access
- Media access (camera, photos)
- Background audio
- Notifications
- Wake lock

---

## Testing Before Release

### iOS TestFlight
1. Upload beta build to TestFlight
2. Add internal testers
3. Test all functionality

### Android Internal Testing
1. Upload to Internal Testing track
2. Add test users
3. Test all functionality

---

## Post-Release Monitoring

### App Store Connect
- Monitor crash reports
- Review user feedback
- Track download analytics

### Google Play Console
- Monitor ANRs and crashes
- Review user ratings
- Track installation metrics

---

## Troubleshooting

### Common iOS Issues
- **Code signing errors**: Check development team and provisioning profiles
- **Build failures**: Clean derived data, restart Xcode
- **Archive issues**: Ensure "Any iOS Device" is selected

### Common Android Issues
- **Signing errors**: Verify key.properties path and credentials
- **Build failures**: Check Android SDK versions
- **Upload errors**: Ensure AAB format, not APK

### Support Resources
- [Flutter deployment docs](https://flutter.dev/docs/deployment)
- [App Store Connect Help](https://developer.apple.com/app-store-connect/)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer/)

---

## Quick Commands Reference

```bash
# iOS Release Build
flutter build ios --release --no-codesign

# Android Release Build  
flutter build appbundle --release

# Clean project
flutter clean && flutter pub get

# Check Flutter setup
flutter doctor -v
``` 