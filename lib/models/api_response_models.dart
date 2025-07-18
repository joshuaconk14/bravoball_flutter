/// API Response Models
/// These models mirror the backend API responses and Swift DrillResponse structure

/// Skill focus model matching backend structure
class SkillFocus {
  final String category;
  final String subSkill;

  SkillFocus({
    required this.category,
    required this.subSkill,
  });

  factory SkillFocus.fromJson(Map<String, dynamic> json) {
    return SkillFocus(
      category: json['category'] ?? '',
      subSkill: json['sub_skill'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'sub_skill': subSkill,
    };
  }
}

/// Drill response model matching backend DrillResponse
class DrillResponse {
  final String id; // Changed from int to String for UUIDs
  final String title;
  final String description;
  final String type;
  final int? duration;
  final int? sets;
  final int? reps;
  final int? rest;
  final List<String> equipment;
  final List<String> suitableLocations;
  final String intensity;
  final List<String> trainingStyles;
  final String difficulty;
  final SkillFocus? primarySkill;
  final List<SkillFocus> secondarySkills;
  final List<String> instructions;
  final List<String> tips;
  final List<String> commonMistakes;
  final List<String> progressionSteps;
  final List<String> variations;
  final String? videoUrl;
  final String? thumbnailUrl;
  final bool isCustom; // ✅ ADDED: is_custom field

  DrillResponse({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.duration,
    this.sets,
    this.reps,
    this.rest,
    required this.equipment,
    required this.suitableLocations,
    required this.intensity,
    required this.trainingStyles,
    required this.difficulty,
    this.primarySkill,
    required this.secondarySkills,
    required this.instructions,
    required this.tips,
    required this.commonMistakes,
    required this.progressionSteps,
    required this.variations,
    this.videoUrl,
    this.thumbnailUrl,
    this.isCustom = false, // ✅ ADDED: Default to false
  });

  factory DrillResponse.fromJson(Map<String, dynamic> json) {
    return DrillResponse(
      id: json['uuid']?.toString() ?? json['id']?.toString() ?? '', // Look for 'uuid' first, then 'id'
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? '',
      duration: json['duration'] as int?,
      sets: json['sets'] as int?,
      reps: json['reps'] as int?,
      rest: json['rest'] as int?,
      equipment: List<String>.from(json['equipment'] ?? []),
      suitableLocations: List<String>.from(json['suitable_locations'] ?? []),
      intensity: json['intensity'] ?? 'medium',
      trainingStyles: List<String>.from(json['training_styles'] ?? []),
      difficulty: json['difficulty'] ?? 'beginner',
      primarySkill: json['primary_skill'] != null 
          ? SkillFocus.fromJson(json['primary_skill'])
          : null,
      secondarySkills: (json['secondary_skills'] as List<dynamic>? ?? [])
          .map((skill) => SkillFocus.fromJson(skill))
          .toList(),
      instructions: List<String>.from(json['instructions'] ?? []),
      tips: List<String>.from(json['tips'] ?? []),
      commonMistakes: List<String>.from(json['common_mistakes'] ?? []),
      progressionSteps: List<String>.from(json['progression_steps'] ?? []),
      variations: List<String>.from(json['variations'] ?? []),
      videoUrl: json['video_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      isCustom: json['is_custom'] ?? false, // ✅ ADDED: Parse is_custom field
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': id, // Send as 'uuid' to match backend expectations
      'title': title,
      'description': description,
      'type': type,
      'duration': duration,
      'sets': sets,
      'reps': reps,
      'rest': rest,
      'equipment': equipment,
      'suitable_locations': suitableLocations,
      'intensity': intensity,
      'training_styles': trainingStyles,
      'difficulty': difficulty,
      'primary_skill': primarySkill?.toJson(),
      'secondary_skills': secondarySkills.map((skill) => skill.toJson()).toList(),
      'instructions': instructions,
      'tips': tips,
      'common_mistakes': commonMistakes,
      'progression_steps': progressionSteps,
      'variations': variations,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'is_custom': isCustom, // ✅ ADDED: Include is_custom field in JSON
    };
  }
}

/// Drill search response with pagination
class DrillSearchResponse {
  final List<DrillResponse> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  DrillSearchResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory DrillSearchResponse.fromJson(Map<String, dynamic> json) {
    return DrillSearchResponse(
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => DrillResponse.fromJson(item))
          .toList(),
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['page_size'] ?? 20,
      totalPages: json['total_pages'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
      'page': page,
      'page_size': pageSize,
      'total_pages': totalPages,
    };
  }

  /// Check if there are more pages
  bool get hasNextPage => page < totalPages;
  
  /// Check if there are previous pages
  bool get hasPreviousPage => page > 1;
}

/// Generic API error response
class ApiErrorResponse {
  final String detail;
  final int? code;

  ApiErrorResponse({
    required this.detail,
    this.code,
  });

  factory ApiErrorResponse.fromJson(Map<String, dynamic> json) {
    return ApiErrorResponse(
      detail: json['detail'] ?? 'Unknown error',
      code: json['code'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'detail': detail,
      'code': code,
    };
  }
}

/// Generic paginated response wrapper
class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  PaginatedResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .map((item) => fromJson(item))
        .toList();
    
    final page = json['page'] ?? 1;
    final totalPages = json['total_pages'] ?? 1;
    
    return PaginatedResponse(
      items: items,
      total: json['total'] ?? 0,
      page: page,
      pageSize: json['page_size'] ?? 20,
      totalPages: totalPages,
      hasNextPage: page < totalPages,
      hasPreviousPage: page > 1,
    );
  }
} 