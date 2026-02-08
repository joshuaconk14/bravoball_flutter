import 'package:flutter_test/flutter_test.dart';
import 'package:bravoball_flutter/models/auth_models.dart';

void main() {
  group('LoginRequest', () {
    group('toJson', () {
      test('serializes email and password correctly', () {
        // Arrange
        final request = LoginRequest(
          email: 'test@example.com',
          password: 'password123',
        );

        // Act
        final json = request.toJson();

        // Assert
        expect(json['email'], 'test@example.com');
        expect(json['password'], 'password123');
        expect(json.keys.length, 2);
      });

      test('handles empty strings', () {
        // Arrange
        final request = LoginRequest(
          email: '',
          password: '',
        );

        // Act
        final json = request.toJson();

        // Assert
        expect(json['email'], '');
        expect(json['password'], '');
      });
    });
  });

  group('LoginResponse', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        // Arrange
        final json = {
          'access_token': 'test-access-token',
          'token_type': 'bearer',
          'email': 'test@example.com',
          'refresh_token': 'test-refresh-token',
        };

        // Act
        final response = LoginResponse.fromJson(json);

        // Assert
        expect(response.accessToken, 'test-access-token');
        expect(response.tokenType, 'bearer');
        expect(response.email, 'test@example.com');
        expect(response.refreshToken, 'test-refresh-token');
      });

      test('handles missing refreshToken (null)', () {
        // Arrange
        final json = {
          'access_token': 'test-access-token',
          'token_type': 'bearer',
          'email': 'test@example.com',
        };

        // Act
        final response = LoginResponse.fromJson(json);

        // Assert
        expect(response.accessToken, 'test-access-token');
        expect(response.tokenType, 'bearer');
        expect(response.email, 'test@example.com');
        expect(response.refreshToken, isNull);
      });

      test('uses default bearer for token_type when missing', () {
        // Arrange
        final json = {
          'access_token': 'test-access-token',
          'email': 'test@example.com',
        };

        // Act
        final response = LoginResponse.fromJson(json);

        // Assert
        expect(response.tokenType, 'bearer');
      });

      test('uses empty strings for missing required fields', () {
        // Arrange
        final json = <String, dynamic>{};

        // Act
        final response = LoginResponse.fromJson(json);

        // Assert
        expect(response.accessToken, '');
        expect(response.tokenType, 'bearer');
        expect(response.email, '');
        expect(response.refreshToken, isNull);
      });

      test('handles null refreshToken in JSON', () {
        // Arrange
        final json = {
          'access_token': 'test-access-token',
          'token_type': 'bearer',
          'email': 'test@example.com',
          'refresh_token': null,
        };

        // Act
        final response = LoginResponse.fromJson(json);

        // Assert
        expect(response.refreshToken, isNull);
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        // Arrange
        final response = LoginResponse(
          accessToken: 'test-access-token',
          tokenType: 'bearer',
          email: 'test@example.com',
          refreshToken: 'test-refresh-token',
        );

        // Act
        final json = response.toJson();

        // Assert
        expect(json['access_token'], 'test-access-token');
        expect(json['token_type'], 'bearer');
        expect(json['email'], 'test@example.com');
        expect(json['refresh_token'], 'test-refresh-token');
      });

      test('includes null refreshToken in serialization', () {
        // Arrange
        final response = LoginResponse(
          accessToken: 'test-access-token',
          tokenType: 'bearer',
          email: 'test@example.com',
          refreshToken: null,
        );

        // Act
        final json = response.toJson();

        // Assert
        expect(json['refresh_token'], isNull);
      });
    });

    group('round-trip serialization', () {
      test('fromJson(toJson()) produces identical response', () {
        // Arrange
        final original = LoginResponse(
          accessToken: 'test-access-token',
          tokenType: 'bearer',
          email: 'test@example.com',
          refreshToken: 'test-refresh-token',
        );

        // Act
        final json = original.toJson();
        final reconstructed = LoginResponse.fromJson(json);

        // Assert
        expect(reconstructed.accessToken, original.accessToken);
        expect(reconstructed.tokenType, original.tokenType);
        expect(reconstructed.email, original.email);
        expect(reconstructed.refreshToken, original.refreshToken);
      });

      test('round-trip works with null refreshToken', () {
        // Arrange
        final original = LoginResponse(
          accessToken: 'test-access-token',
          tokenType: 'bearer',
          email: 'test@example.com',
          refreshToken: null,
        );

        // Act
        final json = original.toJson();
        final reconstructed = LoginResponse.fromJson(json);

        // Assert
        expect(reconstructed.accessToken, original.accessToken);
        expect(reconstructed.tokenType, original.tokenType);
        expect(reconstructed.email, original.email);
        expect(reconstructed.refreshToken, original.refreshToken);
      });
    });
  });

  group('EmailCheckRequest', () {
    group('toJson', () {
      test('serializes email correctly', () {
        // Arrange
        final request = EmailCheckRequest(email: 'test@example.com');

        // Act
        final json = request.toJson();

        // Assert
        expect(json['email'], 'test@example.com');
        expect(json.keys.length, 1);
      });

      test('handles empty email', () {
        // Arrange
        final request = EmailCheckRequest(email: '');

        // Act
        final json = request.toJson();

        // Assert
        expect(json['email'], '');
      });
    });
  });

  group('EmailCheckResponse', () {
    group('fromJson', () {
      test('parses exists and message fields', () {
        // Arrange
        final json = {
          'exists': true,
          'message': 'Email already exists',
        };

        // Act
        final response = EmailCheckResponse.fromJson(json);

        // Assert
        expect(response.exists, true);
        expect(response.message, 'Email already exists');
      });

      test('uses defaults for missing fields', () {
        // Arrange
        final json = <String, dynamic>{};

        // Act
        final response = EmailCheckResponse.fromJson(json);

        // Assert
        expect(response.exists, false);
        expect(response.message, '');
      });

      test('handles false exists value', () {
        // Arrange
        final json = {
          'exists': false,
          'message': 'Email is available',
        };

        // Act
        final response = EmailCheckResponse.fromJson(json);

        // Assert
        expect(response.exists, false);
        expect(response.message, 'Email is available');
      });
    });

    // Note: EmailCheckResponse doesn't have toJson() method
    // It's only used for parsing backend responses, not serialization
  });

  group('UserDisplayInfo', () {
    group('fromJson', () {
      test('parses email correctly', () {
        // Arrange
        final json = {
          'email': 'user@example.com',
        };

        // Act
        final userInfo = UserDisplayInfo.fromJson(json);

        // Assert
        expect(userInfo.email, 'user@example.com');
      });

      test('uses empty string for missing email', () {
        // Arrange
        final json = <String, dynamic>{};

        // Act
        final userInfo = UserDisplayInfo.fromJson(json);

        // Assert
        expect(userInfo.email, '');
      });
    });

    group('toJson', () {
      test('serializes email correctly', () {
        // Arrange
        final userInfo = UserDisplayInfo(email: 'user@example.com');

        // Act
        final json = userInfo.toJson();

        // Assert
        expect(json['email'], 'user@example.com');
        expect(json.keys.length, 1);
      });

      test('handles empty email', () {
        // Arrange
        final userInfo = UserDisplayInfo(email: '');

        // Act
        final json = userInfo.toJson();

        // Assert
        expect(json['email'], '');
      });
    });

    group('round-trip serialization', () {
      test('fromJson(toJson()) produces identical user info', () {
        // Arrange
        final original = UserDisplayInfo(email: 'user@example.com');

        // Act
        final json = original.toJson();
        final reconstructed = UserDisplayInfo.fromJson(json);

        // Assert
        expect(reconstructed.email, original.email);
      });
    });
  });
}

