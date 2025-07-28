import 'package:flutter/foundation.dart';
import '../models/drill_model.dart';
import '../models/filter_models.dart';

class SessionGeneratorViewModel extends ChangeNotifier {
  // User preferences
  UserPreferences _preferences = UserPreferences();
  UserPreferences get preferences => _preferences;
  
  // Drill lists
  final List<DrillModel> _availableDrills = _mockDrills;
  List<DrillModel> get availableDrills => _availableDrills;
  
  final List<DrillModel> _sessionDrills = [];
  List<DrillModel> get sessionDrills => _sessionDrills;
  
  // UI state
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  bool _autoGenerateSession = true;
  bool get autoGenerateSession => _autoGenerateSession;
  
  // Filter methods
  void updateTimeFilter(String? time) {
    _preferences.selectedTime = time;
    if (_autoGenerateSession) {
      _autoGenerateSessionDrills();
    }
    notifyListeners();
  }
  
  void updateEquipmentFilter(Set<String> equipment) {
    _preferences.selectedEquipment = equipment;
    if (_autoGenerateSession) {
      _autoGenerateSessionDrills();
    }
    notifyListeners();
  }
  
  void updateTrainingStyleFilter(String? style) {
    _preferences.selectedTrainingStyle = style;
    if (_autoGenerateSession) {
      _autoGenerateSessionDrills();
    }
    notifyListeners();
  }
  
  void updateLocationFilter(String? location) {
    _preferences.selectedLocation = location;
    if (_autoGenerateSession) {
      _autoGenerateSessionDrills();
    }
    notifyListeners();
  }
  
  void updateDifficultyFilter(String? difficulty) {
    _preferences.selectedDifficulty = difficulty;
    if (_autoGenerateSession) {
      _autoGenerateSessionDrills();
    }
    notifyListeners();
  }
  
  void updateSkillsFilter(Set<String> skills) {
    _preferences.selectedSkills = skills;
    if (_autoGenerateSession) {
      _autoGenerateSessionDrills();
    }
    notifyListeners();
  }
  
  // Auto-generate session drills based on current filters
  void _autoGenerateSessionDrills() {
    final filtered = filteredDrills;
    _sessionDrills.clear();
    
    // Add up to 3-4 drills based on filters
    final maxDrills = _getMaxDrillsForTime();
    final drillsToAdd = filtered.take(maxDrills).toList();
    
    for (final drill in drillsToAdd) {
      _sessionDrills.add(drill);
    }
  }
  
  int _getMaxDrillsForTime() {
    switch (_preferences.selectedTime) {
      case '15min':
        return 2;
      case '30min':
        return 3;
      case '45min':
      case '1h':
        return 4;
      case '1h30':
        return 5;
      case '2h+':
        return 6;
      default:
        return 3;
    }
  }
  
  // Manual drill management methods
  bool addDrillToSession(DrillModel drill) {
    // Check if session already has 10 drills (limit)
    if (_sessionDrills.length >= 10) {
      return false; // Cannot add more drills
    }
    
    if (!_sessionDrills.any((d) => d.id == drill.id)) {
      _sessionDrills.add(drill);
      notifyListeners();
      return true; // Successfully added drill
    }
    
    return false; // Drill already exists in session
  }
  
  void removeDrillFromSession(DrillModel drill) {
    _sessionDrills.removeWhere((d) => d.id == drill.id);
    notifyListeners();
  }
  
  void reorderSessionDrills(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final DrillModel item = _sessionDrills.removeAt(oldIndex);
    _sessionDrills.insert(newIndex, item);
    notifyListeners();
  }
  
  void clearSession() {
    _sessionDrills.clear();
    notifyListeners();
  }
  
  void toggleAutoGenerate(bool value) {
    _autoGenerateSession = value;
    if (value) {
      _autoGenerateSessionDrills();
    }
    notifyListeners();
  }
  
  // Helper methods
  bool get hasSessionDrills => _sessionDrills.isNotEmpty;
  
  int get sessionDrillCount => _sessionDrills.length;
  
  bool isDrillInSession(DrillModel drill) {
    return _sessionDrills.any((d) => d.id == drill.id);
  }
  
  // Get drills not in session for search
  List<DrillModel> get drillsNotInSession {
    return _availableDrills.where((drill) => !isDrillInSession(drill)).toList();
  }
  
  // Filter drills based on user preferences
  List<DrillModel> get filteredDrills {
    List<DrillModel> filtered = List.from(_availableDrills);
    
    // Filter by selected skills
    if (_preferences.selectedSkills.isNotEmpty) {
      filtered = filtered.where((drill) {
        return drill.subSkills.any((subSkill) => 
          _preferences.selectedSkills.contains(subSkill));
      }).toList();
    }
    
    // Filter by equipment
    if (_preferences.selectedEquipment.isNotEmpty) {
      filtered = filtered.where((drill) {
        return _preferences.selectedEquipment.any((equipment) => 
          drill.equipment.contains(equipment));
      }).toList();
    }
    
    // Filter by difficulty
    if (_preferences.selectedDifficulty != null) {
      filtered = filtered.where((drill) => 
        drill.difficulty.toLowerCase() == _preferences.selectedDifficulty!.toLowerCase()
      ).toList();
    }
    
    // Filter by training style
    if (_preferences.selectedTrainingStyle != null) {
      filtered = filtered.where((drill) => 
        drill.trainingStyle.toLowerCase().contains(_preferences.selectedTrainingStyle!.toLowerCase())
      ).toList();
    }
    
    return filtered;
  }
  
  // Search drills by text query
  List<DrillModel> searchDrills(String query) {
    if (query.isEmpty) return drillsNotInSession;
    
    final lowercaseQuery = query.toLowerCase();
    return drillsNotInSession.where((drill) {
      return drill.title.toLowerCase().contains(lowercaseQuery) ||
             drill.skill.toLowerCase().contains(lowercaseQuery) ||
             drill.subSkills.any((subSkill) => 
               subSkill.toLowerCase().contains(lowercaseQuery)) ||
             drill.description.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }
  
  // Filter drills by skill for search
  List<DrillModel> filterDrillsBySkill(String skill) {
    return drillsNotInSession.where((drill) {
      return drill.skill.toLowerCase() == skill.toLowerCase() ||
             drill.subSkills.any((subSkill) => 
               subSkill.toLowerCase().contains(skill.toLowerCase()));
    }).toList();
  }
  
  // Mock data - replace with real data later
  static final List<DrillModel> _mockDrills = [
    DrillModel(
      id: '550e8400-e29b-41d4-a716-446655440001',
      title: 'Ronaldinho drill to cone turn',
      skill: 'Dribbling',
      subSkills: ['Close control', '1v1 moves'],
      sets: 1,
      reps: 1,
      duration: 1,
      description: 'Practice close control and turning at cones like Ronaldinho.',
      instructions: ['Dribble to cone', 'Turn quickly', 'Accelerate away'],
      tips: ['Keep ball close', 'Use both feet', 'Change pace'],
      equipment: ['soccer ball', 'cones'],
      trainingStyle: 'medium intensity',
      difficulty: 'intermediate',
      videoUrl: '',
      isCustom: false, // ✅ ADDED: Set isCustom to false for mock drills
    ),
    DrillModel(
      id: '550e8400-e29b-41d4-a716-446655440002',
      title: 'Quick Passing Drill',
      skill: 'Passing',
      subSkills: ['Short passing', 'One touch passing'],
      sets: 2,
      reps: 10,
      duration: 5,
      description: 'Improve passing accuracy and speed.',
      instructions: ['Pass and move', 'Keep passes low', 'Communicate'],
      tips: ['Look up', 'Follow through', 'Weight the pass'],
      equipment: ['soccer ball', 'cones'],
      trainingStyle: 'medium intensity',
      difficulty: 'beginner',
      videoUrl: '',
      isCustom: false, // ✅ ADDED: Set isCustom to false for mock drills
    ),
    DrillModel(
      id: '550e8400-e29b-41d4-a716-446655440003',
      title: 'Power Shot Training',
      skill: 'Shooting',
      subSkills: ['Power shots', 'First time shots'],
      sets: 3,
      reps: 8,
      duration: 10,
      description: 'Develop shooting power and accuracy.',
      instructions: ['Strike through the ball', 'Keep head down', 'Follow through'],
      tips: ['Plant foot firmly', 'Strike with inside of foot', 'Aim for corners'],
      equipment: ['soccer ball', 'goal'],
      trainingStyle: 'high intensity',
      difficulty: 'advanced',
      videoUrl: '',
      isCustom: false, // ✅ ADDED: Set isCustom to false for mock drills
    ),
    DrillModel(
      id: '550e8400-e29b-41d4-a716-446655440004',
      title: 'First Touch Control',
      skill: 'First Touch',
      subSkills: ['Ground control', 'Touch and move'],
      sets: 2,
      reps: 15,
      duration: 8,
      description: 'Master your first touch under pressure.',
      instructions: ['Receive ball cleanly', 'Touch away from pressure', 'Look up quickly'],
      tips: ['Cushion the ball', 'Use both feet', 'Keep ball close'],
      equipment: ['soccer ball'],
      trainingStyle: 'low intensity',
      difficulty: 'intermediate',
      videoUrl: '',
      isCustom: false, // ✅ ADDED: Set isCustom to false for mock drills
    ),
    DrillModel(
      id: '550e8400-e29b-41d4-a716-446655440005',
      title: 'Long Range Passing',
      skill: 'Passing',
      subSkills: ['Long passing', 'Technique'],
      sets: 2,
      reps: 12,
      duration: 6,
      description: 'Improve long distance passing accuracy.',
      instructions: ['Strike through center', 'Follow through high', 'Aim for target'],
      tips: ['Lean back slightly', 'Contact ball cleanly', 'Use full swing'],
      equipment: ['soccer ball', 'cones'],
      trainingStyle: 'medium intensity',
      difficulty: 'advanced',
      videoUrl: '',
      isCustom: false, // ✅ ADDED: Set isCustom to false for mock drills
    ),
    DrillModel(
      id: '550e8400-e29b-41d4-a716-446655440006',
      title: 'Ball Mastery Skills',
      skill: 'Dribbling',
      subSkills: ['Ball mastery', 'Speed dribbling'],
      sets: 1,
      reps: 20,
      duration: 4,
      description: 'Develop ball control and dribbling skills.',
      instructions: ['Use both feet', 'Keep head up', 'Vary pace'],
      tips: ['Small touches', 'Stay relaxed', 'Practice daily'],
      equipment: ['soccer ball'],
      trainingStyle: 'low intensity',
      difficulty: 'beginner',
      videoUrl: '',
      isCustom: false, // ✅ ADDED: Set isCustom to false for mock drills
    ),
    DrillModel(
      id: '550e8400-e29b-41d4-a716-446655440007',
      title: 'Advanced Shooting Combinations',
      skill: 'Shooting',
      subSkills: ['Finesse shots', 'Volleying'],
      sets: 2,
      reps: 6,
      duration: 12,
      description: 'Master advanced shooting techniques.',
      instructions: ['Setup touch', 'Shoot with accuracy', 'Follow through'],
      tips: ['Stay balanced', 'Keep eyes on ball', 'Practice both feet'],
      equipment: ['soccer ball', 'goal'],
      trainingStyle: 'high intensity',
      difficulty: 'advanced',
      videoUrl: '',
      isCustom: false, // ✅ ADDED: Set isCustom to false for mock drills
    ),
    DrillModel(
      id: '550e8400-e29b-41d4-a716-446655440008',
      title: 'Aerial Control Practice',
      skill: 'First Touch',
      subSkills: ['Aerial control', 'Juggling'],
      sets: 1,
      reps: 25,
      duration: 6,
      description: 'Improve control of balls in the air.',
      instructions: ['Watch the ball', 'Use all surfaces', 'Keep it up'],
      tips: ['Relax your body', 'Small touches', 'Be patient'],
      equipment: ['soccer ball'],
      trainingStyle: 'low intensity',
      difficulty: 'beginner',
      videoUrl: '',
      isCustom: false, // ✅ ADDED: Set isCustom to false for mock drills
    ),
  ];
} 