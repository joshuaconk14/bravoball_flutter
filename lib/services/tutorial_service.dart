import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tutorial Service
/// 
/// Manages tutorial state and tracks whether the user has seen the app tutorial.
/// Uses SharedPreferences for local storage (device-specific).
class TutorialService {
  static final TutorialService instance = TutorialService._internal();
  factory TutorialService() => instance;
  TutorialService._internal();

  // Key for SharedPreferences
  static const String _hasSeenTutorialKey = 'has_seen_tutorial';

  /// Check if the user has seen the tutorial
  Future<bool> hasSeenTutorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_hasSeenTutorialKey) ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ TutorialService: Error checking tutorial state: $e');
      }
      return false;
    }
  }

  /// Mark the tutorial as seen
  Future<void> markTutorialAsSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasSeenTutorialKey, true);
      
      if (kDebugMode) {
        print('✅ TutorialService: Tutorial marked as seen');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ TutorialService: Error marking tutorial as seen: $e');
      }
    }
  }

  /// Reset tutorial state (for testing/debugging)
  Future<void> resetTutorial() async {
    if (kDebugMode) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_hasSeenTutorialKey);
        print('🔄 TutorialService: Tutorial state reset');
      } catch (e) {
        print('❌ TutorialService: Error resetting tutorial: $e');
      }
    }
  }
}

