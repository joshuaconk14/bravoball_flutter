import 'package:flutter_test/flutter_test.dart';
import 'package:bravoball_flutter/utils/preference_utils.dart';

void main() {
  group('PreferenceUtils', () {
    group('formatPreferenceForDisplay', () {
      test('applies title case to simple preferences', () {
        // Arrange
        const input = 'medium intensity';
        
        // Act
        final result = PreferenceUtils.formatPreferenceForDisplay(input);
        
        // Assert
        expect(result, 'Medium Intensity');
      });

      test('handles single word preferences', () {
        // Arrange
        const input = 'beginner';
        
        // Act
        final result = PreferenceUtils.formatPreferenceForDisplay(input);
        
        // Assert
        expect(result, 'Beginner');
      });

      test('preserves special time format cases', () {
        // Arrange
        const specialCases = ['15min', '30min', '45min', '1h', '1h30', '2h+'];
        
        // Act & Assert
        for (final input in specialCases) {
          final result = PreferenceUtils.formatPreferenceForDisplay(input);
          expect(result, input, reason: '$input should remain unchanged');
        }
      });

      test('handles empty string', () {
        // Arrange
        const input = '';
        
        // Act
        final result = PreferenceUtils.formatPreferenceForDisplay(input);
        
        // Assert
        expect(result, '');
      });

      test('handles uppercase input', () {
        // Arrange
        const input = 'SOCCER BALL';
        
        // Act
        final result = PreferenceUtils.formatPreferenceForDisplay(input);
        
        // Assert
        expect(result, 'Soccer Ball');
      });

      test('handles mixed case input', () {
        // Arrange
        const input = 'sOcCeR bAlL';
        
        // Act
        final result = PreferenceUtils.formatPreferenceForDisplay(input);
        
        // Assert
        expect(result, 'Soccer Ball');
      });
    });

    group('formatPreferenceForBackend', () {
      test('converts to lowercase', () {
        // Arrange
        const input = 'Medium Intensity';
        
        // Act
        final result = PreferenceUtils.formatPreferenceForBackend(input);
        
        // Assert
        expect(result, 'medium intensity');
      });

      test('handles already lowercase strings', () {
        // Arrange
        const input = 'soccer ball';
        
        // Act
        final result = PreferenceUtils.formatPreferenceForBackend(input);
        
        // Assert
        expect(result, 'soccer ball');
      });

      test('handles empty string', () {
        // Arrange
        const input = '';
        
        // Act
        final result = PreferenceUtils.formatPreferenceForBackend(input);
        
        // Assert
        expect(result, '');
      });

      test('preserves spaces', () {
        // Arrange
        const input = 'Location With Goals';
        
        // Act
        final result = PreferenceUtils.formatPreferenceForBackend(input);
        
        // Assert
        expect(result, 'location with goals');
      });
    });

    group('normalizePreference', () {
      test('converts title case to normalized format', () {
        // Arrange
        const input = 'Medium Intensity';
        
        // Act
        final result = PreferenceUtils.normalizePreference(input);
        
        // Assert
        expect(result, 'medium intensity');
      });

      test('converts underscore format to normalized format', () {
        // Arrange
        const input = 'soccer_ball';
        
        // Act
        final result = PreferenceUtils.normalizePreference(input);
        
        // Assert
        expect(result, 'soccer ball');
      });

      test('converts uppercase to normalized format', () {
        // Arrange
        const input = 'SOCCER BALL';
        
        // Act
        final result = PreferenceUtils.normalizePreference(input);
        
        // Assert
        expect(result, 'soccer ball');
      });

      test('handles empty string', () {
        // Arrange
        const input = '';
        
        // Act
        final result = PreferenceUtils.normalizePreference(input);
        
        // Assert
        expect(result, '');
      });
    });

    group('arePreferencesEqual', () {
      test('returns true for same preference with different formats', () {
        // Arrange
        const pref1 = 'medium_intensity';
        const pref2 = 'Medium Intensity';
        
        // Act
        final result = PreferenceUtils.arePreferencesEqual(pref1, pref2);
        
        // Assert
        expect(result, true);
      });

      test('returns true for same preference with same format', () {
        // Arrange
        const pref1 = 'medium intensity';
        const pref2 = 'medium intensity';
        
        // Act
        final result = PreferenceUtils.arePreferencesEqual(pref1, pref2);
        
        // Assert
        expect(result, true);
      });

      test('returns false for different preferences', () {
        // Arrange
        const pref1 = 'medium intensity';
        const pref2 = 'high intensity';
        
        // Act
        final result = PreferenceUtils.arePreferencesEqual(pref1, pref2);
        
        // Assert
        expect(result, false);
      });
    });

    group('formatTimeForDisplay', () {
      test('converts 15min to 15m', () {
        // Arrange
        const input = '15min';
        
        // Act
        final result = PreferenceUtils.formatTimeForDisplay(input);
        
        // Assert
        expect(result, '15m');
      });

      test('converts 30min to 30m', () {
        // Arrange
        const input = '30min';
        
        // Act
        final result = PreferenceUtils.formatTimeForDisplay(input);
        
        // Assert
        expect(result, '30m');
      });

      test('converts 45min to 45m', () {
        // Arrange
        const input = '45min';
        
        // Act
        final result = PreferenceUtils.formatTimeForDisplay(input);
        
        // Assert
        expect(result, '45m');
      });

      test('preserves 1h format', () {
        // Arrange
        const input = '1h';
        
        // Act
        final result = PreferenceUtils.formatTimeForDisplay(input);
        
        // Assert
        expect(result, '1h');
      });

      test('converts 1h30 to 1h30m', () {
        // Arrange
        const input = '1h30';
        
        // Act
        final result = PreferenceUtils.formatTimeForDisplay(input);
        
        // Assert
        expect(result, '1h30m');
      });

      test('preserves 2h+ format', () {
        // Arrange
        const input = '2h+';
        
        // Act
        final result = PreferenceUtils.formatTimeForDisplay(input);
        
        // Assert
        expect(result, '2h+');
      });

      test('handles unrecognized time formats', () {
        // Arrange
        const input = 'unknown_format';
        
        // Act
        final result = PreferenceUtils.formatTimeForDisplay(input);
        
        // Assert
        expect(result, 'unknown_format'); // Returns as-is
      });

      test('handles empty string', () {
        // Arrange
        const input = '';
        
        // Act
        final result = PreferenceUtils.formatTimeForDisplay(input);
        
        // Assert
        expect(result, '');
      });

      test('handles case-insensitive input', () {
        // Arrange
        const input = '15MIN';
        
        // Act
        final result = PreferenceUtils.formatTimeForDisplay(input);
        
        // Assert
        expect(result, '15m');
      });
    });

    group('formatEquipmentForDisplay', () {
      test('delegates to formatPreferenceForDisplay', () {
        // Arrange
        const input = 'soccer ball';
        
        // Act
        final result = PreferenceUtils.formatEquipmentForDisplay(input);
        
        // Assert
        expect(result, 'Soccer Ball');
      });
    });

    group('formatTrainingStyleForDisplay', () {
      test('delegates to formatPreferenceForDisplay', () {
        // Arrange
        const input = 'low intensity';
        
        // Act
        final result = PreferenceUtils.formatTrainingStyleForDisplay(input);
        
        // Assert
        expect(result, 'Low Intensity');
      });
    });

    group('formatLocationForDisplay', () {
      test('delegates to formatPreferenceForDisplay', () {
        // Arrange
        const input = 'full field';
        
        // Act
        final result = PreferenceUtils.formatLocationForDisplay(input);
        
        // Assert
        expect(result, 'Full Field');
      });
    });

    group('formatDifficultyForDisplay', () {
      test('applies title case to difficulty levels', () {
        // Arrange
        const input = 'beginner';
        
        // Act
        final result = PreferenceUtils.formatDifficultyForDisplay(input);
        
        // Assert
        expect(result, 'Beginner');
      });

      test('handles intermediate difficulty', () {
        // Arrange
        const input = 'intermediate';
        
        // Act
        final result = PreferenceUtils.formatDifficultyForDisplay(input);
        
        // Assert
        expect(result, 'Intermediate');
      });

      test('handles advanced difficulty', () {
        // Arrange
        const input = 'advanced';
        
        // Act
        final result = PreferenceUtils.formatDifficultyForDisplay(input);
        
        // Assert
        expect(result, 'Advanced');
      });
    });
  });
}

