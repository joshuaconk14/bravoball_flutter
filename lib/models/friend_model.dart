import 'package:flutter/material.dart';
import '../utils/avatar_helper.dart';

/// Friend Models
/// Models for friend system data structures

/// Friend model matching `/api/friends` response structure
class Friend {
  final int id; // User ID
  final int friendshipId; // Friendship record ID (from friendships table)
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? avatarPath;
  final String? avatarBackgroundColor;

  Friend({
    required this.id,
    required this.friendshipId,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.avatarPath,
    this.avatarBackgroundColor,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] ?? 0,
      friendshipId: json['friendship_id'] ?? json['friendshipId'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      avatarPath: json['avatar_path'] as String?,
      avatarBackgroundColor: json['avatar_background_color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'friendship_id': friendshipId,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'avatar_path': avatarPath,
      'avatar_background_color': avatarBackgroundColor,
    };
  }

  /// Get display name (username or full name if available)
  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    }
    return username;
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

/// Friend request model matching `/api/friends/requests` response structure
class FriendRequest {
  final int requestId;
  final int requesterId;
  final String username;
  final String email;
  final String? avatarPath;
  final String? avatarBackgroundColor;

  FriendRequest({
    required this.requestId,
    required this.requesterId,
    required this.username,
    required this.email,
    this.avatarPath,
    this.avatarBackgroundColor,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      requestId: json['request_id'] ?? 0,
      requesterId: json['requester_id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      avatarPath: json['avatar_path'] as String?,
      avatarBackgroundColor: json['avatar_background_color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId,
      'requester_id': requesterId,
      'username': username,
      'email': email,
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

/// User lookup result model for username search
class UserLookupResult {
  final int userId;
  final String username;
  final String? avatarPath;
  final String? avatarBackgroundColor;

  UserLookupResult({
    required this.userId,
    required this.username,
    this.avatarPath,
    this.avatarBackgroundColor,
  });

  factory UserLookupResult.fromJson(Map<String, dynamic> json) {
    return UserLookupResult(
      userId: json['user_id'] ?? 0,
      username: json['username'] ?? '',
      avatarPath: json['avatar_path'] as String?,
      avatarBackgroundColor: json['avatar_background_color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
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

/// Friend detail model for `/api/friends/{user_id}` response
/// Contains friend information and stats
class FriendDetail {
  final int id; // User ID
  final int friendshipId; // Friendship record ID
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? avatarPath;
  final String? avatarBackgroundColor;
  final int points;
  final int sessionsCompleted;
  final int rank; // Rank among friends (or world rank if not in friends leaderboard)
  final int currentStreak;
  final int highestStreak;
  final String? favoriteDrill;
  final DateTime? lastActive; // When they last completed a session
  final int totalPracticeMinutes; // Total minutes across all sessions

  FriendDetail({
    required this.id,
    required this.friendshipId,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.avatarPath,
    this.avatarBackgroundColor,
    required this.points,
    required this.sessionsCompleted,
    required this.rank,
    required this.currentStreak,
    required this.highestStreak,
    this.favoriteDrill,
    this.lastActive,
    required this.totalPracticeMinutes,
  });

  factory FriendDetail.fromJson(Map<String, dynamic> json) {
    // Parse last_active timestamp if present
    DateTime? lastActive;
    if (json['last_active'] != null) {
      try {
        if (json['last_active'] is String) {
          lastActive = DateTime.parse(json['last_active'] as String);
        } else if (json['last_active'] is int) {
          // Unix timestamp in seconds
          lastActive = DateTime.fromMillisecondsSinceEpoch(
            (json['last_active'] as int) * 1000,
          );
        }
      } catch (e) {
        // If parsing fails, leave as null
        lastActive = null;
      }
    }

    return FriendDetail(
      id: json['id'] ?? 0,
      friendshipId: json['friendship_id'] ?? json['friendshipId'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      avatarPath: json['avatar_path'] as String?,
      avatarBackgroundColor: json['avatar_background_color'] as String?,
      points: json['points'] ?? 0,
      sessionsCompleted: json['sessions_completed'] ?? 0,
      rank: json['rank'] ?? 0,
      currentStreak: json['current_streak'] ?? 0,
      highestStreak: json['highest_streak'] ?? 0,
      favoriteDrill: json['favorite_drill'] as String?,
      lastActive: lastActive,
      totalPracticeMinutes: json['total_practice_minutes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'friendship_id': friendshipId,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'avatar_path': avatarPath,
      'avatar_background_color': avatarBackgroundColor,
      'points': points,
      'sessions_completed': sessionsCompleted,
      'rank': rank,
      'current_streak': currentStreak,
      'highest_streak': highestStreak,
      'favorite_drill': favoriteDrill,
      'last_active': lastActive?.toIso8601String(),
      'total_practice_minutes': totalPracticeMinutes,
    };
  }

  /// Get display name (username or full name if available)
  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    }
    return username;
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