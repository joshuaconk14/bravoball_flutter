/// Utility functions for consistent preference option formatting throughout the app
/// This provides a single point of control for how preference options are displayed
class PreferenceUtils {
  /// Format a preference option for display in the UI
  /// 
  /// This function:
  /// - Applies proper title case capitalization to most preferences
  /// - Handles special cases that should remain as-is (like "2h+")
  /// - Maintains readability for compound terms
  /// 
  /// Examples:
  /// - "medium intensity" -> "Medium Intensity"
  /// - "soccer ball" -> "Soccer Ball"
  /// - "location with goals" -> "Location With Goals"
  /// - "15min" -> "15min" (unchanged)
  /// - "2h+" -> "2h+" (unchanged)
  static String formatPreferenceForDisplay(String preference) {
    if (preference.isEmpty) return preference;
    
    // Special cases that should remain unchanged (mostly time formats)
    final specialCases = {
      '15min', '30min', '45min', '1h', '1h30', '2h+',
      // ✅ REMOVED: 'beginner', 'intermediate', 'advanced' so they get title case formatting
    };
    
    if (specialCases.contains(preference.toLowerCase())) {
      return preference;
    }
    
    // Apply title case (capitalize first letter of each word)
    return preference
        .split(' ')
        .map((word) => word.isEmpty 
            ? word 
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }
  
  /// Format a preference option for backend/API usage
  /// 
  /// This ensures preference options are in the correct format for backend operations
  /// while keeping display formatting separate
  /// 
  /// Examples:
  /// - "Medium Intensity" -> "medium intensity"
  /// - "Soccer Ball" -> "soccer ball"
  /// - "Location With Goals" -> "location with goals"
  static String formatPreferenceForBackend(String preference) {
    if (preference.isEmpty) return preference;
    
    // Convert to lowercase and replace spaces with spaces (keep spaces)
    return preference.toLowerCase();
  }
  
  /// Normalize a preference option for internal comparisons
  /// 
  /// This is used for consistent matching regardless of formatting
  /// 
  /// Examples:
  /// - "Medium Intensity" -> "medium intensity"
  /// - "SOCCER BALL" -> "soccer ball"
  /// - "location_with_goals" -> "location with goals"
  static String normalizePreference(String preference) {
    if (preference.isEmpty) return preference;
    
    // Convert to lowercase and replace underscores with spaces
    return preference.toLowerCase().replaceAll('_', ' ');
  }
  
  /// Check if two preference options refer to the same preference
  /// 
  /// This handles comparison between different formats:
  /// - "medium intensity" and "Medium Intensity" are considered the same
  /// - "soccer_ball" and "Soccer Ball" are considered the same
  static bool arePreferencesEqual(String preference1, String preference2) {
    return normalizePreference(preference1) == normalizePreference(preference2);
  }
  
  /// Format a time preference for display
  /// 
  /// Handles special formatting for time-based preferences
  /// 
  /// Examples:
  /// - "15min" -> "15m"
  /// - "1h" -> "1h"
  /// - "1h30" -> "1h30"
  /// - "2h+" -> "2+h"
  static String formatTimeForDisplay(String timePreference) {
    if (timePreference.isEmpty) return timePreference;
    
    switch (timePreference.toLowerCase()) {
      case '15min':
        return '15m';
      case '30min':
        return '30m';
      case '45min':
        return '45m';
      case '1h':
        return '1h';
      case '1h30':
        return '1h30m';
      case '2h+':
        return '2h+';
      default:
        return timePreference; // Return as-is if not recognized
    }
  }
  
  /// Format equipment preference for display
  /// 
  /// Handles special formatting for equipment options
  /// 
  /// Examples:
  /// - "soccer ball" -> "Soccer Ball"
  /// - "goal" -> "Goal"
  static String formatEquipmentForDisplay(String equipment) {
    return formatPreferenceForDisplay(equipment);
  }
  
  /// Format training style preference for display
  /// 
  /// Examples:
  /// - "low intensity" -> "Low Intensity"
  /// - "game prep" -> "Game Prep"
  static String formatTrainingStyleForDisplay(String trainingStyle) {
    return formatPreferenceForDisplay(trainingStyle);
  }
  
  /// Format location preference for display
  /// 
  /// Examples:
  /// - "full field" -> "Full Field"
  /// - "location with goals" -> "Location With Goals"
  static String formatLocationForDisplay(String location) {
    return formatPreferenceForDisplay(location);
  }
  
  /// Format difficulty preference for display
  /// 
  /// Examples:
  /// - "beginner" -> "Beginner"
  /// - "intermediate" -> "Intermediate"
  /// - "advanced" -> "Advanced"
  static String formatDifficultyForDisplay(String difficulty) {
    return formatPreferenceForDisplay(difficulty); // ✅ UPDATED: Use consistent title case like other preferences
  }
} 