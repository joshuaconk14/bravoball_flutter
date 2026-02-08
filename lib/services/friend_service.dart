import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/friend_model.dart';

class FriendService {
  static final FriendService shared = FriendService._internal();
  FriendService._internal();

  /// Get list of all friends
  Future<List<Friend>> getFriends() async {
    try {
      final response = await ApiService.shared.get(
        '/api/friends',
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        // Parse friends from response
        // API service wraps List responses in {'data': [...]}
        dynamic friendsData = response.data;
        
        // Check if response.data is a Map with 'data' key (wrapped array)
        if (friendsData is Map<String, dynamic> && friendsData.containsKey('data')) {
          friendsData = friendsData['data'];
        }
        
        // Now check if it's a List
        final List<dynamic> friendsJson = friendsData is List
            ? friendsData
            : [];

        final List<Friend> friends = friendsJson
            .map((json) => Friend.fromJson(json as Map<String, dynamic>))
            .toList();

        if (kDebugMode) {
          print('✅ FriendService: Retrieved ${friends.length} friends');
        }

        return friends;
      } else {
        if (kDebugMode) {
          print('❌ FriendService: API call failed - ${response.error}');
        }
        throw Exception(response.error ?? 'Failed to fetch friends');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FriendService: Error fetching friends: $e');
      }
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        throw Exception('Unauthorized - please log in again');
      } else {
        throw Exception('Failed to fetch friends');
      }
    }
  }

  /// Get list of incoming friend requests
  Future<List<FriendRequest>> getFriendRequests() async {
    try {
      final response = await ApiService.shared.get(
        '/api/friends/requests',
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        // Parse friend requests from response
        dynamic requestsData = response.data;
        
        if (requestsData is Map<String, dynamic> && requestsData.containsKey('data')) {
          requestsData = requestsData['data'];
        }
        
        final List<dynamic> requestsJson = requestsData is List
            ? requestsData
            : [];

        final List<FriendRequest> requests = requestsJson
            .map((json) => FriendRequest.fromJson(json as Map<String, dynamic>))
            .toList();

        if (kDebugMode) {
          print('✅ FriendService: Retrieved ${requests.length} friend requests');
        }

        return requests;
      } else {
        if (kDebugMode) {
          print('❌ FriendService: API call failed - ${response.error}');
        }
        throw Exception(response.error ?? 'Failed to fetch friend requests');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FriendService: Error fetching friend requests: $e');
      }
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        throw Exception('Unauthorized - please log in again');
      } else {
        throw Exception('Failed to fetch friend requests');
      }
    }
  }

  /// Send a friend request
  Future<bool> sendFriendRequest(int addresseeId) async {
    try {
      final response = await ApiService.shared.post(
        '/api/friends/send',
        body: {
          'addressee_id': addresseeId,
        },
        requiresAuth: true,
      );

      if (response.isSuccess) {
        if (kDebugMode) {
          print('✅ FriendService: Friend request sent successfully');
        }
        return true;
      } else {
        throw Exception(response.error ?? 'Failed to send friend request');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FriendService: Error sending friend request: $e');
      }
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        throw Exception('Unauthorized - please log in again');
      } else {
        throw Exception('Failed to send friend request');
      }
    }
  }

  /// Accept a friend request
  Future<bool> acceptFriendRequest(int requestId) async {
    try {
      final response = await ApiService.shared.post(
        '/api/friends/accept/$requestId',
        requiresAuth: true,
      );

      if (response.isSuccess) {
        if (kDebugMode) {
          print('✅ FriendService: Friend request accepted successfully');
        }
        return true;
      } else {
        throw Exception(response.error ?? 'Failed to accept friend request');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FriendService: Error accepting friend request: $e');
      }
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        throw Exception('Unauthorized - please log in again');
      } else {
        throw Exception('Failed to accept friend request');
      }
    }
  }

  /// Decline a friend request
  Future<bool> declineFriendRequest(int requestId) async {
    try {
      final response = await ApiService.shared.post(
        '/api/friends/decline/$requestId',
        requiresAuth: true,
      );

      if (response.isSuccess) {
        if (kDebugMode) {
          print('✅ FriendService: Friend request declined successfully');
        }
        return true;
      } else {
        throw Exception(response.error ?? 'Failed to decline friend request');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FriendService: Error declining friend request: $e');
      }
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        throw Exception('Unauthorized - please log in again');
      } else {
        throw Exception('Failed to decline friend request');
      }
    }
  }

  /// Remove a friend
  Future<bool> removeFriend(int friendshipId) async {
    try {
      final response = await ApiService.shared.delete(
        '/api/friends/remove/$friendshipId',
        requiresAuth: true,
      );

      if (response.isSuccess) {
        if (kDebugMode) {
          print('✅ FriendService: Friend removed successfully');
        }
        return true;
      } else {
        throw Exception(response.error ?? 'Failed to remove friend');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FriendService: Error removing friend: $e');
      }
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        throw Exception('Unauthorized - please log in again');
      } else {
        throw Exception('Failed to remove friend');
      }
    }
  }

  /// Get friend details including stats
  Future<FriendDetail?> getFriendDetail(int userId) async {
    try {
      final response = await ApiService.shared.get(
        '/api/friends/$userId',
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        // Handle wrapped response
        dynamic friendData = response.data;
        if (friendData is Map<String, dynamic> && friendData.containsKey('data')) {
          friendData = friendData['data'];
        }
        
        final friendDataMap = friendData is Map<String, dynamic>
            ? friendData
            : <String, dynamic>{};
        
        final friendDetail = FriendDetail.fromJson(friendDataMap);
        
        if (kDebugMode) {
          print('✅ FriendService: Retrieved friend details for user ID $userId');
        }
        
        return friendDetail;
      } else {
        if (response.statusCode == 404) {
          if (kDebugMode) {
            print('❌ FriendService: Friend not found for user ID $userId');
          }
          return null;
        }
        
        if (kDebugMode) {
          print('❌ FriendService: API call failed - ${response.error}');
        }
        throw Exception(response.error ?? 'Failed to fetch friend details');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FriendService: Error fetching friend details: $e');
      }
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        throw Exception('Unauthorized - please log in again');
      } else {
        throw Exception('Failed to fetch friend details');
      }
    }
  }

  /// Lookup user by username (returns user ID, username, avatar, and background color)
  Future<UserLookupResult?> lookupUserByUsername(String username) async {
    try {
      final response = await ApiService.shared.get(
        '/api/user/lookup/$username',
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        // Handle wrapped response
        dynamic userData = response.data;
        if (userData is Map<String, dynamic> && userData.containsKey('data')) {
          userData = userData['data'];
        }
        
        final userDataMap = userData is Map<String, dynamic>
            ? userData
            : <String, dynamic>{};
        
        final lookupResult = UserLookupResult.fromJson(userDataMap);
        
        if (kDebugMode) {
          print('✅ FriendService: Found user ID ${lookupResult.userId} for username $username');
        }
        
        return lookupResult;
      } else {
        // Check if it's a 404 (user not found)
        if (response.statusCode == 404) {
          if (kDebugMode) {
            print('❌ FriendService: User not found for username $username');
          }
          return null;
        }
        
        if (kDebugMode) {
          print('❌ FriendService: API call failed - ${response.error}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FriendService: Error looking up user: $e');
      }
      return null;
    }
  }
}
