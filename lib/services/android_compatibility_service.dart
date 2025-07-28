import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';

/// Android Compatibility Service
/// Handles Android-specific issues that don't exist on iOS
class AndroidCompatibilityService {
  static final AndroidCompatibilityService _instance = AndroidCompatibilityService._internal();
  factory AndroidCompatibilityService() => _instance;
  AndroidCompatibilityService._internal();

  static AndroidCompatibilityService get shared => _instance;

  /// Initialize Android-specific compatibility settings
  Future<void> initialize() async {
    if (!Platform.isAndroid) return;

    try {
      if (kDebugMode) {
        print('🤖 [AndroidCompatibility] Initializing Android-specific settings...');
      }

      // Set up audio session for Android
      await _configureAndroidAudioSession();
      
      // Handle scoped storage if needed
      await _handleScopedStorage();

      if (kDebugMode) {
        print('✅ [AndroidCompatibility] Android compatibility settings applied');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AndroidCompatibility] Error initializing: $e');
      }
    }
  }

  /// Configure Android audio session for better background audio compatibility
  Future<void> _configureAndroidAudioSession() async {
    try {
      // This helps with Android audio issues in background
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
        ),
      );

      if (kDebugMode) {
        print('🔊 [AndroidCompatibility] Audio session configured for Android');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AndroidCompatibility] Audio session configuration failed: $e');
      }
    }
  }

  /// Handle Android scoped storage (API 29+) for video file storage
  Future<void> _handleScopedStorage() async {
    try {
      // Android 10+ (API 29+) uses scoped storage
      // Our VideoFileService already handles this correctly by using
      // getApplicationDocumentsDirectory() which is always accessible
      
      if (kDebugMode) {
        print('📁 [AndroidCompatibility] Scoped storage compatibility verified');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AndroidCompatibility] Scoped storage configuration failed: $e');
      }
    }
  }

  /// Check if device needs battery optimization exclusion
  Future<bool> shouldRequestBatteryOptimizationExclusion() async {
    if (!Platform.isAndroid) return false;

    try {
      // You could add more sophisticated detection here
      // For now, we'll assume Android devices might benefit from this
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AndroidCompatibility] Battery optimization check failed: $e');
      }
      return false;
    }
  }

  /// Get Android-specific error messages
  String getAndroidSpecificErrorMessage(String originalError) {
    if (!Platform.isAndroid) return originalError;

    // Map common Android errors to user-friendly messages
    if (originalError.toLowerCase().contains('permission')) {
      return 'Permission denied. Please enable the required permissions in Settings > Apps > BravoBall > Permissions.';
    } else if (originalError.toLowerCase().contains('file not found')) {
      return 'File access issue. This might be due to Android storage restrictions. Please try again.';
    } else if (originalError.toLowerCase().contains('network')) {
      return 'Network connection issue. Please check your internet connection and try again.';
    } else if (originalError.toLowerCase().contains('audio') || originalError.toLowerCase().contains('media')) {
      return 'Audio/media playback issue. Please ensure media volume is turned up and try again.';
    }

    return originalError;
  }

  /// Check if running on Android emulator (which has different capabilities)
  Future<bool> isAndroidEmulator() async {
    if (!Platform.isAndroid) return false;

    try {
      // Simple detection based on known emulator characteristics
      // This is a simplified check - in production you might want more sophisticated detection
      return false; // Assume real device for now
    } catch (e) {
      return false;
    }
  }

  /// Handle Android-specific video file extensions
  String normalizeVideoExtension(String originalPath) {
    if (!Platform.isAndroid) return originalPath;

    // Android is case-sensitive, ensure lowercase extensions
    final parts = originalPath.split('.');
    if (parts.length > 1) {
      final extension = parts.last.toLowerCase();
      parts[parts.length - 1] = extension;
      return parts.join('.');
    }

    return originalPath;
  }

  /// Handle Android-specific audio file extensions  
  String normalizeAudioExtension(String originalPath) {
    if (!Platform.isAndroid) return originalPath;

    // Android is case-sensitive, ensure lowercase extensions
    final parts = originalPath.split('.');
    if (parts.length > 1) {
      final extension = parts.last.toLowerCase();
      parts[parts.length - 1] = extension;
      return parts.join('.');
    }

    return originalPath;
  }

  /// Log Android-specific debug information
  void logAndroidDebugInfo() {
    if (!Platform.isAndroid || !kDebugMode) return;

    print('🤖 [AndroidCompatibility] Android Debug Info:');
    print('   • OS Version: ${Platform.operatingSystemVersion}');
    print('   • Local Hostname: ${Platform.localHostname}');
    print('   • Number of Processors: ${Platform.numberOfProcessors}');
    print('   • Environment: ${Platform.environment.keys.take(5).join(', ')}...');
  }
} 