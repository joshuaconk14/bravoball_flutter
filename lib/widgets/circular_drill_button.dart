import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../utils/haptic_utils.dart';

class CircularDrillButton extends StatefulWidget {
  final String skill;
  final Widget? icon;
  final VoidCallback? onPressed;
  final bool isActive;
  final bool isCompleted;
  final bool disabled;
  final double size;
  final double iconSize;
  final bool showProgress;
  final double progress;
  final bool enableHaptics;

  const CircularDrillButton({
    Key? key,
    required this.skill,
    this.icon,
    this.onPressed,
    this.isActive = false,
    this.isCompleted = false,
    this.disabled = false,
    this.size = 80,
    this.iconSize = 40,
    this.showProgress = false,
    this.progress = 0.0,
    this.enableHaptics = true,
  }) : super(key: key);

  @override
  State<CircularDrillButton> createState() => _CircularDrillButtonState();
}

class _CircularDrillButtonState extends State<CircularDrillButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetAnimation;
  bool _isPressed = false;

  static const double _buttonDropOffset = 6.0; // ✅ UPDATED: Reduced from 8.0 to 6.0 for better scaling with smaller buttons

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 120),
    );
    _offsetAnimation = Tween<double>(begin: 0, end: _buttonDropOffset).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.disabled && widget.onPressed != null) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.disabled && widget.onPressed != null) {
      setState(() => _isPressed = false);
      _controller.reverse();
      if (widget.enableHaptics) {
        HapticUtils.mediumImpact();
      }
      widget.onPressed!();
    }
  }

  void _onTapCancel() {
    if (!widget.disabled) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  Color _getBackgroundColor() {
    if (widget.isCompleted) {
      return AppTheme.success; // ✅ UPDATED: Use green for completed drills instead of skill color
    } else if (widget.isActive) {
      return const Color(0xFFF5C842); // ✅ UPDATED: Use more vibrant golden yellow for active drills
    } else if (widget.disabled) {
      return AppTheme.buttonDisabledGray;
    } else {
      return AppTheme.buttonDisabledGray; // ✅ UPDATED: Use disabled gray for untouched drills
    }
  }

  Color _getBackColor() {
    if (widget.isCompleted) {
      return AppTheme.primaryDarkGreen; // ✅ UPDATED: Use dark green from app theme for completed drills
    } else if (widget.isActive) {
      return const Color(0xFFE0B13A); // ✅ UPDATED: Use darker golden yellow for active drills
    } else if (widget.disabled) {
      return AppTheme.buttonDisabledDarkGray;
    } else {
      return AppTheme.buttonDisabledDarkGray; // ✅ UPDATED: Use disabled dark gray for untouched drills
    }
  }

  Widget _buildIcon() {
    if (widget.isCompleted) {
      return Icon(
        Icons.check,
        color: Colors.white,
        size: widget.iconSize,
      );
    } else if (widget.icon != null) {
      return widget.icon!;
    } else {
      // Default skill icon
      return Image.asset(
        _getSkillIconPath(widget.skill),
        width: widget.iconSize,
        height: widget.iconSize,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            _getSkillIconFallback(widget.skill),
            color: widget.disabled ? AppTheme.primaryGray : Colors.white,
            size: widget.iconSize * 0.7,
          );
        },
      );
    }
  }

  String _getSkillIconPath(String skill) {
    // Normalize the skill name for better matching
    final normalizedSkill = skill.toLowerCase().replaceAll('_', ' ').trim();
    
    switch (normalizedSkill) {
      case 'passing':
        return 'assets/drill-icons/Player_Passing.png';
      case 'shooting':
        return 'assets/drill-icons/Player_Shooting.png';
      case 'dribbling':
        return 'assets/drill-icons/Player_Dribbling.png';
      case 'first touch':
      case 'firsttouch':
        return 'assets/drill-icons/Player_First_Touch.png';
      case 'defending':
        return 'assets/drill-icons/Player_Defending.png';
      case 'goalkeeping':
        return 'assets/drill-icons/Player_Goalkeeping.png';
      case 'fitness':
        return 'assets/drill-icons/Player_Fitness.png';
      default:
        return 'assets/drill-icons/Player_Dribbling.png';
    }
  }

  IconData _getSkillIconFallback(String skill) {
    switch (skill.toLowerCase()) {
      case 'passing':
        return Icons.sports_soccer;
      case 'shooting':
        return Icons.sports_basketball;
      case 'dribbling':
        return Icons.directions_run;
      case 'first touch':
        return Icons.touch_app;
      case 'defending':
        return Icons.shield;
      case 'goalkeeping':
        return Icons.sports_handball;
      case 'fitness':
        return Icons.sports;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _getBackgroundColor();
    final backColor = _getBackColor();
    final progressSize = widget.size + 16; // ✅ UPDATED: Reduced from +22 to +16 for better scaling with smaller buttons

    return SizedBox(
      width: widget.size + _buttonDropOffset,
      height: widget.size + _buttonDropOffset,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Animated arrow for active drill
            if (widget.isActive)
              Positioned(
                right: -(progressSize / 2) - 4, // ✅ UPDATED: Reduced from -6 to -4 for closer positioning
                top: widget.size / 2 - 22, // ✅ UPDATED: Adjusted from -27 to -22 for smaller arrow
                child: _BouncingArrow(),
              ),
            
            // Progress ring (only show if there's progress or completed)
            if (widget.showProgress && (widget.progress > 0 || widget.isCompleted))
              Positioned(
                top: (_buttonDropOffset + (widget.size - progressSize) / 2) - 3, // ✅ UPDATED: Adjusted from -4 to -3 for smaller drop offset
                left: (widget.size - progressSize) / 2,
                child: SizedBox(
                  width: progressSize,
                  height: progressSize,
                  child: CircularProgressIndicator(
                    value: widget.progress,
                    strokeWidth: 4, // ✅ UPDATED: Reduced from 6 to 4 for better proportion with smaller buttons
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.isCompleted ? AppTheme.success : // ✅ UPDATED: Use green for completed drills
                      widget.isActive ? const Color(0xFFF5C842) : // ✅ UPDATED: Use vibrant golden yellow for active drills
                      AppTheme.buttonDisabledGray, // ✅ UPDATED: Use disabled gray for untouched drills
                    ),
                  ),
                ),
              ),
            
            // Back circle
            Positioned(
              top: _buttonDropOffset,
              left: 0,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: backColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            // Animated front circle
            AnimatedBuilder(
              animation: _offsetAnimation,
              builder: (context, child) {
                return Positioned(
                  top: _offsetAnimation.value,
                  left: 0,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: _buildIcon(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 

class _BouncingArrow extends StatefulWidget {
  @override
  State<_BouncingArrow> createState() => _BouncingArrowState();
}

class _BouncingArrowState extends State<_BouncingArrow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100), // Slower bounce
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 10).animate( // ✅ UPDATED: Reduced from 12 to 10 for smaller buttons
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(-_animation.value, 0), // Bounce left
          child: Icon(
            Icons.arrow_left,
            color: Colors.white,
            size: 44, // ✅ UPDATED: Reduced from 54 to 44 for smaller buttons
          ),
        );
      },
    );
  }
} 