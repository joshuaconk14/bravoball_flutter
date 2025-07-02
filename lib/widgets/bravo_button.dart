import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BravoButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final bool disabled;
  final bool enableHaptics;
  final double textSize;
  final double height;
  final double borderRadius;
  final FontWeight fontWeight;
  final BorderSide? borderSide;

  const BravoButton({
    Key? key,
    required this.text,
    required this.onPressed,
    required this.color,
    required this.textColor,
    this.disabled = false,
    this.enableHaptics = true,
    this.textSize = 18,
    this.height = 56,
    this.borderRadius = 16,
    this.fontWeight = FontWeight.bold,
    this.borderSide,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: disabled ? color.withOpacity(0.5) : color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: borderSide ?? BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
          textStyle: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: fontWeight,
            fontSize: textSize,
          ),
        ),
        onPressed: disabled
            ? null
            : () {
                if (enableHaptics) {
                  HapticFeedback.mediumImpact();
                }
                if (onPressed != null) onPressed!();
              },
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
} 