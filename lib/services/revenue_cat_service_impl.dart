import 'package:purchases_flutter/purchases_flutter.dart';
import 'revenue_cat_service.dart';

/// Real implementation of RevenueCatService
/// 
/// Wraps static Purchases methods to make them injectable and testable.
class RevenueCatServiceImpl implements RevenueCatService {
  @override
  Future<CustomerInfo> getCustomerInfo() {
    return Purchases.getCustomerInfo();
  }
  
  @override
  Future<Offerings> getOfferings() {
    return Purchases.getOfferings();
  }
  
  @override
  Future<CustomerInfo> purchase(PurchaseParams params) async {
    final result = await Purchases.purchase(params);
    return result.customerInfo;
  }
  
  @override
  Future<CustomerInfo> restorePurchases() {
    return Purchases.restorePurchases();
  }
  
  @override
  Future<CustomerInfo> logIn(String appUserId) async {
    final result = await Purchases.logIn(appUserId);
    return result.customerInfo;
  }
  
  @override
  Future<CustomerInfo> logOut() async {
    return await Purchases.logOut();
  }
}

