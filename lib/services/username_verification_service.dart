import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/user_manager_service.dart';
import '../utils/avatar_helper.dart'; // ✅ ADDED: Import AvatarHelper for color conversion

class UsernameVerificationService {
  static UsernameVerificationService? _instance;
  static UsernameVerificationService get shared => _instance ??= UsernameVerificationService._();

  UsernameVerificationService._();

  final ApiService _apiService = ApiService.shared;

  Future<bool> updateUsername(String newUsername, UserManagerService userManager) async {
    if (kDebugMode) {
      print('🔄 UsernameVerificationService: Attempting to update username to \$newUsername');
    }

    try {
      final response = await _apiService.put(
        '/api/user/update-username',
        body: {'username': newUsername},
        requiresAuth: true,
      );

      if (response.isSuccess) {
        if (kDebugMode) {
          print('✅ UsernameVerificationService: Username updated successfully on backend.');
        }
        // Update local user manager
        // Preserve existing avatar data
        await userManager.updateUserData(
          email: userManager.email,
          username: newUsername, 
          accessToken: userManager.accessToken,
          refreshToken: userManager.refreshToken,
          avatarPath: userManager.selectedAvatar,
          avatarBackgroundColor: userManager.avatarBackgroundColor != null
              ? AvatarHelper.colorToHex(userManager.avatarBackgroundColor!)
              : null,
        );
        return true;
      } else {
        if (kDebugMode) {
          print('❌ UsernameVerificationService: Failed to update username. \${response.error}');
        }
        throw Exception(response.error ?? 'Failed to update username.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ UsernameVerificationService: Error updating username: \$e');
      }
      rethrow;
    }
  }
}
