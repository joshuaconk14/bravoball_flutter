/// Purchase Configuration
/// 
/// Single source of truth for all purchase-related constants including:
/// - RevenueCat API keys
/// - Product IDs
/// - Package identifiers
/// - Offering IDs
/// - Treat amounts
/// 
/// This ensures consistency across the app and makes it easy to update
/// purchase-related values in one place.
class PurchaseConfig {
  // Private constructor to prevent instantiation
  PurchaseConfig._();

  // ============================================================================
  // REVENUECAT CONFIGURATION
  // ============================================================================
  
  /// RevenueCat API Key for iOS
  static const String revenueCatApiKeyIOS = 'appl_OIYtlnvDkuuhmFAAWJojwiAgBxi';
  
  /// RevenueCat API Key for Android
  static const String revenueCatApiKeyAndroid = 'goog_StgyfWJTGVIARJFEHIFtwKUjYLN';

  // ============================================================================
  // OFFERING IDENTIFIERS
  // ============================================================================
  
  /// Default offering ID (for premium subscriptions)
  static const String defaultOfferingId = 'default';
  
  /// Treats offering ID (for consumable treat packages)
  static const String treatsOfferingId = 'bravoball_treats';

  // ============================================================================
  // PREMIUM SUBSCRIPTION PACKAGE IDENTIFIERS
  // ============================================================================
  
  /// Monthly premium subscription package identifier
  static const String premiumMonthlyPackageId = 'PremiumMonthly';
  
  /// Yearly premium subscription package identifier
  static const String premiumYearlyPackageId = 'PremiumYearly';

  // ============================================================================
  // PREMIUM SUBSCRIPTION PRODUCT IDS
  // ============================================================================
  
  /// Monthly premium subscription product ID (App Store/Google Play)
  static const String premiumMonthlyProductId = 'bravoball_monthly_premium';
  
  /// Yearly premium subscription product ID (App Store/Google Play)
  static const String premiumYearlyProductId = 'bravoball_yearly_premium';

  // ============================================================================
  // TREAT PACKAGE IDENTIFIERS
  // ============================================================================
  
  /// 500 treats package identifier
  static const String treats500PackageId = 'Treats500';
  
  /// 1000 treats package identifier
  static const String treats1000PackageId = 'Treats1000';
  
  /// 2000 treats package identifier
  static const String treats2000PackageId = 'Treats2000';

  // ============================================================================
  // TREAT PRODUCT IDS (App Store/Google Play)
  // ============================================================================
  
  /// 500 treats product ID
  static const String treats500ProductId = 'bravoball_treats_500';
  
  /// 1000 treats product ID
  static const String treats1000ProductId = 'bravoball_treats_1000';
  
  /// 2000 treats product ID
  static const String treats2000ProductId = 'bravoball_treats_2000';

  // ============================================================================
  // TREAT AMOUNTS
  // ============================================================================
  
  /// Amount of treats in the 500 package
  static const int treats500Amount = 500;
  
  /// Amount of treats in the 1000 package
  static const int treats1000Amount = 1000;
  
  /// Amount of treats in the 2000 package
  static const int treats2000Amount = 2000;

  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  
  /// Get product ID from package identifier
  /// 
  /// Maps RevenueCat package identifiers to App Store/Google Play product IDs
  /// Used when working with local StoreKit testing
  static String getProductIdFromPackageId(String packageId) {
    switch (packageId) {
      case treats500PackageId:
        return treats500ProductId;
      case treats1000PackageId:
        return treats1000ProductId;
      case treats2000PackageId:
        return treats2000ProductId;
      case premiumMonthlyPackageId:
        return premiumMonthlyProductId;
      case premiumYearlyPackageId:
        return premiumYearlyProductId;
      default:
        throw Exception('Unknown package identifier: $packageId');
    }
  }
  
  /// Get treat amount from package identifier
  /// 
  /// Returns the number of treats included in a treat package
  static int getTreatAmountFromPackageId(String packageId) {
    switch (packageId) {
      case treats500PackageId:
        return treats500Amount;
      case treats1000PackageId:
        return treats1000Amount;
      case treats2000PackageId:
        return treats2000Amount;
      default:
        return 0;
    }
  }
  
  /// Check if a package identifier is a treat package
  static bool isTreatPackage(String packageId) {
    return packageId == treats500PackageId ||
           packageId == treats1000PackageId ||
           packageId == treats2000PackageId;
  }
  
  /// Check if a package identifier is a premium subscription
  static bool isPremiumPackage(String packageId) {
    return packageId == premiumMonthlyPackageId ||
           packageId == premiumYearlyPackageId;
  }
  
  /// Get all treat package identifiers
  static List<String> getTreatPackageIds() {
    return [
      treats500PackageId,
      treats1000PackageId,
      treats2000PackageId,
    ];
  }
  
  /// Get all treat product IDs
  static List<String> getTreatProductIds() {
    return [
      treats500ProductId,
      treats1000ProductId,
      treats2000ProductId,
    ];
  }
  
  /// Get all premium package identifiers
  static List<String> getPremiumPackageIds() {
    return [
      premiumMonthlyPackageId,
      premiumYearlyPackageId,
    ];
  }
  
  /// Get all premium product IDs
  static List<String> getPremiumProductIds() {
    return [
      premiumMonthlyProductId,
      premiumYearlyProductId,
    ];
  }
}

