import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'dart:async';

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

  // Token refresh timer
  Timer? _proactiveRefreshTimer;
  DateTime? _tokenCreatedAt;

  // ✅ NEW: Guest mode state
  bool _isGuestMode = false;
  
  // Getters
  String get email => _email;
  String get accessToken => _accessToken;
  String get refreshToken => _refreshToken;
  bool get isLoggedIn => _isLoggedIn;
  bool get userHasAccountHistory => _userHasAccountHistory;
  bool get showLoginPage => _showLoginPage;
  bool get showIntroAnimation => _showIntroAnimation;
  
  // ✅ NEW: Guest mode getters
  bool get isGuestMode => _isGuestMode;
  bool get isAuthenticated => _isLoggedIn && !_isGuestMode; // Only true for real authenticated users
  bool get hasValidToken => _accessToken.isNotEmpty && !_isGuestMode;
  
  // ✅ NEW: Combined user state getter
  String get userDisplayName {
    if (_isGuestMode) return 'Guest User';
    if (_email.isNotEmpty) return _email;
    return 'Unknown User';
  }

  /// Initialize user manager and check for existing auth state
  Future<void> initialize() async {
    if (kDebugMode) {
      print('🔐 UserManager: Initializing...');
    }
    
    await _loadUserDataFromStorage();
    
    // Start proactive token refresh if user is logged in
    if (_isLoggedIn && _accessToken.isNotEmpty) {
      _scheduleProactiveTokenRefresh();
    }
    
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
      
      // Load token creation time for proactive refresh
      final tokenCreatedAtMs = prefs.getInt('tokenCreatedAt');
      if (tokenCreatedAtMs != null) {
        _tokenCreatedAt = DateTime.fromMillisecondsSinceEpoch(tokenCreatedAtMs);
      }
      
      // ✅ Guest mode is never loaded from persistence - always starts false
      _isGuestMode = false;

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
      
      // Save token creation time
      if (_tokenCreatedAt != null) {
        await prefs.setInt('tokenCreatedAt', _tokenCreatedAt!.millisecondsSinceEpoch);
      }
      
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
    _tokenCreatedAt = DateTime.now(); // Record when token was created
    
    await _saveUserDataToStorage();
    
    // Start proactive token refresh
    _scheduleProactiveTokenRefresh();
    
    notifyListeners();
    
    if (kDebugMode) {
      print('✅ UserManager: Updated user data for $_email');
      print('🔑 Access token: ${_accessToken.isEmpty ? 'empty' : '${_accessToken.substring(0, 20)}...'}');
    }
  }

  /// Clear user data and logout
  Future<void> logout({bool skipNotification = false}) async {
    if (kDebugMode) {
      print('🚪 UserManager: Logging out user $_email');
    }
    
    try {
      // Cancel proactive refresh timer first
      _cancelProactiveTokenRefresh();
      
      // Clear all user state
      _email = '';
      _accessToken = '';
      _refreshToken = '';
      _isLoggedIn = false;
      _userHasAccountHistory = false;
      _showLoginPage = false;
      _tokenCreatedAt = null;
      _isGuestMode = false; // ✅ Also clear guest mode on logout
      
      // Clear storage
      await _clearUserDataFromStorage();
      
      // Notify listeners unless explicitly skipped
      if (!skipNotification) {
        notifyListeners();
      }
      
      if (kDebugMode) {
        print('✅ UserManager: User logged out successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ UserManager: Error during logout: $e');
      }
      // Even if there's an error, ensure we clear the login state
      _isLoggedIn = false;
      if (!skipNotification) {
        notifyListeners();
      }
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
      await prefs.remove('tokenCreatedAt');
      // ✅ No need to clear guest mode from persistence since it's never saved
      
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
    _tokenCreatedAt = DateTime.now(); // Update token creation time
    await _saveUserDataToStorage();
    
    // Reschedule proactive refresh with new token
    _scheduleProactiveTokenRefresh();
    
    notifyListeners();
    
    if (kDebugMode) {
      print('🔄 UserManager: Updated access token');
    }
  }

  // MARK: - Proactive Token Refresh

  /// Schedule proactive token refresh to happen before token expires
  void _scheduleProactiveTokenRefresh() {
    _cancelProactiveTokenRefresh(); // Cancel any existing timer
    
    if (_refreshToken.isEmpty || _tokenCreatedAt == null) {
      if (kDebugMode) {
        print('⚠️ UserManager: Cannot schedule proactive refresh - missing refresh token or creation time');
      }
      return;
    }
    
    // Refresh token 5 minutes before it expires (assuming 24-hour token life)
    // This gives us a 5-minute buffer
    const tokenLifetime = Duration(hours: 24);
    const refreshBuffer = Duration(minutes: 5);
    final refreshTime = tokenLifetime - refreshBuffer;
    
    final timeUntilRefresh = _tokenCreatedAt!.add(refreshTime).difference(DateTime.now());
    
    if (timeUntilRefresh.isNegative) {
      // Token is already near expiry, refresh immediately
      if (kDebugMode) {
        print('🔄 UserManager: Token near expiry, refreshing immediately');
      }
      _performProactiveTokenRefresh();
    } else {
      if (kDebugMode) {
        print('⏰ UserManager: Scheduled proactive token refresh in ${timeUntilRefresh.inMinutes} minutes');
      }
      
      _proactiveRefreshTimer = Timer(timeUntilRefresh, () {
        _performProactiveTokenRefresh();
      });
    }
  }

  /// Cancel proactive token refresh timer
  void _cancelProactiveTokenRefresh() {
    _proactiveRefreshTimer?.cancel();
    _proactiveRefreshTimer = null;
  }

  /// Perform proactive token refresh
  Future<void> _performProactiveTokenRefresh() async {
    if (_refreshToken.isEmpty) {
      if (kDebugMode) {
        print('❌ UserManager: Cannot perform proactive refresh - no refresh token');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('🔄 UserManager: Performing proactive token refresh...');
      }

      // The automatic refresh in API service will handle actual refreshes when needed
      // For now, just reschedule for next time to keep the timer running
      _scheduleProactiveTokenRefresh();
      
      if (kDebugMode) {
        print('✅ UserManager: Proactive refresh scheduled for next interval');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ UserManager: Error in proactive token refresh: $e');
      }
      
      // Reschedule for next attempt
      _scheduleProactiveTokenRefresh();
    }
  }

  // ✅ NEW: Enter guest mode
  Future<void> enterGuestMode() async {
    if (kDebugMode) {
      print('👤 UserManagerService: Entering guest mode');
    }
    
    // Clear any existing auth data
    await logout(skipNotification: true);
    
    // Set guest mode state
    _isGuestMode = true;
    _email = '';
    _accessToken = '';
    _refreshToken = '';
    _isLoggedIn = false;
    _userHasAccountHistory = false;
    
    // Don't persist guest mode to SharedPreferences
    // Guest mode is always temporary and memory-only
    
    if (kDebugMode) {
      print('✅ UserManagerService: Guest mode activated');
    }
    
    notifyListeners();
  }

  // ✅ NEW: Exit guest mode (usually to go to account creation/login)
  Future<void> exitGuestMode() async {
    if (kDebugMode) {
      print('👤 UserManagerService: Exiting guest mode');
    }
    
    _isGuestMode = false;
    
    if (kDebugMode) {
      print('✅ UserManagerService: Guest mode deactivated');
    }
    
    notifyListeners();
  }

  // ✅ NEW: Check if user can access premium features
  bool get canAccessPremiumFeatures => _isLoggedIn && !_isGuestMode;

  @override
  void dispose() {
    _cancelProactiveTokenRefresh();
    super.dispose();
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
- TokenCreatedAt: $_tokenCreatedAt
- ProactiveRefreshActive: ${_proactiveRefreshTimer != null}
- Is Guest Mode: $_isGuestMode
- Is Authenticated: $isAuthenticated
- Has Valid Token: $hasValidToken
- Can Access Premium: $canAccessPremiumFeatures
- User Display Name: $userDisplayName
''';
  }
} 