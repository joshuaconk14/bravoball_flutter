import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../models/drill_model.dart'; // Added for DrillModel
import '../../models/editable_drill_model.dart'; // Added for EditableDrillModel
import '../../services/mental_training_service.dart';
import '../../models/mental_training_models.dart';
import '../../services/app_state_service.dart';
import '../../services/audio_service.dart';
import '../../services/background_timer_service.dart'; // ✅ ADDED: Background timer service
import '../../services/wake_lock_service.dart'; // ✅ ADDED: Wake lock service
import '../../constants/app_theme.dart';
import '../../utils/haptic_utils.dart';
import '../../widgets/bravo_button.dart';
import '../../views/main_tab_view.dart';
import '../../config/app_config.dart'; // Added for debug mode
import 'package:flutter/foundation.dart'; // Added for kDebugMode
import 'package:uuid/uuid.dart'; // Added for UUID generation
import '../../widgets/guest_account_creation_dialog.dart'; // ✅ ADDED: Import reusable dialog

class MentalTrainingTimerView extends StatefulWidget {
  final int durationMinutes;
  
  const MentalTrainingTimerView({
    Key? key,
    required this.durationMinutes,
  }) : super(key: key);

  @override
  State<MentalTrainingTimerView> createState() => _MentalTrainingTimerViewState();
}

class _MentalTrainingTimerViewState extends State<MentalTrainingTimerView> 
    with TickerProviderStateMixin {
  
  // ✅ UPDATED: Use BackgroundTimerService instead of manual Timer
  final BackgroundTimerService _backgroundTimer = BackgroundTimerService.shared;
  
  // Timer state
  late int _totalSeconds;
  late int _remainingSeconds;
  Timer? _quoteTimer; // Keep quote timer separate for UI
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isCompleted = false;
  
  // ✅ ADDED: Countdown state for 3-2-1 countdown
  bool _showCountdown = false;
  int _countdownValue = 3;
  
  // ✅ ADDED: Separate progress tracking for countdown vs main timer
  bool _isCountdownPhase = false;
  double _countdownProgress = 0.0;
  double _mainTimerProgress = 0.0;
  
  // Quote display
  List<MentalTrainingQuote> _quotes = [];
  MentalTrainingQuote? _currentQuote;
  int _currentQuoteIndex = 0;
  
  // Animations
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late AnimationController _quoteController;
  late AnimationController _breathingController;
  late AnimationController _rippleController;
  
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _quoteOpacityAnimation;
  late Animation<Offset> _quoteSlideAnimation;
  late Animation<double> _breathingAnimation;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeTimer();
    _initializeAnimations();
    _loadQuotes();
    _initializeBackgroundTimer(); // ✅ ADDED: Initialize background timer
    
    // ✅ NEW: Add comprehensive debugging for Android testing
    if (kDebugMode) {
      _logSystemDebugInfo();
    }
  }
  
  // ✅ NEW: Initialize background timer service
  Future<void> _initializeBackgroundTimer() async {
    await _backgroundTimer.initializeBackgroundSession();
    
    if (kDebugMode) {
      print('🧠 Background timer initialized for mental training');
      print('   • Background session active: ${_backgroundTimer.isBackgroundSessionActive}');
      print('   • Lock screen widget available: ${_backgroundTimer.isLockScreenWidgetActive}');
      print('   • Audio muted: ${AudioService.isMuted}');
    }
  }

  // ✅ NEW: Log comprehensive system info for Android testing
  void _logSystemDebugInfo() {
    if (kDebugMode) {
      print('🤖 === MENTAL TRAINING DEBUG INFO ===');
      print('🎯 Timer Configuration:');
      print('   • Duration: ${widget.durationMinutes} minutes (${_totalSeconds}s)');
      print('   • Fast debug mode: ${AppConfig.fastMentalTrainingTimers}');
      print('🔊 Audio System:');
      print('   • Audio muted: ${AudioService.isMuted}');
      print('   • Available sounds: 321-start.mp3, 321-done.mp3, success.mp3, silent-timer.mp3');
      print('⏱️ Background Features:');
      print('   • Background timer service: ${_backgroundTimer.isBackgroundSessionActive}');
      print('   • Wake lock service: Available');
      print('   • Notification service: Available');
      print('🧠 Mental Training Setup:');
      print('   • Quotes loaded: ${_quotes.length}');
      print('   • Quote cycling: ${_quoteTimer != null ? 'Active' : 'Inactive'}');
      print('=====================================');
    }
  }

  void _initializeTimer() {
    if (AppConfig.fastMentalTrainingTimers) {
      // Debug mode: super fast timers (5 seconds total regardless of selected duration)
      _totalSeconds = 15;
    } else {
      // Normal mode: use actual duration
      _totalSeconds = widget.durationMinutes * 60;
    }
    _remainingSeconds = _totalSeconds;
  }

  void _initializeAnimations() {
    // ✅ UPDATED: Progress animation - will be dynamically configured for each phase
    _progressController = AnimationController(
      duration: const Duration(seconds: 3), // Initial duration for countdown
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.linear,
    ));
    
    // Listen to progress animation to update our separate progress values
    _progressController.addListener(() {
      if (mounted) {
        setState(() {
          if (_isCountdownPhase) {
            _countdownProgress = _progressController.value;
          } else {
            _mainTimerProgress = _progressController.value;
          }
        });
      }
    });
    
    // Pulse animation for timer circle
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Quote animations
    _quoteController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _quoteOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _quoteController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _quoteSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _quoteController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
    ));
    
    // Breathing animation
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );
    
    _breathingAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));
    
    // Ripple animation
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));
    
    // Start breathing animation
    _breathingController.repeat(reverse: true);
  }

  void _loadQuotes() async {
    final mentalTrainingService = MentalTrainingService.shared;
    final quotes = await mentalTrainingService.fetchQuotes(limit: 30);
    
    setState(() {
      _quotes = quotes;
      if (_quotes.isNotEmpty) {
        _quotes.shuffle();
        _currentQuote = _quotes.first;
        _currentQuoteIndex = 0;
      }
    });
    
    // ✅ UPDATED: Start quote animation and immediately begin cycling
    // Quote cycling will now run independently of timer state
    if (_quotes.isNotEmpty) {
      _quoteController.forward().then((_) {
        // Start quote rotation immediately after first quote loads
        _startQuoteRotation();
      });
    }
  }

  void _startTimer() {
    // ✅ UPDATED: Start countdown phase first
    setState(() {
      _isRunning = true;
      _isPaused = false;
      _showCountdown = true;
      _countdownValue = 3;
      _isCountdownPhase = true; // Mark as countdown phase
      _countdownProgress = 0.0; // Reset countdown progress
    });
    
    // Enable wake lock for mental training session
    WakeLockService.enableWakeLock();
    
    // Start countdown progress animation (3 seconds)
    _progressController.duration = const Duration(seconds: 3);
    _progressController.reset();
    _progressController.forward();
    
    _pulseController.repeat(reverse: true);
    _rippleController.repeat();
    
    // Start with 3-2-1 countdown using background timer
    _backgroundTimer.startCountdown(
      countdownValue: 3,
      drillName: 'Mental Training Session',
      onTick: (value) {
        if (mounted) {
          setState(() {
            _countdownValue = value;
          });
        }
      },
      onComplete: () {
        if (mounted) {
          setState(() {
            _showCountdown = false;
            _isCountdownPhase = false; // Switch to main timer phase
            _mainTimerProgress = 0.0; // Reset main timer progress
            _countdownProgress = 1.0; // ✅ ADDED: Mark countdown as complete
          });
          _startMainTimer();
        }
      },
    );
    
    // Quote rotation is now handled dynamically in _loadQuotes after first quote animation
  }
  
  // ✅ UPDATED: Start the main mental training timer with properly synced progress
  void _startMainTimer() {
    // ✅ FIXED: Use actual timer duration for progress animation to sync properly
    final actualDuration = AppConfig.fastMentalTrainingTimers 
        ? _totalSeconds // Use debug duration (15 seconds)
        : _remainingSeconds; // Use actual remaining time
    
    // Reset and configure progress controller for actual timer duration
    _progressController.duration = Duration(seconds: actualDuration);
    _progressController.reset();
    _progressController.forward();
    
    _backgroundTimer.startTimer(
      durationSeconds: _remainingSeconds.toDouble(),
      drillName: 'Mental Training Session',
      debugMode: AppConfig.fastMentalTrainingTimers,
      onTick: (remainingTime) {
        if (mounted) {
          setState(() {
            _remainingSeconds = remainingTime.toInt();
          });
        }
      },
      onComplete: () {
        if (mounted) {
          _completeSession();
        }
      },
    );
    
    // ✅ REMOVED: Quote rotation is now handled independently in _loadQuotes()
    // No need to start it here since it's already running
  }

  void _startQuoteRotation() {
    if (_quotes.isEmpty) return;
    
    // ✅ UPDATED: Quote rotation now runs independently of timer state
    _quoteTimer?.cancel();
    
    // Start continuous quote cycling
    _scheduleNextQuote();
  }

  void _scheduleNextQuote() {
    if (_quotes.isEmpty || _currentQuote == null) return;
    
    // ✅ UPDATED: Use longer quote display duration for better readability
    final quoteDuration = AppConfig.fastMentalTrainingTimers 
        ? const Duration(seconds: 3) // Increased from 800ms to 3 seconds in debug mode
        : Duration(seconds: _getQuoteDisplayDuration(_currentQuote!)); // Use enhanced duration calculation
    
    _quoteTimer?.cancel(); // Cancel any existing timer
    _quoteTimer = Timer(quoteDuration, () {
      _showNextQuote();
    });
  }

  // ✅ NEW: Enhanced quote duration calculation
  int _getQuoteDisplayDuration(MentalTrainingQuote quote) {
    // Base duration: minimum 8 seconds for any quote
    int baseDuration = 8;
    
    // Add extra time based on quote length for readability
    if (quote.text.length > 200) {
      baseDuration = 15; // Very long quotes get 15 seconds
    } else if (quote.text.length > 100) {
      baseDuration = 12; // Long quotes get 12 seconds
    } else if (quote.text.length > 50) {
      baseDuration = 10; // Medium quotes get 10 seconds
    }
    
    // Use the longer of: base duration or quote's own displayDuration
    return math.max(baseDuration, quote.displayDuration);
  }

  void _showNextQuote() {
    if (_quotes.isEmpty) return;
    
    // Animate out current quote
    _quoteController.reverse().then((_) {
      setState(() {
        _currentQuoteIndex = (_currentQuoteIndex + 1) % _quotes.length;
        _currentQuote = _quotes[_currentQuoteIndex];
      });
      
      // Animate in new quote
      _quoteController.forward();
      
      // Schedule the next quote with its specific duration
      _scheduleNextQuote();
    });
  }

  void _pauseTimer() {
    setState(() {
      _isPaused = true;
    });
    _backgroundTimer.pauseTimer(); // Pause the background timer
    _quoteTimer?.cancel();
    
    // ✅ FIXED: Use reset and save current value instead of stop for better resume
    if (_progressController.isAnimating) {
      _progressController.stop();
    }
    
    _pulseController.stop();
    _rippleController.stop();
  }

  void _resumeTimer() {
    setState(() {
      _isPaused = false;
    });
    
    // ✅ FIXED: Resume progress animation with proper synchronization
    if (!_progressController.isCompleted && !_isCountdownPhase) {
      // Calculate the current progress based on remaining time
      final totalDuration = AppConfig.fastMentalTrainingTimers ? _totalSeconds : widget.durationMinutes * 60;
      final elapsedTime = totalDuration - _remainingSeconds;
      final currentProgress = elapsedTime / totalDuration;
      
      // Set the progress controller to the current position and continue
      _progressController.value = currentProgress;
      _progressController.forward();
    } else if (!_progressController.isCompleted) {
      // For countdown phase, just continue the animation
      _progressController.forward();
    }
    
    _pulseController.repeat(reverse: true);
    _rippleController.repeat();
    
    // ✅ FIXED: Resume the background timer properly
    _backgroundTimer.resumeTimer();
    
    // ✅ FIXED: Resume quote scheduling if we have quotes loaded
    if (_quotes.isNotEmpty && _currentQuote != null) {
      _scheduleNextQuote();
    }
  }

  void _stopTimer() {
    _backgroundTimer.stopTimer(); // Stop the background timer
    _quoteTimer?.cancel(); // ✅ FIXED: Cancel quote timer on stop
    _progressController.stop(); // ✅ UPDATED: Stop progress animation
    _pulseController.stop();
    _rippleController.stop();
    
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _remainingSeconds = _totalSeconds;
      _isCountdownPhase = false; // ✅ UPDATED: Reset countdown phase
      _countdownProgress = 0.0; // ✅ UPDATED: Reset progress values
      _mainTimerProgress = 0.0;
      _showCountdown = false; // ✅ UPDATED: Reset countdown display
      _isCompleted = false; // ✅ ADDED: Reset completion state
      // ✅ FIXED: Reset quote state for fresh start on next session
      _currentQuoteIndex = 0;
      if (_quotes.isNotEmpty) {
        _currentQuote = _quotes.first;
        _quoteController.reset();
      }
    });
    
    _progressController.reset(); // ✅ UPDATED: Reset progress controller
  }

  void _completeSession() {
    _backgroundTimer.stopTimer(); // Stop the background timer
    _quoteTimer?.cancel();
    _progressController.stop(); // ✅ UPDATED: Stop progress animation
    _pulseController.stop();
    _rippleController.stop();
    
    setState(() {
      _isCompleted = true;
      _remainingSeconds = 0;
      _mainTimerProgress = 1.0; // ✅ UPDATED: Set to complete
      _isCountdownPhase = false; // ✅ ADDED: Ensure we're not in countdown phase
    });
    
    // Celebration animation
    _showCompletionAnimation();
    
    // Save session to backend
    _saveMentalTrainingSession();
  }

  void _showCompletionAnimation() {
    // Add celebration effects
    HapticUtils.heavyImpact();
    AudioService.playSuccess(); // Use existing success sound
    
    // Disable wake lock since session is complete
    WakeLockService.disableWakeLock();
    
    // Show celebration particles or effects here
  }

  void _saveMentalTrainingSession() async {
    try {
      
      // Update app state to count this as a completed session for the day
      final appState = Provider.of<AppStateService>(context, listen: false);
      
      // ✅ UPDATED: Guest mode check - show account creation dialog and navigate to home
      if (appState.isGuestMode) {
        if (kDebugMode) {
          print('👤 Guest mode detected - skipping mental training progress save');
          print('   Duration: ${widget.durationMinutes} minutes');
        }
        
        // ✅ UPDATED: Show proper account creation dialog for guests
        if (mounted) {
          _showGuestCompletionDialog();
        }
        
        return; // Don't save progress for guest users
      }
      
      // Create a CompletedSession for mental training
      final mentalTrainingCompletedSession = CompletedSession(
        date: DateTime.now(),
        drills: [
          EditableDrillModel(
            drill: DrillModel(
              id: const Uuid().v4(), // Use a proper UUID for the drill ID
              title: 'Mental Training Session',
              skill: 'Mental Training',
              subSkills: ['Confidence', 'Focus', 'Resilience'],
              sets: 1,
              reps: 1,
              duration: widget.durationMinutes,
              description: 'Mental training focused on building confidence and resilience',
              instructions: ['Focus on breathing', 'Practice visualization', 'Build confidence'],
              tips: ['Stay present', 'Be patient with yourself', 'Consistency is key'],
              equipment: [],
              trainingStyle: 'mental',
              difficulty: 'beginner',
              videoUrl: '',
              isCustom: false, // ✅ ADDED: Set isCustom to false for mental training drills
            ),
            setsDone: 1,
            totalSets: 1,
            totalReps: 1,
            totalDuration: widget.durationMinutes,
            isCompleted: true,
          ),
        ],
        totalCompletedDrills: 1,
        totalDrills: 1,
        sessionType: 'mental_training'
      );
      
      // Add this as a completed session (counts toward streak)
      await appState.addCompletedSession(mentalTrainingCompletedSession);
      
      // ✅ NEW: Refresh progress data from backend to update mental training metrics
      await appState.refreshProgressHistoryFromBackend();
      
      if (kDebugMode) {
        print('✅ Mental training session completed and counted toward daily progress');
        print('   Duration: ${widget.durationMinutes} minutes');
        print('   Sessions completed today: ${appState.sessionsCompletedToday}');
        print('   Current streak: ${appState.currentStreak}');
        print('   Mental training sessions: ${appState.mentalTrainingSessions}');
        print('   Total mental training minutes: ${appState.totalMentalTrainingMinutes}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving mental training session: $e');
      }
    }
  }

  void _showGuestCompletionDialog() {
    GuestAccountCreationDialog.show(
      context: context,
      title: 'Great Job!',
      description: 'You completed your mental training session! Create an account to save your progress and track your streak.',
      themeColor: AppTheme.primaryYellow,
      icon: Icons.celebration,
      showContinueAsGuest: true,
      continueAsGuestText: 'Continue as Guest',
      onContinueAsGuest: () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const MainTabView(initialIndex: 0),
          ),
          (route) => false,
        );
      },
    );
  }

  @override
  void dispose() {
    _backgroundTimer.stopTimer(); // Stop the background timer (don't dispose shared service)
    _quoteTimer?.cancel();
    _progressController.dispose();
    _pulseController.dispose();
    _quoteController.dispose();
    _breathingController.dispose();
    _rippleController.dispose();
    
    // Disable wake lock when leaving mental training
    WakeLockService.disableWakeLock();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryYellow.withValues(alpha: 0.15),
              AppTheme.backgroundPrimary,
              AppTheme.primaryYellow.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Custom App Bar
                _buildAppBar(),
                
                const SizedBox(height: 40),
                
                // Main Timer Section
                Expanded(
                  flex: 3,
                  child: _buildTimerSection(),
                ),
                
                // Quote Section
                Expanded(
                  flex: 2,
                  child: _buildQuoteSection(),
                ),
                
                // Controls Section
                _buildControlsSection(),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            HapticUtils.lightImpact();
            _showExitConfirmation();
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: AppTheme.primaryGray,
              size: 20,
            ),
          ),
        ),
        Expanded(
          child: Text(
            'Mental Training',
            textAlign: TextAlign.center,
            style: AppTheme.headlineSmall.copyWith(
              color: AppTheme.primaryDark,
            ),
          ),
        ),
        // Spacer to balance the layout
        const SizedBox(width: 40),
      ],
    );
  }

  // ✅ NEW: Test audio functionality
  void _testAudioSounds() async {
    if (kDebugMode) {
      print('🔊 Testing audio sounds...');
      
      // Test countdown start sound
      print('🔊 Playing countdown start sound...');
      await AudioService.playCountdownStart();
      
      // Wait 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      
      // Test countdown final sound  
      print('🔊 Playing countdown final sound...');
      await AudioService.playCountdownFinal();
      
      // Wait 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      
      // Test success sound
      print('🔊 Playing success sound...');
      await AudioService.playSuccess();
      
      print('✅ Audio test complete');
    }
  }

  Widget _buildTimerSection() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple effect
          if (_isRunning && !_isPaused)
            AnimatedBuilder(
              animation: _rippleAnimation,
              builder: (context, child) {
                return Container(
                  width: 300 + (_rippleAnimation.value * 100),
                  height: 300 + (_rippleAnimation.value * 100),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryYellow.withOpacity(
                        0.3 * (1 - _rippleAnimation.value)
                      ),
                      width: 2,
                    ),
                  ),
                );
              },
            ),
          
          // Breathing circle
          AnimatedBuilder(
            animation: _breathingAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _breathingAnimation.value,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primaryYellow.withValues(alpha: 0.1),
                        AppTheme.primaryYellow.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Main timer circle
          AnimatedBuilder(
            animation: Listenable.merge([_progressAnimation, _pulseAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: _isRunning ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 250,
                  height: 250,
                  child: Stack(
                    children: [
                      // Background circle
                      Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.backgroundSecondary,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                      ),
                      
                      // Circular Progress Indicator around the circle
                      SizedBox(
                        width: 250,
                        height: 250,
                        child: CircularProgressIndicator(
                          value: _isCountdownPhase ? _countdownProgress : _mainTimerProgress,
                          strokeWidth: 6,
                          backgroundColor: AppTheme.primaryGray.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isCompleted ? AppTheme.success : 
                            _isCountdownPhase ? AppTheme.primaryYellow : AppTheme.primaryYellow,
                          ),
                        ),
                      ),
                      
                      // Timer text
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isCompleted) ...[
                              Icon(
                                Icons.check_circle_rounded,
                                size: 60,
                                color: AppTheme.success,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Complete!',
                                style: AppTheme.headlineSmall.copyWith(
                                  color: AppTheme.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ] else if (_showCountdown) ...[
                              Text(
                                _countdownValue.toString(),
                                style: AppTheme.headlineLarge.copyWith(
                                  fontSize: 48, // ✅ INCREASED: Larger countdown number
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryYellow,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Get Ready!',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.primaryGray,
                                  fontWeight: FontWeight.w600, // ✅ ADDED: Bolder text
                                ),
                              ),
                              const SizedBox(height: 8), // ✅ ADDED: Space for indicator
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryYellow.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Starting...',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.primaryYellow,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ] else ...[
                              Text(
                                _formatTime(_remainingSeconds),
                                style: AppTheme.headlineLarge.copyWith(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'remaining',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.primaryGray,
                                ),
                              ),
                              if (AppConfig.fastMentalTrainingTimers) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.warning.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'DEBUG MODE - Fast Timer',
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.warning,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteSection() {
    if (_currentQuote == null) {
      return const SizedBox.shrink();
    }
    
    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([_quoteOpacityAnimation, _quoteSlideAnimation]),
        builder: (context, child) {
          return FadeTransition(
            opacity: _quoteOpacityAnimation,
            child: SlideTransition(
              position: _quoteSlideAnimation,
              child: Container(
                // ✅ FIXED: Add constraints to prevent overflow
                constraints: const BoxConstraints(
                  maxHeight: 200, // Maximum height for quote section
                  maxWidth: double.infinity,
                ),
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.white,
                      AppTheme.backgroundSecondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: SingleChildScrollView( // ✅ FIXED: Add scrolling for very long quotes
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✅ FIXED: Improved text handling with proper overflow behavior
                      Flexible(
                        child: Text(
                          '"${_currentQuote!.text}"',
                          style: AppTheme.titleMedium.copyWith(
                            color: AppTheme.primaryDark,
                            height: 1.4,
                            fontStyle: FontStyle.italic,
                            // ✅ FIXED: Dynamic font size based on quote length
                            fontSize: _currentQuote!.text.length > 150 ? 14 : 16,
                          ),
                          textAlign: TextAlign.center,
                          // ✅ FIXED: Proper text overflow handling
                          overflow: TextOverflow.visible,
                          softWrap: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '— ${_currentQuote!.author}',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primaryGray,
                          fontWeight: FontWeight.w600,
                          fontSize: 14, // ✅ FIXED: Consistent author font size
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis, // ✅ FIXED: Handle long author names
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControlsSection() {
    if (_isCompleted) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            height: 56,
            child: BravoButton(
              text: 'Back to Home',
              onPressed: () {
                // ✅ ADDED: Check if guest mode and show overlay instead of navigating
                final appState = Provider.of<AppStateService>(context, listen: false);
                if (appState.isGuestMode) {
                  // Show guest account overlay for guests
                  // GuestAccountOverlay.show( // This line was removed from the new_code, so it's removed here.
                  //   context: context,
                  //   title: 'Create an account to save your progress',
                  //   description: 'Great job completing your mental training! Create an account to track your progress, earn achievements, and unlock all features.',
                  //   themeColor: AppTheme.primaryYellow,
                  //   showDismissButton: true,
                  // );
                } else {
                  // Navigate normally for authenticated users
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const MainTabView(initialIndex: 0),
                    ),
                    (route) => false,
                  );
                }
              },
              color: AppTheme.primaryYellow,
              backColor: AppTheme.primaryDarkYellow,
              textColor: AppTheme.white,
            ),
          ),
        ],
      );
    }
    
    if (!_isRunning && !_isPaused) {
      return Container(
        width: double.infinity,
        height: 56,
        child: BravoButton(
          text: 'Start Mental Training',
          onPressed: _startTimer,
          color: AppTheme.primaryYellow,
          backColor: AppTheme.primaryDarkYellow,
          textColor: AppTheme.white,
        ),
      );
    }
    
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 56,
            child: BravoButton(
              text: _isPaused ? 'Resume' : 'Pause',
              onPressed: _showCountdown ? null : (_isPaused ? _resumeTimer : _pauseTimer), // ✅ DISABLED during countdown
              color: _showCountdown ? AppTheme.buttonDisabledGray : 
                     (_isPaused ? AppTheme.primaryYellow : AppTheme.primaryGray),
              backColor: _showCountdown ? AppTheme.buttonDisabledDarkGray :
                        (_isPaused ? AppTheme.primaryDarkYellow : AppTheme.buttonDisabledDarkGray),
              textColor: AppTheme.white,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 56,
            child: BravoButton(
              text: 'Stop',
              onPressed: _showCountdown ? null : _stopTimer, // ✅ DISABLED during countdown
              color: _showCountdown ? AppTheme.buttonDisabledGray : AppTheme.error,
              backColor: _showCountdown ? AppTheme.buttonDisabledDarkGray : 
                        AppTheme.error.withValues(alpha: 0.8),
              textColor: AppTheme.white,
            ),
          ),
        ),
      ],
    );
  }

  void _showExitConfirmation() {
    // ✅ UPDATED: Allow direct navigation if session is completed or not started
    if (_isCompleted || (!_isRunning && !_isPaused)) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const MainTabView(initialIndex: 0),
        ),
        (route) => false,
      );
      return;
    }
    
    // Only show warning if session is in progress (running or paused)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exit Mental Training?'),
        content: Text('Your progress will be lost if you exit now.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Stop background timer and clean up
              await _backgroundTimer.stopTimer();
              await WakeLockService.disableWakeLock();
              
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const MainTabView(initialIndex: 0),
                ),
                (route) => false,
              );
            },
            child: Text('Exit'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
} 