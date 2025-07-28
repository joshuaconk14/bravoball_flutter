import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import '../models/email_verification_model.dart';
import 'user_manager_service.dart';

class EmailVerificationService {
  static final EmailVerificationService _instance = EmailVerificationService._internal();
  factory EmailVerificationService() => _instance;
  EmailVerificationService._internal();

  static EmailVerificationService get shared => _instance;

  final ApiService _apiService = ApiService.shared;
  final UserManagerService _userManager = UserManagerService.instance;

  /// Check if email is available for use
  Map<String, dynamic>? _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String) return jsonDecode(data) as Map<String, dynamic>;
    return null;
  }

  Future<bool> checkEmailAvailable(String email, EmailVerificationModel emailVerificationModel) async {
    try {
      final response = await _apiService.post(
        '/check-unique-email/',
        body: {'email': email},
      );
      
      if (response.isSuccess && response.data != null) {
        final data = _asMap(response.data);
        final exists = data?['exists'];
        return exists != true; // Return true if email is available (doesn't exist)
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking email availability: $e');
      }
      return false;
    }
  }

  /// Send email verification code for email update
  Future<void> sendEmailVerification(String newEmail, EmailVerificationModel emailVerificationModel) async {
    emailVerificationModel.emailVerificationMessage = '';

    // First check if email is available
    final emailAvailable = await checkEmailAvailable(newEmail, emailVerificationModel);
    if (!emailAvailable) {
      emailVerificationModel.emailVerificationMessage = "Email already registered. Please choose a different email address.";
      return;
    }

    try {
      final response = await _apiService.post(
        '/send-email-verification/',
        body: {'new_email': newEmail},
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        emailVerificationModel.newEmail = newEmail;
        emailVerificationModel.emailVerificationStep = 2;
        emailVerificationModel.emailVerificationMessage = "Verification code sent to your new email address.";
      } else {
        final errorMessage = response.data?['message'] ?? response.error ?? 'Unknown error';
        emailVerificationModel.emailVerificationMessage = "Failed to send verification code: $errorMessage";
      }
    } catch (e) {
      emailVerificationModel.emailVerificationMessage = "Network error. Please try again.";
      if (kDebugMode) {
        print('Error sending email verification: $e');
      }
    }
  }

  /// Verify the email verification code and update email
  Future<void> verifyEmailAndUpdate(String code, EmailVerificationModel emailVerificationModel, {VoidCallback? onSuccess}) async {
    emailVerificationModel.emailVerificationMessage = '';

    try {
      final response = await _apiService.post(
        '/verify-email-update/',
        body: {
          'new_email': emailVerificationModel.newEmail,
          'code': code,
        },
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        emailVerificationModel.emailVerificationMessage = "Email updated successfully!";
        
        // ✅ CRITICAL FIX: Update the user's email in UserManagerService BEFORE logout
        // This ensures the profile page shows the correct email even after token revocation
        if (kDebugMode) {
          print('📧 EmailVerificationService: Updating user email from ${_userManager.email} to ${emailVerificationModel.newEmail}');
        }
        
        // Update the email in user manager to the new email
        await _userManager.updateUserData(
          email: emailVerificationModel.newEmail,
          accessToken: _userManager.accessToken,
          refreshToken: _userManager.refreshToken,
        );
        
        if (kDebugMode) {
          print('✅ EmailVerificationService: User email updated successfully in UserManager');
        }
        
        emailVerificationModel.resetEmailVerificationState();
        onSuccess?.call();
      } else {
        emailVerificationModel.emailVerificationMessage = "Invalid or expired code. Please try again.";
      }
    } catch (e) {
      emailVerificationModel.emailVerificationMessage = "Network error. Please try again.";
      if (kDebugMode) {
        print('Error verifying email update: $e');
      }
    }
  }
} 