import 'package:in_app_purchase/in_app_purchase.dart';

/// Purchase state for tracking purchase progress
enum PurchaseState {
  initial,
  loading,
  purchasing,
  success,
  failed,
  cancelled,
  restored,
}

/// Purchase result with detailed information
class PurchaseResult {
  final bool success;
  final String? errorMessage;
  final PurchaseDetails? purchaseDetails;
  final String? transactionId;
  final DateTime? purchaseDate;

  const PurchaseResult({
    required this.success,
    this.errorMessage,
    this.purchaseDetails,
    this.transactionId,
    this.purchaseDate,
  });

  /// Create success result
  factory PurchaseResult.success({
    required PurchaseDetails purchaseDetails,
    String? transactionId,
    DateTime? purchaseDate,
  }) {
    return PurchaseResult(
      success: true,
      purchaseDetails: purchaseDetails,
      transactionId: transactionId,
      purchaseDate: purchaseDate ?? DateTime.now(),
    );
  }

  /// Create failure result
  factory PurchaseResult.failure({
    required String errorMessage,
    PurchaseDetails? purchaseDetails,
  }) {
    return PurchaseResult(
      success: false,
      errorMessage: errorMessage,
      purchaseDetails: purchaseDetails,
    );
  }

  /// Create cancelled result
  factory PurchaseResult.cancelled() {
    return PurchaseResult(
      success: false,
      errorMessage: 'Purchase was cancelled',
    );
  }
}

/// Store product information
class StoreProduct {
  final String id;
  final String title;
  final String description;
  final String price;
  final String currencyCode;
  final double rawPrice;
  final String? introductoryPrice;
  final String? introductoryPricePaymentMode;
  final int? introductoryPriceNumberOfPeriods;
  final String? introductoryPriceSubscriptionPeriod;
  final String? introductoryPriceAsAmount;
  final String? introductoryPricePaymentModeIOS;
  final String? introductoryPriceNumberOfPeriodsIOS;
  final String? introductoryPriceSubscriptionPeriodIOS;
  final String? introductoryPriceAsAmountIOS;
  final String? introductoryPricePaymentModeAndroid;
  final String? introductoryPriceNumberOfPeriodsAndroid;
  final String? introductoryPriceSubscriptionPeriodAndroid;
  final String? introductoryPriceAsAmountAndroid;

  const StoreProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currencyCode,
    required this.rawPrice,
    this.introductoryPrice,
    this.introductoryPricePaymentMode,
    this.introductoryPriceNumberOfPeriods,
    this.introductoryPriceSubscriptionPeriod,
    this.introductoryPriceAsAmount,
    this.introductoryPricePaymentModeIOS,
    this.introductoryPriceNumberOfPeriodsIOS,
    this.introductoryPriceSubscriptionPeriodIOS,
    this.introductoryPriceAsAmountIOS,
    this.introductoryPricePaymentModeAndroid,
    this.introductoryPriceNumberOfPeriodsAndroid,
    this.introductoryPriceSubscriptionPeriodAndroid,
    this.introductoryPriceAsAmountAndroid,
  });

  /// Create from ProductDetails
  factory StoreProduct.fromProductDetails(ProductDetails productDetails) {
    return StoreProduct(
      id: productDetails.id,
      title: productDetails.title,
      description: productDetails.description,
      price: productDetails.price,
      currencyCode: productDetails.currencyCode,
      rawPrice: productDetails.rawPrice,
      introductoryPrice: null, // Not available in current version
      introductoryPricePaymentMode: null,
      introductoryPriceNumberOfPeriods: null,
      introductoryPriceSubscriptionPeriod: null,
      introductoryPriceAsAmount: null,
      introductoryPricePaymentModeIOS: null,
      introductoryPriceNumberOfPeriodsIOS: null,
      introductoryPriceSubscriptionPeriodIOS: null,
      introductoryPriceAsAmountIOS: null,
      introductoryPricePaymentModeAndroid: null,
      introductoryPriceNumberOfPeriodsAndroid: null,
      introductoryPriceSubscriptionPeriodAndroid: null,
      introductoryPriceAsAmountAndroid: null,
    );
  }

  /// Check if this is a subscription product
  bool get isSubscription {
    return id.contains('premium') || id.contains('subscription');
  }

  /// Get formatted price with currency
  String get formattedPriceWithCurrency {
    return '$price $currencyCode';
  }

  /// Get introductory price if available
  String? get introductoryPriceFormatted {
    if (introductoryPrice != null && introductoryPrice!.isNotEmpty) {
      return '$introductoryPrice $currencyCode';
    }
    return null;
  }
}

/// Purchase error details
class PurchaseError {
  final String code;
  final String message;
  final String? details;
  final DateTime timestamp;

  PurchaseError({
    required this.code,
    required this.message,
    this.details,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime(2025, 1, 1);

  /// Create from IAPError
  factory PurchaseError.fromIAPError(IAPError error) {
    return PurchaseError(
      code: error.code,
      message: error.message,
      details: error.details,
    );
  }

  /// Check if error is user-cancelled
  bool get isUserCancelled {
    return code == 'user_cancelled' || 
           code == 'purchase_cancelled' || 
           message.toLowerCase().contains('cancelled');
  }

  /// Check if error is network-related
  bool get isNetworkError {
    return code == 'network_error' || 
           code == 'timeout' || 
           message.toLowerCase().contains('network');
  }

  /// Get user-friendly error message
  String get userFriendlyMessage {
    if (isUserCancelled) {
      return 'Purchase was cancelled';
    }
    if (isNetworkError) {
      return 'Network error. Please check your connection and try again.';
    }
    if (code == 'product_not_available') {
      return 'This product is not available at the moment.';
    }
    if (code == 'billing_unavailable') {
      return 'Billing is not available on this device.';
    }
    return message.isNotEmpty ? message : 'An unexpected error occurred.';
  }
}

/// Purchase restoration result
class PurchaseRestorationResult {
  final bool success;
  final List<PurchaseDetails> restoredPurchases;
  final String? errorMessage;
  final DateTime timestamp;

  PurchaseRestorationResult({
    required this.success,
    this.restoredPurchases = const [],
    this.errorMessage,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime(2025, 1, 1);

  /// Create success result
  factory PurchaseRestorationResult.success({
    required List<PurchaseDetails> restoredPurchases,
  }) {
    return PurchaseRestorationResult(
      success: true,
      restoredPurchases: restoredPurchases,
    );
  }

  /// Create failure result
  factory PurchaseRestorationResult.failure({
    required String errorMessage,
  }) {
    return PurchaseRestorationResult(
      success: false,
      errorMessage: errorMessage,
    );
  }

  /// Check if any purchases were restored
  bool get hasRestoredPurchases => restoredPurchases.isNotEmpty;

  /// Get count of restored purchases
  int get restoredPurchaseCount => restoredPurchases.length;
}
