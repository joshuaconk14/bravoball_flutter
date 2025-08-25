import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../config/purchase_config.dart';
import '../config/premium_config.dart';
import '../models/purchase_models.dart';
import '../models/premium_models.dart';
import '../services/api_service.dart';
import '../services/premium_service.dart';
import '../utils/haptic_utils.dart';
import '../utils/device_security_utils.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  static PurchaseService get instance => _instance;

  PurchaseService._internal();

  // In-app purchase instance
  late final InAppPurchase _inAppPurchase;
  
  // Device fingerprint key for storage
  static const String _deviceFingerprintKey = 'device_fingerprint';
  
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
      print('🔍 Environment: ${PurchaseConfig.isSandboxEnvironment ? 'Sandbox' : 'Production'}');
      print('🔍 Build type: ${PurchaseConfig.isProductionBuild ? 'Production' : 'Development'}');
    }

    try {
      // Check if we should use mock purchases for testing
      if (PurchaseConfig.shouldEnableMockPurchases) {
        if (kDebugMode) {
          print('🧪 Using mock purchases for testing');
        }
        _isAvailable = true; // Mock purchases are always available
        await _loadProducts(); // This will load mock products
        _isInitialized = true;
        
        if (kDebugMode) {
          print('✅ PurchaseService initialized with mock purchases');
        }
        return;
      }

      // Initialize real in-app purchase
      _inAppPurchase = InAppPurchase.instance;
      
      // Check if in-app purchases are available
      _isAvailable = await _inAppPurchase.isAvailable();
      
      if (kDebugMode) {
        print('🔍 In-app purchase available: $_isAvailable');
        print('🔍 Platform: ${Platform.operatingSystem}');
        print('🔍 Sandbox environment: ${PurchaseConfig.isSandboxEnvironment}');
      }
      
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
    // Check if we should use mock products for testing
    if (PurchaseConfig.shouldEnableMockPurchases) {
      await _loadMockProducts();
      return;
    }
    
    try {
      if (kDebugMode) {
        print('🛍️ Loading products from store...');
        print('🔍 Using product IDs: ${PurchaseConfig.getProductIdsForEnvironment()}');
        print('🔍 Sandbox mode: ${PurchaseConfig.isSandboxEnvironment}');
      }

      final productIds = PurchaseConfig.getProductIdsForEnvironment();
      
      if (productIds.isEmpty) {
        if (kDebugMode) {
          print('❌ No product IDs configured');
        }
        return;
      }
      
      final ProductDetailsResponse response = 
          await _inAppPurchase.queryProductDetails(productIds.toSet());

      if (response.notFoundIDs.isNotEmpty) {
        if (kDebugMode) {
          print('⚠️ Some products not found: ${response.notFoundIDs}');
          print('🔍 This might be normal in sandbox if products are still loading');
          print('🔍 Wait 15-30 minutes after creating products in App Store Connect');
        }
      }

      if (response.error != null) {
        if (kDebugMode) {
          print('❌ Error loading products: ${response.error}');
          print('🔍 Error code: ${response.error!.code}');
          print('🔍 Error message: ${response.error!.message}');
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
        if (_availableProducts.isNotEmpty) {
          for (final product in _availableProducts) {
            print('   - ${product.id}: ${product.formattedPriceWithCurrency}');
          }
        } else {
          print('⚠️ No products loaded - this might indicate:');
          print('   1. Products not yet available in App Store Connect');
          print('   2. Sandbox environment not properly configured');
          print('   3. Device not signed in with sandbox Apple ID');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading products: $e');
        print('🔍 This might be a network or configuration issue');
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
    if (!_isInitialized) {
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
      // Check if this is a sandbox environment issue
      if (PurchaseConfig.isSandboxEnvironment && _availableProducts.isEmpty) {
        return PurchaseResult.failure(
          errorMessage: PurchaseConfig.getUserFriendlyErrorMessage('sandbox_required'),
        );
      }
      
      return PurchaseResult.failure(
        errorMessage: PurchaseConfig.getUserFriendlyErrorMessage('product_not_available'),
      );
    }

    if (kDebugMode) {
      print('🛒 Starting purchase for: ${product.title} (${product.id})');
      print('🔍 Sandbox environment: ${PurchaseConfig.isSandboxEnvironment}');
    }

    // Update state
    _updatePurchaseState(PurchaseState.purchasing);

    // Check if we should use mock purchases for testing
    if (PurchaseConfig.shouldEnableMockPurchases) {
      return await _mockPurchase(productId);
    }

    // Check if real purchases are available
    if (!_isAvailable) {
      return PurchaseResult.failure(
        errorMessage: PurchaseConfig.getUserFriendlyErrorMessage('billing_unavailable'),
      );
    }

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
        print('🔍 Waiting for purchase stream update...');
      }

      // Return a pending result - actual result will come through stream
      return PurchaseResult(
        success: true,
        errorMessage: 'Purchase in progress...',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error starting purchase: $e');
        print('🔍 This might be a sandbox configuration issue');
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
        'platform': Platform.isIOS ? 'ios' : 'android',
        'receiptData': purchaseDetails.verificationData.serverVerificationData.isNotEmpty ? purchaseDetails.verificationData.serverVerificationData : 'mock_receipt_data_${DateTime.now().millisecondsSinceEpoch}',
        'productId': purchaseDetails.productID,
        'transactionId': purchaseDetails.purchaseID,
      };

      // Get device fingerprint for security
      final deviceFingerprint = await _getDeviceFingerprint();
      
      // Call backend validation endpoint
      final response = await ApiService.shared.post(
        '/api/premium/validate-purchase',
        body: validationData,
        headers: {
          'Device-Fingerprint': deviceFingerprint,
          'App-Version': PremiumConfig.appVersion,
        },
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        final isValid = (response.data!['isValid'] as bool?) ?? false;
        
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
    if (!_isInitialized) {
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

    // Check if we should use mock restoration for testing
    if (PurchaseConfig.shouldEnableMockPurchases) {
      return await _mockRestorePurchases();
    }

    // Check if real purchases are available
    if (!_isAvailable) {
      return PurchaseRestorationResult.failure(
        errorMessage: 'Real purchases not available on this device',
      );
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

  /// Check sandbox status and provide debugging info
  Future<Map<String, dynamic>> getSandboxStatus() async {
    final status = <String, dynamic>{
      'isSandboxEnvironment': PurchaseConfig.isSandboxEnvironment,
      'isProductionBuild': PurchaseConfig.isProductionBuild,
      'isDebugMode': PurchaseConfig.isDebugMode,
      'productsLoaded': _availableProducts.length,
      'productsAvailable': _availableProducts.map((p) => p.id).toList(),
      'purchaseServiceAvailable': _isAvailable,
      'purchaseServiceInitialized': _isInitialized,
      'platform': Platform.operatingSystem,
    };
    
    if (kDebugMode) {
      print('🔍 Sandbox Status:');
      for (final entry in status.entries) {
        print('   ${entry.key}: ${entry.value}');
      }
    }
    
    return status;
  }

  /// Refresh products with better error handling
  Future<void> refreshProducts() async {
    if (kDebugMode) {
      print('🔄 Refreshing products...');
      print('🔍 Current sandbox status: ${PurchaseConfig.isSandboxEnvironment}');
    }
    
    await _loadProducts();
    
    if (kDebugMode) {
      print('🔄 Products refresh completed');
      print('🔍 Available products: ${_availableProducts.length}');
    }
  }

  // ===== MOCK PURCHASE METHODS FOR TESTING =====
  
  /// Load mock products for testing
  Future<void> _loadMockProducts() async {
    if (!PurchaseConfig.shouldEnableMockPurchases) return;
    
    if (kDebugMode) {
      print('🧪 Loading mock products for testing...');
    }
    
    // Create mock products
    final mockProducts = [
      StoreProduct(
        id: PurchaseConfig.monthlyPremiumId,
        title: 'Monthly Premium (Mock)',
        description: 'Access to all premium features for 1 month',
        price: '\$15.00',
        currencyCode: 'USD',
        rawPrice: 15.0,
      ),
      StoreProduct(
        id: PurchaseConfig.yearlyPremiumId,
        title: 'Yearly Premium (Mock)',
        description: 'Access to all premium features for 1 year',
        price: '\$95.00',
        currencyCode: 'USD',
        rawPrice: 95.0,
      ),
    ];
    
    _availableProducts = mockProducts;
    _productsController.add(mockProducts);
    
    if (kDebugMode) {
      print('✅ Mock products loaded: ${mockProducts.length} products');
    }
  }
  
  /// Mock purchase for testing
  Future<PurchaseResult> _mockPurchase(String productId) async {
    if (kDebugMode) {
      print('🔍 DEBUG: Starting _mockPurchase');
      print('   ProductId: $productId');
    }
    
    if (!PurchaseConfig.shouldEnableMockPurchases) {
      if (kDebugMode) {
        print('🔍 DEBUG: Mock purchases disabled, returning failure');
      }
      return PurchaseResult.failure(
        errorMessage: 'Mock purchases are disabled',
      );
    }
    
    if (kDebugMode) {
      print('🧪 Processing mock purchase for: $productId');
    }
    
    // Simulate purchase delay
    if (kDebugMode) {
      print('🔍 DEBUG: Simulating purchase delay...');
    }
    await Future.delayed(const Duration(seconds: 2));
    
    if (kDebugMode) {
      print('🔍 DEBUG: Purchase delay completed');
    }
    
    // Create mock purchase result using the constructor directly
    final mockData = PurchaseConfig.mockPurchaseData;
    
    if (kDebugMode) {
      print('🔍 DEBUG: About to update purchase state to purchasing');
    }
    
    // Update state to purchasing while we handle backend
    _updatePurchaseState(PurchaseState.purchasing);
    
    if (kDebugMode) {
      print('🔍 DEBUG: Purchase state updated to purchasing');
    }
    
    // Update premium status after successful purchase
    try {
      if (kDebugMode) {
        print('🔍 DEBUG: About to call _updatePremiumStatusAfterPurchase');
      }
      
      final success = await _updatePremiumStatusAfterPurchase(productId);
      
      if (!success) {
        if (kDebugMode) {
          print('🔍 DEBUG: _updatePremiumStatusAfterPurchase returned false');
        }
        throw Exception('Premium status update failed');
      }
      
      if (kDebugMode) {
        print('🔍 DEBUG: _updatePremiumStatusAfterPurchase completed successfully');
      }
      
      // Only now create success result after backend succeeds
      if (kDebugMode) {
        print('🔍 DEBUG: Creating success PurchaseResult');
      }
      
      final mockResult = PurchaseResult(
        success: true,
        transactionId: mockData['transactionId'],
        purchaseDate: DateTime.now(),
      );
      
      if (kDebugMode) {
        print('🔍 DEBUG: About to update purchase state to success');
      }
      
      // Update state to success
      _updatePurchaseState(PurchaseState.success);
      
      if (kDebugMode) {
        print('🔍 DEBUG: About to add result to purchase result controller');
      }
      
      _purchaseResultController.add(mockResult);
      
      if (kDebugMode) {
        print('✅ Mock purchase completed successfully');
        print('🔍 DEBUG: Returning success result');
      }
      
      return mockResult;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Premium status update failed: $e');
        print('🔍 DEBUG: Exception caught in _mockPurchase');
        print('   Exception type: ${e.runtimeType}');
        print('   Exception message: $e');
        print('🔍 DEBUG: About to revert purchase state to failed');
      }
      
      // Revert purchase state and return failure
      _updatePurchaseState(PurchaseState.failed);
      
      if (kDebugMode) {
        print('🔍 DEBUG: Purchase state reverted to failed');
        print('🔍 DEBUG: Returning failure result');
      }
      
      return PurchaseResult.failure(
        errorMessage: 'Purchase completed but premium activation failed: $e',
      );
    }
  }
  
  /// Mock restore purchases for testing
  Future<PurchaseRestorationResult> _mockRestorePurchases() async {
    if (!PurchaseConfig.shouldEnableMockPurchases) {
      return PurchaseRestorationResult.failure(
        errorMessage: 'Mock purchases are disabled',
      );
    }
    
    if (kDebugMode) {
      print('🧪 Processing mock purchase restoration...');
    }
    
    // Simulate restore delay
    await Future.delayed(const Duration(seconds: 1));
    
    if (kDebugMode) {
      print('✅ Mock purchase restoration completed');
    }
    
    // Return success with empty restored purchases list
    return PurchaseRestorationResult(
      success: true,
      restoredPurchases: [], // Empty list since we don't have real PurchaseDetails
    );
  }

  // ===== PREMIUM STATUS MANAGEMENT =====
  
  /// Update user's premium status after successful purchase
  Future<bool> _updatePremiumStatusAfterPurchase(String productId) async {
    try {
      if (kDebugMode) {
        print('🔓 Updating premium status after purchase: $productId');
      }
      
      // Determine subscription plan from product ID
      final plan = PurchaseConfig.getPlanType(productId);
      if (plan == null) {
        if (kDebugMode) {
          print('⚠️ Could not determine plan type for: $productId');
        }
        return false;
      }
      
      // Update premium status in PremiumService
      final success = await PremiumService.instance.updatePremiumStatusAfterPurchase(
        plan: plan,
        productId: productId,
        purchaseDate: DateTime.now(),
      );
      
      if (kDebugMode) {
        print('✅ Premium status updated successfully for plan: $plan');
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating premium status: $e');
      }
      return false;
    }
  }
  
  /// Check if user has premium access
  Future<bool> hasPremiumAccess() async {
    return await PremiumService.instance.isPremium();
  }
  
  /// Get current premium status
  Future<PremiumStatus> getPremiumStatus() async {
    return await PremiumService.instance.getPremiumStatus();
  }

  /// Dispose resources
  void dispose() {
    _purchaseStateController.close();
    _purchaseResultController.close();
    _productsController.close();
  }

  /// Get device fingerprint for security
  Future<String> _getDeviceFingerprint() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? fingerprint = prefs.getString(_deviceFingerprintKey);
      
      if (fingerprint == null) {
        // Generate new fingerprint
        final deviceInfo = await DeviceSecurityUtils.getDeviceInfo();
        fingerprint = sha256.convert(utf8.encode(deviceInfo)).toString();
        await prefs.setString(_deviceFingerprintKey, fingerprint);
      }
      
      return fingerprint;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting device fingerprint: $e');
      }
      return 'unknown';
    }
  }
}
