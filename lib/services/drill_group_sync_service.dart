import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/drill_group_model.dart';
import '../models/drill_model.dart';
import '../models/api_response_models.dart';
import '../models/drill_group_response_models.dart';
import 'api_service.dart';
import 'drill_api_service.dart';

/// Drill Group Sync Service
/// Handles fetching and syncing drill groups with the backend
/// Mirrors the Swift DrillGroupService functionality
class DrillGroupSyncService {
  static final DrillGroupSyncService _instance = DrillGroupSyncService._internal();
  factory DrillGroupSyncService() => _instance;
  DrillGroupSyncService._internal();

  static DrillGroupSyncService get shared => _instance;

  final ApiService _apiService = ApiService.shared;
  final DrillApiService _drillApiService = DrillApiService.shared;

  // MARK: - Drill Group Methods

  /// Get all drill groups for the current user
  Future<List<DrillGroupResponse>> getAllDrillGroups() async {
    try {
      if (kDebugMode) {
        print('📥 Fetching all drill groups from backend...');
      }

      final response = await _apiService.get(
        '/api/drill-groups/',
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        if (kDebugMode) {
          print('📥 Raw response data type: ${response.data.runtimeType}');
          print('📥 Raw response data: ${response.data}');
        }
        
        // Handle the response data properly
        List<dynamic> groupsJson;
        if (response.data is List) {
          groupsJson = response.data as List<dynamic>;
          if (kDebugMode) {
            print('📥 Parsed as List with ${groupsJson.length} items');
          }
        } else if (response.data is Map<String, dynamic>) {
          // Handle wrapped response format
          final data = response.data as Map<String, dynamic>;
          final dataField = data['data'] ?? data['items'] ?? [];
          if (dataField is List) {
            groupsJson = dataField;
            if (kDebugMode) {
              print('📥 Parsed as wrapped response with ${groupsJson.length} items');
            }
          } else {
            groupsJson = [];
            if (kDebugMode) {
              print('📥 Data field is not a List, using empty list');
            }
          }
        } else {
          if (kDebugMode) {
            print('📥 Response is not a List or Map, using empty list');
          }
          groupsJson = [];
        }
        
        final groups = groupsJson
            .map((groupJson) => DrillGroupResponse.fromJson(groupJson))
            .toList();

        if (kDebugMode) {
          print('✅ Successfully fetched ${groups.length} drill groups');
        }
        return groups;
      } else {
        if (kDebugMode) {
          print('❌ Failed to fetch drill groups: ${response.statusCode} ${response.error}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching drill groups: $e');
      }
      return [];
    }
  }

  /// Get a specific drill group by ID
  Future<DrillGroupResponse?> getDrillGroup(int groupId) async {
    try {
      if (kDebugMode) {
        print('📥 Fetching drill group $groupId from backend...');
      }

      final response = await _apiService.get(
        '/api/drill-groups/$groupId',
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        final group = DrillGroupResponse.fromJson(response.data!);
        if (kDebugMode) {
          print('✅ Successfully fetched drill group: ${group.name}');
        }
        return group;
      } else {
        if (kDebugMode) {
          print('❌ Failed to fetch drill group $groupId: ${response.statusCode} ${response.error}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching drill group $groupId: $e');
      }
      return null;
    }
  }

  /// Create a new drill group
  Future<DrillGroupResponse?> createDrillGroup({
    required String name,
    required String description,
    List<String> drillUuids = const [], // Changed from drillIds to drillUuids
    bool isLikedGroup = false,
  }) async {
    try {
      if (kDebugMode) {
        print('📤 Creating drill group: $name');
      }

      final request = DrillGroupRequest(
        name: name,
        description: description,
        drillUuids: drillUuids,
        isLikedGroup: isLikedGroup,
      );

      final response = await _apiService.post(
        '/api/drill-groups/',
        body: request.toJson(),
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        final group = DrillGroupResponse.fromJson(response.data!);
        if (kDebugMode) {
          print('✅ Successfully created drill group: ${group.name}');
        }
        return group;
      } else {
        if (kDebugMode) {
          print('❌ Failed to create drill group: ${response.statusCode} ${response.error}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating drill group: $e');
      }
      return null;
    }
  }

  /// Update an existing drill group
  Future<DrillGroupResponse?> updateDrillGroup({
    required int groupId,
    required String name,
    required String description,
    required List<String> drillUuids, // Changed from drillIds to drillUuids
    required bool isLikedGroup,
  }) async {
    try {
      if (kDebugMode) {
        print('📤 Updating drill group $groupId: $name');
      }

      final request = DrillGroupRequest(
        name: name,
        description: description,
        drillUuids: drillUuids,
        isLikedGroup: isLikedGroup,
      );

      final response = await _apiService.put(
        '/api/drill-groups/$groupId',
        body: request.toJson(),
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        final group = DrillGroupResponse.fromJson(response.data!);
        if (kDebugMode) {
          print('✅ Successfully updated drill group: ${group.name}');
        }
        return group;
      } else {
        if (kDebugMode) {
          print('❌ Failed to update drill group $groupId: ${response.statusCode} ${response.error}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating drill group $groupId: $e');
      }
      return null;
    }
  }

  /// Delete a drill group
  Future<bool> deleteDrillGroup(int groupId) async {
    try {
      if (kDebugMode) {
        print('🗑️ Deleting drill group $groupId...');
      }

      final response = await _apiService.delete(
        '/api/drill-groups/$groupId',
        requiresAuth: true,
      );

      if (response.isSuccess) {
        if (kDebugMode) {
          print('✅ Successfully deleted drill group $groupId');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('❌ Failed to delete drill group $groupId: ${response.statusCode} ${response.error}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting drill group $groupId: $e');
      }
      return false;
    }
  }

  // MARK: - Drill in Group Methods

  /// Add a drill to a group
  Future<bool> addDrillToGroup(int groupId, String drillId) async { // Changed from int to String
    try {
      if (kDebugMode) {
        print('📤 Adding drill $drillId to group $groupId...');
      }

      final response = await _apiService.post(
        '/api/drill-groups/$groupId/drills/$drillId',
        requiresAuth: true,
      );

      if (response.isSuccess) {
        if (kDebugMode) {
          print('✅ Successfully added drill $drillId to group $groupId');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('❌ Failed to add drill $drillId to group $groupId: ${response.statusCode} ${response.error}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error adding drill $drillId to group $groupId: $e');
      }
      return false;
    }
  }

  /// Remove a drill from a group
  Future<bool> removeDrillFromGroup(int groupId, String drillId) async { // Changed from int to String
    try {
      if (kDebugMode) {
        print('🗑️ Removing drill $drillId from group $groupId...');
      }

      final response = await _apiService.delete(
        '/api/drill-groups/$groupId/drills/$drillId',
        requiresAuth: true,
      );

      if (response.isSuccess) {
        if (kDebugMode) {
          print('✅ Successfully removed drill $drillId from group $groupId');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('❌ Failed to remove drill $drillId from group $groupId: ${response.statusCode} ${response.error}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error removing drill $drillId from group $groupId: $e');
      }
      return false;
    }
  }

  // MARK: - Liked Drills Methods

  /// Get or create the Liked Drills group
  Future<DrillGroupResponse?> getLikedDrillsGroup() async {
    try {
      if (kDebugMode) {
        print('📥 Fetching liked drills group...');
      }

      final response = await _apiService.get(
        '/api/liked-drills',
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        final group = DrillGroupResponse.fromJson(response.data!);
        if (kDebugMode) {
          print('✅ Successfully fetched liked drills group: ${group.name}');
        }
        return group;
      } else {
        if (kDebugMode) {
          print('❌ Failed to fetch liked drills group: ${response.statusCode} ${response.error}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching liked drills group: $e');
      }
      return null;
    }
  }

  /// Toggle like status for a drill
  Future<DrillLikeResponse?> toggleDrillLike(String drillId) async { // Changed from int to String
    try {
      if (kDebugMode) {
        print('❤️ Toggling like status for drill $drillId...');
      }

      final response = await _apiService.post(
        '/api/drills/$drillId/like',
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        final likeResponse = DrillLikeResponse.fromJson(response.data!);
        if (kDebugMode) {
          print('✅ Successfully toggled like status for drill $drillId: ${likeResponse.isLiked}');
        }
        return likeResponse;
      } else {
        if (kDebugMode) {
          print('❌ Failed to toggle like status for drill $drillId: ${response.statusCode} ${response.error}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error toggling like status for drill $drillId: $e');
      }
      return null;
    }
  }

  /// Check if a drill is liked
  Future<bool> checkDrillLiked(String drillId) async { // Changed from int to String
    try {
      if (kDebugMode) {
        print('🔍 Checking if drill $drillId is liked...');
      }

      final response = await _apiService.get(
        '/api/drills/$drillId/like',
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        final isLikedResponse = IsLikedResponse.fromJson(response.data!);
        if (kDebugMode) {
          print('✅ Drill $drillId is liked: ${isLikedResponse.isLiked}');
        }
        return isLikedResponse.isLiked;
      } else {
        if (kDebugMode) {
          print('❌ Failed to check like status for drill $drillId: ${response.statusCode} ${response.error}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking like status for drill $drillId: $e');
      }
      return false;
    }
  }

  // MARK: - Multiple Drills Methods

  /// Add multiple drills to a group at once
  Future<bool> addMultipleDrillsToGroup(int groupId, List<String> drillUuids) async { // Changed from drillIds to drillUuids
    try {
      if (kDebugMode) {
        print('📤 Adding ${drillUuids.length} drills to group $groupId...');
      }

      final response = await _apiService.post(
        '/api/drill-groups/$groupId/drills',
        body: {'drill_uuids': drillUuids}, // Changed from drill_ids to drill_uuids
        requiresAuth: true,
      );

      if (response.isSuccess) {
        if (kDebugMode) {
          print('✅ Successfully added ${drillUuids.length} drills to group $groupId');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('❌ Failed to add drills to group $groupId: ${response.statusCode} ${response.error}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error adding drills to group $groupId: $e');
      }
      return false;
    }
  }

  /// Add multiple drills to the liked drills group
  Future<bool> addMultipleDrillsToLikedGroup(List<String> drillUuids) async { // Changed from drillIds to drillUuids
    try {
      if (kDebugMode) {
        print('❤️ Adding ${drillUuids.length} drills to liked group...');
      }

      final response = await _apiService.post(
        '/api/liked-drills/add',
        body: {'drill_uuids': drillUuids}, // Changed from drill_ids to drill_uuids
        requiresAuth: true,
      );

      if (response.isSuccess) {
        if (kDebugMode) {
          print('✅ Successfully added ${drillUuids.length} drills to liked group');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('❌ Failed to add drills to liked group: ${response.statusCode} ${response.error}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error adding drills to liked group: $e');
      }
      return false;
    }
  }

  // MARK: - Sync Methods

  /// Sync all drill groups to backend (mirrors Swift syncAllDrillGroups)
  Future<void> syncAllDrillGroups({
    required List<DrillGroup> savedGroups,
    required DrillGroup likedGroup,
  }) async {
    try {
      if (kDebugMode) {
        print('🔄 Syncing all drill groups to backend...');
      }
      
      // Get existing groups from backend
      final existingGroups = await getAllDrillGroups();
      if (kDebugMode) {
        print('📥 Fetched ${existingGroups.length} existing groups from backend');
      }
      
      // Sync liked drills group - use UUIDs directly
      final likedDrillUuids = likedGroup.drills.map((drill) => drill.id).toList();
      
      // Always sync liked drills group, even if empty
      DrillGroupResponse? existingLikedGroup;
      try {
        existingLikedGroup = existingGroups.firstWhere(
          (group) => group.isLikedGroup,
        );
      } catch (e) {
        // No existing liked group found
        existingLikedGroup = null;
      }
      
      if (existingLikedGroup != null) {
        // Update existing liked group (even if empty)
        await updateDrillGroup(
          groupId: existingLikedGroup.id,
          name: 'Liked Drills',
          description: 'Your favorite drills',
          drillUuids: likedDrillUuids,
          isLikedGroup: true,
        );
        if (kDebugMode) {
          print('✅ Updated liked drills group with ${likedDrillUuids.length} drills');
        }
      } else if (likedDrillUuids.isNotEmpty) {
        // Only create new liked group if there are drills to add
        await createDrillGroup(
          name: 'Liked Drills',
          description: 'Your favorite drills',
          drillUuids: likedDrillUuids,
          isLikedGroup: true,
        );
        if (kDebugMode) {
          print('✅ Created new liked drills group with ${likedDrillUuids.length} drills');
        }
      }
      
      // Sync saved drill groups - use UUIDs directly
      for (final group in savedGroups) {
        final drillUuids = group.drills.map((drill) => drill.id).toList();
        
        if (kDebugMode) {
          print('🔄 Syncing group: "${group.name}" (ID: ${group.id})');
        }
        
        // Try to find matching existing group by ID (not name)
        DrillGroupResponse? existingGroup;
        try {
          // Match by ID - convert backend int ID to string for comparison
          existingGroup = existingGroups.firstWhere(
            (backendGroup) => backendGroup.id.toString() == group.id && !backendGroup.isLikedGroup,
          );
          if (kDebugMode) {
            print('📍 Found existing group: "${existingGroup.name}" (Backend ID: ${existingGroup.id})');
          }
        } catch (e) {
          // No matching group found - this happens for newly created groups or when ID doesn't match
          existingGroup = null;
          if (kDebugMode) {
            print('📍 No existing group found for ID: ${group.id}');
          }
        }
        
        if (existingGroup != null) {
          // Update existing group
          await updateDrillGroup(
            groupId: existingGroup.id,
            name: group.name,
            description: group.description,
            drillUuids: drillUuids,
            isLikedGroup: false,
          );
          if (kDebugMode) {
            print('✅ Updated group: "${group.name}" (ID: ${existingGroup.id})');
          }
        } else {
          // Create new group
          final newGroup = await createDrillGroup(
            name: group.name,
            description: group.description,
            drillUuids: drillUuids,
            isLikedGroup: false,
          );
          if (kDebugMode) {
            print('✅ Created new group: "${group.name}" (New ID: ${newGroup?.id})');
          }
        }
      }
      
      if (kDebugMode) {
        print('✅ Successfully synced all drill groups');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error syncing drill groups: $e');
      }
    }
  }

  // MARK: - Conversion Methods

  /// Convert DrillGroupResponse to local DrillGroup model
  DrillGroup convertToLocalModel(DrillGroupResponse response) {
    // Convert DrillResponse objects to DrillModel objects
    final drillModels = response.drills.map((drillResponse) {
      return _drillApiService.convertToLocalModel(drillResponse);
    }).toList();

    return DrillGroup(
      id: response.id.toString(), // Convert int ID to string for local model
      name: response.name,
      description: response.description,
      drills: drillModels,
      createdAt: DateTime.now(), // Backend doesn't provide creation date, use current time
      isLikedDrillsGroup: response.isLikedGroup,
    );
  }

  /// Convert multiple DrillGroupResponse objects to local DrillGroup objects
  List<DrillGroup> convertToLocalModels(List<DrillGroupResponse> responses) {
    return responses.map((response) => convertToLocalModel(response)).toList();
  }
} 