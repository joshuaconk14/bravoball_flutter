import 'package:flutter/foundation.dart';

class DrillModel {
  final String id;
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DrillModel) return false;
    return id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
} 