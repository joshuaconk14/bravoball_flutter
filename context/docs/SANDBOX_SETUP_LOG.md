# Sandbox Testing Setup Log

**Date:** August 24, 2025  
**Status:** ❌ Unsuccessful - Products not loading in sandbox

## Setup Attempt Summary

### ✅ What's Working:
- App connects to local backend (`http://192.168.1.101:8000`)
- Environment detection correctly identifies sandbox mode
- PurchaseService initializes successfully
- Sandbox Apple ID configured (`joshuaconk7@gmail.com`)

### ❌ What's Not Working:
- Products not loading from App Store Connect
- Getting "Some products not found: [bravoball_monthly_premium, bravoball_yearly_premium]"
- Apple Pay not appearing due to no available products

## Configuration Variables

### Key Variables to Change:

#### 1. Mock Purchases (Quick Testing)
```dart
// lib/config/purchase_config.dart
static const bool enableMockPurchases = true; // Enable for testing
```

#### 2. Environment Detection
```dart
// lib/config/purchase_config.dart
static bool get isSandboxEnvironment => !isProductionBuild;
static bool get isProductionBuild => !kDebugMode;
```

#### 3. Product IDs
```dart
// lib/config/purchase_config.dart
static const String monthlyPremiumId = 'bravoball_monthly_premium';
static const String yearlyPremiumId = 'bravoball_yearly_premium';
```

#### 4. Debug Mode
```dart
// lib/config/app_config.dart
static const bool debug = true; // Set to false for production
static const bool useLocalStoreKit = true; // Set to false for production
```

// backend
.env
REVENUECAT_ALLOW_SIMULATOR_BYPASS=true // Set to false for production


## Current Status

**Products in App Store Connect:**
- Status: "Ready to Submit" 
- Product IDs: `bravoball_monthly_premium`, `bravoball_yearly_premium`
- Type: Auto-Renewable Subscriptions

**Sandbox Account:**
- Email: `joshuaconk7@gmail.com`
- Status: Active
- Subscription Renewal: Every 5 minutes (for testing)

## Next Steps

1. **Wait 15-30 minutes** for products to become available in sandbox
2. **Verify bundle ID** matches between Xcode and App Store Connect
3. **Check product association** with app in App Store Connect
4. **Temporarily enable mock purchases** to test app logic

## Quick Test Commands

```bash
# Rebuild with changes
flutter clean && flutter pub get && cd ios && pod install && cd .. && flutter install

# Check logs
flutter logs
```
