import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import '../../utils/haptic_utils.dart';
import 'onboarding_questions.dart';
import '../../widgets/bravo_button.dart';
import '../../features/auth/login_view.dart';
import '../../constants/app_theme.dart';
import '../../services/onboarding_service.dart';
import '../../models/onboarding_model.dart';
import '../../main.dart'; // Import for MyApp

/// ✅ NEW: Staggered Animation for Elements
class StaggeredFadeInUp extends StatefulWidget {
  final Widget child;
  final int delay;
  final Duration duration;

  const StaggeredFadeInUp({
    Key? key,
    required this.child,
    this.delay = 0,
    this.duration = const Duration(milliseconds: 400),
  }) : super(key: key);

  @override
  State<StaggeredFadeInUp> createState() => _StaggeredFadeInUpState();
}

class _StaggeredFadeInUpState extends State<StaggeredFadeInUp>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    // Start animation after delay
    Future.delayed(Duration(milliseconds: widget.delay), () {
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// ✅ NEW: Bouncy Button Animation
class BouncyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const BouncyButton({
    Key? key,
    required this.child,
    this.onTap,
  }) : super(key: key);

  @override
  State<BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<BouncyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// ✅ NEW: Typewriter Animation Widget
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration duration;
  final VoidCallback? onComplete;

  const TypewriterText({
    Key? key,
    required this.text,
    required this.style,
    this.duration = const Duration(milliseconds: 50),
    this.onComplete,
  }) : super(key: key);

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _characterCount;
  int _lastCharacterCount = 0;

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
        widget.onComplete?.call();
      }
    });

    // Add listener for haptic feedback during typing
    _characterCount.addListener(() {
      final currentCharacterCount = _characterCount.value;
      
      // Trigger haptic feedback every 3-4 characters to simulate typing feel
      if (currentCharacterCount > _lastCharacterCount && 
          currentCharacterCount % 3 == 0 && 
          currentCharacterCount < widget.text.length) {
        HapticUtils.mediumImpact(); // Medium haptic for typing feel
      }
      
      _lastCharacterCount = currentCharacterCount;
    });

    // Start animation after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
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
        final displayText = widget.text.substring(0, _characterCount.value);
        return Text(
          displayText,
          style: widget.style,
          textAlign: TextAlign.center,
        );
      },
    );
  }
}

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({Key? key}) : super(key: key);

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _step = 0; // 0: initial, 1: preview, 2+: questions
  int _previousStep = 0; // ✅ NEW: Track previous step for animation direction
  final Map<int, int> _answers = {};
  String _regEmail = '';
  String _regPassword = '';
  String _regConfirmPassword = '';
  String _regError = '';
  bool _regPasswordVisible = false;
  bool _regConfirmPasswordVisible = false;
  final Map<int, Set<int>> _multiAnswers = {};
  bool _isSubmitting = false;

  // Persistent controllers for registration fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Additional state for animations
  bool _showNextButton = false;
  bool _textAnimationComplete = false;
  bool _secondTextComplete = false; // ✅ NEW: Track second text completion
  
  // ✅ NEW: Bravo transition animation state
  bool _isBravoTransitioning = false;
  bool _showQuestionContent = false;
  bool _isSkipButtonDisabled = false; // Prevent spam clicking

  static const yellow = Color(0xFFF9CC53);
  static const darkGray = Color(0xFF444444);

  // Step constants for clarity
  static const int stepInitial = 0;
  static const int stepPreview = 1;
  int get stepFirstQuestion => 2;
  int get stepRegistration => onboardingQuestions.length + stepFirstQuestion;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _next() {
    // ✅ NEW: Handle smooth transition from preview to first question
    if (_step == stepPreview) {
      print('🎬 Starting Bravo transition animation');
      // Start Bravo transition animation
      setState(() {
        _isBravoTransitioning = true;
      });
      
      // After a short delay, advance to the next step and show question content
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          print('🎬 Advancing to question step and showing content');
          setState(() {
            _previousStep = _step;
            _step++;
            _showQuestionContent = true;
          });
        }
      });
    } else {
      // Normal next for other steps
      if (_step < stepRegistration) {
        setState(() {
          _previousStep = _step;
          _step++;
          // Reset animation states when leaving preview
          if (_previousStep == stepPreview) {
            _resetAnimationStates();
          }
        });
      }
    }
  }

  void _back() {
    if (_step == 1) {
      setState(() {
        _previousStep = _step;
        _step = 0;
        _resetAnimationStates();
      }); // back to initial
    } else if (_step > 1) {
      setState(() {
        _previousStep = _step;
        _step--;
        // Reset animation states when returning to preview
        if (_step == stepPreview) {
          _resetAnimationStates();
          // Restart preview animations after a short delay
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              _startPreviewAnimations();
            }
          });
        }
        // Reset Bravo transition state when going back to preview
        if (_step == stepPreview) {
          _isBravoTransitioning = false;
          _showQuestionContent = false;
        }
      });
    }
    
    // Add light haptic feedback for back navigation
    HapticUtils.lightImpact();
  }

  // ✅ NEW: Start preview animations when entering preview screen
  void _startPreviewAnimations() {
    // Start the typewriter animation for "Hello! I'm Bravo!"
    setState(() {
      _textAnimationComplete = false;
      _secondTextComplete = false; // User hasn't tapped to continue yet
      _showNextButton = false;
      _isSkipButtonDisabled = false; // Reset skip button
    });
    
    // The TypewriterText widgets will handle their own animation timing
  }

  // ✅ NEW: Reset animation states for preview screen
  void _resetAnimationStates() {
    _showNextButton = false;
    _textAnimationComplete = false;
    _secondTextComplete = false; // Reset tap-to-continue state
    _isBravoTransitioning = false;
    _showQuestionContent = false;
    _isSkipButtonDisabled = false; // Reset skip button
  }

  // Build the onboarding flow with static background and content animations
  @override
  Widget build(BuildContext context) {
    // Debug prints
    final qIdx = _step - stepFirstQuestion;
    debugPrint('ONBOARDING DEBUG: _step=$_step, qIdx=$qIdx, stepRegistration=$stepRegistration');

    // ✅ Static scaffold - no page transitions, only content animations
    return Scaffold(
      backgroundColor: Colors.white, // Static white background
      body: _buildCurrentScreen(),
    );
  }

  /// ✅ NEW: Build the current screen based on step
  Widget _buildCurrentScreen() {
    print('🖥️ Building screen for step: $_step, _isBravoTransitioning: $_isBravoTransitioning, _showQuestionContent: $_showQuestionContent');
    
    if (_step == stepInitial) {
      print('🖥️ Showing initial screen');
      return _buildInitialScreen();
    }

    if (_step == stepPreview || (_step >= stepFirstQuestion && _step < stepRegistration && _isBravoTransitioning)) {
      print('🖥️ Showing unified preview/question screen');
      return _buildPreviewScreen();
    }

    // Question screens (only when not transitioning)
    if (_step >= stepFirstQuestion && _step < stepRegistration && !_isBravoTransitioning) {
      print('🖥️ Showing standalone question screen');
      return _buildQuestionScreen();
    }

    if (_step == stepRegistration) {
      print('🖥️ Showing registration screen');
      return _buildRegistrationScreen();
    }

    // Fallback (should never hit)
    print('🖥️ Showing fallback screen');
    return const SizedBox.shrink();
  }

  /// ✅ Enhanced initial screen with animations
  Widget _buildInitialScreen() {
    return SafeArea(
      child: Column(
        children: [
          const Spacer(flex: 2), // More space at top to center content
          // ✅ Animated Bravo entrance
          StaggeredFadeInUp(
            delay: 100, // Reduced from 200
            child: SizedBox(
              height: 250,
              child: RiveAnimation.asset(
                'assets/rive/Bravo_Animation.riv',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 32),
          // ✅ Animated title
          StaggeredFadeInUp(
            delay: 300, // Reduced from 600
            child: Text(
              'BravoBall',
              style: const TextStyle(
                fontFamily: 'PottaOne',
                fontSize: 40,
                fontWeight: FontWeight.w400,
                color: yellow,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 14),
          // ✅ Animated subtitle
          StaggeredFadeInUp(
            delay: 400, // Reduced from 800
            child: Text(
              'Start Small. Dream Big',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkGray,
              ),
            ),
          ),
          const Spacer(flex: 3), // Larger space below to push buttons to bottom
          // ✅ Animated buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StaggeredFadeInUp(
                  delay: 600, // Reduced from 1200
                  child: BouncyButton(
                    onTap: () {
                      HapticUtils.mediumImpact(); // Medium haptic for major action
                      setState(() {
                        _previousStep = _step;
                        _step = 1;
                      });
                    },
                    child: BravoButton(
                      text: 'Create an account',
                      onPressed: () {
                        HapticUtils.mediumImpact(); // Medium haptic for major action
                        setState(() {
                          _previousStep = _step;
                          _step = 1;
                        });
                      },
                      color: yellow,
                      backColor: AppTheme.primaryDarkYellow,
                      textColor: Colors.white,
                      disabled: false,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                StaggeredFadeInUp(
                  delay: 700, // Reduced from 1400
                  child: BouncyButton(
                    onTap: () {
                      HapticUtils.mediumImpact(); // Medium haptic for major action
                      _goToLogin();
                    },
                    child: BravoButton(
                      text: 'Login',
                      onPressed: () {
                        HapticUtils.mediumImpact(); // Medium haptic for major action
                        _goToLogin();
                      },
                      color: Colors.white,
                      backColor: AppTheme.lightGray,
                      textColor: AppTheme.primaryYellow,
                      disabled: false,
                      borderSide: BorderSide(color: Colors.grey.shade200, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// ✅ Enhanced preview screen with animations  
  Widget _buildPreviewScreen() {
    return SafeArea(
      child: Column(
        children: [
          // ✅ CONSISTENT: Navigation bar that stays throughout the flow
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              children: [
                // Back button on the left
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: darkGray),
                  onPressed: () {
                    HapticUtils.lightImpact(); // Light haptic for back navigation
                    _back();
                  },
                ),
                // Progress bar in the middle
                Expanded(
                  child: LinearProgressIndicator(
                    value: _step >= stepFirstQuestion ? ((_step - stepFirstQuestion + 1) / (onboardingQuestions.length + 1)) : (_isBravoTransitioning ? 0.1 : 0.0),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(yellow),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                // Skip button on the right
                TextButton(
                  onPressed: _isSkipButtonDisabled ? null : () {
                    HapticUtils.lightImpact(); // Light haptic for skip
                    // Use the same transition animation as "Let's Go!"
                    _next();
                  },
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      color: _isSkipButtonDisabled ? Colors.grey.shade400 : darkGray,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // ✅ Main content area with single Bravo
          Expanded(
            child: Stack(
              children: [
                // ✅ Single Bravo that transitions from center to upper left
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeInOutCubic,
                  // Animation: center when showing preview, upper left when transitioning/showing questions
                  top: (_isBravoTransitioning || _step >= stepFirstQuestion) ? 10 : MediaQuery.of(context).size.height / 2 - 180,
                  left: (_isBravoTransitioning || _step >= stepFirstQuestion) ? 30 : MediaQuery.of(context).size.width / 2 - 90,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeInOutCubic,
                    width: (_isBravoTransitioning || _step >= stepFirstQuestion) ? 110 : 180,
                    height: (_isBravoTransitioning || _step >= stepFirstQuestion) ? 110 : 180,
                    child: RiveAnimation.asset(
                      'assets/rive/Bravo_Animation.riv',
                      stateMachines: const ['State Machine 2'],
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                
                // ✅ Preview content that fades out
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 600),
                  opacity: _isBravoTransitioning ? 0.0 : 1.0,
                  child: Column(
                    children: [
                      // Space for Bravo (he's positioned absolutely above)
                      const SizedBox(height: 160), // Move bubble higher
                      
                      // ✅ Message bubble above Bravo
                      _buildBravoMessageBubble(),
                      
                      const SizedBox(height: 160), // More space for Bravo
                      
                      const Spacer(),
                      // ✅ ENHANCED: Dynamic button (Next or Let's Go!)
                      AnimatedSlide(
                        duration: const Duration(milliseconds: 600),
                        offset: _showNextButton ? Offset.zero : const Offset(0, 1),
                        curve: Curves.elasticOut,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 400),
                          opacity: _showNextButton ? 1.0 : 0.0,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: BravoButton(
                                text: _secondTextComplete ? 'Let\'s Go!' : 'Next',
                                onPressed: _showNextButton ? () {
                                  HapticUtils.mediumImpact(); // Medium haptic for major action
                                  if (!_secondTextComplete) {
                                    // First click: show second message
                                    setState(() {
                                      _secondTextComplete = true;
                                      _showNextButton = false; // Hide button during message typing
                                    });
                                  } else {
                                    // Second click: start onboarding
                                    print('🎬 Let\'s Go button clicked - triggering transition');
                                    _next();
                                  }
                                } : null,
                                color: yellow,
                                backColor: AppTheme.primaryDarkYellow,
                                textColor: Colors.white,
                                disabled: false,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                
                // ✅ Question content that fades in (only when step has changed)
                if (_step >= stepFirstQuestion)
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 600),
                    opacity: _showQuestionContent ? 1.0 : 0.0,
                    child: _buildQuestionContent(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Build just the question content (without navigation bar)
  Widget _buildQuestionContent() {
    final qIdx = _step - stepFirstQuestion;
    final question = onboardingQuestions[qIdx];
    final selected = question.isMultiSelect ? _multiAnswers[_step] ?? <int>{} : _answers[_step];
    final isMovingForward = _step > _previousStep;

    // ✅ NEW: Determine if Next button should be enabled
    final bool canProceed = question.isMultiSelect 
        ? (selected as Set<int>).isNotEmpty 
        : selected != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Add spacing to push content down for better balance
        const SizedBox(height: 10),
        
        // ✅ Message bubble in upper left (Bravo is positioned absolutely in the parent Stack)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Space for Bravo (he's positioned absolutely above)
              const SizedBox(width: 100),
              const SizedBox(width: 8),
              Expanded(
                child: _MessageBubble(
                  key: ValueKey<int>(_step),
                  message: question.question,
                  isMovingForward: isMovingForward,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // ✅ Options
        Expanded(
          child: _SimplifiedSlidingOptions(
            key: ValueKey<int>(_step),
            question: question,
            selected: selected,
            isMovingForward: isMovingForward,
            onOptionSelected: (index) {
              if (question.isMultiSelect) {
                setState(() {
                  final set = _multiAnswers[_step] ?? <int>{};
                  if (set.contains(index)) {
                    set.remove(index);
                  } else {
                    set.add(index);
                  }
                  _multiAnswers[_step] = set;
                });
              } else {
                _selectOption(index);
              }
            },
          ),
        ),
        
        // ✅ FIXED: Next button with conditional styling
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: SizedBox(
            width: double.infinity,
            child: BravoButton(
              text: 'Next',
              onPressed: canProceed ? () {
                HapticUtils.mediumImpact(); // Medium haptic for next
                _next();
              } : null,
              color: canProceed ? yellow : Colors.grey.shade300,
              backColor: canProceed ? AppTheme.primaryDarkYellow : Colors.grey.shade400,
              textColor: Colors.white,
              disabled: !canProceed,
            ),
          ),
        ),
      ],
    );
  }

  /// ✅ NEW: Build the smooth Bravo transition from center to upper left
  Widget _buildBravoTransition() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      color: Colors.white, // White background during transition
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeInOutCubic,
            // Animation: start from center, move to upper left when _bravoAnimationStarted is true
            top: _isBravoTransitioning ? 100 : MediaQuery.of(context).size.height / 2 - 90,
            left: _isBravoTransitioning ? 24 : MediaQuery.of(context).size.width / 2 - 90,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeInOutCubic,
              width: _isBravoTransitioning ? 100 : 180,
              height: _isBravoTransitioning ? 100 : 180,
              child: RiveAnimation.asset(
                'assets/rive/Bravo_Animation.riv',
                stateMachines: const ['State Machine 2'],
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ SIMPLIFIED: Question screens with timer-based options showing
  Widget _buildQuestionScreen() {
    final qIdx = _step - stepFirstQuestion;
    final question = onboardingQuestions[qIdx];
    final selected = question.isMultiSelect ? _multiAnswers[_step] ?? <int>{} : _answers[_step];
    final progress = (_step - stepFirstQuestion + 1) / (onboardingQuestions.length + 1);
    final isMovingForward = _step > _previousStep;
    
    // ✅ NEW: Determine if Next button should be enabled
    final bool canProceed = question.isMultiSelect 
        ? (selected as Set<int>).isNotEmpty 
        : selected != null;
    
    // ✅ NEW: Show question content with delay if transitioning from preview
    final isTransitioningFromPreview = _previousStep == stepPreview && _step == stepFirstQuestion;
    
    print('🎬 Question screen - isTransitioningFromPreview: $isTransitioningFromPreview, _isBravoTransitioning: $_isBravoTransitioning, _showQuestionContent: $_showQuestionContent');

    return SafeArea(
      child: Stack(
        children: [
          // ✅ Main question content
          AnimatedOpacity(
            duration: const Duration(milliseconds: 600),
            opacity: isTransitioningFromPreview ? (_showQuestionContent ? 1.0 : 0.0) : 1.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ✅ STATIC: Top bar (never animates)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  child: Row(
                    children: [
                      if (_step >= stepFirstQuestion)
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: darkGray),
                          onPressed: () {
                            HapticUtils.lightImpact(); // Light haptic for back navigation
                            _back();
                          },
                        ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(yellow),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _isSkipButtonDisabled ? null : () {
                          HapticUtils.lightImpact(); // Light haptic for skip
                          _skip();
                        },
                        child: Text('Skip',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            color: _isSkipButtonDisabled ? Colors.grey.shade400 : darkGray,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // ✅ STATIC: Bravo and message bubble (never animates position)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ✅ Only show Bravo if not transitioning from preview (it's handled by transition animation)
                      if (!isTransitioningFromPreview || _showQuestionContent)
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: RiveAnimation.asset(
                            'assets/rive/Bravo_Animation.riv',
                            stateMachines: const ['State Machine 2'],
                            fit: BoxFit.contain,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MessageBubble(
                          key: ValueKey<int>(_step),
                          message: question.question,
                          isMovingForward: isMovingForward,
                          // Remove the callback - we'll use a timer instead
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // ✅ SIMPLIFIED: Options with timer-based showing
                Expanded(
                  child: _SimplifiedSlidingOptions(
                    key: ValueKey<int>(_step),
                    question: question,
                    selected: selected,
                    isMovingForward: isMovingForward,
                    onOptionSelected: (index) {
                      if (question.isMultiSelect) {
                        setState(() {
                          final set = _multiAnswers[_step] ?? <int>{};
                          if (set.contains(index)) {
                            set.remove(index);
                          } else {
                            set.add(index);
                          }
                          _multiAnswers[_step] = set;
                        });
                      } else {
                        _selectOption(index);
                      }
                    },
                  ),
                ),
                
                // ✅ FIXED: Next button with conditional styling
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: BravoButton(
                      text: 'Next',
                      onPressed: canProceed ? () {
                        HapticUtils.mediumImpact(); // Medium haptic for next
                        _next();
                      } : null,
                      color: canProceed ? yellow : Colors.grey.shade300,
                      backColor: canProceed ? AppTheme.primaryDarkYellow : Colors.grey.shade400,
                      textColor: Colors.white,
                      disabled: !canProceed,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // ✅ NEW: Bravo transition overlay for question screen
          if (isTransitioningFromPreview && !_showQuestionContent)
            _buildBravoTransition(),
        ],
      ),
    );
  }

  /// ✅ NEW: Registration form step - FINAL STEP
  Widget _buildRegistrationScreen() {
    final progress = 1.0; // 100% progress on final step

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ✅ STATIC: Top bar (same as question screens)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: darkGray),
                  onPressed: _back,
                ),
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(yellow),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                // ✅ IMPROVED: Show grayed out skip button instead of hiding it
                TextButton(
                  onPressed: null, // Disabled on registration page
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade400, // Grayed out
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // ✅ STATIC: Bravo and message bubble (same as question screens)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: RiveAnimation.asset(
                    'assets/rive/Bravo_Animation.riv',
                    stateMachines: const ['State Machine 2'],
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MessageBubble(
                    key: ValueKey<int>(_step),
                    message: "Enter your Registration Info below!",
                    isMovingForward: true,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // ✅ Registration form fields (scrollable content)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  _BravoTextField(
                    label: 'Email',
                    value: _regEmail,
                    controller: _emailController,
                    onChanged: (v) => setState(() {
                      _regEmail = v;
                      _regError = ''; // Clear error when user types
                    }),
                    keyboardType: TextInputType.emailAddress,
                    isPassword: false,
                    yellow: yellow,
                  ),
                  const SizedBox(height: 16),
                  _BravoTextField(
                    label: 'Password',
                    value: _regPassword,
                    controller: _passwordController,
                    onChanged: (v) => setState(() {
                      _regPassword = v;
                      _regError = ''; // Clear error when user types
                    }),
                    isPassword: true,
                    yellow: yellow,
                    passwordVisible: _regPasswordVisible,
                    onToggleVisibility: () => setState(() => _regPasswordVisible = !_regPasswordVisible),
                  ),
                  const SizedBox(height: 16),
                  _BravoTextField(
                    label: 'Confirm Password',
                    value: _regConfirmPassword,
                    controller: _confirmPasswordController,
                    onChanged: (v) => setState(() {
                      _regConfirmPassword = v;
                      _regError = ''; // Clear error when user types
                    }),
                    isPassword: true,
                    yellow: yellow,
                    passwordVisible: _regConfirmPasswordVisible,
                    onToggleVisibility: () => setState(() => _regConfirmPasswordVisible = !_regConfirmPasswordVisible),
                  ),
                  if (_regError.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _regError, 
                        style: const TextStyle(
                          color: Colors.red,
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // ✅ STATIC: Submit button (same style as question screens)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: _isSubmitting
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(yellow),
                      ),
                    )
                  : BravoButton(
                      text: 'Create Account',
                      onPressed: (_regEmail.isEmpty || _regPassword.isEmpty || _regConfirmPassword.isEmpty)
                          ? null
                          : () async {
                              HapticUtils.mediumImpact(); // Medium haptic for registration
                              setState(() {
                                _regError = '';
                              });
                              
                              // Enhanced validation
                              if (!_regEmail.contains('@') || !_regEmail.contains('.')) {
                                setState(() => _regError = 'Please enter a valid email address.');
                                return;
                              } else if (_regPassword.length < 6) {
                                setState(() => _regError = 'Password must be at least 6 characters.');
                                return;
                              } else if (_regPassword != _regConfirmPassword) {
                                setState(() => _regError = 'Passwords do not match.');
                                return;
                              }
                              
                              setState(() => _isSubmitting = true);
                              
                              // ✅ FIXED: Correct answer mapping based on step indices
                              final answers = _answers;
                              final multiAnswers = _multiAnswers;
                              
                              // Map step numbers to question indices correctly
                              final onboardingData = OnboardingData(
                                email: _regEmail,
                                password: _regPassword,
                                primaryGoal: onboardingQuestions[0].options[answers[stepFirstQuestion] ?? 0],
                                trainingExperience: onboardingQuestions[1].options[answers[stepFirstQuestion + 1] ?? 0],
                                position: onboardingQuestions[2].options[answers[stepFirstQuestion + 2] ?? 0],
                                ageRange: onboardingQuestions[3].options[answers[stepFirstQuestion + 3] ?? 0],
                                strengths: (multiAnswers[stepFirstQuestion + 4] ?? <int>{})
                                    .map((i) => onboardingQuestions[4].options[i]).toList(),
                                areasToImprove: (multiAnswers[stepFirstQuestion + 5] ?? <int>{})
                                    .map((i) => onboardingQuestions[5].options[i]).toList(),
                              );
                              
                              final success = await OnboardingService.shared.submitOnboardingData(
                                onboardingData,
                                onError: (msg) {
                                  setState(() {
                                    _regError = msg;
                                    _isSubmitting = false;
                                  });
                                },
                              );
                              
                              if (success) {
                                if (mounted) {
                                  // Registration successful - let AuthenticationWrapper handle navigation
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (context) => const MyApp()),
                                    (route) => false,
                                  );
                                }
                              } else {
                                setState(() => _isSubmitting = false);
                              }
                            },
                      color: (_regEmail.isEmpty || _regPassword.isEmpty || _regConfirmPassword.isEmpty) ? Colors.grey.shade300 : yellow,
                      backColor: (_regEmail.isEmpty || _regPassword.isEmpty || _regConfirmPassword.isEmpty) ? AppTheme.primaryGray : AppTheme.primaryDarkYellow,
                      textColor: Colors.white,
                      disabled: false,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Helper methods
  void _selectOption(int optionIdx) {
    setState(() {
      _answers[_step] = optionIdx;
    });
  }

  void _skip() {
    // Prevent spam clicking
    if (_isSkipButtonDisabled) return;
    
    setState(() {
      _isSkipButtonDisabled = true;
    });
    
    // Re-enable skip button after delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isSkipButtonDisabled = false;
        });
      }
    });

    // If on registration, do nothing
    if (_step == stepRegistration) {
      // Do nothing, already on registration
      return;
    } else {
      HapticUtils.lightImpact(); // Light haptic for skip
      _next();
    }
  }

  void _goToLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoginView(
          onLoginSuccess: () {
            // Login successful - pop the login view and let AuthenticationWrapper handle navigation
            Navigator.of(context).pop(); // Pop the login view
            
            // Navigate back to the root and let AuthenticationWrapper detect the login state
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MyApp()),
              (route) => false,
            );
          },
          onCancel: () {
            // Go back to welcome page
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  // Message bubble above Bravo
  Widget _buildBravoMessageBubble() {
    return Column(
      children: [
        // Message bubble with same styling as question bubbles
        Container(
          constraints: const BoxConstraints(maxWidth: 280),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5), // Same gray as question bubbles
            borderRadius: BorderRadius.circular(20),
            // No shadow - clean simple look
          ),
          child: _buildMessageContent(),
        ),
        // Triangle pointing down to Bravo - positioned slightly higher
        Transform.translate(
          offset: const Offset(0, -4), // Move triangle up by 4 pixels
          child: CustomPaint(
            size: const Size(24, 15),
            painter: _MessageBubbleTrianglePainter(),
          ),
        ),
      ],
    );
  }

  // ✅ NEW: Build the message content with user interaction
  Widget _buildMessageContent() {
    if (!_textAnimationComplete) {
      // First message: "Hello! I'm Bravo!"
      return TypewriterText(
        key: ValueKey('bubble_hello_$_step'),
        text: "Hello! I'm Bravo!",
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Color(0xFF333333), // Dark gray text like question bubbles
        ),
        duration: const Duration(milliseconds: 60), // Faster typing
        onComplete: () {
          // Show Next button after first message completes
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                _textAnimationComplete = true;
                _showNextButton = true; // Show Next button
              });
            }
          });
        },
      );
    } else if (!_secondTextComplete) {
      // Keep showing first message while Next button is visible
      return const Text(
        "Hello! I'm Bravo!",
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Color(0xFF333333),
        ),
        textAlign: TextAlign.center,
      );
    } else {
      // Second message after user clicks Next
      return TypewriterText(
        key: ValueKey('bubble_help_$_step'),
        text: "I'll help you start training after 6 quick questions!",
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          fontSize: 15,
          color: Color(0xFF333333), // Dark gray text
        ),
        duration: const Duration(milliseconds: 40), // Even faster
        onComplete: () {
          // After second message, button becomes "Let's Go!"
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              setState(() {
                _showNextButton = true; // Show "Let's Go!" button
              });
            }
          });
        },
      );
    }
  }
}

/// ✅ NEW: Message Bubble Widget with improved styling and typewriter effect
class _MessageBubble extends StatefulWidget {
  final String message;
  final bool isMovingForward;

  const _MessageBubble({
    Key? key,
    required this.message,
    this.isMovingForward = true,
  }) : super(key: key);

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _showBubble = false;
  bool _showTypewriter = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200), // Faster, more subtle
      vsync: this,
    );

    // Left-to-right expansion
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart, // Smooth, not bouncy
    ));

    // Start the animation sequence
    _startBubbleSequence();
  }

  void _startBubbleSequence() async {
    if (widget.isMovingForward) {
      // Forward: show bubble, then typewriter
      await Future.delayed(const Duration(milliseconds: 100)); // Faster
      if (mounted) {
        setState(() {
          _showBubble = true;
        });
        _controller.forward();
        
        // Wait briefly, then start typewriter
        await Future.delayed(const Duration(milliseconds: 150)); // Faster
        if (mounted) {
          setState(() {
            _showTypewriter = true;
          });
        }
      }
    } else {
      // Backward: show everything immediately
      if (mounted) {
        setState(() {
          _showBubble = true;
          _showTypewriter = true;
        });
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showBubble) {
      return Container(
        height: 70, // Increased from 55 to 70
        alignment: Alignment.centerLeft,
      );
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.centerLeft, // Expand from left
          transform: Matrix4.identity()..scale(_scaleAnimation.value, 1.0), // Only scale horizontally
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center, // Center the triangle
            children: [
              // Speech bubble tail pointing left to Bravo - centered vertically
              Container(
                child: CustomPaint(
                  size: const Size(12, 16), // Slightly bigger tail
                  painter: _BubbleTailPainter(),
                ),
              ),
              // Main speech bubble with fixed size
              Expanded(
                child: Container(
                  height: 70, // Increased from 55 to 70
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), // Increased padding
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5), // Lighter gray, no shadow
                    borderRadius: BorderRadius.circular(20), // Slightly larger radius
                  ),
                  child: Center(
                    child: _showTypewriter
                        ? widget.isMovingForward
                            ? TypewriterText(
                                text: widget.message,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16, // Increased from 14 to 16
                                  color: Color(0xFF333333),
                                  height: 1.3, // Slightly increased line height
                                ),
                                duration: const Duration(milliseconds: 15), // Much faster
                                // No callback needed anymore
                              )
                            : Text(
                                widget.message, // Show immediately when going backward
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16, // Increased from 14 to 16
                                  color: Color(0xFF333333),
                                  height: 1.3, // Slightly increased line height
                                ),
                                textAlign: TextAlign.center,
                              )
                        : Container(), // Empty when not showing typewriter
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ✅ NEW: Custom painter for message bubble triangle pointing down to Bravo
class _MessageBubbleTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF5F5F5) // Same gray as bubble
      ..style = PaintingStyle.fill;

    final path = Path();
    // Create a downward-pointing triangle
    path.moveTo(size.width * 0.5, size.height); // Bottom center (point)
    path.lineTo(0, 0); // Top left
    path.lineTo(size.width, 0); // Top right
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ✅ NEW: Custom painter for speech bubble tail pointing left
class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF5F5F5) // Same color as bubble
      ..style = PaintingStyle.fill;

    final path = Path();
    // Create a left-pointing triangle tail
    path.moveTo(size.width, 0); // Top right
    path.lineTo(size.width, size.height); // Bottom right
    path.lineTo(0, size.height * 0.5); // Left middle (pointing towards Bravo)
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ✅ NEW: Simplified Sliding Options Widget with Timer
class _SimplifiedSlidingOptions extends StatefulWidget {
  final dynamic question;
  final dynamic selected;
  final bool isMovingForward;
  final Function(int) onOptionSelected;

  const _SimplifiedSlidingOptions({
    Key? key,
    required this.question,
    required this.selected,
    required this.isMovingForward,
    required this.onOptionSelected,
  }) : super(key: key);

  @override
  State<_SimplifiedSlidingOptions> createState() => _SimplifiedSlidingOptionsState();
}

class _SimplifiedSlidingOptionsState extends State<_SimplifiedSlidingOptions>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  bool _showOptions = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Determine slide direction based on movement
    final startOffset = widget.isMovingForward 
        ? const Offset(1.0, 0.0)  // Slide in from right when moving forward
        : const Offset(-1.0, 0.0); // Slide in from left when moving backward

    _slideAnimation = Tween<Offset>(
      begin: startOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    ));

    // ✅ SIMPLIFIED: Use a simple timer instead of callbacks
    _startOptionsTimer();
  }

  void _startOptionsTimer() {
    if (widget.isMovingForward) {
      // Wait for question to type out (approximate timing)
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _showOptions = true;
          });
          _controller.forward();
        }
      });
    } else {
      // Going backward - show immediately
      setState(() {
        _showOptions = true;
      });
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const yellow = Color(0xFFF9CC53);
    const darkGray = Color(0xFF444444);

    // Don't show options until timer completes
    if (!_showOptions) {
      return Container(); // Empty container until ready to show
    }

    return SlideTransition(
      position: _slideAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: [
            if (widget.question.isMultiSelect)
              ...List.generate(widget.question.options.length, (i) {
                final isSelected = (widget.selected as Set<int>).contains(i);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                  child: BouncyButton(
                    onTap: () {
                      HapticUtils.lightImpact(); // Light haptic for option selection
                      widget.onOptionSelected(i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.ease,
                      decoration: BoxDecoration(
                        color: isSelected ? yellow : Colors.white,
                        border: Border.all(
                          color: isSelected ? yellow : Colors.grey.shade300,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: yellow.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.question.options[i],
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                fontSize: 16, // Slightly smaller text
                                color: isSelected ? Colors.white : darkGray,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              })
            else
              ...List.generate(widget.question.options.length, (i) {
                final isSelected = widget.selected == i;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                  child: BouncyButton(
                    onTap: () {
                      HapticUtils.lightImpact(); // Light haptic for option selection
                      widget.onOptionSelected(i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.ease,
                      decoration: BoxDecoration(
                        color: isSelected ? yellow : Colors.white,
                        border: Border.all(
                          color: isSelected ? yellow : Colors.grey.shade300,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: yellow.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.question.options[i],
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                fontSize: 16, // Slightly smaller text
                                color: isSelected ? Colors.white : darkGray,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

// ✅ Custom text field widget for consistent style (moved outside class)
class _BravoTextField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final bool isPassword;
  final bool passwordVisible;
  final VoidCallback? onToggleVisibility;
  final Color yellow;
  final TextEditingController? controller;

  const _BravoTextField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.keyboardType,
    this.isPassword = false,
    this.passwordVisible = false,
    this.onToggleVisibility,
    required this.yellow,
    this.controller,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      obscureText: isPassword && !passwordVisible,
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, color: Color(0xFFBDBDBD)),
        filled: true,
        fillColor: Colors.grey.shade50,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: yellow.withOpacity(0.3), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: yellow, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  passwordVisible ? Icons.visibility : Icons.visibility_off,
                  color: yellow,
                ),
                onPressed: () {
                  if (onToggleVisibility != null) {
                    HapticUtils.lightImpact(); // Light haptic for password toggle
                    onToggleVisibility!();
                  }
                },
              )
            : null,
      ),
    );
  }
} 