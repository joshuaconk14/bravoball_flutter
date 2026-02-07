import 'package:flutter_test/flutter_test.dart';
import 'package:bravoball_flutter/models/drill_model.dart';

void main() {
  group('DrillModel', () {
    group('fromJson', () {
      test('creates model from valid JSON with uuid field', () {
        // Arrange
        final json = {
          'uuid': 'test-uuid-123',
          'title': 'Test Drill',
          'skill': 'first_touch',
          'subSkills': ['ball_control', 'first_touch'],
          'sets': 3,
          'reps': 10,
          'duration': 15,
          'description': 'Test description',
          'instructions': ['Step 1', 'Step 2'],
          'tips': ['Tip 1', 'Tip 2'],
          'equipment': ['Soccer ball'],
          'trainingStyle': 'medium intensity',
          'difficulty': 'beginner',
          'videoUrl': 'https://example.com/video.mp4',
          'is_custom': false,
        };

        // Act
        final drill = DrillModel.fromJson(json);

        // Assert
        expect(drill.id, 'test-uuid-123');
        expect(drill.title, 'Test Drill');
        expect(drill.skill, 'first_touch');
        expect(drill.subSkills, ['ball_control', 'first_touch']);
        expect(drill.sets, 3);
        expect(drill.reps, 10);
        expect(drill.duration, 15);
        expect(drill.description, 'Test description');
        expect(drill.instructions, ['Step 1', 'Step 2']);
        expect(drill.tips, ['Tip 1', 'Tip 2']);
        expect(drill.equipment, ['Soccer ball']);
        expect(drill.trainingStyle, 'medium intensity');
        expect(drill.difficulty, 'beginner');
        expect(drill.videoUrl, 'https://example.com/video.mp4');
        expect(drill.isCustom, false);
      });

      test('creates model from JSON with id field (backward compatibility)', () {
        // Arrange
        final json = {
          'id': 'legacy-id-456',
          'title': 'Legacy Drill',
          'skill': 'dribbling',
          'subSkills': [],
          'sets': 1,
          'reps': 5,
          'duration': 10,
          'description': 'Legacy description',
          'instructions': [],
          'tips': [],
          'equipment': [],
          'trainingStyle': 'low intensity',
          'difficulty': 'intermediate',
          'videoUrl': '',
          'is_custom': true,
        };

        // Act
        final drill = DrillModel.fromJson(json);

        // Assert
        expect(drill.id, 'legacy-id-456');
        expect(drill.isCustom, true);
      });

      test('uses default values for missing fields', () {
        // Arrange
        final json = {
          'uuid': 'minimal-drill',
          'title': 'Minimal Drill',
          'skill': 'shooting',
        };

        // Act
        final drill = DrillModel.fromJson(json);

        // Assert
        expect(drill.id, 'minimal-drill');
        expect(drill.title, 'Minimal Drill');
        expect(drill.skill, 'shooting');
        expect(drill.subSkills, isEmpty);
        expect(drill.sets, 0);
        expect(drill.reps, 0);
        expect(drill.duration, 0);
        expect(drill.description, '');
        expect(drill.instructions, isEmpty);
        expect(drill.tips, isEmpty);
        expect(drill.equipment, isEmpty);
        expect(drill.trainingStyle, '');
        expect(drill.difficulty, '');
        expect(drill.videoUrl, '');
        expect(drill.isCustom, false);
      });

      test('handles empty lists for array fields', () {
        // Arrange
        final json = {
          'uuid': 'empty-arrays',
          'title': 'Empty Arrays Drill',
          'skill': 'passing',
          'subSkills': [],
          'instructions': [],
          'tips': [],
          'equipment': [],
        };

        // Act
        final drill = DrillModel.fromJson(json);

        // Assert
        expect(drill.subSkills, isEmpty);
        expect(drill.instructions, isEmpty);
        expect(drill.tips, isEmpty);
        expect(drill.equipment, isEmpty);
      });

      test('handles null values gracefully', () {
        // Arrange
        final json = {
          'uuid': 'null-values',
          'title': 'Null Values Drill',
          'skill': 'defending',
          'subSkills': null,
          'instructions': null,
          'tips': null,
          'equipment': null,
          'description': null,
          'trainingStyle': null,
          'difficulty': null,
          'videoUrl': null,
        };

        // Act
        final drill = DrillModel.fromJson(json);

        // Assert
        expect(drill.subSkills, isEmpty);
        expect(drill.instructions, isEmpty);
        expect(drill.tips, isEmpty);
        expect(drill.equipment, isEmpty);
        expect(drill.description, '');
        expect(drill.trainingStyle, '');
        expect(drill.difficulty, '');
        expect(drill.videoUrl, '');
      });

      test('handles missing uuid and id fields', () {
        // Arrange
        final json = {
          'title': 'No ID Drill',
          'skill': 'goalkeeping',
        };

        // Act
        final drill = DrillModel.fromJson(json);

        // Assert
        expect(drill.id, '');
      });

      test('handles is_custom field correctly (true)', () {
        // Arrange
        final json = {
          'uuid': 'custom-drill',
          'title': 'Custom Drill',
          'skill': 'fitness',
          'is_custom': true,
        };

        // Act
        final drill = DrillModel.fromJson(json);

        // Assert
        expect(drill.isCustom, true);
      });

      test('handles is_custom field correctly (false)', () {
        // Arrange
        final json = {
          'uuid': 'standard-drill',
          'title': 'Standard Drill',
          'skill': 'fitness',
          'is_custom': false,
        };

        // Act
        final drill = DrillModel.fromJson(json);

        // Assert
        expect(drill.isCustom, false);
      });

      test('defaults is_custom to false when missing', () {
        // Arrange
        final json = {
          'uuid': 'no-custom-field',
          'title': 'No Custom Field',
          'skill': 'fitness',
        };

        // Act
        final drill = DrillModel.fromJson(json);

        // Assert
        expect(drill.isCustom, false);
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        // Arrange
        final drill = DrillModel(
          id: 'serialize-test',
          title: 'Serialize Test',
          skill: 'dribbling',
          subSkills: ['ball_control', 'speed'],
          sets: 4,
          reps: 12,
          duration: 20,
          description: 'Test description',
          instructions: ['Instruction 1', 'Instruction 2'],
          tips: ['Tip 1'],
          equipment: ['Ball', 'Cones'],
          trainingStyle: 'high intensity',
          difficulty: 'advanced',
          videoUrl: 'https://test.com/video.mp4',
          isCustom: true,
        );

        // Act
        final json = drill.toJson();

        // Assert
        expect(json['uuid'], 'serialize-test');
        expect(json['title'], 'Serialize Test');
        expect(json['skill'], 'dribbling');
        expect(json['subSkills'], ['ball_control', 'speed']);
        expect(json['sets'], 4);
        expect(json['reps'], 12);
        expect(json['duration'], 20);
        expect(json['description'], 'Test description');
        expect(json['instructions'], ['Instruction 1', 'Instruction 2']);
        expect(json['tips'], ['Tip 1']);
        expect(json['equipment'], ['Ball', 'Cones']);
        expect(json['trainingStyle'], 'high intensity');
        expect(json['difficulty'], 'advanced');
        expect(json['videoUrl'], 'https://test.com/video.mp4');
        expect(json['is_custom'], true);
      });

      test('uses uuid key not id key', () {
        // Arrange
        final drill = DrillModel(
          id: 'test-id',
          title: 'Test',
          skill: 'passing',
          subSkills: [],
          sets: 1,
          reps: 1,
          duration: 1,
          description: '',
          instructions: [],
          tips: [],
          equipment: [],
          trainingStyle: '',
          difficulty: '',
          videoUrl: '',
          isCustom: false,
        );

        // Act
        final json = drill.toJson();

        // Assert
        expect(json.containsKey('uuid'), true);
        expect(json.containsKey('id'), false);
        expect(json['uuid'], 'test-id');
      });

      test('includes is_custom field in serialization', () {
        // Arrange
        final drill = DrillModel(
          id: 'test',
          title: 'Test',
          skill: 'test',
          subSkills: [],
          sets: 1,
          reps: 1,
          duration: 1,
          description: '',
          instructions: [],
          tips: [],
          equipment: [],
          trainingStyle: '',
          difficulty: '',
          videoUrl: '',
          isCustom: true,
        );

        // Act
        final json = drill.toJson();

        // Assert
        expect(json['is_custom'], true);
      });
    });

    group('round-trip serialization', () {
      test('fromJson(toJson()) produces identical model', () {
        // Arrange
        final original = DrillModel(
          id: 'round-trip-test',
          title: 'Round Trip Test',
          skill: 'first_touch',
          subSkills: ['ball_control', 'first_touch'],
          sets: 3,
          reps: 10,
          duration: 15,
          description: 'Test description',
          instructions: ['Step 1', 'Step 2'],
          tips: ['Tip 1'],
          equipment: ['Soccer ball'],
          trainingStyle: 'medium intensity',
          difficulty: 'beginner',
          videoUrl: 'https://example.com/video.mp4',
          isCustom: false,
        );

        // Act
        final json = original.toJson();
        final reconstructed = DrillModel.fromJson(json);

        // Assert
        expect(reconstructed.id, original.id);
        expect(reconstructed.title, original.title);
        expect(reconstructed.skill, original.skill);
        expect(reconstructed.subSkills, original.subSkills);
        expect(reconstructed.sets, original.sets);
        expect(reconstructed.reps, original.reps);
        expect(reconstructed.duration, original.duration);
        expect(reconstructed.description, original.description);
        expect(reconstructed.instructions, original.instructions);
        expect(reconstructed.tips, original.tips);
        expect(reconstructed.equipment, original.equipment);
        expect(reconstructed.trainingStyle, original.trainingStyle);
        expect(reconstructed.difficulty, original.difficulty);
        expect(reconstructed.videoUrl, original.videoUrl);
        expect(reconstructed.isCustom, original.isCustom);
      });
    });

    group('edge cases', () {
      test('handles empty strings', () {
        // Arrange
        final json = {
          'uuid': '',
          'title': '',
          'skill': '',
          'description': '',
          'videoUrl': '',
        };

        // Act
        final drill = DrillModel.fromJson(json);

        // Assert
        expect(drill.id, '');
        expect(drill.title, '');
        expect(drill.skill, '');
        expect(drill.description, '');
        expect(drill.videoUrl, '');
      });

      test('handles zero values for sets, reps, and duration', () {
        // Arrange
        final json = {
          'uuid': 'zero-values',
          'title': 'Zero Values',
          'skill': 'test',
          'sets': 0,
          'reps': 0,
          'duration': 0,
        };

        // Act
        final drill = DrillModel.fromJson(json);

        // Assert
        expect(drill.sets, 0);
        expect(drill.reps, 0);
        expect(drill.duration, 0);
      });
    });

    group('equality and hashCode', () {
      test('two models with same id are equal', () {
        // Arrange
        final drill1 = DrillModel(
          id: 'same-id',
          title: 'Drill 1',
          skill: 'test',
          subSkills: [],
          sets: 1,
          reps: 1,
          duration: 1,
          description: '',
          instructions: [],
          tips: [],
          equipment: [],
          trainingStyle: '',
          difficulty: '',
          videoUrl: '',
          isCustom: false,
        );

        final drill2 = DrillModel(
          id: 'same-id',
          title: 'Drill 2',
          skill: 'different',
          subSkills: [],
          sets: 2,
          reps: 2,
          duration: 2,
          description: 'different',
          instructions: [],
          tips: [],
          equipment: [],
          trainingStyle: '',
          difficulty: '',
          videoUrl: '',
          isCustom: true,
        );

        // Assert
        expect(drill1, equals(drill2));
        expect(drill1.hashCode, equals(drill2.hashCode));
      });

      test('two models with different ids are not equal', () {
        // Arrange
        final drill1 = DrillModel(
          id: 'id-1',
          title: 'Drill',
          skill: 'test',
          subSkills: [],
          sets: 1,
          reps: 1,
          duration: 1,
          description: '',
          instructions: [],
          tips: [],
          equipment: [],
          trainingStyle: '',
          difficulty: '',
          videoUrl: '',
          isCustom: false,
        );

        final drill2 = DrillModel(
          id: 'id-2',
          title: 'Drill',
          skill: 'test',
          subSkills: [],
          sets: 1,
          reps: 1,
          duration: 1,
          description: '',
          instructions: [],
          tips: [],
          equipment: [],
          trainingStyle: '',
          difficulty: '',
          videoUrl: '',
          isCustom: false,
        );

        // Assert
        expect(drill1, isNot(equals(drill2)));
      });
    });
  });
}

