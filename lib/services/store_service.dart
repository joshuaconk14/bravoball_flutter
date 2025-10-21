import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/user_manager_service.dart';

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


}
