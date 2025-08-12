import 'package:flutter/foundation.dart';
import '../models/premium_models.dart';

class PremiumConfig {
  // Free tier limits
  static const int freeCustomDrillsPerMonth = 3;
  static const int freeSessionsPerDay = 1;
  
  // Premium pricing
  static const double monthlyPrice = 15.0;
  static const double yearlyPrice = 95.0;
  static const double yearlyOriginalPrice = 180.0; // $15 * 12 months
  
  // Trial settings
  static const int trialDays = 7;
  static const bool enableTrial = true;
  
  // API configuration
  static const String apiBaseUrl = 'https://api.bravoball.com'; // Replace with your API
  static const String appVersion = '1.0.0';
  
  // Security settings
  static const int maxValidationAttempts = 3;
  static const int validationTimeoutSeconds = 10;
  
  // Feature flags
  static const bool enablePremiumFeatures = true;
  static const bool enableInAppPurchases = true;
  static const bool enableServerValidation = true;
  
  // Subscription plans
  static List<SubscriptionPlanDetails> get subscriptionPlans => [
    SubscriptionPlanDetails(
      plan: SubscriptionPlan.monthly,
      name: 'Monthly Premium',
      price: monthlyPrice,
      durationDays: 30,
      description: 'Full access to all premium features',
      features: [
        'No ads',
        'Unlimited drills',
        'Unlimited custom drills',
        'Unlimited sessions per day',
        'Advanced analytics',
        'Priority support',
      ],
      isPopular: false,
    ),
    SubscriptionPlanDetails(
      plan: SubscriptionPlan.yearly,
      name: 'Yearly Premium',
      price: yearlyPrice,
      durationDays: 365,
      description: 'Best value - Save 47% compared to monthly',
      features: [
        'No ads',
        'Unlimited drills',
        'Unlimited custom drills',
        'Unlimited sessions per day',
        'Advanced analytics',
        'Priority support',
        'Exclusive yearly content',
      ],
      isPopular: true,
      originalPrice: yearlyOriginalPrice,
    ),
  ];
  
  // Feature descriptions for upgrade prompts
  static Map<PremiumFeature, String> get featureDescriptions => {
    PremiumFeature.noAds: 'Enjoy an ad-free experience',
    PremiumFeature.unlimitedDrills: 'Access to all drill types and variations',
    PremiumFeature.unlimitedCustomDrills: 'Create unlimited custom drills',
    PremiumFeature.unlimitedSessions: 'Practice as much as you want',
    PremiumFeature.advancedAnalytics: 'Detailed progress tracking and insights',
    PremiumFeature.basicDrills: 'Access to basic drill library',
    PremiumFeature.weeklySummaries: 'Weekly performance summaries',
    PremiumFeature.monthlySummaries: 'Monthly performance summaries',
  };
  
  // Upgrade prompt configurations
  static List<PremiumUpgradePrompt> get upgradePrompts => [
    PremiumUpgradePrompt(
      title: 'Unlock Your Full Potential',
      description: 'Get unlimited access to all features and remove restrictions',
      features: [
        'No more ads',
        'Unlimited custom drills',
        'Unlimited daily sessions',
        'Advanced analytics',
      ],
      showTrialOffer: true,
      trialDays: trialDays,
    ),
    PremiumUpgradePrompt(
      title: 'Ready for More?',
      description: 'Upgrade to premium and take your training to the next level',
      features: [
        'Remove daily session limit',
        'Create unlimited custom drills',
        'Access premium drill library',
        'Detailed progress tracking',
      ],
      showTrialOffer: false,
    ),
    PremiumUpgradePrompt(
      title: 'Premium Features Await',
      description: 'Unlock the full BravoBall experience',
      features: [
        'Ad-free experience',
        'Unlimited practice sessions',
        'Custom drill creation',
        'Advanced performance insights',
      ],
      showTrialOffer: true,
      trialDays: trialDays,
    ),
  ];
  
  // Free tier upgrade triggers
  static List<String> get freeTierUpgradeTriggers => [
    'daily_session_limit_reached',
    'monthly_custom_drill_limit_reached',
    'ad_shown_after_session',
    'premium_feature_accessed',
    'performance_summary_viewed',
  ];
  
  // Premium feature access levels
  static Map<PremiumFeature, List<PremiumStatus>> get featureAccessLevels => {
    PremiumFeature.noAds: [PremiumStatus.premium, PremiumStatus.trial],
    PremiumFeature.unlimitedDrills: [PremiumStatus.premium, PremiumStatus.trial],
    PremiumFeature.unlimitedCustomDrills: [PremiumStatus.premium, PremiumStatus.trial],
    PremiumFeature.unlimitedSessions: [PremiumStatus.premium, PremiumStatus.trial],
    PremiumFeature.advancedAnalytics: [PremiumStatus.premium, PremiumStatus.trial],
    PremiumFeature.basicDrills: [PremiumStatus.free, PremiumStatus.premium, PremiumStatus.trial],
    PremiumFeature.weeklySummaries: [PremiumStatus.free, PremiumStatus.premium, PremiumStatus.trial],
    PremiumFeature.monthlySummaries: [PremiumStatus.free, PremiumStatus.premium, PremiumStatus.trial],
  };
  
  // Subscription validation settings
  static const int receiptValidationRetryAttempts = 3;
  static const int receiptValidationRetryDelaySeconds = 5;
  static const bool enableReceiptCaching = true;
  static const int receiptCacheExpiryHours = 24;
  
  // Analytics and tracking
  static const bool enableUsageAnalytics = true;
  static const bool enableConversionTracking = true;
  static const bool enableABTesting = false;
  
  // Debug and development
  static bool get isDebugMode => kDebugMode;
  static const bool enableMockPremium = false; // For testing
  static const bool enablePremiumBypass = false; // For development
  
  // Mock premium status for testing (only in debug mode)
  static PremiumStatus get mockPremiumStatus {
    if (isDebugMode && enableMockPremium) {
      return PremiumStatus.premium;
    }
    return PremiumStatus.free;
  }
  
  // Check if premium features should be enabled
  static bool get shouldEnablePremiumFeatures {
    return enablePremiumFeatures && !isDebugMode;
  }
  
  // Check if in-app purchases should be enabled
  static bool get shouldEnableInAppPurchases {
    return enableInAppPurchases && !isDebugMode;
  }
  
  // Check if server validation should be enabled
  static bool get shouldEnableServerValidation {
    return enableServerValidation && !isDebugMode;
  }
  
  // Get feature access for specific status
  static bool canAccessFeature(PremiumFeature feature, PremiumStatus status) {
    final allowedStatuses = featureAccessLevels[feature] ?? [];
    return allowedStatuses.contains(status);
  }
  
  // Get upgrade prompt for specific trigger
  static PremiumUpgradePrompt? getUpgradePromptForTrigger(String trigger) {
    // Return appropriate upgrade prompt based on trigger
    if (trigger == 'daily_session_limit_reached') {
      return upgradePrompts[1]; // "Ready for More?" prompt
    } else if (trigger == 'monthly_custom_drill_limit_reached') {
      return upgradePrompts[2]; // "Premium Features Await" prompt
    } else {
      return upgradePrompts[0]; // Default "Unlock Your Full Potential" prompt
    }
  }
  
  // Get subscription plan by type
  static SubscriptionPlanDetails? getSubscriptionPlan(SubscriptionPlan plan) {
    try {
      return subscriptionPlans.firstWhere((p) => p.plan == plan);
    } catch (e) {
      return null;
    }
  }
  
  // Get popular subscription plan
  static SubscriptionPlanDetails? get popularPlan {
    try {
      return subscriptionPlans.firstWhere((p) => p.isPopular);
    } catch (e) {
      return subscriptionPlans.isNotEmpty ? subscriptionPlans.first : null;
    }
  }
}
