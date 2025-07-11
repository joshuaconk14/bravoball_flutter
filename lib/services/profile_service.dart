import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/api_service.dart';

class ProfileService {
  static final ProfileService shared = ProfileService._internal();
  ProfileService._internal();

  /// Update user email
  Future<bool> updateEmail(String newEmail) async {
    try {
      final response = await ApiService.shared.put(
        '/api/user/update-email',
        body: {
          'email': newEmail,
        },
        requiresAuth: true,
      );

      if (response.isSuccess) {
        return true;
      } else {
        throw Exception(response.error ?? 'Failed to update email');
      }
    } catch (e) {
      print('❌ ProfileService: Error updating email: $e');
      if (e.toString().contains('Email already registered')) {
        throw Exception('Email already registered');
      } else if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        throw Exception('Unauthorized - please log in again');
      } else {
        throw Exception('Failed to update email');
      }
    }
  }

  /// Update user password
  Future<bool> updatePassword(String currentPassword, String newPassword) async {
    try {
      final response = await ApiService.shared.put(
        '/api/user/update-password',
        body: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
        requiresAuth: true,
      );

      if (response.isSuccess) {
        return true;
      } else {
        throw Exception(response.error ?? 'Failed to update password');
      }
    } catch (e) {
      print('❌ ProfileService: Error updating password: $e');
      if (e.toString().contains('Current password is incorrect')) {
        throw Exception('Current password is incorrect');
      } else if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        throw Exception('Unauthorized - please log in again');
      } else {
        throw Exception('Failed to update password');
      }
    }
  }
} 