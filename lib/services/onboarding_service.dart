import 'package:flutter/foundation.dart';
import '../models/onboarding_model.dart';
import '../models/auth_models.dart';
import '../models/drill_model.dart';
import '../models/editable_drill_model.dart';
import 'api_service.dart';
import 'user_manager_service.dart';
import 'app_state_service.dart';

class OnboardingService {
  static OnboardingService? _instance;
  static OnboardingService get shared => _instance ??= OnboardingService._();
  OnboardingService._();

  final ApiService _apiService = ApiService.shared;
  final UserManagerService _userManager = UserManagerService.instance;

  /// Submits onboarding data to the backend and stores tokens and initial session
  Future<bool> submitOnboardingData(OnboardingData data, {ValueChanged<String>? onError}) async {
    try {
      if (kDebugMode) {
        print('📤 OnboardingService: Sending onboarding data: ${data.toJson()}');
        if (_userManager.isGuestMode) {
          print('👤 OnboardingService: User is in guest mode, will exit guest mode before registration');
        }
      }
      
      // ✅ CRITICAL FIX: Exit guest mode before registration attempt
      if (_userManager.isGuestMode) {
        await _userManager.exitGuestMode();
        if (kDebugMode) {
          print('✅ OnboardingService: Exited guest mode before registration attempt');
        }
      }
      
      final response = await _apiService.post(
        '/api/onboarding',
        body: data.toJson(),
        requiresAuth: false,
      );
      
      if (response.isSuccess && response.data != null) {
        // Parse tokens from response
        final accessToken = response.data!['access_token'] ?? '';
        final refreshToken = response.data!['refresh_token'] ?? '';
        final email = response.data!['email'] ?? data.email;
        final username = response.data!['username'] ?? data.username;
        
        if (accessToken.isNotEmpty) {
          // ✅ Save authentication tokens
          // Extract avatar data from response if available
          final avatarPath = response.data!['avatar_path'] as String?;
          final avatarBackgroundColor = response.data!['avatar_background_color'] as String?;
          
          await _userManager.updateUserData(
            email: email,
            username: username,
            accessToken: accessToken,
            refreshToken: refreshToken,
            avatarPath: avatarPath,
            avatarBackgroundColor: avatarBackgroundColor,
          );
          
          // ✅ FIX: Load avatar from backend to ensure correct avatar (or default if none)
          // This ensures new users without avatars get default avatar, not previous user's avatar
          await _userManager.loadAvatarFromBackend();
          
          if (kDebugMode) {
            print('✅ OnboardingService: Registration successful, tokens saved.');
          }
          
          // ✅ NEW: Handle initial session data from backend
          final initialSession = response.data!['initial_session'];
          if (initialSession != null) {
            await _loadInitialSessionIntoAppState(initialSession);
            if (kDebugMode) {
              print('✅ OnboardingService: Initial session loaded into app state.');
            }
          } else {
            if (kDebugMode) {
              print('⚠️ OnboardingService: No initial session returned from backend.');
            }
          }
          
          // ✅ CRITICAL FIX: Handle authentication state transition
          if (kDebugMode) {
            print('🔄 OnboardingService: Handling authentication state transition...');
          }
          await AppStateService.instance.handleAuthenticationTransition();
          
          return true;
        } else {
          onError?.call('Registration succeeded but no token received.');
          return false;
        }
      } else {
        final errorMsg = response.error ?? 'Registration failed. Please try again.';
        onError?.call(errorMsg);
        if (kDebugMode) {
          print('❌ OnboardingService: Registration failed - $errorMsg');
        }
        return false;
      }
    } catch (e) {
      final errorMsg = 'Network error: $e';
      onError?.call(errorMsg);
      if (kDebugMode) {
        print('❌ OnboardingService: Registration error - $e');
      }
      return false;
    }
  }

  /// ✅ NEW: Load initial session data into app state
  Future<void> _loadInitialSessionIntoAppState(Map<String, dynamic> sessionData) async {
    try {
      final appState = AppStateService.instance;
      
      // Parse session data
      final drillsJson = sessionData['drills'] as List<dynamic>? ?? [];
      final focusAreas = (sessionData['focus_areas'] as List<dynamic>?)?.cast<String>() ?? [];
      
      if (kDebugMode) {
        print('🔄 OnboardingService: Loading ${drillsJson.length} drills into app state');
        print('   Focus areas: $focusAreas');
      }
      
      // Convert drill JSON to DrillModel objects
      final drillModels = <DrillModel>[];
      for (final drillJson in drillsJson) {
        final drill = drillJson as Map<String, dynamic>;
        
        // Extract skill information
        String skill = 'General';
        final subSkills = <String>[];
        
        final primarySkill = drill['primary_skill'] as Map<String, dynamic>?;
        if (primarySkill != null) {
          skill = _mapSkillCategory(primarySkill['category'] as String? ?? 'general');
          final subSkill = primarySkill['sub_skill'] as String?;
          if (subSkill != null) {
            subSkills.add(_mapSubSkill(subSkill));
          }
        }
        
        // Create DrillModel
        final drillModel = DrillModel(
          id: drill['uuid'] as String? ?? '',
          title: drill['title'] as String? ?? 'Unnamed Drill',
          skill: skill,
          subSkills: subSkills,
          sets: drill['sets'] as int? ?? 3,
          reps: drill['reps'] as int? ?? 10,
          duration: drill['duration'] as int? ?? 10,
          description: drill['description'] as String? ?? '',
          instructions: (drill['instructions'] as List<dynamic>?)?.cast<String>() ?? [],
          tips: (drill['tips'] as List<dynamic>?)?.cast<String>() ?? [],
          equipment: (drill['equipment'] as List<dynamic>?)?.cast<String>() ?? [],
          trainingStyle: drill['intensity'] as String? ?? 'medium',
          difficulty: drill['difficulty'] as String? ?? 'beginner',
          videoUrl: drill['video_url'] as String? ?? '',
          isCustom: false, // ✅ ADDED: Set isCustom to false for onboarding drills
        );
        
        drillModels.add(drillModel);
      }
      
      // Convert to EditableDrillModel objects for session
      final editableDrills = drillModels.map((drill) => EditableDrillModel(
        drill: drill,
        setsDone: 0,
        totalSets: drill.sets > 0 ? drill.sets : 3,
        totalReps: drill.reps > 0 ? drill.reps : 10,
        totalDuration: drill.duration > 0 ? drill.duration : 10,
        isCompleted: false,
      )).toList();
      
      // ✅ Load drills into app state as the initial session
      appState.updateOrderedSessionDrillsThroughPreferences(editableDrills);
      
      // ✅ Set user preferences based on focus areas
      if (focusAreas.isNotEmpty) {
        // Map focus areas to frontend skill names and update preferences
        final frontendSkills = focusAreas.map((area) => _mapSubSkill(area)).toSet();
        
        // Update app state with these skills as selected
        appState.updateSkillsFilter(frontendSkills);
        
        if (kDebugMode) {
          print('✅ OnboardingService: Updated preferences with skills: $frontendSkills');
        }
      }
      
      // ✅ ENHANCED: Also set sub-skills based on what user said they want to work on
      // This handles the case where the user selected main categories in onboarding
      // but we need to populate specific sub-skills for the session editor
      final appStateInstance = AppStateService.instance;
      final currentPreferences = appStateInstance.preferences;
      
      // If no specific sub-skills were set from focus areas, derive them from session drills
      if (currentPreferences.selectedSkills.isEmpty && drillModels.isNotEmpty) {
        final derivedSubSkills = <String>{};
        
        // Extract unique sub-skills from the generated session drills
        for (final drill in drillModels) {
          derivedSubSkills.addAll(drill.subSkills);
        }
        
        if (derivedSubSkills.isNotEmpty) {
          appState.updateSkillsFilter(derivedSubSkills);
          if (kDebugMode) {
            print('✅ OnboardingService: Derived and set sub-skills from session drills: $derivedSubSkills');
          }
        }
      }
      
      // ✅ NEW: Set duration preference based on session data
      final totalDuration = sessionData['total_duration'] as int? ?? 30;
      String timePreference = '30min'; // Default
      
      if (totalDuration <= 15) {
        timePreference = '15min';
      } else if (totalDuration <= 30) {
        timePreference = '30min';
      } else if (totalDuration <= 45) {
        timePreference = '45min';
      } else if (totalDuration <= 60) {
        timePreference = '1h';
      } else if (totalDuration <= 90) {
        timePreference = '1h30';
      } else {
        timePreference = '2h+';
      }
      
      // Update time preference in app state
      appState.updateTimeFilter(timePreference);
      
      // ✅ NEW: Clear unwanted preferences that should remain empty after onboarding
      appState.updateTrainingStyleFilter(null);
      appState.updateLocationFilter(null);
      appState.updateDifficultyFilter(null);
      
      // ✅ NEW: Automatically select "soccer ball" as equipment (do this LAST to avoid it being overwritten)
      const soccerBallEquipment = 'soccer ball';
      // Force an equipment update that will persist through backend syncing
      final currentEquipment = Set<String>.from(appState.preferences.selectedEquipment);
      currentEquipment.add(soccerBallEquipment);
      appState.updateEquipmentFilter(currentEquipment);
      
      // ✅ EXTRA SAFETY: Ensure the preference persists by doing it again after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        final finalEquipment = Set<String>.from(appState.preferences.selectedEquipment);
        if (!finalEquipment.contains(soccerBallEquipment)) {
          finalEquipment.add(soccerBallEquipment);
          appState.updateEquipmentFilter(finalEquipment);
          if (kDebugMode) {
            print('🔧 OnboardingService: Re-applied soccer ball equipment after delay');
          }
        }
        
        // ✅ DOUBLE-CHECK: Ensure other preferences stay null
        appState.updateTrainingStyleFilter(null);
        appState.updateLocationFilter(null);
        appState.updateDifficultyFilter(null);
      });
      
      if (kDebugMode) {
        print('✅ OnboardingService: Updated time preference to: $timePreference (${totalDuration}min)');
        print('✅ OnboardingService: Automatically selected soccer ball as equipment');
        print('✅ OnboardingService: Cleared training style, location, and difficulty (should remain empty)');
        print('   Selected equipment after update: ${appState.preferences.selectedEquipment}');
        print('   Equipment contains soccer ball: ${appState.preferences.selectedEquipment.contains(soccerBallEquipment)}');
        print('   Current equipment set size: ${appState.preferences.selectedEquipment.length}');
        print('   Training style: ${appState.preferences.selectedTrainingStyle}');
        print('   Location: ${appState.preferences.selectedLocation}');
        print('   Difficulty: ${appState.preferences.selectedDifficulty}');
        print('✅ OnboardingService: Successfully loaded ${editableDrills.length} drills into session');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ OnboardingService: Error loading initial session: $e');
      }
      // Don't throw error - this is not critical for registration success
    }
  }

  /// ✅ Helper: Map backend skill category to frontend display name
  String _mapSkillCategory(String backendCategory) {
    const categoryMap = {
      'passing': 'Passing',
      'shooting': 'Shooting',
      'dribbling': 'Dribbling',
      'first_touch': 'First Touch',
      'defending': 'Defending',
      'fitness': 'Fitness',
      'general': 'General',
    };
    
    return categoryMap[backendCategory.toLowerCase()] ?? 'General';
  }

  /// ✅ Helper: Map backend sub-skill to frontend display name
  String _mapSubSkill(String backendSubSkill) {
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
} 