import 'package:flutter_test/flutter_test.dart';
import 'package:bravoball_flutter/utils/encryption_utils.dart';

void main() {
  group('EncryptionUtils', () {
    group('generateSecureRandomString', () {
      test('generates string of correct length', () {
        // Arrange
        const length = 10;
        
        // Act
        final result = EncryptionUtils.generateSecureRandomString(length);
        
        // Assert
        expect(result.length, length);
      });

      test('generates different strings on each call', () {
        // Arrange
        const length = 20;
        
        // Act
        final result1 = EncryptionUtils.generateSecureRandomString(length);
        final result2 = EncryptionUtils.generateSecureRandomString(length);
        
        // Assert
        expect(result1, isNot(equals(result2)));
        expect(result1.length, length);
        expect(result2.length, length);
      });

      test('generates string with alphanumeric characters', () {
        // Arrange
        const length = 50;
        const validChars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        
        // Act
        final result = EncryptionUtils.generateSecureRandomString(length);
        
        // Assert
        expect(result.length, length);
        for (final char in result.split('')) {
          expect(validChars.contains(char), isTrue, reason: 'Character $char should be alphanumeric');
        }
      });

      test('handles zero length', () {
        // Arrange
        const length = 0;
        
        // Act
        final result = EncryptionUtils.generateSecureRandomString(length);
        
        // Assert
        expect(result, isEmpty);
      });

      test('handles large length', () {
        // Arrange
        const length = 1000;
        
        // Act
        final result = EncryptionUtils.generateSecureRandomString(length);
        
        // Assert
        expect(result.length, length);
      });
    });

    group('hashString', () {
      test('generates consistent hash for same input', () {
        // Arrange
        const input = 'test_string';
        
        // Act
        final hash1 = EncryptionUtils.hashString(input);
        final hash2 = EncryptionUtils.hashString(input);
        
        // Assert
        expect(hash1, equals(hash2));
        expect(hash1.length, greaterThan(0));
      });

      test('generates different hashes for different inputs', () {
        // Arrange
        const input1 = 'test_string_1';
        const input2 = 'test_string_2';
        
        // Act
        final hash1 = EncryptionUtils.hashString(input1);
        final hash2 = EncryptionUtils.hashString(input2);
        
        // Assert
        expect(hash1, isNot(equals(hash2)));
      });

      test('generates SHA-256 hash (64 hex characters)', () {
        // Arrange
        const input = 'test_string';
        
        // Act
        final hash = EncryptionUtils.hashString(input);
        
        // Assert
        expect(hash.length, 64); // SHA-256 produces 64 hex characters
        expect(hash, matches(RegExp(r'^[0-9a-f]{64}$'))); // Hex format
      });

      test('handles empty string', () {
        // Arrange
        const input = '';
        
        // Act
        final hash = EncryptionUtils.hashString(input);
        
        // Assert
        expect(hash.length, 64); // Still produces valid hash
      });

      test('handles special characters', () {
        // Arrange
        const input = r'test@#$%^&*()_+{}|:"<>?[]\;'',./-=';
        
        // Act
        final hash = EncryptionUtils.hashString(input);
        
        // Assert
        expect(hash.length, 64);
        expect(hash, matches(RegExp(r'^[0-9a-f]{64}$')));
      });

      test('handles unicode characters', () {
        // Arrange
        const input = 'test_测试_тест_🎯';
        
        // Act
        final hash = EncryptionUtils.hashString(input);
        
        // Assert
        expect(hash.length, 64);
        expect(hash, matches(RegExp(r'^[0-9a-f]{64}$')));
      });
    });

    group('verifyHash', () {
      test('returns true for matching hash', () {
        // Arrange
        const input = 'test_string';
        final hash = EncryptionUtils.hashString(input);
        
        // Act
        final result = EncryptionUtils.verifyHash(input, hash);
        
        // Assert
        expect(result, isTrue);
      });

      test('returns false for non-matching hash', () {
        // Arrange
        const input = 'test_string';
        const wrongHash = '0000000000000000000000000000000000000000000000000000000000000000';
        
        // Act
        final result = EncryptionUtils.verifyHash(input, wrongHash);
        
        // Assert
        expect(result, isFalse);
      });

      test('returns false for different input with correct hash', () {
        // Arrange
        const input1 = 'test_string_1';
        const input2 = 'test_string_2';
        final hash1 = EncryptionUtils.hashString(input1);
        
        // Act
        final result = EncryptionUtils.verifyHash(input2, hash1);
        
        // Assert
        expect(result, isFalse);
      });

      test('handles empty string', () {
        // Arrange
        const input = '';
        final hash = EncryptionUtils.hashString(input);
        
        // Act
        final result = EncryptionUtils.verifyHash(input, hash);
        
        // Assert
        expect(result, isTrue);
      });

      test('round-trip verification works', () {
        // Arrange
        const testCases = [
          'simple_string',
          'string with spaces',
          'StringWithMixedCase',
          'string_with_underscores',
          '123456789',
          r'special@#$%chars',
          '',
        ];
        
        // Act & Assert
        for (final input in testCases) {
          final hash = EncryptionUtils.hashString(input);
          final isValid = EncryptionUtils.verifyHash(input, hash);
          expect(isValid, isTrue, reason: 'Hash verification should pass for: $input');
        }
      });
    });

    // Note: Testing encrypt/decrypt methods would require mocking SharedPreferences
    // and DeviceInfo, which is more complex. These are integration-style tests
    // that would be better suited for integration_test directory.
    // 
    // The following tests verify the pure functions that don't require external dependencies:
    
    group('Hash consistency', () {
      test('hashString produces deterministic results', () {
        // Arrange
        const input = 'deterministic_test';
        
        // Act
        final hash1 = EncryptionUtils.hashString(input);
        final hash2 = EncryptionUtils.hashString(input);
        final hash3 = EncryptionUtils.hashString(input);
        
        // Assert
        expect(hash1, equals(hash2));
        expect(hash2, equals(hash3));
      });

      test('verifyHash correctly validates known hashes', () {
        // Arrange
        // Known SHA-256 hash for empty string
        const emptyStringHash = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
        const emptyString = '';
        
        // Act
        final result = EncryptionUtils.verifyHash(emptyString, emptyStringHash);
        
        // Assert
        expect(result, isTrue);
      });
    });
  });
}

