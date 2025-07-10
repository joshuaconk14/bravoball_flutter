import 'api_response_models.dart';

/// Drill group response from backend
class DrillGroupResponse {
  final int id;
  final String name;
  final String description;
  final List<DrillResponse> drills;
  final bool isLikedGroup;

  DrillGroupResponse({
    required this.id,
    required this.name,
    required this.description,
    required this.drills,
    required this.isLikedGroup,
  });

  factory DrillGroupResponse.fromJson(Map<String, dynamic> json) {
    try {
      return DrillGroupResponse(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        drills: (json['drills'] as List<dynamic>? ?? [])
            .map((drill) => DrillResponse.fromJson(drill))
            .toList(),
        isLikedGroup: json['is_liked_group'] ?? false,
      );
    } catch (e) {
      print('❌ Error parsing DrillGroupResponse: $e');
      print('❌ JSON data: $json');
      // Return a default response on error
      return DrillGroupResponse(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        drills: [],
        isLikedGroup: json['is_liked_group'] ?? false,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'drills': drills.map((drill) => drill.toJson()).toList(),
      'is_liked_group': isLikedGroup,
    };
  }
}

/// Drill group request for creating/updating
class DrillGroupRequest {
  final String name;
  final String description;
  final List<String> drillUuids; // Changed from drillIds to drillUuids to match backend
  final bool isLikedGroup;

  DrillGroupRequest({
    required this.name,
    required this.description,
    required this.drillUuids,
    required this.isLikedGroup,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'drill_uuids': drillUuids, // Changed from drill_ids to drill_uuids to match backend
      'is_liked_group': isLikedGroup,
    };
  }
}

/// Drill like response
class DrillLikeResponse {
  final String message;
  final bool isLiked;

  DrillLikeResponse({
    required this.message,
    required this.isLiked,
  });

  factory DrillLikeResponse.fromJson(Map<String, dynamic> json) {
    return DrillLikeResponse(
      message: json['message'] ?? '',
      isLiked: json['is_liked'] ?? false,
    );
  }
}

/// Is liked response
class IsLikedResponse {
  final bool isLiked;

  IsLikedResponse({
    required this.isLiked,
  });

  factory IsLikedResponse.fromJson(Map<String, dynamic> json) {
    return IsLikedResponse(
      isLiked: json['is_liked'] ?? false,
    );
  }
} 