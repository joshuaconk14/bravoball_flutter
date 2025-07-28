import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Wake Lock Service
/// Prevents screen from sleeping during drill timers
/// Complements the background audio approach
class WakeLockService {
  static bool _isWakeLockEnabled = false;
  
  /// Enable wake lock to keep screen on during workouts
  static Future<void> enableWakeLock() async {
    if (_isWakeLockEnabled) return;
    
    try {
      await WakelockPlus.enable();
      _isWakeLockEnabled = true;
      
      if (kDebugMode) {
        print('🔆 Wake lock enabled - screen will stay on');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error enabling wake lock: $e');
      }
    }
  }
  
  /// Disable wake lock when workout is complete
  static Future<void> disableWakeLock() async {
    if (!_isWakeLockEnabled) return;
    
    try {
      await WakelockPlus.disable();
      _isWakeLockEnabled = false;
      
      if (kDebugMode) {
        print('🌙 Wake lock disabled - screen can sleep normally');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error disabling wake lock: $e');
      }
    }
  }
  
  /// Check if wake lock is currently enabled
  static Future<bool> isWakeLockEnabled() async {
    try {
      return await WakelockPlus.enabled;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking wake lock status: $e');
      }
      return false;
    }
  }
  
  /// Get current wake lock status (cached)
  static bool get isEnabled => _isWakeLockEnabled;
} 