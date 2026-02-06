/// Authentication Models
/// Mirrors Swift LoginModel and LoginResponse structures

/// Login request model for API calls
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

/// Login response model from backend
class LoginResponse {
  final String accessToken;
  final String tokenType;
  final String email;
  final String username;
  final String? refreshToken;
  final String? avatarPath;
  final String? avatarBackgroundColor;

  LoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.email,
    required this.username,
    this.refreshToken,
    this.avatarPath,
    this.avatarBackgroundColor,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'] ?? '',
      tokenType: json['token_type'] ?? 'bearer',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      refreshToken: json['refresh_token'] as String?,
      avatarPath: json['avatar_path'] as String?,
      avatarBackgroundColor: json['avatar_background_color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'email': email,
      'username': username,
      'refresh_token': refreshToken,
      'avatar_path': avatarPath,
      'avatar_background_color': avatarBackgroundColor,
    };
  }
}

/// Email check request for validation
class EmailCheckRequest {
  final String email;

  EmailCheckRequest({required this.email});

  Map<String, dynamic> toJson() {
    return {'email': email};
  }
}

/// Email check response
class EmailCheckResponse {
  final bool exists;
  final String message;

  EmailCheckResponse({
    required this.exists,
    required this.message,
  });

  factory EmailCheckResponse.fromJson(Map<String, dynamic> json) {
    return EmailCheckResponse(
      exists: json['exists'] ?? false,
      message: json['message'] ?? '',
    );
  }
}

/// User display info model
class UserDisplayInfo {
  final String email;

  UserDisplayInfo({required this.email});

  factory UserDisplayInfo.fromJson(Map<String, dynamic> json) {
    return UserDisplayInfo(
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'email': email};
  }
} 