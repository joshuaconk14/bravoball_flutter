import 'package:flutter/material.dart';
import '../utils/avatar_helper.dart';

/// Friend Models
/// Models for friend system data structures

/// Friend model matching `/api/friends` response structure
class Friend {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? avatarPath;
  final String? avatarBackgroundColor;

  Friend({
    required this.id,
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
