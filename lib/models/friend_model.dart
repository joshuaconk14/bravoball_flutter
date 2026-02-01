/// Friend Models
/// Models for friend system data structures

/// Friend model matching `/api/friends` response structure
class Friend {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;

  Friend({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
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
}

/// Friend request model matching `/api/friends/requests` response structure
class FriendRequest {
  final int requestId;
  final int requesterId;
  final String username;
  final String email;

  FriendRequest({
    required this.requestId,
    required this.requesterId,
    required this.username,
    required this.email,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      requestId: json['request_id'] ?? 0,
      requesterId: json['requester_id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId,
      'requester_id': requesterId,
      'username': username,
      'email': email,
    };
  }
}
