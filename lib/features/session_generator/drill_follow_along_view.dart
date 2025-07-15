import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../models/editable_drill_model.dart';
import '../../services/app_state_service.dart';
import '../../services/audio_service.dart';
import '../../services/background_timer_service.dart';
import '../../services/wake_lock_service.dart';
import '../../constants/app_theme.dart';
import '../../config/app_config.dart';
import '../../widgets/bravo_button.dart';
import '../../widgets/drill_video_player.dart';
import '../../widgets/info_popup_widget.dart';
import '../../widgets/warning_dialog.dart'; // ✅ NEW: Import reusable warning dialog
import '../../utils/haptic_utils.dart';
import '../../utils/skill_utils.dart'; // ✅ ADDED: Import centralized skill utilities
import 'drill_detail_view.dart';
import 'session_completion_view.dart';
import '../../widgets/circular_drill_button.dart'; // ✅ NEW: Import circular drill button
import 'package:rive/rive.dart';
import '../../widgets/play_pause_button.dart'; // ✅ NEW: Import play pause button
import '../../widgets/circular_control_button.dart'; // ✅ NEW: Import circular control button

class DrillFollowAlongView extends StatefulWidget {
  final EditableDrillModel editableDrill;
  final VoidCallback? onDrillCompleted;
  final VoidCallback? onSessionCompleted;

  const DrillFollowAlongView({
    Key? key,
    required this.editableDrill,
    this.onDrillCompleted,
    this.onSessionCompleted,
  }) : super(key: key);

  @override
  State<DrillFollowAlongView> createState() => _DrillFollowAlongViewState();
}

class _DrillFollowAlongViewState extends State<DrillFollowAlongView> {
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
  bool _showInfoSheet = false;
  
  // Audio state
  bool _finalCountdownPlayed = false;

  @override
  void initState() {
    super.initState();
    
    _editableDrill = widget.editableDrill;
    _setDuration = _editableDrill.calculateSetDuration();
    _elapsedTime = _setDuration;
    
    // Initialize background timer service
    _initializeBackgroundTimer();
  }

  Future<void> _initializeBackgroundTimer() async {
    await _backgroundTimer.initializeBackgroundSession();
    
    if (kDebugMode) {
      print('🎯 Background timer initialized for drill: ${_editableDrill.drill.title}');
    }
  }

  @override
  void dispose() {
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Back button
            IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: () {
                HapticUtils.lightImpact(); // Light haptic for navigation
                // Only show warning if timer has been started (less than original duration)
                if (_elapsedTime < _setDuration) {
                  _showExitWarning();
                } else {
                  // Timer hasn't been started, exit directly
                  Navigator.pop(context);
                }
              },
            ),
            const Spacer(),
            // (Details button removed)
          ],
        ),
      ),
      body: Column(
        children: [
          // Progress section at top - cleaner design
          _buildProgressSection(),
          
          // Main content - flexible layout
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 12), // Reduced from 16
                  _buildDrillHeader(),
                  const SizedBox(height: 16), // Reduced from 20
                  _buildVideoPlayer(),
                  const SizedBox(height: 16), // Reduced from 20
                  _buildPlayControls(),
                  const SizedBox(height: 12), // Reduced from 16
                  _buildActionButtons(),
                  const SizedBox(height: 20), // Reduced from 40
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Sets progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryYellow,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryYellow.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _editableDrill.setsDone >= _editableDrill.totalSets 
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  '${(_editableDrill.progress * 100).toInt()}% Complete',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Progress bar - simple and clean
          LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                width: double.infinity,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Stack(
                  children: [
                    // Progress fill - simple color
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

  Widget _buildDrillHeader() {
    return Column(
      children: [
        // Drill title
        Text(
          _editableDrill.drill.title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 6),
        
        // Skill badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.getSkillColor(_editableDrill.drill.skill).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.getSkillColor(_editableDrill.drill.skill).withOpacity(0.3),
            ),
          ),
          child: Text(
            SkillUtils.formatSkillForDisplay(_editableDrill.drill.skill), // ✅ UPDATED: Use centralized skill formatting
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: AppTheme.getSkillColor(_editableDrill.drill.skill),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Session info row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildInfoChip('${_editableDrill.totalSets} sets', Icons.repeat),
            const SizedBox(width: 8),
            _buildInfoChip('${_editableDrill.totalReps} reps', Icons.fitness_center),
            const SizedBox(width: 8),
            _buildInfoChip('${_editableDrill.totalDuration} mins', Icons.schedule),
          ],
        ),
      ],
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

  Widget _buildVideoPlayer() {
    if (_editableDrill.drill.videoUrl.isNotEmpty) {
      return Container(
        height: 240, // Increased from 180 to make video bigger and easier to see
        child: DrillVideoPlayer(
          videoUrl: _editableDrill.drill.videoUrl,
          aspectRatio: 16 / 9,
          showControls: true,
        ),
      );
    } else {
      // Fallback placeholder when no video URL
      return Container(
        width: double.infinity,
        height: 200, // Increased from 160 to match bigger video size
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off,
              size: 40, // Reduced from 48
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 6), // Reduced from 8
            Text(
              'No video available',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12, // Reduced from 14
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPlayControls() {
    return Container(
      padding: const EdgeInsets.all(16), // Reduced from 20
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Timer display - more compact
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Reduced padding
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer,
                      color: AppTheme.primaryYellow,
                      size: 16, // Reduced from 18
                    ),
                    const SizedBox(width: 6), // Reduced from 8
                    const Text(
                      'Time Remaining',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 12, // Reduced from 14
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6), // Reduced from 8
                Text(
                  _formatTime(_elapsedTime),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 32, // Reduced from 38
                    color: AppTheme.primaryDark,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16), // Reduced from 20
          
          // Control buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Info button
              CircularControlButton(
                icon: Icons.info_outline,
                onPressed: () {
                  HapticUtils.lightImpact(); // Light haptic for info
                  _showInfoPopup();
                },
                color: AppTheme.primaryLightBlue,
                size: 44,
              ),
              // Play/Pause button (larger) - more compact
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
                isComplete: _editableDrill.setsDone >= _editableDrill.totalSets,
                countdownValue: _showCountdown ? _countdownValue : null,
                debugMode: AppConfig.debug,
                disabled: _editableDrill.setsDone >= _editableDrill.totalSets,
                size: 80
              ),
              // Article (details) button - replaces ellipsis
              CircularControlButton(
                icon: Icons.article,
                onPressed: () {
                  HapticUtils.lightImpact();
                  _showDrillDetails(context);
                },
                color: Colors.grey.shade500,
                size: 44,
              ),
            ],
          ),
          
          const SizedBox(height: 10), // Reduced from 12
          
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          // Done button - more compact
          Expanded(
            child: ElevatedButton(
              onPressed: _editableDrill.setsDone >= _editableDrill.totalSets ? () {
                HapticUtils.mediumImpact(); // Medium haptic for completion
                _completeDrill();
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _editableDrill.setsDone >= _editableDrill.totalSets 
                    ? AppTheme.success
                    : Colors.grey.shade400,
                foregroundColor: Colors.white,
                elevation: _editableDrill.setsDone >= _editableDrill.totalSets ? 2 : 0,
                shadowColor: _editableDrill.setsDone >= _editableDrill.totalSets 
                    ? AppTheme.success.withOpacity(0.3) 
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10), // Reduced from 14
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_editableDrill.setsDone >= _editableDrill.totalSets) ...[
                    const Icon(Icons.check_circle, size: 16, color: Colors.white), // Reduced from 18
                    const SizedBox(width: 4), // Reduced from 6
                  ],
                  const Text(
                    'Done',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 14, // Reduced from 16
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _togglePlayPause() {
    if (_editableDrill.setsDone >= _editableDrill.totalSets) return;
    
    // In debug mode, allow skipping countdown by pressing button during countdown
    if (_showCountdown && AppConfig.debug) {
      if (kDebugMode) {
        print('🐛 DEBUG: Skipping countdown');
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
      drillName: _editableDrill.drill.title, // Pass drill name to lock screen widget
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
      drillName: _editableDrill.drill.title, // Pass drill name to lock screen widget
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
    _editableDrill.setsDone = _editableDrill.totalSets; // Ensure setsDone equals totalSets when completed
    
    // Update the drill in the session
    _updateDrillInSession();
    
    // Give the UI time to update
    await Future.delayed(const Duration(milliseconds: 50));
    
    widget.onDrillCompleted?.call();
    
    if (mounted) {
      Navigator.pop(context);
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
      description: 'This drill timer will continue running even when your phone screen is off!\n\n🔒 Lock Screen Widget: See live countdown and progress on your lock screen\n\n🎵 Audio Cues: Turn off silent mode and turn up your audio to hear countdown sounds and completion alerts.\n\n⏱️ Background Timer: The timer uses background audio to keep running when you lock your phone or switch apps.\n\n▶️ Controls: Use pause/resume buttons in the lock screen notification.\n\nPress play to start the 3-second countdown, then use the timer to pace yourself during reps.',
      riveFileName: 'Bravo_Animation.riv',
    );
  }

  void _showExitWarning() {
    WarningDialog.show(
      context: context,
      title: 'Exit Drill?',
      content: 'Are you sure you want to exit this drill? This will reset your timer for the current set.',
      cancelText: 'Stay',
      continueText: 'Exit',
      onCancel: () {
        // User cancelled - do nothing, stay in drill
      },
      onContinue: () async {
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