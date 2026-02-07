import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart';
import '../services/revenue_cat_service.dart';
import '../services/revenue_cat_service_impl.dart';

/// Utility class for checking premium status using RevenueCat
/// 
/// Uses dependency injection for testability while maintaining backward
/// compatibility with static methods.
class PremiumUtils {
  // Singleton instance
  static PremiumUtils? _instance;
  static PremiumUtils get instance => _instance ??= PremiumUtils._();
  
  // RevenueCat service (injectable for testing)
  final RevenueCatService revenueCat;
  
  // Private constructor - use instance getter
  PremiumUtils._({RevenueCatService? revenueCat})
      : revenueCat = revenueCat ?? RevenueCatServiceImpl();
  
  // Factory constructor for testing (allows injecting fake service)
  factory PremiumUtils.test(RevenueCatService revenueCat) {
    _instance = PremiumUtils._(revenueCat: revenueCat);
    return _instance!;
  }
  
  /// Reset instance (useful for testing)
  static void reset() {
    _instance = null;
  }

  /// Check if the user has premium access
  /// This is the main method you'll use throughout your app
  Future<bool> hasPremiumAccess() async {
    try {
      final customerInfo = await revenueCat.getCustomerInfo();
      
      if (kDebugMode) {
        print('🔍 Premium Check Debug:');
        print('   User ID: ${customerInfo.originalAppUserId}');
        print('   Active Entitlements: ${customerInfo.entitlements.active.keys}');
        print('   All Entitlements: ${customerInfo.entitlements.all.keys}');
      }
      
      // Check if user has any active entitlements (this covers the 'premium' entitlement)
      final hasActiveEntitlements = customerInfo.entitlements.active.isNotEmpty;
      
      if (hasActiveEntitlements) {
        if (kDebugMode) {
          print('✅ Premium access granted - Active entitlements: ${customerInfo.entitlements.active.keys}');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('❌ No premium access - No active entitlements found');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking premium status: $e');
      }
      // If there's an error, assume no premium access for security
      return false;
    }
  }

  /// Get current customer info (useful for debugging)
  Future<CustomerInfo?> getCustomerInfo() async {
    try {
      return await revenueCat.getCustomerInfo();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting customer info: $e');
      }
      return null;
    }
  }

  /// Get all active entitlements (for debugging/display purposes)
  Future<List<String>> getActiveEntitlements() async {
    try {
      final customerInfo = await revenueCat.getCustomerInfo();
      return customerInfo.entitlements.active.keys.toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting active entitlements: $e');
      }
      return [];
    }
  }

  /// Debug method to check current RevenueCat user identity
  Future<void> debugUserIdentity() async {
    try {
      final customerInfo = await revenueCat.getCustomerInfo();
      if (kDebugMode) {
        print('🔍 RevenueCat User Identity Debug:');
        print('   Original App User ID: ${customerInfo.originalAppUserId}');
        print('   Active Entitlements: ${customerInfo.entitlements.active.keys}');
        print('   All Entitlements: ${customerInfo.entitlements.all.keys}');
        print('   Active Subscriptions: ${customerInfo.activeSubscriptions}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error debugging user identity: $e');
      }
    }
  }
}
