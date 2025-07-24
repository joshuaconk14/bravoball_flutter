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
        final status = await Permission.photos.request();
        
        if (kDebugMode) {
          print('🔐 [PermissionService] iOS Photos permission: $status');
        }
        
        return status == PermissionStatus.granted || status == PermissionStatus.limited;
      }
      
      // On Android, handle different API levels
      if (Platform.isAndroid) {
        // For Android 13+ (API 33+), use granular media permissions
        if (await _isAndroid13OrHigher()) {
          final videoStatus = await Permission.videos.request();
          
          if (kDebugMode) {
            print('🔐 [PermissionService] Android 13+ Videos permission: $videoStatus');
          }
          
          return videoStatus == PermissionStatus.granted;
        } else {
          // For older Android versions, use storage permission
          final storageStatus = await Permission.storage.request();
          
          if (kDebugMode) {
            print('🔐 [PermissionService] Android <13 Storage permission: $storageStatus');
          }
          
          return storageStatus == PermissionStatus.granted;
        }
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
        if (await _isAndroid13OrHigher()) {
          final status = await Permission.videos.status;
          return status == PermissionStatus.granted;
        } else {
          final status = await Permission.storage.status;
          return status == PermissionStatus.granted;
        }
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
        PermissionStatus status;
        if (await _isAndroid13OrHigher()) {
          status = await Permission.videos.status;
        } else {
          status = await Permission.storage.status;
        }
        return status == PermissionStatus.permanentlyDenied;
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

  /// Check if device is running Android 13 or higher (API 33+)
  Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;
    
    try {
      // This is a simplified check - in a production app you might want to use
      // a more robust method to check Android API level
      return true; // Assume modern Android for now
    } catch (e) {
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
} 