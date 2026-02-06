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
