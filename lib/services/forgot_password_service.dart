import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import '../models/forgot_password_model.dart';
import '../models/api_response_models.dart';

class ForgotPasswordService {
  static final ForgotPasswordService _instance = ForgotPasswordService._internal();
  factory ForgotPasswordService() => _instance;
  ForgotPasswordService._internal();

  static ForgotPasswordService get shared => _instance;

  final ApiService _apiService = ApiService.shared;

  /// Check if email exists in the system
  Map<String, dynamic>? _asMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is String) return jsonDecode(data) as Map<String, dynamic>;
  return null;
}

Future<bool> checkEmailExists(String email, ForgotPasswordModel forgotPasswordModel) async {
  try {
    final response = await _apiService.post(
      '/check-existing-email/',
      body: {'email': email},
    );
    print('DEBUG: status=${response.statusCode}, data=${response.data}, type=${response.data.runtimeType}');
    if (response.isSuccess && response.data != null) {
      final data = _asMap(response.data);
      print('DEBUG: decoded data=$data');
      final exists = data?['exists'];
      print('DEBUG: exists=$exists');
      return exists == true;
    }
    return false;
  } catch (e) {
    if (kDebugMode) {
      print('Error checking email existence: $e');
    }
    return false;
  }
}

  /// Send forgot password email with verification code
  Future<void> sendForgotPassword(String email, ForgotPasswordModel forgotPasswordModel) async {
    forgotPasswordModel.forgotPasswordMessage = '';

    // First check if email exists
    final emailExists = await checkEmailExists(email, forgotPasswordModel);
    if (!emailExists) {
      forgotPasswordModel.forgotPasswordMessage = "Email not found. Please check your email address.";
      return;
    }

    try {
      final response = await _apiService.post(
        '/forgot-password/',
        body: {'email': email},
      );

      if (response.isSuccess && response.data != null) {
        forgotPasswordModel.forgotPasswordEmail = email;
        forgotPasswordModel.forgotPasswordStep = 2;
        forgotPasswordModel.forgotPasswordMessage = "Verification code sent to your email.";
      } else {
        final errorMessage = response.data?['message'] ?? response.error ?? 'Unknown error';
        forgotPasswordModel.forgotPasswordMessage = "Failed to send code: $errorMessage";
      }
    } catch (e) {
      forgotPasswordModel.forgotPasswordMessage = "Network error. Please try again.";
      if (kDebugMode) {
        print('Error sending forgot password: $e');
      }
    }
  }

  /// Verify the reset code
  Future<void> verifyResetCode(String code, ForgotPasswordModel forgotPasswordModel) async {
    forgotPasswordModel.forgotPasswordMessage = '';

    try {
      final response = await _apiService.post(
        '/verify-reset-code/',
        body: {
          'email': forgotPasswordModel.forgotPasswordEmail,
          'code': code,
        },
      );

      if (response.isSuccess && response.data != null) {
        forgotPasswordModel.forgotPasswordCode = code;
        // Clear password fields before moving to step 3
        forgotPasswordModel.forgotPasswordNewPassword = '';
        forgotPasswordModel.forgotPasswordConfirmPassword = '';
        forgotPasswordModel.forgotPasswordStep = 3;
        forgotPasswordModel.forgotPasswordMessage = "Code verified successfully.";
      } else {
        forgotPasswordModel.forgotPasswordMessage = "Invalid or expired code. Please try again.";
      }
    } catch (e) {
      forgotPasswordModel.forgotPasswordMessage = "Network error. Please try again.";
      if (kDebugMode) {
        print('Error verifying reset code: $e');
      }
    }
  }

  /// Reset password with new password
  Future<void> resetPassword(
    String newPassword,
    String confirmPassword,
    ForgotPasswordModel forgotPasswordModel, {
    VoidCallback? onSuccess,
  }) async {
    forgotPasswordModel.forgotPasswordMessage = '';

    // Validate passwords
    if (newPassword != confirmPassword) {
      forgotPasswordModel.forgotPasswordMessage = "Passwords do not match.";
      return;
    }

    // Validate password strength (you can add your own validation logic here)
    if (newPassword.length < 8) {
      forgotPasswordModel.forgotPasswordMessage = "Password must be at least 8 characters long.";
      return;
    }

    try {
      final response = await _apiService.post(
        '/reset-password/',
        body: {
          'email': forgotPasswordModel.forgotPasswordEmail,
          'code': forgotPasswordModel.forgotPasswordCode,
          'new_password': newPassword,
        },
      );

      if (response.isSuccess && response.data != null) {
        forgotPasswordModel.forgotPasswordMessage = "Password reset successfully!";
        // Reset all forgot password state
        forgotPasswordModel.resetForgotPasswordState();
        // Call success callback to navigate back to login
        onSuccess?.call();
      } else {
        final errorMessage = response.data?['message'] ?? response.error ?? 'Unknown error';
        forgotPasswordModel.forgotPasswordMessage = "Failed to reset password: $errorMessage";
      }
    } catch (e) {
      forgotPasswordModel.forgotPasswordMessage = "Network error. Please try again.";
      if (kDebugMode) {
        print('Error resetting password: $e');
      }
    }
  }
} 