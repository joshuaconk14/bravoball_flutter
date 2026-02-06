import 'dart:convert';
import 'package:flutter/foundation.dart';
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

  /// Update username
  Future<bool> updateUsername(String newUsername) async {
    try {
      final response = await ApiService.shared.put(
        '/api/user/update-username',
        body: {
          'username': newUsername,
        },
        requiresAuth: true,
      );

      if (response.isSuccess) {
        return true;
      } else {
        throw Exception(response.error ?? 'Failed to update username');
      }
    } catch (e) {
      print('❌ ProfileService: Error updating username: $e');
      if (e.toString().contains('Username already taken')) {
        throw Exception('Username already taken');
      } else if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        throw Exception('Unauthorized - please log in again');
      } else {
        throw Exception('Failed to update username');
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

  /// Update user avatar and background color
  Future<bool> updateAvatar({
    required String avatarPath,
    required String backgroundColorHex,
  }) async {
    if (kDebugMode) {
      print('🖼️ ProfileService: Updating avatar to $avatarPath with background $backgroundColorHex');
    }

    try {
      final response = await ApiService.shared.put(
        '/api/user/update-avatar',
        body: {
          'avatar_path': avatarPath,
          'avatar_background_color': backgroundColorHex,
        },
        requiresAuth: true,
      );

      if (response.isSuccess) {
        if (kDebugMode) {
          print('✅ ProfileService: Avatar updated successfully');
        }
        return true;
      } else {
        throw Exception(response.error ?? 'Failed to update avatar');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ProfileService: Error updating avatar: $e');
      }
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        throw Exception('Unauthorized - please log in again');
      } else {
        throw Exception('Failed to update avatar');
      }
    }
  }

  /// Fetch user profile data including avatar from backend
  Future<Map<String, String?>?> fetchUserProfile() async {
    if (kDebugMode) {
      print('📥 ProfileService: Fetching user profile from backend');
    }

    try {
      final response = await ApiService.shared.get(
        '/api/user/profile',
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        
        // Handle wrapped response
        dynamic profileData = data;
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          profileData = data['data'];
        }
        
        final profileMap = profileData is Map<String, dynamic>
            ? profileData
            : <String, dynamic>{};
        
        final avatarPath = profileMap['avatar_path'] as String?;
        final avatarBackgroundColor = profileMap['avatar_background_color'] as String?;
        
        if (kDebugMode) {
          print('✅ ProfileService: User profile fetched successfully');
          if (avatarPath != null) {
            print('🖼️ Avatar path: $avatarPath');
          }
        }
        
        return {
          'avatar_path': avatarPath,
          'avatar_background_color': avatarBackgroundColor,
        };
      } else {
        if (kDebugMode) {
          print('❌ ProfileService: Failed to fetch profile - ${response.error}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ProfileService: Error fetching user profile: $e');
      }
      return null;
    }
  }
} 