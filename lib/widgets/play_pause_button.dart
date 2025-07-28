import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../utils/haptic_utils.dart';
import 'circular_drill_button.dart';

class PlayPauseButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback? onPlayPressed;
  final VoidCallback? onPausePressed;
  final VoidCallback? onCompletePressed;
  final bool isComplete;
  final int? countdownValue;
  final bool debugMode;
  final bool disabled;
  final double size;
  final bool enableHaptics;
  final Color? backColor; // NEW

  const PlayPauseButton({
    Key? key,
    required this.isPlaying,
    this.onPlayPressed,
    this.onPausePressed,
    this.onCompletePressed,
    this.isComplete = false,
    this.countdownValue,
    this.debugMode = false,
    this.disabled = false,
    this.size = 80,
    this.enableHaptics = true,
    this.backColor, // NEW
  }) : super(key: key);

  @override
  State<PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<PlayPauseButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetAnimation;
  bool _isPressed = false;

  static const double _buttonDropOffset = 6.0; // ✅ UPDATED: Increased from 4.0 to 6.0 to move back circle more down

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
    if (!widget.disabled && _getOnPressed() != null) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.disabled && _getOnPressed() != null) {
      setState(() => _isPressed = false);
      _controller.reverse();
      if (widget.enableHaptics) {
        HapticUtils.mediumImpact();
      }
      _getOnPressed()!();
    }
  }

  void _onTapCancel() {
    if (!widget.disabled) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  VoidCallback? _getOnPressed() {
    if (widget.isComplete) {
      return widget.onCompletePressed;
    } else if (widget.countdownValue != null && !widget.debugMode) {
      return null; // Disabled during countdown (unless debug mode)
    } else {
      return widget.isPlaying ? widget.onPausePressed : widget.onPlayPressed;
    }
  }

  Color _getBackgroundColor() {
    if (widget.isComplete) {
      return AppTheme.success;
    } else if (widget.disabled || (widget.countdownValue != null && !widget.debugMode)) {
      return Colors.grey.shade400;
    } else {
      return AppTheme.primaryYellow;
    }
  }

  Color _getBackColor() {
    if (widget.backColor != null) {
      return widget.backColor!;
    }
    if (widget.isComplete) {
      return AppTheme.primaryDarkGreen; // ✅ Use primaryDarkGreen for complete state
    } else if (widget.disabled || (widget.countdownValue != null && !widget.debugMode)) {
      return Colors.grey.shade500;
    } else {
      return AppTheme.primaryDarkYellow;
    }
  }

  Widget _buildIcon() {
    if (widget.isComplete) {
      return const Icon(
        Icons.check,
        color: Colors.white,
        size: 32,
      );
    } else if (widget.countdownValue != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Text(
            widget.countdownValue.toString(),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 32,
              color: Colors.white,
            ),
          ),
          // Debug mode indicator
          if (widget.debugMode)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bug_report,
                  size: 10,
                  color: Colors.purple,
                ),
              ),
            ),
        ],
      );
    } else {
      return Icon(
        widget.isPlaying ? Icons.pause : Icons.play_arrow,
        size: 32,
        color: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _getBackgroundColor();
    final backColor = _getBackColor();

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
                  boxShadow: [
                    BoxShadow(
                      color: backgroundColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
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