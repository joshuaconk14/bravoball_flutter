import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../utils/haptic_utils.dart';

class CircularControlButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final Color? backColor; // NEW: Optional back color
  final double size;
  final bool enableHaptics;

  const CircularControlButton({
    Key? key,
    required this.icon,
    this.onPressed,
    required this.color,
    this.backColor, // NEW
    this.size = 44,
    this.enableHaptics = true,
  }) : super(key: key);

  @override
  State<CircularControlButton> createState() => _CircularControlButtonState();
}

class _CircularControlButtonState extends State<CircularControlButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetAnimation;
  bool _isPressed = false;

  static const double _buttonDropOffset = 2.0;

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
    if (widget.onPressed != null) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = false);
      _controller.reverse();
      if (widget.enableHaptics) {
        HapticUtils.lightImpact();
      }
      widget.onPressed!();
    }
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
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
                  color: widget.backColor ?? widget.color.withOpacity(0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (widget.backColor ?? widget.color).withOpacity(0.3),
                      blurRadius: 6,
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
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      size: widget.size * 0.4,
                      color: Colors.white,
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