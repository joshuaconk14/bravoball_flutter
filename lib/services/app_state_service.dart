import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/drill_model.dart';
import '../models/editable_drill_model.dart';
import '../models/drill_group_model.dart';
import '../models/filter_models.dart';
import '../config/app_config.dart';
import '../services/drill_api_service.dart';
import './test_data_service.dart';
import './guest_drill_service.dart'; // ✅ NEW: Import guest drill service
import 'dart:async';
import '../services/session_data_sync_service.dart';
import '../services/progress_data_sync_service.dart';
import '../services/user_manager_service.dart';
import '../services/drill_group_sync_service.dart';
import '../services/preferences_sync_service.dart';
import './api_service.dart'; // ✅ NEW: Import ApiService for public endpoints

// Add CompletedSession model
class CompletedSession {
  final DateTime date;
  final List<EditableDrillModel> drills;
  final int totalCompletedDrills;
  final int totalDrills;

  CompletedSession({
    required this.date,
    required this.drills,
    required this.totalCompletedDrills,
    required this.totalDrills,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'drills': drills.map((d) => d.toJson()).toList(),
    'totalCompletedDrills': totalCompletedDrills,
    'totalDrills': totalDrills,
  };

  factory CompletedSession.fromJson(Map<String, dynamic> json) => CompletedSession(
    date: DateTime.parse(json['date']),
    drills: (json['drills'] as List).map((d) => EditableDrillModel.fromJson(d)).toList(),
    totalCompletedDrills: json['total_completed_drills'],
    totalDrills: json['total_drills'],
  );
}

class AppStateService extends ChangeNotifier {
  static AppStateService? _instance;
  static AppStateService get instance => _instance ??= AppStateService._();
  
  AppStateService._();
  
  // Services
  final DrillApiService _drillApiService = DrillApiService.shared;
  final GuestDrillService _guestDrillService = GuestDrillService.shared; // ✅ NEW: Guest drill service
  final ApiService _apiService = ApiService.shared; // ✅ NEW: API service for public endpoints
  final ProgressDataSyncService _progressSyncService = ProgressDataSyncService.shared;
  final DrillGroupSyncService _drillGroupSyncService = DrillGroupSyncService.shared;
  final PreferencesSyncService _preferencesSyncService = PreferencesSyncService.shared;
  final UserManagerService _userManager = UserManagerService.instance; // ✅ NEW: User manager reference
  
  // User preferences
  UserPreferences _preferences = UserPreferences();
  UserPreferences get preferences => _preferences;
  
  // Session drills (now using EditableDrillModel for progress tracking)
  final List<EditableDrillModel> _editableSessionDrills = [];
  List<EditableDrillModel> get editableSessionDrills => List.unmodifiable(_editableSessionDrills);
  
  // Session drills (legacy - for backward compatibility)
  final List<DrillModel> _sessionDrills = [];
  List<DrillModel> get sessionDrills => List.unmodifiable(_sessionDrills);
  
  // Session progress state
  bool _sessionInProgress = false;
  bool get sessionInProgress => _sessionInProgress;
  
  // ✅ NEW: Track if current session has been completed to prevent duplicates
  bool _currentSessionCompleted = false;
  bool get currentSessionCompleted => _currentSessionCompleted;
  
  // Saved drill groups
  final List<DrillGroup> _savedDrillGroups = [];
  List<DrillGroup> get savedDrillGroups => List.unmodifiable(_savedDrillGroups);
  
  // Liked drills (special group)
  final Set<DrillModel> _likedDrills = {};
  Set<DrillModel> get likedDrills => Set.unmodifiable(_likedDrills);
  
  // ✅ NEW: Guest mode drill storage
  List<DrillModel> _guestDrills = [];
  bool _guestDrillsLoaded = false;
  
  // ✅ NEW: Guest mode detection
  bool get isGuestMode => _userManager.isGuestMode;
  bool get isAuthenticated => _userManager.isAuthenticated;
  
  // All available drills - now supports guest mode
  List<DrillModel> get _availableDrills {
    // ✅ NEW: Handle guest mode
    if (isGuestMode) {
      if (kDebugMode) print('👤 Using guest drills data (limited set)');
      return _guestDrills;
    }
    
    if (AppConfig.useTestData) {
      if (kDebugMode) print('🔧 Using test drills data (AppConfig.useTestData = true)');
      return TestDataService.getTestDrills();
    } else {
      if (kDebugMode) print('🌐 Using backend drills data (no caching)');
      // Return empty list - drills should be loaded from backend when needed
      return [];
    }
  }
  List<DrillModel> get availableDrills => List.unmodifiable(_availableDrills);
  
  // Pagination state for search
  int _currentSearchPage = 1;
  int _totalSearchPages = 1;
  int _totalSearchResults = 0;
  bool _hasMoreSearchResults = false;
  String? _lastSearchQuery;
  String? _lastSearchSkill;
  String? _lastSearchDifficulty;
  
  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  // ✅ NEW: Loading state for session completion
  bool _isCompletingSession = false;
  bool get isCompletingSession => _isCompletingSession;
  
  // ✅ NEW: Flag to prevent unnecessary notifyListeners after session completion
  bool _sessionCompletionFinished = false;

  // ✅ NEW: Loading state for preference updates
  bool _isLoadingPreferences = false;
  bool get isLoadingPreferences => _isLoadingPreferences;
  
  // Search results
  List<DrillModel> _searchResults = [];
  List<DrillModel> get searchResults => List.unmodifiable(_searchResults);
  
  // Error state
  String? _lastError;
  String? get lastError => _lastError;
  
  // Auto-generation settings
  bool _autoGenerateSession = true;
  bool get autoGenerateSession => _autoGenerateSession;
  
  // Completed sessions
  final List<CompletedSession> _completedSessions = [];
  List<CompletedSession> get completedSessions {
    return List.unmodifiable(_completedSessions);
  }

  /// Check if there are any sessions completed today
  bool get hasSessionsCompletedToday {
    final today = DateTime.now();
    return _completedSessions.any((session) => 
      session.date.year == today.year &&
      session.date.month == today.month &&
      session.date.day == today.day
    );
  }

  /// Get the number of sessions completed today
  int get sessionsCompletedToday {
    final today = DateTime.now();
    return _completedSessions.where((session) => 
      session.date.year == today.year &&
      session.date.month == today.month &&
      session.date.day == today.day
    ).length;
  }

  // Progress tracking (mirrors Swift MainAppModel)
  int _currentStreak = 0;
  int get currentStreak => _currentStreak;
  
  int _previousStreak = 0;
  int get previousStreak => _previousStreak;
  
  int _highestStreak = 0;
  int get highestStreak => _highestStreak;
  
  int _countOfFullyCompletedSessions = 0;
  int get countOfFullyCompletedSessions => _countOfFullyCompletedSessions;

  // Initial load flags (mirrors Swift pattern)
  bool _isInitialLoad = true;
  bool get isInitialLoad => _isInitialLoad;
  
  bool _isLoggingOut = false;
  bool get isLoggingOut => _isLoggingOut;

  // Sync timers for reactive syncing
  Timer? _sessionDrillsSyncTimer;
  Timer? _completedSessionSyncTimer;
  Timer? _drillGroupsSyncTimer;
  Timer? _preferencesSyncTimer;
  static const Duration _sessionDrillsSyncDebounce = Duration(milliseconds: 500);
  static const Duration _progressSyncDebounce = Duration(milliseconds: 1000);
  static const Duration _drillGroupsSyncDebounce = Duration(milliseconds: 1000);
  static const Duration _preferencesSyncDebounce = Duration(milliseconds: 1000);

  // ✅ NEW: Add debouncing for search requests
  Timer? _searchDebounceTimer;
  static const Duration _searchDebounceDelay = Duration(milliseconds: 300);

  // ✅ NEW: Track current search request to prevent overlapping
  bool _isSearching = false;

  void addCompletedSession(CompletedSession session) {
    _completedSessions.add(session);
    
    // All progress tracking (including completed sessions count) is now handled by backend
    // No need to calculate locally anymore
    
    if (kDebugMode) {
      print('✅ CompletedSession saved!');
      print('  Date: ${session.date}');
      print('  Drills: ${session.drills.length}');
      print('  Total Completed: ${session.totalCompletedDrills}');
      print('  Total Drills: ${session.totalDrills}');
      print('  Previous Streak: $_previousStreak (from backend)');
      print('  Current Streak: $_currentStreak (from backend)');
      print('  Highest Streak: $_highestStreak (from backend)');
      print('  Completed Sessions: $_countOfFullyCompletedSessions (from backend)');
    }
    
    // ✅ FIXED: Immediate sync instead of timer-based
    _syncCompletedSessionImmediate(session);
    
    notifyListeners();
  }

  // ✅ NEW: Immediate sync method (replaces timer-based approach)
  Future<void> _syncCompletedSessionImmediate(CompletedSession session) async {
    try {
      if (kDebugMode) {
        print('🔄 Starting immediate session sync to backend...');
      }
      
      // Sync completed session to backend
      final syncSuccess = await _progressSyncService.syncCompletedSession(
        date: session.date,
        drills: session.drills,
        totalCompleted: session.totalCompletedDrills,
        total: session.totalDrills,
      );
      
      if (syncSuccess) {
        if (kDebugMode) {
          print('✅ Session sync successful, now refreshing progress history...');
        }
        
        // Refresh progress history from backend after session sync
        await refreshProgressHistoryFromBackend();
        
        // ✅ FINAL UI UPDATE: Mark completion as finished to prevent further updates
        _sessionCompletionFinished = true;
        notifyListeners();
        
        if (kDebugMode) {
          print('✅ Progress history refreshed, session completion flow complete');
          print('   - Updated Current Streak: $_currentStreak');
          print('   - Updated Highest Streak: $_highestStreak');
          print('   - Updated Sessions Count: $_countOfFullyCompletedSessions');
          print('🔒 Session completion finished - preventing further UI updates');
        }
      } else {
        if (kDebugMode) {
          print('❌ Session sync failed');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in immediate session sync: $e');
      }
    }
  }

  // Schedule completed session sync
  void _scheduleCompletedSessionSync(CompletedSession session) {
    _completedSessionSyncTimer?.cancel();
    _completedSessionSyncTimer = Timer(_progressSyncDebounce, () async {
      await _progressSyncService.syncCompletedSession(
        date: session.date,
        drills: session.drills,
        totalCompleted: session.totalCompletedDrills,
        total: session.totalDrills,
      );
    });
  }
  
  // Initialize the service
  Future<void> initialize() async {
    if (kDebugMode) {
      print('🚀 Initializing AppStateService...');
      print('   Environment: ${AppConfig.environmentName}');
      print('   Base URL: ${AppConfig.baseUrl}');
      print('   Use Test Data: ${AppConfig.useTestData}');
      print('   Is Guest Mode: ${isGuestMode}');
    }

    await _loadPersistedState();
    
    // Set initial load flags
    _isInitialLoad = true;
    _isLoggingOut = false;
    
    // ✅ NEW: Handle guest mode initialization
    if (isGuestMode) {
      if (kDebugMode) {
        print('👤 Initializing for guest mode...');
      }
      await _loadGuestDrills();
      if (_guestDrills.isNotEmpty) {
        await _loadTestSessionForGuest();
      }
    } else {
    // Load test session if in debug mode and no session exists
    if (AppConfig.useTestData && _editableSessionDrills.isEmpty) {
      await _loadTestSession();
      }
    }
    
    // No longer pre-caching drills - they'll be loaded from backend when needed
    
    notifyListeners();
  }

  // ✅ NEW: Load guest drills from public API
  Future<void> _loadGuestDrills() async {
    if (!isGuestMode) return;
    
    if (kDebugMode) {
      print('📥 Loading guest drills...');
    }
    
    _setLoading(true);
    
    try {
      final guestDrills = await _guestDrillService.fetchGuestDrills();
      _guestDrills = guestDrills;
      _guestDrillsLoaded = true;
      
      if (kDebugMode) {
        print('✅ Loaded ${_guestDrills.length} guest drills');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading guest drills: $e');
      }
      _setError('Failed to load guest drills: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ✅ NEW: Load a sample session for guest users
  Future<void> _loadTestSessionForGuest() async {
    if (!isGuestMode || _guestDrills.isEmpty) return;
    
    if (kDebugMode) {
      print('📚 Loading sample session for guest with ${_guestDrills.length} available drills');
    }
    
    try {
      // Create a sample session with a few drills from different categories
      final sampleDrills = <DrillModel>[];
      
      // Get one drill from each main category if available
      final categories = ['Passing', 'Dribbling', 'Shooting', 'First Touch'];
      for (final category in categories) {
        final categoryDrill = _guestDrills.where((drill) => drill.skill == category).firstOrNull;
        if (categoryDrill != null && sampleDrills.length < 3) {
          sampleDrills.add(categoryDrill);
        }
      }
      
      // If we don't have 3 drills yet, add any remaining ones
      if (sampleDrills.length < 3) {
        for (final drill in _guestDrills) {
          if (!sampleDrills.contains(drill) && sampleDrills.length < 3) {
            sampleDrills.add(drill);
          }
        }
      }
      
      // Convert to editable drills
      final editableDrills = sampleDrills.map((drill) => EditableDrillModel(
        drill: drill,
        setsDone: 0,
        totalSets: drill.sets > 0 ? drill.sets : 3,
        totalReps: drill.reps > 0 ? drill.reps : 10,
        totalDuration: drill.duration > 0 ? drill.duration : 10,
        isCompleted: false,
      )).toList();
      
      // Set session drills
      _editableSessionDrills.clear();
      _sessionDrills.clear();
      _editableSessionDrills.addAll(editableDrills);
      _sessionDrills.addAll(sampleDrills);
      
      if (kDebugMode) {
        print('✅ Guest sample session loaded with ${sampleDrills.length} drills');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading guest sample session: $e');
      }
    }
  }

  /// Load all backend data (progress history and ordered session drills)
  /// Mirrors Swift loadBackendData() function
  Future<void> loadBackendData() async {
    if (kDebugMode) {
      print('\n🚀 ===== STARTING loadBackendData() =====');
      print('📅 Timestamp: ${DateTime.now()}');
    }
    
    // Check if user has account history (mirrors Swift pattern)
    final userManager = UserManagerService.instance;
    print('👤 [LOAD] Checking user account history...');
    print('   - User email: ${userManager.email}');
    print('   - Has account history: ${userManager.userHasAccountHistory}');
    print('   - Is logged in: ${userManager.isLoggedIn}');
    
    if (!userManager.userHasAccountHistory) {
      if (kDebugMode) {
        print('⚠️ No user account history, skipping backend data load');
      }
      _isInitialLoad = false;
      notifyListeners();
      return;
    }
    
    if (kDebugMode) {
      print('✅ User has account history, loading backend data');
    }
    
    // Set initial load flags
    _isInitialLoad = true;
    _isLoggingOut = false;
    notifyListeners();
    
    try {
      if (kDebugMode) {
        print('📥 Loading backend data...');
      }
      
      print('🔄 [LOAD] Starting progress data loading...');
      // Load progress data (completed sessions and progress history)
      await _loadProgressDataFromBackend();
      print('✅ [LOAD] Progress data loading completed');
      
      print('🔄 [LOAD] Starting ordered session drills loading...');
      // Load ordered session drills
      await _loadOrderedSessionDrillsFromBackend();
      print('✅ [LOAD] Ordered session drills loading completed');
      
      print('🔄 [LOAD] Starting drill groups loading...');
      // Load drill groups
      await _loadDrillGroupsFromBackend();
      print('✅ [LOAD] Drill groups loading completed');
      
      print('🔄 [LOAD] Starting preferences loading...');
      // Load user preferences
      await _loadPreferencesFromBackend();
      print('✅ [LOAD] Preferences loading completed');
      
      if (kDebugMode) {
        print('✅ Successfully loaded all backend data');
        print('📊 Final data summary:');
        print('   - Ordered drills: ${_editableSessionDrills.length}');
        print('   - Completed sessions: ${_completedSessions.length}');
        print('   - Saved drill groups: ${_savedDrillGroups.length}');
        print('   - Liked drills: ${_likedDrills.length}');
        print('   - Previous streak: $_previousStreak');
        print('   - Current streak: $_currentStreak');
        print('   - Highest streak: $_highestStreak');
        print('   - Completed sessions count: $_countOfFullyCompletedSessions}');
        print('   - User preferences loaded: ${_preferences.selectedSkills.isNotEmpty || _preferences.selectedEquipment.isNotEmpty}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading backend data: $e');
        print('Error type: ${e.runtimeType}');
        print('Error description: $e');
      }
    } finally {
      // Set initial load to false after data loading is complete
      _isInitialLoad = false;
      notifyListeners();
      
      if (kDebugMode) {
        print('✅ Set isInitialLoad = false');
        print('🎉 ===== loadBackendData() COMPLETED =====');
      }
    }
  }

  /// Manually refresh backend data (can be called from UI)
  Future<void> refreshBackendData() async {
    if (AppConfig.useTestData) {
      if (kDebugMode) {
        print('ℹ️ Skipping backend refresh - using test data');
      }
      return;
    }
    
    _setLoading(true);
    await loadBackendData();
    _setLoading(false);
    notifyListeners();
  }

  /// Refresh progress history from backend (includes streaks and completed sessions count)
  Future<void> refreshProgressHistoryFromBackend() async {
    if (AppConfig.useTestData) {
      if (kDebugMode) {
        print('ℹ️ Skipping progress history refresh - using test data');
      }
      return;
    }
    
    try {
      if (kDebugMode) {
        print('🔄 Refreshing progress history from backend...');
      }
      
      final progressHistory = await _progressSyncService.updateProgressHistory();
      if (progressHistory != null) {
        _currentStreak = progressHistory['currentStreak'] ?? 0;
        _previousStreak = progressHistory['previousStreak'] ?? 0;
        _highestStreak = progressHistory['highestStreak'] ?? 0;
        _countOfFullyCompletedSessions = progressHistory['completedSessionsCount'] ?? 0;
        
        if (kDebugMode) {
          print('✅ Progress history refreshed from backend:');
          print('   - Current Streak: $_currentStreak');
          print('   - Previous Streak: $_previousStreak');
          print('   - Highest Streak: $_highestStreak');
          print('   - Completed Sessions Count: $_countOfFullyCompletedSessions');
        }
        
        // ✅ MINIMAL FIX: Only notify listeners if not called during session completion

        // ✅ FIXED: Always notify listeners for progress updates - this fixes logout UI issues
        notifyListeners();
        if (kDebugMode) {
          print('🔔 Called notifyListeners() for progress update');
        }
      } else {
        if (kDebugMode) {
          print('⚠️ No progress history data returned from backend');
        }
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error refreshing progress history: $e');
      }
    }
  }

  /// Clear user data (mirrors Swift clearUserData)
  void clearUserData() {
    if (kDebugMode) {
      print('🧹 Clearing user data...');
    }
    
    _editableSessionDrills.clear();
    _sessionDrills.clear();
    _completedSessions.clear();
    _currentStreak = 0;
    _previousStreak = 0;
    _highestStreak = 0;
    _countOfFullyCompletedSessions = 0;
    _savedDrillGroups.clear();
    _likedDrills.clear();
    
    // ✅ FORCE RESET: Clear all session completion state
    _forceResetSessionCompletionState();
    
    // ✅ FIXED: Cancel ALL sync timers to prevent memory leaks
    _cancelAllTimers();
    
    if (kDebugMode) {
      print('✅ User data cleared');
    }
  }

  /// ✅ NEW: Force reset all session completion state and flags
  void _forceResetSessionCompletionState() {
    _sessionInProgress = false;
    // _currentSessionCompleted = false; // ✅ FIXED: Commented out to prevent duplicate session completion when logging back in
    _sessionCompletionFinished = false;
    _isCompletingSession = false;
    _isLoadingPreferences = false;
    _isLoading = false;
    _isLoadingMore = false;
    
    if (kDebugMode) {
      print('🔄 Force reset all session completion state');
    }
    
    // ✅ ENSURE UI UPDATE: Force immediate UI update after state reset
    notifyListeners();
  }

  /// ✅ NEW: Cancel all timers to prevent memory leaks
  void _cancelAllTimers() {
    _sessionDrillsSyncTimer?.cancel();
    _sessionDrillsSyncTimer = null;
    
    _completedSessionSyncTimer?.cancel();
    _completedSessionSyncTimer = null;
    
    _drillGroupsSyncTimer?.cancel();
    _drillGroupsSyncTimer = null;
    
    _preferencesSyncTimer?.cancel();
    _preferencesSyncTimer = null;
    
    // ✅ NEW: Cancel search debounce timer
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = null;
    
    if (kDebugMode) {
      print('🗑️ All sync timers cancelled');
    }
  }

  /// ✅ NEW: Dispose method to clean up resources
  void dispose() {
    _cancelAllTimers();
    // Don't call super.dispose() as this is not a ChangeNotifier subclass in typical sense
  }

  /// Set initial load state (public method)
  void setInitialLoadState(bool isInitialLoad) {
    _isInitialLoad = isInitialLoad;
    notifyListeners();
  }

  // Load progress data from backend
  Future<void> _loadProgressDataFromBackend() async {
    try {
      if (kDebugMode) {
        print('📥 Loading progress data from backend...');
      }
      
      // Load completed sessions
      print('🔄 [PROGRESS] Starting to fetch completed sessions from backend...');
      final completedSessions = await _progressSyncService.fetchCompletedSessions();
      print('📊 [PROGRESS] Backend returned ${completedSessions.length} completed sessions');
      
      _completedSessions.clear();
      _completedSessions.addAll(completedSessions);
      print('✅ [PROGRESS] Updated local completedSessions list: ${_completedSessions.length} sessions');
      
      // Load progress history (streaks calculated by backend)
      print('🔄 [PROGRESS] Starting to fetch progress history from backend...');
      final progressHistory = await _progressSyncService.updateProgressHistory();
      if (progressHistory != null) {
        // All streak data comes from backend calculation
        _currentStreak = progressHistory['currentStreak'] ?? 0;
        _previousStreak = progressHistory['previousStreak'] ?? 0;
        _highestStreak = progressHistory['highestStreak'] ?? 0;
        _countOfFullyCompletedSessions = progressHistory['completedSessionsCount'] ?? 0;
        
        print('📊 [PROGRESS] Progress history loaded from backend:');
        print('   - Current Streak: $_currentStreak');
        print('   - Previous Streak: $_previousStreak');
        print('   - Highest Streak: $_highestStreak');
        print('   - Completed Sessions Count: $_countOfFullyCompletedSessions');
      } else {
        print('⚠️ [PROGRESS] No progress history returned from backend');
        // Reset streak data if backend doesn't return any
        _currentStreak = 0;
        _previousStreak = 0;
        _highestStreak = 0;
        _countOfFullyCompletedSessions = 0;
      }
      
      if (kDebugMode) {
        print('✅ Loaded progress data from backend:');
        print('   Completed Sessions: ${_completedSessions.length}');
        print('   Previous Streak: $_previousStreak');
        print('   Current Streak: $_currentStreak');
        print('   Highest Streak: $_highestStreak');
        print('   Completed Sessions Count: $_countOfFullyCompletedSessions');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading progress data from backend: $e');
        print('Error type: ${e.runtimeType}');
        print('Error description: $e');
      }
      // Reset streak data on error
      _currentStreak = 0;
      _previousStreak = 0;
      _highestStreak = 0;
      _countOfFullyCompletedSessions = 0;
    }
  }

  // Load ordered session drills from backend
  Future<void> _loadOrderedSessionDrillsFromBackend() async {
    try {
      if (kDebugMode) {
        print('📥 Loading ordered session drills from backend...');
      }
      
      final orderedDrills = await SessionDataSyncService.shared.fetchOrderedSessionDrills();
      
      if (orderedDrills.isNotEmpty) {
        _editableSessionDrills.clear();
        _sessionDrills.clear();
        
        _editableSessionDrills.addAll(orderedDrills);
        _sessionDrills.addAll(orderedDrills.map((ed) => ed.drill));
        
        if (kDebugMode) {
          print('✅ Loaded ${orderedDrills.length} ordered session drills from backend');
        }
      } else {
        if (kDebugMode) {
          print('ℹ️ No ordered session drills found in backend');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading ordered session drills from backend: $e');
      }
    }
  }

  // Load drill groups from backend
  Future<void> _loadDrillGroupsFromBackend() async {
    try {
      if (kDebugMode) {
        print('📥 Loading drill groups from backend...');
      }
      
      // Get all drill groups from backend
      final backendGroups = await _drillGroupSyncService.getAllDrillGroups();
      
      if (backendGroups.isNotEmpty) {
        // Convert backend responses to local models
        final localGroups = _drillGroupSyncService.convertToLocalModels(backendGroups);
        
        // Clear existing groups and add backend groups
        _savedDrillGroups.clear();
        _likedDrills.clear();
        
        for (final group in localGroups) {
          if (group.isLikedDrillsGroup) {
            // Add drills to liked drills set
            _likedDrills.addAll(group.drills);
          } else {
            // Add to saved drill groups
            _savedDrillGroups.add(group);
          }
        }
        
        if (kDebugMode) {
          print('✅ Loaded ${localGroups.length} drill groups from backend');
          print('   - Saved groups: ${_savedDrillGroups.length}');
          print('   - Liked drills: ${_likedDrills.length}');
        }
      } else {
        if (kDebugMode) {
          print('ℹ️ No drill groups found in backend');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading drill groups from backend: $e');
      }
    }
  }

  // Load preferences from backend
  Future<void> _loadPreferencesFromBackend() async {
    try {
      if (kDebugMode) {
        print('📥 Loading preferences from backend...');
      }
      
      await _preferencesSyncService.loadPreferencesFromBackend();
      
      if (kDebugMode) {
        print('✅ Loaded preferences from backend');
        print('   - Time: ${_preferences.selectedTime}');
        print('   - Equipment: ${_preferences.selectedEquipment}');
        print('   - Training Style: ${_preferences.selectedTrainingStyle}');
        print('   - Location: ${_preferences.selectedLocation}');
        print('   - Difficulty: ${_preferences.selectedDifficulty}');
        print('   - Skills: ${_preferences.selectedSkills}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading preferences from backend: $e');
      }
    }
  }
  
  // MARK: - Enhanced API-like Methods
  
  /// Search drills with pagination and loading states
  Future<void> searchDrillsWithPagination({
    String? query,
    String? skill,
    String? difficulty,
    String? trainingStyle,
    List<String>? equipment,
    int? maxDuration,
    bool loadMore = false,
  }) async {
    
    // ✅ FIXED: Prevent overlapping search requests
    if (_isSearching && !loadMore) {
      if (kDebugMode) {
        print('🔄 Search already in progress, ignoring new request');
      }
      return;
    }
    
    // Don't allow multiple concurrent searches
    if (_isLoading && !loadMore) return;
    if (_isLoadingMore && loadMore) return;
    
    // ✅ NEW: Cancel previous debounce timer if new search comes in
    if (!loadMore) {
      _searchDebounceTimer?.cancel();
    }
    
    // ✅ NEW: Use debouncing for new searches (but not for load more)
    if (!loadMore) {
      _searchDebounceTimer = Timer(_searchDebounceDelay, () {
        _performSearch(
          query: query,
          skill: skill,
          difficulty: difficulty,
          trainingStyle: trainingStyle,
          equipment: equipment,
          maxDuration: maxDuration,
          loadMore: loadMore,
        );
      });
      return;
    } else {
      // Load more requests are immediate
      await _performSearch(
        query: query,
        skill: skill,
        difficulty: difficulty,
        trainingStyle: trainingStyle,
        equipment: equipment,
        maxDuration: maxDuration,
        loadMore: loadMore,
      );
    }
  }

  /// ✅ NEW: Perform the actual search with proper pagination
  Future<void> _performSearch({
    String? query,
    String? skill,
    String? difficulty,
    String? trainingStyle,
    List<String>? equipment,
    int? maxDuration,
    bool loadMore = false,
  }) async {
    
    // ✅ FIXED: Set search in progress flag
    _isSearching = true;
    
    // Reset pagination for new search
    if (!loadMore) {
      _currentSearchPage = 1;
      _searchResults.clear();
      _lastSearchQuery = query;
      _lastSearchSkill = skill;
      _lastSearchDifficulty = difficulty;
    } else {
      // Check if we can load more
      if (!_hasMoreSearchResults) {
        _isSearching = false;
        return;
      }
      _currentSearchPage++;
    }
    
    loadMore ? _setLoadingMore(true) : _setLoading(true);
    _clearError();
    
    try {
      // ✅ FIXED: Handle guest mode with proper pagination
      if (isGuestMode) {
        // ✅ FIXED: For guest mode, use proper pagination instead of always getting all drills
        final pageSize = 10; // Smaller page size for guests
        final guestDrills = await _guestDrillService.searchGuestDrills(
          query: query ?? _lastSearchQuery,
          category: skill ?? _lastSearchSkill,
          difficulty: difficulty ?? _lastSearchDifficulty,
          page: _currentSearchPage,
          limit: pageSize,
        );
        
        // ✅ FIXED: Handle pagination properly for guests
        if (loadMore) {
          _searchResults.addAll(guestDrills);
        } else {
          _searchResults = guestDrills;
        }
        
        // ✅ FIXED: Calculate pagination for guests
        // For simplicity, assume we have more results if we got a full page
        _hasMoreSearchResults = guestDrills.length == pageSize;
        _totalSearchResults = _searchResults.length + (_hasMoreSearchResults ? 1 : 0);
        _totalSearchPages = (_totalSearchResults / pageSize).ceil();
        
        if (kDebugMode) {
          print('👤 Guest search completed: ${guestDrills.length} drills on page $_currentSearchPage');
          print('  - Total results so far: ${_searchResults.length}');
          print('  - Has more: $_hasMoreSearchResults');
        }
      } else if (AppConfig.useTestData) {
        // Use test data service
        final filters = DrillSearchFilters(
          query: query ?? _lastSearchQuery,
          skill: skill ?? _lastSearchSkill,
          difficulty: difficulty ?? _lastSearchDifficulty,
          trainingStyle: trainingStyle,
          equipment: equipment,
          maxDuration: maxDuration,
          page: _currentSearchPage,
          pageSize: 15,
        );
        
        final response = await TestDataService.searchDrills(filters);
        
        if (loadMore) {
          _searchResults.addAll(response.drills);
        } else {
          _searchResults = response.drills;
        }
        
        _totalSearchPages = response.totalPages;
        _totalSearchResults = response.totalCount;
        _hasMoreSearchResults = response.hasNextPage;
        
        if (kDebugMode) {
          print('📚 Test search completed: ${response.drills.length} drills on page ${response.currentPage}/${response.totalPages}');
        }
      } else {
        // Use real backend API
        final response = await _drillApiService.searchDrills(
          query: query ?? _lastSearchQuery ?? '',
          category: skill ?? _lastSearchSkill,
          difficulty: difficulty ?? _lastSearchDifficulty,
          page: _currentSearchPage,
          limit: 15,
        );
        
        final newDrills = _drillApiService.convertToLocalModels(response.items);
        
        if (loadMore) {
          _searchResults.addAll(newDrills);
        } else {
          _searchResults = newDrills;
        }
        
        _totalSearchPages = response.totalPages;
        _totalSearchResults = response.total;
        _hasMoreSearchResults = response.hasNextPage;
        
        if (kDebugMode) {
          print('🌐 Backend search completed: ${newDrills.length} drills on page ${response.page}/${response.totalPages}');
        }
      }
      
    } catch (e) {
      _setError('Search failed: $e');
      if (kDebugMode) print('❌ Search error: $e');
    } finally {
      loadMore ? _setLoadingMore(false) : _setLoading(false);
      _isSearching = false; // ✅ FIXED: Reset search in progress flag
    }
    
    notifyListeners();
  }
  
  /// Get drills by skill with loading state
  Future<List<DrillModel>> getDrillsBySkillAsync(String skill) async {
    _setLoading(true);
    _clearError();
    
    try {
      // ✅ NEW: Handle guest mode
      if (isGuestMode) {
        final guestDrills = await _guestDrillService.searchGuestDrills(
          category: skill,
          limit: 10, // Limited for guests
        );
        if (kDebugMode) print('👤 Loaded ${guestDrills.length} guest drills for skill: $skill (limited)');
        return guestDrills;
      } else if (AppConfig.useTestData) {
        final drills = await TestDataService.getDrillsBySkill(skill);
        if (kDebugMode) print('📚 Loaded ${drills.length} test drills for skill: $skill');
        return drills;
      } else {
        final response = await _drillApiService.getDrillsByCategory(skill);
        final drills = _drillApiService.convertToLocalModels(response);
        if (kDebugMode) print('🌐 Loaded ${drills.length} backend drills for skill: $skill');
        return drills;
      }
    } catch (e) {
      _setError('Failed to load $skill drills: $e');
      return [];
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }
  
  /// Get popular drills with loading state
  Future<List<DrillModel>> getPopularDrillsAsync() async {
    _setLoading(true);
    _clearError();
    
    try {
      // ✅ NEW: Handle guest mode
      if (isGuestMode) {
        // For guests, return a sample of their limited drills as "popular"
        final popularGuestDrills = _guestDrills.take(8).toList();
        if (kDebugMode) print('👤 Loaded ${popularGuestDrills.length} popular guest drills (limited)');
        return popularGuestDrills;
      } else if (AppConfig.useTestData) {
        final drills = await TestDataService.getPopularDrills();
        if (kDebugMode) print('📚 Loaded ${drills.length} popular test drills');
        return drills;
      } else {
        // For backend, just get the first 10 drills as "popular"
        final response = await _drillApiService.searchDrills(limit: 10);
        final drills = _drillApiService.convertToLocalModels(response.items);
        if (kDebugMode) print('🌐 Loaded ${drills.length} popular backend drills');
        return drills;
      }
    } catch (e) {
      _setError('Failed to load popular drills: $e');
      return [];
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }
  
  /// Get drill recommendations with loading state
  Future<List<DrillModel>> getRecommendedDrillsAsync(int count) async {
    _setLoading(true);
    _clearError();
    
    try {
      if (AppConfig.useTestData) {
        final drills = await TestDataService.getRecommendedDrills(count);
        if (kDebugMode) print('📚 Loaded $count recommended test drills');
        return drills;
      } else {
        // For backend, get random drills as recommendations
        final response = await _drillApiService.searchDrills(limit: count);
        final drills = _drillApiService.convertToLocalModels(response.items);
        if (kDebugMode) print('🌐 Loaded ${drills.length} recommended backend drills');
        return drills;
      }
    } catch (e) {
      _setError('Failed to load recommendations: $e');
      return [];
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }
  
  /// Load more search results
  Future<void> loadMoreSearchResults() async {
    await searchDrillsWithPagination(loadMore: true);
  }
  
  /// Refresh current search
  Future<void> refreshSearch() async {
    await searchDrillsWithPagination(
      query: _lastSearchQuery,
      skill: _lastSearchSkill,
      difficulty: _lastSearchDifficulty,
    );
  }
  
  // MARK: - Loading State Management
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _clearError();
  }
  
  void _setLoadingMore(bool loading) {
    _isLoadingMore = loading;
    if (loading) _clearError();
  }

  // ✅ NEW: Set session completion loading state
  void _setCompletingSession(bool completing) {
    _isCompletingSession = completing;
    notifyListeners();
  }

  // ✅ NEW: Set preference loading state
  void _setLoadingPreferences(bool loading) {
    _isLoadingPreferences = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _lastError = error;
    if (kDebugMode) print('❌ AppState Error: $error');
  }
  
  void _clearError() {
    _lastError = null;
  }
  
  // MARK: - Pagination Getters
  
  int get currentSearchPage => _currentSearchPage;
  int get totalSearchPages => _totalSearchPages;
  int get totalSearchResults => _totalSearchResults;
  bool get hasMoreSearchResults => _hasMoreSearchResults;
  bool get hasSearchResults => _searchResults.isNotEmpty;
  
  // MARK: - Debug Methods
  
  /// Load test session data for debugging
  Future<void> _loadTestSession() async {
    if (!AppConfig.useTestData) return;
    
    if (kDebugMode) print('📚 Loading test session with ${AppConfig.testDrillCount} drills');
    
    _setLoading(true);
    
    try {
      // Simulate loading delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      final testSessionDrills = TestDataService.getTestSessionDrills();
      _editableSessionDrills.clear();
      _sessionDrills.clear();
      
      _editableSessionDrills.addAll(testSessionDrills);
      _sessionDrills.addAll(testSessionDrills.map((ed) => ed.drill));
      
      if (kDebugMode) print('✅ Test session loaded successfully');
      
    } catch (e) {
      _setError('Failed to load test session: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Load test session (can be called from debug menu)
  Future<void> loadTestSession() async {
    await _loadTestSession();
    notifyListeners();
  }
  
  /// Clear all session data (useful for testing)
  void clearAllSessionData() {
    if (kDebugMode) print('🧹 Clearing all session data');
    clearSession();
    // Reset any progress tracking
    _sessionInProgress = false;
    _currentSessionCompleted = false; // ✅ Reset completion flag
    notifyListeners();
  }
  
  // MARK: - Saved Drill Groups Management
  
  void createDrillGroup(String name, String description) {
    final newGroup = DrillGroup(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      drills: [],
      createdAt: DateTime.now(),
    );
    
    _savedDrillGroups.add(newGroup);
    notifyListeners();
    
    // Sync to backend
    _scheduleDrillGroupsSync();
  }
  
  void deleteDrillGroup(String groupId) {
    // Find the group to get its backend ID
    final groupIndex = _savedDrillGroups.indexWhere((group) => group.id == groupId);
    if (groupIndex != -1) {
      final group = _savedDrillGroups[groupIndex];
      // Try to delete from backend if it has a numeric ID
      final backendId = int.tryParse(group.id);
      if (backendId != null && backendId > 0) {
        _drillGroupSyncService.deleteDrillGroup(backendId);
      }
    }
    
    _savedDrillGroups.removeWhere((group) => group.id == groupId);
    notifyListeners();
  }
  
  void editDrillGroup(String groupId, String newName, String newDescription) {
    final groupIndex = _savedDrillGroups.indexWhere((group) => group.id == groupId);
    if (groupIndex != -1) {
      final group = _savedDrillGroups[groupIndex];
      final updatedGroup = group.copyWith(
        name: newName,
        description: newDescription,
      );
      _savedDrillGroups[groupIndex] = updatedGroup;
      notifyListeners();
      
      // Sync to backend
      _scheduleDrillGroupsSync();
    }
  }
  
  void addDrillToGroup(String groupId, DrillModel drill) {
    final groupIndex = _savedDrillGroups.indexWhere((g) => g.id == groupId);
    if (groupIndex != -1) {
      final group = _savedDrillGroups[groupIndex];
      if (!group.drills.any((d) => d.id == drill.id)) {
        final updatedGroup = group.copyWith(
          drills: [...group.drills, drill],
        );
        _savedDrillGroups[groupIndex] = updatedGroup;
        notifyListeners();
        
        // Sync to backend
        _scheduleDrillGroupsSync();
      }
    }
  }
  
  void addDrillsToGroup(String groupId, List<DrillModel> drills) {
    final groupIndex = _savedDrillGroups.indexWhere((g) => g.id == groupId);
    if (groupIndex != -1) {
      final group = _savedDrillGroups[groupIndex];
      final newDrills = drills.where((drill) => 
        !group.drills.any((d) => d.id == drill.id)
      ).toList();
      
      if (newDrills.isNotEmpty) {
        final updatedGroup = group.copyWith(
          drills: [...group.drills, ...newDrills],
        );
        _savedDrillGroups[groupIndex] = updatedGroup;
        notifyListeners();
        
        // Sync to backend
        _scheduleDrillGroupsSync();
      }
    }
  }
  
  void removeDrillFromGroup(String groupId, DrillModel drill) {
    final groupIndex = _savedDrillGroups.indexWhere((g) => g.id == groupId);
    if (groupIndex != -1) {
      final group = _savedDrillGroups[groupIndex];
      final updatedGroup = group.copyWith(
        drills: group.drills.where((d) => d.id != drill.id).toList(),
      );
      _savedDrillGroups[groupIndex] = updatedGroup;
      notifyListeners();
      
      // Sync to backend
      _scheduleDrillGroupsSync();
    }
  }
  
  DrillGroup? getDrillGroup(String groupId) {
    try {
      return _savedDrillGroups.firstWhere((g) => g.id == groupId);
    } catch (e) {
      return null;
    }
  }
  
  // MARK: - Liked Drills Management
  
  void toggleLikedDrill(DrillModel drill) {
    if (_likedDrills.contains(drill)) {
      _likedDrills.remove(drill);
    } else {
      _likedDrills.add(drill);
    }
    notifyListeners();
    
    // Sync to backend
    _scheduleDrillGroupsSync();
  }
  
  bool isDrillLiked(DrillModel drill) {
    return _likedDrills.contains(drill);
  }
  
  // ✅ NEW: Check if drill is saved in any collection
  bool isDrillSavedInAnyCollection(DrillModel drill) {
    // Check if drill is in any saved drill group (excluding liked drills group)
    return _savedDrillGroups.any((group) => 
      group.drills.any((d) => d.id == drill.id)
    );
  }
  
  DrillGroup get likedDrillsGroup {
    return DrillGroup(
      id: 'liked_drills',
      name: 'Liked Drills',
      description: 'Your favorite drills',
      drills: _likedDrills.toList(),
      createdAt: DateTime.now(),
      isLikedDrillsGroup: true,
    );
  }
  
  // MARK: - Existing Filter Methods
  
  void updateTimeFilter(String? time) {
    _setLoadingPreferences(true);
    _preferences.selectedTime = time;
    if (_autoGenerateSession) {
      _autoGenerateSessionDrills();
    }
    notifyListeners();
    
    // Sync to backend
    _schedulePreferencesSync();
  }
  
  void updateEquipmentFilter(Set<String> equipment) {
    _setLoadingPreferences(true);
    _preferences.selectedEquipment = equipment;
    if (_autoGenerateSession) {
      _autoGenerateSessionDrills();
    }
    notifyListeners();
    
    // Sync to backend
    _schedulePreferencesSync();
  }
  
  void updateTrainingStyleFilter(String? style) {
    _setLoadingPreferences(true);
    _preferences.selectedTrainingStyle = style;
    if (_autoGenerateSession) {
      _autoGenerateSessionDrills();
    }
    notifyListeners();
    
    // Sync to backend
    _schedulePreferencesSync();
  }
  
  void updateLocationFilter(String? location) {
    _setLoadingPreferences(true);
    _preferences.selectedLocation = location;
    if (_autoGenerateSession) {
      _autoGenerateSessionDrills();
    }
    notifyListeners();
    
    // Sync to backend
    _schedulePreferencesSync();
  }
  
  void updateDifficultyFilter(String? difficulty) {
    _setLoadingPreferences(true);
    _preferences.selectedDifficulty = difficulty;
    if (_autoGenerateSession) {
      _autoGenerateSessionDrills();
    }
    notifyListeners();
    
    // Sync to backend
    _schedulePreferencesSync();
  }
  
  void updateSkillsFilter(Set<String> skills) {
    _setLoadingPreferences(true);
    _preferences.selectedSkills = skills;
    // Don't auto-generate session drills when skills change
    // This preserves the ordered session drills from backend
    notifyListeners();
    
    // Sync to backend
    _schedulePreferencesSync();
  }

  /// Update user preferences (called by PreferencesSyncService)
  void updateUserPreferences(UserPreferences preferences) {
    _preferences = preferences;
    notifyListeners();
  }

  /// Update ordered session drills (called by PreferencesSyncService)
  void updateOrderedSessionDrillsThroughPreferences(List<EditableDrillModel> drills) {
    _editableSessionDrills.clear();
    _sessionDrills.clear();
    
    _editableSessionDrills.addAll(drills);
    _sessionDrills.addAll(drills.map((ed) => ed.drill));
    
    // ✅ Check if session should remain completed after drill updates
    // Only reset completion flag if there are incomplete drills
    if (drills.isNotEmpty && drills.any((drill) => !drill.isCompleted)) {
      _currentSessionCompleted = false;
    }
    
    // ✅ Stop loading preferences when drills are updated
    _setLoadingPreferences(false);
    
    notifyListeners();
  }
  
  // Session drill management
  void addDrillToSession(DrillModel drill) {
    if (!_sessionDrills.any((d) => d.id == drill.id)) {
      _sessionDrills.add(drill);
      
      // Also add to editable session drills
      final editableDrill = EditableDrillModel(
        drill: drill,
        setsDone: 0,
        totalSets: drill.sets > 0 ? drill.sets : 3,
        totalReps: drill.reps > 0 ? drill.reps : 10,
        totalDuration: drill.duration > 0 ? drill.duration : 5,
        isCompleted: false,
      );
      _editableSessionDrills.add(editableDrill);
      
      // ✅ Reset completion flag when adding new drills
      _currentSessionCompleted = false;
      
      notifyListeners();
      _scheduleSessionDrillsSync();
    }
  }
  
  void removeDrillFromSession(DrillModel drill) {
    _sessionDrills.removeWhere((d) => d.id == drill.id);
    _editableSessionDrills.removeWhere((ed) => ed.drill.id == drill.id);
    notifyListeners();
    _scheduleSessionDrillsSync();
  }
  
  void reorderSessionDrills(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final DrillModel item = _sessionDrills.removeAt(oldIndex);
    _sessionDrills.insert(newIndex, item);
    
    final EditableDrillModel editableItem = _editableSessionDrills.removeAt(oldIndex);
    _editableSessionDrills.insert(newIndex, editableItem);
    
    notifyListeners();
    _scheduleSessionDrillsSync();
  }
  
  void clearSession() {
    _sessionDrills.clear();
    _editableSessionDrills.clear();
    _sessionInProgress = false;
    _currentSessionCompleted = false; // ✅ Reset completion flag
    notifyListeners();
    _scheduleSessionDrillsSync();
  }
  
  // Update drill properties in session
  void updateDrillInSession(String drillId, {int? sets, int? reps, int? duration}) {
    // Update legacy session drills
    final drillIndex = _sessionDrills.indexWhere((drill) => drill.id == drillId);
    if (drillIndex != -1) {
      final currentDrill = _sessionDrills[drillIndex];
      final updatedDrill = DrillModel(
        id: currentDrill.id,
        title: currentDrill.title,
        skill: currentDrill.skill,
        subSkills: currentDrill.subSkills,
        sets: sets ?? currentDrill.sets,
        reps: reps ?? currentDrill.reps,
        duration: duration ?? currentDrill.duration,
        description: currentDrill.description,
        instructions: currentDrill.instructions,
        tips: currentDrill.tips,
        equipment: currentDrill.equipment,
        trainingStyle: currentDrill.trainingStyle,
        difficulty: currentDrill.difficulty,
        videoUrl: currentDrill.videoUrl,
      );
      
      _sessionDrills[drillIndex] = updatedDrill;
    }
    
    // Update editable session drills
    final editableDrillIndex = _editableSessionDrills.indexWhere((drill) => drill.drill.id == drillId);
    if (editableDrillIndex != -1) {
      final currentEditableDrill = _editableSessionDrills[editableDrillIndex];
      _editableSessionDrills[editableDrillIndex] = currentEditableDrill.copyWith(
        totalSets: sets,
        totalReps: reps,
        totalDuration: duration,
      );
    }
    
    notifyListeners();
    _scheduleSessionDrillsSync();
  }
  
  // Update drill progress during follow-along
  void updateDrillProgress(String drillId, {int? setsDone, bool? isCompleted}) {
    final editableDrillIndex = _editableSessionDrills.indexWhere((drill) => drill.drill.id == drillId);
    if (editableDrillIndex != -1) {
      final currentEditableDrill = _editableSessionDrills[editableDrillIndex];
      _editableSessionDrills[editableDrillIndex] = currentEditableDrill.copyWith(
        setsDone: setsDone,
        isCompleted: isCompleted,
      );
      
      // ✅ FIXED: Don't auto-complete here to avoid issues
      // The completion should be handled explicitly by the UI
      
      notifyListeners();
      _scheduleSessionDrillsSync();
    }
  }
  
  // Session progress methods
  void startSession() {
    _sessionInProgress = true;
    _currentSessionCompleted = false; // ✅ Reset completion flag when starting
    _sessionCompletionFinished = false; // ✅ Reset to allow future updates
    notifyListeners();
  }
  
  // ✅ UPDATED: Prevent duplicate session completions
  Future<void> completeSession() async {
    if (_currentSessionCompleted) {
      if (kDebugMode) {
        print('⚠️ Session already completed, ignoring duplicate completion request');
      }
      return;
    }
    
    if (_isCompletingSession) {
      if (kDebugMode) {
        print('⚠️ Session completion already in progress, ignoring duplicate request');
      }
      return;
    }
    
    await _completeSessionOnce();
  }
  
  // ✅ NEW: Private method that actually completes the session once
  Future<void> _completeSessionOnce() async {
    if (_currentSessionCompleted || _isCompletingSession) return; // Double-check protection
    
    try {
      _setCompletingSession(true);
      
      _sessionInProgress = false;
      _currentSessionCompleted = true; // ✅ Mark as completed
      
      // Don't force-complete drills, use their current state
      // Session completion should only be allowed when all drills are already fully completed
      
      // Save completed session with current drill states
      final completedSession = CompletedSession(
        date: DateTime.now(),
        drills: List.from(_editableSessionDrills),
        totalCompletedDrills: _editableSessionDrills.where((d) => d.isFullyCompleted).length,
        totalDrills: _editableSessionDrills.length,
      );
      
      // ✅ FIXED: Await the session sync to complete before continuing
      await _addCompletedSessionWithSync(completedSession);
      
      if (kDebugMode) {
        print('✅ Session completed and synced to backend.');
        print('   - Fully completed drills: ${completedSession.totalCompletedDrills}');
        print('   - Total drills: ${completedSession.totalDrills}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error completing session: $e');
      }
    } finally {
      _setCompletingSession(false);
    }
  }

  // ✅ NEW: Add completed session and wait for sync to complete
  Future<void> _addCompletedSessionWithSync(CompletedSession session) async {
    _completedSessions.add(session);
    
    if (kDebugMode) {
      print('✅ CompletedSession saved locally!');
      print('  Date: ${session.date}');
      print('  Drills: ${session.drills.length}');
      print('  Total Completed: ${session.totalCompletedDrills}');
      print('  Total Drills: ${session.totalDrills}');
    }
    
    // ✅ FIXED: Await immediate sync instead of timer-based
    await _syncCompletedSessionImmediate(session);
  }
  
  // Get the next incomplete drill
  EditableDrillModel? getNextIncompleteDrill() {
    try {
      return _editableSessionDrills.firstWhere((drill) => !drill.isCompleted);
    } catch (e) {
      return null;
    }
  }
  
  // Check if session has any progress
  bool get hasSessionProgress {
    return _editableSessionDrills.any((drill) => drill.setsDone > 0 || drill.isCompleted);
  }
  
  // Get session completion percentage
  double get sessionCompletionPercentage {
    if (_editableSessionDrills.isEmpty) return 0.0;
    
    final completedDrills = _editableSessionDrills.where((drill) => drill.isFullyCompleted).length;
    return completedDrills / _editableSessionDrills.length;
  }
  
  // Check if all drills are completed
  bool get isSessionComplete {
    if (_editableSessionDrills.isEmpty) return false;
    return _editableSessionDrills.every((drill) => drill.isFullyCompleted);
  }
  
  // ✅ NEW: Check if current session can be completed (not already completed)
  bool get canCompleteSession {
    return isSessionComplete && !_currentSessionCompleted;
  }
  
  void toggleAutoGenerate(bool value) {
    _autoGenerateSession = value;
    if (value) {
      _autoGenerateSessionDrills();
    }
    notifyListeners();
  }
  
  // Auto-generate session drills based on current filters
  void _autoGenerateSessionDrills() {
    final filtered = filteredDrills;
    _sessionDrills.clear();
    
    final maxDrills = _getMaxDrillsForTime();
    final drillsToAdd = filtered.take(maxDrills).toList();
    
    _sessionDrills.addAll(drillsToAdd);
  }
  
  int _getMaxDrillsForTime() {
    switch (_preferences.selectedTime) {
      case '15min':
        return 2;
      case '30min':
        return 3;
      case '45min':
      case '1h':
        return 4;
      case '1h30':
        return 5;
      case '2h+':
        return 6;
      default:
        return 3;
    }
  }
  
  // Helper methods
  bool get hasSessionDrills => _sessionDrills.isNotEmpty;
  int get sessionDrillCount => _sessionDrills.length;
  
  bool isDrillInSession(DrillModel drill) {
    return _sessionDrills.any((d) => d.id == drill.id);
  }
  
  List<DrillModel> get drillsNotInSession {
    return _availableDrills.where((drill) => !isDrillInSession(drill)).toList();
  }
  
  // Filter drills based on user preferences
  List<DrillModel> get filteredDrills {
    List<DrillModel> filtered = List.from(_availableDrills);
    
    if (_preferences.selectedSkills.isNotEmpty) {
      filtered = filtered.where((drill) {
        return drill.subSkills.any((subSkill) => 
          _preferences.selectedSkills.contains(subSkill));
      }).toList();
    }
    
    if (_preferences.selectedEquipment.isNotEmpty) {
      filtered = filtered.where((drill) {
        return _preferences.selectedEquipment.any((equipment) => 
          drill.equipment.contains(equipment));
      }).toList();
    }
    
    if (_preferences.selectedDifficulty != null) {
      filtered = filtered.where((drill) => 
        drill.difficulty.toLowerCase() == _preferences.selectedDifficulty!.toLowerCase()
      ).toList();
    }
    
    if (_preferences.selectedTrainingStyle != null) {
      filtered = filtered.where((drill) => 
        drill.trainingStyle.toLowerCase().contains(_preferences.selectedTrainingStyle!.toLowerCase())
      ).toList();
    }
    
    return filtered;
  }
  
  // Search functionality
  List<DrillModel> searchDrills(String query) {
    if (query.isEmpty) return drillsNotInSession;
    
    final lowercaseQuery = query.toLowerCase();
    return drillsNotInSession.where((drill) {
      return drill.title.toLowerCase().contains(lowercaseQuery) ||
             drill.skill.toLowerCase().contains(lowercaseQuery) ||
             drill.subSkills.any((subSkill) => 
               subSkill.toLowerCase().contains(lowercaseQuery)) ||
             drill.description.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }
  
  List<DrillModel> filterDrillsBySkill(String skill) {
    return drillsNotInSession.where((drill) {
      return drill.skill.toLowerCase() == skill.toLowerCase() ||
             drill.subSkills.any((subSkill) => 
               subSkill.toLowerCase().contains(skill.toLowerCase()));
    }).toList();
  }
  
  // Persistence methods
  Future<void> _persistState() async {
    // No local persistence - everything is backend-synced
    // This method is kept for potential future use but does nothing
  }
  
  Future<void> _loadPersistedState() async {
    // No local loading - everything is loaded from backend
    // This method is kept for potential future use but does nothing
  }
  
  // Clear all data (for logout, etc.)
  Future<void> clearAllData() async {
    // Reset all local state (backend data will be cleared by backend sync)
    _preferences = UserPreferences();
    _autoGenerateSession = true;
    
    // Clear local session state (will be reloaded from backend)
    _sessionDrills.clear();
    _editableSessionDrills.clear();
    _savedDrillGroups.clear();
    _likedDrills.clear();
    _completedSessions.clear();
    _currentStreak = 0;
    _previousStreak = 0;
    _highestStreak = 0;
    _countOfFullyCompletedSessions = 0;
    
    // ✅ FIXED: Use centralized timer cleanup
    _cancelAllTimers();
    
    notifyListeners();
  }
  
  // Mock data - same as before
  static final List<DrillModel> _mockDrills = [
    DrillModel(
      id: '550e8400-e29b-41d4-a716-446655440001',
      title: 'Ronaldinho drill to cone turn',
      skill: 'Dribbling',
      subSkills: ['Close control', '1v1 moves'],
      sets: 1,
      reps: 1,
      duration: 1,
      description: 'Practice close control and turning at cones like Ronaldinho.',
      instructions: ['Dribble to cone', 'Turn quickly', 'Accelerate away'],
      tips: ['Keep ball close', 'Use both feet', 'Change pace'],
      equipment: ['soccer ball', 'cones'],
      trainingStyle: 'medium intensity',
      difficulty: 'intermediate',
      videoUrl: '',
    ),
    DrillModel(
      id: '550e8400-e29b-41d4-a716-446655440002',
      title: 'Quick Passing Drill',
      skill: 'Passing',
      subSkills: ['Short passing', 'One touch passing'],
      sets: 2,
      reps: 10,
      duration: 5,
      description: 'Improve passing accuracy and speed.',
      instructions: ['Pass and move', 'Keep passes low', 'Communicate'],
      tips: ['Look up', 'Follow through', 'Weight the pass'],
      equipment: ['soccer ball', 'cones'],
      trainingStyle: 'medium intensity',
      difficulty: 'beginner',
      videoUrl: '',
    ),
    DrillModel(
      id: '550e8400-e29b-41d4-a716-446655440003',
      title: 'Power Shot Training',
      skill: 'Shooting',
      subSkills: ['Power shots', 'First time shots'],
      sets: 3,
      reps: 8,
      duration: 10,
      description: 'Develop shooting power and accuracy.',
      instructions: ['Strike through the ball', 'Keep head down', 'Follow through'],
      tips: ['Plant foot firmly', 'Strike with inside of foot', 'Aim for corners'],
      equipment: ['soccer ball', 'goal'],
      trainingStyle: 'high intensity',
      difficulty: 'advanced',
      videoUrl: '',
    ),
    DrillModel(
      id: '550e8400-e29b-41d4-a716-446655440004',
      title: 'First Touch Control',
      skill: 'First Touch',
      subSkills: ['Ground control', 'Touch and move'],
      sets: 2,
      reps: 15,
      duration: 8,
      description: 'Master your first touch under pressure.',
      instructions: ['Receive ball cleanly', 'Touch away from pressure', 'Look up quickly'],
      tips: ['Cushion the ball', 'Use both feet', 'Keep ball close'],
      equipment: ['soccer ball'],
      trainingStyle: 'medium intensity',
      difficulty: 'intermediate',
      videoUrl: '',
    ),
    DrillModel(
      id: '550e8400-e29b-41d4-a716-446655440005',
      title: 'Long Range Passing',
      skill: 'Passing',
      subSkills: ['Long passing', 'Technique'],
      sets: 2,
      reps: 12,
      duration: 6,
      description: 'Improve long distance passing accuracy.',
      instructions: ['Strike through center', 'Follow through high', 'Aim for target'],
      tips: ['Lean back slightly', 'Contact ball cleanly', 'Use full swing'],
      equipment: ['soccer ball', 'cones'],
      trainingStyle: 'medium intensity',
      difficulty: 'advanced',
      videoUrl: '',
    ),
    DrillModel(
      id: '550e8400-e29b-41d4-a716-446655440006',
      title: 'Ball Mastery Skills',
      skill: 'Dribbling',
      subSkills: ['Ball mastery', 'Speed dribbling'],
      sets: 1,
      reps: 20,
      duration: 4,
      description: 'Develop ball control and dribbling skills.',
      instructions: ['Use both feet', 'Keep head up', 'Vary pace'],
      tips: ['Small touches', 'Stay relaxed', 'Practice daily'],
      equipment: ['soccer ball'],
      trainingStyle: 'low intensity',
      difficulty: 'beginner',
      videoUrl: '',
    ),
    DrillModel(
      id: '550e8400-e29b-41d4-a716-446655440007',
      title: 'Advanced Shooting Combinations',
      skill: 'Shooting',
      subSkills: ['Finesse shots', 'Volleying'],
      sets: 2,
      reps: 6,
      duration: 12,
      description: 'Master advanced shooting techniques.',
      instructions: ['Setup touch', 'Shoot with accuracy', 'Follow through'],
      tips: ['Stay balanced', 'Keep eyes on ball', 'Practice both feet'],
      equipment: ['soccer ball', 'goal'],
      trainingStyle: 'high intensity',
      difficulty: 'advanced',
      videoUrl: '',
    ),
    DrillModel(
      id: '550e8400-e29b-41d4-a716-446655440008',
      title: 'Aerial Control Practice',
      skill: 'First Touch',
      subSkills: ['Aerial control', 'Juggling'],
      sets: 1,
      reps: 25,
      duration: 6,
      description: 'Improve control of balls in the air.',
      instructions: ['Watch the ball', 'Use all surfaces', 'Keep it up'],
      tips: ['Relax your body', 'Small touches', 'Be patient'],
      equipment: ['soccer ball'],
      trainingStyle: 'low intensity',
      difficulty: 'beginner',
      videoUrl: '',
    ),
  ];

  void _scheduleSessionDrillsSync() {
    // ✅ NEW: Skip sync for guest users
    if (isGuestMode) {
      if (kDebugMode) {
        print('👤 AppStateService: Skipping session drills sync for guest user');
      }
      return;
    }
    
    _sessionDrillsSyncTimer?.cancel();
    _sessionDrillsSyncTimer = Timer(_sessionDrillsSyncDebounce, () async {
      await SessionDataSyncService.shared.syncOrderedSessionDrills(_editableSessionDrills);
    });
  }

  void _scheduleDrillGroupsSync() {
    // ✅ NEW: Skip sync for guest users
    if (isGuestMode) {
      if (kDebugMode) {
        print('👤 AppStateService: Skipping drill groups sync for guest user');
      }
      return;
    }
    
    _drillGroupsSyncTimer?.cancel();
    _drillGroupsSyncTimer = Timer(_drillGroupsSyncDebounce, () async {
      await _drillGroupSyncService.syncAllDrillGroups(
        savedGroups: _savedDrillGroups,
        likedGroup: likedDrillsGroup,
      );
    });
  }

  void _schedulePreferencesSync() {
    // ✅ UPDATED: Use debouncing for guest users too to prevent spamming the backend
    _preferencesSyncTimer?.cancel();
    _preferencesSyncTimer = Timer(_preferencesSyncDebounce, () async {
      if (isGuestMode) {
        if (kDebugMode) {
          print('👤 AppStateService: Guest mode detected - using public session generation (debounced)');
        }
        await _generateGuestSession();
      } else {
      await _preferencesSyncService.syncPreferencesWithBackend(
        time: _preferences.selectedTime,
        equipment: _preferences.selectedEquipment,
        trainingStyle: _preferences.selectedTrainingStyle,
        location: _preferences.selectedLocation,
        difficulty: _preferences.selectedDifficulty,
        skills: _preferences.selectedSkills,
      );
      
      // ✅ Set loading to false after sync completes
      // Note: updateOrderedSessionDrillsThroughPreferences will also set loading to false
      // if new drills are received, but we set it here as a fallback
      _setLoadingPreferences(false);
      }
    });
  }

  // ✅ NEW: Generate session for guest users using public endpoint
  Future<void> _generateGuestSession() async {
    if (!isGuestMode) return;
    
    try {
      if (kDebugMode) {
        print('👤 Generating guest session with preferences:');
        print('   - Time: ${_preferences.selectedTime}');
        print('   - Equipment: ${_preferences.selectedEquipment}');
        print('   - Training Style: ${_preferences.selectedTrainingStyle}');
        print('   - Location: ${_preferences.selectedLocation}');
        print('   - Difficulty: ${_preferences.selectedDifficulty}');
        print('   - Skills: ${_preferences.selectedSkills}');
      }
      
      // Prepare preferences for backend
      final preferencesData = {
        'duration': _mapTimeToMinutes(_preferences.selectedTime),
        'available_equipment': _preferences.selectedEquipment.toList(),
        'training_style': _preferences.selectedTrainingStyle ?? 'medium_intensity',
        'training_location': _preferences.selectedLocation ?? 'full_field',
        'difficulty': _preferences.selectedDifficulty ?? 'beginner',
        'target_skills': _preferences.selectedSkills.toList(),
      };
      
      final requestData = {
        'preferences': preferencesData,
      };
      
      if (kDebugMode) {
        print('👤 Sending guest session request: $requestData');
      }
      
      final response = await _apiService.post(
        '/public/session/generate',
        body: requestData,
        requiresAuth: false, // Public endpoint
      );
      
      if (response.isSuccess && response.data != null) {
        final sessionData = response.data!['data'];
        if (sessionData != null && sessionData['drills'] != null) {
          final drillsJson = sessionData['drills'] as List<dynamic>;
          
          if (kDebugMode) {
            print('👤 Received ${drillsJson.length} drills from guest session generation');
          }
          
          // Convert to EditableDrillModel objects
          final editableDrills = drillsJson.map((drillJson) {
            // Parse the drill data
            final drill = DrillModel(
              id: drillJson['uuid'] ?? '',
              title: drillJson['title'] ?? 'Unnamed Drill',
              skill: _mapBackendSkillToFrontend(drillJson['primary_skill']?['category'] ?? 'general'),
              subSkills: _extractSubSkills(drillJson),
              sets: drillJson['sets'] ?? 3,
              reps: drillJson['reps'] ?? 10,
              duration: drillJson['duration'] ?? 10,
              description: drillJson['description'] ?? '',
              instructions: (drillJson['instructions'] as List<dynamic>?)?.cast<String>() ?? [],
              tips: (drillJson['tips'] as List<dynamic>?)?.cast<String>() ?? [],
              equipment: (drillJson['equipment'] as List<dynamic>?)?.cast<String>() ?? [],
              trainingStyle: drillJson['intensity'] ?? 'medium',
              difficulty: drillJson['difficulty'] ?? 'beginner',
              videoUrl: drillJson['video_url'] ?? '',
            );
            
            return EditableDrillModel(
              drill: drill,
              setsDone: 0,
              totalSets: drill.sets > 0 ? drill.sets : 3,
              totalReps: drill.reps > 0 ? drill.reps : 10,
              totalDuration: drill.duration > 0 ? drill.duration : 10,
              isCompleted: false,
            );
          }).toList();
          
          // Update session drills
          _editableSessionDrills.clear();
          _sessionDrills.clear();
          _editableSessionDrills.addAll(editableDrills);
          _sessionDrills.addAll(editableDrills.map((ed) => ed.drill));
          
          if (kDebugMode) {
            print('✅ Guest session updated with ${editableDrills.length} drills');
          }
        }
      } else {
        if (kDebugMode) {
          print('❌ Failed to generate guest session: ${response.error}');
        }
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating guest session: $e');
      }
    } finally {
      // ✅ Always stop loading preferences
      _setLoadingPreferences(false);
      notifyListeners();
    }
  }

  // ✅ NEW: Helper method to map time preference to minutes
  int _mapTimeToMinutes(String? timePreference) {
    switch (timePreference) {
      case '15min':
        return 15;
      case '30min':
        return 30;
      case '45min':
        return 45;
      case '1h':
        return 60;
      case '1h30':
        return 90;
      case '2h+':
        return 120;
      default:
        return 30; // Default to 30 minutes
    }
  }

  // ✅ NEW: Helper method to map backend skill category to frontend
  String _mapBackendSkillToFrontend(String backendSkill) {
    const skillMap = {
      'passing': 'Passing',
      'shooting': 'Shooting',
      'dribbling': 'Dribbling',
      'first_touch': 'First Touch',
      'defending': 'Defending',
      'fitness': 'Fitness',
      'general': 'General',
    };
    
    return skillMap[backendSkill.toLowerCase()] ?? 'General';
  }

  // ✅ NEW: Helper method to extract sub-skills from drill JSON
  List<String> _extractSubSkills(Map<String, dynamic> drillJson) {
    final subSkills = <String>[];
    
    // Add primary sub-skill
    final primarySubSkill = drillJson['primary_skill']?['sub_skill'];
    if (primarySubSkill != null) {
      subSkills.add(_mapBackendSubSkillToFrontend(primarySubSkill));
    }
    
    // Add secondary sub-skills
    final secondarySkills = drillJson['secondary_skills'] as List<dynamic>?;
    if (secondarySkills != null) {
      for (final skill in secondarySkills) {
        final subSkill = skill['sub_skill'];
        if (subSkill != null) {
          subSkills.add(_mapBackendSubSkillToFrontend(subSkill));
        }
      }
    }
    
    return subSkills;
  }

  // ✅ NEW: Helper method to map backend sub-skill to frontend
  String _mapBackendSubSkillToFrontend(String backendSubSkill) {
    const subSkillMap = {
      // Dribbling
      'close_control': 'Close control',
      'speed_dribbling': 'Speed dribbling',
      '1v1_moves': '1v1 moves',
      'change_of_direction': 'Change of direction',
      'ball_mastery': 'Ball mastery',
      
      // First Touch
      'ground_control': 'Ground control',
      'aerial_control': 'Aerial control',
      'turn_with_ball': 'Turn with ball',
      'touch_and_move': 'Touch and move',
      'juggling': 'Juggling',
      
      // Passing
      'short_passing': 'Short passing',
      'long_passing': 'Long passing',
      'one_touch_passing': 'One touch passing',
      'technique': 'Technique',
      'passing_with_movement': 'Passing with movement',
      
      // Shooting
      'power_shots': 'Power shots',
      'finesse_shots': 'Finesse shots',
      'first_time_shots': 'First time shots',
      '1v1_to_shoot': '1v1 to shoot',
      'shooting_on_the_run': 'Shooting on the run',
      'volleying': 'Volleying',
      
      // Defending
      'tackling': 'Tackling',
      'marking': 'Marking',
      'intercepting': 'Intercepting',
      'positioning': 'Positioning',
      
      // Fallback
      'general': 'General',
    };
    
    return subSkillMap[backendSubSkill.toLowerCase()] ?? backendSubSkill;
  }

  // ✅ DEBUG METHODS FOR STREAK TESTING
  /// Reset all streak values to 0 (for debugging/testing)
  void resetStreak() {
    _currentStreak = 0;
    _previousStreak = 0;
    _highestStreak = 0;
    _countOfFullyCompletedSessions = 0;
    
    if (kDebugMode) {
      print('🧪 [DEBUG] Streaks reset: current=0, previous=0, highest=0, sessions=0');
    }
    
    notifyListeners();
  }

  /// Increment current streak by 1 (for debugging/testing)
  void incrementStreak() {
    _previousStreak = _currentStreak;
    _currentStreak += 1;
    _highestStreak = _currentStreak > _highestStreak ? _currentStreak : _highestStreak;
    
    if (kDebugMode) {
      print('🧪 [DEBUG] Streak incremented: current=$_currentStreak, previous=$_previousStreak, highest=$_highestStreak');
    }
    
    notifyListeners();
  }

  /// Add multiple completed sessions for testing (for debugging/testing)
  void addCompletedSessions(int count) {
    final now = DateTime.now();
    
    for (int i = 0; i < count; i++) {
      // Create sessions on consecutive past days
      final sessionDate = now.subtract(Duration(days: count - i));
      
      // Create a test completed session
      final testSession = CompletedSession(
        date: sessionDate,
        drills: [
          EditableDrillModel(
            drill: _mockDrills.first, // Use first mock drill
            setsDone: 1,
            totalSets: 1,
            totalReps: 10,
            totalDuration: 5,
            isCompleted: true,
          ),
        ],
        totalCompletedDrills: 1,
        totalDrills: 1,
      );
      
      _completedSessions.add(testSession);
    }
    
    // Update completed sessions count
    _countOfFullyCompletedSessions = _completedSessions.length;
    
    // Recalculate streaks based on new sessions
    _recalculateStreaksFromSessions();
    
    if (kDebugMode) {
      print('🧪 [DEBUG] Added $count completed sessions');
      print('   - Total sessions: $_countOfFullyCompletedSessions');
      print('   - Current streak: $_currentStreak');
      print('   - Highest streak: $_highestStreak');
    }
    
    notifyListeners();
  }

  /// Recalculate streaks based on completed sessions (helper method)
  void _recalculateStreaksFromSessions() {
    if (_completedSessions.isEmpty) {
      _currentStreak = 0;
      _previousStreak = 0;
      _highestStreak = 0;
      return;
    }

    // Sort sessions by date
    final sortedSessions = _completedSessions.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Calculate current streak (consecutive days ending at today or yesterday)
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    int currentStreak = 0;
    int maxStreak = 0;
    int tempStreak = 1;
    
    // Group sessions by date (in case multiple sessions per day)
    final sessionDates = <DateTime>{};
    for (final session in sortedSessions) {
      final sessionDate = DateTime(session.date.year, session.date.month, session.date.day);
      sessionDates.add(sessionDate);
    }
    
    final sortedDates = sessionDates.toList()..sort();
    
    // Calculate max streak
    for (int i = 0; i < sortedDates.length; i++) {
      if (i > 0) {
        final daysDifference = sortedDates[i].difference(sortedDates[i - 1]).inDays;
        if (daysDifference == 1) {
          tempStreak++;
        } else {
          tempStreak = 1;
        }
      }
      maxStreak = tempStreak > maxStreak ? tempStreak : maxStreak;
    }
    
    // Calculate current streak (from today backwards)
    DateTime checkDate = todayDate;
    while (sessionDates.contains(checkDate)) {
      currentStreak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    
    // If no session today, check if there was one yesterday
    if (currentStreak == 0 && sessionDates.contains(todayDate.subtract(const Duration(days: 1)))) {
      checkDate = todayDate.subtract(const Duration(days: 1));
      while (sessionDates.contains(checkDate)) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    }
    
    _previousStreak = _currentStreak;
    _currentStreak = currentStreak;
    _highestStreak = maxStreak > _highestStreak ? maxStreak : _highestStreak;
  }

  /// ✅ NEW: Reset drill progress for a new session (keep drills, reset progress)
  void resetDrillProgressForNewSession() {
    if (kDebugMode) {
      print('🔄 Resetting drill progress for new session...');
      print('  - Drills before reset: ${_editableSessionDrills.length}');
    }
    
    // Reset progress for all drills in the session
    for (int i = 0; i < _editableSessionDrills.length; i++) {
      final currentDrill = _editableSessionDrills[i];
      _editableSessionDrills[i] = currentDrill.copyWith(
        setsDone: 0,
        isCompleted: false,
      );
      
      if (kDebugMode) {
        print('    Reset drill ${i + 1}: ${currentDrill.drill.title}');
        print('      - setsDone: ${currentDrill.setsDone} → 0');
        print('      - isCompleted: ${currentDrill.isCompleted} → false');
      }
    }
    
    // Reset session completion state
    _currentSessionCompleted = false;
    _sessionCompletionFinished = false;
    _isCompletingSession = false;
    
    if (kDebugMode) {
      print('✅ Drill progress reset complete');
      print('  - Session completion state reset');
      print('  - Ready for new session with same drills');
    }
    
    // Sync the reset state to backend
    _scheduleSessionDrillsSync();
    
    // Notify UI to update
    notifyListeners();
  }
} 