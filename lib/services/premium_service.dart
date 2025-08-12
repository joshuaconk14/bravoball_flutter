import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../config/premium_config.dart';
import '../models/premium_models.dart';
import '../utils/device_security_utils.dart';

class PremiumService {
  static final PremiumService _instance = PremiumService._internal();
  static PremiumService get instance => _instance;

  PremiumService._internal();

  // Premium status cache
  PremiumStatus? _cachedStatus;
  DateTime? _lastValidationTime;
  
  // Security
  static const int _validationCacheTime = 300; // 5 minutes cache
  static const String _premiumKey = 'premium_status';
  static const String _lastValidationKey = 'last_validation_time';
  static const String _deviceFingerprintKey = 'device_fingerprint';

  /// Initialize premium service and validate current status
  Future<void> initialize() async {
    if (kDebugMode) {
      print('🚀 Initializing PremiumService...');
    }

    try {
      // Check device security first
      if (await DeviceSecurityUtils.isDeviceCompromised()) {
        if (kDebugMode) {
          print('⚠️ Device security compromised - premium features disabled');
        }
        _cachedStatus = PremiumStatus.free;
        return;
      }

      // Load cached status
      await _loadCachedStatus();
      
      // Validate with server if needed
      if (_shouldValidateWithServer()) {
        await _validateWithServer();
      }

      if (kDebugMode) {
        print('✅ PremiumService initialized - Status: ${_cachedStatus?.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing PremiumService: $e');
      }
      // Fallback to free status on error
      _cachedStatus = PremiumStatus.free;
    }
  }

  /// Get current premium status (cached for performance)
  Future<PremiumStatus> getPremiumStatus() async {
    if (_cachedStatus == null) {
      await _loadCachedStatus();
    }
    return _cachedStatus ?? PremiumStatus.free;
  }

  /// Check if user has premium access
  Future<bool> isPremium() async {
    final status = await getPremiumStatus();
    return status == PremiumStatus.premium;
  }

  /// Check if user can access a specific feature
  Future<bool> canAccessFeature(PremiumFeature feature) async {
    final status = await getPremiumStatus();
    
    switch (feature) {
      case PremiumFeature.noAds:
        return status == PremiumStatus.premium;
      
      case PremiumFeature.unlimitedDrills:
        return status == PremiumStatus.premium;
      
      case PremiumFeature.unlimitedCustomDrills:
        return status == PremiumStatus.premium;
      
      case PremiumFeature.unlimitedSessions:
        return status == PremiumStatus.premium;
      
      case PremiumFeature.advancedAnalytics:
        return status == PremiumStatus.premium;
      
      case PremiumFeature.basicDrills:
        return true; // Free users can access basic drills
      
      case PremiumFeature.weeklySummaries:
        return true; // Free users get basic summaries
      
      case PremiumFeature.monthlySummaries:
        return true; // Free users get basic summaries
    }
  }

  /// Check if user can create custom drills (free: 3/month, premium: unlimited)
  Future<bool> canCreateCustomDrill() async {
    if (await isPremium()) {
      return true; // Premium users can create unlimited drills
    }

    // Free users: check monthly limit
    final prefs = await SharedPreferences.getInstance();
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;
    final monthKey = 'custom_drills_${currentYear}_${currentMonth}';
    
    final drillsThisMonth = prefs.getInt(monthKey) ?? 0;
    return drillsThisMonth < PremiumConfig.freeCustomDrillsPerMonth;
  }

  /// Record custom drill creation
  Future<void> recordCustomDrillCreation() async {
    final prefs = await SharedPreferences.getInstance();
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;
    final monthKey = 'custom_drills_${currentYear}_${currentMonth}';
    
    final drillsThisMonth = prefs.getInt(monthKey) ?? 0;
    await prefs.setInt(monthKey, drillsThisMonth + 1);
    
    if (kDebugMode) {
      print('📝 Custom drill created - Month: $currentMonth/$currentYear, Count: ${drillsThisMonth + 1}');
    }
  }

  /// Check if user can do another session today (free: 1/day, premium: unlimited)
  Future<bool> canDoSessionToday() async {
    if (await isPremium()) {
      return true; // Premium users can do unlimited sessions
    }

    // Free users: check daily limit
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
    final sessionsToday = prefs.getInt('sessions_$today') ?? 0;
    
    return sessionsToday < PremiumConfig.freeSessionsPerDay;
  }

  /// Record session completion
  Future<void> recordSessionCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
    final sessionsToday = prefs.getInt('sessions_$today') ?? 0;
    
    await prefs.setInt('sessions_$today', sessionsToday + 1);
    
    if (kDebugMode) {
      print('📝 Session completed - Date: $today, Count: ${sessionsToday + 1}');
    }
  }

  /// Get remaining free features for today
  Future<FreeFeatureUsage> getFreeFeatureUsage() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Custom drills this month
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;
    final monthKey = 'custom_drills_${currentYear}_${currentMonth}';
    final drillsThisMonth = prefs.getInt(monthKey) ?? 0;
    
    // Sessions today
    final today = DateTime.now().toIso8601String().split('T')[0];
    final sessionsToday = prefs.getInt('sessions_$today') ?? 0;
    
    return FreeFeatureUsage(
      customDrillsRemaining: PremiumConfig.freeCustomDrillsPerMonth - drillsThisMonth,
      sessionsRemaining: PremiumConfig.freeSessionsPerDay - sessionsToday,
      customDrillsUsed: drillsThisMonth,
      sessionsUsed: sessionsToday,
    );
  }

  /// Validate premium status with server
  Future<void> _validateWithServer() async {
    try {
      if (kDebugMode) {
        print('🌐 Validating premium status with server...');
      }

      // Get device fingerprint for security
      final deviceFingerprint = await _getDeviceFingerprint();
      
      // Make API call to server
      final response = await http.post(
        Uri.parse('${PremiumConfig.apiBaseUrl}/validate-premium'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
          'Device-Fingerprint': deviceFingerprint,
          'App-Version': PremiumConfig.appVersion,
        },
        body: jsonEncode({
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'device_id': deviceFingerprint,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newStatus = PremiumStatus.values.firstWhere(
          (e) => e.name == data['status'],
          orElse: () => PremiumStatus.free,
        );
        
        await _updatePremiumStatus(newStatus);
        
        if (kDebugMode) {
          print('✅ Server validation successful - Status: ${newStatus.name}');
        }
      } else {
        if (kDebugMode) {
          print('⚠️ Server validation failed - Status: ${response.statusCode}');
        }
        // Keep cached status on server error
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Server validation error: $e');
      }
      // Keep cached status on error
    }
  }

  /// Load cached premium status
  Future<void> _loadCachedStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusString = prefs.getString(_premiumKey);
      final lastValidation = prefs.getInt(_lastValidationKey);
      
      if (statusString != null && lastValidation != null) {
        _cachedStatus = PremiumStatus.values.firstWhere(
          (e) => e.name == statusString,
          orElse: () => PremiumStatus.free,
        );
        _lastValidationTime = DateTime.fromMillisecondsSinceEpoch(lastValidation);
        
        if (kDebugMode) {
          print('📱 Loaded cached premium status: ${_cachedStatus?.name}');
        }
      } else {
        _cachedStatus = PremiumStatus.free;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading cached status: $e');
      }
      _cachedStatus = PremiumStatus.free;
    }
  }

  /// Update premium status and cache it
  Future<void> _updatePremiumStatus(PremiumStatus status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_premiumKey, status.name);
      await prefs.setInt(_lastValidationKey, DateTime.now().millisecondsSinceEpoch);
      
      _cachedStatus = status;
      _lastValidationTime = DateTime.now();
      
      if (kDebugMode) {
        print('💾 Updated premium status: ${status.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating premium status: $e');
      }
    }
  }

  /// Check if we should validate with server
  bool _shouldValidateWithServer() {
    if (_lastValidationTime == null) return true;
    
    final timeSinceLastValidation = DateTime.now().difference(_lastValidationTime!).inSeconds;
    return timeSinceLastValidation >= _validationCacheTime;
  }

  /// Get device fingerprint for security
  Future<String> _getDeviceFingerprint() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? fingerprint = prefs.getString(_deviceFingerprintKey);
      
      if (fingerprint == null) {
        // Generate new fingerprint
        final deviceInfo = await DeviceSecurityUtils.getDeviceInfo();
        fingerprint = sha256.convert(utf8.encode(deviceInfo)).toString();
        await prefs.setString(_deviceFingerprintKey, fingerprint);
      }
      
      return fingerprint;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting device fingerprint: $e');
      }
      return 'unknown';
    }
  }

  /// Get authentication token (implement based on your auth system)
  Future<String> _getAuthToken() async {
    // TODO: Implement based on your authentication system
    // This should return a valid JWT or similar token
    return 'placeholder_token';
  }

  /// Force refresh premium status (for testing or manual refresh)
  Future<void> forceRefresh() async {
    if (kDebugMode) {
      print('🔄 Forcing premium status refresh...');
    }
    
    _lastValidationTime = null;
    await _validateWithServer();
  }

  /// Clear cached data (for testing or logout)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_premiumKey);
      await prefs.remove(_lastValidationKey);
      
      _cachedStatus = null;
      _lastValidationTime = null;
      
      if (kDebugMode) {
        print('🗑️ Premium cache cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing cache: $e');
      }
    }
  }
}
