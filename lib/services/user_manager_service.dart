import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../utils/avatar_helper.dart';
import '../services/profile_service.dart'; // ✅ ADDED: Import ProfileService for backend sync
import 'dart:async';

/// User Manager Service
// Mirrors Swift UserManager for managing user state and authentication
class UserManagerService extends ChangeNotifier {
  static UserManagerService? _instance;
  static UserManagerService get instance => _instance ??= UserManagerService._();
  
  UserManagerService._();

  // User state
  String _email = '';
  String _username = '';
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
  
  // ✅ NEW: Avatar selection
  String? _selectedAvatar;
  Color? _avatarBackgroundColor;
  
  // Getters
  String get email => _email;
  String get username => _username;
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
    if (_username.isNotEmpty) return _username;
    if (_email.isNotEmpty) return _email;
    return 'Unknown User';
  }
  
  // ✅ NEW: Avatar getters
  String? get selectedAvatar => _selectedAvatar;
  Color? get avatarBackgroundColor => _avatarBackgroundColor;

  /// Initialize user manager and check for existing auth state
  Future<void> initialize() async {
    if (kDebugMode) {
      print('🔐 UserManager: Initializing...');
    }
    
    await _loadUserDataFromStorage();
    
    // Start proactive token refresh if user is logged in
    if (_isLoggedIn && _accessToken.isNotEmpty) {
      _scheduleProactiveTokenRefresh();
      
      // ✅ ADDED: Fetch avatar from backend if user is already logged in
      await loadAvatarFromBackend();
    }
    
    if (kDebugMode) {
      print('🔐 UserManager: Initialized');
      print('   Email: $_email');
      print('   Username: $_username');
      print('   IsLoggedIn: $_isLoggedIn');
      print('   HasHistory: $_userHasAccountHistory');
    }
  }

  /// Load avatar from backend for already logged-in users
  /// Can be called after token refresh to ensure avatar is up to date
  Future<void> loadAvatarFromBackend() async {
    if (_isGuestMode || !_isLoggedIn) return;
    
    try {
      final profileData = await ProfileService.shared.fetchUserProfile();
      if (profileData != null) {
        final avatarPath = profileData['avatar_path'] as String?;
        final avatarBackgroundColorStr = profileData['avatar_background_color'] as String?;
        
        if (kDebugMode) {
          print('🖼️ UserManager: Loading avatar from backend');
          print('   Raw avatar_path: $avatarPath');
          print('   Raw avatar_background_color: $avatarBackgroundColorStr');
        }
        
        // Validate and set avatar path
        if (avatarPath != null && avatarPath.isNotEmpty) {
          // Check if the path is valid (exists in available avatars)
          if (AvatarHelper.isValidAvatar(avatarPath)) {
            _selectedAvatar = avatarPath;
            if (kDebugMode) {
              print('✅ UserManager: Valid avatar path set: $avatarPath');
            }
          } else {
            // Try to find avatar by name if path doesn't match exactly
            final avatarName = avatarPath.split('/').last.split('.').first;
            final foundPath = AvatarHelper.getAvatarPathByName(avatarName);
            if (foundPath != null) {
              _selectedAvatar = foundPath;
              if (kDebugMode) {
                print('✅ UserManager: Found avatar by name: $foundPath (from $avatarPath)');
              }
            } else {
              if (kDebugMode) {
                print('⚠️ UserManager: Invalid avatar path from backend: $avatarPath');
                print('   Falling back to default avatar');
              }
              _selectedAvatar = null; // Will use default in UI
            }
          }
        } else {
          if (kDebugMode) {
            print('⚠️ UserManager: No avatar_path in backend response (null or empty)');
          }
          _selectedAvatar = null; // Will use default in UI
        }
        
        // Set background color
        if (avatarBackgroundColorStr != null && avatarBackgroundColorStr.isNotEmpty) {
          final bgColor = AvatarHelper.hexToColor(avatarBackgroundColorStr);
          if (bgColor != null) {
            _avatarBackgroundColor = bgColor;
            if (kDebugMode) {
              print('✅ UserManager: Background color set: $bgColor');
            }
          } else {
            if (kDebugMode) {
              print('⚠️ UserManager: Invalid background color format: $avatarBackgroundColorStr');
            }
            _avatarBackgroundColor = AvatarHelper.getDefaultBackgroundColor();
          }
        } else {
          _avatarBackgroundColor = AvatarHelper.getDefaultBackgroundColor();
          if (kDebugMode) {
            print('⚠️ UserManager: No background color in backend response, using default');
          }
        }
        
        notifyListeners();
        
        if (kDebugMode) {
          print('✅ UserManager: Avatar loading complete');
          print('   Final selectedAvatar: ${_selectedAvatar ?? "null (will use default)"}');
          print('   Final avatarBackgroundColor: $_avatarBackgroundColor');
        }
      } else {
        // ✅ FIX: If profile data is null, clear avatar to default
        _selectedAvatar = null;
        _avatarBackgroundColor = AvatarHelper.getDefaultBackgroundColor();
        notifyListeners();
        if (kDebugMode) {
          print('⚠️ UserManager: Profile data is null, cleared avatar to default');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ UserManager: Error loading avatar from backend: $e');
        print('   Stack trace: ${StackTrace.current}');
      }
      // Don't throw - avatar loading failure shouldn't break app initialization
    }
  }

  /// Load user data from persistent storage
  Future<void> _loadUserDataFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _email = prefs.getString('userEmail') ?? '';
      _username = prefs.getString('username') ?? '';
      _accessToken = prefs.getString('accessToken') ?? '';
      _refreshToken = prefs.getString('refreshToken') ?? '';
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _userHasAccountHistory = prefs.getBool('userHasAccountHistory') ?? false;
      
      // ✅ REMOVED: Avatar no longer stored in SharedPreferences - loaded from backend
      
      // Load token creation time for proactive refresh
      final tokenCreatedAtMs = prefs.getInt('tokenCreatedAt');
      if (tokenCreatedAtMs != null) {
        _tokenCreatedAt = DateTime.fromMillisecondsSinceEpoch(tokenCreatedAtMs);
      }
      
      // ✅ Guest mode is never loaded from persistence - always starts false
      _isGuestMode = false;

      if (kDebugMode) {
        print('🔑 UserManager: Loaded from storage - Email: $_email, Username: $_username, LoggedIn: $_isLoggedIn');
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
      await prefs.setString('username', _username);
      await prefs.setString('accessToken', _accessToken);
      await prefs.setString('refreshToken', _refreshToken);
      await prefs.setBool('isLoggedIn', _isLoggedIn);
      await prefs.setBool('userHasAccountHistory', _userHasAccountHistory);
      
      // ✅ REMOVED: Avatar no longer stored in SharedPreferences - synced to backend only
      
      // Save token creation time
      if (_tokenCreatedAt != null) {
        await prefs.setInt('tokenCreatedAt', _tokenCreatedAt!.millisecondsSinceEpoch);
      }
      
      if (kDebugMode) {
        print('💾 UserManager: Saved to storage - Email: $_email, Username: $_username, LoggedIn: $_isLoggedIn');
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
    required String username,
    required String accessToken,
    String? refreshToken,
    String? avatarPath,
    String? avatarBackgroundColor,
  }) async {
    if (kDebugMode) {
      print('🔐 UserManager: Updating user data for $email');
      print('   Previous state - isLoggedIn: $_isLoggedIn, isGuestMode: $_isGuestMode');
    }
    
    // ✅ FIX: Detect if this is a new login (different user) vs token refresh (same user)
    final isNewLogin = _email != email || _email.isEmpty;
    
    _email = email;
    _username = username;
    _accessToken = accessToken;
    _refreshToken = refreshToken ?? '';
    _isLoggedIn = true;
    _userHasAccountHistory = true;
    _showLoginPage = false;
    _isGuestMode = false; // ✅ CRITICAL FIX: Clear guest mode on successful authentication
    _tokenCreatedAt = DateTime.now(); // Record when token was created
    
    // ✅ FIX: Handle avatar data
    if (avatarPath != null && avatarPath.isNotEmpty) {
      // Avatar provided - use it
      _selectedAvatar = avatarPath;
    } else if (isNewLogin) {
      // New login without avatar - clear to default (will be loaded from backend)
      _selectedAvatar = null;
      if (kDebugMode) {
        print('🖼️ UserManager: New login without avatar, clearing to default');
      }
    }
    // If token refresh and no avatar provided, preserve existing avatar
    
    if (avatarBackgroundColor != null && avatarBackgroundColor.isNotEmpty) {
      _avatarBackgroundColor = AvatarHelper.hexToColor(avatarBackgroundColor) ?? 
          AvatarHelper.getDefaultBackgroundColor();
    } else if (isNewLogin) {
      // New login without background color - use default
      _avatarBackgroundColor = AvatarHelper.getDefaultBackgroundColor();
    }
    // If token refresh and no background color provided, preserve existing color
    
    await _saveUserDataToStorage();
    
    // Start proactive token refresh
    _scheduleProactiveTokenRefresh();
    
    // ✅ Validate state after authentication update
    validateState();
    
    notifyListeners();
    
    if (kDebugMode) {
      print('✅ UserManager: Updated user data for $_email');
      print('🔑 Access token: ${_accessToken.isEmpty ? 'empty' : '${_accessToken.substring(0, 20)}...'}');
      print('🎯 New state - isLoggedIn: $_isLoggedIn, isGuestMode: $_isGuestMode, isAuthenticated: $isAuthenticated');
      if (avatarPath != null) {
        print('🖼️ Avatar loaded from backend: $avatarPath');
      }
    }
  }

  /// Update both avatar and background color (syncs to backend)
  Future<void> updateAvatarAndBackground({
    required String avatarPath,
    required Color backgroundColor,
  }) async {
    if (kDebugMode) {
      print('🖼️ UserManager: Updating avatar and background');
    }
    
    // Skip if guest mode
    if (_isGuestMode) {
      if (kDebugMode) {
        print('👤 Guest mode - skipping avatar update');
      }
      return;
    }
    
    try {
      // Sync to backend first
      final backgroundColorHex = AvatarHelper.colorToHex(backgroundColor);
      final success = await ProfileService.shared.updateAvatar(
        avatarPath: avatarPath,
        backgroundColorHex: backgroundColorHex,
      );
      
      if (success) {
        // Update local state only after successful backend sync
        _selectedAvatar = avatarPath;
        _avatarBackgroundColor = backgroundColor;
        notifyListeners();
        
        if (kDebugMode) {
          print('✅ UserManager: Avatar and background synced to backend successfully');
        }
      } else {
        throw Exception('Failed to sync avatar to backend');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ UserManager: Error syncing avatar to backend: $e');
      }
      rethrow;
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
      _username = '';
      _accessToken = '';
      _refreshToken = '';
      _isLoggedIn = false;
      _userHasAccountHistory = false;
      _showLoginPage = false;
      _tokenCreatedAt = null;
      _isGuestMode = false; // ✅ Also clear guest mode on logout
      
      // ✅ FIX: Clear avatar data on logout to prevent showing previous user's avatar
      _selectedAvatar = null;
      _avatarBackgroundColor = AvatarHelper.getDefaultBackgroundColor();
      
      // Clear storage
      await _clearUserDataFromStorage();
      
      // ✅ Validate state after logout
      validateState();
      
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
      await prefs.remove('username');
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

    // ✅ FIX: Check if token is near expiry to prevent infinite loops
    if (_tokenCreatedAt != null) {
      final tokenAge = DateTime.now().difference(_tokenCreatedAt!);
      const tokenLifetime = Duration(hours: 24);
      const refreshBuffer = Duration(minutes: 5);
      final refreshTime = tokenLifetime - refreshBuffer;
      
      // If token is already near expiry, don't reschedule to prevent infinite loops
      if (tokenAge >= refreshTime) {
        if (kDebugMode) {
          print('⚠️ UserManager: Token already near expiry, skipping proactive refresh to prevent loops');
        }
        return;
      }
    }

    try {
      if (kDebugMode) {
        print('🔄 UserManager: Performing proactive token refresh...');
      }

      // ✅ FIX: Don't reschedule immediately - let the API service handle actual refreshes
      // The automatic refresh in API service will handle actual refreshes when needed
      // We'll only reschedule if the token refresh was successful
      
      if (kDebugMode) {
        print('✅ UserManager: Proactive refresh completed, will reschedule on next token update');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ UserManager: Error in proactive token refresh: $e');
      }
      
      // ✅ FIX: Don't reschedule on error to prevent infinite loops
      // Let the API service handle token refresh when needed
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
    _username = '';
    _accessToken = '';
    _refreshToken = '';
    _isLoggedIn = false;
    _userHasAccountHistory = false;
    
    // Don't persist guest mode to SharedPreferences
    // Guest mode is always temporary and memory-only
    
    // ✅ Validate state after entering guest mode
    validateState();
    
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
    
    // ✅ Validate state after exiting guest mode
    validateState();
    
    if (kDebugMode) {
      print('✅ UserManagerService: Guest mode deactivated');
    }
    
    notifyListeners();
  }

  // ✅ NEW: Check if user can access premium features
  bool get canAccessPremiumFeatures => _isLoggedIn && !_isGuestMode;
  
  // ✅ NEW: Check if user should see upgrade prompts  
  bool get shouldShowUpgradePrompts => _isGuestMode;
  
  // ✅ NEW: State validation helpers
  bool get isInValidState {
    // Valid states:
    // 1. Guest mode: isGuestMode=true, isLoggedIn=false, no tokens
    // 2. Authenticated: isGuestMode=false, isLoggedIn=true, has tokens
    // 3. Unauthenticated: isGuestMode=false, isLoggedIn=false, no tokens
    
    if (_isGuestMode) {
      // Guest mode should have no authentication data
      return !_isLoggedIn && _accessToken.isEmpty && _refreshToken.isEmpty;
    } else if (_isLoggedIn) {
      // Authenticated users should have tokens and not be in guest mode
      return _accessToken.isNotEmpty && !_isGuestMode;
    } else {
      // Unauthenticated users should have no tokens and not be in guest mode
      return _accessToken.isEmpty && !_isGuestMode;
    }
  }
  
  void validateState() {
    if (!isInValidState) {
      if (kDebugMode) {
        print('❌ INVALID USER STATE DETECTED!');
        print(debugInfo);
        print('This indicates a bug in state management.');
      }
    }
  }

  @override
  void dispose() {
    _cancelProactiveTokenRefresh();
    super.dispose();
  }

  /// Enhanced debug info with validation
  String get debugInfo {
    return '''
User Manager Debug Info:
- Email: $_email
- Username: $_username
- IsLoggedIn: $_isLoggedIn
- IsGuestMode: $_isGuestMode
- IsAuthenticated: $isAuthenticated
- HasValidToken: $hasValidToken
- CanAccessPremium: $canAccessPremiumFeatures
- ShouldShowUpgrade: $shouldShowUpgradePrompts
- StateIsValid: $isInValidState
- HasAccountHistory: $_userHasAccountHistory
- HasToken: ${_accessToken.isNotEmpty}
- TokenLength: ${_accessToken.length}
- ShowLoginPage: $_showLoginPage
- TokenCreatedAt: $_tokenCreatedAt
- ProactiveRefreshActive: ${_proactiveRefreshTimer != null}
- Is 
''';
  }
}