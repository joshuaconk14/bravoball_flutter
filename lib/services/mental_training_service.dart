import 'package:flutter/foundation.dart';
import '../models/mental_training_models.dart';
import '../services/api_service.dart';
import '../models/api_response_models.dart';

class MentalTrainingService extends ChangeNotifier {
  static final MentalTrainingService _instance = MentalTrainingService._internal();
  factory MentalTrainingService() => _instance;
  MentalTrainingService._internal();

  static MentalTrainingService get shared => _instance;

  final ApiService _apiService = ApiService.shared;

  List<MentalTrainingQuote> _quotes = [];
  bool _isLoadingQuotes = false;
  String? _lastError;

  // Getters
  List<MentalTrainingQuote> get quotes => _quotes;
  bool get isLoadingQuotes => _isLoadingQuotes;
  String? get lastError => _lastError;

  /// Fetch mental training quotes from the backend
  Future<List<MentalTrainingQuote>> fetchQuotes({
    int limit = 50,
    String? quoteType,
  }) async {
    _isLoadingQuotes = true;
    _lastError = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('🧠 Fetching mental training quotes...');
      }

      final Map<String, String> queryParams = {
        'limit': limit.toString(),
      };

      if (quoteType != null) {
        queryParams['quote_type'] = quoteType;
      }

      final response = await _apiService.request(
        endpoint: '/api/mental-training/quotes',
        method: 'GET',
        queryParameters: queryParams,
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        // Handle wrapped response format - quotes might be in 'data' field or directly as array
        List<dynamic> quotesData;
        if (response.data is List) {
          quotesData = response.data as List<dynamic>;
        } else if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          quotesData = (data['data'] ?? data['quotes'] ?? []) as List<dynamic>;
        } else {
          quotesData = [];
        }
        
        _quotes = quotesData.map((json) => MentalTrainingQuote.fromJson(json)).toList();
        
        if (kDebugMode) {
          print('✅ Successfully fetched ${_quotes.length} mental training quotes');
        }
        
        return _quotes;
      } else {
        throw Exception(response.error ?? 'Failed to fetch quotes');
      }
    } catch (e) {
      _lastError = e.toString();
      if (kDebugMode) {
        print('❌ Error fetching mental training quotes: $e');
      }
      return [];
    } finally {
      _isLoadingQuotes = false;
      notifyListeners();
    }
  }

  /// Create a new mental training session
  Future<MentalTrainingSession?> createMentalTrainingSession({
    required int durationMinutes,
    String sessionType = 'mental_training',
  }) async {
    try {
      if (kDebugMode) {
        print('🧠 Creating mental training session...');
        print('   Duration: $durationMinutes minutes');
        print('   Type: $sessionType');
      }

      final sessionData = {
        'duration_minutes': durationMinutes,
        'session_type': sessionType,
      };

      final response = await _apiService.request(
        endpoint: '/api/mental-training/sessions',
        method: 'POST',
        body: sessionData,
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        final session = MentalTrainingSession.fromJson(response.data!);
        
        if (kDebugMode) {
          print('✅ Successfully created mental training session');
          print('   Session ID: ${session.id}');
          print('   Duration: ${session.durationMinutes} minutes');
        }
        
        return session;
      } else {
        throw Exception(response.error ?? 'Failed to create session');
      }
    } catch (e) {
      _lastError = e.toString();
      if (kDebugMode) {
        print('❌ Error creating mental training session: $e');
      }
      return null;
    }
  }

  /// Get all mental training sessions for the current user
  Future<List<MentalTrainingSession>> fetchSessions() async {
    try {
      if (kDebugMode) {
        print('🧠 Fetching mental training sessions...');
      }

      final response = await _apiService.request(
        endpoint: '/api/mental-training/sessions',
        method: 'GET',
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        final List<dynamic> sessionsData = response.data as List<dynamic>;
        final sessions = sessionsData.map((json) => MentalTrainingSession.fromJson(json)).toList();
        
        if (kDebugMode) {
          print('✅ Successfully fetched ${sessions.length} mental training sessions');
        }
        
        return sessions;
      } else {
        throw Exception(response.error ?? 'Failed to fetch sessions');
      }
    } catch (e) {
      _lastError = e.toString();
      if (kDebugMode) {
        print('❌ Error fetching mental training sessions: $e');
      }
      return [];
    }
  }

  /// Get mental training sessions completed today
  Future<MentalTrainingSessionsToday?> fetchTodaySessions() async {
    try {
      if (kDebugMode) {
        print('🧠 Fetching today\'s mental training sessions...');
      }

      final response = await _apiService.request(
        endpoint: '/api/mental-training/sessions/today',
        method: 'GET',
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        final todaySessions = MentalTrainingSessionsToday.fromJson(response.data!);
        
        if (kDebugMode) {
          print('✅ Successfully fetched today\'s mental training sessions');
          print('   Sessions today: ${todaySessions.sessionsToday}');
          print('   Total minutes today: ${todaySessions.totalMinutesToday}');
        }
        
        return todaySessions;
      } else {
        throw Exception(response.error ?? 'Failed to fetch today\'s sessions');
      }
    } catch (e) {
      _lastError = e.toString();
      if (kDebugMode) {
        print('❌ Error fetching today\'s mental training sessions: $e');
      }
      return null;
    }
  }

  /// Clear any cached data
  void clearCache() {
    _quotes.clear();
    _lastError = null;
    notifyListeners();
  }
} 