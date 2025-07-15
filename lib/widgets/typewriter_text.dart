import 'package:flutter/material.dart';
import '../utils/haptic_utils.dart';

/// Reusable Typewriter Animation Widget
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration duration;
  final VoidCallback? onComplete;
  final Duration startDelay;
  final bool enableHaptics;
  final TextAlign textAlign;

  const TypewriterText({
    Key? key,
    required this.text,
    required this.style,
    this.duration = const Duration(milliseconds: 50),
    this.onComplete,
    this.startDelay = const Duration(milliseconds: 500),
    this.enableHaptics = true,
    this.textAlign = TextAlign.center,
  }) : super(key: key);

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _characterCount;
  int _lastCharacterCount = 0;
  bool _isAnimationComplete = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.text.length * widget.duration.inMilliseconds),
      vsync: this,
    );

    _characterCount = StepTween(
      begin: 0,
      end: widget.text.length,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _isAnimationComplete = true;
        widget.onComplete?.call();
      }
    });

    // Add listener for haptic feedback during typing
    if (widget.enableHaptics) {
      _characterCount.addListener(() {
        final currentCharacterCount = _characterCount.value;
        
        // Multiple checks to ensure haptics stop when animation completes
        if (_isAnimationComplete || 
            currentCharacterCount >= widget.text.length ||
            !mounted ||
            _controller.status == AnimationStatus.completed) {
          return; // Stop all haptics when animation is done
        }
        
        // Trigger haptic feedback every 3-4 characters to simulate typing feel
        if (currentCharacterCount > _lastCharacterCount && 
            currentCharacterCount % 3 == 0) {
          HapticUtils.mediumImpact(); // Medium haptic for typing feel
        }
        
        _lastCharacterCount = currentCharacterCount;
      });
    }

    // Start animation after the specified delay
    Future.delayed(widget.startDelay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _characterCount,
      builder: (context, child) {
        final safeLength = widget.text.length;
        final count = _characterCount.value.clamp(0, safeLength);
        final displayText = safeLength == 0 ? '' : widget.text.substring(0, count);
        return Text(
          displayText,
          style: widget.style,
          textAlign: widget.textAlign,
        );
      },
    );
  }
} 