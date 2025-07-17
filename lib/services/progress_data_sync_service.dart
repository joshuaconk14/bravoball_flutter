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
    required String type,
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
        'session_type': type
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
          
          final sessions = <CompletedSession>[];
          
          for (int i = 0; i < sessionsJson.length; i++) {
            final sessionJson = sessionsJson[i];
            print('🔄 [API] Parsing session $i: $sessionJson');
            
            try {
              // 🧠 Check if this is a mental training session
              final sessionType = sessionJson['session_type'] ?? 'training';
              final drillsData = sessionJson['drills'];
              final hasNullDrills = drillsData == null;
              
              print('🧠 [MENTAL_TRAINING] Session $i type: $sessionType, drills null: $hasNullDrills');
              
              if (sessionType == 'mental_training') {
                print('🧠 [MENTAL_TRAINING] Found mental training session!');
                print('   Date: ${sessionJson['date']}');
                print('   Total drills: ${sessionJson['total_drills']}');
                print('   Completed drills: ${sessionJson['total_completed_drills']}');
                print('   Drills data: $drillsData');
              }
              
              final session = CompletedSession.fromJson(sessionJson);
              sessions.add(session);
              
              print('✅ [API] Successfully parsed session $i for date: ${session.date}, type: ${session.sessionType}');
              
              if (session.sessionType == 'mental_training') {
                print('🧠 [MENTAL_TRAINING] Successfully parsed mental training session!');
                print('   Drills count: ${session.drills.length}');
                print('   Session date: ${session.date}');
              }
              
            } catch (e) {
              print('❌ [API] Error parsing session $i: $e');
              print('   Session data: $sessionJson');
              print('   Stack trace: ${e.toString()}');
              // Continue with other sessions instead of failing completely
            }
          }

          print('✅ [API] Successfully parsed ${sessions.length} completed sessions');
          
          // 🧠 Count mental training sessions
          final mentalTrainingSessions = sessions.where((s) => s.sessionType == 'mental_training').length;
          print('🧠 [MENTAL_TRAINING] Found $mentalTrainingSessions mental training sessions out of ${sessions.length} total');
          
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
          // ✅ NEW: Enhanced progress metrics
          'favoriteDrill': response.data!['favorite_drill'] ?? '',
          'drillsPerSession': response.data!['drills_per_session'] ?? 0.0,
          'minutesPerSession': response.data!['minutes_per_session'] ?? 0.0,
          'totalTimeAllSessions': response.data!['total_time_all_sessions'] ?? 0,
          'dribblingDrillsCompleted': response.data!['dribbling_drills_completed'] ?? 0,
          'firstTouchDrillsCompleted': response.data!['first_touch_drills_completed'] ?? 0,
          'passingDrillsCompleted': response.data!['passing_drills_completed'] ?? 0,
          'shootingDrillsCompleted': response.data!['shooting_drills_completed'] ?? 0,
          'defendingDrillsCompleted': response.data!['defending_drills_completed'] ?? 0,
          'goalkeepingDrillsCompleted': response.data!['goalkeeping_drills_completed'] ?? 0,
          'fitnessDrillsCompleted': response.data!['fitness_drills_completed'] ?? 0,
          // ✅ NEW: Additional progress metrics
          'mostImprovedSkill': response.data!['most_improved_skill'] ?? '',
          'uniqueDrillsCompleted': response.data!['unique_drills_completed'] ?? 0,
          'beginnerDrillsCompleted': response.data!['beginner_drills_completed'] ?? 0,
          'intermediateDrillsCompleted': response.data!['intermediate_drills_completed'] ?? 0,
          'advancedDrillsCompleted': response.data!['advanced_drills_completed'] ?? 0,
          // ✅ NEW: Mental training metrics
          'mentalTrainingSessions': response.data!['mental_training_sessions'] ?? 0,
          'totalMentalTrainingMinutes': response.data!['total_mental_training_minutes'] ?? 0,
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