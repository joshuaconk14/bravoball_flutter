import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/editable_drill_model.dart';
import 'api_service.dart';
import 'app_state_service.dart'; // Import for CompletedSession

class ProgressDataSyncService {
  static final ProgressDataSyncService _instance = ProgressDataSyncService._internal();
  factory ProgressDataSyncService() => _instance;
  ProgressDataSyncService._internal();

  static ProgressDataSyncService get shared => _instance;

  final ApiService _apiService = ApiService.shared;

  // MARK: - Completed Sessions Sync

  /// Sync a completed session to the backend
  Future<bool> syncCompletedSession({
    required DateTime date,
    required List<EditableDrillModel> drills,
    required int totalCompleted,
    required int total,
  }) async {
    try {
      final drillsData = drills.map((drill) => {
        'drill': {
          'uuid': drill.drill.id,
          'title': drill.drill.title,
          'skill': drill.drill.skill,
          'subSkills': drill.drill.subSkills,
          'sets': drill.drill.sets,
          'reps': drill.drill.reps,
          'duration': drill.drill.duration,
          'description': drill.drill.description,
          'tips': drill.drill.tips,
          'instructions': drill.drill.instructions,
          'equipment': drill.drill.equipment,
          'trainingStyle': drill.drill.trainingStyle,
          'difficulty': drill.drill.difficulty,
          'videoUrl': drill.drill.videoUrl,
        },
        'setsDone': drill.setsDone,
        'totalSets': drill.totalSets,
        'totalReps': drill.totalReps,
        'totalDuration': drill.totalDuration,
        'isCompleted': drill.isCompleted,
      }).toList();

      final sessionData = {
        'date': date.toIso8601String(),
        'drills': drillsData,
        'total_completed_drills': totalCompleted,
        'total_drills': total,
      };

      if (kDebugMode) {
        print('📤 Syncing completed session: ${jsonEncode(sessionData)}');
      }

      final response = await _apiService.post(
        '/api/sessions/completed/',
        body: sessionData,
        requiresAuth: true,
      );

      if (response.isSuccess) {
        if (kDebugMode) {
          print('✅ Successfully synced completed session');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('❌ Failed to sync completed session: ${response.statusCode} ${response.error}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error syncing completed session: $e');
      }
      return false;
    }
  }

  /// Fetch completed sessions from the backend
  Future<List<CompletedSession>> fetchCompletedSessions() async {
    print('🔄 [COMPLETED_SESSIONS] Starting fetchCompletedSessions()');
    
    try {
      if (kDebugMode) {
        print('📥 Fetching completed sessions from backend');
      }

      print('🌐 [API] Making GET request to /api/sessions/completed/');
      
      // Test if the API call is being made
      print('🔍 [DEBUG] About to make API call...');
      
      final response = await _apiService.get(
        '/api/sessions/completed/',
        requiresAuth: true,
      );

      print('🔍 [DEBUG] API call completed');
      print('📡 [API] Response status: ${response.statusCode}');
      print('📡 [API] Response success: ${response.isSuccess}');
      print('📡 [API] Response data: ${response.data}');

      // If response is empty or null, return empty list
      if (response.data == null) {
        print('❌ [API] Response data is null');
        return [];
      }

      if (response.isSuccess && response.data != null) {
        print('✅ [API] Response was successful and has data');
        
        // Check if data has 'sessions' key or is directly an array
        final sessionsJson = response.data!['sessions'] ?? response.data!['data'] ?? response.data!;
        print('📊 [API] Found ${sessionsJson.length} sessions in response');
        print('📊 [API] Sessions data type: ${sessionsJson.runtimeType}');
        
        if (sessionsJson is List) {
          print('✅ [API] Sessions is a List, processing ${sessionsJson.length} items');
          
          final sessions = sessionsJson.map((sessionJson) {
            print('🔄 [API] Parsing session: $sessionJson');
            try {
              final session = CompletedSession.fromJson(sessionJson);
              print('✅ [API] Successfully parsed session for date: ${session.date}');
              return session;
            } catch (e) {
              print('❌ [API] Error parsing session: $e');
              print('   Session data: $sessionJson');
              rethrow;
            }
          }).toList();

          print('✅ [API] Successfully parsed ${sessions.length} completed sessions');
          return sessions;
        } else {
          print('❌ [API] Sessions is not a List, it is: ${sessionsJson.runtimeType}');
          return [];
        }
      } else {
        print('❌ [API] Response was not successful or has no data');
        print('   Status Code: ${response.statusCode}');
        print('   Error: ${response.error}');
        print('   Data: ${response.data}');
        return [];
      }
    } catch (e) {
      print('💥 [API] Exception while fetching completed sessions: $e');
      print('   Error type: ${e.runtimeType}');
      print('   Error description: $e');
      return [];
    }
  }


  /// Update and fetch progress history from the backend
  Future<Map<String, dynamic>?> updateProgressHistory() async {
    try {
      if (kDebugMode) {
        print('📥 Fetching progress history from backend');
      }

      final response = await _apiService.get(
        '/api/progress_history/',
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        final progressData = {
          'currentStreak': response.data!['current_streak'] ?? 0,
          'previousStreak': response.data!['previous_streak'] ?? 0,
          'highestStreak': response.data!['highest_streak'] ?? 0,
          'completedSessionsCount': response.data!['completed_sessions_count'] ?? 0,
        };

        if (kDebugMode) {
          print('✅ Successfully fetched progress history: $progressData');
        }
        return progressData;
      } else {
        if (kDebugMode) {
          print('❌ Failed to fetch progress history: ${response.statusCode} ${response.error}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching progress history: $e');
      }
      return null;
    }
  }
} 