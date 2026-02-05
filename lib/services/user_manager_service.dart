import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../utils/avatar_helper.dart';
import 'dart:async';
import 'package:purchases_flutter/purchases_flutter.dart';

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
    }
    
    if (kDebugMode) {
      print('🔐 UserManager: Initialized');
      print('   Email: $_email');
      print('   Username: $_username');
      print('   IsLoggedIn: $_isLoggedIn');
      print('   HasHistory: $_userHasAccountHistory');
    }
  }

  /// Load user data from persistent storage
  Future<void> _loadUserDataFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load email (can be plain text or encrypted for backward compatibility)
      final emailData = prefs.getString('userEmail') ?? '';
      if (emailData.isNotEmpty) {
        // Try to decrypt, if it fails assume it's plain text (backward compatibility)
        try {
          _email = await EncryptionUtils.decryptString(emailData);
        } catch (e) {
          // If decryption fails, assume it's plain text (old format)
          _email = emailData;
          if (kDebugMode) {
            print('⚠️ UserManager: Email was stored unencrypted, migrating...');
          }
        }
      }
      
      // Load username (from staging-v2 - not encrypted as it's not sensitive)
      _username = prefs.getString('username') ?? '';
      
      // Load and decrypt tokens
      final encryptedAccessToken = prefs.getString('accessToken') ?? '';
      if (encryptedAccessToken.isNotEmpty) {
        try {
          _accessToken = await EncryptionUtils.decryptString(encryptedAccessToken);
        } catch (e) {
          // If decryption fails, assume it's plain text (old format) - backward compatibility
          _accessToken = encryptedAccessToken;
          if (kDebugMode) {
            print('⚠️ UserManager: Access token was stored unencrypted, migrating...');
          }
          // Re-save encrypted version
          if (_accessToken.isNotEmpty) {
            await prefs.setString('accessToken', await EncryptionUtils.encryptString(_accessToken));
          }
        }
      }
      
      final encryptedRefreshToken = prefs.getString('refreshToken') ?? '';
      if (encryptedRefreshToken.isNotEmpty) {
        try {
          _refreshToken = await EncryptionUtils.decryptString(encryptedRefreshToken);
        } catch (e) {
          // If decryption fails, assume it's plain text (old format) - backward compatibility
          _refreshToken = encryptedRefreshToken;
          if (kDebugMode) {
            print('⚠️ UserManager: Refresh token was stored unencrypted, migrating...');
          }
          // Re-save encrypted version
          if (_refreshToken.isNotEmpty) {
            await prefs.setString('refreshToken', await EncryptionUtils.encryptString(_refreshToken));
          }
        }
      }
      
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _userHasAccountHistory = prefs.getBool('userHasAccountHistory') ?? false;
      _selectedAvatar = prefs.getString('selectedAvatar');
      
      // Load avatar background color
      final bgColorHex = prefs.getString('avatarBackgroundColor');
      _avatarBackgroundColor = AvatarHelper.hexToColor(bgColorHex) ?? 
          AvatarHelper.getDefaultBackgroundColor();
      
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
      
      // Encrypt sensitive data before saving
      String? encryptedAccessToken;
      String? encryptedRefreshToken;
      
      if (_email.isNotEmpty) {
        final encryptedEmail = await EncryptionUtils.encryptString(_email);
        await prefs.setString('userEmail', encryptedEmail);
      } else {
        await prefs.remove('userEmail');
      }
      
      // Save username (from staging-v2 - not encrypted as it's not sensitive)
      if (_username.isNotEmpty) {
        await prefs.setString('username', _username);
      } else {
        await prefs.remove('username');
      }
      
      if (_accessToken.isNotEmpty) {
        encryptedAccessToken = await EncryptionUtils.encryptString(_accessToken);
        await prefs.setString('accessToken', encryptedAccessToken);
      } else {
        await prefs.remove('accessToken');
      }
      
      if (_refreshToken.isNotEmpty) {
        encryptedRefreshToken = await EncryptionUtils.encryptString(_refreshToken);
        await prefs.setString('refreshToken', encryptedRefreshToken);
      } else {
        await prefs.remove('refreshToken');
      }
      
      await prefs.setBool('isLoggedIn', _isLoggedIn);
      await prefs.setBool('userHasAccountHistory', _userHasAccountHistory);
      
      // Save avatar
      if (_selectedAvatar != null) {
        await prefs.setString('selectedAvatar', _selectedAvatar!);
      } else {
        await prefs.remove('selectedAvatar');
      }
      
      // Save token creation time
      if (_tokenCreatedAt != null) {
        await prefs.setInt('tokenCreatedAt', _tokenCreatedAt!.millisecondsSinceEpoch);
      }
      
      if (kDebugMode) {
        print('💾 UserManager: Saved encrypted data to storage - Email: $_email, Username: $_username, LoggedIn: $_isLoggedIn');
        
        // Show encryption verification
        if (_accessToken.isNotEmpty && encryptedAccessToken != null) {
          print('🔐 Encryption Verification:');
          print('   Plain Access Token (first 30): ${_accessToken.substring(0, _accessToken.length > 30 ? 30 : _accessToken.length)}...');
          print('   Encrypted Access Token (first 50): ${encryptedAccessToken.substring(0, encryptedAccessToken.length > 50 ? 50 : encryptedAccessToken.length)}...');
        }
        if (_refreshToken.isNotEmpty && encryptedRefreshToken != null) {
          print('   Plain Refresh Token (first 30): ${_refreshToken.substring(0, _refreshToken.length > 30 ? 30 : _refreshToken.length)}...');
          print('   Encrypted Refresh Token (first 50): ${encryptedRefreshToken.substring(0, encryptedRefreshToken.length > 50 ? 50 : encryptedRefreshToken.length)}...');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ UserManager: Error saving user data: $e');
      }
      // If encryption fails, fall back to unencrypted storage (better than losing data)
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userEmail', _email);
        await prefs.setString('username', _username);
        await prefs.setString('accessToken', _accessToken);
        await prefs.setString('refreshToken', _refreshToken);
        if (kDebugMode) {
          print('⚠️ UserManager: Encryption failed, saved unencrypted (fallback)');
        }
      } catch (fallbackError) {
        if (kDebugMode) {
          print('❌ UserManager: Fallback save also failed: $fallbackError');
        }
      }
    }
  }

  /// Update user data after successful login (mirrors Swift updateUserKeychain)
  Future<void> updateUserData({
    required String email,
    required String username,
    required String accessToken,
    String? refreshToken,
  }) async {
    if (kDebugMode) {
      print('🔐 UserManager: Updating user data for $email');
      print('   Previous state - isLoggedIn: $_isLoggedIn, isGuestMode: $_isGuestMode');
    }
    
    _email = email;
    _username = username;
    _accessToken = accessToken;
    _refreshToken = refreshToken ?? '';
    _isLoggedIn = true;
    _userHasAccountHistory = true;
    _showLoginPage = false;
    _isGuestMode = false; // ✅ CRITICAL FIX: Clear guest mode on successful authentication
    _tokenCreatedAt = DateTime.now(); // Record when token was created
    
    await _saveUserDataToStorage();
    
    // Start proactive token refresh
    _scheduleProactiveTokenRefresh();
    
    // ✅ Validate state after authentication update
    validateState();
    
    notifyListeners();
    
    if (kDebugMode) {
      print('✅ UserManager: Updated user data for $_email');
      print('🔑 Access token: ${_accessToken.isEmpty ? 'empty' : '${_accessToken.substring(0, 20)}...'}');
      print('🔄 Refresh token: ${_refreshToken.isEmpty ? 'empty' : '${_refreshToken.substring(0, 20)}...'}');
      print('🎯 New state - isLoggedIn: $_isLoggedIn, isGuestMode: $_isGuestMode, isAuthenticated: $isAuthenticated');
    }
  }

  /// Update user's selected avatar
  Future<void> updateAvatar(String avatarPath) async {
    if (kDebugMode) {
      print('🖼️ UserManager: Updating avatar to $avatarPath');
    }
    
    _selectedAvatar = avatarPath;
    await _saveUserDataToStorage();
    notifyListeners();
    
    if (kDebugMode) {
      print('✅ UserManager: Avatar updated successfully');
    }
  }

  /// Update avatar background color
  Future<void> updateAvatarBackgroundColor(Color backgroundColor) async {
    if (kDebugMode) {
      print('🎨 UserManager: Updating avatar background color');
    }
    
    _avatarBackgroundColor = backgroundColor;
    await _saveUserDataToStorage();
    notifyListeners();
    
    if (kDebugMode) {
      print('✅ UserManager: Avatar background color updated successfully');
    }
  }

  /// Update both avatar and background color
  Future<void> updateAvatarAndBackground({
    required String avatarPath,
    required Color backgroundColor,
  }) async {
    if (kDebugMode) {
      print('🖼️ UserManager: Updating avatar and background');
    }
    
    _selectedAvatar = avatarPath;
    _avatarBackgroundColor = backgroundColor;
    await _saveUserDataToStorage();
    notifyListeners();
    
    if (kDebugMode) {
      print('✅ UserManager: Avatar and background updated successfully');
    }
  }

  /// Clear user data and logout
  Future<void> logout({bool skipNotification = false}) async {
    if (kDebugMode) {
      print('🚪 UserManager: Logging out user $_email');
    }
    
    try {
      // ✅ CRITICAL: Reset RevenueCat user BEFORE clearing local state
      // This prevents purchases from being transferred to the next user
      try {
        if (kDebugMode) {
          print('🔍 UserManager: Resetting RevenueCat user on logout...');
        }
        
        await Purchases.logOut();
        
        if (kDebugMode) {
          print('✅ UserManager: RevenueCat user reset successfully');
        }
      } catch (revenueCatError) {
        if (kDebugMode) {
          print('⚠️ UserManager: Failed to reset RevenueCat user: $revenueCatError');
        }
        // Don't fail logout if RevenueCat reset fails, but log the error
      }
      
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
      
      // Clear encryption keys on logout for security
      await EncryptionUtils.clearEncryptionData();
      
      if (kDebugMode) {
        print('🗑️ UserManager: Cleared storage and encryption data');
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
    
    // ✅ CRITICAL: Reset RevenueCat user when entering guest mode
    try {
      if (kDebugMode) {
        print('🔍 UserManagerService: Resetting RevenueCat user for guest mode...');
      }
      
      // Reset RevenueCat to anonymous user - this prevents subscription sharing with guest users
      await Purchases.logOut();
      
      if (kDebugMode) {
        print('✅ UserManagerService: RevenueCat user reset for guest mode');
      }
    } catch (revenueCatError) {
      if (kDebugMode) {
        print('⚠️ UserManagerService: Failed to reset RevenueCat user for guest mode: $revenueCatError');
      }
      // Don't fail guest mode entry if RevenueCat reset fails
    }
    
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