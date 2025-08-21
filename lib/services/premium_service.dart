import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../config/premium_config.dart';
import '../models/premium_models.dart';
import '../utils/device_security_utils.dart';
import '../utils/encryption_utils.dart';
import 'api_service.dart';

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
  
  // Rate limiting and abuse prevention
  static const int _maxValidationAttempts = 5;
  static const int _validationCooldownSeconds = 60;
  static Map<String, int> _validationAttempts = {};
  static Map<String, DateTime> _lastValidationTimeMap = {};

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
    
    // 🔍 DEBUG: Log premium status from cache
    if (kDebugMode) {
      print('🔒 PremiumService: getPremiumStatus() called');
      print('   Cached status: ${_cachedStatus?.name ?? "null"}');
      print('   Last validation: ${_lastValidationTime?.toIso8601String() ?? "never"}');
    }
    
    return _cachedStatus ?? PremiumStatus.free;
  }

  /// Check if user has premium access
  Future<bool> isPremium() async {
    // 🔒 SECURITY: Validate device fingerprint first
    if (!await _validateSecurity()) {
      if (kDebugMode) {
        print('🚨 Security validation failed - denying premium access');
      }
      return false;
    }
    
    final status = await getPremiumStatus();
    final isPremium = status == PremiumStatus.premium;
    
    // 🔍 DEBUG: Log premium access check
    if (kDebugMode) {
      print('🔒 PremiumService: isPremium() called');
      print('   Status: ${status.name}');
      print('   Has premium access: $isPremium');
    }
    
    return isPremium;
  }

  /// Check if user can access a specific feature using backend
  Future<bool> canAccessFeature(PremiumFeature feature) async {
    try {
      // Map frontend feature enum to backend feature string
      final backendFeature = _mapFeatureToBackend(feature);
      
      final response = await ApiService.shared.post(
        '/api/premium/check-feature',
        body: {
          'feature': backendFeature,
        },
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        // Handle nested data structure from backend
        final responseData = response.data!;
        final canAccess = responseData['data']?['canAccess'] as bool? ?? 
                         responseData['canAccess'] as bool? ?? false;
        
        if (kDebugMode) {
          print('🔒 Feature access check: $feature -> $canAccess');
          print('   Backend response: ${response.data}');
        }
        
        return canAccess;
      } else {
        if (kDebugMode) {
          print('❌ Feature access check failed: ${response.error}');
        }
        // Fallback to local check on error
        return await _fallbackFeatureCheck(feature);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking feature access: $e');
      }
      // Fallback to local check on error
      return await _fallbackFeatureCheck(feature);
    }
  }

  /// Check if user can create custom drills (free: 3/month, premium: unlimited)
  Future<bool> canCreateCustomDrill() async {
    return await canAccessFeature(PremiumFeature.unlimitedCustomDrills);
  }


  /// Check if user can do another session today (free: 1/day, premium: unlimited)
  Future<bool> canDoSessionToday() async {
    return await canAccessFeature(PremiumFeature.unlimitedSessions);
  }

  /// Record session completion using backend
  /// NOTE: This method is deprecated - backend now checks database directly for completedSession creation dates
  @Deprecated('Backend now checks database directly instead of UsageTracking model')
  Future<void> recordSessionCompletion() async {
    if (kDebugMode) {
      print('📝 Session completion - backend will check database for limits');
    }
    // No longer needed - backend checks completedSession creation dates directly
  }

  /// Get remaining free features for today from backend
  Future<FreeFeatureUsage> getFreeFeatureUsage() async {
    try {
      final response = await ApiService.shared.get(
        '/api/premium/usage-stats',
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        
        return FreeFeatureUsage(
          customDrillsRemaining: data['customDrillsRemaining'] ?? 0,
          sessionsRemaining: data['sessionsRemaining'] ?? 0,
          customDrillsUsed: data['customDrillsUsed'] ?? 0,
          sessionsUsed: data['sessionsUsed'] ?? 0,
        );
      } else {
        if (kDebugMode) {
          print('⚠️ Failed to get usage stats: ${response.error}');
        }
        // Return fallback data
        return const FreeFeatureUsage(
          customDrillsRemaining: 3,
          sessionsRemaining: 1,
          customDrillsUsed: 0,
          sessionsUsed: 0,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting usage stats: $e');
      }
      // Return fallback data
      return const FreeFeatureUsage(
        customDrillsRemaining: 3,
        sessionsRemaining: 1,
        customDrillsUsed: 0,
        sessionsUsed: 0,
      );
    }
  }

  /// Map frontend feature enum to backend feature string
  String _mapFeatureToBackend(PremiumFeature feature) {
    switch (feature) {
      case PremiumFeature.noAds:
        return 'noAds';
      case PremiumFeature.unlimitedDrills:
        return 'unlimitedDrills';
      case PremiumFeature.unlimitedCustomDrills:
        return 'unlimitedCustomDrills';
      case PremiumFeature.unlimitedSessions:
        return 'unlimitedSessions';
      case PremiumFeature.advancedAnalytics:
        return 'advancedAnalytics';
      case PremiumFeature.basicDrills:
        return 'basicDrills';
      case PremiumFeature.weeklySummaries:
        return 'weeklySummaries';
      case PremiumFeature.monthlySummaries:
        return 'monthlySummaries';
    }
  }

  /// Fallback feature check when backend is unavailable
  Future<bool> _fallbackFeatureCheck(PremiumFeature feature) async {
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

  /// Validate premium status with server
  Future<void> _validateWithServer() async {
    try {
      // 🔒 RATE LIMITING: Check if user can attempt validation
      final userId = await _getCurrentUserId();
      if (!_canAttemptValidation(userId)) {
        if (kDebugMode) {
          print('🚫 Rate limit exceeded - skipping server validation');
        }
        return;
      }
      
      // Record this validation attempt
      _recordValidationAttempt(userId);
      
      if (kDebugMode) {
        print('🌐 Validating premium status with server...');
        print('   API endpoint: /api/premium/status');
      }

      // Make API call using ApiService (same as other endpoints)
      if (kDebugMode) {
        print('   Making API call via ApiService...');
      }
      
      final response = await ApiService.shared.get(
        '/api/premium/status',
        headers: {
          'App-Version': PremiumConfig.appVersion,
        },
        requiresAuth: true,
      );

      if (kDebugMode) {
        print('   Response success: ${response.isSuccess}');
        print('   Response data: ${response.data}');
        print('   Response error: ${response.error}');
      }

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        
        if (kDebugMode) {
          print('   Raw response data: $data');
        }
        
        // Handle the nested response structure from backend
        final responseData = data['data'] ?? data;
        final statusString = responseData['status'] as String?;
        
        if (kDebugMode) {
          print('   Extracted status string: "$statusString"');
        }
        
        if (statusString != null) {
          final newStatus = PremiumStatus.values.firstWhere(
            (e) => e.name == statusString,
            orElse: () => PremiumStatus.free,
          );
          
          if (kDebugMode) {
            print('   Parsed status from response: ${newStatus.name}');
          }
          
          await _updatePremiumStatus(newStatus);
          
          if (kDebugMode) {
            print('✅ Server validation successful - Status: ${newStatus.name}');
          }
        } else {
          if (kDebugMode) {
            print('⚠️ No status found in response data');
          }
        }
      } else {
        if (kDebugMode) {
          print('⚠️ Server validation failed: ${response.error}');
        }
        // Keep cached status on server error
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Server validation error: $e');
        print('   Error type: ${e.runtimeType}');
      }
      // Keep cached status on error
    }
  }

  /// Load cached premium status
  Future<void> _loadCachedStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encryptedStatus = prefs.getString(_premiumKey);
      final lastValidation = prefs.getInt(_lastValidationKey);
      
      if (kDebugMode) {
        print('🔍 DEBUG: _loadCachedStatus() called');
        print('   Encrypted status: "$encryptedStatus"');
        print('   Raw last validation: $lastValidation');
      }
      
      if (encryptedStatus != null && lastValidation != null) {
        // 🔐 DECRYPTION: Decrypt the stored status
        final decryptedStatus = await EncryptionUtils.decryptString(encryptedStatus);
        
        if (kDebugMode) {
          print('🔐 Decrypted status: "$decryptedStatus"');
        }
        
        _cachedStatus = PremiumStatus.values.firstWhere(
          (e) => e.name == decryptedStatus,
          orElse: () => PremiumStatus.free,
        );
        _lastValidationTime = DateTime.fromMillisecondsSinceEpoch(lastValidation);
        
        if (kDebugMode) {
          print('📱 Loaded cached premium status: ${_cachedStatus?.name}');
          print('   Parsed status: ${_cachedStatus?.name}');
          print('   Parsed validation time: ${_lastValidationTime?.toIso8601String()}');
        }
      } else {
        _cachedStatus = PremiumStatus.free;
        if (kDebugMode) {
          print('📱 No cached status found, defaulting to: ${_cachedStatus?.name}');
        }
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
      // 🔒 SECURITY: Only allow status updates from validated sources
      if (status == PremiumStatus.premium) {
        if (!await _isValidPremiumSource()) {
          if (kDebugMode) {
            print('🚨 Invalid premium source detected - rejecting status update');
          }
          return; // Reject invalid premium status
        }
      }
      
      final prefs = await SharedPreferences.getInstance();
      
      // 🔐 ENCRYPTION: Encrypt premium status before storage
      final encryptedStatus = await EncryptionUtils.encryptString(status.name);
      await prefs.setString(_premiumKey, encryptedStatus);
      await prefs.setInt(_lastValidationKey, DateTime.now().millisecondsSinceEpoch);
      
      _cachedStatus = status;
      _lastValidationTime = DateTime.now();
      
      if (kDebugMode) {
        print('💾 Updated premium status: ${status.name} (encrypted)');
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

  /// Check if user can attempt validation (rate limiting)
  bool _canAttemptValidation(String userId) {
    final now = DateTime.now();
    final lastAttempt = _lastValidationTimeMap[userId];
    final attempts = _validationAttempts[userId] ?? 0;
    
    if (lastAttempt != null) {
      final timeSinceLast = now.difference(lastAttempt).inSeconds;
      if (timeSinceLast < _validationCooldownSeconds) {
        if (kDebugMode) {
          print('⏰ Rate limit: Too soon since last attempt');
        }
        return false;
      }
    }
    
    if (attempts >= _maxValidationAttempts) {
      if (kDebugMode) {
        print('🚫 Rate limit: Max attempts exceeded');
      }
      return false;
    }
    
    return true;
  }

  /// Record validation attempt for rate limiting
  void _recordValidationAttempt(String userId) {
    final now = DateTime.now();
    _lastValidationTimeMap[userId] = now;
    _validationAttempts[userId] = (_validationAttempts[userId] ?? 0) + 1;
    
    if (kDebugMode) {
      print('📊 Rate limit: User $userId has ${_validationAttempts[userId]} attempts');
    }
  }

  /// Get current user ID for rate limiting
  Future<String> _getCurrentUserId() async {
    try {
      // Try to get user ID from shared preferences or other sources
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? 
                    prefs.getString('auth_token') ?? 
                    'anonymous_${DateTime.now().millisecondsSinceEpoch}';
      
      return userId;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting user ID: $e');
      }
      return 'unknown_user';
    }
  }

  /// Log security events for monitoring and debugging
  void _logSecurityEvent(String event, Map<String, dynamic> details) {
    if (kDebugMode) {
      print('🔒 SECURITY EVENT: $event - $details');
    }
    
    // In production, send to security monitoring service
    if (!kDebugMode) {
      // TODO: Send to security monitoring service
      // _sendToSecurityMonitoring(event, details);
      
      // For now, just log locally
      print('🔒 SECURITY EVENT: $event - $details');
    }
  }

  /// Validate that premium status update is coming from a legitimate source
  Future<bool> _isValidPremiumSource() async {
    try {
      // Check if this update is coming from:
      // 1. Valid receipt validation
      // 2. Backend API call
      // 3. Valid purchase flow
      
      // For now, implement basic validation
      // TODO: Implement proper receipt validation when backend is ready
      
      // Check if we have a recent backend validation
      if (_lastValidationTime != null) {
        final timeSinceLastValidation = DateTime.now().difference(_lastValidationTime!).inSeconds;
        if (timeSinceLastValidation < 300) { // 5 minutes
          return true; // Recent backend validation
        }
      }
      
      // Check if device security is valid
      return await _validateSecurity();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error validating premium source: $e');
      }
      return false; // Fail secure
    }
  }

  /// Validate device security and integrity
  Future<bool> _validateSecurity() async {
    try {
      // Check device fingerprint
      final isFingerprintValid = await EncryptionUtils.validateDeviceFingerprint();
      
      // Check device security
      final isDeviceSecure = !await DeviceSecurityUtils.isDeviceCompromised();
      
      if (kDebugMode) {
        print('🔒 Security validation:');
        print('   Device fingerprint: ${isFingerprintValid ? "✅ Valid" : "❌ Invalid"}');
        print('   Device security: ${isDeviceSecure ? "✅ Secure" : "❌ Compromised"}');
      }
      
      // 🔒 SECURITY LOGGING: Log security events
      _logSecurityEvent('security_validation', {
        'timestamp': DateTime.now().toIso8601String(),
        'fingerprint_valid': isFingerprintValid,
        'device_secure': isDeviceSecure,
        'overall_result': isFingerprintValid && isDeviceSecure,
      });
      
      return isFingerprintValid && isDeviceSecure;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error validating security: $e');
      }
      
      // 🔒 SECURITY LOGGING: Log security errors
      _logSecurityEvent('security_validation_error', {
        'timestamp': DateTime.now().toIso8601String(),
        'error': e.toString(),
        'error_type': e.runtimeType.toString(),
      });
      
      // Fail secure: deny access on security validation errors
      return false;
    }
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



  /// Force refresh premium status (for testing or manual refresh)
  Future<void> forceRefresh() async {
    if (kDebugMode) {
      print('🔄 Forcing premium status refresh...');
      print('   Current cached status: ${_cachedStatus?.name ?? "null"}');
    }
    
    _lastValidationTime = null;
    
    try {
      await _validateWithServer();
      
      if (kDebugMode) {
        print('✅ Force refresh completed');
        print('   New cached status: ${_cachedStatus?.name ?? "null"}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Force refresh failed: $e');
        print('   Cached status remains: ${_cachedStatus?.name ?? "null"}');
      }
      rethrow; // Re-throw so calling code knows it failed
    }
  }

  /// Debug method to manually check and fix premium status
  Future<void> debugCheckPremiumStatus() async {
    if (kDebugMode) {
      print('🔍 DEBUG: Manual premium status check');
      print('   Current cached status: ${_cachedStatus?.name ?? "null"}');
      print('   Last validation: ${_lastValidationTime?.toIso8601String() ?? "never"}');
      print('   About to force refresh...');
    }
    
    try {
      await forceRefresh();
      
      if (kDebugMode) {
        print('✅ DEBUG: Premium status check completed');
        print('   Final cached status: ${_cachedStatus?.name ?? "null"}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ DEBUG: Premium status check failed: $e');
      }
    }
  }

  /// Update premium status after successful purchase
  Future<bool> updatePremiumStatusAfterPurchase({
    required String plan,
    required String productId,
    required DateTime purchaseDate,
  }) async {
    if (kDebugMode) {
      print('🔍 DEBUG: Starting updatePremiumStatusAfterPurchase');
      print('   Plan: $plan');
      print('   ProductId: $productId');
      print('   PurchaseDate: $purchaseDate');
    }
    
    try {
      if (kDebugMode) {
        print('🔓 Updating premium status after purchase: $plan ($productId)');
      }
      
      // Set premium status based on plan
      PremiumStatus newStatus;
      DateTime? trialEndDate;
      DateTime? subscriptionEndDate;
      
      switch (plan) {
        case 'monthly':
          newStatus = PremiumStatus.premium;
          subscriptionEndDate = purchaseDate.add(const Duration(days: 30));
          break;
        case 'yearly':
          newStatus = PremiumStatus.premium;
          subscriptionEndDate = purchaseDate.add(const Duration(days: 365));
          break;
        default:
          newStatus = PremiumStatus.premium;
          subscriptionEndDate = purchaseDate.add(const Duration(days: 30));
      }
      
      if (kDebugMode) {
        print('🔍 DEBUG: Plan processed');
        print('   NewStatus: ${newStatus.name}');
        print('   SubscriptionEndDate: ${subscriptionEndDate?.toIso8601String()}');
      }
      
      // Create premium subscription object
      final subscription = PremiumSubscription(
        id: 'mock_subscription_${DateTime.now().millisecondsSinceEpoch}',
        status: newStatus,
        plan: _mapPlanStringToEnum(plan),
        startDate: purchaseDate,
        endDate: subscriptionEndDate,
        trialEndDate: null,
        isActive: true,
        isTrial: false,
        platform: Platform.isIOS ? 'ios' : 'android',
        receiptData: 'mock_receipt_$productId',
      );
      
      if (kDebugMode) {
        print('🔍 DEBUG: PremiumSubscription object created');
        print('   Subscription ID: ${subscription.id}');
        print('   Subscription Plan: ${subscription.plan.name}');
      }
      
      // Update cached status
      if (kDebugMode) {
        print('🔍 DEBUG: About to update cached status to: ${newStatus.name}');
      }
      _cachedStatus = newStatus;
      
      if (kDebugMode) {
        print('🔍 DEBUG: Cached status updated to: ${_cachedStatus?.name}');
      }
      
      // Save to local storage
      if (kDebugMode) {
        print('🔍 DEBUG: About to save premium subscription to local storage');
      }
      await _savePremiumSubscription(subscription);
      
      if (kDebugMode) {
        print('🔍 DEBUG: Local storage save completed');
      }
      
      // Subscribe user to plan via backend
      if (kDebugMode) {
        print('🔍 DEBUG: About to call backend subscription');
      }
      await _subscribeUserToPlan(subscription);
      
      if (kDebugMode) {
        print('🔍 DEBUG: Backend subscription completed successfully');
      }
      
      // Only print success message if we reach here (backend succeeded)
      if (kDebugMode) {
        print('✅ Premium status updated to: ${newStatus.name}');
        print('   Plan: $plan');
        print('   Valid until: ${subscriptionEndDate?.toIso8601String()}');
      }
      
      // Return here to indicate success
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating premium status: $e');
        print('🔍 DEBUG: Exception caught in updatePremiumStatusAfterPurchase');
        print('   Exception type: ${e.runtimeType}');
        print('   Exception message: $e');
      }
      // Revert to free status on error
      if (kDebugMode) {
        print('🔍 DEBUG: About to revert cached status to free');
      }
      _cachedStatus = PremiumStatus.free;
      
      if (kDebugMode) {
        print('🔍 DEBUG: Cached status reverted to: ${_cachedStatus?.name}');
      }
      
      // Re-throw the exception so the calling method knows it failed
      return false;
    }
  }
  
  /// Map plan string to SubscriptionPlan enum
  SubscriptionPlan _mapPlanStringToEnum(String plan) {
    switch (plan) {
      case 'monthly':
        return SubscriptionPlan.monthly;
      case 'yearly':
        return SubscriptionPlan.yearly;
      default:
        return SubscriptionPlan.monthly;
    }
  }
  
  /// Save premium subscription to local storage
  Future<void> _savePremiumSubscription(PremiumSubscription subscription) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save subscription details
      await prefs.setString('premium_subscription', jsonEncode(subscription.toJson()));
      await prefs.setString(_premiumKey, subscription.status.name);
      await prefs.setInt(_lastValidationKey, DateTime.now().millisecondsSinceEpoch);
      
      if (kDebugMode) {
        print('💾 Premium subscription saved to local storage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving premium subscription: $e');
      }
    }
  }
  
  /// Subscribe user to premium plan via backend
  Future<void> _subscribeUserToPlan(PremiumSubscription subscription) async {
    if (kDebugMode) {
      print('🔍 DEBUG: Starting _subscribeUserToPlan');
      print('   Subscription Plan: ${subscription.plan.name}');
      print('   Subscription ID: ${subscription.id}');
    }
    
    try {
      if (kDebugMode) {
        print('🌐 Subscribing user to plan via backend: ${subscription.plan.name}');
        print('🔍 DEBUG: About to make API call to /api/premium/subscribe');
      }
      
      // Prepare purchase data matching backend PurchaseCompletedRequest model
      final purchaseData = {
        'plan': subscription.plan.name,
        'productId': subscription.id,
        'purchaseDate': subscription.startDate.toIso8601String(),
        'expiryDate': subscription.endDate?.toIso8601String(),
        'platform': subscription.platform ?? (Platform.isIOS ? 'ios' : 'android'),
      };
      
      if (kDebugMode) {
        print('🔍 DEBUG: Sending purchase data: $purchaseData');
      }
      
      final response = await ApiService.shared.post(
        '/api/premium/subscribe',
        body: purchaseData,
        requiresAuth: true,
      );
      
      if (kDebugMode) {
        print('🔍 DEBUG: API response received');
        print('   Response success: ${response.isSuccess}');
        print('   Response error: ${response.error}');
        print('   Response data: ${response.data}');
      }
      
      if (response.isSuccess) {
        if (kDebugMode) {
          print('✅ User successfully subscribed to ${subscription.plan.name} plan');
          print('🔍 DEBUG: Backend subscription succeeded');
        }
        
        // Update local subscription with backend data if needed
        // The backend will handle all the subscription logic
      } else {
        if (kDebugMode) {
          print('⚠️ Failed to subscribe user: ${response.error}');
          print('🔍 DEBUG: Backend subscription failed, about to throw exception');
        }
        // Fail the purchase if backend subscription fails
        // This ensures data consistency between frontend and backend
        throw Exception('Failed to activate subscription: ${response.error}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error subscribing user to plan: $e');
        print('🔍 DEBUG: Exception caught in _subscribeUserToPlan');
        print('   Exception type: ${e.runtimeType}');
        print('   Exception message: $e');
        print('🔍 DEBUG: About to rethrow exception');
      }
      // Re-throw the error to fail the purchase
      // This ensures premium status is not granted if backend fails
      rethrow;
    }
  }

  /// Clear cached data (for testing or logout)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_premiumKey);
      await prefs.remove(_lastValidationKey);
      
      _cachedStatus = null;
      _lastValidationTime = null;
      
      // 🔐 SECURITY: Clear encryption data on logout
      await EncryptionUtils.clearEncryptionData();
      
      if (kDebugMode) {
        print('🗑️ Premium cache and encryption data cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing cache: $e');
      }
    }
  }
}
