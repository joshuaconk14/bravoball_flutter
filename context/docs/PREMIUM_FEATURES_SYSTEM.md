# Premium Features System Documentation

## 🎯 Overview

The Premium Features System is a **simplified, unified subscription management solution** that controls access to app features based on user subscription status. It implements a freemium model with a **single source of truth** approach, eliminating complex trigger-specific dialogs in favor of consistent navigation to a unified `PremiumPage`.

**Last Major Refactor**: August 14, 2025 - Complete system simplification

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    PREMIUM SYSTEM                           │
├─────────────────────────────────────────────────────────────┤
│  Models → Service → Config → UI → Backend                 │
│                                                             │
│  • Premium Models: Data structures & enums                 │
│  • Premium Service: Backend feature checks                 │
│  • Premium Config: Limits, pricing & validation           │
│  • PremiumPage: Single unified upgrade interface           │
│  • Backend Integration: Direct API calls for limits        │
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
- **`FreeFeatureUsage`**: Tracks remaining free features from backend
- **`PremiumSubscription`**: User's subscription details
- **`PremiumAnalytics`**: Usage tracking and insights

### 2. Premium Service (`premium_service.dart`)

#### Core Methods
```dart
// Check feature access via backend
Future<bool> canAccessFeature(PremiumFeature feature)

// Check specific limits
Future<bool> canCreateCustomDrill()
Future<bool> canDoSessionToday()

// Get usage stats from backend
Future<FreeFeatureUsage> getFreeFeatureUsage()

// NOTE: Usage tracking now handled by backend database checks
// recordCustomDrillCreation() and recordSessionCompletion() deprecated
```

#### Backend Integration
- **Feature Checks**: POST to `/api/premium/check-feature`
- **Usage Stats**: GET from `/api/premium/usage-stats`
- **Response Parsing**: Handles nested `data` field structure
- **Fallback Logic**: Local validation when backend unavailable

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

#### Preserved for Future Use
- **Receipt Validation**: Caching and retry settings
- **Analytics**: Usage tracking and conversion monitoring
- **Security**: Device validation and anti-tampering

### 4. PremiumPage (`features/premium/premium_page.dart`)

#### Features
- **Single Unified Interface**: Consistent experience everywhere
- **Consistent Content**: Same header, features, and plans regardless of entry point
- **Plan Selection**: Monthly and yearly subscription options
- **Trial Promotion**: 7-day free trial offer
- **Navigation-Based**: Full page instead of modal dialog

## 🚀 Implementation Patterns

### Feature Access Check
```dart
// In any widget/service
final premiumService = PremiumService.instance;

// Check if user can access feature
if (await premiumService.canAccessFeature(PremiumFeature.unlimitedDrills)) {
  // Allow access
} else {
  // Navigate to unified premium page
  Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => const PremiumPage()),
  );
}
```

### Session Limit Check
```dart
// Check if user can start new session today
if (!await appState.canStartNewSession()) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => const PremiumPage()),
  );
}
```

### Custom Drill Limit Check
```dart
// Check if user can create custom drill
if (!await premiumService.canAccessFeature(PremiumFeature.unlimitedCustomDrills)) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => const PremiumPage()),
  );
}
```

## 🔒 Backend Integration

### Feature Access Endpoint
```dart
// POST /api/premium/check-feature
// Request body: { "feature": "unlimitedSessions" }
// Response structure:
{
  "success": true,
  "data": {
    "canAccess": true/false,
    "feature": "unlimitedSessions",
    "remainingUses": 0,
    "limit": "1 per day"
  }
}
```

### Usage Statistics Endpoint
```dart
// GET /api/premium/usage-stats
// Response structure:
{
  "success": true,
  "data": {
    "customDrillsRemaining": 2,
    "sessionsRemaining": 0,
    "customDrillsUsed": 1,
    "sessionsUsed": 1,
    "isPremium": false
  }
}
```

### Backend Logic
- **Session Limits**: Check `completedSession` creation dates for today
- **Custom Drill Limits**: Check `customDrill` creation dates for current month
- **No UsageTracking Model**: Direct database queries for efficiency

## 📊 Premium Page Implementation

### Navigation Points
1. **Custom Drill Limit**: Yellow plus button on bottom toolbar
2. **Session Limit**: Backpack, mental training, or drill buttons
3. **Profile Upgrade**: "Upgrade to Premium" button in profile

### Consistent Content
- **Header**: Star icon, "Upgrade to Premium" title, unified description
- **Features**: Same premium features list everywhere
- **Plans**: Monthly ($15) and Yearly ($95) options
- **Trial**: 7-day free trial offer
- **Button**: "Continue with [Selected Plan]"

## 🧪 Testing & Development

### Test Scenarios
1. **Free User Hits Session Limit**
   - Complete one session
   - Try to start another session
   - Should navigate to PremiumPage

2. **Free User Hits Custom Drill Limit**
   - Create 3 custom drills in a month
   - Try to create another drill
   - Should navigate to PremiumPage

3. **Profile Upgrade Button**
   - Navigate to profile
   - Tap "Upgrade to Premium"
   - Should navigate to PremiumPage

4. **Premium User Access**
   - Premium users should never see upgrade prompts
   - All features should be accessible

### Backend Integration Testing
- Verify `/api/premium/check-feature` returns correct `canAccess` values
- Test with both free and premium user accounts
- Confirm response parsing handles nested `data` field correctly

## 🔄 Integration Points

### AppStateService
```dart
// Centralized session limit checking
Future<bool> canStartNewSession() async {
  final response = await _apiService.post('/api/premium/check-feature', ...);
  return response.data!['data']['canAccess'] ?? false;
}
```

### PremiumService
```dart
// Backend-first feature access checking
Future<bool> canAccessFeature(PremiumFeature feature) async {
  final response = await ApiService.shared.post('/api/premium/check-feature', ...);
  final canAccess = responseData['data']?['canAccess'] ?? 
                   responseData['canAccess'] ?? false;
  return canAccess;
}
```

## 📈 Performance Optimizations

### Backend-First Approach
- **Direct API Calls**: Feature checks go straight to backend
- **No Local Caching**: Backend is source of truth for limits
- **Efficient Queries**: Backend checks database directly
- **Real-time Limits**: Always current usage information

### Memory Management
- **Singleton Pattern**: Single service instance
- **No Complex State**: Simple boolean responses
- **Minimal Storage**: No local usage tracking

## 🚨 Common Issues & Solutions

### Issue: Premium page not showing
```dart
// Solution: Check navigation context
Navigator.of(context).push(
  MaterialPageRoute(builder: (context) => const PremiumPage()),
);
```

### Issue: Feature access always false
```dart
// Solution: Check backend response parsing
final canAccess = responseData['data']?['canAccess'] ?? 
                 responseData['canAccess'] ?? false;
```

### Issue: Backend integration not working
```dart
// Solution: Verify API endpoints and authentication
// Check: /api/premium/check-feature
// Check: /api/premium/usage-stats
```

## 🔮 Future Enhancements

### Immediate Next Steps
1. **In-App Purchase Flow**
   - Connect "Continue with [Plan]" button to payment system
   - Handle purchase success/failure states
   - Update user premium status after successful purchase

2. **Receipt Validation**
   - Use preserved receipt validation settings in `PremiumConfig`
   - Implement server-side receipt verification
   - Cache validation results for performance

### Long-term Features
1. **Analytics Integration**
   - Track premium upgrade conversion rates
   - Monitor feature usage patterns
   - A/B test different premium messaging

2. **Advanced Premium Features**
   - Family sharing options
   - Gift subscriptions
   - Referral programs

## 📚 Code Examples

### Adding New Premium Check
```dart
// In any widget/service
if (!await premiumService.canAccessFeature(PremiumFeature.someFeature)) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => const PremiumPage()),
  );
}
```

### Customizing PremiumPage (Future)
```dart
// Currently all content is hardcoded for consistency
// Future: Add optional parameters for slight customization if needed
class PremiumPage extends StatefulWidget {
  final String? customTitle; // Optional for future use
  final String? customDescription; // Optional for future use
  
  const PremiumPage({
    Key? key,
    this.customTitle,
    this.customDescription,
  }) : super(key: key);
}
```

## ✅ Benefits of New Architecture

### For Developers
- **Simplified Architecture**: No more complex trigger logic
- **Easier Maintenance**: One page to update, affects everywhere
- **Better Testing**: Consistent behavior across all entry points
- **Cleaner Code**: Removed unused models and complex configurations

### For Users
- **Consistent Experience**: Same premium page regardless of entry point
- **No More Bugs**: Eliminated dialog dismissal and widget unmount issues
- **Clearer Messaging**: Unified premium value proposition
- **Smoother Navigation**: Page-based navigation instead of modal dialogs

### For Business
- **Better Conversion**: Consistent premium messaging
- **Easier A/B Testing**: Single page to optimize
- **Reduced Support**: Fewer user-reported bugs
- **Faster Development**: Simpler architecture for future features

## 📅 Recent Changes

### January 27, 2025 - Major System Refactor
- **Eliminated Complex Dialog System**: Replaced with single PremiumPage
- **Simplified Navigation**: Direct page navigation instead of modal dialogs
- **Unified Premium Experience**: Consistent content everywhere
- **Backend Integration**: Fixed response parsing and feature checks
- **Code Cleanup**: Removed unused models and complex configurations

### Files Affected
- **New**: `lib/features/premium/premium_page.dart`
- **Modified**: 10 files (services, views, config, models)
- **Deleted**: 4 files (old dialogs and unused services)

---

**Last Updated**: January 27, 2025  
**Maintainer**: Development Team  
**Version**: 3.0.0 - Simplified Architecture  
**Status**: Complete ✅
