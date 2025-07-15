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

class SkillCategories {
  static const List<SkillCategory> categories = [
    SkillCategory(
      name: "Passing",
      subSkills: [
        "Short passing",
        "Long passing",
        "One touch passing",
        "Technique",
        "Passing with movement"
      ],
      icon: "passing_icon",
    ),
    SkillCategory(
      name: "Shooting",
      subSkills: [
        "Power shots",
        "Finesse shots",
        "First time shots",
        "1v1 to shoot",
        "Shooting on the run",
        "Volleying"
      ],
      icon: "shooting_icon",
    ),
    SkillCategory(
      name: "Dribbling",
      subSkills: [
        "Close control",
        "Speed dribbling",
        "1v1 moves",
        "Change of direction",
        "Ball mastery"
      ],
      icon: "dribbling_icon",
    ),
    SkillCategory(
      name: "First Touch",
      subSkills: [
        "Ground control",
        "Aerial control",
        "Turn with ball",
        "Touch and move",
        "Juggling"
      ],
      icon: "first_touch_icon",
    ),
    SkillCategory(
      name: "Defending",
      subSkills: [
        "Tackling",
        "Marking",
        "Intercepting",
        "Positioning",
        "Agility",
        "Aerial defending"
      ],
      icon: "defending_icon",
    ),
    SkillCategory(
      name: "Goalkeeping",
      subSkills: [
        "Hand eye coordination",
        "Diving",
        "Reflexes",
        "Shot stopping",
        "Positioning",
        "Catching"
      ],
      icon: "goalkeeping_icon",
    ),
    SkillCategory(
      name: "Fitness",
      subSkills: [
        "Speed",
        "Endurance",
        "Agility"
      ],
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