import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'audio_service.dart';
import 'notification_service.dart';

/// Background Timer Service
/// Keeps drill timers running even when phone screen is off
/// Uses silent audio background playback to maintain app activity
/// Shows live timer widget on lock screen similar to RunKeeper
class BackgroundTimerService {
  static final BackgroundTimerService _instance = BackgroundTimerService._internal();
  factory BackgroundTimerService() => _instance;
  BackgroundTimerService._internal();

  static BackgroundTimerService get shared => _instance;

  // Audio players
  static final AudioPlayer _backgroundPlayer = AudioPlayer();
  static final AudioPlayer _effectsPlayer = AudioPlayer();
  
  // Services
  final NotificationService _notificationService = NotificationService.shared;
  
  // Timer state
  Timer? _timer;
  Timer? _countdownTimer;
  
  // Background session state
  bool _isBackgroundSessionActive = false;
  bool _isTimerRunning = false;
  bool _isTimerPaused = false;
  
  // Timer data for lock screen widget
  String _currentDrillName = '';
  int _totalDurationSeconds = 0;
  int _remainingSeconds = 0;
  
  // Timer callbacks
  Function(int)? _onTimerTick;
  Function()? _onTimerComplete;
  Function(int)? _onCountdownTick;
  Function()? _onCountdownComplete;

  /// Initialize background audio session and notifications
  Future<void> initializeBackgroundSession() async {
    try {
      // Configure background audio session
      await _backgroundPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
      
      // Initialize notification service
      await _notificationService.initialize();
      
      if (kDebugMode) {
        print('🎵 Background timer session initialized with lock screen widget support');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing background session: $e');
      }
    }
  }

  /// Start countdown with background support and lock screen widget
  Future<void> startCountdown({
    int countdownValue = 3,
    String drillName = 'Drill Timer',
    Function(int)? onTick,
    Function()? onComplete,
  }) async {
    _onCountdownTick = onTick;
    _onCountdownComplete = onComplete;
    _currentDrillName = drillName;
    
    // Start background audio session
    await _startBackgroundAudio();
    
    // Cancel any existing countdown
    _countdownTimer?.cancel();
    
    // Play countdown start sound
    AudioService.playCountdownStart();
    HapticFeedback.mediumImpact();
    
    if (kDebugMode) {
      print('⏱️ Starting background countdown: $countdownValue for $_currentDrillName');
    }
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdownValue > 1) {
        countdownValue--;
        _onCountdownTick?.call(countdownValue);
        HapticFeedback.lightImpact();
        
        if (kDebugMode) {
          print('⏱️ Countdown: $countdownValue');
        }
      } else {
        timer.cancel();
        _onCountdownComplete?.call();
        HapticFeedback.heavyImpact();
        
        if (kDebugMode) {
          print('✅ Countdown complete - starting timer with lock screen widget');
        }
      }
    });
  }

  /// Start drill timer with background support and live lock screen widget
  Future<void> startTimer({
    required double durationSeconds,
    String drillName = 'Drill Timer',
    Function(int)? onTick,
    Function()? onComplete,
    bool debugMode = false,
  }) async {
    _onTimerTick = onTick;
    _onTimerComplete = onComplete;
    _currentDrillName = drillName;
    _totalDurationSeconds = durationSeconds.toInt();
    _remainingSeconds = _totalDurationSeconds;
    
    // Ensure background audio is running
    await _startBackgroundAudio();
    
    // Cancel any existing timer
    _timer?.cancel();
    
    _isTimerRunning = true;
    _isTimerPaused = false;
    int elapsedTime = durationSeconds.toInt();
    bool finalCountdownPlayed = false;
    
    // Start lock screen notification widget
    await _notificationService.startTimerNotification(
      drillName: _currentDrillName,
      totalDurationSeconds: _totalDurationSeconds,
      remainingSeconds: _remainingSeconds,
      isPaused: false,
    );
    
    // Use faster timer in debug mode
    final timerInterval = debugMode 
        ? const Duration(milliseconds: 100) 
        : const Duration(seconds: 1);
    final timeDecrement = debugMode ? 1.0 : 1.0;
    
    if (kDebugMode) {
      print('🎯 Starting background timer with lock screen widget: ${elapsedTime}s (debug: $debugMode)');
    }
    
    _timer = Timer.periodic(timerInterval, (timer) {
      if (!_isTimerRunning || _isTimerPaused) {
        timer.cancel();
        return;
      }
      
      if (elapsedTime > 0) {
        elapsedTime = (elapsedTime - timeDecrement).toInt();
        _remainingSeconds = elapsedTime;
        _onTimerTick?.call(elapsedTime);
        
        // Update lock screen widget every second (or every 10th update in debug mode)
        if (!debugMode || elapsedTime % 10 == 0) {
          _notificationService.updateTimerNotification(
            drillName: _currentDrillName,
            totalDurationSeconds: _totalDurationSeconds,
            remainingSeconds: _remainingSeconds,
            isPaused: false,
          );
        }
        
        // Play final countdown at 3 seconds (only once)
        if (elapsedTime <= 3 && elapsedTime > 0 && !finalCountdownPlayed) {
          finalCountdownPlayed = true;
          AudioService.playCountdownFinal();
        }
        
        // Haptic feedback at intervals (only in normal mode)
        if (!debugMode) {
          if (elapsedTime == 30 || elapsedTime == 10) {
            HapticFeedback.lightImpact();
          } else if (elapsedTime <= 3 && elapsedTime > 0) {
            HapticFeedback.mediumImpact();
          }
        }
        
        if (kDebugMode && elapsedTime % 10 == 0) {
          print('⏱️ Timer: ${elapsedTime}s remaining (Lock screen: ${_remainingSeconds}s)');
        }
      } else {
        // Timer complete
        timer.cancel();
        _isTimerRunning = false;
        _onTimerComplete?.call();
        HapticFeedback.heavyImpact();
        
        // Show completion notification and stop timer widget
        _notificationService.showTimerCompletionNotification(drillName: _currentDrillName);
        _notificationService.stopTimerNotification();
        
        if (kDebugMode) {
          print('✅ Timer complete! Lock screen widget updated.');
        }
      }
    });
  }

  /// Pause the timer (keeps background session active, updates lock screen)
  void pauseTimer() {
    _timer?.cancel();
    _isTimerRunning = false;
    _isTimerPaused = true;
    
    // Update lock screen widget to show paused state
    _notificationService.updateTimerNotification(
      drillName: _currentDrillName,
      totalDurationSeconds: _totalDurationSeconds,
      remainingSeconds: _remainingSeconds,
      isPaused: true,
    );
    
    if (kDebugMode) {
      print('⏸️ Timer paused (background session and lock screen widget maintained)');
    }
  }

  /// Resume the timer
  void resumeTimer() {
    _isTimerRunning = true;
    _isTimerPaused = false;
    
    // Update lock screen widget to show active state
    _notificationService.updateTimerNotification(
      drillName: _currentDrillName,
      totalDurationSeconds: _totalDurationSeconds,
      remainingSeconds: _remainingSeconds,
      isPaused: false,
    );
    
    if (kDebugMode) {
      print('▶️ Timer resumed with lock screen widget update');
    }
  }

  /// Stop the timer and clean up background session + lock screen widget
  Future<void> stopTimer() async {
    _timer?.cancel();
    _countdownTimer?.cancel();
    _isTimerRunning = false;
    _isTimerPaused = false;
    
    // Stop background audio session
    await _stopBackgroundAudio();
    
    // Stop lock screen widget
    await _notificationService.stopTimerNotification();
    
    if (kDebugMode) {
      print('🛑 Timer stopped, background session and lock screen widget ended');
    }
  }

  /// Start background audio to keep app active
  Future<void> _startBackgroundAudio() async {
    if (_isBackgroundSessionActive) return;
    
    try {
      // Play a very quiet/silent audio file on loop to keep app active
      await _backgroundPlayer.setVolume(0.01); // Almost silent
      await _backgroundPlayer.play(AssetSource('audio/silent-timer.mp3'));
      
      _isBackgroundSessionActive = true;
      
      if (kDebugMode) {
        print('🎵 Background audio started for timer with lock screen support');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error starting background audio: $e');
      }
    }
  }

  /// Stop background audio session
  Future<void> _stopBackgroundAudio() async {
    if (!_isBackgroundSessionActive) return;
    
    try {
      await _backgroundPlayer.stop();
      _isBackgroundSessionActive = false;
      
      if (kDebugMode) {
        print('🔇 Background audio stopped');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error stopping background audio: $e');
      }
    }
  }

  /// Check if timer is currently running
  bool get isTimerRunning => _isTimerRunning;
  
  /// Check if timer is currently paused
  bool get isTimerPaused => _isTimerPaused;
  
  /// Check if background session is active
  bool get isBackgroundSessionActive => _isBackgroundSessionActive;
  
  /// Check if lock screen widget is active
  bool get isLockScreenWidgetActive => _notificationService.isTimerNotificationActive;

  /// Dispose of all resources
  Future<void> dispose() async {
    await stopTimer();
    await _backgroundPlayer.dispose();
    await _effectsPlayer.dispose();
    
    if (kDebugMode) {
      print('🗑️ Background timer service disposed');
    }
  }
} 