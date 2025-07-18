import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../config/app_config.dart';
import '../models/preferences_models.dart';
import '../models/drill_model.dart';
import '../models/editable_drill_model.dart';
import '../models/filter_models.dart';
import '../services/api_service.dart';
import '../services/user_manager_service.dart';
import '../services/app_state_service.dart';

/// Preferences Sync Service
/// Mirrors Swift PreferencesUpdateService for syncing user preferences with backend
class PreferencesSyncService {
  static PreferencesSyncService? _instance;
  static PreferencesSyncService get shared => _instance ??= PreferencesSyncService._();
  
  PreferencesSyncService._();

  final ApiService _apiService = ApiService.shared;
  final UserManagerService _userManager = UserManagerService.instance;

  /// Convert time string to minutes (mirrors Swift convertTimeToMinutes)
  int _convertTimeToMinutes(String? time) {
    if (time == null) return 60; // Default to 1 hour
    
    switch (time) {
      case '15min': return 15;
      case '30min': return 30;
      case '45min': return 45;
      case '1h': return 60;
      case '1h30': return 90;
      case '2h+': return 120;
      default: return 60;
    }
  }

  /// Convert minutes to time string (mirrors Swift convertMinutesToTimeString)
  String _convertMinutesToTimeString(int minutes) {
    switch (minutes) {
      case 0: case 1: case 2: case 3: case 4: case 5: case 6: case 7: case 8: case 9: case 10: case 11: case 12: case 13: case 14: case 15:
        return '15min';
      case 16: case 17: case 18: case 19: case 20: case 21: case 22: case 23: case 24: case 25: case 26: case 27: case 28: case 29: case 30:
        return '30min';
      case 31: case 32: case 33: case 34: case 35: case 36: case 37: case 38: case 39: case 40: case 41: case 42: case 43: case 44: case 45:
        return '45min';
      case 46: case 47: case 48: case 49: case 50: case 51: case 52: case 53: case 54: case 55: case 56: case 57: case 58: case 59: case 60:
        return '1h';
      case 61: case 62: case 63: case 64: case 65: case 66: case 67: case 68: case 69: case 70: case 71: case 72: case 73: case 74: case 75: case 76: case 77: case 78: case 79: case 80: case 81: case 82: case 83: case 84: case 85: case 86: case 87: case 88: case 89: case 90:
        return '1h30';
      default:
        return '2h+';
    }
  }

  /// Sync preferences with backend (mirrors Swift syncPreferencesWithBackend)
  Future<void> syncPreferencesWithBackend({
    required String? time,
    required Set<String> equipment,
    required String? trainingStyle,
    required String? location,
    required String? difficulty,
    required Set<String> skills,
  }) async {
    // SAFETY: Prevent updates if logging out or no valid user
    final userEmail = _userManager.email;
    if (userEmail.isEmpty) {
      if (kDebugMode) {
        print('[SAFETY] Skipping syncPreferencesWithBackend: userEmail=empty');
      }
      return;
    }

    if (kDebugMode) {
      print('🔄 [PREFERENCES] Starting preferences sync with backend...');
      print('   Time: $time');
      print('   Equipment: $equipment');
      print('   Training Style: $trainingStyle');
      print('   Location: $location');
      print('   Difficulty: $difficulty');
      print('   Skills: $skills');
    }

    try {
      final duration = _convertTimeToMinutes(time);
      final preferencesRequest = SessionPreferencesRequest(
        duration: duration,
        availableEquipment: equipment.toList(),
        trainingStyle: trainingStyle,
        trainingLocation: location,
        difficulty: difficulty,
        targetSkills: skills.toList(),
      );

      final response = await _apiService.put(
        '/api/session/preferences',
        body: preferencesRequest.toJson(),
        requiresAuth: true,
      );

      if (kDebugMode) {
        print('📥 [PREFERENCES] Backend response status: ${response.statusCode}');
      }

      if (response.isSuccess && response.data != null) {
        if (kDebugMode) {
          print('✅ [PREFERENCES] Successfully updated preferences');
        }

        // Parse the response and update session data
        await _parsePreferencesResponse(response.data!);
      } else {
        if (kDebugMode) {
          print('❌ [PREFERENCES] Failed to update preferences: ${response.statusCode}');
          print('Error: ${response.error}');
        }
        throw Exception('Failed to update preferences: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [PREFERENCES] Error syncing preferences: $e');
      }
      rethrow;
    }
  }


  /// Parse preferences response and update session data (mirrors Swift parsing logic)
  Future<void> _parsePreferencesResponse(Map<String, dynamic> jsonData) async {
    try {
      if (kDebugMode) {
        print('🔄 [PREFERENCES] Parsing response data...');
      }

      final data = jsonData['data'] as Map<String, dynamic>?;
      if (data == null) {
        if (kDebugMode) {
          print('❌ [PREFERENCES] No data field in response');
        }
        return;
      }

      final sessionId = data['session_id'] as int?;
      final totalDuration = data['total_duration'] as int?;
      final focusAreas = (data['focus_areas'] as List<dynamic>?)?.cast<String>() ?? [];
      final drillsArray = data['drills'] as List<dynamic>? ?? [];

      if (kDebugMode) {
        print('📊 [PREFERENCES] Parsed session data:');
        print('   Session ID: $sessionId');
        print('   Total Duration: $totalDuration');
        print('   Focus Areas: $focusAreas');
        print('   Drills Count: ${drillsArray.length}');
      }

      // Convert drill responses to DrillModel objects
      final drillModels = <DrillModel>[];
      for (final drillJson in drillsArray) {
        final drill = drillJson as Map<String, dynamic>;
        
        // Extract UUID or generate one
        final uuid = drill['uuid'] as String? ?? 
                    '550e8400-e29b-41d4-a716-${DateTime.now().millisecondsSinceEpoch}';
        
        // Extract skill category
        String skill = 'General';
        if (drill['primary_skill'] != null) {
          final primarySkill = drill['primary_skill'] as Map<String, dynamic>;
          final category = primarySkill['category'] as String?;
          if (category != null && category.isNotEmpty) {
            skill = category;
          }
        }

        // Extract sub-skills
        final subSkills = <String>[];
        if (drill['primary_skill'] != null) {
          final primarySkill = drill['primary_skill'] as Map<String, dynamic>;
          final subSkill = primarySkill['sub_skill'] as String?;
          if (subSkill != null) {
            subSkills.add(subSkill);
          }
        }
        if (drill['secondary_skills'] != null) {
          final secondarySkills = drill['secondary_skills'] as List<dynamic>;
          for (final secondarySkill in secondarySkills) {
            final subSkill = secondarySkill['sub_skill'] as String?;
            if (subSkill != null) {
              subSkills.add(subSkill);
            }
          }
        }

        final drillModel = DrillModel(
          id: uuid,
          title: drill['title'] as String? ?? 'Unnamed Drill',
          skill: skill,
          subSkills: subSkills,
          sets: drill['sets'] as int? ?? 0,
          reps: drill['reps'] as int? ?? 0,
          duration: drill['duration'] as int? ?? 10,
          description: drill['description'] as String? ?? '',
          instructions: (drill['instructions'] as List<dynamic>?)?.cast<String>() ?? [],
          tips: (drill['tips'] as List<dynamic>?)?.cast<String>() ?? [],
          equipment: (drill['equipment'] as List<dynamic>?)?.cast<String>() ?? [],
          trainingStyle: drill['intensity'] as String? ?? '',
          difficulty: drill['difficulty'] as String? ?? '',
          videoUrl: drill['video_url'] as String? ?? '',
          isCustom: false, // ✅ ADDED: Set isCustom to false for preference drills
        );

        drillModels.add(drillModel);
      }

      if (kDebugMode) {
        print('✅ [PREFERENCES] Converted ${drillModels.length} drills to DrillModel objects');
      }

      // Update AppStateService with new session data
      final appState = AppStateService.instance;
      
      // Update session ID if available
      if (sessionId != null) {
        // Note: AppStateService doesn't have currentSessionId, but we can store it if needed
        if (kDebugMode) {
          print('📝 [PREFERENCES] Session ID updated to: $sessionId');
        }
      }

      // Update ordered session drills
      final editableDrills = drillModels.map((drill) => EditableDrillModel(
        drill: drill,
        setsDone: 0,
        totalSets: drill.sets > 0 ? drill.sets : 3,
        totalReps: drill.reps > 0 ? drill.reps : 10,
        totalDuration: drill.duration > 0 ? drill.duration : 5,
        isCompleted: false,
      )).toList();

      // Update AppStateService
      appState.updateOrderedSessionDrillsThroughPreferences(editableDrills);

      if (kDebugMode) {
        print('✅ [PREFERENCES] Successfully updated ordered session drills');
        print('   New drill count: ${editableDrills.length}');
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ [PREFERENCES] Error parsing preferences response: $e');
      }
      rethrow;
    }
  }

  /// Fetch preferences from backend (mirrors Swift fetchPreferences)
  Future<PreferencesData?> fetchPreferences() async {
    try {
      if (kDebugMode) {
        print('🔄 [PREFERENCES] Fetching preferences from backend...');
      }

      final response = await _apiService.get(
        '/api/session/preferences',
        requiresAuth: true,
      );

      if (kDebugMode) {
        print('📥 [PREFERENCES] Backend response status: ${response.statusCode}');
      }

      if (response.isSuccess && response.data != null) {
        if (kDebugMode) {
          print('✅ [PREFERENCES] Successfully fetched preferences');
        }

        final preferencesResponse = PreferencesResponse.fromJson(response.data!);
        return preferencesResponse.data;
      } else {
        if (kDebugMode) {
          print('❌ [PREFERENCES] Failed to fetch preferences: ${response.statusCode}');
          print('Error: ${response.error}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [PREFERENCES] Error fetching preferences: $e');
      }
      return null;
    }
  }

  /// Load preferences from backend and update AppStateService
  Future<void> loadPreferencesFromBackend() async {
    try {
      if (kDebugMode) {
        print('🔄 [PREFERENCES] Loading preferences from backend...');
        final appState = AppStateService.instance;
        print('   Current equipment before backend load: ${appState.preferences.selectedEquipment}');
      }

      final preferencesData = await fetchPreferences();
      if (preferencesData != null) {
        final appState = AppStateService.instance;
        
        // ✅ PRESERVE ONBOARDING EQUIPMENT: Don't overwrite if equipment was set during onboarding
        final currentEquipment = appState.preferences.selectedEquipment;
        final backendEquipment = preferencesData.availableEquipment?.toSet() ?? {};
        
        // If we have equipment from onboarding (contains soccer ball), preserve it
        Set<String> finalEquipment;
        if (currentEquipment.contains('soccer ball') && !backendEquipment.contains('soccer ball')) {
          finalEquipment = Set<String>.from(currentEquipment)..addAll(backendEquipment);
          if (kDebugMode) {
            print('🔧 [PREFERENCES] Preserving onboarding equipment (soccer ball) over backend data');
          }
        } else {
          finalEquipment = backendEquipment;
        }
        
        // ✅ PRESERVE ONBOARDING NULLS: Keep training style, location, and difficulty empty if they're currently null
        // This indicates they should remain empty after onboarding
        final currentTrainingStyle = appState.preferences.selectedTrainingStyle;
        final currentLocation = appState.preferences.selectedLocation;
        final currentDifficulty = appState.preferences.selectedDifficulty;
        
        final finalTrainingStyle = currentTrainingStyle == null ? null : preferencesData.trainingStyle;
        final finalLocation = currentLocation == null ? null : preferencesData.trainingLocation;
        final finalDifficulty = currentDifficulty == null ? null : preferencesData.difficulty;
        
        if (kDebugMode) {
          print('🔧 [PREFERENCES] Preference preservation logic:');
          print('   Training Style: current=$currentTrainingStyle, backend=${preferencesData.trainingStyle}, final=$finalTrainingStyle');
          print('   Location: current=$currentLocation, backend=${preferencesData.trainingLocation}, final=$finalLocation');
          print('   Difficulty: current=$currentDifficulty, backend=${preferencesData.difficulty}, final=$finalDifficulty');
        }
        
        // Convert backend data to UserPreferences
        final userPreferences = UserPreferences(
          selectedTime: preferencesData.duration != null 
              ? _convertMinutesToTimeString(preferencesData.duration!)
              : null,
          selectedEquipment: finalEquipment,
          selectedTrainingStyle: finalTrainingStyle,
          selectedLocation: finalLocation,
          selectedDifficulty: finalDifficulty,
          selectedSkills: preferencesData.targetSkills?.toSet() ?? {},
        );

        // Update AppStateService preferences
        appState.updateUserPreferences(userPreferences);

        if (kDebugMode) {
          print('✅ [PREFERENCES] Successfully loaded preferences from backend');
          print('   Time: ${userPreferences.selectedTime}');
          print('   Equipment (final): ${userPreferences.selectedEquipment}');
          print('   Equipment (from backend): ${backendEquipment}');
          print('   Equipment (preserved from onboarding): ${currentEquipment.contains('soccer ball')}');
          print('   Training Style (final): ${userPreferences.selectedTrainingStyle}');
          print('   Location (final): ${userPreferences.selectedLocation}');
          print('   Difficulty (final): ${userPreferences.selectedDifficulty}');
          print('   Skills: ${userPreferences.selectedSkills}');
        }
      } else {
        if (kDebugMode) {
          print('⚠️ [PREFERENCES] No preferences data returned from backend');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [PREFERENCES] Error loading preferences from backend: $e');
      }
    }
  }
} 