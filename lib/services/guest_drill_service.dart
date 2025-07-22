import 'package:flutter/foundation.dart';
import '../models/drill_model.dart';
import '../config/app_config.dart';
import 'api_service.dart';

/// Service for handling drill data specifically for guest users
/// Uses public endpoints that don't require authentication
class GuestDrillService {
  static final GuestDrillService _instance = GuestDrillService._internal();
  factory GuestDrillService() => _instance;
  GuestDrillService._internal();

  static GuestDrillService get shared => _instance;

  final ApiService _apiService = ApiService.shared;

  /// Fetch limited drill set for guest users
  Future<List<DrillModel>> fetchGuestDrills() async {
    try {
      if (kDebugMode) {
        print('📥 GuestDrillService: Fetching limited drills for guest mode');
      }

      final response = await _apiService.get(
        '/public/drills/limited',
        requiresAuth: false,
      );

      if (response.isSuccess && response.data != null) {
        final List<dynamic> drillsJson = response.data!['drills'] ?? [];
        final drills = drillsJson.map((drillJson) {
          return _convertBackendDrillToModel(drillJson);
        }).toList();

        if (kDebugMode) {
          print('✅ GuestDrillService: Successfully fetched ${drills.length} guest drills');
          print('   Categories: ${response.data!['categories_included']}');
        }
        return drills;
      } else {
        if (kDebugMode) {
          print('❌ GuestDrillService: Failed to fetch guest drills: ${response.statusCode} ${response.error}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ GuestDrillService: Error fetching guest drills: $e');
      }
      return [];
    }
  }

  /// Search guest drills with limited results to encourage account creation
  Future<List<DrillModel>> searchGuestDrills({
    String? query,
    String? category,
    String? difficulty,
    int page = 1,
    int limit = 15,
  }) async {
    try {
      if (kDebugMode) {
        print('👤 Searching guest drills: query="$query", category="$category", difficulty="$difficulty"');
      }

      // ✅ UPDATED: For guests, always return all available drills (ignore pagination)
      // This ensures guests see their full limited catalog at once
      final response = await _apiService.get(
        '/public/drills/search/limited',
        queryParameters: {
          if (query != null && query.isNotEmpty) 'query': query,
          if (category != null) 'category': category,
          if (difficulty != null) 'difficulty': difficulty,
          'page': '1', // Always start from page 1
          'limit': '50', // Get all available guest drills at once
        },
        requiresAuth: false,
      );

      if (response.isSuccess && response.data != null) {
        final items = response.data!['items'] as List<dynamic>? ?? [];
        final drills = items.map((item) => _convertBackendDrillToModel(item)).toList();
        
        if (kDebugMode) {
          print('✅ Guest search returned ${drills.length} drills (showing all available)');
        }
        
        return drills;
      } else {
        if (kDebugMode) {
          print('❌ Failed to search guest drills: ${response.statusCode}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error searching guest drills: $e');
      }
      return [];
    }
  }

  /// Convert backend drill response to DrillModel
  DrillModel _convertBackendDrillToModel(Map<String, dynamic> drillJson) {
    // Handle the skill focus data
    String skill = 'General';
    List<String> subSkills = [];

    // Try to get skill from primary_skill first
    if (drillJson['primary_skill'] != null) {
      final primarySkill = drillJson['primary_skill'];
      skill = _mapSkillCategory(primarySkill['category'] ?? 'general');
      if (primarySkill['sub_skill'] != null) {
        subSkills.add(_mapSubSkill(primarySkill['sub_skill']));
      }
    }

    // Fallback to category if no primary_skill
    if (skill == 'General' && drillJson['category'] != null) {
      skill = _mapSkillCategory(drillJson['category']);
    }

    // Get equipment list
    List<String> equipment = [];
    if (drillJson['equipment'] is List) {
      equipment = (drillJson['equipment'] as List).cast<String>();
    }

    // Get instructions list
    List<String> instructions = [];
    if (drillJson['instructions'] is List) {
      instructions = (drillJson['instructions'] as List).cast<String>();
    }

    // Get tips list
    List<String> tips = [];
    if (drillJson['tips'] is List) {
      tips = (drillJson['tips'] as List).cast<String>();
    }

    return DrillModel(
      id: drillJson['uuid'] ?? drillJson['id'] ?? '',
      title: drillJson['title'] ?? 'Unnamed Drill',
      skill: skill,
      subSkills: subSkills,
      sets: drillJson['sets'] ?? 3,
      reps: drillJson['reps'] ?? 10,
      duration: drillJson['duration'] ?? 10,
      description: drillJson['description'] ?? '',
      instructions: instructions,
      tips: tips,
      equipment: equipment,
      trainingStyle: drillJson['intensity'] ?? drillJson['training_style'] ?? 'medium',
      difficulty: drillJson['difficulty'] ?? 'beginner',
      videoUrl: drillJson['video_url'] ?? '',
      isCustom: false, // ✅ ADDED: Set isCustom to false for guest drills
    );
  }

  /// Helper: Map backend skill category to frontend display name
  String _mapSkillCategory(String backendCategory) {
    const categoryMap = {
      'passing': 'Passing',
      'shooting': 'Shooting',
      'dribbling': 'Dribbling',
      'first_touch': 'First Touch',
      'defending': 'Defending',
      'fitness': 'Fitness',
      'goalkeeping': 'Goalkeeping', // ✅ ADDED: Missing goalkeeping mapping
      'general': 'General',
    };
    
    return categoryMap[backendCategory.toLowerCase()] ?? 'General';
  }

  /// Helper: Map backend sub-skill to frontend display name
  String _mapSubSkill(String backendSubSkill) {
    const subSkillMap = {
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
      'positioning': 'Positioning',
      
      // Fallback
      'general': 'General',
    };
    
    return subSkillMap[backendSubSkill.toLowerCase()] ?? backendSubSkill;
  }
} 