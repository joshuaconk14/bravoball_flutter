import 'package:flutter/foundation.dart';

/// Skill Configuration
/// 
/// Central configuration for all skill and subskill mappings between backend and frontend.
/// This ensures consistency across the app and makes it easy to update skill mappings
/// in one place.
/// 
/// **Usage:**
/// ```dart
/// // Map backend sub-skill to frontend display name
/// final displayName = SkillConfig.mapSubSkill('close_control'); // Returns 'Close control'
/// 
/// // Map backend category to frontend display name
/// final category = SkillConfig.mapSkillCategory('first_touch'); // Returns 'First Touch'
/// 
/// // Map frontend display name back to backend identifier (for API calls)
/// final backendKey = SkillConfig.mapSubSkillToBackend('Close control'); // Returns 'close_control'
/// ```
class SkillConfig {
  // Private constructor to prevent instantiation
  SkillConfig._();

  // ============================================================================
  // SUB-SKILL MAPPINGS (Backend -> Frontend)
  // ============================================================================
  
  /// Maps backend sub-skill identifiers to frontend display names
  /// 
  /// This is the single source of truth for all sub-skill mappings.
  /// Update this map when backend sub-skill names change or new ones are added.
  static const Map<String, String> subSkillMap = {
    // Dribbling
    'close_control': 'Close control',
    'speed_dribbling': 'Speed dribbling',
    '1v1_moves': '1v1 moves',
    'change_of_direction': 'Change of direction',
    'ball_mastery': 'Ball mastery',
    
    // First Touch
    'ground_control': 'Ground control',
    'aerial_control': 'Aerial control',
    'turn_with_ball': 'Turn with ball',
    'touch_and_move': 'Touch and move',
    'juggling': 'Juggling',
    
    // Passing
    'short_passing': 'Short passing',
    'long_passing': 'Long passing',
    'one_touch_passing': 'One touch passing',
    'technique': 'Technique',
    'passing_with_movement': 'Passing with movement',
    
    // Shooting
    'power_shots': 'Power shots',
    'finesse_shots': 'Finesse shots',
    'first_time_shots': 'First time shots',
    '1v1_to_shoot': '1v1 to shoot',
    'shooting_on_the_run': 'Shooting on the run',
    'volleying': 'Volleying',
    
    // Defending
    'tackling': 'Tackling',
    'marking': 'Marking',
    'intercepting': 'Intercepting',
    'jockeying': 'Jockeying',
    'aerial_defending': 'Aerial defending',
    
    // Goalkeeping
    'hand_eye_coordination': 'Hand eye coordination',
    'diving': 'Diving',
    'reflexes': 'Reflexes',
    'shot_stopping': 'Shot stopping',
    'positioning': 'Positioning', // Note: Only for goalkeeping, not defending
    'catching': 'Catching',
    
    // Fitness
    'speed': 'Speed',
    'endurance': 'Endurance',
    'agility': 'Agility',
    
    // Fallback
    'general': 'General',
  };

  // ============================================================================
  // REVERSE MAPPINGS (Frontend -> Backend)
  // ============================================================================
  
  /// Reverse mapping for API calls (frontend display name -> backend identifier)
  /// 
  /// Generated automatically from [subSkillMap] to ensure consistency.
  /// Used when sending data to the backend that requires backend format.
  static final Map<String, String> _reverseSubSkillMap = {
    for (var entry in subSkillMap.entries)
      entry.value: entry.key
  };

  // ============================================================================
  // SKILL CATEGORY MAPPINGS (Backend -> Frontend)
  // ============================================================================
  
  /// Maps backend skill category identifiers to frontend display names
  static const Map<String, String> skillCategoryMap = {
    'passing': 'Passing',
    'shooting': 'Shooting',
    'dribbling': 'Dribbling',
    'first_touch': 'First Touch',
    'defending': 'Defending',
    'fitness': 'Fitness',
    'goalkeeping': 'Goalkeeping',
    'general': 'General',
  };

  // ============================================================================
  // SUB-SKILLS BY CATEGORY (Frontend Display Names)
  // ============================================================================
  
  /// Maps frontend skill category names to their available sub-skills
  /// 
  /// Returns a list of frontend display names for sub-skills in the given category.
  /// This is used by UI components that need to display sub-skill options.
  static const Map<String, List<String>> subSkillsByCategory = {
    'Passing': [
      'Short passing',
      'Long passing',
      'One touch passing',
      'Technique',
      'Passing with movement',
    ],
    'Shooting': [
      'Power shots',
      'Finesse shots',
      'First time shots',
      '1v1 to shoot',
      'Shooting on the run',
      'Volleying',
    ],
    'Dribbling': [
      'Close control',
      'Speed dribbling',
      '1v1 moves',
      'Change of direction',
      'Ball mastery',
    ],
    'First Touch': [
      'Ground control',
      'Aerial control',
      'Turn with ball',
      'Touch and move',
      'Juggling',
    ],
    'Defending': [
      'Tackling',
      'Marking',
      'Intercepting',
      'Jockeying',
      'Aerial defending',
    ],
    'Goalkeeping': [
      'Hand eye coordination',
      'Diving',
      'Reflexes',
      'Shot stopping',
      'Positioning',
      'Catching',
    ],
    'Fitness': [
      'Speed',
      'Endurance',
      'Agility',
    ],
  };

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================
  
  /// Gets the list of sub-skills for a given skill category
  /// 
  /// **Parameters:**
  /// - [category]: The frontend skill category name (e.g., 'Passing', 'Defending')
  /// 
  /// **Returns:**
  /// - List of sub-skill display names for the category
  /// - Empty list if category not found
  /// 
  /// **Example:**
  /// ```dart
  /// SkillConfig.getSubSkillsForCategory('Defending'); 
  /// // Returns ['Tackling', 'Marking', 'Intercepting', 'Jockeying', 'Aerial defending']
  /// ```
  static List<String> getSubSkillsForCategory(String category) {
    return subSkillsByCategory[category] ?? [];
  }
  
  /// Maps a backend sub-skill identifier to its frontend display name
  /// 
  /// **Parameters:**
  /// - [backendSubSkill]: The backend sub-skill identifier (e.g., 'close_control')
  /// 
  /// **Returns:**
  /// - The mapped display name if found (e.g., 'Close control')
  /// - The original backend identifier if not found (for backwards compatibility)
  /// - 'General' if [backendSubSkill] is null or empty
  /// 
  /// **Example:**
  /// ```dart
  /// SkillConfig.mapSubSkill('close_control'); // Returns 'Close control'
  /// SkillConfig.mapSubSkill('unknown_skill'); // Returns 'unknown_skill'
  /// SkillConfig.mapSubSkill(null); // Returns 'General'
  /// ```
  static String mapSubSkill(String? backendSubSkill) {
    if (backendSubSkill == null || backendSubSkill.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ SkillConfig: Empty or null sub-skill provided, returning "General"');
      }
      return 'General';
    }
    
    final normalized = backendSubSkill.toLowerCase();
    final mapped = subSkillMap[normalized];
    
    if (mapped == null && kDebugMode) {
      debugPrint('⚠️ SkillConfig: Unmapped sub-skill: "$backendSubSkill" (normalized: "$normalized")');
    }
    
    return mapped ?? backendSubSkill;
  }
  
  /// Maps a backend skill category identifier to its frontend display name
  /// 
  /// **Parameters:**
  /// - [backendCategory]: The backend category identifier (e.g., 'first_touch')
  /// 
  /// **Returns:**
  /// - The mapped display name if found (e.g., 'First Touch')
  /// - 'General' if not found or if [backendCategory] is null/empty
  /// 
  /// **Example:**
  /// ```dart
  /// SkillConfig.mapSkillCategory('first_touch'); // Returns 'First Touch'
  /// SkillConfig.mapSkillCategory('unknown'); // Returns 'General'
  /// SkillConfig.mapSkillCategory(null); // Returns 'General'
  /// ```
  static String mapSkillCategory(String? backendCategory) {
    if (backendCategory == null || backendCategory.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ SkillConfig: Empty or null category provided, returning "General"');
      }
      return 'General';
    }
    
    final normalized = backendCategory.toLowerCase();
    final mapped = skillCategoryMap[normalized];
    
    if (mapped == null && kDebugMode) {
      debugPrint('⚠️ SkillConfig: Unmapped skill category: "$backendCategory" (normalized: "$normalized")');
    }
    
    return mapped ?? 'General';
  }
  
  /// Maps a frontend sub-skill display name back to backend identifier
  /// 
  /// Useful for API calls that require backend format.
  /// 
  /// **Parameters:**
  /// - [frontendSubSkill]: The frontend display name (e.g., 'Close control')
  /// 
  /// **Returns:**
  /// - The backend identifier if found (e.g., 'close_control')
  /// - A normalized version (lowercase with underscores) if not found
  /// - 'general' if [frontendSubSkill] is null or empty
  /// 
  /// **Example:**
  /// ```dart
  /// SkillConfig.mapSubSkillToBackend('Close control'); // Returns 'close_control'
  /// SkillConfig.mapSubSkillToBackend('Unknown Skill'); // Returns 'unknown_skill'
  /// SkillConfig.mapSubSkillToBackend(null); // Returns 'general'
  /// ```
  static String mapSubSkillToBackend(String? frontendSubSkill) {
    if (frontendSubSkill == null || frontendSubSkill.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ SkillConfig: Empty or null frontend sub-skill provided, returning "general"');
      }
      return 'general';
    }
    
    final mapped = _reverseSubSkillMap[frontendSubSkill];
    if (mapped != null) {
      return mapped;
    }
    
    // Fallback: normalize the frontend name to backend format
    final normalized = frontendSubSkill.toLowerCase().replaceAll(' ', '_');
    if (kDebugMode) {
      debugPrint('⚠️ SkillConfig: No reverse mapping found for "$frontendSubSkill", using normalized: "$normalized"');
    }
    return normalized;
  }
}

