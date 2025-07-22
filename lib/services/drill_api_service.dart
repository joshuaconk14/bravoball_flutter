import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/api_response_models.dart';
import '../models/drill_model.dart';
import 'api_service.dart';

/// Drill API Service
/// Handles all drill-related API calls
/// Mirrors the Swift DrillSearchService functionality
class DrillApiService {
  static final DrillApiService _instance = DrillApiService._internal();
  factory DrillApiService() => _instance;
  DrillApiService._internal();

  static DrillApiService get shared => _instance;

  final ApiService _apiService = ApiService.shared;

  // MARK: - Search Drills

  /// Search for drills with various filter options
  /// Mirrors Swift's searchDrills method
  Future<DrillSearchResponse> searchDrills({
    String query = '',
    String? category,
    String? difficulty,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{
        'query': query,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      // Add optional parameters with proper mapping
      if (category != null && category.isNotEmpty) {
        // Map frontend skill name to backend category name
        final backendCategory = _mapSkillToBackendCategory(category);
        queryParams['category'] = backendCategory;
      }
      if (difficulty != null && difficulty.isNotEmpty) {
        queryParams['difficulty'] = difficulty;
      }

      // Determine which endpoint to use
      String endpoint;
      bool requiresAuth;

      if (AppConfig.useRealBackend) {
        // Use the authenticated endpoint for real backend
        endpoint = '/api/drills/search';
        requiresAuth = true;
      } else {
        // Use public endpoint for testing
        endpoint = '/public/drills/search';
        requiresAuth = false;
      }

      _logRequest('searchDrills', endpoint, queryParams);

      // Make the API request
      final response = await _apiService.get(
        endpoint,
        queryParameters: queryParams,
        requiresAuth: requiresAuth,
      );

      if (response.isSuccess && response.data != null) {
        final drillSearchResponse = DrillSearchResponse.fromJson(response.data!);
        _logSuccess('searchDrills', drillSearchResponse.items.length);
        return drillSearchResponse;
      } else {
        _logError('searchDrills', response.error ?? 'Unknown error');
        // Return empty response on error
        return DrillSearchResponse(
          items: [],
          total: 0,
          page: page,
          pageSize: limit,
          totalPages: 0,
        );
      }
    } catch (e) {
      _logError('searchDrills', e.toString());
      // Return empty response on exception
      return DrillSearchResponse(
        items: [],
        total: 0,
        page: page,
        pageSize: limit,
        totalPages: 0,
      );
    }
  }

  /// Get drills by category
  Future<List<DrillResponse>> getDrillsByCategory(String category) async {
    final response = await searchDrills(category: category, limit: 100);
    return response.items;
  }

  /// Get drills by difficulty
  Future<List<DrillResponse>> getDrillsByDifficulty(String difficulty) async {
    final response = await searchDrills(difficulty: difficulty, limit: 100);
    return response.items;
  }

  /// Get a specific drill by ID
  Future<DrillResponse?> getDrillById(String id) async {
    try {
      _logRequest('getDrillById', '/api/drills/$id', {});

      final response = await _apiService.get(
        '/api/drills/$id',
        requiresAuth: AppConfig.useRealBackend,
      );

      if (response.isSuccess && response.data != null) {
        final drillResponse = DrillResponse.fromJson(response.data!);
        _logSuccess('getDrillById', 1);
        return drillResponse;
      } else {
        _logError('getDrillById', response.error ?? 'Unknown error');
        return null;
      }
    } catch (e) {
      _logError('getDrillById', e.toString());
      return null;
    }
  }

  // MARK: - Conversion Methods

  /// Convert DrillResponse to local DrillModel
  DrillModel convertToLocalModel(DrillResponse drillResponse) {
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
      id: drillResponse.id.toString(), // Use the backend ID as UUID
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
      isCustom: drillResponse.isCustom, // ✅ UPDATED: Use the isCustom field from DrillResponse
    );
  }

  /// Convert multiple DrillResponse objects to local DrillModel objects
  List<DrillModel> convertToLocalModels(List<DrillResponse> drillResponses) {
    return drillResponses.map((response) => convertToLocalModel(response)).toList();
  }

  // MARK: - Mapping Methods

  /// Map frontend skill name to backend category name
  String _mapSkillToBackendCategory(String frontendSkill) {
    const skillToBackendMap = {
      'Passing': 'passing',
      'Shooting': 'shooting',
      'Dribbling': 'dribbling',
      'First Touch': 'first_touch',
      'Defending': 'defending',
      'Goalkeeping': 'goalkeeping', // ✅ ADDED: Missing goalkeeping mapping
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
      'goalkeeping': 'Goalkeeping', // ✅ ADDED: Missing goalkeeping mapping
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

  // MARK: - Mock Data Fallback
  
  /// Create mock drill search response for testing
  DrillSearchResponse createMockSearchResponse({
    int page = 1,
    int limit = 20,
    String query = '',
    String? category,
    String? difficulty,
  }) {
    final mockDrills = _getMockDrills();
    
    // Filter mock drills based on search criteria
    var filteredDrills = mockDrills.where((drill) {
      bool matchesQuery = query.isEmpty || 
          drill.title.toLowerCase().contains(query.toLowerCase()) ||
          drill.description.toLowerCase().contains(query.toLowerCase());
      
      bool matchesCategory = category == null || 
          drill.primarySkill?.category.toLowerCase() == category.toLowerCase();
      
      bool matchesDifficulty = difficulty == null || 
          drill.difficulty.toLowerCase() == difficulty.toLowerCase();
      
      return matchesQuery && matchesCategory && matchesDifficulty;
    }).toList();

    // Apply pagination
    final startIndex = (page - 1) * limit;
    final endIndex = (startIndex + limit).clamp(0, filteredDrills.length);
    final paginatedDrills = filteredDrills.sublist(
      startIndex.clamp(0, filteredDrills.length),
      endIndex,
    );

    return DrillSearchResponse(
      items: paginatedDrills,
      total: filteredDrills.length,
      page: page,
      pageSize: limit,
      totalPages: (filteredDrills.length / limit).ceil(),
    );
  }

  /// Get mock drill data for testing
  List<DrillResponse> _getMockDrills() {
    return [
      DrillResponse(
        id: '550e8400-e29b-41d4-a716-446655440001',
        title: 'One-Touch Passing Drill',
        description: 'Improve first-touch control and quick decision-making using the wall',
        type: 'passing',
        duration: 15,
        sets: 3,
        reps: 30,
        rest: 30,
        equipment: ['ball', 'wall'],
        suitableLocations: ['full_field', 'medium_field', 'indoor_court', 'backyard'],
        intensity: 'medium',
        trainingStyles: ['medium_intensity'],
        difficulty: 'beginner',
        primarySkill: SkillFocus(category: 'passing', subSkill: 'short_passing'),
        secondarySkills: [
          SkillFocus(category: 'first_touch', subSkill: 'ground_control'),
          SkillFocus(category: 'passing', subSkill: 'ball_control'),
        ],
        instructions: [
          'Stand 5 yards away from a wall with the ball.',
          'Pass the ball against the wall and immediately pass it back in one touch.',
        ],
        tips: [
          'Keep your ankle locked for better pass accuracy.',
          'Stay on your toes to react quickly to the return pass.',
        ],
        commonMistakes: [],
        progressionSteps: [],
        variations: [],
      ),
      DrillResponse(
        id: '550e8400-e29b-41d4-a716-446655440002',
        title: 'Cone Dribbling Challenge',
        description: 'Improve close control dribbling through a series of cones',
        type: 'dribbling',
        duration: 20,
        sets: 4,
        reps: 5,
        rest: 45,
        equipment: ['ball', 'cones'],
        suitableLocations: ['full_field', 'medium_field', 'indoor_court', 'backyard'],
        intensity: 'medium',
        trainingStyles: ['medium_intensity'],
        difficulty: 'beginner',
        primarySkill: SkillFocus(category: 'dribbling', subSkill: 'close_control'),
        secondarySkills: [
          SkillFocus(category: 'dribbling', subSkill: 'ball_mastery'),
          SkillFocus(category: 'fitness', subSkill: 'agility'),
        ],
        instructions: [
          'Set up 6 cones in a zig-zag pattern.',
          'Dribble through the cones as quickly as possible while maintaining control.',
        ],
        tips: [
          'Use both feet',
          'Keep the ball close to your feet',
          'Look up occasionally',
        ],
        commonMistakes: [],
        progressionSteps: [],
        variations: [],
      ),
      DrillResponse(
        id: '550e8400-e29b-41d4-a716-446655440003',
        title: 'Power Shooting Practice',
        description: 'Basic shooting drill to improve accuracy and power',
        type: 'shooting',
        duration: 25,
        sets: 3,
        reps: 10,
        rest: 60,
        equipment: ['ball', 'goal'],
        suitableLocations: ['full_field', 'medium_field'],
        intensity: 'high',
        trainingStyles: ['high_intensity'],
        difficulty: 'intermediate',
        primarySkill: SkillFocus(category: 'shooting', subSkill: 'power'),
        secondarySkills: [
          SkillFocus(category: 'shooting', subSkill: 'finishing'),
          SkillFocus(category: 'shooting', subSkill: 'ball_striking'),
        ],
        instructions: [
          'Place the ball 15 yards from goal',
          'Take a shot aiming for the corners',
        ],
        tips: [
          'Plant your non-kicking foot beside the ball',
          'Follow through with your shot',
          'Keep your head down',
        ],
        commonMistakes: [],
        progressionSteps: [],
        variations: [],
      ),
    ];
  }

  // MARK: - Debug Logging

  void _logRequest(String method, String endpoint, Map<String, String> params) {
    if (AppConfig.logApiCalls && kDebugMode) {
      print('🔍 DrillAPI Request: $method');
      print('   Endpoint: $endpoint');
      print('   Params: $params');
    }
  }

  void _logSuccess(String method, int count) {
    if (AppConfig.logApiCalls && kDebugMode) {
      print('✅ DrillAPI Success: $method - $count items');
    }
  }

  void _logError(String method, String error) {
    if (AppConfig.logApiCalls && kDebugMode) {
      print('❌ DrillAPI Error: $method - $error');
    }
  }
} 