import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/auth_models.dart';
import '../models/login_state_model.dart';
import 'api_service.dart';
import 'user_manager_service.dart';
import 'authentication_service.dart';
import 'loading_state_service.dart';
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
  final LoadingStateService _loadingService = LoadingStateService.instance;

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
      if (_userManager.isGuestMode) {
        print('👤 LoginService: User is in guest mode, will exit guest mode before login');
      }
    }

    loginModel.setLoading(true);
    loginModel.clearError();
    
    // Start loading with progress tracking
    _loadingService.startLoading(
      type: LoadingType.login,
      initialMessage: 'Signing you in...',
    );

    try {
      // ✅ CRITICAL FIX: Exit guest mode before authentication attempt
      if (_userManager.isGuestMode) {
        await _userManager.exitGuestMode();
        if (kDebugMode) {
          print('✅ LoginService: Exited guest mode before login attempt');
        }
      }
      
      // Create login request
      final loginRequest = LoginRequest(
        email: loginModel.email,
        password: loginModel.password,
      );

      // Update progress: validating credentials
      _loadingService.updateProgress(0.3, message: 'Validating credentials...');
      
      // Make API call to login endpoint
      final response = await _apiService.post(
        '/login/',
        body: loginRequest.toJson(),
        requiresAuth: false, // Login doesn't require auth
      );

      if (response.isSuccess && response.data != null) {
        // Update progress: connecting to server
        _loadingService.updateProgress(0.6, message: 'Connecting to server...');
        
        // Parse login response
        final loginResponse = LoginResponse.fromJson(response.data!);
        
        if (kDebugMode) {
          print('✅ LoginService: Login successful for ${loginResponse.email}');
          print('🔑 Access token received: ${loginResponse.accessToken.substring(0, 20)}...');
        }

        // Update progress: loading user data
        _loadingService.updateProgress(0.9, message: 'Loading your data...');
        
        // Update user manager with new auth data
        await _userManager.updateUserData(
          email: loginResponse.email,
          username: loginResponse.username,
          accessToken: loginResponse.accessToken,
          refreshToken: loginResponse.refreshToken,
          avatarPath: loginResponse.avatarPath,
          avatarBackgroundColor: loginResponse.avatarBackgroundColor,
        );

        // ✅ FIX: Load avatar from backend to ensure correct avatar (or default if none)
        // This ensures users without avatars get default avatar, not previous user's avatar
        await _userManager.loadAvatarFromBackend();

        // ✅ CRITICAL FIX: Handle authentication state transition 
        _loadingService.updateProgress(0.95, message: 'Setting up your account...');
        await AppStateService.instance.handleAuthenticationTransition();

        // Complete loading
        _loadingService.completeLoading();
        
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
      // Reset loading service on error
      if (_loadingService.isLoading) {
        _loadingService.reset();
      }
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
  Future<bool> logoutUser() async {
    if (kDebugMode) {
      print('🚪 LoginService: Logging out user');
    }

    try {
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
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ LoginService: Error during logout: $e');
      }
      return false;
    }
  }

  /// Delete user account and clear all data (mirrors Swift deleteAccount)
  Future<bool> deleteAccount() async {
    if (kDebugMode) {
      print('🗑️ LoginService: Deleting user account');
    }

    try {
      // ✅ STEP 1: Delete account on server FIRST (while we still have valid tokens)
      if (kDebugMode) {
        print('🌐 Deleting account on server first...');
      }
      
      final response = await _apiService.delete(
        '/delete-account/',
        requiresAuth: true,
      );

      if (kDebugMode) {
        print('📥 Server deletion response: ${response.statusCode}');
      }

      // ✅ STEP 2: Clear local data immediately regardless of server response
      // (Even if server deletion fails, we want user to be logged out locally)
      if (kDebugMode) {
        print('🧹 Clearing local user data...');
      }
      
      // Clear app state
      final appState = AppStateService.instance;
      appState.clearUserData();
      
      // Clear user manager data  
      await _userManager.logout();
      if (kDebugMode) {
        print('  ✓ Cleared user manager data');
      }

      // Clear authentication service data
      await AuthenticationService.shared.clearInvalidTokens();
      if (kDebugMode) {
        print('  ✓ Cleared authentication data');
      }

      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (kDebugMode) {
        print('  ✓ Cleared shared preferences data');
      }

      // Force clear any potential guest mode state
      if (_userManager.isGuestMode) {
        await _userManager.exitGuestMode();
        if (kDebugMode) {
          print('  ✓ Exited guest mode');
        }
      }

      if (kDebugMode) {
        if (response.isSuccess) {
          print('✅ Account successfully deleted on server and locally');
        } else {
          print('⚠️ Server deletion failed, but local data cleared successfully');
        }
        print('📱 User should now be directed to onboarding flow');
      }

      // Return success regardless of server response - user is logged out locally
      return true;
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error during account deletion: $e');
        print('🧹 Attempting to clear local data anyway...');
      }
      
      // Even if there's an error, try to clear local data so user isn't stuck
      try {
        final appState = AppStateService.instance;
        appState.clearUserData();
        await _userManager.logout();
        await AuthenticationService.shared.clearInvalidTokens();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        
        if (kDebugMode) {
          print('✅ Local data cleared despite error');
        }
      } catch (cleanupError) {
        if (kDebugMode) {
          print('❌ Local cleanup also failed: $cleanupError');
        }
      }
      
      // Still return true so user can navigate away
      return true;
    }
  }
}