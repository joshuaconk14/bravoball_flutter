import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/api_service.dart';
import '../services/user_manager_service.dart';
import '../config/app_config.dart';

/// Store Service for managing user store items and purchases
class StoreService extends ChangeNotifier {
  static StoreService? _instance;
  static StoreService get instance => _instance ??= StoreService._();
  
  StoreService._();

  // Store items state
  int _treats = 2000; // Placeholder amount
  int _streakFreezes = 0;
  int _streakRevivers = 0;
  bool _isLoading = false;
  String? _error;

  // Getters
  int get treats => _treats;
  int get streakFreezes => _streakFreezes;
  int get streakRevivers => _streakRevivers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize the store service and fetch user's store items
  Future<void> initialize() async {
    try {
      _setLoading(true);
      await _fetchUserStoreItems();
      if (kDebugMode) {
        print('✅ Store service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing store service: $e');
      }
      _setError('Failed to load store items');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch user's store items from the backend
  Future<void> _fetchUserStoreItems() async {
    try {
      final userManager = UserManagerService.instance;
      if (!userManager.isAuthenticated) {
        if (kDebugMode) {
          print('⚠️ User not authenticated, using placeholder data');
        }
        return;
      }

      final response = await ApiService.shared.get(
        '/api/store/items',
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        _treats = data['treats'] ?? 2000;
        _streakFreezes = data['streak_freezes'] ?? 0;
        _streakRevivers = data['streak_revivers'] ?? 0;
        
        if (kDebugMode) {
          print('📦 Store items loaded:');
          print('   Treats: $_treats');
          print('   Streak Freezes: $_streakFreezes');
          print('   Streak Revivers: $_streakRevivers');
        }
        
        notifyListeners();
      } else {
        throw Exception('Failed to fetch store items: ${response.error}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching store items: $e');
      }
      // Keep placeholder values on error
      _treats = 2000;
      _streakFreezes = 0;
      _streakRevivers = 0;
      notifyListeners();
    }
  }

  /// Purchase a streak freeze using treats
  Future<bool> purchaseStreakFreeze() async {
    const requiredTreats = 50;
    
    if (_treats < requiredTreats) {
      _setError('Not enough treats! You need $requiredTreats treats.');
      return false;
    }

    try {
      _setLoading(true);
      _setError(null);

      final userManager = UserManagerService.instance;
      if (!userManager.isAuthenticated) {
        // For testing without authentication
        _treats -= requiredTreats;
        _streakFreezes += 1;
        notifyListeners();
        return true;
      }

      // Step 1: Increment streak freezes
      final incrementResponse = await ApiService.shared.post(
        '/api/store/items/increment',
        body: {'streak_freezes': 1},
        requiresAuth: true,
      );

      if (!incrementResponse.isSuccess) {
        throw Exception('Failed to increment streak freezes: ${incrementResponse.error}');
      }

      // Step 2: Decrement treats
      final decrementResponse = await ApiService.shared.post(
        '/api/store/items/decrement',
        body: {'treats': requiredTreats},
        requiresAuth: true,
      );

      if (decrementResponse.isSuccess && decrementResponse.data != null) {
        final data = decrementResponse.data!;
        _treats = data['treats'] ?? _treats - requiredTreats;
        _streakFreezes = data['streak_freezes'] ?? _streakFreezes + 1;
        
        if (kDebugMode) {
          print('✅ Streak freeze purchased!');
          print('   New treats: $_treats');
          print('   New streak freezes: $_streakFreezes');
        }
        
        notifyListeners();
        return true;
      } else {
        throw Exception('Failed to decrement treats: ${decrementResponse.error}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error purchasing streak freeze: $e');
      }
      _setError('Failed to purchase streak freeze');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Purchase a streak reviver using treats
  Future<bool> purchaseStreakReviver() async {
    const requiredTreats = 100;
    
    if (_treats < requiredTreats) {
      _setError('Not enough treats! You need $requiredTreats treats.');
      return false;
    }

    try {
      _setLoading(true);
      _setError(null);

      final userManager = UserManagerService.instance;
      if (!userManager.isAuthenticated) {
        // For testing without authentication
        _treats -= requiredTreats;
        _streakRevivers += 1;
        notifyListeners();
        return true;
      }

      // Step 1: Increment streak revivers
      final incrementResponse = await ApiService.shared.post(
        '/api/store/items/increment',
        body: {'streak_revivers': 1},
        requiresAuth: true,
      );

      if (!incrementResponse.isSuccess) {
        throw Exception('Failed to increment streak revivers: ${incrementResponse.error}');
      }

      // Step 2: Decrement treats
      final decrementResponse = await ApiService.shared.post(
        '/api/store/items/decrement',
        body: {'treats': requiredTreats},
        requiresAuth: true,
      );

      if (decrementResponse.isSuccess && decrementResponse.data != null) {
        final data = decrementResponse.data!;
        _treats = data['treats'] ?? _treats - requiredTreats;
        _streakRevivers = data['streak_revivers'] ?? _streakRevivers + 1;
        
        if (kDebugMode) {
          print('✅ Streak reviver purchased!');
          print('   New treats: $_treats');
          print('   New streak revivers: $_streakRevivers');
        }
        
        notifyListeners();
        return true;
      } else {
        throw Exception('Failed to decrement treats: ${decrementResponse.error}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error purchasing streak reviver: $e');
      }
      _setError('Failed to purchase streak reviver');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _setError(null);
  }

  /// Add treats as a reward (for ads, achievements, etc.)
  Future<bool> addTreatsReward(int amount) async {
    try {
      _setLoading(true);
      _setError(null);

      final userManager = UserManagerService.instance;
      if (!userManager.isAuthenticated) {
        // For testing without authentication
        _treats += amount;
        notifyListeners();
        if (kDebugMode) {
          print('🎁 Reward: Added $amount treats. New total: $_treats');
        }
        return true;
      }

      // Make API call to add treats in backend
      final response = await ApiService.shared.post(
        '/api/store/items/increment',
        body: {'treats': amount},
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        _treats = data['treats'] ?? _treats + amount;
        
        if (kDebugMode) {
          print('🎁 Reward: Added $amount treats via API. New total: $_treats');
        }
        
        notifyListeners();
        return true;
      } else {
        throw Exception('Failed to add treats reward: ${response.error}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error adding treats reward: $e');
      }
      // Fallback to local update if API fails
      _treats += amount;
      notifyListeners();
      if (kDebugMode) {
        print('🎁 Reward: Added $amount treats locally (API failed). New total: $_treats');
      }
      return true;
    } finally {
      _setLoading(false);
    }
  }

  /// Debug method to add treats (only works in debug mode)
  Future<void> addDebugTreats(int amount) async {
    if (kDebugMode) {
      try {
        _setLoading(true);
        _setError(null);

        final userManager = UserManagerService.instance;
        if (!userManager.isAuthenticated) {
          // For testing without authentication
          _treats += amount;
          notifyListeners();
          if (kDebugMode) {
            print('🐛 DEBUG: Added $amount treats. New total: $_treats');
          }
          return;
        }

        // Make API call to update treats in backend
        final response = await ApiService.shared.post(
          '/api/store/items/increment',
          body: {'treats': amount},
          requiresAuth: true,
        );

        if (response.isSuccess && response.data != null) {
          final data = response.data!;
          _treats = data['treats'] ?? _treats + amount;
          
          if (kDebugMode) {
            print('🐛 DEBUG: Added $amount treats via API. New total: $_treats');
          }
          
          notifyListeners();
        } else {
          throw Exception('Failed to update treats: ${response.error}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error updating treats: $e');
        }
        // Fallback to local update if API fails
        _treats += amount;
        notifyListeners();
        if (kDebugMode) {
          print('🐛 DEBUG: Added $amount treats locally (API failed). New total: $_treats');
        }
      } finally {
        _setLoading(false);
      }
    }
  }

  /// Purchase treat packages using RevenueCat
  Future<bool> purchaseTreatPackage(String packageIdentifier) async {
    try {
      _setLoading(true);
      _setError(null);

      if (kDebugMode) {
        print('🛒 Attempting to purchase treat package: $packageIdentifier');
        print('   Using ${AppConfig.useLocalStoreKit ? 'Local StoreKit' : 'Production'}');
      }

      // Get offerings from RevenueCat
      final offerings = await Purchases.getOfferings();
      
      if (kDebugMode) {
        print('🔍 Debug: All available offerings:');
        for (final entry in offerings.all.entries) {
          print('   ${entry.key}: ${entry.value.availablePackages.length} packages');
          for (final package in entry.value.availablePackages) {
            print('     - ${package.identifier}: ${package.storeProduct.identifier}');
          }
        }
      }
      
      // Get the treats offering specifically
      final treatsOffering = offerings.all['bravoball_treats'];
      if (treatsOffering == null) {
        throw Exception('Treats offering not found. Available offerings: ${offerings.all.keys}');
      }

      if (kDebugMode) {
        print('📦 Found treats offering: ${treatsOffering.identifier}');
        print('   Available packages: ${treatsOffering.availablePackages.map((p) => p.identifier).toList()}');
      }

      // Find the package - handle local StoreKit vs production mapping
      Package? package;
      if (AppConfig.useLocalStoreKit) {
        // For local StoreKit, map package identifiers to product IDs
        String productId;
        switch (packageIdentifier) {
          case 'Treats500':
            productId = 'bravoball_treats_500';
            break;
          case 'Treats1000':
            productId = 'bravoball_treats_1000';
            break;
          case 'Treats2000':
            productId = 'bravoball_treats_2000';
            break;
          default:
            throw Exception('Unknown package identifier: $packageIdentifier');
        }
        
        // Find package by product ID in local StoreKit
        package = treatsOffering.availablePackages
            .where((p) => p.storeProduct.identifier == productId)
            .firstOrNull;
      } else {
        // For production, use RevenueCat package identifiers
        package = treatsOffering.getPackage(packageIdentifier);
      }
      
      if (package == null) {
        throw Exception('Package $packageIdentifier not found');
      }

      if (kDebugMode) {
        print('📦 Found package: ${package.identifier}');
        print('   Product: ${package.storeProduct.identifier}');
        print('   Price: ${package.storeProduct.priceString}');
      }

      // Make the purchase
      final purchaseResult = await Purchases.purchase(PurchaseParams.package(package));
      
      if (purchaseResult.customerInfo.entitlements.active.isNotEmpty) {
        // This shouldn't happen for consumables, but just in case
        if (kDebugMode) {
          print('⚠️ Purchase completed but no entitlements expected for consumables');
        }
      }

      // Determine treat amount based on package identifier
      int treatAmount = 0;
      switch (packageIdentifier) {
        case 'Treats500':
          treatAmount = 500;
          break;
        case 'Treats1000':
          treatAmount = 1000;
          break;
        case 'Treats2000':
          treatAmount = 2000;
          break;
        default:
          throw Exception('Unknown package identifier: $packageIdentifier');
      }

      // Add treats to user's account
      final success = await addTreatsReward(treatAmount);
      
      if (success) {
        if (kDebugMode) {
          print('✅ Treat package purchased successfully!');
          print('   Package: $packageIdentifier');
          print('   Treats added: $treatAmount');
          print('   New total: $_treats');
        }
        return true;
      } else {
        throw Exception('Failed to add treats to account');
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ Error purchasing treat package: $e');
      }
      
      // Handle specific RevenueCat errors
      if (e is PurchasesError) {
        switch (e.code) {
          case PurchasesErrorCode.purchaseCancelledError:
            _setError('Purchase was cancelled');
            break;
          case PurchasesErrorCode.paymentPendingError:
            _setError('Payment is pending');
            break;
          case PurchasesErrorCode.productNotAvailableForPurchaseError:
            _setError('Product not available');
            break;
          case PurchasesErrorCode.purchaseNotAllowedError:
            _setError('Purchase not allowed');
            break;
          case PurchasesErrorCode.purchaseInvalidError:
            _setError('Invalid purchase');
            break;
          default:
            _setError('Purchase failed: ${e.message}');
        }
      } else {
        _setError('Purchase failed: $e');
      }
      
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get available treat packages from RevenueCat
  Future<List<Package>> getAvailableTreatPackages() async {
    try {
      final offerings = await Purchases.getOfferings();
      
      // Get the treats offering specifically
      final treatsOffering = offerings.all['bravoball_treats'];
      if (treatsOffering == null) {
        if (kDebugMode) {
          print('⚠️ Treats offering not found. Available offerings: ${offerings.all.keys}');
        }
        return [];
      }

      List<Package> treatPackages;
      
      if (AppConfig.useLocalStoreKit) {
        // For local StoreKit, filter by product IDs
        treatPackages = treatsOffering.availablePackages
            .where((package) => 
                package.storeProduct.identifier == 'bravoball_treats_500' ||
                package.storeProduct.identifier == 'bravoball_treats_1000' ||
                package.storeProduct.identifier == 'bravoball_treats_2000')
            .toList();
      } else {
        // For production, filter by package identifiers
        treatPackages = treatsOffering.availablePackages
            .where((package) => package.identifier.startsWith('Treats'))
            .toList();
      }

      if (kDebugMode) {
        print('📦 Available treat packages from ${treatsOffering.identifier}:');
        for (final package in treatPackages) {
          print('   ${package.identifier}: ${package.storeProduct.priceString}');
        }
      }

      return treatPackages;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting treat packages: $e');
      }
      return [];
    }
  }
}
