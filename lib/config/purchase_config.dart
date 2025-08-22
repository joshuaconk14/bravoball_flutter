import 'package:flutter/foundation.dart';

class PurchaseConfig {
  // Product IDs for both platforms
  static const String monthlyPremiumId = 'bravoball_monthly_premium';
  static const String yearlyPremiumId = 'bravoball_yearly_premium';
  
  // Product IDs mapping for different platforms
  static const Map<String, String> productIds = {
    'monthly': monthlyPremiumId,
    'yearly': yearlyPremiumId,
  };
  
  // Expected prices (for validation)
  static const double expectedMonthlyPrice = 15.0;
  static const double expectedYearlyPrice = 95.0;
  
  // Purchase settings
  static const int purchaseTimeoutSeconds = 60;
  static const int maxRetryAttempts = 3;
  static const int retryDelaySeconds = 2;
  
  // Receipt validation settings
  static const bool enableReceiptValidation = true;
  static const int receiptValidationTimeoutSeconds = 30;
  static const int receiptValidationRetryAttempts = 3;
  
  // Feature flags
  static const bool enablePurchaseRestoration = true;
  static const bool enableIntroductoryPricing = true;
  static const bool enableFamilySharing = false; // Future feature
  
  // Debug and development
  static bool get isDebugMode => kDebugMode;
  static const bool enableMockPurchases = true; // For testing
  static const bool enablePurchaseBypass = false; // For development
  
  // Mock purchase data for testing
  static Map<String, dynamic> get mockPurchaseData {
    if (!isDebugMode || !enableMockPurchases) return {};
    
    return {
      'transactionId': 'mock_transaction_${DateTime.now().millisecondsSinceEpoch}',
      'purchaseDate': DateTime.now().toIso8601String(),
      'productId': monthlyPremiumId,
      'isRestored': false,
    };
  }
  
  // Mock receipt data for testing
  static Map<String, dynamic> get mockReceiptData {
    if (!isDebugMode || !enableMockPurchases) return {};
    
    return {
      'platform': 'ios',
      'receiptData': 'mock_receipt_data_${DateTime.now().millisecondsSinceEpoch}',
      'productId': monthlyPremiumId,
      'transactionId': 'mock_transaction_${DateTime.now().millisecondsSinceEpoch}',
    };
  }
  
  // Get product ID by subscription plan
  static String? getProductId(String plan) {
    return productIds[plan];
  }
  
  // Get all product IDs
  static List<String> getAllProductIds() {
    return productIds.values.toList();
  }
  
  // Validate product ID
  static bool isValidProductId(String productId) {
    return productIds.values.contains(productId);
  }
  
  // Check if product is monthly plan
  static bool isMonthlyPlan(String productId) {
    return productId == monthlyPremiumId;
  }
  
  // Check if product is yearly plan
  static bool isYearlyPlan(String productId) {
    return productId == yearlyPremiumId;
  }
  
  // Get plan type from product ID
  static String? getPlanType(String productId) {
    if (productId == monthlyPremiumId) return 'monthly';
    if (productId == yearlyPremiumId) return 'yearly';
    return null;
  }
  
  // Get expected price for product
  static double? getExpectedPrice(String productId) {
    if (productId == monthlyPremiumId) return expectedMonthlyPrice;
    if (productId == yearlyPremiumId) return expectedYearlyPrice;
    return null;
  }
  
  // Check if price is within expected range (allowing for currency differences)
  static bool isPriceReasonable(String productId, double actualPrice) {
    final expectedPrice = getExpectedPrice(productId);
    if (expectedPrice == null) return false;
    
    // Allow 20% variance for currency differences and regional pricing
    final variance = expectedPrice * 0.2;
    final minPrice = expectedPrice - variance;
    final maxPrice = expectedPrice + variance;
    
    return actualPrice >= minPrice && actualPrice <= maxPrice;
  }
  
  // Platform-specific settings
  static const Map<String, dynamic> platformSettings = {
    'ios': {
      'subscriptionGroup': 'bravoball_premium_subscriptions',
      'autoRenewable': true,
      'introductoryPricing': true,
    },
    'android': {
      'subscriptionType': 'recurring',
      'gracePeriod': true,
      'accountHold': true,
    },
  };
  
  // Get platform-specific setting
  static dynamic getPlatformSetting(String platform, String key) {
    final settings = platformSettings[platform];
    return settings?[key];
  }
  
  // Error messages
  static const Map<String, String> errorMessages = {
    'product_not_available': 'This product is not available at the moment.',
    'billing_unavailable': 'Billing is not available on this device.',
    'network_error': 'Network error. Please check your connection and try again.',
    'timeout': 'Request timed out. Please try again.',
    'user_cancelled': 'Purchase was cancelled.',
    'purchase_cancelled': 'Purchase was cancelled.',
    'unknown_error': 'An unexpected error occurred. Please try again.',
  };
  
  // Get user-friendly error message
  static String getUserFriendlyErrorMessage(String errorCode) {
    return errorMessages[errorCode] ?? errorMessages['unknown_error']!;
  }
  
  // Success messages
  static const Map<String, String> successMessages = {
    'monthly': 'Monthly Premium subscription activated!',
    'yearly': 'Yearly Premium subscription activated!',
    'restored': 'Previous purchases restored successfully!',
  };
  
  // Get success message
  static String getSuccessMessage(String planType) {
    return successMessages[planType] ?? 'Premium subscription activated!';
  }
  
  // Purchase flow settings
  static const bool showConfirmationDialog = true;
  static const bool showSuccessAnimation = true;
  static const bool enableHapticFeedback = true;
  static const int successAnimationDuration = 2000; // milliseconds
  
  // Analytics and tracking
  static const bool enablePurchaseAnalytics = true;
  static const bool enableConversionTracking = true;
  static const bool enableErrorTracking = true;
  
  // Security settings
  static const bool enableReceiptEncryption = true;
  static const bool enableDeviceValidation = true;
  static const bool enableRateLimiting = true;
  static const int maxPurchaseAttemptsPerHour = 10;
  
  // Testing and development helpers
  static bool get shouldEnableMockPurchases => isDebugMode && enableMockPurchases;
  static bool get shouldEnablePurchaseBypass => isDebugMode && enablePurchaseBypass;
  static bool get shouldEnableDebugLogging => isDebugMode;
  
  // Get configuration summary for debugging
  static Map<String, dynamic> get debugInfo {
    return {
      'isDebugMode': isDebugMode,
      'enableMockPurchases': enableMockPurchases,
      'enablePurchaseBypass': enablePurchaseBypass,
      'productIds': productIds,
      'expectedPrices': {
        'monthly': expectedMonthlyPrice,
        'yearly': expectedYearlyPrice,
      },
      'purchaseSettings': {
        'timeout': purchaseTimeoutSeconds,
        'maxRetries': maxRetryAttempts,
        'retryDelay': retryDelaySeconds,
      },
      'securitySettings': {
        'receiptValidation': enableReceiptValidation,
        'receiptEncryption': enableReceiptEncryption,
        'deviceValidation': enableDeviceValidation,
        'rateLimiting': enableRateLimiting,
      },
    };
  }
}
