import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

/// Avatar Helper
/// Manages available avatar icons and provides utility methods
class AvatarHelper {
  // Available avatar asset paths
  static const List<String> availableAvatars = [
    'assets/avatar-icons/SoccerBoy1.png',
    'assets/avatar-icons/SoccerBoy2.png',
  ];

  // Avatar display names (optional, for UI)
  static const List<String> avatarNames = [
    'Soccer Boy 1',
    'Soccer Boy 2',
  ];

  // Available background colors for avatar
  static const List<Color> availableBackgroundColors = [
    AppTheme.secondaryBlue,
    AppTheme.primaryYellow,
    AppTheme.primaryGreen,
    AppTheme.primaryPurple,
    AppTheme.secondaryOrange,
    AppTheme.skillPassing,
    AppTheme.skillShooting,
    AppTheme.skillDribbling,
    AppTheme.skillFirstTouch,
    AppTheme.skillDefending,
    AppTheme.skillGoalkeeping,
    AppTheme.skillFitness,
  ];

  // Background color names for UI
  static const List<String> backgroundColorNames = [
    'Blue',
    'Yellow',
    'Green',
    'Purple',
    'Orange',
    'Cyan',
    'Magenta',
    'Orange Red',
    'Lime',
    'Brown',
    'Beige',
    'Blue',
  ];

  /// Get background color by index
  static Color? getBackgroundColor(int index) {
    if (index >= 0 && index < availableBackgroundColors.length) {
      return availableBackgroundColors[index];
    }
    return null;
  }

  /// Get background color index
  static int? getBackgroundColorIndex(Color? color) {
    if (color == null) return null;
    final index = availableBackgroundColors.indexWhere((c) => 
      c.value == color.value);
    return index >= 0 ? index : null;
  }

  /// Get default background color (first one)
  static Color getDefaultBackgroundColor() {
    return availableBackgroundColors.first;
  }

  /// Convert color to hex string for storage
  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2)}';
  }

  /// Convert hex string to color
  static Color? hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      final hexCode = hex.replaceAll('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      return null;
    }
  }

  /// Get avatar asset path by index
  static String? getAvatarPath(int index) {
    if (index >= 0 && index < availableAvatars.length) {
      return availableAvatars[index];
    }
    return null;
  }

  /// Get avatar asset path by name identifier
  static String? getAvatarPathByName(String avatarName) {
    final index = availableAvatars.indexWhere((path) => 
      path.contains(avatarName));
    if (index >= 0) {
      return availableAvatars[index];
    }
    return null;
  }

  /// Get avatar index by asset path
  static int? getAvatarIndex(String? avatarPath) {
    if (avatarPath == null) return null;
    final index = availableAvatars.indexWhere((path) => path == avatarPath);
    return index >= 0 ? index : null;
  }

  /// Get default avatar (first one)
  static String getDefaultAvatar() {
    return availableAvatars.first;
  }

  /// Check if avatar path is valid
  static bool isValidAvatar(String? avatarPath) {
    if (avatarPath == null) return false;
    return availableAvatars.contains(avatarPath);
  }

  /// Get number of available avatars
  static int get avatarCount => availableAvatars.length;
}
