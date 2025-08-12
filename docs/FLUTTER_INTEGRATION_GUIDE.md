# BravoBall Flutter App - Backend Integration Guide

## 🎯 Overview
This document shows the exact data models and API calls that the Flutter app makes to the backend. Use this to ensure your backend responses match what the app expects.

## 📱 Flutter Models (What the App Expects)

### PremiumStatus Enum
```dart
enum PremiumStatus {
  free,      // User has no premium subscription
  premium,   // User has active premium subscription
  trial,     // User is in trial period
  expired    // User's premium subscription has expired
}
```

### SubscriptionPlan Enum
```dart
enum SubscriptionPlan {
  monthly,   // Monthly subscription ($15/month)
  yearly,    // Yearly subscription ($95/year)
  lifetime   // One-time payment (not implemented yet)
}
```

### PremiumFeature Enum
```dart
enum PremiumFeature {
  noAds,                    // No advertisements
  unlimitedDrills,          // Access to all drill types
  unlimitedCustomDrills,    // Create unlimited custom drills
  unlimitedSessions,        // No daily session limit
  advancedAnalytics,        // Detailed progress tracking
  basicDrills,              // Access to basic drill library
  weeklySummaries,          // Weekly performance summaries
  monthlySummaries          // Monthly performance summaries
}
```

## 🔑 Key API Endpoints the App Calls

### 1. Premium Status Check
**App calls**: `PremiumService.instance.getPremiumStatus()`

**Expected Backend Response**:
```json
{
  "success": true,
  "data": {
    "status": "premium",
    "plan": "yearly",
    "startDate": "2024-01-15T00:00:00Z",
    "endDate": "2025-01-15T00:00:00Z",
    "trialEndDate": null,
    "isActive": true,
    "features": [
      "noAds",
      "unlimitedDrills", 
      "unlimitedCustomDrills",
      "unlimitedSessions",
      "advancedAnalytics"
    ]
  }
}
```

### 2. Feature Access Check
**App calls**: `PremiumService.instance.canAccessFeature(PremiumFeature.unlimitedCustomDrills)`

**Expected Backend Response**:
```json
{
  "success": true,
  "data": {
    "canAccess": true,
    "feature": "unlimitedCustomDrills",
    "remainingUses": null,  // null for unlimited
    "limit": "unlimited"
  }
}
```

### 3. Usage Tracking
**App calls**: `PremiumService.instance.recordCustomDrillCreation()`

**App sends to backend**:
```json
{
  "featureType": "custom_drill",
  "usageDate": "2024-01-15",
  "metadata": {
    "drillType": "passing",
    "difficulty": "intermediate"
  }
}
```

## 📊 Data Structures the App Uses

### SubscriptionPlanDetails
```dart
class SubscriptionPlanDetails {
  final SubscriptionPlan plan;           // monthly, yearly, lifetime
  final String name;                     // "Monthly Premium", "Yearly Premium"
  final double price;                    // 15.0, 95.0
  final String currency;                 // "USD"
  final int durationDays;                // 30, 365
  final String? description;            // "Best value - Save 47% compared to monthly"
  final List<String> features;          // ["No ads", "Unlimited drills", ...]
  final bool isPopular;                  // true for yearly plan
  final double? originalPrice;          // 180.0 for yearly (shows savings)
}
```

### FreeFeatureUsage
```dart
class FreeFeatureUsage {
  final int customDrillsRemaining;       // 2 (out of 3 per month)
  final int sessionsRemaining;           // 0 (out of 1 per day)
  final int customDrillsUsed;            // 1 (used this month)
  final int sessionsUsed;                // 1 (used today)
}
```

### PremiumSubscription
```dart
class PremiumSubscription {
  final String id;                       // Unique subscription ID
  final PremiumStatus status;            // premium, trial, expired
  final SubscriptionPlan plan;           // monthly, yearly
  final DateTime startDate;              // When subscription started
  final DateTime? endDate;               // When it expires
  final DateTime? trialEndDate;          // When trial ends
  final bool isActive;                   // Is subscription currently active
  final bool isTrial;                    // Is user in trial period
  final String? platform;                // "ios", "android", "web"
  final String? receiptData;             // Receipt for validation
}
```

## 🔐 Authentication Headers the App Sends

### Every Premium API Call Includes:
```http
Authorization: Bearer <jwt_token>
Device-Fingerprint: <device_hash>
App-Version: <app_version>
Content-Type: application/json
```

### Device Fingerprint Format:
```dart
// Generated from device info + app info
final deviceInfo = await DeviceSecurityUtils.getDeviceInfo();
final appInfo = await DeviceSecurityUtils.getAppInfo();
final fingerprint = sha256.convert(utf8.encode('$deviceInfo|$appInfo')).toString();
```

## 📱 App Behavior Based on Premium Status

### Free Users (PremiumStatus.free)
- **Custom Drills**: Limited to 3 per month
- **Sessions**: Limited to 1 per day
- **Ads**: Shown after sessions and app opens
- **Features**: Basic drills, basic summaries

### Premium Users (PremiumStatus.premium)
- **Custom Drills**: Unlimited
- **Sessions**: Unlimited per day
- **Ads**: None
- **Features**: All premium features unlocked

### Trial Users (PremiumStatus.trial)
- **Access**: Same as premium users
- **Duration**: 7 days (configurable)
- **Conversion**: Must upgrade before trial ends

## 🚨 Important Notes for Backend

### 1. Status Validation Frequency
- App validates premium status every 5 minutes
- Backend should cache responses to avoid excessive API calls
- Implement rate limiting: max 5 validation requests per minute per user

### 2. Feature Access Logic
```dart
// App checks feature access like this:
switch (feature) {
  case PremiumFeature.noAds:
    return status == PremiumStatus.premium;
  case PremiumFeature.unlimitedCustomDrills:
    return status == PremiumStatus.premium;
  case PremiumFeature.basicDrills:
    return true; // Free users can access
}
```

### 3. Usage Limits
- **Custom Drills**: Reset monthly (1st of each month)
- **Sessions**: Reset daily (midnight local time)
- **Track both**: Used count AND remaining count

### 4. Error Handling
- App expects `success: true/false` in all responses
- App handles network errors gracefully
- App falls back to cached status on server errors

## 🔍 Testing the Integration

### 1. Test Premium Status Changes
```bash
# Set user to premium
curl -X POST /api/premium/test/set-status \
  -H "Authorization: Bearer <token>" \
  -d '{"status": "premium", "plan": "yearly"}'

# Check status
curl -X GET /api/premium/status \
  -H "Authorization: Bearer <token>"
```

### 2. Test Feature Access
```bash
# Check if user can create custom drill
curl -X POST /api/premium/check-feature \
  -H "Authorization: Bearer <token>" \
  -d '{"feature": "unlimitedCustomDrills"}'
```

### 3. Test Usage Tracking
```bash
# Record custom drill creation
curl -X POST /api/premium/track-usage \
  -H "Authorization: Bearer <token>" \
  -d '{"featureType": "custom_drill", "usageDate": "2024-01-15"}'
```

## 📞 Integration Checklist

- [ ] Implement all required API endpoints
- [ ] Match response format exactly
- [ ] Handle authentication properly
- [ ] Implement device fingerprinting
- [ ] Set up proper error responses
- [ ] Test with Flutter app
- [ ] Monitor API performance
- [ ] Set up logging and monitoring

## 🚀 Next Steps

1. **Review this guide** with your backend team
2. **Implement the API endpoints** as specified
3. **Test the integration** using the test endpoints
4. **Deploy to staging** and test with Flutter app
5. **Go live** with production backend

---

**Questions?** Contact the Flutter development team for clarification on any of these specifications.
