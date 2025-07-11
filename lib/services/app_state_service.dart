import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/drill_model.dart';
import '../models/editable_drill_model.dart';
import '../models/drill_group_model.dart';
import '../models/filter_models.dart';
import '../config/app_config.dart';
import '../services/drill_api_service.dart';
import './test_data_service.dart';
import 'dart:async';
import '../services/session_data_sync_service.dart';
import '../services/progress_data_sync_service.dart';
import '../services/user_manager_service.dart';
import '../services/drill_group_sync_service.dart';
import '../services/preferences_sync_service.dart';

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
  final ProgressDataSyncService _progressSyncService = ProgressDataSyncService.shared;
  final DrillGroupSyncService _drillGroupSyncService = DrillGroupSyncService.shared;
  final PreferencesSyncService _preferencesSyncService = PreferencesSyncService.shared;
  
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
  
  // Saved drill groups
  final List<DrillGroup> _savedDrillGroups = [];
  List<DrillGroup> get savedDrillGroups => List.unmodifiable(_savedDrillGroups);
  
  // Liked drills (special group)
  final Set<DrillModel> _likedDrills = {};
  Set<DrillModel> get likedDrills => Set.unmodifiable(_likedDrills);
  
  // All available drills - always use backend data for consistency
  List<DrillModel> get _availableDrills {
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
    print('📊 [GETTER] Accessing completedSessions: ${_completedSessions.length} sessions');
    return List.unmodifiable(_completedSessions);
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
    
    // Schedule syncs
    _scheduleCompletedSessionSync(session);
    
    // Refresh progress history from backend after session completion
    // This ensures we get the latest streaks and completed sessions count
    refreshProgressHistoryFromBackend();
    
    notifyListeners();
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
    }

    await _loadPersistedState();
    
    // Set initial load flags
    _isInitialLoad = true;
    _isLoggingOut = false;
    
    // Load test session if in debug mode and no session exists
    if (AppConfig.useTestData && _editableSessionDrills.isEmpty) {
      await _loadTestSession();
    }
    
    // No longer pre-caching drills - they'll be loaded from backend when needed
    
    notifyListeners();
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
      } else {
        if (kDebugMode) {
          print('⚠️ No progress history data returned from backend');
        }
      }
      
      notifyListeners();
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
    
    // Cancel sync timers
    _sessionDrillsSyncTimer?.cancel();
    _completedSessionSyncTimer?.cancel();
    _drillGroupsSyncTimer?.cancel();
    
    if (kDebugMode) {
      print('✅ User data cleared');
    }
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
    
    // Don't allow multiple concurrent searches
    if (_isLoading && !loadMore) return;
    if (_isLoadingMore && loadMore) return;
    
    // Reset pagination for new search
    if (!loadMore) {
      _currentSearchPage = 1;
      _searchResults.clear();
      _lastSearchQuery = query;
      _lastSearchSkill = skill;
      _lastSearchDifficulty = difficulty;
    } else {
      // Check if we can load more
      if (!_hasMoreSearchResults) return;
      _currentSearchPage++;
    }
    
    loadMore ? _setLoadingMore(true) : _setLoading(true);
    _clearError();
    
    try {
      if (AppConfig.useTestData) {
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
    }
    
    notifyListeners();
  }
  
  /// Get drills by skill with loading state
  Future<List<DrillModel>> getDrillsBySkillAsync(String skill) async {
    _setLoading(true);
    _clearError();
    
    try {
      if (AppConfig.useTestData) {
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
      if (AppConfig.useTestData) {
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
    _preferences.selectedTime = time;
    if (_autoGenerateSession) {
      _autoGenerateSessionDrills();
    }
    notifyListeners();
    
    // Sync to backend
    _schedulePreferencesSync();
  }
  
  void updateEquipmentFilter(Set<String> equipment) {
    _preferences.selectedEquipment = equipment;
    if (_autoGenerateSession) {
      _autoGenerateSessionDrills();
    }
    notifyListeners();
    
    // Sync to backend
    _schedulePreferencesSync();
  }
  
  void updateTrainingStyleFilter(String? style) {
    _preferences.selectedTrainingStyle = style;
    if (_autoGenerateSession) {
      _autoGenerateSessionDrills();
    }
    notifyListeners();
    
    // Sync to backend
    _schedulePreferencesSync();
  }
  
  void updateLocationFilter(String? location) {
    _preferences.selectedLocation = location;
    if (_autoGenerateSession) {
      _autoGenerateSessionDrills();
    }
    notifyListeners();
    
    // Sync to backend
    _schedulePreferencesSync();
  }
  
  void updateDifficultyFilter(String? difficulty) {
    _preferences.selectedDifficulty = difficulty;
    if (_autoGenerateSession) {
      _autoGenerateSessionDrills();
    }
    notifyListeners();
    
    // Sync to backend
    _schedulePreferencesSync();
  }
  
  void updateSkillsFilter(Set<String> skills) {
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
      
      notifyListeners();
      _scheduleSessionDrillsSync();
    }
  }
  
  // Session progress methods
  void startSession() {
    _sessionInProgress = true;
    notifyListeners();
  }
  
  void completeSession() {
    _sessionInProgress = false;
    // Mark all drills as completed
    for (int i = 0; i < _editableSessionDrills.length; i++) {
      _editableSessionDrills[i] = _editableSessionDrills[i].copyWith(isCompleted: true);
    }
    // Save completed session
    final completedSession = CompletedSession(
      date: DateTime.now(),
      drills: List.from(_editableSessionDrills),
      totalCompletedDrills: _editableSessionDrills.where((d) => d.isCompleted).length,
      totalDrills: _editableSessionDrills.length,
    );
    addCompletedSession(completedSession);
    print('Session completed and added to completedSessions.');
    notifyListeners();
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
    
    final completedDrills = _editableSessionDrills.where((drill) => drill.isCompleted).length;
    return completedDrills / _editableSessionDrills.length;
  }
  
  // Check if all drills are completed
  bool get isSessionComplete {
    if (_editableSessionDrills.isEmpty) return false;
    return _editableSessionDrills.every((drill) => drill.isCompleted);
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
    
    // Cancel sync timers
    _sessionDrillsSyncTimer?.cancel();
    _completedSessionSyncTimer?.cancel();
    _drillGroupsSyncTimer?.cancel();
    _preferencesSyncTimer?.cancel();
    
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
      trainingStyle: 'medium intensity',
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
      trainingStyle: 'medium intensity',
      difficulty: 'beginner',
      videoUrl: '',
    ),
  ];

  void _scheduleSessionDrillsSync() {
    _sessionDrillsSyncTimer?.cancel();
    _sessionDrillsSyncTimer = Timer(_sessionDrillsSyncDebounce, () async {
      await SessionDataSyncService.shared.syncOrderedSessionDrills(_editableSessionDrills);
    });
  }

  void _scheduleDrillGroupsSync() {
    _drillGroupsSyncTimer?.cancel();
    _drillGroupsSyncTimer = Timer(_drillGroupsSyncDebounce, () async {
      await _drillGroupSyncService.syncAllDrillGroups(
        savedGroups: _savedDrillGroups,
        likedGroup: likedDrillsGroup,
      );
    });
  }

  void _schedulePreferencesSync() {
    _preferencesSyncTimer?.cancel();
    _preferencesSyncTimer = Timer(_preferencesSyncDebounce, () async {
      await _preferencesSyncService.syncPreferencesWithBackend(
        time: _preferences.selectedTime,
        equipment: _preferences.selectedEquipment,
        trainingStyle: _preferences.selectedTrainingStyle,
        location: _preferences.selectedLocation,
        difficulty: _preferences.selectedDifficulty,
        skills: _preferences.selectedSkills,
      );
    });
  }
} 