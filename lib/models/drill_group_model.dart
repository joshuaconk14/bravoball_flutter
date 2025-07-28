import 'drill_model.dart';

class DrillGroup {
  final String id;
  final String name;
  final String description;
  final List<DrillModel> drills;
  final DateTime createdAt;
  final bool isLikedDrillsGroup;

  DrillGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.drills,
    required this.createdAt,
    this.isLikedDrillsGroup = false,
  });

  DrillGroup copyWith({
    String? id,
    String? name,
    String? description,
    List<DrillModel>? drills,
    DateTime? createdAt,
    bool? isLikedDrillsGroup,
  }) {
    return DrillGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      drills: drills ?? this.drills,
      createdAt: createdAt ?? this.createdAt,
      isLikedDrillsGroup: isLikedDrillsGroup ?? this.isLikedDrillsGroup,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'drills': drills.map((drill) => drill.id).toList(),
      'createdAt': createdAt.toIso8601String(),
      'isLikedDrillsGroup': isLikedDrillsGroup,
    };
  }

  static DrillGroup fromJson(Map<String, dynamic> json, List<DrillModel> allDrills) {
    final drillIds = List<String>.from(json['drills'] ?? []);
    final groupDrills = drillIds
        .map((id) => allDrills.firstWhere(
              (drill) => drill.id == id,
              orElse: () => throw StateError('Drill with id $id not found'),
            ))
        .toList();

    return DrillGroup(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      drills: groupDrills,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isLikedDrillsGroup: json['isLikedDrillsGroup'] ?? false,
    );
  }
} 