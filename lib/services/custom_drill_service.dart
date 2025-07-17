import 'package:flutter/foundation.dart';
import '../models/drill_model.dart';
import '../models/api_response_models.dart';
import 'api_service.dart';

/// Service for creating and managing custom drills
class CustomDrillService {
  static final CustomDrillService _instance = CustomDrillService._internal();
  factory CustomDrillService() => _instance;
  CustomDrillService._internal();

  static CustomDrillService get shared => _instance;

  final ApiService _apiService = ApiService.shared;

  /// Create a custom drill
  Future<DrillModel?> createCustomDrill({
    required String title,
    required String description,
    required String skill,
    required List<String> subSkills,
    required int sets,
    required int reps,
    required int duration,
    required List<String> instructions,
    required List<String> tips,
    required List<String> equipment,
    required String trainingStyle,
    required String difficulty,
    String videoUrl = '',
  }) async {
    try {
      if (kDebugMode) {
        print('📤 Creating custom drill: $title');
      }

      // Map frontend skill to backend category
      final backendCategory = _mapSkillToBackendCategory(skill);
      
      // Map training style to intensity
      final intensity = _mapTrainingStyleToIntensity(trainingStyle);

      final requestBody = {
        'title': title,
        'description': description,
        'type': backendCategory,
        'duration': duration,
        'sets': sets,
        'reps': reps,
        'equipment': equipment,
        'suitable_locations': ['full_field', 'medium_field'],
        'intensity': intensity,
        'training_styles': [trainingStyle],
        'difficulty': difficulty.toLowerCase(),
        'primary_skill': {
          'category': backendCategory,
          'sub_skill': subSkills.isNotEmpty ? subSkills.first : 'general',
        },
        'secondary_skills': subSkills.skip(1).map((subSkill) => {
          'category': backendCategory,
          'sub_skill': subSkill,
        }).toList(),
        'instructions': instructions,
        'tips': tips,
        'common_mistakes': [],
        'progression_steps': [],
        'variations': [],
        'video_url': videoUrl,
      };

      final response = await _apiService.post(
        '/api/custom-drills/',
        body: requestBody,
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        final drillResponse = DrillResponse.fromJson(response.data!);
        final drillModel = _convertToLocalModel(drillResponse);
        
        if (kDebugMode) {
          print('✅ Successfully created custom drill: ${drillModel.title}');
        }
        
        return drillModel;
      } else {
        if (kDebugMode) {
          print('❌ Failed to create custom drill: ${response.statusCode} ${response.error}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating custom drill: $e');
      }
      return null;
    }
  }

  /// Convert DrillResponse to local DrillModel
  DrillModel _convertToLocalModel(DrillResponse drillResponse) {
    // Get the primary skill category, defaulting to "General" if not available
    final skillCategory = drillResponse.primarySkill?.category ?? 'General';
    
    // Collect all sub-skills from both primary and secondary skills
    final allSubSkills = <String>[];
    if (drillResponse.primarySkill?.subSkill != null) {
      allSubSkills.add(drillResponse.primarySkill!.subSkill);
    }
    allSubSkills.addAll(
      drillResponse.secondarySkills.map((skill) => skill.subSkill),
    );

    // Map intensity to training style
    final trainingStyle = _mapIntensityToTrainingStyle(drillResponse.intensity);

    return DrillModel(
      id: drillResponse.id.toString(),
      title: drillResponse.title,
      skill: _mapSkillCategory(skillCategory),
      subSkills: allSubSkills,
      sets: drillResponse.sets ?? 0,
      reps: drillResponse.reps ?? 0,
      duration: drillResponse.duration ?? 10,
      description: drillResponse.description,
      instructions: drillResponse.instructions,
      tips: drillResponse.tips,
      equipment: drillResponse.equipment,
      trainingStyle: trainingStyle,
      difficulty: _mapDifficulty(drillResponse.difficulty),
      videoUrl: drillResponse.videoUrl ?? '',
    );
  }

  /// Map frontend skill name to backend category name
  String _mapSkillToBackendCategory(String frontendSkill) {
    const skillToBackendMap = {
      'Passing': 'passing',
      'Shooting': 'shooting',
      'Dribbling': 'dribbling',
      'First Touch': 'first_touch',
      'Defending': 'defending',
      'Fitness': 'fitness',
    };
    
    return skillToBackendMap[frontendSkill] ?? frontendSkill.toLowerCase();
  }

  /// Map API skill category to app skill category
  String _mapSkillCategory(String apiCategory) {
    const skillMap = {
      'passing': 'Passing',
      'shooting': 'Shooting',
      'dribbling': 'Dribbling',
      'first_touch': 'First Touch',
      'fitness': 'Fitness',
      'defending': 'Defending',
    };
    
    return skillMap[apiCategory.toLowerCase()] ?? apiCategory;
  }

  /// Map API difficulty to app difficulty
  String _mapDifficulty(String apiDifficulty) {
    const difficultyMap = {
      'beginner': 'Beginner',
      'intermediate': 'Intermediate',
      'advanced': 'Advanced',
    };
    
    return difficultyMap[apiDifficulty.toLowerCase()] ?? apiDifficulty;
  }

  /// Map intensity to training style
  String _mapIntensityToTrainingStyle(String intensity) {
    switch (intensity.toLowerCase()) {
      case 'low':
        return 'low intensity';
      case 'medium':
        return 'medium intensity';
      case 'high':
        return 'high intensity';
      default:
        return 'medium intensity';
    }
  }

  /// Map training style to intensity
  String _mapTrainingStyleToIntensity(String trainingStyle) {
    switch (trainingStyle.toLowerCase()) {
      case 'low':
        return 'low';
      case 'medium':
        return 'medium';
      case 'high':
        return 'high';
      default:
        return 'medium';
    }
  }
} 