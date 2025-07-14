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

  static const double _buttonDropOffset = 6.0; // ✅ UPDATED: Increased from 4.0 to 6.0 to make back circle lower

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
      return AppTheme.getSkillColor(widget.skill); // ✅ UPDATED: Keep original skill color when completed
    } else if (widget.isActive) {
      return AppTheme.getSkillColor(widget.skill);
    } else if (widget.disabled) {
      return AppTheme.buttonDisabledGray;
    } else {
      return AppTheme.buttonDisabledGray; // ✅ UPDATED: Use disabled gray for untouched drills
    }
  }

  Color _getBackColor() {
    if (widget.isCompleted) {
      return AppTheme.getSkillDarkColor(widget.skill); // ✅ UPDATED: Keep original dark skill color when completed
    } else if (widget.isActive) {
      return AppTheme.getSkillDarkColor(widget.skill);
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
    switch (skill.toLowerCase()) {
      case 'passing':
        return 'assets/drill-icons/Player_Passing.png';
      case 'shooting':
        return 'assets/drill-icons/Player_Shooting.png';
      case 'dribbling':
        return 'assets/drill-icons/Player_Dribbling.png';
      case 'first touch':
        return 'assets/drill-icons/Player_First_Touch.png';
      case 'defending':
        return 'assets/drill-icons/Player_Dribbling.png';
      case 'fitness':
        return 'assets/drill-icons/Player_Dribbling.png';
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
      case 'fitness':
        return Icons.fitness_center;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _getBackgroundColor();
    final backColor = _getBackColor();
    final progressSize = widget.size + 18; // Increased from +10 to +18 for a larger progress ring

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
                right: -(progressSize / 2) - 6, // Closer to the button
                top: widget.size / 2 - 27, // Adjusted for bigger arrow
                child: _BouncingArrow(),
              ),
            
            // Progress ring (only show if there's progress or completed)
            if (widget.showProgress && (widget.progress > 0 || widget.isCompleted))
              Positioned(
                top: (_buttonDropOffset + (widget.size - progressSize) / 2) - 3, // Move up by 3 pixels
                left: (widget.size - progressSize) / 2,
                child: SizedBox(
                  width: progressSize,
                  height: progressSize,
                  child: CircularProgressIndicator(
                    value: widget.progress,
                    strokeWidth: 6,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.isCompleted ? AppTheme.getSkillColor(widget.skill) : 
                      widget.isActive ? AppTheme.getSkillColor(widget.skill) : 
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
    _animation = Tween<double>(begin: 0, end: 12).animate(
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
            size: 54, // Bigger arrow
          ),
        );
      },
    );
  }
} 