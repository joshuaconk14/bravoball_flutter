import 'package:flutter/services.dart';

/// Utility class for managing haptic feedback throughout the app
/// Provides different levels of haptic feedback for various interactions
class HapticUtils {
  /// Light haptic feedback - for small interactions like toggles, checkboxes, filter chips
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  /// Medium haptic feedback - for most buttons, drill cards, modal actions
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy haptic feedback - for major navigation, tab switching, important actions
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  /// Selection feedback - for selecting items, drag operations
  static void selectionClick() {
    HapticFeedback.selectionClick();
  }

  /// Vibrate pattern - for special events like session completion
  static void vibrate() {
    HapticFeedback.vibrate();
  }
} 