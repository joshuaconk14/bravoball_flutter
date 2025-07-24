import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// App Configuration
/// Mirrors Swift's GlobalSettings for environment and debug configuration
class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();

  // MARK: - Environment Configuration
  /// App Development Cases (mirrors Swift appDevCase)
  /// 1: Production
  /// 2: Computer (localhost)
  /// 3: Phone (Wi-Fi IP)
  static const int appDevCase = 2; // For changing devices when testing

  /// Debug mode toggle
  static const bool debug = true; // Set false in production

  /// Wi-Fi IP address for phone testing - loaded from .env file
  /// You can find this by running `ipconfig getifaddr en0` on macOS
  static String get phoneWifiIP => dotenv.env['PHONE_WIFI_IP'] ?? '127.0.0.1';

  // MARK: - Environment Settings
  /// Get base URL based on app development case
  static String get baseUrl {
    if (kDebugMode) {
      switch (appDevCase) {
        case 1:
          // Production (simulated during debug)
          return 'https://bravoball-backend.onrender.com';
        case 2:
          // Localhost for simulator or computer
          // Use 10.0.2.2 for Android emulator, 127.0.0.1 for iOS simulator
          if (defaultTargetPlatform == TargetPlatform.android) {
            return 'http://10.0.2.2:8000';
          } else {
            return 'http://127.0.0.1:8000';
          }
        case 3:
          // Wi-Fi IP for phone testing
          return 'http://$phoneWifiIP:8000';
        default:
          if (defaultTargetPlatform == TargetPlatform.android) {
            return 'http://10.0.2.2:8000';
          } else {
            return 'http://127.0.0.1:8000';
          }
      }
    } else {
      // Always use production in release builds
      return 'https://bravoball-backend.onrender.com';
    }
  }

  // MARK: - Environment Info
  /// Get current environment name
  static String get environmentName {
    switch (appDevCase) {
      case 1:
        return 'Production';
      case 2:
        return 'Localhost';
      case 3:
        return 'Wi-Fi IP';
      default:
        return 'Unknown';
    }
  }

  // MARK: - Debug Settings
  /// Main debug toggle - set to true for test data, false for real backend
  static bool get useTestData => debug && appDevCase == 0; // Only use test data when appDevCase is 0

  /// Additional debug options
  static bool get enableDebugMenu => kDebugMode && debug;
  static bool get logApiCalls => kDebugMode && debug;
  static bool get showPerformanceOverlay => kDebugMode && false;
  static bool get fastMentalTrainingTimers => kDebugMode && debug; // Speed up mental training timers for testing

  // MARK: - Test Data Settings (when useTestData is true)
  static const int testDrillCount = 5;
  static const String testUserEmail = 'test@bravoball.com';
  static const int testUserStreak = 3;

  // MARK: - API Configuration
  /// API timeout settings
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 15);

  /// API retry settings
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  // MARK: - Debug Info
  /// Get debug info string for display
  static String get debugInfo {
    if (!kDebugMode) return 'Release Build';

    return '''
Environment: $environmentName (Case $appDevCase)
Base URL: $baseUrl
Debug Mode: $debug
Test Data: $useTestData
API Timeout: ${apiTimeout.inSeconds}s
''';
  }

  /// Check if we should use real backend
  static bool get useRealBackend => !useTestData;

  /// Check if debug menu should be shown
  static bool get shouldShowDebugMenu => enableDebugMenu;

  /// Get full API URL with endpoint
  static String apiUrl(String endpoint) {
    if (!endpoint.startsWith('/')) {
      endpoint = '/$endpoint';
    }
    return '$baseUrl$endpoint';
  }
}

/// Environment types
enum Environment {
  production,
  localhost,
  wifiIP,
} 