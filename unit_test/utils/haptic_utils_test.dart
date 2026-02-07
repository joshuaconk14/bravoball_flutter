import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bravoball_flutter/utils/haptic_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('HapticUtils', () {
    // Note: These tests verify that the methods call the correct HapticFeedback methods
    // Since HapticFeedback methods are static and don't return values, we can't easily
    // verify they were called without more complex mocking. However, we can verify
    // that the methods don't throw exceptions and execute successfully.
    
    test('lightImpact does not throw exception', () {
      // Act & Assert
      expect(() => HapticUtils.lightImpact(), returnsNormally);
    });

    test('mediumImpact does not throw exception', () {
      // Act & Assert
      expect(() => HapticUtils.mediumImpact(), returnsNormally);
    });

    test('heavyImpact does not throw exception', () {
      // Act & Assert
      expect(() => HapticUtils.heavyImpact(), returnsNormally);
    });

    test('selectionClick does not throw exception', () {
      // Act & Assert
      expect(() => HapticUtils.selectionClick(), returnsNormally);
    });

    test('vibrate does not throw exception', () {
      // Act & Assert
      expect(() => HapticUtils.vibrate(), returnsNormally);
    });

    // Integration-style test: Verify all methods can be called in sequence
    test('all haptic methods can be called in sequence', () {
      // Act & Assert - Should not throw
      expect(() {
        HapticUtils.lightImpact();
        HapticUtils.mediumImpact();
        HapticUtils.heavyImpact();
        HapticUtils.selectionClick();
        HapticUtils.vibrate();
      }, returnsNormally);
    });
  });
}

