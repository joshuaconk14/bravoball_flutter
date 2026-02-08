import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceSecurityUtils {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  /// Check if device is compromised (jailbroken/rooted)
  static Future<bool> isDeviceCompromised() async {
    try {
      if (Platform.isAndroid) {
        return await _isAndroidCompromised();
      } else if (Platform.isIOS) {
        return await _isIOSCompromised();
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking device security: $e');
      }
      return false; // Default to safe on error
    }
  }
  
  /// Check Android device for root
  static Future<bool> _isAndroidCompromised() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      
      // Check for root indicators
      final buildTags = androidInfo.tags ?? '';
      final buildFingerprint = androidInfo.fingerprint ?? '';
      
      // Common root indicators
      final rootIndicators = [
        'test-keys',
        'debug',
        'su',
        'magisk',
        'supersu',
        'kingroot',
        'oneclickroot',
      ];
      
      for (final indicator in rootIndicators) {
        if (buildTags.toLowerCase().contains(indicator) ||
            buildFingerprint.toLowerCase().contains(indicator)) {
          if (kDebugMode) {
            print('⚠️ Root indicator found: $indicator');
          }
          return true;
        }
      }
      
      // Check for common root apps
      final isRooted = await _checkForRootApps();
      if (isRooted) {
        if (kDebugMode) {
          print('⚠️ Root apps detected');
        }
        return true;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking Android security: $e');
      }
      return false;
    }
  }
  
  /// Check iOS device for jailbreak
  static Future<bool> _isIOSCompromised() async {
    try {
      final iosInfo = await _deviceInfo.iosInfo;
      
      // Check for jailbreak indicators
      final systemName = iosInfo.systemName ?? '';
      final systemVersion = iosInfo.systemVersion ?? '';
      
      // Common jailbreak indicators
      if (systemName.toLowerCase().contains('jailbreak') ||
          systemVersion.toLowerCase().contains('jailbreak')) {
        if (kDebugMode) {
          print('⚠️ Jailbreak indicator found in system info');
        }
        return true;
      }
      
      // Check for common jailbreak apps
      final isJailbroken = await _checkForJailbreakApps();
      if (isJailbroken) {
        if (kDebugMode) {
          print('⚠️ Jailbreak apps detected');
        }
        return true;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking iOS security: $e');
      }
      return false;
    }
  }
  
  /// Check for common root apps on Android
  static Future<bool> _checkForRootApps() async {
    try {
      // This is a simplified check - in production you'd want more sophisticated detection
      final commonRootApps = [
        'com.noshufou.android.su',
        'com.thirdparty.superuser',
        'eu.chainfire.supersu',
        'com.topjohnwu.magisk',
        'com.kingroot.kinguser',
        'com.saurik.substrate',
      ];
      
      // For now, return false - implement actual app checking logic
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Check for common jailbreak apps on iOS
  static Future<bool> _checkForJailbreakApps() async {
    try {
      // This is a simplified check - in production you'd want more sophisticated detection
      final commonJailbreakApps = [
        'Cydia',
        'Sileo',
        'Zebra',
        'Installer',
        'Sileo',
      ];
      
      // For now, return false - implement actual app checking logic
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Get device information for fingerprinting
  static Future<String> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.brand}_${androidInfo.model}_${androidInfo.version.release}_${androidInfo.id}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return '${iosInfo.name}_${iosInfo.model}_${iosInfo.systemVersion}_${iosInfo.identifierForVendor}';
      }
      return 'unknown_device';
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting device info: $e');
      }
      return 'unknown_device';
    }
  }
  
  /// Get app package info
  static Future<String> getAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.appName}_${packageInfo.version}_${packageInfo.buildNumber}';
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting app info: $e');
      }
      return 'unknown_app';
    }
  }
  
  /// Check if app is running in debug mode
  static bool get isDebugMode => kDebugMode;
  
  /// Check if app is running in release mode
  static bool get isReleaseMode => !kDebugMode;
  
  /// Get comprehensive device fingerprint
  static Future<String> getDeviceFingerprint() async {
    try {
      final deviceInfo = await getDeviceInfo();
      final appInfo = await getAppInfo();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      return '${deviceInfo}_${appInfo}_$timestamp';
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating device fingerprint: $e');
      }
      return 'unknown_fingerprint';
    }
  }
}
