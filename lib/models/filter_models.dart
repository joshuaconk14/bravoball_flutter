import '../config/skill_config.dart';

enum FilterType { time, equipment, trainingStyle, location, difficulty }

class FilterOptions {
  static const List<String> timeOptions = [
    "15min", "30min", "45min", "1h", "1h30", "2h+"
  ];
  
  static const List<String> equipmentOptions = [
    "soccer ball", "cones", "goal"
  ];
  
  static const List<String> trainingStyleOptions = [
    "low intensity", "medium intensity", "high intensity"
  ];
  
  static const List<String> locationOptions = [
    "full field", "medium field", "small space", "location with goals", "location with wall"
  ];
  
  static const List<String> difficultyOptions = [
    "beginner", "intermediate", "advanced"
  ];
}

/// UI model for skill categories used in filtering
/// 
/// This model combines skill category data with UI-specific properties (icons).
/// Sub-skills are sourced from [SkillConfig] to maintain a single source of truth.
class SkillCategory {
  final String name;
  final List<String> subSkills;
  final String icon;
  
  const SkillCategory({
    required this.name,
    required this.subSkills,
    required this.icon,
  });
}

/// Skill categories for UI filtering
/// 
/// Uses [SkillConfig] as the source of truth for sub-skills to avoid duplication.
/// Icons remain here as they are UI-specific presentation concerns.
class SkillCategories {
  /// List of skill categories with their sub-skills and icons
  /// 
  /// Computed once at initialization to avoid recreating objects on each access.
  /// Sub-skills are sourced from [SkillConfig] to maintain consistency.
  static final List<SkillCategory> categories = [
    SkillCategory(
      name: "Passing",
      subSkills: SkillConfig.getSubSkillsForCategory("Passing"),
      icon: "passing_icon",
    ),
    SkillCategory(
      name: "Shooting",
      subSkills: SkillConfig.getSubSkillsForCategory("Shooting"),
      icon: "shooting_icon",
    ),
    SkillCategory(
      name: "Dribbling",
      subSkills: SkillConfig.getSubSkillsForCategory("Dribbling"),
      icon: "dribbling_icon",
    ),
    SkillCategory(
      name: "First Touch",
      subSkills: SkillConfig.getSubSkillsForCategory("First Touch"),
      icon: "first_touch_icon",
    ),
    SkillCategory(
      name: "Defending",
      subSkills: SkillConfig.getSubSkillsForCategory("Defending"),
      icon: "defending_icon",
    ),
    SkillCategory(
      name: "Goalkeeping",
      subSkills: SkillConfig.getSubSkillsForCategory("Goalkeeping"),
      icon: "goalkeeping_icon",
    ),
    SkillCategory(
      name: "Fitness",
      subSkills: SkillConfig.getSubSkillsForCategory("Fitness"),
      icon: "fitness_icon",
    ),
  ];
}

class UserPreferences {
  String? selectedTime;
  Set<String> selectedEquipment = {};
  String? selectedTrainingStyle;
  String? selectedLocation;
  String? selectedDifficulty;
  Set<String> selectedSkills = {};
  
  UserPreferences({
    this.selectedTime,
    Set<String>? selectedEquipment,
    this.selectedTrainingStyle,
    this.selectedLocation,
    this.selectedDifficulty,
    Set<String>? selectedSkills,
  }) {
    this.selectedEquipment = selectedEquipment ?? {};
    this.selectedSkills = selectedSkills ?? {};
  }
} 