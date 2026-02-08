import 'package:purchases_flutter/purchases_flutter.dart';

/// Abstract interface for RevenueCat operations
/// 
/// This allows us to inject different implementations for testing
/// and production use.
abstract class RevenueCatService {
  /// Get current customer info from RevenueCat
  Future<CustomerInfo> getCustomerInfo();
  
  /// Get available offerings from RevenueCat
  Future<Offerings> getOfferings();
  
  /// Make a purchase
  Future<CustomerInfo> purchase(PurchaseParams params);
  
  /// Restore previous purchases
  Future<CustomerInfo> restorePurchases();
  
  /// Log in a user with RevenueCat
  Future<CustomerInfo> logIn(String appUserId);
  
  /// Log out current user
  Future<CustomerInfo> logOut();
}

