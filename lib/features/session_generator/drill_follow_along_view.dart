import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../models/editable_drill_model.dart';
import '../../services/app_state_service.dart';
import '../../constants/app_theme.dart';
import '../../widgets/bravo_button.dart';
import '../../widgets/drill_video_player.dart';
import 'drill_detail_view.dart';
import 'session_completion_view.dart';

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
  Timer? _timer;
  Timer? _countdownTimer;
  
  // Timer state
  bool _isPlaying = false;
  int _countdownValue = 3;
  bool _showCountdown = false;
  late double _elapsedTime;
  late double _setDuration;
  
  // UI state
  bool _showInfoSheet = false;
  
  @override
  void initState() {
    super.initState();
    
    print('🔍 [DRILL_FOLLOW_ALONG] initState() called');
    print('📥 [DRILL_FOLLOW_ALONG] Received editableDrill from widget:');
    print('   - Drill ID: ${widget.editableDrill.drill.id}');
    print('   - Drill Title: ${widget.editableDrill.drill.title}');
    print('   - Total Sets: ${widget.editableDrill.totalSets}');
    print('   - Total Reps: ${widget.editableDrill.totalReps}');
    print('   - Total Duration: ${widget.editableDrill.totalDuration}');
    print('   - Sets Done: ${widget.editableDrill.setsDone}');
    print('   - Is Completed: ${widget.editableDrill.isCompleted}');
    
    _editableDrill = widget.editableDrill;
    
    print('📊 [DRILL_FOLLOW_ALONG] After assignment to _editableDrill:');
    print('   - Total Sets: ${_editableDrill.totalSets}');
    print('   - Total Reps: ${_editableDrill.totalReps}');
    print('   - Total Duration: ${_editableDrill.totalDuration}');
    print('   - Sets Done: ${_editableDrill.setsDone}');
    
    _setDuration = _editableDrill.calculateSetDuration();
    _elapsedTime = _setDuration;
    
    print('⏱️ [DRILL_FOLLOW_ALONG] Timer setup:');
    print('   - Set Duration: $_setDuration');
    print('   - Elapsed Time: $_elapsedTime');
    print('✅ [DRILL_FOLLOW_ALONG] initState() completed');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
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
              onPressed: () => Navigator.pop(context),
            ),
            
            const Spacer(),
            
            // Details button
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: ElevatedButton(
                onPressed: () => _showDrillDetails(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Details',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Progress section at top
          _buildProgressSection(),
          
          // Main content - flexible layout
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildDrillHeader(),
                  const SizedBox(height: 20),
                  _buildVideoPlayer(),
                  const SizedBox(height: 20),
                  _buildPlayControls(),
                  const SizedBox(height: 12),
                  _buildActionButtons(),
                  const SizedBox(height: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
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
              Text(
                _editableDrill.setsDone >= _editableDrill.totalSets 
                    ? 'All Sets Complete!' 
                    : 'Set ${_editableDrill.setsDone + 1} of ${_editableDrill.totalSets}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${(_editableDrill.progress * 100).toInt()}% Complete',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Progress bar - clearly left to right
          LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                width: double.infinity,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Stack(
                  children: [
                    // Progress fill - animated from left to right
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: constraints.maxWidth * _editableDrill.progress,
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            AppTheme.buttonPrimary,
                            AppTheme.buttonPrimary.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(3),
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
            color: _getSkillColor(_editableDrill.drill.skill).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getSkillColor(_editableDrill.drill.skill).withOpacity(0.3),
            ),
          ),
          child: Text(
            _editableDrill.drill.skill,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: _getSkillColor(_editableDrill.drill.skill),
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
      return DrillVideoPlayer(
        videoUrl: _editableDrill.drill.videoUrl,
        aspectRatio: 16 / 9,
        showControls: true,
      );
    } else {
      // Fallback placeholder when no video URL
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off,
              size: 48,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              'No video available',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Timer display
          Column(
            children: [
              const Text(
                'Time Remaining',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(_elapsedTime),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 36,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Control buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Info button
              _buildControlButton(
                icon: Icons.info_outline,
                onTap: () => setState(() => _showInfoSheet = true),
                color: Colors.grey.shade400,
                size: 40,
              ),
              
              // Play/Pause button (larger)
              GestureDetector(
                onTap: (_editableDrill.setsDone < _editableDrill.totalSets && !_showCountdown) ? _togglePlayPause : null,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: (_editableDrill.setsDone < _editableDrill.totalSets && !_showCountdown)
                          ? [
                              AppTheme.buttonPrimary,
                              AppTheme.buttonPrimary.withOpacity(0.8),
                            ]
                          : [
                              Colors.grey.shade400,
                              Colors.grey.shade500,
                            ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _showCountdown
                        ? Text(
                            _countdownValue.toString(),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 36,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 36,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
              
              // Settings/menu button
              _buildControlButton(
                icon: Icons.more_vert,
                onTap: () {
                  // Could add more options here
                },
                color: Colors.grey.shade400,
                size: 40,
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Current set indicator
          if (_editableDrill.setsDone < _editableDrill.totalSets)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.buttonPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Set ${_editableDrill.setsDone + 1} of ${_editableDrill.totalSets}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: AppTheme.buttonPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required double size,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: size * 0.5,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Done button
        Expanded(
          child: ElevatedButton(
            onPressed: _editableDrill.setsDone >= _editableDrill.totalSets ? _completeDrill : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _editableDrill.setsDone >= _editableDrill.totalSets 
                  ? AppTheme.success
                  : Colors.grey.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              minimumSize: const Size(0, 44),
            ),
            child: const Text(
              'Done',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Skip button
        SizedBox(
          width: 100,
          child: ElevatedButton(
            onPressed: _skipDrill,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.buttonPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              minimumSize: const Size(0, 44),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.skip_next, size: 16),
                SizedBox(width: 4),
                Text(
                  'Skip',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _togglePlayPause() {
    if (_editableDrill.setsDone >= _editableDrill.totalSets) return;
    
    // Prevent interaction during countdown
    if (_showCountdown) return;
    
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
    // Cancel any existing countdown timer to prevent multiple timers
    _countdownTimer?.cancel();
    
    setState(() {
      _showCountdown = true;
      _countdownValue = 3;
    });
    
    // Provide haptic feedback
    HapticFeedback.mediumImpact();
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownValue > 1) {
        setState(() {
          _countdownValue--;
        });
        HapticFeedback.lightImpact();
      } else {
        timer.cancel();
        setState(() {
          _showCountdown = false;
          _isPlaying = true;
        });
        HapticFeedback.heavyImpact();
        _startTimer();
      }
    });
  }

  void _startTimer() {
    // Cancel any existing timer to prevent multiple timers
    _timer?.cancel();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_elapsedTime > 0) {
          _elapsedTime--;
          
          // Provide haptic feedback at certain intervals
          if (_elapsedTime == 30 || _elapsedTime == 10) {
            HapticFeedback.lightImpact();
          } else if (_elapsedTime <= 3 && _elapsedTime > 0) {
            HapticFeedback.mediumImpact();
          }
        } else {
          // Time's up for this set
          _completeSet();
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _showCountdown = false;  // Reset countdown state when stopping
      // Do NOT reset _elapsedTime here - preserve the current time
    });
  }

  void _completeSet() {
    _stopTimer();
    HapticFeedback.heavyImpact();
    
    setState(() {
      _editableDrill.setsDone++;
      _elapsedTime = _setDuration; // Only reset here
      _isPlaying = false;
    });
    
    // Update the drill in the session
    _updateDrillInSession();
  }

  void _completeDrill() {
    _stopTimer();
    _editableDrill.isCompleted = true;
    _updateDrillInSession();
    
    widget.onDrillCompleted?.call();
    
    // Always just go back to the main page
    // The trophy will be highlighted if session is complete
    Navigator.pop(context);
  }

  void _skipDrill() {
    _stopTimer();
    _editableDrill.isCompleted = true;
    _elapsedTime = _setDuration; // Only reset here
    _updateDrillInSession();
    
    widget.onDrillCompleted?.call();
    Navigator.pop(context);
  }

  void _updateDrillInSession() {
    print('🔄 [DRILL_FOLLOW_ALONG] _updateDrillInSession() called');
    print('📊 [DRILL_FOLLOW_ALONG] Current _editableDrill values:');
    print('   - Total Sets: ${_editableDrill.totalSets}');
    print('   - Total Reps: ${_editableDrill.totalReps}');
    print('   - Total Duration: ${_editableDrill.totalDuration}');
    print('   - Sets Done: ${_editableDrill.setsDone}');
    
    final appState = Provider.of<AppStateService>(context, listen: false);
    appState.updateDrillInSession(
      _editableDrill.drill.id,
      sets: _editableDrill.totalSets,      // Fixed: use totalSets instead of setsDone
      reps: _editableDrill.totalReps,
      duration: _editableDrill.totalDuration,
    );
    
    print('📤 [DRILL_FOLLOW_ALONG] Called appState.updateDrillInSession with:');
    print('   - Drill ID: ${_editableDrill.drill.id}');
    print('   - Sets: ${_editableDrill.totalSets}');
    print('   - Reps: ${_editableDrill.totalReps}');
    print('   - Duration: ${_editableDrill.totalDuration}');
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

  String _formatTime(double seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = (seconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getSkillColor(String skill) {
    // Simple color mapping for different skills
    switch (skill.toLowerCase()) {
      case 'dribbling':
        return Colors.orange;
      case 'passing':
        return Colors.blue;
      case 'shooting':
        return Colors.red;
      case 'first touch':
        return Colors.green;
      case 'defending':
        return Colors.purple;
      default:
        return AppTheme.buttonPrimary;
    }
  }
} 