/// RevenueCat Configuration Template
/// 
/// Copy this file to revenuecat_config.dart and fill in your actual values.
/// This keeps your API keys secure and separate from the test files.

class RevenueCatConfig {
  // Your actual RevenueCat Public API Key
  // Found in your RevenueCat dashboard under Project Settings
  static const String apiKey = 'appl_OIYtlnvDkuuhmFAAWJojwiAgBxi';
  
  // Test user ID (can be any string, RevenueCat will create the user)
  static const String testUserId = 'bravoball_test_user';
  
  // Production user ID (for production builds)
  static const String productionUserId = 'bravoball_production_user';
  
  // Product IDs - these should match your App Store Connect products
  static const String monthlyPremiumId = 'bravoball_monthly_premium';
  static const String yearlyPremiumId = 'bravoball_yearly_premium';
  
  // Entitlement ID - this should match what you set up in RevenueCat dashboard
  static const String premiumEntitlementId = 'premium';
  
  // Offering ID - this should match what you set up in RevenueCat dashboard
  static const String defaultOfferingId = 'default';
  
  // Environment settings
  static const bool enableDebugLogging = true;
  static const bool enableVerboseLogging = false;
  
  // Apple Pay specific settings
  static const bool enableApplePay = true;
  static const bool requireApplePay = false; // Set to true if you want to force Apple Pay
  
  // Test settings
  static const bool enableMockPurchases = false; // Set to true for testing without real purchases
  static const bool enableSandboxMode = true; // Set to false for production testing
  
  /// Get the appropriate API key based on environment
  static String getApiKey({bool isProduction = false}) {
    // In a real app, you might want different API keys for different environments
    return apiKey;
  }
  
  /// Get the appropriate user ID based on environment
  static String getUserId({bool isProduction = false}) {
    return isProduction ? productionUserId : testUserId;
  }
  
  /// Get all product IDs
  static List<String> getAllProductIds() {
    return [monthlyPremiumId, yearlyPremiumId];
  }
  
  /// Validate configuration
  static bool isValid() {
    if (apiKey == 'YOUR_REVENUECAT_API_KEY_HERE' || apiKey.isEmpty) {
      print('❌ RevenueCat API key not configured');
      return false;
    }
    
    if (monthlyPremiumId.isEmpty || yearlyPremiumId.isEmpty) {
      print('❌ Product IDs not configured');
      return false;
    }
    
    if (premiumEntitlementId.isEmpty || defaultOfferingId.isEmpty) {
      print('❌ Entitlement or Offering ID not configured');
      return false;
    }
    
    return true;
  }
  
  /// Get configuration summary for debugging
  static Map<String, dynamic> getDebugInfo() {
    return {
      'apiKey': apiKey.substring(0, 10) + '...',
      'testUserId': testUserId,
      'productionUserId': productionUserId,
      'monthlyPremiumId': monthlyPremiumId,
      'yearlyPremiumId': yearlyPremiumId,
      'premiumEntitlementId': premiumEntitlementId,
      'defaultOfferingId': defaultOfferingId,
      'enableDebugLogging': enableDebugLogging,
      'enableApplePay': enableApplePay,
      'enableMockPurchases': enableMockPurchases,
      'enableSandboxMode': enableSandboxMode,
      'isValid': isValid(),
    };
  }
}
