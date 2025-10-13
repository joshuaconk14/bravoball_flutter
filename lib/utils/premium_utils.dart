import 'package:purchases_flutter/purchases_flutter.dart';

/// Simple utility class for checking premium status using RevenueCat
class PremiumUtils {
  /// Check if the user has premium access
  /// This is the main method you'll use throughout your app
  static Future<bool> hasPremiumAccess() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      
      // Debug logging to see what's happening
      print('🔍 Premium Check Debug:');
      print('   User ID: ${customerInfo.originalAppUserId}');
      print('   Active Entitlements: ${customerInfo.entitlements.active.keys}');
      print('   All Entitlements: ${customerInfo.entitlements.all.keys}');
      
      // Check if user has any active entitlements (this covers the 'premium' entitlement)
      final hasActiveEntitlements = customerInfo.entitlements.active.isNotEmpty;
      
      if (hasActiveEntitlements) {
        print('✅ Premium access granted - Active entitlements: ${customerInfo.entitlements.active.keys}');
        return true;
      } else {
        print('❌ No premium access - No active entitlements found');
        return false;
      }
    } catch (e) {
      print('❌ Error checking premium status: $e');
      // If there's an error, assume no premium access for security
      return false;
    }
  }

  /// Get current customer info (useful for debugging)
  static Future<CustomerInfo?> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      print('❌ Error getting customer info: $e');
      return null;
    }
  }

  /// Get all active entitlements (for debugging/display purposes)
  static Future<List<String>> getActiveEntitlements() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.keys.toList();
    } catch (e) {
      print('❌ Error getting active entitlements: $e');
      return [];
    }
  }

  /// Debug method to check current RevenueCat user identity
  static Future<void> debugUserIdentity() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      print('🔍 RevenueCat User Identity Debug:');
      print('   Original App User ID: ${customerInfo.originalAppUserId}');
      print('   Active Entitlements: ${customerInfo.entitlements.active.keys}');
      print('   All Entitlements: ${customerInfo.entitlements.all.keys}');
      print('   Active Subscriptions: ${customerInfo.activeSubscriptions}');
    } catch (e) {
      print('❌ Error debugging user identity: $e');
    }
  }
}
