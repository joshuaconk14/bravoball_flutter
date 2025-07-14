import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../models/drill_model.dart';
import '../../models/editable_drill_model.dart';
import '../../services/app_state_service.dart';
import '../../constants/app_theme.dart';
import '../../widgets/drill_video_player.dart';
import 'drill_detail_view.dart';
import '../../utils/haptic_utils.dart';
import '../../utils/skill_utils.dart'; // ✅ ADDED: Import centralized skill utilities

class EditDrillView extends StatefulWidget {
  final EditableDrillModel editableDrill;
  final VoidCallback? onSave; // Optional callback when changes are saved

  const EditDrillView({
    Key? key,
    required this.editableDrill,
    this.onSave,
  }) : super(key: key);

  @override
  State<EditDrillView> createState() => _EditDrillViewState();
}

class _EditDrillViewState extends State<EditDrillView> {
  late int sets;
  late int reps;
  late int duration;
  
  // Timers for hold-to-repeat functionality
  Timer? _holdTimer;
  Timer? _repeatTimer;
  
  @override
  void initState() {
    super.initState();
    sets = widget.editableDrill.totalSets;
    reps = widget.editableDrill.totalReps;
    duration = widget.editableDrill.totalDuration;
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _repeatTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () {
            HapticUtils.lightImpact(); // Light haptic for navigation
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Edit Drill',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: () {
                HapticUtils.lightImpact(); // Light haptic for details
                _showDrillDetails(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 32),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Details',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Video placeholder (like in Swift app)
                  _buildVideoSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Drill title
                  Text(
                    widget.editableDrill.drill.title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Skill badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.getSkillColor(widget.editableDrill.drill.skill).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.getSkillColor(widget.editableDrill.drill.skill).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      SkillUtils.formatSkillForDisplay(widget.editableDrill.drill.skill), // ✅ UPDATED: Use centralized skill formatting
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: AppTheme.getSkillColor(widget.editableDrill.drill.skill),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Edit controls
                  _buildEditControls(),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          
          // Save Changes button
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildVideoSection() {
    if (widget.editableDrill.drill.videoUrl.isNotEmpty) {
      return DrillVideoPlayer(
        videoUrl: widget.editableDrill.drill.videoUrl,
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

  Widget _buildEditControls() {
    return Column(
      children: [
        _buildControlRow('Sets', sets, (value) => setState(() => sets = value)),
        const SizedBox(height: 16),
        _buildControlRow('Reps', reps, (value) => setState(() => reps = value)),
        const SizedBox(height: 16),
        _buildControlRow('Minutes', duration, (value) => setState(() => duration = value)),
      ],
    );
  }

  Widget _buildControlRow(String label, int value, Function(int) onChanged) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Minus button with hold-to-repeat
                GestureDetector(
                  onTapDown: value > 1 ? (_) {
                    HapticUtils.lightImpact(); // Light haptic for decrement
                    _startHoldToRepeat(() {
                      // Get current value based on label
                      int currentValue = _getCurrentValue(label);
                      if (currentValue > 1) {
                        onChanged(currentValue - 1);
                      }
                    }, () {
                      // Check current value during hold
                      int currentValue = _getCurrentValue(label);
                      return currentValue > 1;
                    });
                  } : null,
                  onTapUp: (_) => _stopHoldToRepeat(),
                  onTapCancel: () => _stopHoldToRepeat(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: value > 1 ? Colors.grey.shade300 : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.remove,
                      color: value > 1 ? Colors.black54 : Colors.grey.shade400,
                      size: 16,
                    ),
                  ),
                ),
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                // Plus button with hold-to-repeat
                GestureDetector(
                  onTapDown: value < _getMaxValue(label) ? (_) {
                    HapticUtils.lightImpact(); // Light haptic for increment
                    _startHoldToRepeat(() {
                      // Get current value based on label
                      int currentValue = _getCurrentValue(label);
                      if (currentValue < _getMaxValue(label)) {
                        onChanged(currentValue + 1);
                      }
                    }, () {
                      // Check current value during hold
                      int currentValue = _getCurrentValue(label);
                      return currentValue < _getMaxValue(label);
                    });
                  } : null,
                  onTapUp: (_) => _stopHoldToRepeat(),
                  onTapCancel: () => _stopHoldToRepeat(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: value < _getMaxValue(label) ? Colors.grey.shade300 : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add,
                      color: value < _getMaxValue(label) ? Colors.black54 : Colors.grey.shade400,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  int _getCurrentValue(String label) {
    switch (label) {
      case 'Sets':
        return sets;
      case 'Reps':
        return reps;
      case 'Minutes':
        return duration;
      default:
        return 0;
    }
  }

  int _getMaxValue(String label) {
    switch (label) {
      case 'Sets':
        return 99; // Maximum 99 sets
      case 'Reps':
        return 999; // Maximum 999 reps  
      case 'Minutes':
        return 120; // Maximum 120 minutes (2 hours)
      default:
        return 99;
    }
  }

  void _startHoldToRepeat(VoidCallback action, bool Function() canContinue) {
    // Cancel any existing timers
    _holdTimer?.cancel();
    _repeatTimer?.cancel();
    
    // Execute the action immediately
    action();
    
    // Start the hold timer - wait 500ms before starting to repeat
    _holdTimer = Timer(const Duration(milliseconds: 500), () {
      if (canContinue()) {
        _startRepeating(action, canContinue);
      }
    });
  }

  void _startRepeating(VoidCallback action, bool Function() canContinue) {
    int elapsedMs = 0;
    int lastActionTime = 0;
    
    _repeatTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!canContinue()) {
        timer.cancel();
        return;
      }
      
      elapsedMs += 50;
      
      // Determine current speed based on elapsed time
      int currentInterval;
      if (elapsedMs < 1000) { // First 1 second
        currentInterval = 200;
      } else if (elapsedMs < 2000) { // Next 1 second
        currentInterval = 150;
      } else if (elapsedMs < 3000) { // Next 1 second
        currentInterval = 100;
      } else { // After 3 seconds
        currentInterval = 50;
      }
      
      // Execute action if enough time has passed since last action
      if (elapsedMs - lastActionTime >= currentInterval) {
        action();
        HapticUtils.lightImpact(); // Add haptic feedback for rapid changes
        lastActionTime = elapsedMs;
      }
    });
  }

  void _stopHoldToRepeat() {
    _holdTimer?.cancel();
    _repeatTimer?.cancel();
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 65),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            HapticUtils.mediumImpact(); // Medium haptic for save action
            _saveChanges();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.buttonPrimary,
            foregroundColor: AppTheme.textOnPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
          ),
          child: Text(
            'Save Changes',
            style: AppTheme.buttonTextMedium,
          ),
        ),
      ),
    );
  }

  void _saveChanges() {
    // Update the drill in the session using AppStateService
    final appState = Provider.of<AppStateService>(context, listen: false);
    
    // Only update if the drill is actually in the session
    if (appState.isDrillInSession(widget.editableDrill.drill)) {
      appState.updateDrillInSession(
        widget.editableDrill.drill.id,
        sets: sets,
        reps: reps,
        duration: duration,
      );
      
      // Call the onSave callback if provided
      widget.onSave?.call();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Drill updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
    
    Navigator.pop(context);
  }

  void _showDrillDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DrillDetailView(
          drill: widget.editableDrill.drill,
          isInSession: true,
        ),
      ),
    );
  }
} 