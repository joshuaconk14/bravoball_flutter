import 'package:flutter/material.dart';
import '../utils/avatar_helper.dart';

/// Leaderboard Models
/// Models for leaderboard data structures

/// Leaderboard entry model matching backend response structure
class LeaderboardEntry {
  final int id;
  final String username;
  final int points;
  final int sessionsCompleted;
  final int rank;
  final String? avatarPath;
  final String? avatarBackgroundColor;

  LeaderboardEntry({
    required this.id,
    required this.username,
    required this.points,
    required this.sessionsCompleted,
    required this.rank,
    this.avatarPath,
    this.avatarBackgroundColor,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      points: json['points'] ?? 0,
      sessionsCompleted: json['sessions_completed'] ?? 0,
      rank: json['rank'] ?? 0,
      avatarPath: json['avatar_path'] as String?,
      avatarBackgroundColor: json['avatar_background_color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'points': points,
      'sessions_completed': sessionsCompleted,
      'rank': rank,
      'avatar_path': avatarPath,
      'avatar_background_color': avatarBackgroundColor,
    };
  }

  /// Get avatar path with fallback to default
  String get displayAvatarPath {
    return avatarPath ?? AvatarHelper.getDefaultAvatar();
  }

  /// Get background color with fallback to default
  Color get displayBackgroundColor {
    if (avatarBackgroundColor != null) {
      return AvatarHelper.hexToColor(avatarBackgroundColor) ?? 
          AvatarHelper.getDefaultBackgroundColor();
    }
    return AvatarHelper.getDefaultBackgroundColor();
  }
}

/// World leaderboard response model
/// Contains top 50 users and the current user's rank
class WorldLeaderboardResponse {
  final List<LeaderboardEntry> top50;
  final LeaderboardEntry userRank;

  WorldLeaderboardResponse({
    required this.top50,
    required this.userRank,
  });

  factory WorldLeaderboardResponse.fromJson(Map<String, dynamic> json) {
    // Parse top 50 entries
    final List<dynamic> top50Json = json['top_50'] is List
        ? json['top_50'] as List<dynamic>
        : [];
    
    final List<LeaderboardEntry> top50 = top50Json
        .map((entry) => LeaderboardEntry.fromJson(entry as Map<String, dynamic>))
        .toList();

    // Parse user rank entry
    final LeaderboardEntry userRank = LeaderboardEntry.fromJson(
      json['user_rank'] as Map<String, dynamic>,
    );

    return WorldLeaderboardResponse(
      top50: top50,
      userRank: userRank,
    );
  }

  /// Check if user is in top 50
  bool get isUserInTop50 {
    return top50.any((entry) => entry.id == userRank.id);
  }
}
