import 'package:flutter_test/flutter_test.dart';
import 'package:bravoball_flutter/models/onboarding_model.dart';

void main() {
  group('OnboardingData', () {
    group('fromJson', () {
      test('parses all required fields', () {
        // Arrange
        final json = {
          'email': 'test@example.com',
          'password': 'password123',
          'primaryGoal': 'improve_skills',
          'trainingExperience': 'beginner',
          'position': 'forward',
          'ageRange': '18-25',
          'strengths': ['speed', 'dribbling'],
          'areasToImprove': ['passing', 'shooting'],
        };

        // Act
        final data = OnboardingData.fromJson(json);

        // Assert
        expect(data.email, 'test@example.com');
        expect(data.password, 'password123');
        expect(data.primaryGoal, 'improve_skills');
        expect(data.trainingExperience, 'beginner');
        expect(data.position, 'forward');
        expect(data.ageRange, '18-25');
        expect(data.strengths, ['speed', 'dribbling']);
        expect(data.areasToImprove, ['passing', 'shooting']);
      });

      test('handles optional fields with defaults', () {
        // Arrange
        final json = {
          'email': 'test@example.com',
          'password': 'password123',
          'primaryGoal': 'improve_skills',
          'trainingExperience': 'beginner',
          'position': 'forward',
          'ageRange': '18-25',
          'strengths': [],
          'areasToImprove': [],
        };

        // Act
        final data = OnboardingData.fromJson(json);

        // Assert
        expect(data.biggestChallenge, isEmpty);
        expect(data.playstyle, isEmpty);
        expect(data.trainingLocation, isEmpty);
        expect(data.availableEquipment, ['Soccer ball']);
        expect(data.dailyTrainingTime, '30');
        expect(data.weeklyTrainingDays, 'moderate');
      });

      test('handles empty lists for optional arrays', () {
        // Arrange
        final json = {
          'email': 'test@example.com',
          'password': 'password123',
          'primaryGoal': 'improve_skills',
          'trainingExperience': 'beginner',
          'position': 'forward',
          'ageRange': '18-25',
          'strengths': [],
          'areasToImprove': [],
          'biggestChallenge': [],
          'playstyle': [],
          'trainingLocation': [],
        };

        // Act
        final data = OnboardingData.fromJson(json);

        // Assert
        expect(data.biggestChallenge, isEmpty);
        expect(data.playstyle, isEmpty);
        expect(data.trainingLocation, isEmpty);
      });

      test('uses default values for dailyTrainingTime and weeklyTrainingDays', () {
        // Arrange
        final json = {
          'email': 'test@example.com',
          'password': 'password123',
          'primaryGoal': 'improve_skills',
          'trainingExperience': 'beginner',
          'position': 'forward',
          'ageRange': '18-25',
          'strengths': [],
          'areasToImprove': [],
        };

        // Act
        final data = OnboardingData.fromJson(json);

        // Assert
        expect(data.dailyTrainingTime, '30');
        expect(data.weeklyTrainingDays, 'moderate');
      });

      test('handles missing availableEquipment (defaults to Soccer ball)', () {
        // Arrange
        final json = {
          'email': 'test@example.com',
          'password': 'password123',
          'primaryGoal': 'improve_skills',
          'trainingExperience': 'beginner',
          'position': 'forward',
          'ageRange': '18-25',
          'strengths': [],
          'areasToImprove': [],
        };

        // Act
        final data = OnboardingData.fromJson(json);

        // Assert
        expect(data.availableEquipment, ['Soccer ball']);
      });

      test('uses empty strings for missing required fields', () {
        // Arrange
        final json = <String, dynamic>{};

        // Act
        final data = OnboardingData.fromJson(json);

        // Assert
        expect(data.email, '');
        expect(data.password, '');
        expect(data.primaryGoal, '');
        expect(data.trainingExperience, '');
        expect(data.position, '');
        expect(data.ageRange, '');
        expect(data.strengths, isEmpty);
        expect(data.areasToImprove, isEmpty);
      });

      test('handles null values (should use defaults)', () {
        // Arrange
        final json = {
          'email': 'test@example.com',
          'password': 'password123',
          'primaryGoal': 'improve_skills',
          'trainingExperience': 'beginner',
          'position': 'forward',
          'ageRange': '18-25',
          'strengths': null,
          'areasToImprove': null,
          'biggestChallenge': null,
          'playstyle': null,
          'trainingLocation': null,
          'availableEquipment': null,
          'dailyTrainingTime': null,
          'weeklyTrainingDays': null,
        };

        // Act
        final data = OnboardingData.fromJson(json);

        // Assert
        expect(data.strengths, isEmpty);
        expect(data.areasToImprove, isEmpty);
        expect(data.biggestChallenge, isEmpty);
        expect(data.playstyle, isEmpty);
        expect(data.trainingLocation, isEmpty);
        expect(data.availableEquipment, ['Soccer ball']);
        expect(data.dailyTrainingTime, '30');
        expect(data.weeklyTrainingDays, 'moderate');
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        // Arrange
        final data = OnboardingData(
          email: 'test@example.com',
          password: 'password123',
          primaryGoal: 'improve_skills',
          trainingExperience: 'beginner',
          position: 'forward',
          ageRange: '18-25',
          strengths: ['speed', 'dribbling'],
          areasToImprove: ['passing', 'shooting'],
          biggestChallenge: ['consistency'],
          playstyle: ['aggressive'],
          trainingLocation: ['field'],
          availableEquipment: ['Soccer ball', 'Cones'],
          dailyTrainingTime: '45',
          weeklyTrainingDays: 'frequent',
        );

        // Act
        final json = data.toJson();

        // Assert
        expect(json['email'], 'test@example.com');
        expect(json['password'], 'password123');
        expect(json['primaryGoal'], 'improve_skills');
        expect(json['trainingExperience'], 'beginner');
        expect(json['position'], 'forward');
        expect(json['ageRange'], '18-25');
        expect(json['strengths'], ['speed', 'dribbling']);
        expect(json['areasToImprove'], ['passing', 'shooting']);
        expect(json['biggestChallenge'], ['consistency']);
        expect(json['playstyle'], ['aggressive']);
        expect(json['trainingLocation'], ['field']);
        expect(json['availableEquipment'], ['Soccer ball', 'Cones']);
        expect(json['dailyTrainingTime'], '45');
        expect(json['weeklyTrainingDays'], 'frequent');
      });

      test('includes optional fields even if empty', () {
        // Arrange
        final data = OnboardingData(
          email: 'test@example.com',
          password: 'password123',
          primaryGoal: 'improve_skills',
          trainingExperience: 'beginner',
          position: 'forward',
          ageRange: '18-25',
          strengths: [],
          areasToImprove: [],
        );

        // Act
        final json = data.toJson();

        // Assert
        expect(json.containsKey('biggestChallenge'), true);
        expect(json.containsKey('playstyle'), true);
        expect(json.containsKey('trainingLocation'), true);
        expect(json.containsKey('availableEquipment'), true);
        expect(json.containsKey('dailyTrainingTime'), true);
        expect(json.containsKey('weeklyTrainingDays'), true);
        expect(json['biggestChallenge'], isEmpty);
        expect(json['playstyle'], isEmpty);
        expect(json['trainingLocation'], isEmpty);
      });
    });

    group('round-trip serialization', () {
      test('fromJson(toJson()) produces identical model', () {
        // Arrange
        final original = OnboardingData(
          email: 'test@example.com',
          password: 'password123',
          primaryGoal: 'improve_skills',
          trainingExperience: 'beginner',
          position: 'forward',
          ageRange: '18-25',
          strengths: ['speed', 'dribbling'],
          areasToImprove: ['passing', 'shooting'],
          biggestChallenge: ['consistency'],
          playstyle: ['aggressive'],
          trainingLocation: ['field'],
          availableEquipment: ['Soccer ball', 'Cones'],
          dailyTrainingTime: '45',
          weeklyTrainingDays: 'frequent',
        );

        // Act
        final json = original.toJson();
        final reconstructed = OnboardingData.fromJson(json);

        // Assert
        expect(reconstructed.email, original.email);
        expect(reconstructed.password, original.password);
        expect(reconstructed.primaryGoal, original.primaryGoal);
        expect(reconstructed.trainingExperience, original.trainingExperience);
        expect(reconstructed.position, original.position);
        expect(reconstructed.ageRange, original.ageRange);
        expect(reconstructed.strengths, original.strengths);
        expect(reconstructed.areasToImprove, original.areasToImprove);
        expect(reconstructed.biggestChallenge, original.biggestChallenge);
        expect(reconstructed.playstyle, original.playstyle);
        expect(reconstructed.trainingLocation, original.trainingLocation);
        expect(reconstructed.availableEquipment, original.availableEquipment);
        expect(reconstructed.dailyTrainingTime, original.dailyTrainingTime);
        expect(reconstructed.weeklyTrainingDays, original.weeklyTrainingDays);
      });

      test('round-trip works with default optional values', () {
        // Arrange
        final original = OnboardingData(
          email: 'test@example.com',
          password: 'password123',
          primaryGoal: 'improve_skills',
          trainingExperience: 'beginner',
          position: 'forward',
          ageRange: '18-25',
          strengths: [],
          areasToImprove: [],
        );

        // Act
        final json = original.toJson();
        final reconstructed = OnboardingData.fromJson(json);

        // Assert
        expect(reconstructed.email, original.email);
        expect(reconstructed.biggestChallenge, original.biggestChallenge);
        expect(reconstructed.availableEquipment, original.availableEquipment);
        expect(reconstructed.dailyTrainingTime, original.dailyTrainingTime);
        expect(reconstructed.weeklyTrainingDays, original.weeklyTrainingDays);
      });
    });

    group('edge cases', () {
      test('handles empty strings for required fields', () {
        // Arrange
        final json = {
          'email': '',
          'password': '',
          'primaryGoal': '',
          'trainingExperience': '',
          'position': '',
          'ageRange': '',
          'strengths': [],
          'areasToImprove': [],
        };

        // Act
        final data = OnboardingData.fromJson(json);

        // Assert
        expect(data.email, '');
        expect(data.password, '');
        expect(data.primaryGoal, '');
        expect(data.trainingExperience, '');
        expect(data.position, '');
        expect(data.ageRange, '');
      });

      test('handles empty lists for required arrays', () {
        // Arrange
        final json = {
          'email': 'test@example.com',
          'password': 'password123',
          'primaryGoal': 'improve_skills',
          'trainingExperience': 'beginner',
          'position': 'forward',
          'ageRange': '18-25',
          'strengths': [],
          'areasToImprove': [],
        };

        // Act
        final data = OnboardingData.fromJson(json);

        // Assert
        expect(data.strengths, isEmpty);
        expect(data.areasToImprove, isEmpty);
      });
    });
  });
}

