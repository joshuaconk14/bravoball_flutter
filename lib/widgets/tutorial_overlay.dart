import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../utils/haptic_utils.dart';
import '../services/tutorial_service.dart';

/// Tutorial Overlay Widget
/// 
/// Displays a step-by-step tutorial overlay with tooltips highlighting key features.
/// Uses a spotlight effect to draw attention to specific UI elements.
class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;

  const TutorialOverlay({
    super.key,
    required this.steps,
    this.onComplete,
    this.onSkip,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      HapticUtils.lightImpact();
    } else {
      _completeTutorial();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      HapticUtils.lightImpact();
    }
  }

  void _skipTutorial() {
    HapticUtils.lightImpact();
    TutorialService.instance.markTutorialAsSeen();
    widget.onSkip?.call();
  }

  void _completeTutorial() {
    HapticUtils.mediumImpact();
    TutorialService.instance.markTutorialAsSeen();
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) return const SizedBox.shrink();

    final currentStep = widget.steps[_currentStep];
    final isLastStep = _currentStep == widget.steps.length - 1;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Dark overlay with spotlight
            _buildSpotlightOverlay(context, currentStep),
            
            // Tutorial content card
            _buildTutorialCard(context, currentStep, isLastStep),
          ],
        ),
      ),
    );
  }

  Widget _buildSpotlightOverlay(BuildContext context, TutorialStep step) {
    return CustomPaint(
      painter: SpotlightPainter(
        spotlightRect: step.targetRect,
        backgroundColor: Colors.black.withValues(alpha: 0.5), // ✅ REDUCED: Less strong shadow (from 0.7 to 0.5)
      ),
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }

  Widget _buildTutorialCard(
    BuildContext context,
    TutorialStep step,
    bool isLastStep,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardHeight = 280.0; // Approximate card height
    final padding = 20.0;
    final bottomNavBarHeight = 90.0; // Bottom navigation bar height (including center button)
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    
    // Calculate the maximum top position to avoid bottom navigation bar
    final maxAvailableTop = screenHeight - cardHeight - bottomNavBarHeight - safeAreaBottom - padding;
    final minTop = padding + safeAreaTop;
    
    // Position card based on spotlight position
    double cardTop;
    double cardLeft = (screenWidth - 320) / 2; // Center card
    
    // Calculate available space above and below the spotlight
    final spaceAbove = step.targetRect.top - safeAreaTop;
    final spaceBelow = screenHeight - step.targetRect.bottom - bottomNavBarHeight - safeAreaBottom;
    
    // Always position card at top if spotlight is in bottom 40% of screen OR not enough space below
    final bottomThreshold = screenHeight * 0.6; // Bottom 40% of screen
    if (step.targetRect.top > bottomThreshold || spaceBelow < cardHeight + padding) {
      // Show card lower from top - give more breathing room
      cardTop = minTop + 60; // Lower it by 60px from the very top
    } else {
      // Show card below the spotlight, but ensure it doesn't overlap with nav bar
      cardTop = step.targetRect.bottom + 20;
      // Clamp to ensure it doesn't go below navigation bar
      if (cardTop > maxAvailableTop) {
        cardTop = maxAvailableTop;
      }
    }
    
    // Final bounds checking - ensure card stays fully visible and above navigation bar
    cardTop = cardTop.clamp(minTop, maxAvailableTop);

    return Positioned(
      top: cardTop,
      left: cardLeft,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step indicator
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLightBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentStep + 1} / ${widget.steps.length}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryLightBlue,
                    ),
                  ),
                ),
                const Spacer(),
                // Skip button
                TextButton(
                  onPressed: _skipTutorial,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Title
            Text(
              step.title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            
            // Description
            Text(
              step.description,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            
            // Navigation buttons
            Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: TextButton(
                      onPressed: _previousStep,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Previous',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLastStep ? _completeTutorial : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryYellow,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isLastStep ? 'Get Started' : 'Next',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tutorial Step Model
class TutorialStep {
  final String title;
  final String description;
  final Rect targetRect; // Position and size of the element to highlight

  const TutorialStep({
    required this.title,
    required this.description,
    required this.targetRect,
  });
}

/// Custom Painter for Spotlight Effect
class SpotlightPainter extends CustomPainter {
  final Rect spotlightRect;
  final Color backgroundColor;

  SpotlightPainter({
    required this.spotlightRect,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw dark background
    final backgroundPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Create a path that covers everything except the spotlight area
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Cut out the spotlight area with rounded corners
    final spotlightPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          spotlightRect,
          const Radius.circular(12),
        ),
      );

    final cutoutPath = Path.combine(
      PathOperation.difference,
      path,
      spotlightPath,
    );

    // Draw the cutout
    final cutoutPaint = Paint()..color = backgroundColor;
    canvas.drawPath(cutoutPath, cutoutPaint);
  }

  @override
  bool shouldRepaint(SpotlightPainter oldDelegate) {
    return oldDelegate.spotlightRect != spotlightRect ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

