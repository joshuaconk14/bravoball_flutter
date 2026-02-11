import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Connectivity Service
/// Monitors network connectivity status and notifies listeners when it changes
class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  static ConnectivityService get instance => _instance;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  
  bool _isOnline = true; // Start optimistic (assume online)
  bool get isOnline => _isOnline;

  /// Initialize the connectivity service
  /// Checks initial status and starts listening for changes
  Future<void> initialize() async {
    try {
      // Check initial status immediately
      final result = await _connectivity.checkConnectivity();
      _updateStatus(result);
      
      // Listen for changes
      _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
      
      if (kDebugMode) {
        print('🌐 ConnectivityService initialized - Status: ${_isOnline ? "Online" : "Offline"}');
        print('🌐 Connectivity results: $result');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ ConnectivityService initialization error: $e');
      }
      // Default to online if check fails (optimistic approach)
      _isOnline = true;
      notifyListeners();
    }
  }

  /// Update connectivity status based on connectivity results
  void _updateStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    
    // Consider online if any connection type is available (not ConnectivityResult.none)
    // Handle empty list as offline
    if (results.isEmpty) {
      _isOnline = false;
    } else {
      // Check if any result indicates a connection (not none)
      _isOnline = results.any((result) => result != ConnectivityResult.none);
    }
    
    if (wasOnline != _isOnline) {
      notifyListeners();
      if (kDebugMode) {
        print('🌐 Connectivity changed: ${_isOnline ? "Online" : "Offline"}');
        print('🌐 Connectivity results: $results');
      }
    } else if (kDebugMode) {
      // Log even when status hasn't changed for debugging
      print('🌐 Connectivity status unchanged: ${_isOnline ? "Online" : "Offline"}');
      print('🌐 Connectivity results: $results');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

