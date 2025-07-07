import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Global app theme and color definitions
/// Centralizes all design tokens for consistent styling across the app
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // MARK: - Primary Colors
  static const Color primaryYellow = Color(0xFFF9CC53);
  static const Color primaryDarkYellow = Color(0xFFE6B547);
  static const Color primaryGreen = Color(0xFF70D412);
  static const Color primaryDarkGreen = Color(0xFF60AE17);
  static const Color primaryPurple = Color(0xFF8E4EC6);
  static const Color primaryDarkPurple = Color(0xFF7A42A8);
  
  // MARK: - Secondary Colors
  static const Color secondaryBlue = Color(0xFF86C9F7);
  static const Color secondaryOrange = Colors.orange;
  static const Color secondaryRed = Colors.red;
  
  // MARK: - Neutral Colors
  static const Color primaryDark = Color(0xFF2C2C2C);
  static const Color primaryGray = Color(0xFF8E8E93);
  static const Color lightGray = Color(0xFFF2F2F7);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  
  // MARK: - Semantic Colors
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF007AFF);
  
  // MARK: - Button Colors
  static const Color buttonPrimary = primaryYellow;
  static const Color buttonPrimaryDark = primaryDarkYellow;
  static const Color buttonSecondary = lightGray;
  static const Color buttonDisabled = Color(0xFFE5E5EA);
  
  // MARK: - Text Colors
  static const Color textPrimary = primaryDark;
  static const Color textSecondary = primaryGray;
  static const Color textOnPrimary = white;
  static const Color textOnSecondary = primaryDark;
  
  // MARK: - Background Colors
  static const Color backgroundPrimary = white;
  static const Color backgroundSecondary = lightGray;
  static const Color backgroundField = primaryGreen;
  
  // MARK: - Speech Bubble Colors
  static const Color speechBubbleBackground = primaryDarkGreen;
  static const Color speechBubbleText = white;
  
  // MARK: - Skill Colors (for drill categories)
  static const Color skillPassing = Color(0xFF007AFF);
  static const Color skillShooting = Color(0xFFFF3B30);
  static const Color skillDribbling = Color(0xFF34C759);
  static const Color skillFirstTouch = Color(0xFF8E4EC6);
  static const Color skillDefending = Color(0xFFFF9500);
  static const Color skillFitness = Color(0xFF32ADE6);
  
  /// Get skill color by skill name
  static Color getSkillColor(String skill) {
    switch (skill.toLowerCase()) {
      case 'passing':
        return skillPassing;
      case 'shooting':
        return skillShooting;
      case 'dribbling':
        return skillDribbling;
      case 'first touch':
        return skillFirstTouch;
      case 'defending':
        return skillDefending;
      case 'fitness':
        return skillFitness;
      default:
        return primaryGray;
    }
  }
  
  // MARK: - Font Families
  static const String fontPoppins = 'Poppins';
  static const String fontPottaOne = 'PottaOne';
  
  // MARK: - Text Styles
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontPoppins,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontPoppins,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontPoppins,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );
  
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontPoppins,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontPoppins,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontPoppins,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontPoppins,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontPoppins,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontPoppins,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );
  
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontPoppins,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontPoppins,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontPoppins,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );
  
  // MARK: - Button Text Styles
  static const TextStyle buttonTextLarge = TextStyle(
    fontFamily: fontPoppins,
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: textOnPrimary,
  );
  
  static const TextStyle buttonTextMedium = TextStyle(
    fontFamily: fontPoppins,
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: textOnPrimary,
  );
  
  static const TextStyle buttonTextSmall = TextStyle(
    fontFamily: fontPoppins,
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: textOnPrimary,
  );
  
  // MARK: - Spacing
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  
  // MARK: - Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusRound = 50.0;
  
  // MARK: - Elevation
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
  
  // MARK: - Flutter ThemeData
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryYellow,
        brightness: Brightness.light,
        primary: primaryYellow,
        secondary: primaryGreen,
        surface: backgroundPrimary,
        error: error,
      ),
      fontFamily: fontPoppins,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundPrimary,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: titleLarge,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonPrimary,
          foregroundColor: textOnPrimary,
          textStyle: buttonTextMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLarge,
            vertical: spacingMedium,
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      ),
    );
  }
}

/// Environment types for API endpoints
enum Environment {
  production,
  localhost,
  staging,
}

/// Debug and Environment Settings
/// Similar to iOS GlobalSettings for easy debugging and environment switching
class AppSettings {
  // Private constructor
  AppSettings._();
  
  // MARK: - Debug Settings
  /// Main debug toggle - set to true for test data, false for real backend
  static const bool useTestData = true; // CHANGE THIS TO TOGGLE DEBUG MODE
  
  /// Additional debug options
  static const bool enableDebugMenu = true; // Show debug menu in profile
  static const bool logApiCalls = true; // Log API calls in debug mode
  static const bool showPerformanceOverlay = false; // Show Flutter performance overlay
  
  // MARK: - Environment Settings
  /// Current environment (only used when useTestData is false)
  static const Environment currentEnvironment = Environment.localhost;
  
  /// Get base URL based on environment
  static String get baseUrl {
    if (kDebugMode) {
      switch (currentEnvironment) {
        case Environment.production:
          return 'https://bravoball-backend.onrender.com';
        case Environment.localhost:
          return 'http://127.0.0.1:8000';
        case Environment.staging:
          return 'https://staging-bravoball-backend.onrender.com'; // Example staging URL
      }
    } else {
      // Always use production in release builds
      return 'https://bravoball-backend.onrender.com';
    }
  }
  
  // MARK: - Test Data Settings
  /// Number of test drills to generate
  static const int testDrillCount = 5;
  
  /// Test user settings
  static const String testUserEmail = 'test@bravoball.com';
  static const int testUserStreak = 3;
  
  // MARK: - Debug Info
  /// Get debug info string for display
  static String get debugInfo {
    if (!kDebugMode) return 'Release Build';
    
    return '''
Debug Mode: ${useTestData ? 'Test Data' : 'Backend Data'}
Environment: ${currentEnvironment.name}
Base URL: $baseUrl
Test Drills: $testDrillCount
''';
  }
  
  /// Check if we should use test data
  static bool get shouldUseTestData {
    return kDebugMode && useTestData;
  }
  
  /// Check if debug menu should be shown
  static bool get shouldShowDebugMenu {
    return kDebugMode && enableDebugMenu;
  }
} 