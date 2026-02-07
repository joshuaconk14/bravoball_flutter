import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/leaderboard_model.dart';

class LeaderboardService {
  static final LeaderboardService shared = LeaderboardService._internal();
  LeaderboardService._internal();

  /// Get leaderboard data
  /// Returns all entries (current user + friends) sorted by points
  Future<List<LeaderboardEntry>> getLeaderboard() async {
    try {
      final response = await ApiService.shared.get(
        '/api/leaderboard/friends',
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        // Parse leaderboard entries from response
        // API service wraps List responses in {'data': [...]}
        dynamic entriesData = response.data;
        
        // Check if response.data is a Map with 'data' key (wrapped array)
        if (entriesData is Map<String, dynamic> && entriesData.containsKey('data')) {
          entriesData = entriesData['data'];
        }
        
        // Now check if it's a List
        final List<dynamic> entriesJson = entriesData is List
            ? entriesData
            : [];

        if (entriesJson.isEmpty) {
          if (kDebugMode) {
            print('⚠️ LeaderboardService: Empty leaderboard response');
            print('   Response data type: ${response.data.runtimeType}');
            print('   Response data: ${response.data}');
          }
          return [];
        }

        // Parse all entries
        final List<LeaderboardEntry> entries = entriesJson
            .map((json) => LeaderboardEntry.fromJson(json as Map<String, dynamic>))
            .toList();

        if (kDebugMode) {
          print('✅ LeaderboardService: Retrieved ${entries.length} leaderboard entries');
        }

        return entries;
      } else {
        if (kDebugMode) {
          print('❌ LeaderboardService: API call failed - ${response.error}');
        }
        throw Exception(response.error ?? 'Failed to fetch leaderboard');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ LeaderboardService: Error fetching leaderboard: $e');
      }
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        throw Exception('Unauthorized - please log in again');
      } else {
        throw Exception('Failed to fetch leaderboard');
      }
    }
  }

  /// Get world leaderboard data
  /// Returns top 50 users globally plus the current user's rank
  Future<WorldLeaderboardResponse> getWorldLeaderboard() async {
    try {
      final response = await ApiService.shared.get(
        '/api/leaderboard/world',
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        // Parse world leaderboard response
        dynamic responseData = response.data;
        
        // Check if response.data is wrapped in a 'data' key
        if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
          responseData = responseData['data'];
        }

        if (responseData is! Map<String, dynamic>) {
          if (kDebugMode) {
            print('⚠️ LeaderboardService: Invalid world leaderboard response format');
            print('   Response data type: ${response.data.runtimeType}');
          }
          throw Exception('Invalid response format');
        }

        final worldLeaderboard = WorldLeaderboardResponse.fromJson(responseData);

        if (kDebugMode) {
          print('✅ LeaderboardService: Retrieved world leaderboard');
          print('   Top 50 entries: ${worldLeaderboard.top50.length}');
          print('   User rank: #${worldLeaderboard.userRank.rank}');
        }

        return worldLeaderboard;
      } else {
        if (kDebugMode) {
          print('❌ LeaderboardService: World leaderboard API call failed - ${response.error}');
        }
        throw Exception(response.error ?? 'Failed to fetch world leaderboard');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ LeaderboardService: Error fetching world leaderboard: $e');
      }
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        throw Exception('Unauthorized - please log in again');
      } else {
        throw Exception('Failed to fetch world leaderboard');
      }
    }
  }
}
