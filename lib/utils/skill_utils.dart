/// Utility functions for consistent skill name formatting throughout the app
/// This provides a single point of control for how skill names are displayed
class SkillUtils {
  /// Format a skill name for display in the UI
  /// 
  /// This function:
  /// - Replaces underscores with spaces
  /// - Applies proper title case capitalization
  /// - Handles special cases (like "First Touch" vs "first touch")
  /// 
  /// Examples:
  /// - "first_touch" -> "First Touch"
  /// - "dribbling" -> "Dribbling" 
  /// - "power_shots" -> "Power Shots"
  static String formatSkillForDisplay(String skill) {
    if (skill.isEmpty) return skill;
    
    // Replace underscores with spaces
    String formatted = skill.replaceAll('_', ' ');
    
    // Apply title case (capitalize first letter of each word)
    return formatted
        .split(' ')
        .map((word) => word.isEmpty 
            ? word 
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }
  
  /// Format a skill name for backend/API usage
  /// 
  /// This ensures skill names are in the correct format for backend operations
  /// while keeping display formatting separate
  /// 
  /// Examples:
  /// - "First Touch" -> "first_touch"
  /// - "Dribbling" -> "dribbling"
  /// - "Power Shots" -> "power_shots"
  static String formatSkillForBackend(String skill) {
    if (skill.isEmpty) return skill;
    
    // Convert to lowercase and replace spaces with underscores
    return skill.toLowerCase().replaceAll(' ', '_');
  }
  
  /// Normalize a skill name for internal comparisons and color mapping
  /// 
  /// This is used by AppTheme.getSkillColor() and other functions that need
  /// to match skill names regardless of their formatting
  /// 
  /// Examples:
  /// - "first_touch" -> "first touch"
  /// - "First Touch" -> "first touch"
  /// - "DRIBBLING" -> "dribbling"
  static String normalizeSkill(String skill) {
    if (skill.isEmpty) return skill;
    
    // Convert to lowercase and replace underscores with spaces
    return skill.toLowerCase().replaceAll('_', ' ');
  }
  
  /// Check if two skill names refer to the same skill
  /// 
  /// This handles comparison between different formats:
  /// - "first_touch" and "First Touch" are considered the same
  /// - "dribbling" and "Dribbling" are considered the same
  static bool areSkillsEqual(String skill1, String skill2) {
    return normalizeSkill(skill1) == normalizeSkill(skill2);
  }
} 