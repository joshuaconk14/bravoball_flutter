import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../models/editable_drill_model.dart';
import '../../services/app_state_service.dart';
import '../../services/background_timer_service.dart';
import '../../services/wake_lock_service.dart';
import '../../constants/app_theme.dart';
import '../../config/app_config.dart';
import '../../widgets/info_popup_widget.dart';
import '../../widgets/warning_dialog.dart';
import '../../widgets/drill_video_background.dart'; // ✅ ADDED: Import new reusable widget
import '../../utils/haptic_utils.dart';
import '../../utils/skill_utils.dart';
import 'drill_detail_view.dart';
import '../../widgets/play_pause_button.dart';
import '../../widgets/circular_control_button.dart';

class DrillFollowAlongView extends StatefulWidget {
  final EditableDrillModel editableDrill;
  final VoidCallback? onDrillCompleted;
  final VoidCallback? onSessionCompleted;

  const DrillFollowAlongView({
    Key? key,
    required this.editableDrill,
    this.onDrillCompleted,
    this.onSessionCompleted,
  });

  @override
  State<DrillFollowAlongView> createState() => _DrillFollowAlongViewState();
}

class _DrillFollowAlongViewState extends State<DrillFollowAlongView>
    with TickerProviderStateMixin {
  late EditableDrillModel _editableDrill;
  
  // Background timer service
  final BackgroundTimerService _backgroundTimer = BackgroundTimerService.shared;
  
  // Timer state
  bool _isPlaying = false;
  int _countdownValue = 3;
  bool _showCountdown = false;
  late double _elapsedTime;
  late double _setDuration;
  
  // UI state
  bool _hideUI = false; // For tap to hide UI functionality
  
  // ✅ ADDED: Animation controllers for UI overlay containers
  late AnimationController _uiAnimationController;
  late Animation<double> _topSectionSlideAnimation;
  late Animation<double> _bottomSectionSlideAnimation;
  late Animation<double> _uiFadeAnimation;
  late Animation<double> _topSectionScaleAnimation;
  late Animation<double> _bottomSectionScaleAnimation;
  
  // ✅ REMOVED: Video player controller and related state - now handled by DrillVideoBackground

  @override
  void initState() {
    super.initState();
    
    _editableDrill = widget.editableDrill;
    _setDuration = _editableDrill.calculateSetDuration();
    _elapsedTime = _setDuration;
    
    // ✅ ADDED: Initialize UI animation controller
    _uiAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // ✅ ADDED: Setup UI animations
    _uiFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _uiAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _topSectionSlideAnimation = Tween<double>(
      begin: -50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _uiAnimationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    ));

    _bottomSectionSlideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _uiAnimationController,
      curve: const Interval(0.2, 0.9, curve: Curves.easeOutCubic),
    ));

    _topSectionScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _uiAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    ));

    _bottomSectionScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _uiAnimationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
    ));
    
    // ✅ REMOVED: Video initialization - now handled by DrillVideoBackground
    
    // Initialize background timer service
    _initializeBackgroundTimer();
    
    // ✅ ADDED: Start UI animations
    _uiAnimationController.forward();
  }

  Future<void> _initializeBackgroundTimer() async {
    await _backgroundTimer.initializeBackgroundSession();
    
    if (kDebugMode) {
      if (kDebugMode) print('🎯 Background timer initialized for drill: ${_editableDrill.drill.title}');
    }
  }

  @override
  void dispose() {
    // ✅ REMOVED: Video controller disposal - now handled by DrillVideoBackground
    
    // ✅ ADDED: Dispose UI animation controller
    _uiAnimationController.dispose();
    
    // Clean up background timer and wake lock
    _stopAllTimers();
    super.dispose();
  }

  Future<void> _stopAllTimers() async {
    await _backgroundTimer.stopTimer();
    await WakeLockService.disableWakeLock();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ UPDATED: Get updated video path for custom drills from app state
    final appState = Provider.of<AppStateService>(context, listen: false);
    String videoUrlToUse = _editableDrill.drill.videoUrl;
    
    // Check if this is a custom drill and if there's an updated version in app state
    if (_editableDrill.drill.isCustom) {
      final updatedDrill = appState.customDrills.firstWhere(
        (drill) => drill.id == _editableDrill.drill.id,
        orElse: () => _editableDrill.drill,
      );
      videoUrlToUse = updatedDrill.videoUrl;
    }
    
    // ✅ UPDATED: Use new reusable DrillVideoBackground widget
    return DrillVideoBackground(
      videoUrl: videoUrlToUse,
      onTap: () {
        // ✅ ADDED: Light haptic feedback when tapping to toggle UI
        HapticUtils.lightImpact();
        // Toggle UI visibility when tapping on video
        setState(() {
          _hideUI = !_hideUI;
        });
      },
      child: _buildUIOverlay(),
    );
  }

  // ✅ REMOVED: All video background building methods - now handled by DrillVideoBackground

  Widget _buildUIOverlay() {
    return SafeArea(
      child: AnimatedBuilder(
        animation: _uiAnimationController,
        builder: (context, child) {
          return Column(
            children: [
              // ✅ ANIMATED: Top section with slide, scale, fade, and tap-to-hide animations
              AnimatedOpacity(
                opacity: !_hideUI ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: AnimatedSlide(
                  offset: !_hideUI ? Offset.zero : const Offset(0, -1.0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Transform.translate(
                    offset: Offset(0, _topSectionSlideAnimation.value),
                    child: Transform.scale(
                      scale: _topSectionScaleAnimation.value,
                      child: FadeTransition(
                        opacity: _uiFadeAnimation,
                        child: _buildTopSection(),
                      ),
                    ),
                  ),
                ),
              ),
              
              const Spacer(),
              
              // ✅ ANIMATED: Bottom section with slide, scale, fade, and tap-to-hide animations
              AnimatedOpacity(
                opacity: !_hideUI ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: AnimatedSlide(
                  offset: !_hideUI ? Offset.zero : const Offset(0, 1.0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Transform.translate(
                    offset: Offset(0, _bottomSectionSlideAnimation.value),
                    child: Transform.scale(
                      scale: _bottomSectionScaleAnimation.value,
                      child: FadeTransition(
                        opacity: _uiFadeAnimation,
                        child: _buildBottomSection(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9), // ✅ UPDATED: Increased opacity from 0.7 to 0.9
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row with drill title and close button
          Stack(
            children: [
              // Drill title (centered with proper padding)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40), // Add horizontal padding to avoid X button
                child: Center(
                  child: Text(
                    _editableDrill.drill.title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              
              // ✅ UPDATED: Close button (X) on the left with better positioning
              Positioned(
                left: -8,
                top: -8,
                child: IconButton(
                  onPressed: () {
                    HapticUtils.lightImpact();
                    _handleExitAttempt();
                  },
                  icon: const Icon(
                    Icons.close,
                    color: Colors.grey,
                    size: 24,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Row with skill badge and drill info chips
          Row(
            children: [
              // Skill badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.getSkillColor(_editableDrill.drill.skill).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.getSkillColor(_editableDrill.drill.skill).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  SkillUtils.formatSkillForDisplay(_editableDrill.drill.skill),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: AppTheme.getSkillColor(_editableDrill.drill.skill),
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Drill info chips
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildInfoChip('${_editableDrill.totalSets} sets', Icons.repeat),
                    const SizedBox(width: 6),
                    _buildInfoChip('${_editableDrill.totalReps} reps', Icons.fitness_center),
                    const SizedBox(width: 6),
                    _buildInfoChip('${_editableDrill.totalDuration} mins', Icons.schedule),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Sets progress and completion percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryYellow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _editableDrill.isCompleted 
                      ? 'All Sets Complete! 🎉' 
                      : 'Set ${_editableDrill.setsDone + 1} of ${_editableDrill.totalSets}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                '${(_editableDrill.progress * 100).toInt()}% Complete',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Progress bar
          LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                width: double.infinity,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: constraints.maxWidth * _editableDrill.progress,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryYellow,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12), // Reduced from 16
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9), // ✅ UPDATED: Increased opacity from 0.7 to 0.9
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 4), // Add small spacing to move timer down slightly
          
          // Timer display (simplified)
          _buildTimerDisplay(),
          
          const SizedBox(height: 14), // Reduced from 16
          
          // Control buttons
          _buildControlButtons(),
          
          const SizedBox(height: 10), // Reduced from 12
          
          // Done button
          _buildDoneButton(),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay() {
    return Text(
      _formatTime(_elapsedTime),
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.bold,
        fontSize: 28, // Reduced from 36
        color: AppTheme.primaryDark,
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Info button
        CircularControlButton(
          icon: Icons.info_outline,
          onPressed: () {
            HapticUtils.lightImpact();
            _showInfoPopup();
          },
          color: AppTheme.primaryLightBlue,
          size: 44, // Reduced from 50
        ),
        
        // Play/Pause button (larger)
        PlayPauseButton(
          isPlaying: _isPlaying,
          onPlayPressed: () {
            _togglePlayPause();
          },
          onPausePressed: () {
            _togglePlayPause();
          },
          onCompletePressed: () {
            _completeDrill();
          },
          isComplete: _editableDrill.isCompleted,
          countdownValue: _showCountdown ? _countdownValue : null,
          debugMode: AppConfig.debug,
          disabled: _editableDrill.isCompleted,
          size: 70, // Reduced from 90
        ),
        
        // Details button
        CircularControlButton(
          icon: Icons.article,
          onPressed: () {
            HapticUtils.lightImpact();
            _showDrillDetails(context);
          },
          color: Colors.grey.shade500,
          size: 44, // Reduced from 50
        ),
      ],
    );
  }

  Widget _buildDoneButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          HapticUtils.mediumImpact();
          _handleExitAttempt();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _editableDrill.isCompleted 
              ? AppTheme.success
              : AppTheme.primaryLightBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: _editableDrill.isCompleted 
              ? AppTheme.success.withValues(alpha: 0.3) 
              : AppTheme.primaryLightBlue.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_editableDrill.isCompleted) ...[
              const Icon(Icons.check_circle, size: 18, color: Colors.white),
              const SizedBox(width: 6),
            ] else ...[
              const Icon(Icons.exit_to_app, size: 18, color: Colors.white),
              const SizedBox(width: 6),
            ],
            Text(
              _editableDrill.isCompleted ? 'Completed!' : 'Exit Drill',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _togglePlayPause() {
    if (_editableDrill.isCompleted) return;
    
    // In debug mode, allow skipping countdown by pressing button during countdown
    if (_showCountdown && AppConfig.debug) {
      if (kDebugMode) {
        if (kDebugMode) print('🐛 DEBUG: Skipping countdown');
      }
      setState(() {
        _showCountdown = false;
        _isPlaying = true;
      });
      _startTimer();
      return;
    }
    
    // Prevent interaction during countdown (except in debug mode)
    if (_showCountdown && !AppConfig.debug) return;
    
    if (!_isPlaying) {
      // If timer was paused (not at initial state), resume immediately
      if (_elapsedTime < _setDuration && _elapsedTime > 0) {
        setState(() {
          _isPlaying = true;
        });
        _startTimer();
      } else {
        // Start from beginning with countdown
        _startCountdown();
      }
    } else {
      // Just pause the timer
      _stopTimer();
    }
  }

  void _startCountdown() {
    setState(() {
      _showCountdown = true;
      _countdownValue = 3;
    });
    
    // Enable wake lock for workout
    WakeLockService.enableWakeLock();
    
    // Start background countdown with drill name for lock screen widget
    _backgroundTimer.startCountdown(
      countdownValue: 3,
      drillName: _editableDrill.drill.title,
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
            _isPlaying = true;
          });
          _startTimer();
        }
      },
    );
  }

  void _startTimer() {
    // Start background timer with callbacks and drill name for lock screen widget
    _backgroundTimer.startTimer(
      durationSeconds: _elapsedTime,
      drillName: _editableDrill.drill.title,
      debugMode: AppConfig.debug,
      onTick: (remainingTime) {
        if (mounted) {
          setState(() {
            _elapsedTime = remainingTime.toDouble();
          });
        }
      },
      onComplete: () {
        if (mounted) {
          _completeSet();
        }
      },
    );
  }

  void _stopTimer() {
    _backgroundTimer.pauseTimer();
    setState(() {
      _isPlaying = false;
      _showCountdown = false;
    });
  }

  void _completeSet() {
    setState(() {
      _editableDrill.setsDone++;
      _elapsedTime = _setDuration; // Reset for next set
      _isPlaying = false;
      
      // ✅ NEW: Automatically mark drill as completed when all sets are done
      if (_editableDrill.setsDone >= _editableDrill.totalSets) {
        _editableDrill.isCompleted = true;
        if (kDebugMode) {
          print('✅ Auto-completed drill: ${_editableDrill.drill.title} - all sets finished');
        }
      }
    });
    
    // Update the drill in the session
    _updateDrillInSession();
    
    if (kDebugMode) {
      print('✅ Set ${_editableDrill.setsDone}/${_editableDrill.totalSets} completed');
    }
  }

  void _completeDrill() async {
    await _stopAllTimers();
    
    _editableDrill.isCompleted = true;
    _editableDrill.setsDone = _editableDrill.totalSets;
    
    // Update the drill in the session
    _updateDrillInSession();
    
    // Give the UI time to update
    await Future.delayed(const Duration(milliseconds: 50));
    
    widget.onDrillCompleted?.call();
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _exitDrill() async {
    await _stopAllTimers();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _handleExitAttempt() {
    // ✅ NEW: Check if timer is running and show warning if needed
    if (_isPlaying || _showCountdown) {
      _showExitWarning();
    } else {
      _exitDrill();
    }
  }

  void _updateDrillInSession() {
    final appState = Provider.of<AppStateService>(context, listen: false);
    
    // Update drill properties (sets, reps, duration)
    appState.updateDrillInSession(
      _editableDrill.drill.id,
      sets: _editableDrill.totalSets,
      reps: _editableDrill.totalReps,
      duration: _editableDrill.totalDuration,
    );
    
    // Update drill progress (completion state, sets done)
    appState.updateDrillProgress(
      _editableDrill.drill.id,
      setsDone: _editableDrill.setsDone,
      isCompleted: _editableDrill.isCompleted,
    );
    
    // ✅ NEW: Call completion callback when drill is automatically completed
    if (_editableDrill.isCompleted && widget.onDrillCompleted != null) {
      widget.onDrillCompleted!.call();
    }
  }

  void _showDrillDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DrillDetailView(
          drill: _editableDrill.drill,
          isInSession: true,
        ),
      ),
    );
  }

  void _showInfoPopup() {
    InfoPopupWidget.show(
      context,
      title: 'Background Timer & Lock Screen Widget',
      description: 'This drill timer will continue running even when your phone screen is off!\n\n🔒 Lock Screen Widget: See live countdown and progress on your lock screen\n\n🎵 Audio Cues: Turn off silent mode and turn up your audio to hear countdown sounds and completion alerts.\n\n⏱️ Background Timer: The timer uses background audio to keep running when you lock your phone or switch apps.\n\n▶️ Controls: Use pause/resume buttons in the lock screen notification.\n\nPress play to start the 3-second countdown, then use the timer to pace yourself during reps.\n\n👆 Tap anywhere on the video to hide/show controls for a cleaner view!',
      riveFileName: 'Bravo_Animation.riv',
    );
  }

  void _showExitWarning() {
    WarningDialog.show(
      context: context,
      title: 'Exit Drill?',
      content: _isPlaying 
          ? 'You\'re currently in the middle of a set. Are you sure you want to exit? This will reset your timer for the current set.'
          : 'Are you sure you want to exit this drill?',
      cancelText: 'Stay',
      continueText: 'Exit',
      warningColor: Colors.orange,
      warningIcon: Icons.warning_amber_rounded,
      onCancel: () {
        HapticUtils.lightImpact();
        // User cancelled - do nothing, stay in drill
      },
      onContinue: () async {
        HapticUtils.mediumImpact();
        // User confirmed - stop timers and exit
        await _stopAllTimers();
        if (mounted) {
          Navigator.pop(context);
        }
      },
    );
  }

  String _formatTime(double seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = (seconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
} 