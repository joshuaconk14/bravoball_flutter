import 'drill_model.dart';

class EditableDrillModel {
  final DrillModel drill;
  int setsDone;
  int totalSets;
  int totalReps;
  int totalDuration;
  bool isCompleted;

  EditableDrillModel({
    required this.drill,
    this.setsDone = 0,
    required this.totalSets,
    required this.totalReps,
    required this.totalDuration,
    this.isCompleted = false,
  });

  // Copy constructor for creating copies with modifications
  EditableDrillModel copyWith({
    DrillModel? drill,
    int? setsDone,
    int? totalSets,
    int? totalReps,
    int? totalDuration,
    bool? isCompleted,
  }) {
    return EditableDrillModel(
      drill: drill ?? this.drill,
      setsDone: setsDone ?? this.setsDone,
      totalSets: totalSets ?? this.totalSets,
      totalReps: totalReps ?? this.totalReps,
      totalDuration: totalDuration ?? this.totalDuration,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  // Calculate progress as a percentage
  double get progress {
    if (totalSets == 0) return 0.0;
    return (setsDone / totalSets).clamp(0.0, 1.0);
  }

  // Check if the drill is fully completed (not skipped)
  bool get isFullyCompleted {
    return isCompleted || setsDone >= totalSets;
  }

  // Check if the drill is done (either completed or skipped)
  bool get isDone {
    return isCompleted;
  }

  // Calculate time per set based on total duration
  double calculateSetDuration({int breakDuration = 45}) {
    if (totalSets <= 0) return 0.0;
    
    // Convert total duration to seconds
    final totalDurationSeconds = totalDuration * 60.0;
    
    // Calculate total break time
    final totalBreakSeconds = (totalSets - 1) * breakDuration.toDouble();
    
    // Calculate available time for sets
    final availableTimeForSets = totalDurationSeconds - totalBreakSeconds;
    
    // Ensure minimum set duration (10 seconds)
    const minimumSetDuration = 10.0;
    
    // Calculate base set duration
    var setDuration = availableTimeForSets / totalSets;
    
    // If set duration is too short, use minimum
    if (setDuration < minimumSetDuration) {
      setDuration = minimumSetDuration;
    }
    
    // Round to nearest 10 seconds
    return (setDuration / 10.0).round() * 10.0;
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'drill': drill.toJson(),
      'setsDone': setsDone,
      'totalSets': totalSets,
      'totalReps': totalReps,
      'totalDuration': totalDuration,
      'isCompleted': isCompleted,
    };
  }

  factory EditableDrillModel.fromJson(Map<String, dynamic> json) {
    return EditableDrillModel(
      drill: DrillModel.fromJson(json['drill']),
      setsDone: json['setsDone'] ?? json['sets_done'] ?? 0,
      totalSets: json['totalSets'] ?? json['sets'] ?? 0,
      totalReps: json['totalReps'] ?? json['reps'] ?? 0,
      totalDuration: json['totalDuration'] ?? json['duration'] ?? 0,
      isCompleted: json['isCompleted'] ?? json['is_completed'] ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EditableDrillModel) return false;
    return drill.id == other.drill.id;
  }

  @override
  int get hashCode => drill.id.hashCode;
} 