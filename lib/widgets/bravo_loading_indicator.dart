import 'package:flutter/material.dart';
import 'package:rive/rive.dart' hide LinearGradient;
import '../constants/app_theme.dart';
import '../constants/app_assets.dart';
import 'dart:math' as math;

/// Simple, Clean Bravo Loading Indicator
/// White background, horizontal progress, professional but fun design
class BravoLoadingIndicator extends StatefulWidget {
  final String? message;
  final double? progress; // 0.0 to 1.0, null for indeterminate
  final bool showProgressText;
  final Color? backgroundColor;
  final String? riveAsset;
  final List<String>? loadingSteps;
  final int? currentStep;

  const BravoLoadingIndicator({
    Key? key,
    this.message,
    this.progress,
    this.showProgressText = true,
    this.backgroundColor,
    this.riveAsset = AppAssets.bravoAnimation,
    this.loadingSteps,
    this.currentStep,
  }) : super(key: key);

  @override
  State<BravoLoadingIndicator> createState() => _BravoLoadingIndicatorState();
}

class _BravoLoadingIndicatorState extends State<BravoLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _dotsController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Gentle bounce animation for Bravo character
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));

    // Dots animation
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Start animations
    _bounceController.repeat(reverse: true);
    _dotsController.repeat();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              
              // Simple Bravo Character
              _buildSimpleBravoCharacter(),
              
              const SizedBox(height: 40),
              
              // Loading message
              _buildLoadingMessage(),
              
              const SizedBox(height: 30),
              
              // Horizontal progress bar
              _buildHorizontalProgress(),
              
              const SizedBox(height: 30),
              
              // Optional loading steps
              if (widget.loadingSteps != null && widget.loadingSteps!.isNotEmpty)
                _buildSimpleSteps(),
              
              const Spacer(flex: 2),
              
              // Simple animated dots
              _buildSimpleAnimatedDots(),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleBravoCharacter() {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_bounceAnimation.value),
          child: SizedBox(
            width: 120,
            height: 120,
            child: widget.riveAsset != null
                ? RiveAnimation.asset(
                    widget.riveAsset!,
                    fit: BoxFit.contain,
                  )
                : Icon(
                    Icons.sports_soccer,
                    size: 60,
                    color: AppTheme.primaryYellow,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingMessage() {
    return Text(
      'Let me set up your training experience!',
      style: AppTheme.headlineSmall.copyWith(
        color: AppTheme.primaryDark,
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildHorizontalProgress() {
    return Column(
      children: [
        // Progress bar container
        Container(
          width: double.infinity,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.lightGray,
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: widget.progress != null
                ? LinearProgressIndicator(
                    value: widget.progress,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryYellow),
                  )
                : LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryYellow),
                  ),
          ),
        ),
        
        // Progress percentage
        if (widget.showProgressText && widget.progress != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${(widget.progress! * 100).round()}%',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.primaryGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSimpleSteps() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.lightGray.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryYellow.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: widget.loadingSteps!.take(4).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isCompleted = widget.currentStep != null && index < widget.currentStep!;
          final isCurrent = widget.currentStep == index;
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted 
                        ? AppTheme.primaryGreen
                        : isCurrent 
                            ? AppTheme.primaryYellow
                            : AppTheme.primaryGray.withOpacity(0.3),
                  ),
                  child: isCompleted
                      ? Icon(
                          Icons.check,
                          size: 10,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step,
                    style: AppTheme.bodySmall.copyWith(
                      color: isCompleted || isCurrent 
                          ? AppTheme.primaryDark
                          : AppTheme.primaryGray,
                      fontWeight: isCurrent ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSimpleAnimatedDots() {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.3;
            final animationValue = (_dotsController.value + delay) % 1.0;
            final opacity = (0.3 + (math.sin(animationValue * math.pi * 2) * 0.4)).clamp(0.0, 1.0);
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryYellow.withOpacity(opacity),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Simple Login Loading Indicator - Just Bravo, message, and progress bar
class BravoLoginLoadingIndicator extends StatefulWidget {
  final String? message;
  final String? riveAsset;

  const BravoLoginLoadingIndicator({
    Key? key,
    this.message,
    this.riveAsset = AppAssets.bravoAnimation,
  }) : super(key: key);

  @override
  State<BravoLoginLoadingIndicator> createState() => _BravoLoginLoadingIndicatorState();
}

class _BravoLoginLoadingIndicatorState extends State<BravoLoginLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _dotsController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Gentle bounce animation for Bravo character
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));

    // Dots animation
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Start animations
    _bounceController.repeat(reverse: true);
    _dotsController.repeat();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              
              // Simple Bravo Character
              _buildSimpleBravoCharacter(),
              
              const SizedBox(height: 40),
              
              // Simple login message
              _buildLoginMessage(),
              
              const SizedBox(height: 30),
              
              // Simple horizontal progress bar (indeterminate)
              _buildSimpleProgress(),
              
              const Spacer(flex: 2),
              
              // Simple animated dots
              _buildSimpleAnimatedDots(),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleBravoCharacter() {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_bounceAnimation.value),
          child: SizedBox(
            width: 120,
            height: 120,
            child: widget.riveAsset != null
                ? RiveAnimation.asset(
                    widget.riveAsset!,
                    fit: BoxFit.contain,
                  )
                : Icon(
                    Icons.sports_soccer,
                    size: 60,
                    color: AppTheme.primaryYellow,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildLoginMessage() {
    return Text(
      widget.message ?? 'Welcome back! Signing you in...',
      style: AppTheme.headlineSmall.copyWith(
        color: AppTheme.primaryDark,
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSimpleProgress() {
    return Container(
      width: double.infinity,
      height: 8,
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryYellow),
        ),
      ),
    );
  }

  Widget _buildSimpleAnimatedDots() {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.3;
            final animationValue = (_dotsController.value + delay) % 1.0;
            final opacity = (0.3 + (math.sin(animationValue * math.pi * 2) * 0.4)).clamp(0.0, 1.0);
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryYellow.withOpacity(opacity),
              ),
            );
          }),
        );
      },
    );
  }
}