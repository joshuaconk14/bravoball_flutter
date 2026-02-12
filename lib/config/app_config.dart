import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// App Configuration
/// Mirrors Swift's GlobalSettings for environment and debug configuration
class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();

  // MARK: - Environment Configuration
  /// App Development Cases (mirrors Swift appDevCase)
  /// 0: Staging (Testing db for migration) - Points to bravoball-staging.onrender.com
  /// 1: Legacy Production (DEPRECATED)
  /// 2: Computer (localhost)
  /// 3: Phone (Wi-Fi IP)
  /// 4: V2 Backend (App Store Review & Production)
  static const int appDevCase = 4; // Localhost for local backend testing

  /// Debug mode toggle
  static const bool debug = false; // Enable debug for local testing

  /// Wi-Fi IP address for phone testing - loaded from .env file
  /// You can find this by running `ipconfig getifaddr en0` on macOS
  static String get phoneWifiIP => dotenv.env['PHONE_WIFI_IP'] ?? '127.0.0.1';

  // MARK: - Environment Settings
  /// Get base URL based on app development case
  static String get baseUrl {
    // Use appDevCase for both debug and release builds
    // This allows TestFlight builds to use staging backend
    switch (appDevCase) {
      case 0:
        // Staging for migration testing / TestFlight testing
        return 'https://bravoball-staging.onrender.com';
      case 1:
        // DEPRECATED: Production (simulated during debug)
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
      case 4:
        // V2 Backend for App Store review / Production
        return 'https://bravoball-v2-backend.onrender.com';
      default:
        if (defaultTargetPlatform == TargetPlatform.android) {
          return 'http://10.0.2.2:8000';
        } else {
          return 'http://127.0.0.1:8000';
        }
    }
  }

  // MARK: - Environment Info
  /// Get current environment name
  static String get environmentName {
    switch (appDevCase) {
      case 0:
        return 'Staging';
      case 1:
        return 'Legacy Production (Deprecated)';
      case 2:
        return 'Localhost';
      case 3:
        return 'Wi-Fi IP';
      case 4:
        return 'V2 Backend';
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
  static bool get fastMentalTrainingTimers => kDebugMode && debug;
  
  /// Verbose backend logging - set to false to show only simple success/failure messages
  /// When false: Shows "✅ API endpoint loaded successfully" or "❌ API endpoint failed"
  /// When true: Shows full API request/response details including response bodies
  static const bool verboseBackendLogging = true;
  

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