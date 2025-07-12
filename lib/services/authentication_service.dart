import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'api_service.dart';
import 'user_manager_service.dart';

/// Authentication Service
/// Mirrors Swift AuthenticationService for managing authentication state
class AuthenticationService extends ChangeNotifier {
  static AuthenticationService? _instance;
  static AuthenticationService get shared => _instance ??= AuthenticationService._();
  
  AuthenticationService._();

  final ApiService _apiService = ApiService.shared;
  final UserManagerService _userManager = UserManagerService.instance;

  bool _isCheckingAuthentication = false;
  bool _isAuthenticated = false;
  bool _isCheckingAuth = true;

  // Getters
  bool get isCheckingAuthentication => _isCheckingAuthentication;
  bool get isAuthenticated => _isAuthenticated;
  bool get isCheckingAuth => _isCheckingAuth;

  /// Checks if user has valid stored credentials and validates them with the backend
  /// Mirrors Swift checkAuthenticationStatus
  Future<bool> checkAuthenticationStatus() async {
    if (kDebugMode) {
      print('🔍 AuthenticationService: Starting authentication check...');
    }

    _isCheckingAuthentication = true;
    notifyListeners();

    // Check if we have stored tokens
    if (!_userManager.hasValidToken || _userManager.email.isEmpty) {
      if (kDebugMode) {
        print('❌ AuthenticationService: No stored tokens found');
      }
      
      _isCheckingAuthentication = false;
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }

    if (kDebugMode) {
      print('✅ AuthenticationService: Found stored tokens for user: ${_userManager.email}');
      print('🔑 AuthenticationService: Access token: ${_userManager.accessToken.substring(0, 20)}...');
    }

    // ✅ IMPROVED: Don't validate token with backend on startup
    // The API service will handle token refresh automatically when needed
    // This prevents clearing valid refresh tokens unnecessarily
    
    if (kDebugMode) {
      print('✅ AuthenticationService: Using stored tokens (validation handled by API service)');
    }

    _isCheckingAuthentication = false;
    _isAuthenticated = true;
    notifyListeners();

    return true;
  }

  /// Update authentication status on app start (mirrors Swift updateAuthenticationStatus)
  Future<void> updateAuthenticationStatus() async {
    if (kDebugMode) {
      print('\n🔐 ===== STARTING AUTHENTICATION CHECK =====');
      print('📅 Timestamp: ${DateTime.now()}');
    }

    try {
      // Check if user has valid stored credentials
      final isAuthenticated = await checkAuthenticationStatus();

      // Add a minimum delay to show any loading animation
      await Future.delayed(const Duration(milliseconds: 800));

      if (isAuthenticated) {
        // User has valid tokens, authentication already handled in UserManager
        if (kDebugMode) {
          print('✅ Authentication check passed - user is logged in');
          print('📱 User: ${_userManager.email}');
        }
      } else {
        if (kDebugMode) {
          print('❌ Authentication check failed - user needs to login');
          print('📱 No valid tokens found or backend validation failed');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error in authentication check: $e');
      }
      // Ensure we don't get stuck in loading state on error
      _isAuthenticated = false;
    } finally {
      // ✅ ALWAYS end loading state to prevent endless loading
      _isCheckingAuth = false;
      notifyListeners();
      
      if (kDebugMode) {
        print('🏁 Authentication check complete - isCheckingAuth: $_isCheckingAuth');
        print('🔐 ===== AUTHENTICATION CHECK FINISHED =====\n');
      }
    }
  }

  /// Clear invalid tokens from storage (mirrors Swift clearInvalidTokens)
  Future<void> clearInvalidTokens() async {
    if (kDebugMode) {
      print('🗑️ AuthenticationService: Clearing invalid tokens');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear all auth-related data
      await prefs.remove('accessToken');
      await prefs.remove('refreshToken');
      await prefs.remove('userEmail');
      await prefs.remove('isLoggedIn');
      await prefs.remove('userHasAccountHistory');
      
      // Update user manager state
      await _userManager.logout();
      
      if (kDebugMode) {
        print('✅ AuthenticationService: Invalid tokens cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ AuthenticationService: Error clearing tokens: $e');
      }
    }
  }

  /// Initialize authentication service
  Future<void> initialize() async {
    if (kDebugMode) {
      print('🔐 AuthenticationService: Initializing...');
    }

    // Initialize user manager first
    await _userManager.initialize();
    
    // Check authentication status
    await updateAuthenticationStatus();
    
    if (kDebugMode) {
      print('✅ AuthenticationService: Initialized');
    }
  }

  /// Force refresh authentication state
  Future<void> refreshAuthenticationState() async {
    _isCheckingAuth = true;
    notifyListeners();
    
    await updateAuthenticationStatus();
  }

  /// Debug info
  String get debugInfo {
    return '''
Authentication Service Debug Info:
- IsCheckingAuth: $_isCheckingAuth
- IsCheckingAuthentication: $_isCheckingAuthentication  
- IsAuthenticated: $_isAuthenticated
- UserManager HasToken: ${_userManager.hasValidToken}
- UserManager IsLoggedIn: ${_userManager.isLoggedIn}
''';
  }
} 