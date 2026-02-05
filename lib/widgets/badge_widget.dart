import 'package:flutter/material.dart';

/// Reusable badge widget for displaying notification indicators
/// Shows a red circle dot (Duolingo-style) without numbers, positioned at top-right of child widget
class BadgeWidget extends StatelessWidget {
  final Widget child;
  final int count;
  final bool showBadge;
  final Color badgeColor;
  final double badgeSize;

  const BadgeWidget({
    Key? key,
    required this.child,
    required this.count,
    this.showBadge = true,
    this.badgeColor = Colors.red,
    this.badgeSize = 14.0, // Increased size for better visibility
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!showBadge || count <= 0) {
      return child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -4,
          right: -4,
          child: Container(
            width: badgeSize,
            height: badgeSize,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
