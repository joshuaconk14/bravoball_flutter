import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'audio_service.dart';

/// Background Timer Service
/// Keeps drill timers running even when phone screen is off
/// Uses silent audio background playback to maintain app activity
class BackgroundTimerService {
  static final BackgroundTimerService _instance = BackgroundTimerService._internal();
  factory BackgroundTimerService() => _instance;
  BackgroundTimerService._internal();

  static BackgroundTimerService get shared => _instance;

  // Audio players
  static final AudioPlayer _backgroundPlayer = AudioPlayer();
  static final AudioPlayer _effectsPlayer = AudioPlayer();
  
  // Timer state
  Timer? _timer;
  Timer? _countdownTimer;
  
  // Background session state
  bool _isBackgroundSessionActive = false;
  bool _isTimerRunning = false;
  
  // Timer callbacks
  Function(int)? _onTimerTick;
  Function()? _onTimerComplete;
  Function(int)? _onCountdownTick;
  Function()? _onCountdownComplete;

  /// Initialize background audio session
  Future<void> initializeBackgroundSession() async {
    try {
      // Configure background audio session
      await _backgroundPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
      
      if (kDebugMode) {
        print('🎵 Background timer session initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing background session: $e');
      }
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
        print('🎵 Background audio started for timer');
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

  /// Start countdown with background support
  Future<void> startCountdown({
    int countdownValue = 3,
    Function(int)? onTick,
    Function()? onComplete,
  }) async {
    _onCountdownTick = onTick;
    _onCountdownComplete = onComplete;
    
    // Start background audio session
    await _startBackgroundAudio();
    
    // Cancel any existing countdown
    _countdownTimer?.cancel();
    
    // Play countdown start sound
    AudioService.playCountdownStart();
    HapticFeedback.mediumImpact();
    
    if (kDebugMode) {
      print('⏱️ Starting background countdown: $countdownValue');
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
          print('✅ Countdown complete - starting timer');
        }
      }
    });
  }

  /// Start drill timer with background support
  Future<void> startTimer({
    required double durationSeconds,
    Function(int)? onTick,
    Function()? onComplete,
    bool debugMode = false,
  }) async {
    _onTimerTick = onTick;
    _onTimerComplete = onComplete;
    
    // Ensure background audio is running
    await _startBackgroundAudio();
    
    // Cancel any existing timer
    _timer?.cancel();
    
    _isTimerRunning = true;
    int elapsedTime = durationSeconds.toInt();
    bool finalCountdownPlayed = false;
    
    // Use faster timer in debug mode
    final timerInterval = debugMode 
        ? const Duration(milliseconds: 100) 
        : const Duration(seconds: 1);
    final timeDecrement = debugMode ? 1.0 : 1.0;
    
    if (kDebugMode) {
      print('🎯 Starting background timer: ${elapsedTime}s (debug: $debugMode)');
    }
    
    _timer = Timer.periodic(timerInterval, (timer) {
      if (!_isTimerRunning) {
        timer.cancel();
        return;
      }
      
      if (elapsedTime > 0) {
        elapsedTime = (elapsedTime - timeDecrement).toInt();
        _onTimerTick?.call(elapsedTime);
        
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
          print('⏱️ Timer: ${elapsedTime}s remaining');
        }
      } else {
        // Timer complete
        timer.cancel();
        _isTimerRunning = false;
        _onTimerComplete?.call();
        HapticFeedback.heavyImpact();
        // Removed AudioService.playSuccess() - success sound is built into 321-done audio
        // and should only be used for trophy tapping in the app
        
        if (kDebugMode) {
          print('✅ Timer complete!');
        }
      }
    });
  }

  /// Pause the timer (keeps background session active)
  void pauseTimer() {
    _timer?.cancel();
    _isTimerRunning = false;
    
    if (kDebugMode) {
      print('⏸️ Timer paused (background session maintained)');
    }
  }

  /// Resume the timer
  void resumeTimer() {
    _isTimerRunning = true;
    
    if (kDebugMode) {
      print('▶️ Timer resumed');
    }
  }

  /// Stop the timer and clean up background session
  Future<void> stopTimer() async {
    _timer?.cancel();
    _countdownTimer?.cancel();
    _isTimerRunning = false;
    
    // Stop background audio session
    await _stopBackgroundAudio();
    
    if (kDebugMode) {
      print('🛑 Timer stopped, background session ended');
    }
  }

  /// Check if timer is currently running
  bool get isTimerRunning => _isTimerRunning;
  
  /// Check if background session is active
  bool get isBackgroundSessionActive => _isBackgroundSessionActive;

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