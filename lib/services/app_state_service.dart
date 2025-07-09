import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/drill_model.dart';
import '../models/editable_drill_model.dart';
import '../models/drill_group_model.dart';
import '../models/filter_models.dart';
import '../config/app_config.dart';
import '../services/drill_api_service.dart';
import './test_data_service.dart';

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
    totalCompletedDrills: json['totalCompletedDrills'],
    totalDrills: json['totalDrills'],
  );
}

class AppStateService extends ChangeNotifier {
  static AppStateService? _instance;
  static AppStateService get instance => _instance ??= AppStateService._();
  
  AppStateService._();
  
  // Services
  final DrillApiService _drillApiService = DrillApiService.shared;
  
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
  
  // All available drills - use test data or real data based on config
  List<DrillModel> get _availableDrills {
    if (AppConfig.useTestData) {
      if (kDebugMode) print('🔧 Using test drills data (AppConfig.useTestData = true)');
      return TestDataService.getTestDrills();
    } else {
      if (kDebugMode) print('🌐 Using cached backend drills data (AppConfig.useTestData = false)');
      return _cachedDrills;
    }
  }
  List<DrillModel> get availableDrills => List.unmodifiable(_availableDrills);
  
  // Cached drill data for performance
  List<DrillModel> _cachedDrills = [];
  
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
  List<CompletedSession> get completedSessions => List.unmodifiable(_completedSessions);

  void addCompletedSession(CompletedSession session) {
    _completedSessions.add(session);
    if (kDebugMode) {
      print('✅ CompletedSession saved!');
      print('  Date: ${session.date}');
      print('  Drills: ${session.drills.length}');
      print('  Total Completed: ${session.totalCompletedDrills}');
      print('  Total Drills: ${session.totalDrills}');
    }
    // TODO: persist to disk
    notifyListeners();
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
    
    // Load test session if in debug mode and no session exists
    if (AppConfig.useTestData && _editableSessionDrills.isEmpty) {
      await _loadTestSession();
    }
    
    // Pre-cache some drills for better performance
    await _loadInitialDrills();
    
    notifyListeners();
  }
  
  // MARK: - Enhanced API-like Methods
  
  /// Load initial drills with loading state
  Future<void> _loadInitialDrills() async {
    _setLoading(true);
    _clearError();
    
    try {
      if (AppConfig.useTestData) {
        // Use test data service
        final response = await TestDataService.searchDrills(
          DrillSearchFilters(page: 1, pageSize: 20)
        );
        _cachedDrills = response.drills;
        if (kDebugMode) print('📚 Loaded ${_cachedDrills.length} test drills');
      } else {
        // Use real backend API
        final response = await _drillApiService.searchDrills(
          page: 1,
          limit: 20,
        );
        _cachedDrills = _drillApiService.convertToLocalModels(response.items);
        if (kDebugMode) print('🌐 Loaded ${_cachedDrills.length} backend drills');
      }
      
    } catch (e) {
      _setError('Failed to load drills: $e');
      if (kDebugMode) print('❌ Error loading initial drills: $e');
    } finally {
      _setLoading(false);
    }
  }
  
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
      
      await _persistState();
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
    _persistState();
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
    _persistState();
    notifyListeners();
  }
  
  void deleteDrillGroup(String groupId) {
    _savedDrillGroups.removeWhere((group) => group.id == groupId);
    _persistState();
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
      _persistState();
      notifyListeners();
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
        _persistState();
        notifyListeners();
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
        _persistState();
        notifyListeners();
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
      _persistState();
      notifyListeners();
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
    _persistState();
    notifyListeners();
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
    _persistState();
    notifyListeners();
  }
  
  void updateEquipmentFilter(Set<String> equipment) {
    _preferences.selectedEquipment = equipment;
    if (_autoGenerateSession) {
      _autoGenerateSessionDrills();
    }
    _persistState();
    notifyListeners();
  }
  
  void updateTrainingStyleFilter(String? style) {
    _preferences.selectedTrainingStyle = style;
    if (_autoGenerateSession) {
      _autoGenerateSessionDrills();
    }
    _persistState();
    notifyListeners();
  }
  
  void updateLocationFilter(String? location) {
    _preferences.selectedLocation = location;
    if (_autoGenerateSession) {
      _autoGenerateSessionDrills();
    }
    _persistState();
    notifyListeners();
  }
  
  void updateDifficultyFilter(String? difficulty) {
    _preferences.selectedDifficulty = difficulty;
    if (_autoGenerateSession) {
      _autoGenerateSessionDrills();
    }
    _persistState();
    notifyListeners();
  }
  
  void updateSkillsFilter(Set<String> skills) {
    _preferences.selectedSkills = skills;
    if (_autoGenerateSession) {
      _autoGenerateSessionDrills();
    }
    _persistState();
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
      
      _persistState();
      notifyListeners();
    }
  }
  
  void removeDrillFromSession(DrillModel drill) {
    _sessionDrills.removeWhere((d) => d.id == drill.id);
    _editableSessionDrills.removeWhere((ed) => ed.drill.id == drill.id);
    _persistState();
    notifyListeners();
  }
  
  void reorderSessionDrills(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final DrillModel item = _sessionDrills.removeAt(oldIndex);
    _sessionDrills.insert(newIndex, item);
    
    final EditableDrillModel editableItem = _editableSessionDrills.removeAt(oldIndex);
    _editableSessionDrills.insert(newIndex, editableItem);
    
    _persistState();
    notifyListeners();
  }
  
  void clearSession() {
    _sessionDrills.clear();
    _editableSessionDrills.clear();
    _sessionInProgress = false;
    _persistState();
    notifyListeners();
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
    
    _persistState();
    notifyListeners();
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
      
      _persistState();
      notifyListeners();
    }
  }
  
  // Session progress methods
  void startSession() {
    _sessionInProgress = true;
    _persistState();
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
    _persistState();
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
    _persistState();
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
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save preferences
      await prefs.setString('user_preferences', jsonEncode({
        'selectedTime': _preferences.selectedTime,
        'selectedEquipment': _preferences.selectedEquipment.toList(),
        'selectedTrainingStyle': _preferences.selectedTrainingStyle,
        'selectedLocation': _preferences.selectedLocation,
        'selectedDifficulty': _preferences.selectedDifficulty,
        'selectedSkills': _preferences.selectedSkills.toList(),
      }));
      
      // Save session drills
      await prefs.setStringList('session_drill_ids', _sessionDrills.map((d) => d.id).toList());
      
      // Save saved drill groups
      await prefs.setString('saved_drill_groups', jsonEncode(
        _savedDrillGroups.map((group) => group.toJson()).toList()
      ));
      
      // Save liked drills
      await prefs.setStringList('liked_drill_ids', _likedDrills.map((d) => d.id).toList());
      
      // Save auto-generation setting
      await prefs.setBool('auto_generate_session', _autoGenerateSession);
      
    } catch (e) {
      debugPrint('Error persisting state: $e');
    }
  }
  
  Future<void> _loadPersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load preferences
      final preferencesJson = prefs.getString('user_preferences');
      if (preferencesJson != null) {
        final preferencesMap = jsonDecode(preferencesJson) as Map<String, dynamic>;
        _preferences = UserPreferences(
          selectedTime: preferencesMap['selectedTime'] as String?,
          selectedEquipment: Set<String>.from(preferencesMap['selectedEquipment'] ?? []),
          selectedTrainingStyle: preferencesMap['selectedTrainingStyle'] as String?,
          selectedLocation: preferencesMap['selectedLocation'] as String?,
          selectedDifficulty: preferencesMap['selectedDifficulty'] as String?,
          selectedSkills: Set<String>.from(preferencesMap['selectedSkills'] ?? []),
        );
      }
      
      // Load session drills
      final sessionDrillIds = prefs.getStringList('session_drill_ids');
      if (sessionDrillIds != null) {
        _sessionDrills.clear();
        for (final id in sessionDrillIds) {
          final drill = _availableDrills.firstWhere(
            (d) => d.id == id,
            orElse: () => _availableDrills.first, // Fallback if drill not found
          );
          _sessionDrills.add(drill);
        }
      }
      
      // Load saved drill groups
      final savedGroupsJson = prefs.getString('saved_drill_groups');
      if (savedGroupsJson != null) {
        final savedGroupsList = jsonDecode(savedGroupsJson) as List;
        _savedDrillGroups.clear();
        for (final groupData in savedGroupsList) {
          try {
            final group = DrillGroup.fromJson(groupData as Map<String, dynamic>, _availableDrills);
            _savedDrillGroups.add(group);
          } catch (e) {
            debugPrint('Error loading drill group: $e');
          }
        }
      }
      
      // Load liked drills
      final likedDrillIds = prefs.getStringList('liked_drill_ids');
      if (likedDrillIds != null) {
        _likedDrills.clear();
        for (final id in likedDrillIds) {
          final drill = _availableDrills.firstWhere(
            (d) => d.id == id,
            orElse: () => _availableDrills.first, // Fallback if drill not found
          );
          _likedDrills.add(drill);
        }
      }
      
      // Load auto-generation setting
      _autoGenerateSession = prefs.getBool('auto_generate_session') ?? true;
      
    } catch (e) {
      debugPrint('Error loading persisted state: $e');
    }
  }
  
  // Clear all data (for logout, etc.)
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      _preferences = UserPreferences();
      _sessionDrills.clear();
      _savedDrillGroups.clear();
      _likedDrills.clear();
      _autoGenerateSession = true;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing data: $e');
    }
  }
  
  // Mock data - same as before
  static final List<DrillModel> _mockDrills = [
    DrillModel(
      id: '1',
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
      id: '2',
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
      id: '3',
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
      id: '4',
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
      id: '5',
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
      id: '6',
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
      id: '7',
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
      id: '8',
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
} 