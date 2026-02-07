import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/drill_model.dart';
import '../models/editable_drill_model.dart';
import '../models/drill_group_model.dart';
import '../models/filter_models.dart';
import '../config/app_config.dart';
import '../services/drill_api_service.dart';
import './test_data_service.dart';
import './guest_drill_service.dart';
import 'dart:async';
import '../services/session_data_sync_service.dart';
import '../services/progress_data_sync_service.dart';
import '../services/user_manager_service.dart';
import '../services/drill_group_sync_service.dart';
import '../services/preferences_sync_service.dart';
import '../services/loading_state_service.dart';
import './api_service.dart';
import './custom_drill_service.dart';
import './friend_service.dart';

// ===== ENUMS FOR STATE MANAGEMENT =====
// Session lifecycle states - tracks progress through a training session
enum SessionState { 
  idle,           // No session started
  inProgress,     // Session started, drills being done
  canComplete,    // All drills finished, ready to complete
  completing,     // Currently saving completion data
  completed       // Session saved and done
}

// UI loading states for search operations
enum LoadingState { 
  idle,           // No loading
  loading,        // Initial search/load
  loadingMore,    // Loading additional pages
  refreshing      // Pull-to-refresh
}

// Backend sync states
enum SyncState { 
  idle,           // No sync in progress
  syncing,        // Currently syncing
  failed          // Sync failed
}

// ===== COMPLETED SESSION MODEL =====
// Represents a finished training session with all drill data
class CompletedSession {
  final DateTime date;
  final List<EditableDrillModel> drills;
  final int totalCompletedDrills;
  final int totalDrills;
  final String sessionType;

  CompletedSession({
    required this.date,
    required this.drills,
    required this.totalCompletedDrills,
    required this.totalDrills,
    this.sessionType = 'training',
  });

  // Serialization for backend storage
  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'drills': drills.map((d) => d.toJson()).toList(),
    'totalCompletedDrills': totalCompletedDrills,
    'totalDrills': totalDrills,
    'session_type': sessionType,
  };

  factory CompletedSession.fromJson(Map<String, dynamic> json) => CompletedSession(
    date: DateTime.parse(json['date']),
    drills: json['drills'] != null 
        ? (json['drills'] as List).map((d) => EditableDrillModel.fromJson(d)).toList()
        : [], // Handle null drills for mental training sessions
    totalCompletedDrills: json['total_completed_drills'],
    totalDrills: json['total_drills'],
    sessionType: json['session_type'] ?? 'training',
  );
}

// ===== SYNC COORDINATOR CLASS =====
// Prevents race conditions and manages debounced operations
// Critical for preventing duplicate API calls and data conflicts
class SyncCoordinator {
  final Map<String, Timer> _timers = {};
  final Map<String, Completer<void>> _activeOperations = {};
  
  // Schedule a debounced operation (e.g., sync after user stops typing)
  void scheduleSync(String key, Duration delay, Future<void> Function() operation) {
    _timers[key]?.cancel();
    _timers[key] = Timer(delay, () async {
      await _guardedOperation(key, operation);
    });
  }
  
  // Prevents multiple instances of the same operation running simultaneously
  Future<void> _guardedOperation(String key, Future<void> Function() operation) async {
    if (_activeOperations.containsKey(key)) {
      if (kDebugMode) print('⚠️ Operation $key already in progress, skipping');
      return;
    }
    
    final completer = Completer<void>();
    _activeOperations[key] = completer;
    
    try {
      await operation();
    } catch (e) {
      if (kDebugMode) print('❌ Operation $key failed: $e');
    } finally {
      _activeOperations.remove(key);
      completer.complete();
    }
  }
  
  // Same as above but returns a result
  Future<T?> _guardedOperationWithResult<T>(String key, Future<T> Function() operation) async {
    if (_activeOperations.containsKey(key)) {
      if (kDebugMode) print('⚠️ Operation $key already in progress, skipping');
      return null;
    }
    
    final completer = Completer<void>();
    _activeOperations[key] = completer;
    
    try {
      final result = await operation();
      return result;
    } catch (e) {
      if (kDebugMode) print('❌ Operation $key failed: $e');
      return null;
    } finally {
      _activeOperations.remove(key);
      completer.complete();
    }
  }
  
  // Execute operation immediately, canceling any pending timer
  Future<void> executeImmediate(String key, Future<void> Function() operation) async {
    _timers[key]?.cancel();
    await _guardedOperation(key, operation);
  }
  
  Future<T?> executeImmediateWithResult<T>(String key, Future<T> Function() operation) async {
    _timers[key]?.cancel();
    return await _guardedOperationWithResult(key, operation);
  }
  
  // Cleanup all pending operations
  void cancelAll() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _activeOperations.clear();
  }
  
  bool isOperationActive(String key) => _activeOperations.containsKey(key);
}

// ===== MAIN APP STATE SERVICE =====
// Singleton service managing all app state, data synchronization, and business logic
class AppStateService extends ChangeNotifier {
  static AppStateService? _instance;
  static AppStateService get instance => _instance ??= AppStateService._();
  
  AppStateService._();
  
  // ===== SERVICES =====
  // External service dependencies - centralized here for easy testing/mocking
  final DrillApiService _drillApiService = DrillApiService.shared;
  final GuestDrillService _guestDrillService = GuestDrillService.shared;
  final ApiService _apiService = ApiService.shared;
  final ProgressDataSyncService _progressSyncService = ProgressDataSyncService.shared;
  final DrillGroupSyncService _drillGroupSyncService = DrillGroupSyncService.shared;
  final PreferencesSyncService _preferencesSyncService = PreferencesSyncService.shared;
  final UserManagerService _userManager = UserManagerService.instance;
  // ✅ ADDED: Custom drill service for fetching user's custom drills
  final CustomDrillService _customDrillService = CustomDrillService.shared;
  // ✅ ADDED: Friend service for friend request tracking
  final FriendService _friendService = FriendService.shared;
  
  // ===== SYNC COORDINATION =====
  // Prevents race conditions and manages debounced operations
  final SyncCoordinator _syncCoordinator = SyncCoordinator();
  
  // Debounce timers - balance between responsiveness and API efficiency
  static const Duration _sessionDrillsSyncDebounce = Duration(milliseconds: 500);
  static const Duration _progressSyncDebounce = Duration(milliseconds: 1000);
  static const Duration _drillGroupsSyncDebounce = Duration(milliseconds: 1000);
  static const Duration _preferencesSyncDebounce = Duration(milliseconds: 1500); // ✅ IMPROVED: Increased from 1000ms for better debouncing
  static const Duration _searchDebounceDelay = Duration(milliseconds: 300);
  
  // ===== USER PREFERENCES SECTION =====
  // User's training preferences that drive session generation
  UserPreferences _preferences = UserPreferences();
  UserPreferences get preferences => _preferences;
  SyncState _preferencesSyncState = SyncState.idle;
  bool get isLoadingPreferences => _preferencesSyncState == SyncState.syncing;
  
  // ===== SESSION MANAGEMENT SECTION =====
  // Current training session data - split into editable (with progress) and read-only versions
  final List<EditableDrillModel> _editableSessionDrills = [];
  List<EditableDrillModel> get editableSessionDrills => List.unmodifiable(_editableSessionDrills);
  
  final List<DrillModel> _sessionDrills = [];
  List<DrillModel> get sessionDrills => List.unmodifiable(_sessionDrills);
  
  // Session state management
  SessionState _sessionState = SessionState.idle;
  SessionState get sessionState => _sessionState;
  bool get sessionInProgress => _sessionState == SessionState.inProgress || _sessionState == SessionState.canComplete;
  bool get currentSessionCompleted => _sessionState == SessionState.completed;
  bool get canCompleteSession => _sessionState == SessionState.canComplete;
  bool get isCompletingSession => _sessionState == SessionState.completing;
  
  // ===== GUEST MODE SECTION =====
  // Limited drill set for users without accounts
  List<DrillModel> _guestDrills = [];
  bool _guestDrillsLoaded = false;
  bool get isGuestMode => _userManager.isGuestMode;
  bool get isAuthenticated => _userManager.isAuthenticated;
  
  // ===== DRILL COLLECTIONS SECTION =====
  // User's saved drill collections and liked drills
  final List<DrillGroup> _savedDrillGroups = [];
  List<DrillGroup> get savedDrillGroups => List.unmodifiable(_savedDrillGroups);
  
  final Set<DrillModel> _likedDrills = {};
  Set<DrillModel> get likedDrills => Set.unmodifiable(_likedDrills);
  
  // ✅ ADDED: User's custom drills storage
  final List<DrillModel> _customDrills = [];
  List<DrillModel> get customDrills => List.unmodifiable(_customDrills);
  
  // ===== SEARCH SECTION =====
  // Drill search state and pagination
  LoadingState _searchState = LoadingState.idle;
  bool get isLoading => _searchState == LoadingState.loading || _searchState == LoadingState.refreshing;
  bool get isLoadingMore => _searchState == LoadingState.loadingMore;
  
  List<DrillModel> _searchResults = [];
  List<DrillModel> get searchResults => List.unmodifiable(_searchResults);
  
  // Pagination state
  int _currentSearchPage = 1;
  int _totalSearchPages = 1;
  int _totalSearchResults = 0;
  bool _hasMoreSearchResults = false;
  
  // Last search parameters for "load more" functionality
  String? _lastSearchQuery;
  String? _lastSearchSkill;
  String? _lastSearchDifficulty;
  
  // ===== PROGRESS TRACKING SECTION =====
  // User's training history and streak data
  final List<CompletedSession> _completedSessions = [];
  List<CompletedSession> get completedSessions => List.unmodifiable(_completedSessions);
  
  // Streak tracking for gamification
  int _currentStreak = 0;
  int get currentStreak => _currentStreak;
  
  int _previousStreak = 0;
  int get previousStreak => _previousStreak;
  
  int _highestStreak = 0;
  int get highestStreak => _highestStreak;
  
  int _countOfFullyCompletedSessions = 0;
  int get countOfFullyCompletedSessions => _countOfFullyCompletedSessions;
  
  // ✅ NEW: Backend-sourced progress metrics only
  String _favoriteDrill = '';
  String get favoriteDrill => _favoriteDrill;
  
  double _drillsPerSession = 0.0;
  double get drillsPerSession => _drillsPerSession;
  
  double _minutesPerSession = 0.0;
  double get minutesPerSession => _minutesPerSession;
  
  int _totalTimeAllSessions = 0;
  int get totalTimeAllSessions => _totalTimeAllSessions;
  
  int _dribblingDrillsCompleted = 0;
  int get dribblingDrillsCompleted => _dribblingDrillsCompleted;
  
  int _firstTouchDrillsCompleted = 0;
  int get firstTouchDrillsCompleted => _firstTouchDrillsCompleted;
  
  int _passingDrillsCompleted = 0;
  int get passingDrillsCompleted => _passingDrillsCompleted;
  
  int _shootingDrillsCompleted = 0;
  int get shootingDrillsCompleted => _shootingDrillsCompleted;
  
  int _defendingDrillsCompleted = 0;
  int get defendingDrillsCompleted => _defendingDrillsCompleted;
  
  int _goalkeepingDrillsCompleted = 0;
  int get goalkeepingDrillsCompleted => _goalkeepingDrillsCompleted;
  
  int _fitnessDrillsCompleted = 0;
  int get fitnessDrillsCompleted => _fitnessDrillsCompleted;
  
  // ✅ NEW: Additional progress metrics
  String _mostImprovedSkill = '';
  String get mostImprovedSkill => _mostImprovedSkill;
  
  int _uniqueDrillsCompleted = 0;
  int get uniqueDrillsCompleted => _uniqueDrillsCompleted;
  
  int _beginnerDrillsCompleted = 0;
  int get beginnerDrillsCompleted => _beginnerDrillsCompleted;
  
  int _intermediateDrillsCompleted = 0;
  int get intermediateDrillsCompleted => _intermediateDrillsCompleted;
  
  int _advancedDrillsCompleted = 0;
  int get advancedDrillsCompleted => _advancedDrillsCompleted;
  
  // ✅ NEW: Mental training metrics
  int _mentalTrainingSessions = 0;
  int get mentalTrainingSessions => _mentalTrainingSessions;
  
  int _totalMentalTrainingMinutes = 0;
  int get totalMentalTrainingMinutes => _totalMentalTrainingMinutes;
  
  // ===== APPLICATION STATE SECTION =====
  // Global app state flags
  bool _isInitialLoad = true;
  bool get isInitialLoad => _isInitialLoad;
  
  bool _isLoggingOut = false;
  bool get isLoggingOut => _isLoggingOut;
  
  String? _lastError;
  String? get lastError => _lastError;
  
  // Auto-generation feature toggle
  bool _autoGenerateSession = true;
  bool get autoGenerateSession => _autoGenerateSession;

  // ===== FRIEND REQUEST COUNT SECTION =====
  // Track pending friend requests for badge display
  int _friendRequestCount = 0;
  int get friendRequestCount => _friendRequestCount;
  bool get hasFriendRequests => _friendRequestCount > 0;
  
  // ===== DERIVED PROPERTIES =====
  // Computed properties based on current state and configuration
  List<DrillModel> get _availableDrills {
    if (isGuestMode) {
      if (kDebugMode) print('👤 Using guest drills data (limited set)');
      return _guestDrills;
    }
    
    if (AppConfig.useTestData) {
      if (kDebugMode) print('🔧 Using test drills data (AppConfig.useTestData = true)');
      return TestDataService.getTestDrills();
    } else {
      if (kDebugMode) print('🌐 Using backend drills data - search handled by backend API');
      // ✅ FIXED: Return empty list for production since search is handled by backend
      // The backend search endpoint should include both default drills and custom drills
      return <DrillModel>[];
    }
  }
  List<DrillModel> get availableDrills => List.unmodifiable(_availableDrills);
  
  // Check if user has completed any sessions today
  bool get hasSessionsCompletedToday {
    final today = DateTime.now();
    return _completedSessions.any((session) => 
      session.date.year == today.year &&
      session.date.month == today.month &&
      session.date.day == today.day
    );
  }

  // Count of sessions completed today
  int get sessionsCompletedToday {
    final today = DateTime.now();
    return _completedSessions.where((session) => 
      session.date.year == today.year &&
      session.date.month == today.month &&
      session.date.day == today.day
    ).length;
  }

  // Check if user has made any progress on current session
  bool get hasSessionProgress {
    return _editableSessionDrills.any((drill) => drill.setsDone > 0 || drill.isCompleted);
  }
  
  // Calculate completion percentage for progress bars
  double get sessionCompletionPercentage {
    if (_editableSessionDrills.isEmpty) return 0.0;
    final completedDrills = _editableSessionDrills.where((drill) => drill.isFullyCompleted).length;
    return completedDrills / _editableSessionDrills.length;
  }
  
  // Check if all drills in session are fully completed
  bool get isSessionComplete {
    if (_editableSessionDrills.isEmpty) return false;
    return _editableSessionDrills.every((drill) => drill.isFullyCompleted);
  }
  
  // Quick access properties for UI
  bool get hasSessionDrills => _sessionDrills.isNotEmpty;
  int get sessionDrillCount => _sessionDrills.length;
  int get currentSearchPage => _currentSearchPage;
  int get totalSearchPages => _totalSearchPages;
  int get totalSearchResults => _totalSearchResults;
  bool get hasMoreSearchResults => _hasMoreSearchResults;
  bool get hasSearchResults => _searchResults.isNotEmpty;
  
  // ===== INITIALIZATION SECTION =====
  // App startup sequence - sets up initial state based on user type
  Future<void> initialize() async {
    if (kDebugMode) {
      print('🚀 Initializing AppStateService...');
      print('   Environment: ${AppConfig.environmentName}');
      print('   Base URL: ${AppConfig.baseUrl}');
      print('   Use Test Data: ${AppConfig.useTestData}');
      print('   Is Guest Mode: ${isGuestMode}');
    }

    await _loadPersistedState();
    
    _isInitialLoad = true;
    _isLoggingOut = false;
    
    // Load appropriate data based on user type
    if (isGuestMode) {
      if (kDebugMode) print('👤 Initializing for guest mode...');
      await _loadGuestDrills();
      if (_guestDrills.isNotEmpty) {
        await _loadTestSessionForGuest();
      }
    } else {
      // Load test session for development/testing
      if (AppConfig.useTestData && _editableSessionDrills.isEmpty) {
        await _loadTestSession();
      }
    }
    
    notifyListeners();
  }

  // Load limited drill set for guest users
  Future<void> _loadGuestDrills() async {
    if (!isGuestMode) return;
    
    if (kDebugMode) print('📥 Loading guest drills...');
    _setSearchState(LoadingState.loading);
    
    try {
      final guestDrills = await _guestDrillService.fetchGuestDrills();
      _guestDrills = guestDrills;
      _guestDrillsLoaded = true;
      
      if (kDebugMode) print('✅ Loaded ${_guestDrills.length} guest drills');
    } catch (e) {
      if (kDebugMode) print('❌ Error loading guest drills: $e');
      _setError('Failed to load guest drills: $e');
    } finally {
      _setSearchState(LoadingState.idle);
    }
  }

  // Generate a sample session for guest users to try the app
  Future<void> _loadTestSessionForGuest() async {
    if (!isGuestMode || _guestDrills.isEmpty) return;
    
    if (kDebugMode) print('📚 Loading sample session for guest with ${_guestDrills.length} available drills');
    
    try {
      final sampleDrills = <DrillModel>[];
      final categories = ['Passing', 'Dribbling', 'Shooting', 'First Touch', 'Defending', 'Goalkeeping', 'Fitness'];
      
      // Try to get one drill from each category for variety
      for (final category in categories) {
        final categoryDrill = _guestDrills.where((drill) => drill.skill == category).firstOrNull;
        if (categoryDrill != null && sampleDrills.length < 3) {
          sampleDrills.add(categoryDrill);
        }
      }
      
      // Fill remaining slots with any available drills
      if (sampleDrills.length < 3) {
        for (final drill in _guestDrills) {
          if (!sampleDrills.contains(drill) && sampleDrills.length < 3) {
            sampleDrills.add(drill);
          }
        }
      }
      
      // Convert to editable format with default values
      final editableDrills = sampleDrills.map((drill) => EditableDrillModel(
        drill: drill,
        setsDone: 0,
        totalSets: drill.sets > 0 ? drill.sets : 3,
        totalReps: drill.reps > 0 ? drill.reps : 10,
        totalDuration: drill.duration > 0 ? drill.duration : 10,
        isCompleted: false,
      )).toList();
      
      _editableSessionDrills.clear();
      _sessionDrills.clear();
      _editableSessionDrills.addAll(editableDrills);
      _sessionDrills.addAll(sampleDrills);
      
      if (kDebugMode) print('✅ Guest sample session loaded with ${sampleDrills.length} drills');
      
    } catch (e) {
      if (kDebugMode) print('❌ Error loading guest sample session: $e');
    }
  }

  // Load test session for development/testing
  Future<void> _loadTestSession() async {
    if (!AppConfig.useTestData) return;
    
    if (kDebugMode) print('📚 Loading test session with ${AppConfig.testDrillCount} drills');
    
    _setSearchState(LoadingState.loading);
    
    try {
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
      _setSearchState(LoadingState.idle);
    }
  }
  
  // Public method for debugging
  Future<void> loadTestSession() async {
    await _loadTestSession();
    notifyListeners();
  }

  // Placeholder for future persistence logic
  Future<void> _loadPersistedState() async {
    if (kDebugMode) print('📥 Loading persisted state (no-op for backend sync)');
  }
  
  // ===== BACKEND DATA LOADING SECTION =====
  // Load all user data from backend after authentication
  Future<void> loadBackendData() async {
    if (kDebugMode) {
      print('\n🚀 ===== STARTING loadBackendData() =====');
      print('📅 Timestamp: ${DateTime.now()}');
    }
    
    final userManager = UserManagerService.instance;
    final loadingService = LoadingStateService.instance;
    
    if (!userManager.userHasAccountHistory) {
      if (kDebugMode) print('⚠️ No user account history, skipping backend data load');
      _isInitialLoad = false;
      loadingService.completeLoading();
      notifyListeners();
      return;
    }
    
    _isInitialLoad = true;
    _isLoggingOut = false;
    notifyListeners();
    
    try {
      if (kDebugMode) print('📥 Loading backend data...');
      
      // Load all user data in sequence with progress updates
      loadingService.updateProgress(0.2, message: 'Loading your profile...');
      await _loadProgressDataFromBackend();
      
      loadingService.updateProgress(0.4, message: 'Fetching saved drills...');
      await _loadOrderedSessionDrillsFromBackend();
      
      loadingService.updateProgress(0.6, message: 'Loading training history...');
      await _loadDrillGroupsFromBackend();
      
      loadingService.updateProgress(0.8, message: 'Syncing preferences...');
      await _loadPreferencesFromBackend();
      
      loadingService.updateProgress(0.9, message: 'Loading custom drills...');
      await _loadCustomDrillsFromBackend();
      
      loadingService.updateProgress(1.0, message: 'Setup complete!');
      
      if (kDebugMode) print('✅ Successfully loaded all backend data');
    } catch (e) {
      if (kDebugMode) print('❌ Error loading backend data: $e');
      loadingService.updateMessage('Error loading data. Retrying...');
    } finally {
      _isInitialLoad = false;
      loadingService.completeLoading();
      notifyListeners();
    }
  }

  // Load user's progress history and streak data
  Future<void> _loadProgressDataFromBackend() async {
    try {
      if (kDebugMode) print('📥 Loading progress data from backend...');
      
      final completedSessions = await _progressSyncService.fetchCompletedSessions();
      
      // 🧠 Debug mental training sessions before clearing
      print('🧠 [MENTAL_TRAINING] Before clearing: ${_completedSessions.length} sessions in memory');
      final currentMentalSessions = _completedSessions.where((s) => s.sessionType == 'mental_training').length;
      print('🧠 [MENTAL_TRAINING] Current mental training sessions in memory: $currentMentalSessions');
      
      _completedSessions.clear();
      _completedSessions.addAll(completedSessions);
      
      // 🧠 Debug mental training sessions after loading
      print('🧠 [MENTAL_TRAINING] After loading: ${_completedSessions.length} sessions in memory');
      final newMentalSessions = _completedSessions.where((s) => s.sessionType == 'mental_training').length;
      print('🧠 [MENTAL_TRAINING] New mental training sessions in memory: $newMentalSessions');
      
      // 🧠 List all mental training sessions for debugging
      for (int i = 0; i < _completedSessions.length; i++) {
        final session = _completedSessions[i];
        if (session.sessionType == 'mental_training') {
          print('🧠 [MENTAL_TRAINING] Session $i: date=${session.date}, drills=${session.drills.length}, completed=${session.totalCompletedDrills}/${session.totalDrills}');
        }
      }
      
      final progressHistory = await _progressSyncService.updateProgressHistory();
      if (progressHistory != null) {
        _currentStreak = progressHistory['currentStreak'] ?? 0;
        _previousStreak = progressHistory['previousStreak'] ?? 0;
        _highestStreak = progressHistory['highestStreak'] ?? 0;
        _countOfFullyCompletedSessions = progressHistory['completedSessionsCount'] ?? 0;
        
        // ✅ NEW: Load backend-sourced progress metrics only
        _favoriteDrill = progressHistory['favoriteDrill'] ?? '';
        _drillsPerSession = (progressHistory['drillsPerSession'] ?? 0.0).toDouble();
        _minutesPerSession = (progressHistory['minutesPerSession'] ?? 0.0).toDouble();
        _totalTimeAllSessions = progressHistory['totalTimeAllSessions'] ?? 0;
        _dribblingDrillsCompleted = progressHistory['dribblingDrillsCompleted'] ?? 0;
        _firstTouchDrillsCompleted = progressHistory['firstTouchDrillsCompleted'] ?? 0;
        _passingDrillsCompleted = progressHistory['passingDrillsCompleted'] ?? 0;
        _shootingDrillsCompleted = progressHistory['shootingDrillsCompleted'] ?? 0;
        _defendingDrillsCompleted = progressHistory['defendingDrillsCompleted'] ?? 0;
        _goalkeepingDrillsCompleted = progressHistory['goalkeepingDrillsCompleted'] ?? 0;
        _fitnessDrillsCompleted = progressHistory['fitnessDrillsCompleted'] ?? 0;

        // ✅ NEW: Additional progress metrics
        _mostImprovedSkill = progressHistory['mostImprovedSkill'] ?? '';
        _uniqueDrillsCompleted = progressHistory['uniqueDrillsCompleted'] ?? 0;
        _beginnerDrillsCompleted = progressHistory['beginnerDrillsCompleted'] ?? 0;
        _intermediateDrillsCompleted = progressHistory['intermediateDrillsCompleted'] ?? 0;
        _advancedDrillsCompleted = progressHistory['advancedDrillsCompleted'] ?? 0;

        // ✅ NEW: Mental training metrics
        _mentalTrainingSessions = progressHistory['mentalTrainingSessions'] ?? 0;
        _totalMentalTrainingMinutes = progressHistory['totalMentalTrainingMinutes'] ?? 0;
      }
      
      if (kDebugMode) print('✅ Loaded progress data from backend');
    } catch (e) {
      if (kDebugMode) print('❌ Error loading progress data: $e');
    }
  }

  // Load user's current session drills with progress
  Future<void> _loadOrderedSessionDrillsFromBackend() async {
    try {
      if (kDebugMode) print('📥 Loading ordered session drills from backend...');
      
      final orderedDrills = await SessionDataSyncService.shared.fetchOrderedSessionDrills();
      
      if (orderedDrills.isNotEmpty) {
        _editableSessionDrills.clear();
        _sessionDrills.clear();
        
        _editableSessionDrills.addAll(orderedDrills);
        _sessionDrills.addAll(orderedDrills.map((ed) => ed.drill));
        
        // Update session state based on drill completion
        if (_editableSessionDrills.every((drill) => drill.isFullyCompleted)) {
          // Check if session was already completed today to prevent re-completion
          if (hasSessionsCompletedToday) {
            _setSessionState(SessionState.completed);
            if (kDebugMode) print('✅ Session already completed today - setting state to completed');
          } else {
            _setSessionState(SessionState.canComplete);
          }
        } else if (_editableSessionDrills.any((drill) => drill.setsDone > 0)) {
          _setSessionState(SessionState.inProgress);
        }
      }
      
      if (kDebugMode) print('✅ Loaded ${orderedDrills.length} ordered session drills');
    } catch (e) {
      if (kDebugMode) print('❌ Error loading ordered session drills: $e');
    }
  }

  // Load user's drill collections and liked drills
  Future<void> _loadDrillGroupsFromBackend() async {
    try {
      if (kDebugMode) print('📥 Loading drill groups from backend...');
      
      final backendGroups = await _drillGroupSyncService.getAllDrillGroups();
      
      if (backendGroups.isNotEmpty) {
        final localGroups = _drillGroupSyncService.convertToLocalModels(backendGroups);
        
        _savedDrillGroups.clear();
        _likedDrills.clear();
        
        // Separate liked drills from regular collections
        for (final group in localGroups) {
          if (group.isLikedDrillsGroup) {
            _likedDrills.addAll(group.drills);
          } else {
            _savedDrillGroups.add(group);
          }
        }
      }
      
      if (kDebugMode) print('✅ Loaded drill groups from backend');
    } catch (e) {
      if (kDebugMode) print('❌ Error loading drill groups: $e');
    }
  }

  // Load user's training preferences
  Future<void> _loadPreferencesFromBackend() async {
    try {
      if (kDebugMode) print('📥 Loading preferences from backend...');
      await _preferencesSyncService.loadPreferencesFromBackend();
      if (kDebugMode) print('✅ Loaded preferences from backend');
    } catch (e) {
      if (kDebugMode) print('❌ Error loading preferences: $e');
    }
  }

  // ✅ ADDED: Load user's custom drills from backend
  Future<void> _loadCustomDrillsFromBackend() async {
    try {
      if (kDebugMode) print('📥 Loading custom drills from backend...');
      
      // Fetch custom drills using the API service directly since CustomDrillService 
      // doesn't have a fetch method yet
      final response = await _apiService.get(
        '/api/custom-drills/',
        requiresAuth: true,
      );
      
      if (response.isSuccess && response.data != null) {
        // ✅ FIXED: Handle both List and Map response formats from API
        List<dynamic> drillsJson;
        
        if (response.data is List) {
          // Direct array response
          drillsJson = response.data as List<dynamic>;
        } else if (response.data is Map) {
          // Cast to Map first to avoid null safety issues
          final Map<String, dynamic> dataMap = response.data as Map<String, dynamic>;
          if (dataMap['data'] != null) {
            // Wrapped in data object
            drillsJson = dataMap['data'] as List<dynamic>;
          } else {
            if (kDebugMode) print('⚠️ Map response but no "data" key found');
            return;
          }
        } else {
          if (kDebugMode) print('⚠️ Unexpected response format for custom drills');
          return;
        }
        
        _customDrills.clear();
        
        for (final drillJson in drillsJson) {
          try {
            // Convert backend custom drill to local DrillModel
            final drill = DrillModel(
              id: drillJson['uuid'] ?? '',
              title: drillJson['title'] ?? 'Custom Drill',
              skill: _mapBackendSkillToFrontend(drillJson['primary_skill']?['category'] ?? 'general'),
              subSkills: _extractCustomDrillSubSkills(drillJson),
              sets: drillJson['sets'] ?? 3,
              reps: drillJson['reps'] ?? 10,
              duration: drillJson['duration'] ?? 10,
              description: drillJson['description'] ?? '',
              instructions: (drillJson['instructions'] as List<dynamic>?)?.cast<String>() ?? [],
              tips: (drillJson['tips'] as List<dynamic>?)?.cast<String>() ?? [],
              equipment: (drillJson['equipment'] as List<dynamic>?)?.cast<String>() ?? [],
              trainingStyle: _mapIntensityToTrainingStyle(drillJson['intensity'] ?? 'medium'),
              difficulty: _mapBackendDifficultyToFrontend(drillJson['difficulty'] ?? 'beginner'),
              videoUrl: drillJson['video_url'] ?? '',
              isCustom: true, // ✅ UPDATED: Set isCustom to true for custom drills
            );
            
            _customDrills.add(drill);
          } catch (e) {
            if (kDebugMode) print('⚠️ Error parsing custom drill: $e');
          }
        }
        
        if (kDebugMode) print('✅ Loaded ${_customDrills.length} custom drills from backend');
      } else {
        if (kDebugMode) print('⚠️ No custom drills found or error fetching: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error loading custom drills: $e');
    }
  }

  // ✅ ADDED: Helper method to extract sub-skills from custom drill data
  List<String> _extractCustomDrillSubSkills(Map<String, dynamic> drillJson) {
    final subSkills = <String>[];
    
    // ✅ UPDATED: For custom drills, only extract the primary sub-skill
    final primarySubSkill = drillJson['primary_skill']?['sub_skill'];
    if (primarySubSkill != null) {
      subSkills.add(_mapBackendSubSkillToFrontend(primarySubSkill));
    }
    
    // ✅ REMOVED: secondary_skills processing - custom drills only store primary category and subskill
    
    return subSkills;
  }

  // ✅ ADDED: Helper method to map intensity to training style for custom drills
  String _mapIntensityToTrainingStyle(String intensity) {
    switch (intensity.toLowerCase()) {
      case 'low':
        return 'low intensity';
      case 'medium':
        return 'medium intensity';
      case 'high':
        return 'high intensity';
      default:
        return 'medium intensity';
    }
  }

  // ✅ ADDED: Helper method to map backend difficulty to frontend
  String _mapBackendDifficultyToFrontend(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return 'Beginner';
      case 'intermediate':
        return 'Intermediate';
      case 'advanced':
        return 'Advanced';
      default:
        return 'Beginner';
    }
  }

  // Refresh all data from backend (pull-to-refresh)
  Future<void> refreshBackendData() async {
    if (AppConfig.useTestData) return;
    
    _setSearchState(LoadingState.refreshing);
    await loadBackendData();
    _setSearchState(LoadingState.idle);
    notifyListeners();
  }

  // Refresh just the progress data (for real-time updates)
  Future<void> refreshProgressHistoryFromBackend() async {
    if (AppConfig.useTestData) return;
    
    try {
      if (kDebugMode) print('🔄 Refreshing progress history from backend...');
      
      final progressHistory = await _progressSyncService.updateProgressHistory();
      if (progressHistory != null) {
        _currentStreak = progressHistory['currentStreak'] ?? 0;
        _previousStreak = progressHistory['previousStreak'] ?? 0;
        _highestStreak = progressHistory['highestStreak'] ?? 0;
        _countOfFullyCompletedSessions = progressHistory['completedSessionsCount'] ?? 0;
        
        // ✅ NEW: Refresh backend-sourced progress metrics only
        _favoriteDrill = progressHistory['favoriteDrill'] ?? '';
        _drillsPerSession = (progressHistory['drillsPerSession'] ?? 0.0).toDouble();
        _minutesPerSession = (progressHistory['minutesPerSession'] ?? 0.0).toDouble();
        _totalTimeAllSessions = progressHistory['totalTimeAllSessions'] ?? 0;
        _dribblingDrillsCompleted = progressHistory['dribblingDrillsCompleted'] ?? 0;
        _firstTouchDrillsCompleted = progressHistory['firstTouchDrillsCompleted'] ?? 0;
        _passingDrillsCompleted = progressHistory['passingDrillsCompleted'] ?? 0;
        _shootingDrillsCompleted = progressHistory['shootingDrillsCompleted'] ?? 0;
        _defendingDrillsCompleted = progressHistory['defendingDrillsCompleted'] ?? 0;
        _goalkeepingDrillsCompleted = progressHistory['goalkeepingDrillsCompleted'] ?? 0;
        _fitnessDrillsCompleted = progressHistory['fitnessDrillsCompleted'] ?? 0;

        // ✅ NEW: Refresh additional progress metrics
        _mostImprovedSkill = progressHistory['mostImprovedSkill'] ?? '';
        _uniqueDrillsCompleted = progressHistory['uniqueDrillsCompleted'] ?? 0;
        _beginnerDrillsCompleted = progressHistory['beginnerDrillsCompleted'] ?? 0;
        _intermediateDrillsCompleted = progressHistory['intermediateDrillsCompleted'] ?? 0;
        _advancedDrillsCompleted = progressHistory['advancedDrillsCompleted'] ?? 0;

        // ✅ NEW: Refresh mental training metrics
        _mentalTrainingSessions = progressHistory['mentalTrainingSessions'] ?? 0;
        _totalMentalTrainingMinutes = progressHistory['totalMentalTrainingMinutes'] ?? 0;
        
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error refreshing progress history: $e');
    }
  }

  // ✅ ADDED: Refresh custom drills from backend (can be called after creating new drill)
  Future<void> refreshCustomDrillsFromBackend() async {
    if (AppConfig.useTestData) return;
    
    try {
      if (kDebugMode) print('🔄 Refreshing custom drills from backend...');
      await _loadCustomDrillsFromBackend();
      notifyListeners();
      if (kDebugMode) print('✅ Custom drills refreshed successfully');
    } catch (e) {
      if (kDebugMode) print('❌ Error refreshing custom drills: $e');
    }
  }

  // ✅ ADDED: Refresh drill groups from backend (can be called after custom drill updates)
  Future<void> refreshDrillGroupsFromBackend() async {
    if (AppConfig.useTestData) return;
    
    try {
      if (kDebugMode) print('🔄 Refreshing drill groups from backend...');
      await _loadDrillGroupsFromBackend();
      notifyListeners();
      if (kDebugMode) print('✅ Drill groups refreshed successfully');
    } catch (e) {
      if (kDebugMode) print('❌ Error refreshing drill groups: $e');
    }
  }

  // ✅ ADDED: Delete a custom drill
  Future<bool> deleteCustomDrill(String drillId) async {
    if (AppConfig.useTestData) return true;
    
    try {
      if (kDebugMode) print('🗑️ Deleting custom drill: $drillId');
      
      final success = await _customDrillService.deleteCustomDrill(drillId);
      
      if (success) {
        // Remove from local list
        _customDrills.removeWhere((drill) => drill.id == drillId);
        notifyListeners();
        if (kDebugMode) print('✅ Custom drill deleted successfully');
        return true;
      } else {
        if (kDebugMode) print('❌ Failed to delete custom drill');
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error deleting custom drill: $e');
      return false;
    }
  }

  // ===== CUSTOM DRILL LOOKUP METHODS =====
  // Methods to get updated drill data for reactive UI updates
  
  /// Get custom drill by ID from app state
  /// Returns null if drill is not found in the custom drills list
  DrillModel? getCustomDrillById(String drillId) {
    try {
      return _customDrills.firstWhere((drill) => drill.id == drillId);
    } catch (e) {
      // Drill not found
      return null;
    }
  }

  /// Get updated drill data - for custom drills, gets latest from app state
  /// For non-custom drills, returns the original drill unchanged
  /// This ensures UI always shows the most current drill data
  DrillModel getUpdatedDrill(DrillModel originalDrill) {
    if (originalDrill.isCustom) {
      // For custom drills, get the latest version from app state
      final updatedDrill = getCustomDrillById(originalDrill.id);
      return updatedDrill ?? originalDrill; // Fallback to original if not found
    }
    // For non-custom drills, return as-is
    return originalDrill;
  }
  
  // ===== STATE MANAGEMENT UTILITIES =====
  // Internal state management helpers
  void _setSearchState(LoadingState state) {
    _searchState = state;
    if (state == LoadingState.loading || state == LoadingState.refreshing) {
      _clearError();
    }
  }
  
  void _setSessionState(SessionState state) {
    if (kDebugMode) print('🔄 Session state: ${_sessionState} → $state');
    _sessionState = state;
    notifyListeners();
  }
  
  void _setPreferencesSyncState(SyncState state) {
    _preferencesSyncState = state;
    notifyListeners();
  }
  
  void _setError(String error) {
    _lastError = error;
    if (kDebugMode) print('❌ AppState Error: $error');
  }
  
  void _clearError() {
    _lastError = null;
  }

  // ===== SESSION COMPLETION SECTION =====
  // Handle completion of training sessions
  Future<void> addCompletedSession(CompletedSession session) async {
    // ✅ ADDED: Guest mode check - don't save progress for guests
    if (isGuestMode) {
      if (kDebugMode) {
        print('👤 Guest mode detected - skipping progress save');
        print('   Session type: ${session.sessionType}');
        print('   Date: ${session.date}');
        print('   Drills: ${session.drills.length}');
      }
      return; // Don't save progress for guest users
    }
    
    _completedSessions.add(session);
        
    if (kDebugMode) {
      print('✅ CompletedSession saved!');
      print('  Date: ${session.date}');
      print('  Drills: ${session.drills.length}');
      print('  Total Completed: ${session.totalCompletedDrills}');
      print('  Total Drills: ${session.totalDrills}');
    }
    
    // Immediately sync to backend
    await _syncCompletedSessionImmediate(session);
    notifyListeners();
  }

  // Immediately sync completed session to backend and update streaks
  Future<void> _syncCompletedSessionImmediate(CompletedSession session) async {
    await _syncCoordinator.executeImmediate('session_completion', () async {
      try {
        if (kDebugMode) print('🔄 Starting immediate session sync to backend...');
        
        final syncSuccess = await _progressSyncService.syncCompletedSession(
          date: session.date,
          drills: session.drills,
          totalCompleted: session.totalCompletedDrills,
          total: session.totalDrills,
          type: session.sessionType
        );
        
        if (syncSuccess) {
          if (kDebugMode) print('✅ Session sync successful, refreshing progress...');
          await refreshProgressHistoryFromBackend();
        }
      } catch (e) {
        if (kDebugMode) print('❌ Error in session sync: $e');
      }
    });
  }

  // Complete current session - main entry point for session completion
  Future<void> completeSession() async {
    if (_sessionState == SessionState.completing || _sessionState == SessionState.completed) {
      if (kDebugMode) print('⚠️ Session already completing/completed');
      return;
    }
    
    if (!isSessionComplete) {
      if (kDebugMode) print('⚠️ Cannot complete session - not all drills finished');
      return;
    }
    
    await _completeSessionOnce();
  }
  
  // Internal session completion logic - ensures it only happens once
  Future<void> _completeSessionOnce() async {
    _setSessionState(SessionState.completing);
    
    try {
      final completedSession = CompletedSession(
        date: DateTime.now(),
        drills: List.from(_editableSessionDrills),
        totalCompletedDrills: _editableSessionDrills.where((d) => d.isFullyCompleted).length,
        totalDrills: _editableSessionDrills.length,
        sessionType: 'training',
      );
      
      await _addCompletedSessionWithSync(completedSession);
      _setSessionState(SessionState.completed);
      
      if (kDebugMode) print('✅ Session completed successfully');
    } catch (e) {
      if (kDebugMode) print('❌ Error completing session: $e');
      _setSessionState(SessionState.canComplete); // Revert state on error
    }
  }

  // Add completed session and sync to backend
  Future<void> _addCompletedSessionWithSync(CompletedSession session) async {
    // ✅ ADDED: Guest mode check - don't save progress for guests
    if (isGuestMode) {
      if (kDebugMode) {
        print('👤 Guest mode detected - skipping session sync');
        print('   Session type: ${session.sessionType}');
        print('   Date: ${session.date}');
        print('   Drills: ${session.drills.length}');
      }
      return; // Don't save progress for guest users
    }
    
    _completedSessions.add(session);
    await _syncCompletedSessionImmediate(session);
  }

  // Start a new session
  void startSession() {
    _setSessionState(SessionState.inProgress);
  }

  // Get next drill that hasn't been completed
  EditableDrillModel? getNextIncompleteDrill() {
    try {
      return _editableSessionDrills.firstWhere((drill) => !drill.isCompleted);
    } catch (e) {
      return null;
    }
  }
  
  // ===== SEARCH FUNCTIONALITY SECTION =====
  // Drill search with pagination and filtering
  Future<void> searchDrillsWithPagination({
    String? query,
    String? skill,
    String? difficulty,
    String? trainingStyle,
    List<String>? equipment,
    int? maxDuration,
    bool loadMore = false,
  }) async {
    
    final operationKey = loadMore ? 'search_load_more' : 'search_new';
    
    if (_syncCoordinator.isOperationActive(operationKey)) {
      if (kDebugMode) print('🔄 Search operation already in progress');
      return;
    }
    
    if (!loadMore) {
      // Debounce new searches to avoid spamming API
      _syncCoordinator.scheduleSync(operationKey, _searchDebounceDelay, () async {
        await _performSearch(
          query: query,
          skill: skill,
          difficulty: difficulty,
          trainingStyle: trainingStyle,
          equipment: equipment,
          maxDuration: maxDuration,
          loadMore: false,
        );
      });
    } else {
      // Load more results immediately
      await _syncCoordinator.executeImmediate(operationKey, () async {
        await _performSearch(
          query: query,
          skill: skill,
          difficulty: difficulty,
          trainingStyle: trainingStyle,
          equipment: equipment,
          maxDuration: maxDuration,
          loadMore: true,
        );
      });
    }
  }

  // Internal search implementation - handles different data sources
  Future<void> _performSearch({
    String? query,
    String? skill,
    String? difficulty,
    String? trainingStyle,
    List<String>? equipment,
    int? maxDuration,
    bool loadMore = false,
  }) async {
    
    if (!loadMore) {
      // Reset pagination for new search
      _currentSearchPage = 1;
      _searchResults.clear();
      _lastSearchQuery = query;
      _lastSearchSkill = skill;
      _lastSearchDifficulty = difficulty;
      _setSearchState(LoadingState.loading);
    } else {
      if (!_hasMoreSearchResults) return;
      _currentSearchPage++;
      _setSearchState(LoadingState.loadingMore);
    }
    
    _clearError();
    
    try {
      // Handle different data sources based on app configuration
      if (isGuestMode) {
        // Guest users get limited search results  
        final pageSize = 20;
        final guestDrills = await _guestDrillService.searchGuestDrills(
          query: query ?? _lastSearchQuery,
          category: skill ?? _lastSearchSkill,
          difficulty: difficulty ?? _lastSearchDifficulty,
          page: _currentSearchPage,
          limit: pageSize,
        );
        
        if (loadMore) {
          _searchResults.addAll(guestDrills);
        } else {
          _searchResults = guestDrills;
        }
        
        _hasMoreSearchResults = guestDrills.length == pageSize;
        _totalSearchResults = _searchResults.length + (_hasMoreSearchResults ? 1 : 0);
        _totalSearchPages = (_totalSearchResults / pageSize).ceil();
        
      } else if (AppConfig.useTestData) {
        // Test data search for development
        final filters = DrillSearchFilters(
          query: query ?? _lastSearchQuery,
          skill: skill ?? _lastSearchSkill,
          difficulty: difficulty ?? _lastSearchDifficulty,
          trainingStyle: trainingStyle,
          equipment: equipment,
          maxDuration: maxDuration,
          page: _currentSearchPage,
          pageSize: 20,
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
        
      } else {
        // Production backend search
        final response = await _drillApiService.searchDrills(
          query: query ?? _lastSearchQuery ?? '',
          category: skill ?? _lastSearchSkill,
          difficulty: difficulty ?? _lastSearchDifficulty,
          page: _currentSearchPage,
          limit: 20,
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
      }
      
    } catch (e) {
      _setError('Search failed: $e');
    } finally {
      _setSearchState(LoadingState.idle);
    }
    
    notifyListeners();
  }
  
  // Load more search results for pagination
  Future<void> loadMoreSearchResults() async {
    await searchDrillsWithPagination(loadMore: true);
  }
  
  // Refresh current search results
  Future<void> refreshSearch() async {
    await searchDrillsWithPagination(
      query: _lastSearchQuery,
      skill: _lastSearchSkill,
      difficulty: _lastSearchDifficulty,
    );
  }

  // ===== DRILL API METHODS =====
  // Get drills by specific skill category
  Future<List<DrillModel>> getDrillsBySkillAsync(String skill) async {
    final result = await _syncCoordinator.executeImmediateWithResult<List<DrillModel>>('get_drills_by_skill', () async {
      _setSearchState(LoadingState.loading);
      _clearError();
      
      try {
        if (isGuestMode) {
          final guestDrills = await _guestDrillService.searchGuestDrills(
            category: skill,
            limit: 10,
          );
          return guestDrills;
        } else if (AppConfig.useTestData) {
          return await TestDataService.getDrillsBySkill(skill);
        } else {
          final response = await _drillApiService.getDrillsByCategory(skill);
          return _drillApiService.convertToLocalModels(response);
        }
      } catch (e) {
        _setError('Failed to load $skill drills: $e');
        return <DrillModel>[];
      } finally {
        _setSearchState(LoadingState.idle);
        notifyListeners();
      }
    });
    return result ?? <DrillModel>[];
  }
  
  // Get popular/trending drills
  Future<List<DrillModel>> getPopularDrillsAsync() async {
    final result = await _syncCoordinator.executeImmediateWithResult<List<DrillModel>>('get_popular_drills', () async {
      _setSearchState(LoadingState.loading);
      _clearError();
      
      try {
        if (isGuestMode) {
          return _guestDrills.take(8).toList();
        } else if (AppConfig.useTestData) {
          return await TestDataService.getPopularDrills();
        } else {
          final response = await _drillApiService.searchDrills(limit: 10);
          return _drillApiService.convertToLocalModels(response.items);
        }
      } catch (e) {
        _setError('Failed to load popular drills: $e');
        return <DrillModel>[];
      } finally {
        _setSearchState(LoadingState.idle);
        notifyListeners();
      }
    });
    return result ?? <DrillModel>[];
  }

  // ===== USER PREFERENCES SECTION =====
  // Update user preferences and trigger session regeneration
  void updateTimeFilter(String? time) {
    // ✅ IMPROVED: Don't set loading immediately - let debounced sync handle it
    _preferences.selectedTime = time;
    if (_autoGenerateSession) {
      _autoGenerateSessionDrills();
    }
    notifyListeners();
    _schedulePreferencesSync();
  }
  
  void updateEquipmentFilter(Set<String> equipment) {
    // ✅ IMPROVED: Don't set loading immediately - let debounced sync handle it
    _preferences.selectedEquipment = equipment;
    if (_autoGenerateSession) {
      _autoGenerateSessionDrills();
    }
    notifyListeners();
    _schedulePreferencesSync();
  }
  
  void updateTrainingStyleFilter(String? style) {
    // ✅ IMPROVED: Don't set loading immediately - let debounced sync handle it
    _preferences.selectedTrainingStyle = style;
    if (_autoGenerateSession) {
      _autoGenerateSessionDrills();
    }
    notifyListeners();
    _schedulePreferencesSync();
  }
  
  void updateLocationFilter(String? location) {
    // ✅ IMPROVED: Don't set loading immediately - let debounced sync handle it
    _preferences.selectedLocation = location;
    if (_autoGenerateSession) {
      _autoGenerateSessionDrills();
    }
    notifyListeners();
    _schedulePreferencesSync();
  }
  
  void updateDifficultyFilter(String? difficulty) {
    // ✅ IMPROVED: Don't set loading immediately - let debounced sync handle it
    _preferences.selectedDifficulty = difficulty;
    if (_autoGenerateSession) {
      _autoGenerateSessionDrills();
    }
    notifyListeners();
    _schedulePreferencesSync();
  }
  
  void updateSkillsFilter(Set<String> skills) {
    // ✅ IMPROVED: Don't set loading immediately - let debounced sync handle it
    _preferences.selectedSkills = skills;
    notifyListeners();
    _schedulePreferencesSync();
  }

  // Update all preferences at once
  void updateUserPreferences(UserPreferences preferences) {
    _preferences = preferences;
    notifyListeners();
  }

  // Update session drills from preferences sync service
  void updateOrderedSessionDrillsThroughPreferences(List<EditableDrillModel> drills) {
    _editableSessionDrills.clear();
    _sessionDrills.clear();
    
    _editableSessionDrills.addAll(drills);
    _sessionDrills.addAll(drills.map((ed) => ed.drill));
    
    // Update session state based on completion
    if (drills.isNotEmpty && drills.any((drill) => !drill.isCompleted)) {
      if (drills.every((drill) => drill.isFullyCompleted)) {
        _setSessionState(SessionState.canComplete);
      } else if (drills.any((drill) => drill.setsDone > 0)) {
        _setSessionState(SessionState.inProgress);
      } else {
        _setSessionState(SessionState.idle);
      }
    }
    
    _setPreferencesSyncState(SyncState.idle);
    notifyListeners();
  }

  // Schedule preferences sync with backend
  void _schedulePreferencesSync() {
    _syncCoordinator.scheduleSync('preferences_sync', _preferencesSyncDebounce, () async {
      // ✅ IMPROVED: Set loading state only when actual sync starts (after debounce)
      _setPreferencesSyncState(SyncState.syncing);
      
      try {
        if (isGuestMode) {
          if (kDebugMode) print('👤 Guest mode detected - using public session generation');
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
        }
      } finally {
        // ✅ IMPROVED: Always clear loading state when sync completes/fails
        _setPreferencesSyncState(SyncState.idle);
      }
    });
  }

  // Generate session for guest users using public API
  Future<void> _generateGuestSession() async {
    if (!isGuestMode) return;
    
    try {
      if (kDebugMode) print('👤 Generating guest session with preferences');
      
      final preferencesData = {
        'duration': _mapTimeToMinutes(_preferences.selectedTime),
        'available_equipment': _preferences.selectedEquipment.toList(),
        'training_style': _preferences.selectedTrainingStyle ?? 'medium_intensity',
        'training_location': _preferences.selectedLocation ?? 'full_field',
        'difficulty': _preferences.selectedDifficulty ?? 'beginner',
        'target_skills': _preferences.selectedSkills.toList(),
      };
      
      final requestData = {'preferences': preferencesData};
      
      final response = await _apiService.post(
        '/public/session/generate',
        body: requestData,
        requiresAuth: false,
      );
      
      if (response.isSuccess && response.data != null) {
        final sessionData = response.data!['data'];
        if (sessionData != null && sessionData['drills'] != null) {
          final drillsJson = sessionData['drills'] as List<dynamic>;
          
          // Convert backend drill format to local models
          final editableDrills = drillsJson.map((drillJson) {
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
              isCustom: false, // ✅ ADDED: Set isCustom to false for guest drills
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
          
          _editableSessionDrills.clear();
          _sessionDrills.clear();
          _editableSessionDrills.addAll(editableDrills);
          _sessionDrills.addAll(editableDrills.map((ed) => ed.drill));
          
          if (kDebugMode) print('✅ Guest session updated with ${editableDrills.length} drills');
        }
      }
      
    } catch (e) {
      if (kDebugMode) print('❌ Error generating guest session: $e');
    } finally {
      // ✅ REMOVED: Loading state now handled by parent sync method
      notifyListeners();
    }
  }

  // Helper methods for mapping backend data to frontend models
  int _mapTimeToMinutes(String? timePreference) {
    switch (timePreference) {
      case '15min': return 15;
      case '30min': return 30;
      case '45min': return 45;
      case '1h': return 60;
      case '1h30': return 90;
      case '2h+': return 120;
      default: return 30;
    }
  }

  String _mapBackendSkillToFrontend(String backendSkill) {
    const skillMap = {
      'passing': 'Passing',
      'shooting': 'Shooting',
      'dribbling': 'Dribbling',
      'first_touch': 'First Touch',
      'defending': 'Defending',
      'goalkeeping': 'Goalkeeping',
      'fitness': 'Fitness',
      'general': 'General',
    };
    return skillMap[backendSkill.toLowerCase()] ?? 'General';
  }

  List<String> _extractSubSkills(Map<String, dynamic> drillJson) {
    final subSkills = <String>[];
    
    final primarySubSkill = drillJson['primary_skill']?['sub_skill'];
    if (primarySubSkill != null) {
      subSkills.add(_mapBackendSubSkillToFrontend(primarySubSkill));
    }
    
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

  String _mapBackendSubSkillToFrontend(String backendSubSkill) {
    const subSkillMap = {
      'close_control': 'Close control',
      'speed_dribbling': 'Speed dribbling',
      '1v1_moves': '1v1 moves',
      'change_of_direction': 'Change of direction',
      'ball_mastery': 'Ball mastery',
      'ground_control': 'Ground control',
      'aerial_control': 'Aerial control',
      'turn_with_ball': 'Turn with ball',
      'touch_and_move': 'Touch and move',
      'juggling': 'Juggling',
      'short_passing': 'Short passing',
      'long_passing': 'Long passing',
      'one_touch_passing': 'One touch passing',
      'technique': 'Technique',
      'passing_with_movement': 'Passing with movement',
      'power_shots': 'Power shots',
      'finesse_shots': 'Finesse shots',
      'first_time_shots': 'First time shots',
      '1v1_to_shoot': '1v1 to shoot',
      'shooting_on_the_run': 'Shooting on the run',
      'volleying': 'Volleying',
      'tackling': 'Tackling',
      'marking': 'Marking',
      'intercepting': 'Intercepting',
      'positioning': 'Positioning',
      'agility': 'Agility',
      'aerial_defending': 'Aerial defending',
      'hand_eye_coordination': 'Hand eye coordination',
      'diving': 'Diving',
      'reflexes': 'Reflexes',
      'shot_stopping': 'Shot stopping',
      'catching': 'Catching',
      'general': 'General',
    };
    return subSkillMap[backendSubSkill.toLowerCase()] ?? backendSubSkill;
  }

  // ===== SESSION DRILL MANAGEMENT SECTION =====
  // Manage drills in current session
  bool addDrillToSession(DrillModel drill) {
    // Check if session already has 10 drills (limit)
    if (_sessionDrills.length >= 10) {
      return false; // Cannot add more drills
    }
    
    if (!_sessionDrills.any((d) => d.id == drill.id)) {
      if (kDebugMode) {
        print('🔍 [ADD_DRILL] Adding drill to session: ${drill.title}');
        print('🔍 [ADD_DRILL] Drill ID: ${drill.id}');
        print('🔍 [ADD_DRILL] isCustom: ${drill.isCustom}');
      }
      
      _sessionDrills.add(drill);
      
      // Create editable version with default values
      final editableDrill = EditableDrillModel(
        drill: drill,
        setsDone: 0,
        totalSets: drill.sets > 0 ? drill.sets : 3,
        totalReps: drill.reps > 0 ? drill.reps : 10,
        totalDuration: drill.duration > 0 ? drill.duration : 5,
        isCompleted: false,
      );
      
      if (kDebugMode) {
        print('🔍 [ADD_DRILL] Created EditableDrillModel');
        print('🔍 [ADD_DRILL] EditableDrill isCustom: ${editableDrill.drill.isCustom}');
      }
      
      _editableSessionDrills.add(editableDrill);
      
      // Reset session state when adding new drills
      if (_sessionState == SessionState.completed) {
        _setSessionState(SessionState.idle);
      }
      
      notifyListeners();
      _scheduleSessionDrillsSync();
      return true; // Successfully added drill
    }
    
    return false; // Drill already exists in session
  }
  
  void removeDrillFromSession(DrillModel drill) {
    _sessionDrills.removeWhere((d) => d.id == drill.id);
    _editableSessionDrills.removeWhere((ed) => ed.drill.id == drill.id);
    notifyListeners();
    _scheduleSessionDrillsSync();
  }
  
  // Reorder drills in session (drag and drop)
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
  
  // Clear all drills from session
  void clearSession() {
    _sessionDrills.clear();
    _editableSessionDrills.clear();
    _setSessionState(SessionState.idle);
    notifyListeners();
    _scheduleSessionDrillsSync();
  }
  
  // Update drill parameters in session
  void updateDrillInSession(String drillId, {int? sets, int? reps, int? duration}) {
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
        isCustom: currentDrill.isCustom, // ✅ FIXED: Preserve the original isCustom value
      );
      
      _sessionDrills[drillIndex] = updatedDrill;
    }
    
    // Update editable version
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
  
  // Update drill progress during session
  void updateDrillProgress(String drillId, {int? setsDone, bool? isCompleted}) {
    final editableDrillIndex = _editableSessionDrills.indexWhere((drill) => drill.drill.id == drillId);
    if (editableDrillIndex != -1) {
      final currentEditableDrill = _editableSessionDrills[editableDrillIndex];
      _editableSessionDrills[editableDrillIndex] = currentEditableDrill.copyWith(
        setsDone: setsDone,
        isCompleted: isCompleted,
      );
      
      // Update session state based on overall progress
      if (isSessionComplete && _sessionState != SessionState.completed) {
        _setSessionState(SessionState.canComplete);
      } else if (hasSessionProgress && _sessionState == SessionState.idle) {
        _setSessionState(SessionState.inProgress);
      }
      
      notifyListeners();
      _scheduleSessionDrillsSync();
    }
  }
  
  // Schedule sync of session drills to backend
  void _scheduleSessionDrillsSync() {
    if (isGuestMode) {
      if (kDebugMode) print('👤 Skipping session drills sync for guest user');
      return;
    }
    
    _syncCoordinator.scheduleSync('session_drills_sync', _sessionDrillsSyncDebounce, () async {
      await SessionDataSyncService.shared.syncOrderedSessionDrills(_editableSessionDrills);
    });
  }

  // ===== DRILL GROUPS MANAGEMENT SECTION =====
  // Manage user's drill collections
  Future<void> createDrillGroup(String name, String description) async {
    // Create a temporary group with a local ID
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final newGroup = DrillGroup(
      id: tempId,
      name: name,
      description: description,
      drills: [],
      createdAt: DateTime.now(),
    );
    _savedDrillGroups.add(newGroup);
    notifyListeners();

    // Immediately create the group on the backend
    final backendGroup = await _drillGroupSyncService.createDrillGroup(
      name: name,
      description: description,
      drillUuids: [],
      isLikedGroup: false,
    );
    if (backendGroup != null) {
      // Update the local group ID to match the backend's
      final groupIndex = _savedDrillGroups.indexWhere((g) => g.id == tempId);
      if (groupIndex != -1) {
        _savedDrillGroups[groupIndex] = _savedDrillGroups[groupIndex].copyWith(
          id: backendGroup.id.toString(),
        );
        notifyListeners();
      }
    }
    _scheduleDrillGroupsSync();
  }
  
  void deleteDrillGroup(String groupId) {
    final groupIndex = _savedDrillGroups.indexWhere((group) => group.id == groupId);
    if (groupIndex != -1) {
      final group = _savedDrillGroups[groupIndex];
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
      _scheduleDrillGroupsSync();
    }
  }
  
  // Add single drill to collection
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
        _scheduleDrillGroupsSync();
      }
    }
  }
  
  // Add multiple drills to collection
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
      _scheduleDrillGroupsSync();
    }
  }
  
  // Get drill group by ID
  DrillGroup? getDrillGroup(String groupId) {
    try {
      return _savedDrillGroups.firstWhere((g) => g.id == groupId);
    } catch (e) {
      return null;
    }
  }
  
  // Toggle drill like status
  void toggleLikedDrill(DrillModel drill) {
    if (_likedDrills.contains(drill)) {
      _likedDrills.remove(drill);
    } else {
      _likedDrills.add(drill);
    }
    notifyListeners();
    _scheduleDrillGroupsSync();
  }
  
  // Check if drill is liked
  bool isDrillLiked(DrillModel drill) {
    return _likedDrills.contains(drill);
  }
  
  // Check if drill is saved in any collection
  bool isDrillSavedInAnyCollection(DrillModel drill) {
    return _savedDrillGroups.any((group) => 
      group.drills.any((d) => d.id == drill.id)
    );
  }
  
  // Check if drill is in current session
  bool isDrillInSession(DrillModel drill) {
    return _sessionDrills.any((d) => d.id == drill.id);
  }
  
  // Virtual liked drills group
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

  // Schedule sync of drill groups to backend
  void _scheduleDrillGroupsSync() {
    if (isGuestMode) {
      if (kDebugMode) print('👤 Skipping drill groups sync for guest user');
      return;
    }
    
    _syncCoordinator.scheduleSync('drill_groups_sync', _drillGroupsSyncDebounce, () async {
      await _drillGroupSyncService.syncAllDrillGroups(
        savedGroups: _savedDrillGroups,
        likedGroup: likedDrillsGroup,
      );
    });
  }

  // ===== AUTO GENERATION SECTION =====
  // Automatic session generation based on preferences
  void toggleAutoGenerate(bool value) {
    _autoGenerateSession = value;
    if (value) {
      _autoGenerateSessionDrills();
    }
    notifyListeners();
  }
  
  // Generate session drills based on current preferences
  void _autoGenerateSessionDrills() {
    final filtered = filteredDrills;
    _sessionDrills.clear();
    
    final maxDrills = _getMaxDrillsForTime();
    final drillsToAdd = filtered.take(maxDrills).toList();
    
    _sessionDrills.addAll(drillsToAdd);
  }
  
  // Get max drills based on time preference
  int _getMaxDrillsForTime() {
    switch (_preferences.selectedTime) {
      case '15min': return 2;
      case '30min': return 3;
      case '45min':
      case '1h': return 4;
      case '1h30': return 5;
      case '2h+': return 6;
      default: return 3;
    }
  }

  // ===== FILTER AND SEARCH HELPERS =====
  // Filter drills based on current preferences
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
  
  // Get drills not currently in session
  List<DrillModel> get drillsNotInSession {
    return _availableDrills.where((drill) => !isDrillInSession(drill)).toList();
  }
  
  // Search drills by query string
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
  
  // Filter drills by skill category
  List<DrillModel> filterDrillsBySkill(String skill) {
    return drillsNotInSession.where((drill) {
      return drill.skill.toLowerCase() == skill.toLowerCase() ||
             drill.subSkills.any((subSkill) => 
               subSkill.toLowerCase().contains(skill.toLowerCase()));
    }).toList();
  }
  
  // ===== RESET AND DEBUG METHODS =====
  // Reset drill progress for new session
  void resetDrillProgressForNewSession() {
    if (kDebugMode) print('🔄 Resetting drill progress for new session...');
    
    for (int i = 0; i < _editableSessionDrills.length; i++) {
      final currentDrill = _editableSessionDrills[i];
      _editableSessionDrills[i] = currentDrill.copyWith(
        setsDone: 0,
        isCompleted: false,
      );
    }
    
    _setSessionState(SessionState.idle);
    _scheduleSessionDrillsSync();
    notifyListeners();
    
    if (kDebugMode) print('✅ Drill progress reset complete');
  }

  // Debug methods for testing streaks
  void resetStreak() {
    _currentStreak = 0;
    _previousStreak = 0;
    _highestStreak = 0;
    _countOfFullyCompletedSessions = 0;
    
    if (kDebugMode) print('🧪 [DEBUG] Streaks reset: current=0, previous=0, highest=0, sessions=0');
    notifyListeners();
  }

  void incrementStreak() {
    _previousStreak = _currentStreak;
    _currentStreak += 1;
    _highestStreak = _currentStreak > _highestStreak ? _currentStreak : _highestStreak;
    
    if (kDebugMode) print('🧪 [DEBUG] Streak incremented: current=$_currentStreak, previous=$_previousStreak, highest=$_highestStreak');
    notifyListeners();
  }

  // Add fake completed sessions for testing
  void addCompletedSessions(int count) {
    final now = DateTime.now();
    
    for (int i = 0; i < count; i++) {
      final sessionDate = now.subtract(Duration(days: count - i));
      
      final testSession = CompletedSession(
        date: sessionDate,
        drills: [
          EditableDrillModel(
            drill: _mockDrills.first,
            setsDone: 1,
            totalSets: 1,
            totalReps: 10,
            totalDuration: 5,
            isCompleted: true,
          ),
        ],
        totalCompletedDrills: 1,
        totalDrills: 1,
        sessionType: 'training',
      );
      
      _completedSessions.add(testSession);
    }
    
    _countOfFullyCompletedSessions = _completedSessions.length;
    _recalculateStreaksFromSessions();
    
    if (kDebugMode) {
      print('🧪 [DEBUG] Added $count completed sessions');
      print('   - Total sessions: $_countOfFullyCompletedSessions');
      print('   - Current streak: $_currentStreak');
      print('   - Highest streak: $_highestStreak');
    }
    
    notifyListeners();
  }

  // Recalculate streaks from completed sessions
  void _recalculateStreaksFromSessions() {
    if (_completedSessions.isEmpty) {
      _currentStreak = 0;
      _previousStreak = 0;
      _highestStreak = 0;
      return;
    }

    final sortedSessions = _completedSessions.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    int currentStreak = 0;
    int maxStreak = 0;
    int tempStreak = 1;
    
    // Get unique session dates
    final sessionDates = <DateTime>{};
    for (final session in sortedSessions) {
      final sessionDate = DateTime(session.date.year, session.date.month, session.date.day);
      sessionDates.add(sessionDate);
    }
    
    final sortedDates = sessionDates.toList()..sort();
    
    // Calculate max streak from historical data
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
    
    // Calculate current streak from today backwards
    DateTime checkDate = todayDate;
    while (sessionDates.contains(checkDate)) {
      currentStreak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    
    // If no session today, check yesterday for active streak
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

  // ===== CLEANUP SECTION =====
  // Clear user-specific data (for logout)
  void clearUserData() {
    if (kDebugMode) print('🧹 Clearing user data...');
    
    _editableSessionDrills.clear();
    _sessionDrills.clear();
    _completedSessions.clear();
    _currentStreak = 0;
    _previousStreak = 0;
    _highestStreak = 0;
    _countOfFullyCompletedSessions = 0;
    _savedDrillGroups.clear();
    _likedDrills.clear();
    // ✅ ADDED: Clear custom drills on logout
    _customDrills.clear();
    
    // ✅ NEW: Reset backend-sourced progress metrics only
    _favoriteDrill = '';
    _drillsPerSession = 0.0;
    _minutesPerSession = 0.0;
    _totalTimeAllSessions = 0;
    _dribblingDrillsCompleted = 0;
    _firstTouchDrillsCompleted = 0;
    _passingDrillsCompleted = 0;
    _shootingDrillsCompleted = 0;
    _defendingDrillsCompleted = 0;
    _goalkeepingDrillsCompleted = 0;
    _fitnessDrillsCompleted = 0;

    // ✅ NEW: Reset additional progress metrics
    _mostImprovedSkill = '';
    _uniqueDrillsCompleted = 0;
    _beginnerDrillsCompleted = 0;
    _intermediateDrillsCompleted = 0;
    _advancedDrillsCompleted = 0;
    
    // ✅ NEW: Reset mental training metrics
    _mentalTrainingSessions = 0;
    _totalMentalTrainingMinutes = 0;
    
    // Don't reset session state if it was completed - preserve completion status
    if (_sessionState != SessionState.completed) {
      _setSessionState(SessionState.idle);
    } else {
      if (kDebugMode) print('🔒 Preserving completed session state during logout');
    }
    
    _setPreferencesSyncState(SyncState.idle);
    _setSearchState(LoadingState.idle);
    
    _syncCoordinator.cancelAll();
    
    if (kDebugMode) print('✅ User data cleared');
  }

  // Clear all app data (for fresh start)
  Future<void> clearAllData() async {
    _preferences = UserPreferences();
    _autoGenerateSession = true;
    
    _sessionDrills.clear();
    _editableSessionDrills.clear();
    _savedDrillGroups.clear();
    _likedDrills.clear();
    // ✅ ADDED: Clear custom drills on full reset
    _customDrills.clear();
    _completedSessions.clear();
    _currentStreak = 0;
    _previousStreak = 0;
    _highestStreak = 0;
    _countOfFullyCompletedSessions = 0;
    
    // ✅ NEW: Reset backend-sourced progress metrics only
    _favoriteDrill = '';
    _drillsPerSession = 0.0;
    _minutesPerSession = 0.0;
    _totalTimeAllSessions = 0;
    _dribblingDrillsCompleted = 0;
    _firstTouchDrillsCompleted = 0;
    _passingDrillsCompleted = 0;
    _shootingDrillsCompleted = 0;
    _defendingDrillsCompleted = 0;
    _goalkeepingDrillsCompleted = 0;
    _fitnessDrillsCompleted = 0;

    // ✅ NEW: Reset additional progress metrics
    _mostImprovedSkill = '';
    _uniqueDrillsCompleted = 0;
    _beginnerDrillsCompleted = 0;
    _intermediateDrillsCompleted = 0;
    _advancedDrillsCompleted = 0;
    
    // ✅ NEW: Reset mental training metrics
    _mentalTrainingSessions = 0;
    _totalMentalTrainingMinutes = 0;
    
    _syncCoordinator.cancelAll();
    notifyListeners();
  }

  // Set initial load state
  void setInitialLoadState(bool isInitialLoad) {
    _isInitialLoad = isInitialLoad;
    notifyListeners();
  }

  // ===== MOCK DATA =====
  // Mock data for testing
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
      isCustom: false, // ✅ ADDED: Set isCustom to false for mock drills
    ),
  ];

  // ✅ NEW: Handle transition from guest mode to authenticated mode
  Future<void> handleAuthenticationTransition() async {
    if (kDebugMode) {
      print('\n🔄 ===== HANDLING AUTHENTICATION TRANSITION =====');
      print('📅 Timestamp: ${DateTime.now()}');
      print('   Previous state: Guest Mode');
      print('   New state: Authenticated User');
    }

    try {
      // Step 1: Clear guest-specific data
      if (kDebugMode) print('🧹 Clearing guest-specific data...');
      _guestDrills.clear();
      _guestDrillsLoaded = false;
      
      // Step 2: Clear any test session data that was loaded for guest
      if (kDebugMode) print('🔄 Clearing guest session data...');
      _editableSessionDrills.clear();
      _sessionDrills.clear();
      _setSessionState(SessionState.idle);
      
      // Step 3: Reset to initial load state
      _isInitialLoad = true;
      notifyListeners();
      
      // Step 4: Load authenticated user data if they have account history
      final userManager = UserManagerService.instance;
      if (userManager.userHasAccountHistory) {
        if (kDebugMode) print('📥 Loading authenticated user data...');
        await loadBackendData();
      } else {
        if (kDebugMode) print('🆕 New user - skipping backend data load');
        _isInitialLoad = false;
      }
      
      // Step 5: Trigger UI refresh
      notifyListeners();
      
      if (kDebugMode) {
        print('✅ Authentication transition complete');
        print('   User is now: ${userManager.isAuthenticated ? 'Authenticated' : 'Not Authenticated'}');
        print('   Guest mode: ${userManager.isGuestMode}');
        print('   Has session drills: ${_editableSessionDrills.isNotEmpty}');
        print('🔄 ===== AUTHENTICATION TRANSITION FINISHED =====\n');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error during authentication transition: $e');
      }
      // Ensure we don't get stuck in loading state
      _isInitialLoad = false;
      notifyListeners();
    }
  }

  // ===== FRIEND REQUEST COUNT METHODS =====
  /// Refresh friend request count from backend
  Future<void> refreshFriendRequestCount({int? count}) async {
    // Skip for guest users
    if (isGuestMode) {
      _friendRequestCount = 0;
      notifyListeners();
      return;
    }

    // If count is provided, use it directly to avoid API call
    if (count != null) {
      _friendRequestCount = count;
      if (kDebugMode) {
        print('✅ Friend request count updated: $_friendRequestCount');
      }
      notifyListeners();
      return;
    }

    try {
      final requests = await _friendService.getFriendRequests();
      _friendRequestCount = requests.length;
      if (kDebugMode) {
        print('✅ Friend request count updated: $_friendRequestCount');
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error refreshing friend request count: $e');
      }
      // On error, set to 0 to avoid showing stale data
      _friendRequestCount = 0;
      notifyListeners();
    }
  }

  // Cleanup sync coordinator on dispose
  @override
  void dispose() {
    _syncCoordinator.cancelAll();
    super.dispose();
  }
} 