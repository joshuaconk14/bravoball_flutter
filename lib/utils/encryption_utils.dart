import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Reusable encryption utilities for securing sensitive data
class EncryptionUtils {
  static const String _encryptionKeyKey = 'encryption_key';
  static const String _ivKey = 'encryption_iv';
  static const String _deviceFingerprintKey = 'device_fingerprint';
  
  // Cache for performance
  static encrypt.Encrypter? _cachedEncrypter;
  static encrypt.IV? _cachedIV;
  static String? _cachedDeviceFingerprint;

  /// Generate a secure encryption key
  static Future<encrypt.Key> _generateEncryptionKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? keyString = prefs.getString(_encryptionKeyKey);
      
      if (keyString == null) {
        // Generate new 32-byte (256-bit) key
        final random = Random.secure();
        final keyBytes = List<int>.generate(32, (i) => random.nextInt(256));
        keyString = base64Encode(keyBytes);
        
        // Store the key securely
        await prefs.setString(_encryptionKeyKey, keyString);
        
        if (kDebugMode) {
          print('🔐 Generated new encryption key');
        }
      }
      
      return encrypt.Key.fromBase64(keyString);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating encryption key: $e');
      }
      // Fallback to a default key (less secure but functional)
      return encrypt.Key.fromBase64('your-32-char-secret-key-here!!!!!!');
    }
  }

  /// Generate or retrieve the initialization vector (IV)
  static Future<encrypt.IV> _generateIV() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? ivString = prefs.getString(_ivKey);
      
      if (ivString == null) {
        // Generate new 16-byte IV
        final random = Random.secure();
        final ivBytes = List<int>.generate(16, (i) => random.nextInt(256));
        ivString = base64Encode(ivBytes);
        
        // Store the IV
        await prefs.setString(_ivKey, ivString);
        
        if (kDebugMode) {
          print('🔐 Generated new IV');
        }
      }
      
      return encrypt.IV.fromBase64(ivString);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating IV: $e');
      }
      // Fallback to a default IV
      return encrypt.IV.fromBase64('your-16-char-iv!!');
    }
  }

  /// Get cached or create new encrypter instance
  static Future<encrypt.Encrypter> _getEncrypter() async {
    if (_cachedEncrypter == null) {
      final key = await _generateEncryptionKey();
      final iv = await _generateIV();
      _cachedEncrypter = encrypt.Encrypter(encrypt.AES(key));
      _cachedIV = iv;
    }
    return _cachedEncrypter!;
  }

  /// Get cached IV
  static Future<encrypt.IV> _getIV() async {
    if (_cachedIV == null) {
      _cachedIV = await _generateIV();
    }
    return _cachedIV!;
  }

  /// Encrypt a string value
  static Future<String> encryptString(String value) async {
    try {
      final encrypter = await _getEncrypter();
      final iv = await _getIV();
      
      final encrypted = encrypter.encrypt(value, iv: iv);
      return encrypted.base64;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Encryption error: $e');
      }
      // Fallback: return original value (less secure but functional)
      return value;
    }
  }

  /// Decrypt an encrypted string
  static Future<String> decryptString(String encryptedValue) async {
    try {
      final encrypter = await _getEncrypter();
      final iv = await _getIV();
      
      final decrypted = encrypter.decrypt64(encryptedValue, iv: iv);
      return decrypted;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Decryption error: $e');
      }
      // Fallback: return encrypted value as-is
      return encryptedValue;
    }
  }

  /// Encrypt a map/object (convert to JSON first)
  static Future<String> encryptMap(Map<String, dynamic> data) async {
    try {
      final jsonString = jsonEncode(data);
      return await encryptString(jsonString);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error encrypting map: $e');
      }
      return jsonEncode(data); // Fallback to unencrypted
    }
  }

  /// Decrypt and parse a map/object
  static Future<Map<String, dynamic>?> decryptMap(String encryptedData) async {
    try {
      final decryptedString = await decryptString(encryptedData);
      return jsonDecode(decryptedString) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error decrypting map: $e');
      }
      return null;
    }
  }

  /// Generate a unique device fingerprint
  static Future<String> generateDeviceFingerprint() async {
    try {
      if (_cachedDeviceFingerprint != null) {
        return _cachedDeviceFingerprint!;
      }

      final prefs = await SharedPreferences.getInstance();
      String? fingerprint = prefs.getString(_deviceFingerprintKey);
      
      if (fingerprint == null) {
        // Generate new fingerprint
        final deviceInfo = await _getDeviceInfo();
        fingerprint = sha256.convert(utf8.encode(deviceInfo)).toString();
        
        // Store the fingerprint
        await prefs.setString(_deviceFingerprintKey, fingerprint);
        
        if (kDebugMode) {
          print('🔐 Generated new device fingerprint');
        }
      }
      
      _cachedDeviceFingerprint = fingerprint;
      return fingerprint;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating device fingerprint: $e');
      }
      // Fallback to a basic fingerprint
      return 'fallback_fingerprint_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Get comprehensive device information for fingerprinting
  static Future<String> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final List<String> deviceData = [];
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceData.addAll([
          androidInfo.brand,
          androidInfo.device,
          androidInfo.fingerprint,
          androidInfo.hardware,
          androidInfo.manufacturer,
          androidInfo.model,
          androidInfo.product,
          androidInfo.version.release,
          androidInfo.version.sdkInt.toString(),
        ]);
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceData.addAll([
          iosInfo.name,
          iosInfo.model,
          iosInfo.systemName,
          iosInfo.systemVersion,
          iosInfo.identifierForVendor ?? 'unknown',
        ]);
      }
      
      // Add app-specific identifiers
      final prefs = await SharedPreferences.getInstance();
      final installationId = prefs.getString('installation_id') ?? 
          DateTime.now().millisecondsSinceEpoch.toString();
      
      if (prefs.getString('installation_id') == null) {
        await prefs.setString('installation_id', installationId);
      }
      
      deviceData.add(installationId);
      
      // Add timestamp for uniqueness
      deviceData.add(DateTime.now().toIso8601String());
      
      return deviceData.where((item) => item != null && item.isNotEmpty).join('|');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting device info: $e');
      }
      // Fallback device info
      return 'fallback_device_${Platform.operatingSystem}_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Validate device fingerprint (check if it matches stored value)
  static Future<bool> validateDeviceFingerprint() async {
    try {
      final currentFingerprint = await generateDeviceFingerprint();
      final prefs = await SharedPreferences.getInstance();
      final storedFingerprint = prefs.getString(_deviceFingerprintKey);
      
      if (storedFingerprint == null) {
        // First time, store current fingerprint
        await prefs.setString(_deviceFingerprintKey, currentFingerprint);
        return true;
      }
      
      final isValid = currentFingerprint == storedFingerprint;
      
      if (kDebugMode) {
        print('🔐 Device fingerprint validation: ${isValid ? "✅ Valid" : "❌ Invalid"}');
      }
      
      return isValid;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error validating device fingerprint: $e');
      }
      return false;
    }
  }

  /// Clear all encryption data (for logout/security)
  static Future<void> clearEncryptionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_encryptionKeyKey);
      await prefs.remove(_ivKey);
      await prefs.remove(_deviceFingerprintKey);
      
      // Clear cache
      _cachedEncrypter = null;
      _cachedIV = null;
      _cachedDeviceFingerprint = null;
      
      if (kDebugMode) {
        print('🗑️ Encryption data cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing encryption data: $e');
      }
    }
  }

  /// Generate a secure random string
  static String generateSecureRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

  /// Hash a string using SHA-256
  static String hashString(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  /// Verify if a string matches its hash
  static bool verifyHash(String input, String hash) {
    return hashString(input) == hash;
  }
}
