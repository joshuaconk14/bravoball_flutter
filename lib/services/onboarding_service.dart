import 'package:flutter/foundation.dart';
import '../models/onboarding_model.dart';
import '../models/auth_models.dart';
import 'api_service.dart';
import 'user_manager_service.dart';

class OnboardingService {
  static OnboardingService? _instance;
  static OnboardingService get shared => _instance ??= OnboardingService._();
  OnboardingService._();

  final ApiService _apiService = ApiService.shared;
  final UserManagerService _userManager = UserManagerService.instance;

  /// Submits onboarding data to the backend and stores tokens
  Future<bool> submitOnboardingData(OnboardingData data, {ValueChanged<String>? onError}) async {
    try {
      if (kDebugMode) {
        print('📤 OnboardingService: Sending onboarding data: ${data.toJson()}');
      }
      final response = await _apiService.post(
        '/api/onboarding',
        body: data.toJson(),
        requiresAuth: false,
      );
      if (response.isSuccess && response.data != null) {
        // Parse tokens from response
        final accessToken = response.data!['access_token'] ?? '';
        final refreshToken = response.data!['refresh_token'] ?? '';
        final email = response.data!['email'] ?? data.email;
        if (accessToken.isNotEmpty) {
          await _userManager.updateUserData(
            email: email,
            accessToken: accessToken,
            refreshToken: refreshToken,
          );
          if (kDebugMode) {
            print('✅ OnboardingService: Registration successful, tokens saved.');
          }
          return true;
        } else {
          onError?.call('Registration succeeded but no token received.');
          return false;
        }
      } else {
        final errorMsg = response.error ?? 'Registration failed. Please try again.';
        onError?.call(errorMsg);
        if (kDebugMode) {
          print('❌ OnboardingService: Registration failed - $errorMsg');
        }
        return false;
      }
    } catch (e) {
      final errorMsg = 'Network error: $e';
      onError?.call(errorMsg);
      if (kDebugMode) {
        print('❌ OnboardingService: Registration error - $e');
      }
      return false;
    }
  }
} 