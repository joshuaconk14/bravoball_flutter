import 'package:flutter/foundation.dart';

class AdConfig {
  // Ad frequency settings
  static const int adsAfterEveryNOpens = 3; // Show ad every 3 app opens
  static const int minTimeBetweenAds = 180; // 5 minutes between ads (seconds)
  
  // Test ad unit IDs (Google's official test IDs)
  static const String androidTestAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String iosTestAdUnitId = 'ca-app-pub-3940256099942544/4411468910';
  
  // Production ad unit IDs (REPLACE WITH YOUR ACTUAL IDs)
  static const String androidProductionAdUnitId = 'ca-app-pub-3940256099942544/1033173712'; // Replace with your ID
  static const String iosProductionAdUnitId = 'ca-app-pub-3940256099942544/4411468910'; // Replace with your ID
  
  // App IDs for Google Mobile Ads
  static const String androidAppId = 'ca-app-pub-3940256099942544~3347511713'; // Replace with your ID
  static const String iosAppId = 'ca-app-pub-3940256099942544~1458002511'; // Replace with your ID
  
  // Get the appropriate ad unit ID based on platform and build mode
  static String get adUnitId {
    if (kDebugMode) {
      // Use test ad unit IDs in debug mode
      return androidTestAdUnitId; // For now, just return Android test ID
    } else {
      // Use production ad unit IDs in release mode
      return androidProductionAdUnitId; // For now, just return Android production ID
    }
  }
  
  // Get the appropriate app ID based on platform and build mode
  static String get appId {
    if (kDebugMode) {
      // Use test app IDs in debug mode
      return androidAppId; // For now, just return Android test ID
    } else {
      // Use production app IDs in release mode
      return androidAppId; // For now, just return Android production ID
    }
  }
  
  // Check if ads should be enabled
  static bool get adsEnabled {
    // You can add logic here to disable ads for premium users, etc.
    return true;
  }
  
  // Check if ads should be shown in debug mode
  static bool get showAdsInDebugMode {
    return true; // Set to false if you don't want test ads during development
  }
}
