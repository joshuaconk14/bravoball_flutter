import 'package:flutter_test/flutter_test.dart';
import 'package:bravoball_flutter/utils/skill_utils.dart';

void main() {
  group('SkillUtils', () {
    group('formatSkillForDisplay', () {
      test('converts underscore-separated skill to title case', () {
        // Arrange
        const input = 'first_touch';
        
        // Act
        final result = SkillUtils.formatSkillForDisplay(input);
        
        // Assert
        expect(result, 'First Touch');
      });

      test('handles single word skills', () {
        // Arrange
        const input = 'dribbling';
        
        // Act
        final result = SkillUtils.formatSkillForDisplay(input);
        
        // Assert
        expect(result, 'Dribbling');
      });

      test('handles multiple words with underscores', () {
        // Arrange
        const input = 'power_shots';
        
        // Act
        final result = SkillUtils.formatSkillForDisplay(input);
        
        // Assert
        expect(result, 'Power Shots');
      });

      test('handles already formatted strings', () {
        // Arrange
        const input = 'Dribbling';
        
        // Act
        final result = SkillUtils.formatSkillForDisplay(input);
        
        // Assert
        expect(result, 'Dribbling');
      });

      test('handles empty string', () {
        // Arrange
        const input = '';
        
        // Act
        final result = SkillUtils.formatSkillForDisplay(input);
        
        // Assert
        expect(result, '');
      });

      test('handles uppercase input', () {
        // Arrange
        const input = 'FIRST_TOUCH';
        
        // Act
        final result = SkillUtils.formatSkillForDisplay(input);
        
        // Assert
        expect(result, 'First Touch');
      });

      test('handles mixed case input', () {
        // Arrange
        const input = 'FiRsT_ToUcH';
        
        // Act
        final result = SkillUtils.formatSkillForDisplay(input);
        
        // Assert
        expect(result, 'First Touch');
      });

      test('handles multiple consecutive underscores', () {
        // Arrange
        const input = 'first___touch';
        
        // Act
        final result = SkillUtils.formatSkillForDisplay(input);
        
        // Assert
        expect(result, 'First   Touch'); // Multiple spaces preserved
      });
    });

    group('formatSkillForBackend', () {
      test('converts title case to lowercase with underscores', () {
        // Arrange
        const input = 'First Touch';
        
        // Act
        final result = SkillUtils.formatSkillForBackend(input);
        
        // Assert
        expect(result, 'first_touch');
      });

      test('handles single word skills', () {
        // Arrange
        const input = 'Dribbling';
        
        // Act
        final result = SkillUtils.formatSkillForBackend(input);
        
        // Assert
        expect(result, 'dribbling');
      });

      test('handles already formatted backend strings', () {
        // Arrange
        const input = 'first_touch';
        
        // Act
        final result = SkillUtils.formatSkillForBackend(input);
        
        // Assert
        expect(result, 'first_touch');
      });

      test('handles empty string', () {
        // Arrange
        const input = '';
        
        // Act
        final result = SkillUtils.formatSkillForBackend(input);
        
        // Assert
        expect(result, '');
      });

      test('handles uppercase input', () {
        // Arrange
        const input = 'FIRST TOUCH';
        
        // Act
        final result = SkillUtils.formatSkillForBackend(input);
        
        // Assert
        expect(result, 'first_touch');
      });

      test('handles mixed case input', () {
        // Arrange
        const input = 'FiRsT ToUcH';
        
        // Act
        final result = SkillUtils.formatSkillForBackend(input);
        
        // Assert
        expect(result, 'first_touch');
      });
    });

    group('normalizeSkill', () {
      test('converts underscore format to normalized format', () {
        // Arrange
        const input = 'first_touch';
        
        // Act
        final result = SkillUtils.normalizeSkill(input);
        
        // Assert
        expect(result, 'first touch');
      });

      test('converts title case to normalized format', () {
        // Arrange
        const input = 'First Touch';
        
        // Act
        final result = SkillUtils.normalizeSkill(input);
        
        // Assert
        expect(result, 'first touch');
      });

      test('converts uppercase to normalized format', () {
        // Arrange
        const input = 'DRIBBLING';
        
        // Act
        final result = SkillUtils.normalizeSkill(input);
        
        // Assert
        expect(result, 'dribbling');
      });

      test('handles already normalized strings', () {
        // Arrange
        const input = 'first touch';
        
        // Act
        final result = SkillUtils.normalizeSkill(input);
        
        // Assert
        expect(result, 'first touch');
      });

      test('handles empty string', () {
        // Arrange
        const input = '';
        
        // Act
        final result = SkillUtils.normalizeSkill(input);
        
        // Assert
        expect(result, '');
      });

      test('handles single word skills', () {
        // Arrange
        const input = 'dribbling';
        
        // Act
        final result = SkillUtils.normalizeSkill(input);
        
        // Assert
        expect(result, 'dribbling');
      });
    });

    group('areSkillsEqual', () {
      test('returns true for same skill with different formats', () {
        // Arrange
        const skill1 = 'first_touch';
        const skill2 = 'First Touch';
        
        // Act
        final result = SkillUtils.areSkillsEqual(skill1, skill2);
        
        // Assert
        expect(result, true);
      });

      test('returns true for same skill with same format', () {
        // Arrange
        const skill1 = 'first_touch';
        const skill2 = 'first_touch';
        
        // Act
        final result = SkillUtils.areSkillsEqual(skill1, skill2);
        
        // Assert
        expect(result, true);
      });

      test('returns false for different skills', () {
        // Arrange
        const skill1 = 'first_touch';
        const skill2 = 'dribbling';
        
        // Act
        final result = SkillUtils.areSkillsEqual(skill1, skill2);
        
        // Assert
        expect(result, false);
      });

      test('handles case-insensitive comparison', () {
        // Arrange
        const skill1 = 'FIRST_TOUCH';
        const skill2 = 'first_touch';
        
        // Act
        final result = SkillUtils.areSkillsEqual(skill1, skill2);
        
        // Assert
        expect(result, true);
      });

      test('handles empty strings', () {
        // Arrange
        const skill1 = '';
        const skill2 = '';
        
        // Act
        final result = SkillUtils.areSkillsEqual(skill1, skill2);
        
        // Assert
        expect(result, true);
      });

      test('handles one empty string and one non-empty', () {
        // Arrange
        const skill1 = '';
        const skill2 = 'dribbling';
        
        // Act
        final result = SkillUtils.areSkillsEqual(skill1, skill2);
        
        // Assert
        expect(result, false);
      });
    });
  });
}

