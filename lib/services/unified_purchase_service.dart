import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../config/app_config.dart';
import '../config/purchase_config.dart';
import 'store_service.dart';
import 'revenue_cat_service.dart';
import 'revenue_cat_service_impl.dart';

/// Unified Purchase Service
/// 
/// Handles all in-app purchases (premium subscriptions and treat products)
/// in a single, consistent way for better maintainability and user experience.
class UnifiedPurchaseService extends ChangeNotifier {
  static UnifiedPurchaseService? _instance;
  static UnifiedPurchaseService get instance => _instance ??= UnifiedPurchaseService._();
  
  // Dependencies (injectable for testing)
  final RevenueCatService revenueCat;
  final StoreService storeService;
  
  UnifiedPurchaseService._({
    RevenueCatService? revenueCat,
    StoreService? storeService,
  }) : revenueCat = revenueCat ?? RevenueCatServiceImpl(),
       storeService = storeService ?? StoreService.instance;

  // Purchase state
  bool _isPurchasing = false;
  String? _lastError;

  // Getters
  bool get isPurchasing => _isPurchasing;
  String? get lastError => _lastError;

  /// Purchase any product (premium subscription or treat package)
  /// 
  /// [productType] - Either 'premium' or 'treats'
  /// [packageIdentifier] - The RevenueCat package identifier
  /// [productName] - Human-readable name for error messages
  /// 
  /// Returns: PurchaseResult with success status and details
  Future<PurchaseResult> purchaseProduct({
    required ProductType productType,
    required String packageIdentifier,
    required String productName,
  }) async {
    try {
      _setPurchasing(true);
      _clearError();

      if (kDebugMode) {
        print('🛒 Unified Purchase: Starting $productType purchase');
        print('   Package: $packageIdentifier');
        print('   Product: $productName');
        print('   Using ${AppConfig.useLocalStoreKit ? 'Local StoreKit' : 'Production'}');
      }

      // Get offerings from RevenueCat
      final offerings = await revenueCat.getOfferings();
      
      if (kDebugMode) {
        print('🔍 Debug: All available offerings:');
        for (final entry in offerings.all.entries) {
          print('   ${entry.key}: ${entry.value.availablePackages.length} packages');
        }
      }

      // Find the correct offering and package
      final package = await _findPackage(offerings, productType, packageIdentifier);
      
      if (package == null) {
        throw Exception('Package $packageIdentifier not found in ${productType.name} offering');
      }

      if (kDebugMode) {
        print('📦 Found package: ${package.identifier}');
        print('   Product: ${package.storeProduct.identifier}');
        print('   Price: ${package.storeProduct.priceString}');
      }

      // Make the purchase
      final customerInfo = await revenueCat.purchase(PurchaseParams.package(package));
      
      if (kDebugMode) {
        print('✅ Purchase completed');
        print('   Active subscriptions: ${customerInfo.activeSubscriptions}');
        print('   Entitlements: ${customerInfo.entitlements.active.keys}');
      }

      // Handle post-purchase logic based on product type
      await _handlePostPurchase(productType, packageIdentifier, customerInfo);

      return PurchaseResult.success(
        productName: productName,
        packageIdentifier: packageIdentifier,
        price: package.storeProduct.priceString,
        customerInfo: customerInfo,
      );

    } catch (e) {
      if (kDebugMode) {
        print('❌ Unified Purchase failed: $e');
      }
      
      _setError(_getErrorMessage(e, productName));
      
      return PurchaseResult.failure(
        productName: productName,
        packageIdentifier: packageIdentifier,
        error: e.toString(),
      );
    } finally {
      _setPurchasing(false);
    }
  }

  /// Find the correct package based on product type
  Future<Package?> _findPackage(
    Offerings offerings, 
    ProductType productType, 
    String packageIdentifier
  ) async {
    switch (productType) {
      case ProductType.premium:
        // Premium subscriptions are in the default offering
        if (offerings.current == null) {
          throw Exception('No default offering available');
        }
        return offerings.current!.getPackage(packageIdentifier);
        
      case ProductType.treats:
        // Treat products are in the bravoball_treats offering
        final treatsOffering = offerings.all[PurchaseConfig.treatsOfferingId];
        if (treatsOffering == null) {
          throw Exception('Treats offering not found. Available: ${offerings.all.keys}');
        }
        
        if (AppConfig.useLocalStoreKit) {
          // For local StoreKit, map package identifiers to product IDs
          final productId = PurchaseConfig.getProductIdFromPackageId(packageIdentifier);
          
          return treatsOffering.availablePackages
              .where((p) => p.storeProduct.identifier == productId)
              .firstOrNull;
        } else {
          // For production, use RevenueCat package identifiers
          return treatsOffering.getPackage(packageIdentifier);
        }
    }
  }

  /// Handle post-purchase logic based on product type
  Future<void> _handlePostPurchase(
    ProductType productType,
    String packageIdentifier,
    CustomerInfo customerInfo,
  ) async {
    switch (productType) {
      case ProductType.premium:
        // Premium subscriptions are handled automatically by RevenueCat
        // No additional action needed - entitlements are automatically active
        if (kDebugMode) {
          print('🎉 Premium subscription activated');
        }
        break;
        
      case ProductType.treats:
        // For treat products, we need to add treats to the user's account
        final treatAmount = PurchaseConfig.getTreatAmountFromPackageId(packageIdentifier);
        if (treatAmount > 0) {
          final success = await storeService.addTreatsReward(treatAmount);
          
          if (success) {
            if (kDebugMode) {
              print('🎁 Added $treatAmount treats to user account');
            }
          } else {
            throw Exception('Failed to add treats to account');
          }
        }
        break;
    }
  }
  String _getErrorMessage(dynamic error, String productName) {
    if (error is PurchasesError) {
      switch (error.code) {
        case PurchasesErrorCode.purchaseCancelledError:
          return 'Purchase cancelled';
        case PurchasesErrorCode.paymentPendingError:
          return 'Payment is pending';
        case PurchasesErrorCode.productNotAvailableForPurchaseError:
          return '$productName is not available';
        case PurchasesErrorCode.purchaseNotAllowedError:
          return 'Purchase not allowed';
        case PurchasesErrorCode.purchaseInvalidError:
          return 'Invalid purchase';
        default:
          return 'Purchase failed: ${error.message}';
      }
    }
    return 'Failed to purchase $productName: $error';
  }

  /// Get available packages for a specific product type
  Future<List<Package>> getAvailablePackages(ProductType productType) async {
    try {
      final offerings = await revenueCat.getOfferings();
      
      switch (productType) {
        case ProductType.premium:
          if (offerings.current == null) return [];
          return offerings.current!.availablePackages;
          
        case ProductType.treats:
          final treatsOffering = offerings.all[PurchaseConfig.treatsOfferingId];
          if (treatsOffering == null) return [];
          
          List<Package> treatPackages;
          
          if (AppConfig.useLocalStoreKit) {
            final treatProductIds = PurchaseConfig.getTreatProductIds();
            treatPackages = treatsOffering.availablePackages
                .where((package) => treatProductIds.contains(package.storeProduct.identifier))
                .toList();
          } else {
            treatPackages = treatsOffering.availablePackages
                .where((package) => PurchaseConfig.isTreatPackage(package.identifier))
                .toList();
          }
          
          // Sort packages in desired order: 500, 1000, 2000
          treatPackages.sort((a, b) {
            final aAmount = PurchaseConfig.getTreatAmountFromPackageId(a.identifier);
            final bAmount = PurchaseConfig.getTreatAmountFromPackageId(b.identifier);
            return aAmount.compareTo(bAmount);
          });
          
          return treatPackages;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting packages for $productType: $e');
      }
      return [];
    }
  }

  /// Restore previous purchases
  Future<bool> restorePurchases() async {
    try {
      _setPurchasing(true);
      _clearError();

      if (kDebugMode) {
        print('🔄 Restoring previous purchases...');
      }

      final customerInfo = await revenueCat.restorePurchases();
      
      if (kDebugMode) {
        print('✅ Purchases restored');
        print('   Active subscriptions: ${customerInfo.activeSubscriptions}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error restoring purchases: $e');
      }
      _setError('Failed to restore purchases: $e');
      return false;
    } finally {
      _setPurchasing(false);
    }
  }

  /// Set purchasing state
  void _setPurchasing(bool purchasing) {
    _isPurchasing = purchasing;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _lastError = error;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _lastError = null;
    notifyListeners();
  }

  /// Clear error (public method)
  void clearError() {
    _clearError();
  }
}

/// Product types supported by the unified purchase service
enum ProductType {
  premium,
  treats,
}

/// Result of a purchase operation
class PurchaseResult {
  final bool success;
  final String productName;
  final String packageIdentifier;
  final String? price;
  final String? error;
  final CustomerInfo? customerInfo;

  PurchaseResult._({
    required this.success,
    required this.productName,
    required this.packageIdentifier,
    this.price,
    this.error,
    this.customerInfo,
  });

  factory PurchaseResult.success({
    required String productName,
    required String packageIdentifier,
    required String price,
    required CustomerInfo customerInfo,
  }) {
    return PurchaseResult._(
      success: true,
      productName: productName,
      packageIdentifier: packageIdentifier,
      price: price,
      customerInfo: customerInfo,
    );
  }

  factory PurchaseResult.failure({
    required String productName,
    required String packageIdentifier,
    required String error,
  }) {
    return PurchaseResult._(
      success: false,
      productName: productName,
      packageIdentifier: packageIdentifier,
      error: error,
    );
  }
}
