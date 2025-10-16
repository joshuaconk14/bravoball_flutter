import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppRatingService {
  static final AppRatingService instance = AppRatingService._internal();
  factory AppRatingService() => instance;
  AppRatingService._internal();

  final InAppReview _inAppReview = InAppReview.instance;

  // Keys for SharedPreferences
  static const String _sessionCountKey = 'completed_sessions_count';
  static const String _hasRatedKey = 'has_rated_app';
  static const String _lastPromptDateKey = 'last_rating_prompt_date';

  // Configuration - when to show the prompt
  static const int _minSessionsBeforePrompt = 2;  // Show after 2 completed sessions
  static const int _daysBetweenPrompts = 14;      // Wait 2 weeks between prompts

  /// Call this after each session completion
  Future<void> incrementSessionCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_sessionCountKey) ?? 0;
    await prefs.setInt(_sessionCountKey, currentCount + 1);
    
    if (kDebugMode) {
      print('📊 Sessions completed: ${currentCount + 1}');
    }
  }

  /// Check if we should show the rating prompt
  Future<bool> shouldShowRatingPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Don't show if user already rated
    final hasRated = prefs.getBool(_hasRatedKey) ?? false;
    if (hasRated) return false;
    
    // Check if enough sessions completed
    final sessionCount = prefs.getInt(_sessionCountKey) ?? 0;
    if (sessionCount < _minSessionsBeforePrompt) return false;
    
    // Check if enough time passed since last prompt
    final lastPromptString = prefs.getString(_lastPromptDateKey);
    if (lastPromptString != null) {
      final lastPrompt = DateTime.parse(lastPromptString);
      final daysSinceLastPrompt = DateTime.now().difference(lastPrompt).inDays;
      if (daysSinceLastPrompt < _daysBetweenPrompts) return false;
    }
    
    return true;
  }

  /// Request the rating - shows native OS dialog
  Future<void> requestReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if the review dialog is available
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
        
        // Mark that we showed the prompt
        await prefs.setString(_lastPromptDateKey, DateTime.now().toIso8601String());
        
        if (kDebugMode) {
          print('✅ Rating prompt shown successfully');
        }
      } else {
        if (kDebugMode) {
          print('⚠️ In-app review not available on this device');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error requesting review: $e');
      }
    }
  }

  /// Mark that user has rated (optional - for manual tracking)
  Future<void> markAsRated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasRatedKey, true);
  }

  /// Reset for testing (debug only)
  Future<void> resetRatingData() async {
    if (kDebugMode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionCountKey);
      await prefs.remove(_hasRatedKey);
      await prefs.remove(_lastPromptDateKey);
      print('🔄 Rating data reset');
    }
  }
}

