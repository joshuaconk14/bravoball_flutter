import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/api_service.dart';
import '../services/user_manager_service.dart';
import '../utils/store_business_rules.dart';

/// Store Service for managing user store items and purchases
class StoreService extends ChangeNotifier {
  static StoreService? _instance;
  static StoreService get instance => _instance ??= StoreService._();
  
  StoreService._();

  // Store items state
  int _treats = 0; // Placeholder amount
  int _streakFreezes = 0;
  int _streakRevivers = 0;
  DateTime? _activeFreezeDate;
  List<DateTime> _usedFreezes = []; // ✅ Historical record of all freeze dates used
  DateTime? _activeStreakReviver; // ✅ NEW: Active streak reviver date
  List<DateTime> _usedRevivers = []; // ✅ NEW: Historical record of all reviver dates used
  bool _isLoading = false;
  String? _error;

  // Getters
  int get treats => _treats;
  int get streakFreezes => _streakFreezes;
  int get streakRevivers => _streakRevivers;
  DateTime? get activeFreezeDate => _activeFreezeDate;
  List<DateTime> get usedFreezes => _usedFreezes; // ✅ Expose used freezes
  DateTime? get activeStreakReviver => _activeStreakReviver; // ✅ NEW: Expose active reviver
  List<DateTime> get usedRevivers => _usedRevivers; // ✅ NEW: Expose used revivers
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
        _treats = data['treats'] ?? 0;
        _streakFreezes = data['streak_freezes'] ?? 0;
        _streakRevivers = data['streak_revivers'] ?? 0;
        
        // ✅ Load active freeze date from store items
        _activeFreezeDate = StoreBusinessRules.parseDateSafely(data['active_freeze_date']);
        
        // ✅ NEW: Load used freezes array from store items
        if (data['used_freezes'] != null && data['used_freezes'] is List) {
          _usedFreezes = [];
          for (var freezeDateStr in data['used_freezes']) {
            try {
              _usedFreezes.add(DateTime.parse(freezeDateStr));
            } catch (e) {
              if (kDebugMode) {
                print('❌ Error parsing freeze date $freezeDateStr: $e');
              }
            }
          }
        } else {
          _usedFreezes = [];
        }
        
        // ✅ NEW: Load active streak reviver date from store items
        _activeStreakReviver = StoreBusinessRules.parseDateSafely(data['active_streak_reviver']);
        
        // ✅ NEW: Load used revivers array from store items
        if (data['used_revivers'] != null && data['used_revivers'] is List) {
          _usedRevivers = [];
          for (var reviverDateStr in data['used_revivers']) {
            try {
              _usedRevivers.add(DateTime.parse(reviverDateStr));
            } catch (e) {
              if (kDebugMode) {
                print('❌ Error parsing reviver date $reviverDateStr: $e');
              }
            }
          }
        } else {
          _usedRevivers = [];
        }
        
        if (kDebugMode) {
          print('📦 Store items loaded:');
          print('   Treats: $_treats');
          print('   Streak Freezes: $_streakFreezes');
          print('   Streak Revivers: $_streakRevivers');
          print('   Active Freeze Date: $_activeFreezeDate');
          print('   Used Freezes Count: ${_usedFreezes.length}');
          print('   Used Freezes Array: $_usedFreezes');
          print('   Active Streak Reviver: $_activeStreakReviver');
          print('   Used Revivers Count: ${_usedRevivers.length}');
          print('   Used Revivers Array: $_usedRevivers');
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
      _treats = 0;
      _streakFreezes = 0;
      _streakRevivers = 0;
      notifyListeners();
    }
  }

  /// Purchase a streak freeze using treats
  Future<bool> purchaseStreakFreeze() async {
    final requiredTreats = StoreBusinessRules.getRequiredTreatsForFreeze();
    
    if (!StoreBusinessRules.canPurchaseStreakFreeze(_treats)) {
      _setError('Not enough treats! You need $requiredTreats treats.');
      return false;
    }

    try {
      _setLoading(true);
      _setError(null);

      final userManager = UserManagerService.instance;
      // Require authentication - no bypasses in production
      if (!userManager.isAuthenticated) {
        if (kDebugMode) {
          print('⚠️ Cannot purchase streak freeze: User not authenticated');
        }
        _setError('You must be logged in to purchase items');
        return false;
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
    final requiredTreats = StoreBusinessRules.getRequiredTreatsForReviver();
    
    if (!StoreBusinessRules.canPurchaseStreakReviver(_treats)) {
      _setError('Not enough treats! You need $requiredTreats treats.');
      return false;
    }

    try {
      _setLoading(true);
      _setError(null);

      final userManager = UserManagerService.instance;
      // Require authentication - no bypasses in production
      if (!userManager.isAuthenticated) {
        if (kDebugMode) {
          print('⚠️ Cannot purchase streak reviver: User not authenticated');
        }
        _setError('You must be logged in to purchase items');
        return false;
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

  /// Use a streak reviver to restore a lost streak
  Future<Map<String, dynamic>?> useStreakReviver() async {
    if (!StoreBusinessRules.hasStreakReviversAvailable(_streakRevivers)) {
      _setError('You don\'t have any streak revivers available');
      return null;
    }

    try {
      _setLoading(true);
      _setError(null);

      final userManager = UserManagerService.instance;
      if (!userManager.isAuthenticated) {
        _setError('You must be logged in to use a streak reviver');
        return null;
      }

      // Call the use-streak-reviver endpoint
      final response = await ApiService.shared.post(
        '/api/store/use-streak-reviver',
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        
        // Update local state
        if (data['store_items'] != null) {
          _streakRevivers = data['store_items']['streak_revivers'] ?? _streakRevivers;
          
          // ✅ Update active streak reviver date from store items
          _activeStreakReviver = StoreBusinessRules.parseDateSafely(
            data['store_items']['active_streak_reviver'],
          );
          
          // ✅ NEW: Update used revivers array from store items
          if (data['store_items']['used_revivers'] != null && data['store_items']['used_revivers'] is List) {
            _usedRevivers = [];
            for (var reviverDateStr in data['store_items']['used_revivers']) {
              try {
                _usedRevivers.add(DateTime.parse(reviverDateStr));
              } catch (e) {
                if (kDebugMode) {
                  print('❌ Error parsing reviver date $reviverDateStr: $e');
                }
              }
            }
          }
        }
        
        if (kDebugMode) {
          print('✅ Streak reviver used successfully!');
          print('   ${data['message']}');
          print('   Remaining streak revivers: $_streakRevivers');
          print('   Active streak reviver: $_activeStreakReviver');
          print('   Total used revivers: ${_usedRevivers.length}');
        }
        
        notifyListeners();
        return data;
      } else {
        throw Exception(response.error ?? 'Failed to use streak reviver');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error using streak reviver: $e');
      }
      _setError(e.toString().replaceAll('Exception: ', ''));
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Use a streak freeze to protect today's streak
  Future<Map<String, dynamic>?> useStreakFreeze() async {
    if (!StoreBusinessRules.hasStreakFreezesAvailable(_streakFreezes)) {
      _setError('You don\'t have any streak freezes available');
      return null;
    }

    try {
      _setLoading(true);
      _setError(null);

      final userManager = UserManagerService.instance;
      if (!userManager.isAuthenticated) {
        _setError('You must be logged in to use a streak freeze');
        return null;
      }

      // Call the use-streak-freeze endpoint
      final response = await ApiService.shared.post(
        '/api/store/use-streak-freeze',
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        
        // Update local state
        if (data['store_items'] != null) {
          _streakFreezes = data['store_items']['streak_freezes'] ?? _streakFreezes;
          
          // ✅ Update active freeze date from store items
          _activeFreezeDate = StoreBusinessRules.parseDateSafely(
            data['store_items']['active_freeze_date'],
          );
          
          // ✅ NEW: Update used freezes array from store items
          if (data['store_items']['used_freezes'] != null && data['store_items']['used_freezes'] is List) {
            _usedFreezes = [];
            for (var freezeDateStr in data['store_items']['used_freezes']) {
              try {
                _usedFreezes.add(DateTime.parse(freezeDateStr));
              } catch (e) {
                if (kDebugMode) {
                  print('❌ Error parsing freeze date $freezeDateStr: $e');
                }
              }
            }
          }
        }
        
        if (kDebugMode) {
          print('✅ Streak freeze used successfully!');
          print('   ${data['message']}');
          print('   Remaining streak freezes: $_streakFreezes');
          print('   Active freeze date: $_activeFreezeDate');
          print('   Total used freezes: ${_usedFreezes.length}');
        }
        
        notifyListeners();
        return data;
      } else {
        throw Exception(response.error ?? 'Failed to use streak freeze');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error using streak freeze: $e');
      }
      _setError(e.toString().replaceAll('Exception: ', ''));
      return null;
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

  /// Grant treats to user based on reward type (centralized function)
  /// This is the single source of truth for granting treats for any action
  Future<bool> grantTreatsReward(TreatRewardType rewardType) async {
    final amount = StoreBusinessRules.getTreatRewardAmount(rewardType);
    return await addTreatsReward(amount);
  }

  /// Verify a treat purchase with the backend and grant treats
  /// 
  /// This method sends purchase information to the backend, which verifies it
  /// via RevenueCat webhook before granting treats. This prevents fraud.
  Future<bool> verifyAndGrantTreatPurchase({
    required String productId,
    required String packageIdentifier,
    required int treatAmount,
    required CustomerInfo customerInfo,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final userManager = UserManagerService.instance;
      if (!userManager.isAuthenticated) {
        if (kDebugMode) {
          print('⚠️ Cannot verify purchase: User not authenticated');
        }
        throw Exception('User must be authenticated to verify purchases');
      }

      // Extract transaction information from CustomerInfo
      // nonSubscriptionTransactions is a List<StoreTransaction>
      final nonSubscriptionTransactions = customerInfo.nonSubscriptionTransactions;
      
      // Find the transaction for this product
      StoreTransaction? transaction;
      
      // Iterate through transactions to find matching product
      for (final tx in nonSubscriptionTransactions) {
        if (tx.productIdentifier == productId) {
          transaction = tx;
          break;
        }
      }
      
      // Fallback: use most recent transaction if product-specific one not found
      if (transaction == null && nonSubscriptionTransactions.isNotEmpty) {
        transaction = nonSubscriptionTransactions.last;
        if (kDebugMode) {
          print('⚠️ No transaction found for product: $productId');
          print('📝 Using most recent transaction: ${transaction.productIdentifier}');
        }
      }

      if (transaction == null) {
        throw Exception('No transaction found for purchase verification');
      }

      // Send purchase verification to backend
      // StoreTransaction properties: transactionIdentifier, productIdentifier, purchaseDate
      final purchaseDate = transaction.purchaseDate;
      // purchaseDate can be DateTime or String depending on RevenueCat SDK version
      final purchaseDateString = purchaseDate is DateTime 
          ? (purchaseDate as DateTime).toIso8601String() 
          : purchaseDate.toString();
      
      final response = await ApiService.shared.post(
        '/api/store/verify-treat-purchase',
        body: {
          'product_id': productId,
          'package_identifier': packageIdentifier,
          'treat_amount': treatAmount,
          'transaction_id': transaction.transactionIdentifier,
          'original_transaction_id': transaction.transactionIdentifier, // Use same ID if original not available
          'purchase_date': purchaseDateString,
          'revenue_cat_user_id': customerInfo.originalAppUserId,
          'platform': Platform.isIOS ? 'ios' : 'android', // Use Platform instead of transaction.store
        },
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        
        // Update local state with verified treats
        if (data['treats'] != null) {
          _treats = data['treats'] as int;
        }
        
        if (kDebugMode) {
          print('✅ Purchase verified and treats granted');
          print('   Product: $productId');
          print('   Transaction: ${transaction.transactionIdentifier}');
          print('   Treats granted: $treatAmount');
          print('   New total: $_treats');
        }
        
        notifyListeners();
        return true;
      } else {
        throw Exception('Purchase verification failed: ${response.error ?? 'Unknown error'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error verifying purchase: $e');
      }
      _setError('Failed to verify purchase: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Add treats as a reward (for ads, achievements, etc.)
  /// Use grantTreatsReward() for standard reward types, or this for custom amounts
  /// 
  /// NOTE: This method should NOT be used for purchases - use verifyAndGrantTreatPurchase instead
  Future<bool> addTreatsReward(int amount) async {
    try {
      _setLoading(true);
      _setError(null);

      final userManager = UserManagerService.instance;
      // Require authentication - no bypasses in production
      if (!userManager.isAuthenticated) {
        if (kDebugMode) {
          print('⚠️ Cannot add treats reward: User not authenticated');
        }
        _setError('You must be logged in to receive rewards');
        return false;
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
      // DO NOT fallback to local update - this prevents fraud
      // If API fails, the operation should fail
      _setError('Failed to add treats: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Debug method to add treats (only works in debug mode)
  /// 
  /// ⚠️ SECURITY: This method only works in debug mode and requires authentication
  /// In production builds, this method does nothing
  Future<void> addDebugTreats(int amount) async {
    if (!kDebugMode) {
      // Do nothing in release builds
      if (kDebugMode) {
        print('⚠️ addDebugTreats: Only available in debug mode');
      }
      return;
    }
    
    try {
      _setLoading(true);
      _setError(null);

      final userManager = UserManagerService.instance;
      // Even in debug mode, require authentication for security
      if (!userManager.isAuthenticated) {
        if (kDebugMode) {
          print('⚠️ DEBUG: Cannot add treats - user not authenticated');
        }
        _setError('Debug treats require authentication');
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
      // DO NOT fallback to local update - this prevents fraud
      // If API fails, the operation should fail
      _setError('Failed to add debug treats: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
}

