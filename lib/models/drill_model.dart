import 'package:flutter/foundation.dart';

class DrillModel {
  final String id; // This will store the UUID from backend
  final String title;
  final String skill;
  final List<String> subSkills;
  final int sets;
  final int reps;
  final int duration;
  final String description;
  final List<String> instructions;
  final List<String> tips;
  final List<String> equipment;
  final String trainingStyle;
  final String difficulty;
  final String videoUrl;

  DrillModel({
    required this.id,
    required this.title,
    required this.skill,
    required this.subSkills,
    this.sets = 0,
    this.reps = 0,
    required this.duration,
    required this.description,
    required this.instructions,
    required this.tips,
    required this.equipment,
    required this.trainingStyle,
    required this.difficulty,
    required this.videoUrl,
  });

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'uuid': id, // Use 'uuid' for backend compatibility
      'title': title,
      'skill': skill,
      'subSkills': subSkills,
      'sets': sets,
      'reps': reps,
      'duration': duration,
      'description': description,
      'instructions': instructions,
      'tips': tips,
      'equipment': equipment,
      'trainingStyle': trainingStyle,
      'difficulty': difficulty,
      'videoUrl': videoUrl,
    };
  }

  factory DrillModel.fromJson(Map<String, dynamic> json) {
    // Handle both 'uuid' (new backend format) and 'id' (legacy format)
    final drillId = json['uuid'] ?? json['id'] ?? '';
    
    return DrillModel(
      id: drillId,
      title: json['title'] ?? '',
      skill: json['skill'] ?? '',
      subSkills: List<String>.from(json['subSkills'] ?? []),
      sets: json['sets'] ?? 0,
      reps: json['reps'] ?? 0,
      duration: json['duration'] ?? 0,
      description: json['description'] ?? '',
      instructions: List<String>.from(json['instructions'] ?? []),
      tips: List<String>.from(json['tips'] ?? []),
      equipment: List<String>.from(json['equipment'] ?? []),
      trainingStyle: json['trainingStyle'] ?? '',
      difficulty: json['difficulty'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DrillModel) return false;
    return id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
} 