import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../models/editable_drill_model.dart';
import '../../services/app_state_service.dart';
import '../../constants/app_theme.dart';
import '../../widgets/drill_video_background.dart'; // ✅ ADDED: Import new video background widget
import 'drill_detail_view.dart';
import '../../utils/haptic_utils.dart';
import '../../utils/skill_utils.dart';

class EditDrillView extends StatefulWidget {
  final EditableDrillModel editableDrill;
  final VoidCallback? onSave;

  const EditDrillView({
    Key? key,
    required this.editableDrill,
    this.onSave,
  });

  @override
  State<EditDrillView> createState() => _EditDrillViewState();
}

class _EditDrillViewState extends State<EditDrillView>
  with TickerProviderStateMixin {
  late int sets;
  late int reps;
  late int duration;
  
  // Timers for hold-to-repeat functionality
  Timer? _holdTimer;
  Timer? _repeatTimer;
  
  // ✅ ADDED: Animation controllers for UI overlay containers
  late AnimationController _uiAnimationController;
  late Animation<double> _topSectionSlideAnimation;
  late Animation<double> _bottomSectionSlideAnimation;
  late Animation<double> _uiFadeAnimation;
  late Animation<double> _topSectionScaleAnimation;
  late Animation<double> _bottomSectionScaleAnimation;
  
  // ✅ ADDED: UI visibility state for tap-to-hide functionality
  bool _isUIVisible = true;
  
  @override
  void initState() {
    super.initState();
    sets = widget.editableDrill.totalSets;
    reps = widget.editableDrill.totalReps;
    duration = widget.editableDrill.totalDuration;
    
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
    
    // ✅ ADDED: Start UI animations
    _uiAnimationController.forward();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _repeatTimer?.cancel();
    // ✅ ADDED: Dispose UI animation controller
    _uiAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ UPDATED: Get updated video path for custom drills from app state
    final appState = Provider.of<AppStateService>(context, listen: false);
    String videoUrlToUse = widget.editableDrill.drill.videoUrl;
    
    // Check if this is a custom drill and if there's an updated version in app state
    if (widget.editableDrill.drill.isCustom) {
      final updatedDrill = appState.customDrills.firstWhere(
        (drill) => drill.id == widget.editableDrill.drill.id,
        orElse: () => widget.editableDrill.drill,
      );
      videoUrlToUse = updatedDrill.videoUrl;
    }
    
    // ✅ UPDATED: Use new DrillVideoBackground widget
    return DrillVideoBackground(
      videoUrl: videoUrlToUse,
      child: _buildOverlayContent(),
    );
  }

  Widget _buildOverlayContent() {
    return GestureDetector(
      onTap: () {
        HapticUtils.lightImpact();
        _toggleUIVisibility();
      },
      behavior: HitTestBehavior.translucent,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _uiAnimationController,
          builder: (context, child) {
            return Column(
              children: [
                // ✅ ANIMATED: Top section with slide, scale, and fade animations
                AnimatedOpacity(
                  opacity: _isUIVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: AnimatedSlide(
                    offset: _isUIVisible ? Offset.zero : const Offset(0, -1.0),
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
                
                // ✅ ANIMATED: Bottom section with slide, scale, and fade animations
                AnimatedOpacity(
                  opacity: _isUIVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: AnimatedSlide(
                    offset: _isUIVisible ? Offset.zero : const Offset(0, 1.0),
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
      ),
    );
  }

  Widget _buildTopSection() {
    return GestureDetector(
      onTap: () {
        // Absorb taps on the top section to prevent triggering the background tap
      },
      child: Container(
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
            // Row with close button and drill title
            Row(
              children: [
                // Close button
                GestureDetector(
                  onTap: () {
                    HapticUtils.lightImpact();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Drill title (expanded to take remaining space)
                Expanded(
                  child: Text(
                    widget.editableDrill.drill.title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Details button
                GestureDetector(
                  onTap: () {
                    HapticUtils.lightImpact();
                    _showDrillDetails(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade500,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.article,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Skill badge centered
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.getSkillColor(widget.editableDrill.drill.skill).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.getSkillColor(widget.editableDrill.drill.skill).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                SkillUtils.formatSkillForDisplay(widget.editableDrill.drill.skill),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: AppTheme.getSkillColor(widget.editableDrill.drill.skill),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return GestureDetector(
      onTap: () {
        // Absorb taps on the bottom section to prevent triggering the background tap
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12), // ✅ REDUCED: From 16 to 12
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
            // Edit controls
            _buildEditControls(),
            
            const SizedBox(height: 16), // ✅ REDUCED: From 20 to 16
            
            // Save button
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEditControls() {
    return Column(
      children: [
        _buildControlRow('Sets', sets, (value) => setState(() => sets = value)),
        const SizedBox(height: 12), // ✅ REDUCED: From 16 to 12
        _buildControlRow('Reps', reps, (value) => setState(() => reps = value)),
        const SizedBox(height: 12), // ✅ REDUCED: From 16 to 12
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
              fontSize: 14, // ✅ REDUCED: From 16 to 14
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // ✅ REDUCED: From 16,8 to 12,6
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20), // ✅ REDUCED: From 25 to 20
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Minus button
                GestureDetector(
                  onTapDown: value > 1 ? (_) {
                    HapticUtils.lightImpact();
                    _startHoldToRepeat(() {
                      int currentValue = _getCurrentValue(label);
                      if (currentValue > 1) {
                        onChanged(currentValue - 1);
                      }
                    }, () {
                      int currentValue = _getCurrentValue(label);
                      return currentValue > 1;
                    });
                  } : null,
                  onTapUp: (_) => _stopHoldToRepeat(),
                  onTapCancel: () => _stopHoldToRepeat(),
                  child: Container(
                    width: 28, // ✅ REDUCED: From 32 to 28
                    height: 28, // ✅ REDUCED: From 32 to 28
                    decoration: BoxDecoration(
                      color: value > 1 ? Colors.grey.shade300 : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.remove,
                      color: value > 1 ? Colors.black54 : Colors.grey.shade400,
                      size: 14, // ✅ REDUCED: From 16 to 14
                    ),
                  ),
                ),
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 16, // ✅ REDUCED: From 18 to 16
                    color: Colors.black,
                  ),
                ),
                // Plus button
                GestureDetector(
                  onTapDown: value < _getMaxValue(label) ? (_) {
                    HapticUtils.lightImpact();
                    _startHoldToRepeat(() {
                      int currentValue = _getCurrentValue(label);
                      if (currentValue < _getMaxValue(label)) {
                        onChanged(currentValue + 1);
                      }
                    }, () {
                      int currentValue = _getCurrentValue(label);
                      return currentValue < _getMaxValue(label);
                    });
                  } : null,
                  onTapUp: (_) => _stopHoldToRepeat(),
                  onTapCancel: () => _stopHoldToRepeat(),
                  child: Container(
                    width: 28, // ✅ REDUCED: From 32 to 28
                    height: 28, // ✅ REDUCED: From 32 to 28
                    decoration: BoxDecoration(
                      color: value < _getMaxValue(label) ? Colors.grey.shade300 : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add,
                      color: value < _getMaxValue(label) ? Colors.black54 : Colors.grey.shade400,
                      size: 14, // ✅ REDUCED: From 16 to 14
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

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          HapticUtils.mediumImpact();
          _saveChanges();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryYellow,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Save Changes',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 14, // ✅ REDUCED: From 16 to 14
          ),
        ),
      ),
    );
  }

  // Helper methods remain the same
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
        return 99;
      case 'Reps':
        return 999;
      case 'Minutes':
        return 120;
      default:
        return 99;
    }
  }

  void _startHoldToRepeat(VoidCallback action, bool Function() canContinue) {
    _holdTimer?.cancel();
    _repeatTimer?.cancel();
    
    action();
    
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
      
      int currentInterval;
      if (elapsedMs < 1000) {
        currentInterval = 200;
      } else if (elapsedMs < 2000) {
        currentInterval = 150;
      } else if (elapsedMs < 3000) {
        currentInterval = 100;
      } else {
        currentInterval = 50;
      }
      
      if (elapsedMs - lastActionTime >= currentInterval) {
        action();
        HapticUtils.lightImpact();
        lastActionTime = elapsedMs;
      }
    });
  }

  void _stopHoldToRepeat() {
    _holdTimer?.cancel();
    _repeatTimer?.cancel();
  }

  // ✅ ADDED: Toggle UI visibility for tap-to-hide functionality
  void _toggleUIVisibility() {
    setState(() {
      _isUIVisible = !_isUIVisible;
    });
  }

  void _saveChanges() {
    final appState = Provider.of<AppStateService>(context, listen: false);
    
    if (appState.isDrillInSession(widget.editableDrill.drill)) {
      appState.updateDrillInSession(
        widget.editableDrill.drill.id,
        sets: sets,
        reps: reps,
        duration: duration,
      );
      
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