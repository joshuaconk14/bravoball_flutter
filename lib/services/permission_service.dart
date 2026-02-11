import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

/// Service for handling runtime permissions across platforms
/// Focuses on Android's granular permission system while maintaining iOS compatibility
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  static PermissionService get shared => _instance;

  /// Check and request photo library permissions for video picking
  /// Returns true if permission is granted, false otherwise
  Future<bool> requestPhotoLibraryPermission() async {
    try {
      if (kDebugMode) {
        print('🔐 [PermissionService] Checking photo library permissions...');
      }

      // On iOS, use photos permission
      if (Platform.isIOS) {
        // Check current status first
        final currentStatus = await Permission.photos.status;
        if (kDebugMode) {
          print('🔐 [PermissionService] Current iOS Photos permission status: $currentStatus');
        }
        
        // If already permanently denied, don't try to request again
        if (currentStatus == PermissionStatus.permanentlyDenied) {
          if (kDebugMode) {
            print('🔐 [PermissionService] iOS Photos permission permanently denied - cannot request again');
          }
          return false;
        }
        
        // If already granted or limited, return true
        if (currentStatus == PermissionStatus.granted || currentStatus == PermissionStatus.limited) {
          if (kDebugMode) {
            print('🔐 [PermissionService] iOS Photos permission already granted/limited');
          }
          return true;
        }
        
        // Request permission
        final status = await Permission.photos.request();
        
        if (kDebugMode) {
          print('🔐 [PermissionService] iOS Photos permission request result: $status');
        }
        
        return status == PermissionStatus.granted || status == PermissionStatus.limited;
      }
      
      // On Android, Photo Picker works on all versions without permissions
      // Android 13+: Native Photo Picker
      // Android ≤12: Photo Picker via Google Play Services backport
      if (Platform.isAndroid) {
        if (kDebugMode) {
          print('🔐 [PermissionService] Android: Photo Picker used, no permission needed');
        }
        return true; // Photo Picker doesn't require permissions on any Android version
      }
      
      // For other platforms, assume permission is granted
      return true;
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ [PermissionService] Error requesting photo library permission: $e');
      }
      return false;
    }
  }

  /// Check if current permission status allows photo library access
  Future<bool> hasPhotoLibraryPermission() async {
    try {
      if (Platform.isIOS) {
        final status = await Permission.photos.status;
        return status == PermissionStatus.granted || status == PermissionStatus.limited;
      }
      
      if (Platform.isAndroid) {
        // Photo Picker works on all Android versions without permissions
        return true;
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [PermissionService] Error checking photo library permission: $e');
      }
      return false;
    }
  }

  /// Check if the permission was permanently denied
  Future<bool> isPhotoLibraryPermissionPermanentlyDenied() async {
    try {
      if (Platform.isIOS) {
        final status = await Permission.photos.status;
        return status == PermissionStatus.permanentlyDenied;
      }
      
      if (Platform.isAndroid) {
        // Photo Picker doesn't have permanent denial concept (no permissions needed)
        return false;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [PermissionService] Error checking permanent denial: $e');
      }
      return false;
    }
  }

  /// Open app settings for permission management
  Future<bool> openPermissionSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      if (kDebugMode) {
        print('❌ [PermissionService] Error opening app settings: $e');
      }
      return false;
    }
  }

  /// Get user-friendly permission status message
  String getPermissionStatusMessage(bool hasPermission, bool isPermanentlyDenied) {
    if (hasPermission) {
      return 'Permission granted';
    } else if (isPermanentlyDenied) {
      if (Platform.isAndroid) {
        return 'Permission denied. Please enable photo/media access in Settings > Apps > BravoBall > Permissions.';
      } else {
        return 'Permission denied. Please enable photo library access in Settings > Privacy & Security > Photos.';
      }
    } else {
      return 'Permission required to select videos for custom drills.';
    }
  }

  /// Get detailed instructions for enabling photo library permissions
  String getDetailedPermissionInstructions() {
    if (Platform.isAndroid) {
      return '''To enable photo/media access:
1. Open your device Settings
2. Go to Apps or Application Manager
3. Find and tap "BravoBall" or "Bravoball Flutter"
4. Tap "Permissions"
5. Find "Photos and media" or "Storage" and enable it
6. Return to the app and try again''';
    } else {
      return '''To enable photo library access:
1. Open your device Settings
2. Scroll down and tap "Privacy & Security"
3. Tap "Photos"
4. Find "BravoBall" or "Bravoball Flutter" in the list
5. Select "All Photos" or "Selected Photos"
6. Return to the app and try again''';
    }
  }

  /// Check if we should show a detailed instruction dialog
  Future<bool> shouldShowDetailedInstructions() async {
    return await isPhotoLibraryPermissionPermanentlyDenied();
  }
} 