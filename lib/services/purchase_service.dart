import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import '../config/purchase_config.dart';
import '../models/purchase_models.dart';
import '../services/api_service.dart';
import '../utils/haptic_utils.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  static PurchaseService get instance => _instance;

  PurchaseService._internal();

  // In-app purchase instance
  late final InAppPurchase _inAppPurchase;
  
  // Stream controllers for purchase updates
  final StreamController<PurchaseState> _purchaseStateController = 
      StreamController<PurchaseState>.broadcast();
  final StreamController<PurchaseResult> _purchaseResultController = 
      StreamController<PurchaseResult>.broadcast();
  final StreamController<List<StoreProduct>> _productsController = 
      StreamController<List<StoreProduct>>.broadcast();

  // Current state
  PurchaseState _currentState = PurchaseState.initial;
  List<StoreProduct> _availableProducts = [];
  List<ProductDetails> _productDetails = []; // Store actual ProductDetails
  bool _isInitialized = false;
  bool _isAvailable = false;

  // Getters
  PurchaseState get currentState => _currentState;
  List<StoreProduct> get availableProducts => _availableProducts;
  bool get isInitialized => _isInitialized;
  bool get isAvailable => _isAvailable;
  
  // Streams
  Stream<PurchaseState> get purchaseStateStream => _purchaseStateController.stream;
  Stream<PurchaseResult> get purchaseResultStream => _purchaseResultController.stream;
  Stream<List<StoreProduct>> get productsStream => _productsController.stream;

  /// Initialize the purchase service
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (kDebugMode) {
      print('🚀 Initializing PurchaseService...');
    }

    try {
      // Initialize in-app purchase
      _inAppPurchase = InAppPurchase.instance;
      
      // Check if in-app purchases are available
      _isAvailable = await _inAppPurchase.isAvailable();
      
      if (!_isAvailable) {
        if (kDebugMode) {
          print('⚠️ In-app purchases not available on this device');
        }
        _isInitialized = true;
        return;
      }

      // Set up purchase stream listener
      _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdate,
        onDone: () {
          if (kDebugMode) {
            print('✅ Purchase stream completed');
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print('❌ Purchase stream error: $error');
          }
        },
      );

      // Load available products
      await _loadProducts();

      _isInitialized = true;
      
      if (kDebugMode) {
        print('✅ PurchaseService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing PurchaseService: $e');
      }
      _isInitialized = true; // Mark as initialized to prevent retries
    }
  }

  /// Load available products from the store
  Future<void> _loadProducts() async {
    try {
      if (kDebugMode) {
        print('🛍️ Loading products from store...');
      }

      final productIds = PurchaseConfig.getAllProductIds();
      
      final ProductDetailsResponse response = 
          await _inAppPurchase.queryProductDetails(productIds.toSet());

      if (response.notFoundIDs.isNotEmpty) {
        if (kDebugMode) {
          print('⚠️ Some products not found: ${response.notFoundIDs}');
        }
      }

      if (response.error != null) {
        if (kDebugMode) {
          print('❌ Error loading products: ${response.error}');
        }
        return;
      }

      // Store both StoreProduct and ProductDetails
      _productDetails = response.productDetails;
      _availableProducts = response.productDetails
          .map((product) => StoreProduct.fromProductDetails(product))
          .toList();

      // Emit products update
      _productsController.add(_availableProducts);

      if (kDebugMode) {
        print('✅ Loaded ${_availableProducts.length} products');
        for (final product in _availableProducts) {
          print('   - ${product.id}: ${product.formattedPriceWithCurrency}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading products: $e');
      }
    }
  }

  /// Get product by ID
  StoreProduct? getProduct(String productId) {
    try {
      return _availableProducts.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// Get product by subscription plan
  StoreProduct? getProductByPlan(String plan) {
    final productId = PurchaseConfig.getProductId(plan);
    if (productId == null) return null;
    return getProduct(productId);
  }

  /// Start purchase flow for a specific product
  Future<PurchaseResult> purchaseProduct(String productId) async {
    if (!_isInitialized || !_isAvailable) {
      return PurchaseResult.failure(
        errorMessage: 'Purchase service not available',
      );
    }

    if (!PurchaseConfig.isValidProductId(productId)) {
      return PurchaseResult.failure(
        errorMessage: 'Invalid product ID',
      );
    }

    final product = getProduct(productId);
    if (product == null) {
      return PurchaseResult.failure(
        errorMessage: 'Product not available',
      );
    }

    if (kDebugMode) {
      print('🛒 Starting purchase for: ${product.title} (${product.id})');
    }

    // Update state
    _updatePurchaseState(PurchaseState.purchasing);

    try {
      // Create purchase parameters
      final productDetails = _getProductDetails(productId);
      if (productDetails == null) {
        _updatePurchaseState(PurchaseState.failed);
        return PurchaseResult.failure(
          errorMessage: 'Product details not available',
        );
      }

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );

      // Initiate purchase
      final bool success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!success) {
        _updatePurchaseState(PurchaseState.failed);
        return PurchaseResult.failure(
          errorMessage: 'Failed to initiate purchase',
        );
      }

      // Purchase initiated successfully - wait for stream update
      if (kDebugMode) {
        print('✅ Purchase initiated successfully');
      }

      // Return a pending result - actual result will come through stream
      return PurchaseResult(
        success: true,
        errorMessage: 'Purchase in progress...',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error starting purchase: $e');
      }
      
      _updatePurchaseState(PurchaseState.failed);
      return PurchaseResult.failure(
        errorMessage: 'Error starting purchase: $e',
      );
    }
  }

  /// Purchase by subscription plan
  Future<PurchaseResult> purchasePlan(String plan) async {
    final productId = PurchaseConfig.getProductId(plan);
    if (productId == null) {
      return PurchaseResult.failure(
        errorMessage: 'Invalid subscription plan',
      );
    }
    return await purchaseProduct(productId);
  }

  /// Handle purchase updates from the stream
  void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (kDebugMode) {
        print('📱 Purchase update: ${purchaseDetails.status} - ${purchaseDetails.productID}');
      }

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          _updatePurchaseState(PurchaseState.purchasing);
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _handleSuccessfulPurchase(purchaseDetails);
          break;

        case PurchaseStatus.error:
          _handleFailedPurchase(purchaseDetails);
          break;

        case PurchaseStatus.canceled:
          _handleCancelledPurchase(purchaseDetails);
          break;

        default:
          if (kDebugMode) {
            print('⚠️ Unknown purchase status: ${purchaseDetails.status}');
          }
      }
    }
  }

  /// Handle successful purchase
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    if (kDebugMode) {
      print('✅ Purchase successful: ${purchaseDetails.productID}');
    }

    // Update state
    _updatePurchaseState(PurchaseState.success);

    // Provide haptic feedback
    if (PurchaseConfig.enableHapticFeedback) {
      HapticUtils.heavyImpact();
    }

    try {
      // Validate purchase with backend
      final validationResult = await _validatePurchaseWithBackend(purchaseDetails);
      
      if (validationResult) {
        // Create success result
        final result = PurchaseResult.success(
          purchaseDetails: purchaseDetails,
          transactionId: purchaseDetails.purchaseID,
          purchaseDate: DateTime.now(),
        );

        // Emit result
        _purchaseResultController.add(result);

        if (kDebugMode) {
          print('✅ Purchase validated with backend');
        }
      } else {
        // Backend validation failed
        final result = PurchaseResult.failure(
          errorMessage: 'Purchase validation failed',
          purchaseDetails: purchaseDetails,
        );

        _purchaseResultController.add(result);
        _updatePurchaseState(PurchaseState.failed);

        if (kDebugMode) {
          print('❌ Backend validation failed');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error validating purchase: $e');
      }

      // Still emit success since purchase was successful
      final result = PurchaseResult.success(
        purchaseDetails: purchaseDetails,
        transactionId: purchaseDetails.purchaseID,
        purchaseDate: DateTime.now(),
      );

      _purchaseResultController.add(result);
    }

    // Complete the purchase
    await _completePurchase(purchaseDetails);
  }

  /// Handle failed purchase
  void _handleFailedPurchase(PurchaseDetails purchaseDetails) {
    if (kDebugMode) {
      print('❌ Purchase failed: ${purchaseDetails.error?.message}');
    }

    _updatePurchaseState(PurchaseState.failed);

    final error = purchaseDetails.error;
    if (error != null) {
      final purchaseError = PurchaseError.fromIAPError(error);
      final result = PurchaseResult.failure(
        errorMessage: purchaseError.userFriendlyMessage,
        purchaseDetails: purchaseDetails,
      );

      _purchaseResultController.add(result);
    }

    // Complete the purchase to clean up
    _completePurchase(purchaseDetails);
  }

  /// Handle cancelled purchase
  void _handleCancelledPurchase(PurchaseDetails purchaseDetails) {
    if (kDebugMode) {
      print('🚫 Purchase cancelled: ${purchaseDetails.productID}');
    }

    _updatePurchaseState(PurchaseState.cancelled);

    final result = PurchaseResult.cancelled();
    _purchaseResultController.add(result);

    // Complete the purchase to clean up
    _completePurchase(purchaseDetails);
  }

  /// Validate purchase with backend
  Future<bool> _validatePurchaseWithBackend(PurchaseDetails purchaseDetails) async {
    if (!PurchaseConfig.enableReceiptValidation) {
      if (kDebugMode) {
        print('⚠️ Receipt validation disabled - skipping backend validation');
      }
      return true;
    }

    try {
      if (kDebugMode) {
        print('🌐 Validating purchase with backend...');
      }

      // Prepare validation data
      final validationData = {
        'productId': purchaseDetails.productID,
        'purchaseId': purchaseDetails.purchaseID,
        'transactionDate': purchaseDetails.transactionDate,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'receiptData': purchaseDetails.verificationData.serverVerificationData,
      };

      // Call backend validation endpoint
      final response = await ApiService.shared.post(
        '/api/premium/validate-purchase',
        body: validationData,
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        final isValid = response.data!['isValid'] as bool? ?? false;
        
        if (kDebugMode) {
          print('✅ Backend validation result: $isValid');
        }
        
        return isValid;
      } else {
        if (kDebugMode) {
          print('❌ Backend validation failed: ${response.error}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error during backend validation: $e');
      }
      return false;
    }
  }

  /// Complete purchase (clean up)
  Future<void> _completePurchase(PurchaseDetails purchaseDetails) async {
    try {
      await _inAppPurchase.completePurchase(purchaseDetails);
      if (kDebugMode) {
        print('✅ Purchase completed and cleaned up');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error completing purchase: $e');
      }
    }
  }

  /// Restore previous purchases
  Future<PurchaseRestorationResult> restorePurchases() async {
    if (!_isInitialized || !_isAvailable) {
      return PurchaseRestorationResult.failure(
        errorMessage: 'Purchase service not available',
      );
    }

    if (!PurchaseConfig.enablePurchaseRestoration) {
      return PurchaseRestorationResult.failure(
        errorMessage: 'Purchase restoration is disabled',
      );
    }

    if (kDebugMode) {
      print('🔄 Restoring previous purchases...');
    }

    try {
      await _inAppPurchase.restorePurchases();
      
      // Return success - actual restored purchases will come through stream
      return PurchaseRestorationResult.success(
        restoredPurchases: [],
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error restoring purchases: $e');
      }
      
      return PurchaseRestorationResult.failure(
        errorMessage: 'Error restoring purchases: $e',
      );
    }
  }

  /// Update purchase state
  void _updatePurchaseState(PurchaseState newState) {
    _currentState = newState;
    _purchaseStateController.add(newState);
    
    if (kDebugMode) {
      print('🔄 Purchase state updated: ${newState.name}');
    }
  }

  /// Get ProductDetails for a product ID
  ProductDetails? _getProductDetails(String productId) {
    try {
      return _productDetails.firstWhere((product) => product.id == productId);
    } catch (e) {
      if (kDebugMode) {
        print('❌ ProductDetails not found for: $productId');
      }
      return null;
    }
  }

  /// Check if a product is available
  bool isProductAvailable(String productId) {
    return _availableProducts.any((product) => product.id == productId);
  }

  /// Get product price
  String? getProductPrice(String productId) {
    final product = getProduct(productId);
    return product?.price;
  }

  /// Refresh products
  Future<void> refreshProducts() async {
    await _loadProducts();
  }

  /// Dispose resources
  void dispose() {
    _purchaseStateController.close();
    _purchaseResultController.close();
    _productsController.close();
  }
}
