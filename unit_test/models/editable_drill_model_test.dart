import 'package:flutter_test/flutter_test.dart';
import 'package:bravoball_flutter/models/editable_drill_model.dart';
import 'package:bravoball_flutter/models/drill_model.dart';

void main() {
  // Helper to create a test drill
  DrillModel _createTestDrill({
    String id = 'test-drill',
    String title = 'Test Drill',
    String skill = 'dribbling',
  }) {
    return DrillModel(
      id: id,
      title: title,
      skill: skill,
      subSkills: [],
      sets: 3,
      reps: 10,
      duration: 15,
      description: 'Test description',
      instructions: [],
      tips: [],
      equipment: [],
      trainingStyle: 'medium',
      difficulty: 'beginner',
      videoUrl: '',
      isCustom: false,
    );
  }

  group('EditableDrillModel', () {
    group('fromJson', () {
      test('creates model with nested DrillModel', () {
        // Arrange
        final json = {
          'drill': {
            'uuid': 'test-drill',
            'title': 'Test Drill',
            'skill': 'dribbling',
            'subSkills': [],
            'sets': 3,
            'reps': 10,
            'duration': 15,
            'description': 'Test',
            'instructions': [],
            'tips': [],
            'equipment': [],
            'trainingStyle': 'medium',
            'difficulty': 'beginner',
            'videoUrl': '',
            'is_custom': false,
          },
          'setsDone': 2,
          'totalSets': 5,
          'totalReps': 50,
          'totalDuration': 30,
          'isCompleted': false,
        };

        // Act
        final editable = EditableDrillModel.fromJson(json);

        // Assert
        expect(editable.drill.id, 'test-drill');
        expect(editable.setsDone, 2);
        expect(editable.totalSets, 5);
        expect(editable.totalReps, 50);
        expect(editable.totalDuration, 30);
        expect(editable.isCompleted, false);
      });

      test('handles camelCase field names', () {
        // Arrange
        final json = {
          'drill': _createTestDrill().toJson(),
          'setsDone': 1,
          'totalSets': 3,
          'totalReps': 30,
          'totalDuration': 20,
          'isCompleted': true,
        };

        // Act
        final editable = EditableDrillModel.fromJson(json);

        // Assert
        expect(editable.setsDone, 1);
        expect(editable.totalSets, 3);
        expect(editable.totalReps, 30);
        expect(editable.totalDuration, 20);
        expect(editable.isCompleted, true);
      });

      test('handles snake_case field names (backward compatibility)', () {
        // Arrange
        final json = {
          'drill': _createTestDrill().toJson(),
          'sets_done': 3,
          'sets': 5,
          'reps': 50,
          'duration': 30,
          'is_completed': false,
        };

        // Act
        final editable = EditableDrillModel.fromJson(json);

        // Assert
        expect(editable.setsDone, 3);
        expect(editable.totalSets, 5);
        expect(editable.totalReps, 50);
        expect(editable.totalDuration, 30);
        expect(editable.isCompleted, false);
      });

      test('uses default values for missing fields', () {
        // Arrange
        final json = {
          'drill': _createTestDrill().toJson(),
        };

        // Act
        final editable = EditableDrillModel.fromJson(json);

        // Assert
        expect(editable.setsDone, 0);
        expect(editable.totalSets, 0);
        expect(editable.totalReps, 0);
        expect(editable.totalDuration, 0);
        expect(editable.isCompleted, false);
      });
    });

    group('toJson', () {
      test('serializes nested drill correctly', () {
        // Arrange
        final drill = _createTestDrill();
        final editable = EditableDrillModel(
          drill: drill,
          setsDone: 2,
          totalSets: 5,
          totalReps: 50,
          totalDuration: 30,
          isCompleted: false,
        );

        // Act
        final json = editable.toJson();

        // Assert
        expect(json['drill'], isA<Map<String, dynamic>>());
        expect(json['drill']['uuid'], drill.id);
        expect(json['setsDone'], 2);
        expect(json['totalSets'], 5);
        expect(json['totalReps'], 50);
        expect(json['totalDuration'], 30);
        expect(json['isCompleted'], false);
      });

      test('includes all fields in serialization', () {
        // Arrange
        final editable = EditableDrillModel(
          drill: _createTestDrill(),
          setsDone: 1,
          totalSets: 3,
          totalReps: 30,
          totalDuration: 20,
          isCompleted: true,
        );

        // Act
        final json = editable.toJson();

        // Assert
        expect(json.keys.length, 6); // drill, setsDone, totalSets, totalReps, totalDuration, isCompleted
        expect(json.containsKey('drill'), true);
        expect(json.containsKey('setsDone'), true);
        expect(json.containsKey('totalSets'), true);
        expect(json.containsKey('totalReps'), true);
        expect(json.containsKey('totalDuration'), true);
        expect(json.containsKey('isCompleted'), true);
      });
    });

    group('copyWith', () {
      test('creates new instance with modified fields', () {
        // Arrange
        final original = EditableDrillModel(
          drill: _createTestDrill(),
          setsDone: 2,
          totalSets: 5,
          totalReps: 50,
          totalDuration: 30,
          isCompleted: false,
        );

        // Act
        final modified = original.copyWith(
          setsDone: 3,
          isCompleted: true,
        );

        // Assert
        expect(modified.setsDone, 3);
        expect(modified.isCompleted, true);
        expect(modified.totalSets, 5); // Unchanged
        expect(modified.totalReps, 50); // Unchanged
        expect(modified.totalDuration, 30); // Unchanged
        expect(modified.drill.id, original.drill.id); // Unchanged
      });

      test('preserves unchanged fields when modifying one field', () {
        // Arrange
        final original = EditableDrillModel(
          drill: _createTestDrill(id: 'original'),
          setsDone: 1,
          totalSets: 3,
          totalReps: 30,
          totalDuration: 20,
          isCompleted: false,
        );

        // Act
        final modified = original.copyWith(setsDone: 2);

        // Assert
        expect(modified.setsDone, 2);
        expect(modified.totalSets, original.totalSets);
        expect(modified.totalReps, original.totalReps);
        expect(modified.totalDuration, original.totalDuration);
        expect(modified.isCompleted, original.isCompleted);
        expect(modified.drill.id, original.drill.id);
      });

      test('handles null parameters (keeps original values)', () {
        // Arrange
        final original = EditableDrillModel(
          drill: _createTestDrill(),
          setsDone: 2,
          totalSets: 5,
          totalReps: 50,
          totalDuration: 30,
          isCompleted: false,
        );

        // Act
        final modified = original.copyWith();

        // Assert
        expect(modified.setsDone, original.setsDone);
        expect(modified.totalSets, original.totalSets);
        expect(modified.totalReps, original.totalReps);
        expect(modified.totalDuration, original.totalDuration);
        expect(modified.isCompleted, original.isCompleted);
        expect(modified.drill.id, original.drill.id);
      });

      test('can modify drill field', () {
        // Arrange
        final original = EditableDrillModel(
          drill: _createTestDrill(id: 'original'),
          setsDone: 1,
          totalSets: 3,
          totalReps: 30,
          totalDuration: 20,
          isCompleted: false,
        );

        final newDrill = _createTestDrill(id: 'new-drill', title: 'New Title');

        // Act
        final modified = original.copyWith(drill: newDrill);

        // Assert
        expect(modified.drill.id, 'new-drill');
        expect(modified.drill.title, 'New Title');
        expect(modified.setsDone, original.setsDone); // Other fields unchanged
      });
    });

    group('computed properties - progress', () {
      test('calculates progress correctly (0% to 100%)', () {
        // Arrange
        final editable = EditableDrillModel(
          drill: _createTestDrill(),
          setsDone: 2,
          totalSets: 5,
          totalReps: 50,
          totalDuration: 30,
          isCompleted: false,
        );

        // Act
        final progress = editable.progress;

        // Assert
        expect(progress, 0.4); // 2/5 = 0.4
      });

      test('returns 0.0 when totalSets is zero', () {
        // Arrange
        final editable = EditableDrillModel(
          drill: _createTestDrill(),
          setsDone: 5,
          totalSets: 0,
          totalReps: 50,
          totalDuration: 30,
          isCompleted: false,
        );

        // Act
        final progress = editable.progress;

        // Assert
        expect(progress, 0.0);
      });

      test('clamps progress to 0.0 minimum', () {
        // Arrange
        final editable = EditableDrillModel(
          drill: _createTestDrill(),
          setsDone: -1, // Negative (shouldn't happen but test edge case)
          totalSets: 5,
          totalReps: 50,
          totalDuration: 30,
          isCompleted: false,
        );

        // Act
        final progress = editable.progress;

        // Assert
        expect(progress, greaterThanOrEqualTo(0.0));
      });

      test('clamps progress to 1.0 maximum', () {
        // Arrange
        final editable = EditableDrillModel(
          drill: _createTestDrill(),
          setsDone: 10, // More than totalSets
          totalSets: 5,
          totalReps: 50,
          totalDuration: 30,
          isCompleted: false,
        );

        // Act
        final progress = editable.progress;

        // Assert
        expect(progress, lessThanOrEqualTo(1.0));
        expect(progress, 1.0);
      });

      test('returns 1.0 when setsDone equals totalSets', () {
        // Arrange
        final editable = EditableDrillModel(
          drill: _createTestDrill(),
          setsDone: 5,
          totalSets: 5,
          totalReps: 50,
          totalDuration: 30,
          isCompleted: false,
        );

        // Act
        final progress = editable.progress;

        // Assert
        expect(progress, 1.0);
      });
    });

    group('computed properties - isFullyCompleted', () {
      test('returns true when isCompleted is true', () {
        // Arrange
        final editable = EditableDrillModel(
          drill: _createTestDrill(),
          setsDone: 2,
          totalSets: 5,
          totalReps: 50,
          totalDuration: 30,
          isCompleted: true,
        );

        // Act & Assert
        expect(editable.isFullyCompleted, true);
      });

      test('returns true when setsDone >= totalSets', () {
        // Arrange
        final editable = EditableDrillModel(
          drill: _createTestDrill(),
          setsDone: 5,
          totalSets: 5,
          totalReps: 50,
          totalDuration: 30,
          isCompleted: false,
        );

        // Act & Assert
        expect(editable.isFullyCompleted, true);
      });

      test('returns true when setsDone > totalSets', () {
        // Arrange
        final editable = EditableDrillModel(
          drill: _createTestDrill(),
          setsDone: 6,
          totalSets: 5,
          totalReps: 50,
          totalDuration: 30,
          isCompleted: false,
        );

        // Act & Assert
        expect(editable.isFullyCompleted, true);
      });

      test('returns false when not completed and setsDone < totalSets', () {
        // Arrange
        final editable = EditableDrillModel(
          drill: _createTestDrill(),
          setsDone: 2,
          totalSets: 5,
          totalReps: 50,
          totalDuration: 30,
          isCompleted: false,
        );

        // Act & Assert
        expect(editable.isFullyCompleted, false);
      });
    });

    group('computed properties - isDone', () {
      test('returns isCompleted value', () {
        // Arrange
        final editable = EditableDrillModel(
          drill: _createTestDrill(),
          setsDone: 2,
          totalSets: 5,
          totalReps: 50,
          totalDuration: 30,
          isCompleted: true,
        );

        // Act & Assert
        expect(editable.isDone, true);
      });

      test('returns false when isCompleted is false', () {
        // Arrange
        final editable = EditableDrillModel(
          drill: _createTestDrill(),
          setsDone: 5,
          totalSets: 5,
          totalReps: 50,
          totalDuration: 30,
          isCompleted: false,
        );

        // Act & Assert
        expect(editable.isDone, false);
      });
    });

    group('calculateSetDuration', () {
      test('calculates duration correctly with breaks', () {
        // Arrange
        final editable = EditableDrillModel(
          drill: _createTestDrill(),
          setsDone: 0,
          totalSets: 3,
          totalReps: 30,
          totalDuration: 15, // 15 minutes
          isCompleted: false,
        );

        // Act
        final setDuration = editable.calculateSetDuration();

        // Assert
        // 15 minutes = 900 seconds
        // 3 sets = 2 breaks of 45 seconds = 90 seconds
        // Available time = 900 - 90 = 810 seconds
        // Per set = 810 / 3 = 270 seconds
        // Rounded to nearest 10 = 270 seconds
        expect(setDuration, 270.0);
      });

      test('handles zero totalSets (returns 0.0)', () {
        // Arrange
        final editable = EditableDrillModel(
          drill: _createTestDrill(),
          setsDone: 0,
          totalSets: 0,
          totalReps: 0,
          totalDuration: 15,
          isCompleted: false,
        );

        // Act
        final setDuration = editable.calculateSetDuration();

        // Assert
        expect(setDuration, 0.0);
      });

      test('enforces minimum set duration (10 seconds)', () {
        // Arrange
        final editable = EditableDrillModel(
          drill: _createTestDrill(),
          setsDone: 0,
          totalSets: 10, // Many sets
          totalReps: 30,
          totalDuration: 1, // Very short duration
          isCompleted: false,
        );

        // Act
        final setDuration = editable.calculateSetDuration();

        // Assert
        expect(setDuration, greaterThanOrEqualTo(10.0));
      });

      test('rounds to nearest 10 seconds', () {
        // Arrange
        final editable = EditableDrillModel(
          drill: _createTestDrill(),
          setsDone: 0,
          totalSets: 3,
          totalReps: 30,
          totalDuration: 10,
          isCompleted: false,
        );

        // Act
        final setDuration = editable.calculateSetDuration();

        // Assert
        // Should be rounded to nearest 10
        expect(setDuration % 10, 0.0);
      });

      test('handles custom breakDuration parameter', () {
        // Arrange
        final editable = EditableDrillModel(
          drill: _createTestDrill(),
          setsDone: 0,
          totalSets: 3,
          totalReps: 30,
          totalDuration: 15,
          isCompleted: false,
        );

        // Act
        final setDuration = editable.calculateSetDuration(breakDuration: 60);

        // Assert
        // 15 minutes = 900 seconds
        // 3 sets = 2 breaks of 60 seconds = 120 seconds
        // Available time = 900 - 120 = 780 seconds
        // Per set = 780 / 3 = 260 seconds
        // Rounded to nearest 10 = 260 seconds
        expect(setDuration, 260.0);
      });
    });

    group('round-trip serialization', () {
      test('fromJson(toJson()) produces identical model', () {
        // Arrange
        final original = EditableDrillModel(
          drill: _createTestDrill(),
          setsDone: 2,
          totalSets: 5,
          totalReps: 50,
          totalDuration: 30,
          isCompleted: false,
        );

        // Act
        final json = original.toJson();
        final reconstructed = EditableDrillModel.fromJson(json);

        // Assert
        expect(reconstructed.drill.id, original.drill.id);
        expect(reconstructed.setsDone, original.setsDone);
        expect(reconstructed.totalSets, original.totalSets);
        expect(reconstructed.totalReps, original.totalReps);
        expect(reconstructed.totalDuration, original.totalDuration);
        expect(reconstructed.isCompleted, original.isCompleted);
      });
    });

    group('equality and hashCode', () {
      test('two models with same drill id are equal', () {
        // Arrange
        final drill1 = _createTestDrill(id: 'same-id');
        final drill2 = _createTestDrill(id: 'same-id');

        final editable1 = EditableDrillModel(
          drill: drill1,
          setsDone: 1,
          totalSets: 3,
          totalReps: 30,
          totalDuration: 20,
          isCompleted: false,
        );

        final editable2 = EditableDrillModel(
          drill: drill2,
          setsDone: 5, // Different value
          totalSets: 10, // Different value
          totalReps: 100, // Different value
          totalDuration: 60, // Different value
          isCompleted: true, // Different value
        );

        // Assert
        expect(editable1, equals(editable2));
        expect(editable1.hashCode, equals(editable2.hashCode));
      });

      test('two models with different drill ids are not equal', () {
        // Arrange
        final editable1 = EditableDrillModel(
          drill: _createTestDrill(id: 'id-1'),
          setsDone: 1,
          totalSets: 3,
          totalReps: 30,
          totalDuration: 20,
          isCompleted: false,
        );

        final editable2 = EditableDrillModel(
          drill: _createTestDrill(id: 'id-2'),
          setsDone: 1,
          totalSets: 3,
          totalReps: 30,
          totalDuration: 20,
          isCompleted: false,
        );

        // Assert
        expect(editable1, isNot(equals(editable2)));
      });
    });
  });
}

