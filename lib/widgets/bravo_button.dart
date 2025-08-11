import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_theme.dart';
import '../utils/haptic_utils.dart';

class BravoButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color color;
  final Color backColor;
  final Color textColor;
  final bool disabled;
  final bool enableHaptics;
  final double textSize;
  final double height;
  final double borderRadius;
  final FontWeight fontWeight;
  final BorderSide? borderSide;
  final Widget? child; // Add child parameter for custom widgets

  const BravoButton({
    Key? key,
    required this.text,
    required this.onPressed,
    required this.color,
    required this.backColor,
    required this.textColor,
    this.disabled = false,
    this.enableHaptics = true,
    this.textSize = 18,
    this.height = 56,
    this.borderRadius = 16,
    this.fontWeight = FontWeight.bold,
    this.borderSide,
    this.child, // Add child parameter
  }) : super(key: key);

  @override
  State<BravoButton> createState() => _BravoButtonState();
}

class _BravoButtonState extends State<BravoButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetAnimation;
  bool _isPressed = false;

  static const double _buttonDropOffset = 6.0;

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
    if (!widget.disabled) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.disabled) {
      setState(() => _isPressed = false);
      _controller.reverse();
      if (widget.enableHaptics) {
        HapticUtils.mediumImpact(); // Use our haptic utility
      }
      if (widget.onPressed != null) widget.onPressed!();
    }
  }

  void _onTapCancel() {
    if (!widget.disabled) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color backColor = widget.disabled ? AppTheme.buttonDisabledDarkGray : widget.backColor;
    final Color frontColor = widget.disabled ? AppTheme.buttonDisabledGray : widget.color;
    return SizedBox(
      width: double.infinity,
      height: widget.height + _buttonDropOffset,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Back rectangle
            Positioned(
              left: 0,
              right: 0,
              top: _buttonDropOffset,
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  color: backColor,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: widget.borderSide != null ? Border.all(color: widget.borderSide!.color, width: widget.borderSide!.width) : null,
          ),
              ),
            ),
            // Animated front rectangle
            AnimatedBuilder(
              animation: _offsetAnimation,
              builder: (context, child) {
                return Positioned(
                  left: 0,
                  right: 0,
                  top: _offsetAnimation.value,
                  child: Container(
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: frontColor,
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      border: widget.borderSide != null ? Border.all(color: widget.borderSide!.color, width: widget.borderSide!.width) : null,
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    child: widget.child != null 
                      ? widget.child! 
                      : FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
                        widget.text,
            overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: widget.fontWeight,
                          fontSize: widget.textSize,
                          color: widget.textColor,
                        ),
                      ),
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