import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
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

      final response = await http.get(
        Uri.parse(AppConfig.apiUrl('/api/store/items')),
        headers: {
          'Authorization': 'Bearer ${userManager.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
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
        throw Exception('Failed to fetch store items: ${response.statusCode}');
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
      final incrementResponse = await http.post(
        Uri.parse(AppConfig.apiUrl('/api/store/items/increment')),
        headers: {
          'Authorization': 'Bearer ${userManager.accessToken}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'streak_freezes': 1,
        }),
      );

      if (incrementResponse.statusCode != 200) {
        throw Exception('Failed to increment streak freezes: ${incrementResponse.statusCode}');
      }

      // Step 2: Decrement treats
      final decrementResponse = await http.post(
        Uri.parse(AppConfig.apiUrl('/api/store/items/decrement')),
        headers: {
          'Authorization': 'Bearer ${userManager.accessToken}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'treats': requiredTreats,
        }),
      );

      if (decrementResponse.statusCode == 200) {
        final data = json.decode(decrementResponse.body);
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
        throw Exception('Failed to decrement treats: ${decrementResponse.statusCode}');
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
      final incrementResponse = await http.post(
        Uri.parse(AppConfig.apiUrl('/api/store/items/increment')),
        headers: {
          'Authorization': 'Bearer ${userManager.accessToken}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'streak_revivers': 1,
        }),
      );

      if (incrementResponse.statusCode != 200) {
        throw Exception('Failed to increment streak revivers: ${incrementResponse.statusCode}');
      }

      // Step 2: Decrement treats
      final decrementResponse = await http.post(
        Uri.parse(AppConfig.apiUrl('/api/store/items/decrement')),
        headers: {
          'Authorization': 'Bearer ${userManager.accessToken}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'treats': requiredTreats,
        }),
      );

      if (decrementResponse.statusCode == 200) {
        final data = json.decode(decrementResponse.body);
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
        throw Exception('Failed to decrement treats: ${decrementResponse.statusCode}');
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
        final response = await http.post(
          Uri.parse(AppConfig.apiUrl('/api/store/items/increment')),
          headers: {
            'Authorization': 'Bearer ${userManager.accessToken}',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'treats': amount,
          }),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _treats = data['treats'] ?? _treats + amount;
          
          if (kDebugMode) {
            print('🐛 DEBUG: Added $amount treats via API. New total: $_treats');
          }
          
          notifyListeners();
        } else {
          throw Exception('Failed to update treats: ${response.statusCode}');
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
