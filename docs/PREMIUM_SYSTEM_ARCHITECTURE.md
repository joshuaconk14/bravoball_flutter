# Premium System Architecture

## Overview

This document explains the premium subscription system implementation in BravoBall. The system uses RevenueCat for subscription management and follows a simple, reliable architecture that ensures premium features work correctly across devices and user sessions.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Design Decisions](#design-decisions)
3. [Core Components](#core-components)
4. [User Identification Strategy](#user-identification-strategy)
5. [Premium Access Checking](#premium-access-checking)
6. [Subscription Management](#subscription-management)
7. [Implementation Examples](#implementation-examples)
8. [Best Practices](#best-practices)
9. [Troubleshooting](#troubleshooting)

## Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   User Login    │───▶│   RevenueCat     │───▶│  Premium Utils  │
│   Registration  │    │   Identification │    │  Access Check   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │   App Features   │
                       │   (Premium/Free) │
                       └──────────────────┘
```

### Key Principles

1. **User-Centric**: Premium access is tied to user accounts, not devices
2. **Cross-Device**: Subscriptions work across all user's devices
3. **Simple**: Minimal complexity for maximum reliability
4. **RevenueCat-First**: Leverages RevenueCat's robust infrastructure

## Design Decisions

### Why RevenueCat?

- **Reliable**: Handles subscription state management across platforms
- **Cross-Platform**: Works on iOS, Android, and web
- **User Management**: Proper user identification prevents subscription sharing
- **Entitlements**: Flexible feature access control
- **Analytics**: Built-in subscription analytics and insights

### Why User Identification?

- **Prevents Sharing**: Subscriptions are tied to user accounts, not devices
- **Cross-Device Access**: Users can access premium features on any device
- **Proper Billing**: Ensures correct subscription attribution
- **Security**: Prevents unauthorized access to premium features

### Why Simple Architecture?

- **Maintainability**: Easy to understand and modify
- **Reliability**: Fewer moving parts = fewer failure points
- **Performance**: Direct RevenueCat calls are fast
- **Debugging**: Clear error paths and logging

## Core Components

### 1. PremiumUtils (`lib/utils/premium_utils.dart`)

The central utility class for all premium access checks.

```dart
class PremiumUtils {
  /// Main method for checking premium access
  static Future<bool> hasPremiumAccess() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.isNotEmpty;
    } catch (e) {
      print('❌ Error checking premium status: $e');
      return false; // Fail-safe: no premium access on error
    }
  }
}
```

**Key Features:**
- Single source of truth for premium status
- Fail-safe design (assumes no premium on error)
- Comprehensive debug logging
- Async/await pattern for reliability

### 2. User Identification System

RevenueCat user identification is handled at key user lifecycle points:

#### Login (`lib/services/login_service.dart`)
```dart
// Identify user with RevenueCat after successful login
await Purchases.logIn(loginResponse.email);
```

#### Registration (`lib/services/onboarding_service.dart`)
```dart
// Identify new user with RevenueCat after registration
await Purchases.logIn(email);
```

#### Logout (`lib/services/login_service.dart`)
```dart
// Reset RevenueCat user to prevent subscription sharing
await Purchases.logOut();
```

#### Guest Mode (`lib/services/user_manager_service.dart`)
```dart
// Reset RevenueCat user when entering guest mode
await Purchases.logOut();
```

### 3. Premium Page (`lib/features/premium/premium_page.dart`)

Simplified subscription purchase flow with direct RevenueCat integration.

```dart
Future<void> _purchaseProduct(String productId, String planName) async {
  try {
    final purchaseResult = await Purchases.purchaseProduct(productId);
    // Handle success/failure
  } catch (e) {
    // Handle errors
  }
}
```

## User Identification Strategy

### The Problem

Without proper user identification, subscriptions can be shared between different user accounts on the same device, leading to:
- Unauthorized access to premium features
- Incorrect billing attribution
- Poor user experience

### The Solution

**RevenueCat User Identification Flow:**

1. **App Launch**: RevenueCat starts with anonymous user
2. **User Login**: `Purchases.logIn(userEmail)` identifies user
3. **User Logout**: `Purchases.logOut()` resets to anonymous
4. **Guest Mode**: `Purchases.logOut()` prevents subscription sharing

### Implementation Points

```dart
// ✅ CORRECT: Identify user after login
await Purchases.logIn(userEmail);

// ✅ CORRECT: Reset user on logout
await Purchases.logOut();

// ✅ CORRECT: Reset user in guest mode
await Purchases.logOut();
```

## Premium Access Checking

### Simple Pattern

```dart
// Check premium access before showing premium features
final hasPremium = await PremiumUtils.hasPremiumAccess();
if (hasPremium) {
  // Show premium feature
} else {
  // Show upgrade prompt or free alternative
}
```

### In Widgets

```dart
FutureBuilder<bool>(
  future: PremiumUtils.hasPremiumAccess(),
  builder: (context, snapshot) {
    final hasPremium = snapshot.data ?? false;
    return hasPremium ? PremiumWidget() : FreeWidget();
  },
)
```

### In Services

```dart
class AdService {
  Future<void> showAd() async {
    final hasPremium = await PremiumUtils.hasPremiumAccess();
    if (!hasPremium) {
      // Show ad for free users
    }
  }
}
```

## Subscription Management

### Purchase Flow

1. User taps subscription button
2. `Purchases.purchaseProduct()` called
3. RevenueCat handles purchase with App Store
4. User gets premium access immediately
5. Subscription status synced across devices

### Account Deletion

When users delete their account:

1. **Subscription Warning**: Show warning if user has active subscription
2. **Manual Cancellation**: User must cancel subscription manually
3. **Account Deletion**: Proceed with account deletion
4. **RevenueCat Reset**: `Purchases.logOut()` called

**Why Manual Cancellation?**
- App Store policy requires manual subscription management
- Prevents accidental subscription loss
- Gives users control over their billing

## Implementation Examples

### 1. Premium Feature Gating

```dart
class CustomDrillCreation {
  Future<void> createDrill() async {
    final hasPremium = await PremiumUtils.hasPremiumAccess();
    if (!hasPremium) {
      _showUpgradePrompt();
      return;
    }
    
    // Proceed with premium feature
    _createCustomDrill();
  }
}
```

### 2. Ad Display Logic

```dart
class AdService {
  Future<void> showInterstitialAd() async {
    final hasPremium = await PremiumUtils.hasPremiumAccess();
    if (!hasPremium) {
      _displayAd();
    }
    // Premium users see no ads
  }
}
```

### 3. UI Conditional Rendering

```dart
Widget build(BuildContext context) {
  return FutureBuilder<bool>(
    future: PremiumUtils.hasPremiumAccess(),
    builder: (context, snapshot) {
      final hasPremium = snapshot.data ?? false;
      
      return Column(
        children: [
          if (hasPremium) PremiumFeatureWidget(),
          if (!hasPremium) UpgradePromptWidget(),
        ],
      );
    },
  );
}
```

## Best Practices

### 1. Always Use PremiumUtils

```dart
// ✅ GOOD: Use centralized utility
final hasPremium = await PremiumUtils.hasPremiumAccess();

// ❌ BAD: Direct RevenueCat calls
final customerInfo = await Purchases.getCustomerInfo();
final hasPremium = customerInfo.entitlements.active.isNotEmpty;
```

### 2. Handle Errors Gracefully

```dart
// ✅ GOOD: Fail-safe approach
try {
  final hasPremium = await PremiumUtils.hasPremiumAccess();
  return hasPremium;
} catch (e) {
  // Assume no premium access on error
  return false;
}
```

### 3. Use FutureBuilder for UI

```dart
// ✅ GOOD: Proper async UI handling
FutureBuilder<bool>(
  future: PremiumUtils.hasPremiumAccess(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return LoadingWidget();
    }
    final hasPremium = snapshot.data ?? false;
    return hasPremium ? PremiumWidget() : FreeWidget();
  },
)
```

### 4. Identify Users Properly

```dart
// ✅ GOOD: Identify user after login
await Purchases.logIn(userEmail);

// ✅ GOOD: Reset user on logout
await Purchases.logOut();
```

### 5. Debug Logging

```dart
// ✅ GOOD: Comprehensive logging
if (kDebugMode) {
  print('🔍 Premium Check Debug:');
  print('   User ID: ${customerInfo.originalAppUserId}');
  print('   Active Entitlements: ${customerInfo.entitlements.active.keys}');
}
```

## Troubleshooting

### Common Issues

#### 1. New Users Getting Premium Access

**Problem**: New users automatically get premium features
**Cause**: RevenueCat not properly identifying users
**Solution**: Ensure `Purchases.logIn()` is called after registration

#### 2. Subscriptions Shared Between Users

**Problem**: Different users share subscriptions on same device
**Cause**: RevenueCat user not reset on logout
**Solution**: Call `Purchases.logOut()` on logout and guest mode

#### 3. Premium Status Not Updating

**Problem**: Premium status doesn't update after purchase
**Cause**: Not checking latest customer info
**Solution**: Use `PremiumUtils.hasPremiumAccess()` which gets fresh data

#### 4. Purchase Errors

**Problem**: "Product not found" errors
**Cause**: Products not configured in App Store Connect
**Solution**: Verify product IDs match App Store Connect configuration

### Debug Commands

```dart
// Check current RevenueCat user identity
await PremiumUtils.debugUserIdentity();

// Get detailed customer info
final customerInfo = await PremiumUtils.getCustomerInfo();

// Check active entitlements
final entitlements = await PremiumUtils.getActiveEntitlements();
```

### Testing

1. **Test User Identification**: Login/logout with different users
2. **Test Cross-Device**: Purchase on one device, check on another
3. **Test Guest Mode**: Ensure no subscription sharing
4. **Test Error Handling**: Simulate network errors
5. **Test Purchase Flow**: Complete purchase and verify access

## File Structure

```
lib/
├── utils/
│   └── premium_utils.dart          # Core premium utilities
├── features/
│   └── premium/
│       └── premium_page.dart       # Subscription purchase UI
├── services/
│   ├── login_service.dart          # User identification on login
│   ├── onboarding_service.dart     # User identification on registration
│   └── user_manager_service.dart   # User identification on guest mode
└── config/
    └── app_config.dart             # RevenueCat configuration
```

## Conclusion

This premium system architecture prioritizes simplicity, reliability, and user experience. By using RevenueCat for subscription management and implementing proper user identification, we ensure that premium features work correctly across all devices while preventing unauthorized access.

The key to success is consistent user identification at all user lifecycle points and using the centralized `PremiumUtils` class for all premium access checks.
