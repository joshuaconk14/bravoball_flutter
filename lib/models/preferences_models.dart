/// Preferences API Models
/// Mirrors Swift SessionPreferencesRequest and PreferencesUpdateResponse structures

/// Request model for updating session preferences
class SessionPreferencesRequest {
  final int duration;
  final List<String> availableEquipment;
  final String? trainingStyle;
  final String? trainingLocation;
  final String? difficulty;
  final List<String> targetSkills;

  SessionPreferencesRequest({
    required this.duration,
    required this.availableEquipment,
    this.trainingStyle,
    this.trainingLocation,
    this.difficulty,
    required this.targetSkills,
  });

  Map<String, dynamic> toJson() {
    return {
      'duration': duration,
      'available_equipment': availableEquipment,
      'training_style': trainingStyle,
      'training_location': trainingLocation,
      'difficulty': difficulty,
      'target_skills': targetSkills,
    };
  }
}

/// Response model for preferences update
class PreferencesUpdateResponse {
  final String status;
  final String message;
  final SessionData? data;

  PreferencesUpdateResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory PreferencesUpdateResponse.fromJson(Map<String, dynamic> json) {
    return PreferencesUpdateResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] != null ? SessionData.fromJson(json['data']) : null,
    );
  }
}

/// Session data structure in preferences response
class SessionData {
  final int sessionId;
  final int totalDuration;
  final List<String> focusAreas;
  final List<DrillResponse> drills;

  SessionData({
    required this.sessionId,
    required this.totalDuration,
    required this.focusAreas,
    required this.drills,
  });

  factory SessionData.fromJson(Map<String, dynamic> json) {
    return SessionData(
      sessionId: json['session_id'] ?? 0,
      totalDuration: json['total_duration'] ?? 0,
      focusAreas: List<String>.from(json['focus_areas'] ?? []),
      drills: (json['drills'] as List? ?? [])
          .map((drill) => DrillResponse.fromJson(drill))
          .toList(),
    );
  }
}

/// Drill response structure
class DrillResponse {
  final int id;
  final String title;
  final String description;
  final int duration;
  final String intensity;
  final String difficulty;
  final List<String> equipment;
  final List<String> suitableLocations;
  final List<String> instructions;
  final List<String> tips;
  final String type;
  final int sets;
  final int reps;
  final int? rest;
  final Map<String, dynamic>? primarySkill;
  final List<Map<String, dynamic>>? secondarySkills;
  final String videoUrl;
  final bool isCustom; // ✅ ADDED: is_custom field for consistency

  DrillResponse({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.intensity,
    required this.difficulty,
    required this.equipment,
    required this.suitableLocations,
    required this.instructions,
    required this.tips,
    required this.type,
    required this.sets,
    required this.reps,
    this.rest,
    this.primarySkill,
    this.secondarySkills,
    required this.videoUrl,
    this.isCustom = false, // ✅ ADDED: Default to false
  });

  factory DrillResponse.fromJson(Map<String, dynamic> json) {
    return DrillResponse(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      duration: json['duration'] ?? 0,
      intensity: json['intensity'] ?? '',
      difficulty: json['difficulty'] ?? '',
      equipment: List<String>.from(json['equipment'] ?? []),
      suitableLocations: List<String>.from(json['suitable_locations'] ?? []),
      instructions: List<String>.from(json['instructions'] ?? []),
      tips: List<String>.from(json['tips'] ?? []),
      type: json['type'] ?? '',
      sets: json['sets'] ?? 0,
      reps: json['reps'] ?? 0,
      rest: json['rest'],
      primarySkill: json['primary_skill'],
      secondarySkills: json['secondary_skills'] != null
          ? List<Map<String, dynamic>>.from(json['secondary_skills'])
          : null,
      videoUrl: json['video_url'] ?? '',
      isCustom: json['is_custom'] ?? false, // ✅ ADDED: Parse is_custom field
    );
  }
}

/// Response model for fetching preferences
class PreferencesResponse {
  final String status;
  final String message;
  final PreferencesData data;

  PreferencesResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory PreferencesResponse.fromJson(Map<String, dynamic> json) {
    return PreferencesResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: PreferencesData.fromJson(json['data'] ?? {}),
    );
  }
}

/// Preferences data structure
class PreferencesData {
  final int? duration;
  final List<String>? availableEquipment;
  final String? trainingStyle;
  final String? trainingLocation;
  final String? difficulty;
  final List<String>? targetSkills;

  PreferencesData({
    this.duration,
    this.availableEquipment,
    this.trainingStyle,
    this.trainingLocation,
    this.difficulty,
    this.targetSkills,
  });

  factory PreferencesData.fromJson(Map<String, dynamic> json) {
    return PreferencesData(
      duration: json['duration'],
      availableEquipment: json['available_equipment'] != null
          ? List<String>.from(json['available_equipment'])
          : null,
      trainingStyle: json['training_style'],
      trainingLocation: json['training_location'],
      difficulty: json['difficulty'],
      targetSkills: json['target_skills'] != null
          ? List<String>.from(json['target_skills'])
          : null,
    );
  }
} 