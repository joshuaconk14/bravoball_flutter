# Premium Features System Documentation

## 🎯 Overview

The Premium Features System is a comprehensive subscription management solution that controls access to app features based on user subscription status. It implements a freemium model with clear upgrade paths and secure validation.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    PREMIUM SYSTEM                           │
├─────────────────────────────────────────────────────────────┤
│  Models → Service → Config → UI → Validation              │
│                                                             │
│  • Premium Models: Data structures & enums                 │
│  • Premium Service: Business logic & feature checks        │
│  • Premium Config: Limits, pricing, & triggers             │
│  • Upgrade Dialog: User conversion interface               │
│  • Server Validation: Backend verification                 │
└─────────────────────────────────────────────────────────────┘
```

## 📱 User Tiers & Limits

### Free Users
- **Daily Sessions**: 1 per day (resets at midnight)
- **Custom Drills**: 3 per month (resets monthly)
- **Features**: Basic drills, basic summaries
- **Ads**: Yes

### Trial Users (7 days)
- **Access**: All premium features
- **Duration**: 7 days from activation
- **Auto-expires**: Converts to free after trial

### Premium Users
- **Access**: Unlimited everything
- **Features**: No ads, advanced analytics, priority support
- **Duration**: Based on subscription plan

## 🔧 Core Components

### 1. Premium Models (`premium_models.dart`)

#### Key Enums
```dart
enum PremiumStatus { free, premium, trial, expired }
enum PremiumFeature { noAds, unlimitedDrills, unlimitedCustomDrills, ... }
enum SubscriptionPlan { monthly, yearly, lifetime }
```

#### Key Classes
- **`SubscriptionPlanDetails`**: Plan pricing, features, and metadata
- **`FreeFeatureUsage`**: Tracks remaining free features
- **`PremiumSubscription`**: User's subscription details
- **`PremiumUpgradePrompt`**: Upgrade dialog content

### 2. Premium Service (`premium_service.dart`)

#### Core Methods
```dart
// Check feature access
Future<bool> canAccessFeature(PremiumFeature feature)

// Check specific limits
Future<bool> canCreateCustomDrill()
Future<bool> canDoSessionToday()

// Track usage
Future<void> recordCustomDrillCreation()
Future<void> recordSessionCompletion()

// Get usage stats
Future<FreeFeatureUsage> getFreeFeatureUsage()
```

#### Security Features
- **Device Fingerprinting**: Prevents account sharing
- **Server Validation**: Backend verification every 5 minutes
- **Receipt Validation**: In-app purchase verification
- **Anti-tampering**: Device security checks

### 3. Premium Config (`premium_config.dart`)

#### Configuration Constants
```dart
// Free tier limits
static const int freeCustomDrillsPerMonth = 3;
static const int freeSessionsPerDay = 1;

// Pricing
static const double monthlyPrice = 15.0;
static const double yearlyPrice = 95.0; // 47% savings

// Trial
static const int trialDays = 7;
```

#### Subscription Plans
- **Monthly**: $15/month
- **Yearly**: $95/year (most popular, 47% savings)
- **Lifetime**: One-time payment (future implementation)

### 4. Upgrade Dialog (`premium_upgrade_dialog.dart`)

#### Features
- **Fullscreen Modal**: Immersive upgrade experience
- **Plan Comparison**: Visual plan selection
- **Feature Highlighting**: Clear value proposition
- **Trial Promotion**: 7-day free trial offer
- **Responsive Design**: Works on all screen sizes

## 🚀 Implementation Patterns

### Feature Access Check
```dart
// In any widget/service
final premiumService = PremiumService.instance;

// Check if user can access feature
if (await premiumService.canAccessFeature(PremiumFeature.unlimitedDrills)) {
  // Allow access
} else {
  // Show upgrade prompt
  showPremiumUpgradeDialog(context, trigger: 'premium_feature_accessed');
}
```

### Limit Tracking
```dart
// Before allowing action
if (await premiumService.canCreateCustomDrill()) {
  // Create drill
  await drillService.createDrill(drillData);
  // Record usage
  await premiumService.recordCustomDrillCreation();
} else {
  // Show limit reached message
  showLimitReachedDialog(context);
}
```

### Upgrade Dialog Trigger
```dart
// Show upgrade dialog with specific trigger
showPremiumUpgradeDialog(
  context,
  title: 'Unlock Unlimited Drills',
  description: 'Create as many custom drills as you want',
  trigger: 'monthly_custom_drill_limit_reached',
  onUpgrade: () => _handleUpgrade(),
  onDismiss: () => Navigator.pop(context),
);
```

## 🔒 Security Implementation

### Device Fingerprinting
```dart
// Generates unique device identifier
final deviceFingerprint = await _getDeviceFingerprint();
// Uses device info + SHA256 hash
// Stored securely in SharedPreferences
```

### Server Validation
```dart
// Validates premium status every 5 minutes
POST /validate-premium
Headers: Authorization, Device-Fingerprint, App-Version
Body: { timestamp, device_id }
```

### Anti-Tampering
```dart
// Checks device security before allowing premium
if (await DeviceSecurityUtils.isDeviceCompromised()) {
  _cachedStatus = PremiumStatus.free;
  return;
}
```

## 📊 Usage Analytics

### Tracked Metrics
- **Feature Access Attempts**: When users try premium features
- **Upgrade Dialog Views**: How many see upgrade prompts
- **Conversion Rates**: Free to premium conversion
- **Usage Patterns**: Most accessed premium features

### Analytics Implementation
```dart
// Premium analytics data
class PremiumAnalytics {
  final int totalSessions;
  final int totalCustomDrills;
  final double averageSessionDuration;
  final Map<String, int> monthlyProgress;
}
```

## 🧪 Testing & Development

### Debug Features
```dart
// Enable mock premium for testing
static const bool enableMockPremium = false;

// Force premium status refresh
await premiumService.forceRefresh();

// Clear cached data
await premiumService.clearCache();
```

### Testing Scenarios
1. **Free User Limits**: Verify daily/monthly restrictions
2. **Upgrade Flow**: Test purchase and status update
3. **Trial Expiration**: Verify auto-conversion to free
4. **Security**: Test device fingerprinting and validation

## 🔄 Integration Points

### Authentication Service
```dart
// Premium status tied to user account
final authToken = await _getAuthToken();
// Premium validation includes user authentication
```

### Ad Service
```dart
// Ads shown based on premium status
if (await premiumService.canAccessFeature(PremiumFeature.noAds)) {
  // No ads shown
} else {
  // Show ads after manual drill completion, session completion, etc.
  await AdService.instance.showAdAfterDrillCompletion();
}
```

### Drill Services
```dart
// Custom drill creation limited for free users
if (await premiumService.canCreateCustomDrill()) {
  // Allow creation
} else {
  // Show upgrade prompt
}
```

## 📈 Performance Optimizations

### Caching Strategy
- **Premium Status**: Cached for 5 minutes
- **Feature Checks**: Local validation when possible
- **Server Calls**: Only when cache expires
- **Background Sync**: Non-blocking validation

### Memory Management
- **Singleton Pattern**: Single service instance
- **Lazy Loading**: Load data only when needed
- **Efficient Storage**: Minimal SharedPreferences usage

## 🚨 Common Issues & Solutions

### Issue: Premium status not updating
```dart
// Solution: Force refresh
await premiumService.forceRefresh();

// Check server validation
if (PremiumConfig.shouldEnableServerValidation) {
  await premiumService._validateWithServer();
}
```

### Issue: Free limits not working
```dart
// Solution: Check SharedPreferences keys
final monthKey = 'custom_drills_${currentYear}_${currentMonth}';
final drillsThisMonth = prefs.getInt(monthKey) ?? 0;
```

### Issue: Upgrade dialog not showing
```dart
// Solution: Verify trigger and context
showPremiumUpgradeDialog(
  context,
  trigger: 'specific_trigger_name',
);
```

## 🔮 Future Enhancements

### Planned Features
- **Lifetime Plan**: One-time payment option
- **Family Sharing**: Multiple devices per subscription
- **Gift Subscriptions**: Purchase for others
- **Referral Program**: Earn premium time
- **Advanced Analytics**: Detailed progress insights

### Technical Improvements
- **Offline Support**: Premium status when offline
- **Push Notifications**: Trial expiration reminders
- **A/B Testing**: Different upgrade prompts
- **Machine Learning**: Personalized upgrade timing

## 📚 Related Documentation

- **Authentication System**: User management and login
- **Ad System**: Ad display and revenue
- **State Management**: App-wide state coordination
- **Security Patterns**: Data protection and validation

---

**Last Updated**: August 2025  
**Maintainer**: Development Team  
**Version**: 2.1.0
