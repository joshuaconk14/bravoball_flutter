import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

/// User Manager Service
/// Mirrors Swift UserManager for managing user state and authentication
class UserManagerService extends ChangeNotifier {
  static UserManagerService? _instance;
  static UserManagerService get instance => _instance ??= UserManagerService._();
  
  UserManagerService._();

  // User state
  String _email = '';
  String _accessToken = '';
  String _refreshToken = '';
  bool _isLoggedIn = false;
  bool _userHasAccountHistory = false;
  bool _showLoginPage = false;
  bool _showIntroAnimation = true;

  // Getters
  String get email => _email;
  String get accessToken => _accessToken;
  String get refreshToken => _refreshToken;
  bool get isLoggedIn => _isLoggedIn;
  bool get userHasAccountHistory => _userHasAccountHistory;
  bool get showLoginPage => _showLoginPage;
  bool get showIntroAnimation => _showIntroAnimation;

  /// Initialize user manager and check for existing auth state
  Future<void> initialize() async {
    if (kDebugMode) {
      print('🔐 UserManager: Initializing...');
    }
    
    await _loadUserDataFromStorage();
    
    if (kDebugMode) {
      print('🔐 UserManager: Initialized');
      print('   Email: $_email');
      print('   IsLoggedIn: $_isLoggedIn');
      print('   HasHistory: $_userHasAccountHistory');
    }
  }

  /// Load user data from persistent storage
  Future<void> _loadUserDataFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _email = prefs.getString('userEmail') ?? '';
      _accessToken = prefs.getString('accessToken') ?? '';
      _refreshToken = prefs.getString('refreshToken') ?? '';
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _userHasAccountHistory = prefs.getBool('userHasAccountHistory') ?? false;
      
      if (kDebugMode) {
        print('🔑 UserManager: Loaded from storage - Email: $_email, LoggedIn: $_isLoggedIn');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ UserManager: Error loading user data: $e');
      }
    }
  }

  /// Save user data to persistent storage
  Future<void> _saveUserDataToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('userEmail', _email);
      await prefs.setString('accessToken', _accessToken);
      await prefs.setString('refreshToken', _refreshToken);
      await prefs.setBool('isLoggedIn', _isLoggedIn);
      await prefs.setBool('userHasAccountHistory', _userHasAccountHistory);
      
      if (kDebugMode) {
        print('💾 UserManager: Saved to storage - Email: $_email, LoggedIn: $_isLoggedIn');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ UserManager: Error saving user data: $e');
      }
    }
  }

  /// Update user data after successful login (mirrors Swift updateUserKeychain)
  Future<void> updateUserData({
    required String email,
    required String accessToken,
    String? refreshToken,
  }) async {
    _email = email;
    _accessToken = accessToken;
    _refreshToken = refreshToken ?? '';
    _isLoggedIn = true;
    _userHasAccountHistory = true;
    _showLoginPage = false;
    
    await _saveUserDataToStorage();
    notifyListeners();
    
    if (kDebugMode) {
      print('✅ UserManager: Updated user data for $_email');
      print('🔑 Access token: ${_accessToken.isEmpty ? 'empty' : '${_accessToken.substring(0, 20)}...'}');
    }
  }

  /// Clear user data and logout
  Future<void> logout() async {
    if (kDebugMode) {
      print('🚪 UserManager: Logging out user $_email');
    }
    
    _email = '';
    _accessToken = '';
    _refreshToken = '';
    _isLoggedIn = false;
    _userHasAccountHistory = false;
    _showLoginPage = false;
    
    await _clearUserDataFromStorage();
    notifyListeners();
    
    if (kDebugMode) {
      print('✅ UserManager: User logged out successfully');
    }
  }

  /// Clear user data from storage
  Future<void> _clearUserDataFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove('userEmail');
      await prefs.remove('accessToken');
      await prefs.remove('refreshToken');
      await prefs.remove('isLoggedIn');
      await prefs.remove('userHasAccountHistory');
      
      if (kDebugMode) {
        print('🗑️ UserManager: Cleared storage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ UserManager: Error clearing storage: $e');
      }
    }
  }

  /// Show login page
  void showLogin() {
    _showLoginPage = true;
    notifyListeners();
  }

  /// Hide login page
  void hideLogin() {
    _showLoginPage = false;
    notifyListeners();
  }

  /// Hide intro animation
  void hideIntroAnimation() {
    _showIntroAnimation = false;
    notifyListeners();
  }

  /// Check if user has valid authentication token
  bool get hasValidToken => _accessToken.isNotEmpty && _isLoggedIn;

  /// Get authorization header for API requests
  Map<String, String> get authHeaders {
    if (_accessToken.isEmpty) return {};
    
    return {
      'Authorization': 'Bearer $_accessToken',
    };
  }

  /// Update access token (for token refresh)
  Future<void> updateAccessToken(String newAccessToken) async {
    _accessToken = newAccessToken;
    await _saveUserDataToStorage();
    notifyListeners();
    
    if (kDebugMode) {
      print('🔄 UserManager: Updated access token');
    }
  }

  /// Debug info
  String get debugInfo {
    return '''
User Manager Debug Info:
- Email: $_email
- IsLoggedIn: $_isLoggedIn
- HasAccountHistory: $_userHasAccountHistory
- HasToken: ${_accessToken.isNotEmpty}
- TokenLength: ${_accessToken.length}
- ShowLoginPage: $_showLoginPage
''';
  }
} 