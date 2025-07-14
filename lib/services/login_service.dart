import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/auth_models.dart';
import '../models/login_state_model.dart';
import 'api_service.dart';
import 'user_manager_service.dart';
import 'authentication_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_state_service.dart';

/// Login Service
/// Mirrors Swift LoginService for handling authentication API calls
class LoginService {
  static LoginService? _instance;
  static LoginService get shared => _instance ??= LoginService._();
  
  LoginService._();

  final ApiService _apiService = ApiService.shared;
  final UserManagerService _userManager = UserManagerService.instance;

  /// Login user with email and password (mirrors Swift loginUser)
  Future<bool> loginUser({
    required LoginStateModel loginModel,
  }) async {
    // Validate inputs
    if (loginModel.email.isEmpty || loginModel.password.isEmpty) {
      loginModel.setErrorMessage('Please fill in all fields.');
      return false;
    }

    if (!loginModel.isEmailValid) {
      loginModel.setErrorMessage('Please enter a valid email address.');
      return false;
    }

    if (kDebugMode) {
      print('🔐 LoginService: Attempting login for ${loginModel.email}');
    }

    loginModel.setLoading(true);
    loginModel.clearError();

    try {
      // Create login request
      final loginRequest = LoginRequest(
        email: loginModel.email,
        password: loginModel.password,
      );

      // Make API call to login endpoint
      final response = await _apiService.post(
        '/login/',
        body: loginRequest.toJson(),
        requiresAuth: false, // Login doesn't require auth
      );

      if (response.isSuccess && response.data != null) {
        // Parse login response
        final loginResponse = LoginResponse.fromJson(response.data!);
        
        if (kDebugMode) {
          print('✅ LoginService: Login successful for ${loginResponse.email}');
          print('🔑 Access token received: ${loginResponse.accessToken.substring(0, 20)}...');
        }

        // Update user manager with new auth data
        await _userManager.updateUserData(
          email: loginResponse.email,
          accessToken: loginResponse.accessToken,
          refreshToken: loginResponse.refreshToken,
        );

        // Reset login form
        loginModel.resetLoginInfo();
        
        return true;
        
      } else {
        // Handle API errors
        String errorMessage = 'Failed to login. Please try again.';
        
        // ✅ IMPROVED: Use specific backend error messages when available
        if (response.error != null) {
          errorMessage = response.error!;
        } else if (response.statusCode == 401) {
          errorMessage = 'Invalid credentials, please try again.';
        } else if (response.statusCode == 400) {
          errorMessage = 'Invalid request. Please check your information.';
        } else if (response.statusCode == 429) {
          errorMessage = 'Too many login attempts. Please wait before trying again.';
        } else if (response.statusCode == 500) {
          errorMessage = 'Server error. Please try again later.';
        }
        
        loginModel.setErrorMessage(errorMessage);
        
        if (kDebugMode) {
          print('❌ LoginService: Login failed - ${response.statusCode}: ${response.error}');
        }
        
        return false;
      }
      
    } catch (e) {
      String errorMessage = 'Network error. Please try again.';
      
      if (e.toString().contains('timeout') || e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timed out. Please check your connection.';
      }
      
      loginModel.setErrorMessage(errorMessage);
      
      if (kDebugMode) {
        print('❌ LoginService: Login error - $e');
      }
      
      return false;
      
    } finally {
      loginModel.setLoading(false);
    }
  }

  /// Check if email exists in system (mirrors Swift email check)
  Future<EmailCheckResponse?> checkEmailExists(String email) async {
    if (email.isEmpty) return null;

    try {
      if (kDebugMode) {
        print('📧 LoginService: Checking email existence for $email');
      }

      final emailRequest = EmailCheckRequest(email: email);
      
      final response = await _apiService.post(
        '/check-existing-email/',
        body: emailRequest.toJson(),
        requiresAuth: false,
      );

      if (response.isSuccess && response.data != null) {
        final emailResponse = EmailCheckResponse.fromJson(response.data!);
        
        if (kDebugMode) {
          print('✅ LoginService: Email check result - exists: ${emailResponse.exists}');
        }
        
        return emailResponse;
      } else {
        if (kDebugMode) {
          print('❌ LoginService: Email check failed - ${response.error}');
        }
        return null;
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ LoginService: Email check error - $e');
      }
      return null;
    }
  }

  /// Check if email is available for registration
  Future<EmailCheckResponse?> checkEmailIsNew(String email) async {
    if (email.isEmpty) return null;

    try {
      if (kDebugMode) {
        print('📧 LoginService: Checking email availability for $email');
      }

      final emailRequest = EmailCheckRequest(email: email);
      
      final response = await _apiService.post(
        '/check-unique-email/',
        body: emailRequest.toJson(),
        requiresAuth: false,
      );

      if (response.isSuccess && response.data != null) {
        final emailResponse = EmailCheckResponse.fromJson(response.data!);
        
        if (kDebugMode) {
          print('✅ LoginService: Email availability result - exists: ${emailResponse.exists}');
        }
        
        return emailResponse;
      } else {
        if (kDebugMode) {
          print('❌ LoginService: Email availability check failed - ${response.error}');
        }
        return null;
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ LoginService: Email availability check error - $e');
      }
      return null;
    }
  }

  /// Logout user and clear all auth data
  Future<void> logoutUser() async {
    if (kDebugMode) {
      print('🚪 LoginService: Logging out user');
    }

    // ✅ FORCE RESET: Clear any lingering session state that might interfere with navigation
    final appState = AppStateService.instance;
    appState.clearUserData();
    
    // Clear user data
    await _userManager.logout();
    
    // Clear any cached auth state
    await AuthenticationService.shared.clearInvalidTokens();
    
    if (kDebugMode) {
      print('✅ LoginService: User logged out successfully');
    }
  }

  /// Delete user account and clear all data (mirrors Swift deleteAccount)
  Future<bool> deleteAccount() async {
    if (kDebugMode) {
      print('🗑️ LoginService: Deleting user account');
    }

    try {
      // Store email before clearing for logging
      final userEmail = _userManager.email;
      
      // ✅ FORCE RESET: Clear any lingering session state that might interfere with navigation
      final appState = AppStateService.instance;
      appState.clearUserData();
      
      // Make DELETE request to backend
      final response = await _apiService.delete(
        '/delete-account/',
        requiresAuth: true,
      );

      if (kDebugMode) {
        print('📥 Backend response status: ${response.statusCode}');
        if (response.data != null) {
          print('Response: ${response.data}');
        }
      }

      if (response.isSuccess) {
        // Clear all user data
        if (kDebugMode) {
          print('\n🗑️ Deleting account for user: $userEmail');
        }

        // 1. Clear user manager data
        await _userManager.logout();
        if (kDebugMode) {
          print('  ✓ Cleared user manager data');
        }

        // 2. Clear authentication service data
        await AuthenticationService.shared.clearInvalidTokens();
        if (kDebugMode) {
          print('  ✓ Cleared authentication data');
        }

        // 3. Clear shared preferences (equivalent to UserDefaults)
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (kDebugMode) {
          print('  ✓ Cleared shared preferences data');
        }

        if (kDebugMode) {
          print('✅ Account deleted and all data cleared successfully');
        }
        
        return true;
      } else {
        if (kDebugMode) {
          print('❌ Failed to delete account: ${response.statusCode}');
          print('Error: ${response.error}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting account: $e');
      }
      return false;
    }
  }
} 