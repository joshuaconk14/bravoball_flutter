import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'onboarding_questions.dart';
import '../../widgets/bravo_button.dart';
import '../../features/auth/login_view.dart';
import '../../constants/app_theme.dart';
import '../../services/onboarding_service.dart';
import '../../models/onboarding_model.dart';
import '../../main.dart'; // Import for MyApp

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({Key? key}) : super(key: key);

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _step = 0; // 0: initial, 1: preview, 2+: questions
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
    // Only advance if not past registration
    if (_step < stepRegistration) {
      setState(() => _step++);
    }
    // Do not automatically go to login page here
  }

  void _back() {
    if (_step == 1) {
      setState(() => _step = 0); // back to initial
    } else if (_step > 1) {
      setState(() => _step--);
    }
  }

  void _selectOption(int optionIdx) {
    setState(() {
      _answers[_step] = optionIdx;
    });
  }

  void _skip() {
    // If on registration, do nothing
    if (_step == stepRegistration) {
      // Do nothing, already on registration
    } else {
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

  @override
  Widget build(BuildContext context) {
    // Debug prints
    final qIdx = _step - stepFirstQuestion;
    debugPrint('ONBOARDING DEBUG: _step=$_step, qIdx=$qIdx, stepRegistration=$stepRegistration');

    if (_step == stepInitial) {
      // Initial page
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 48),
              SizedBox(
                height: 220,
                child: RiveAnimation.asset(
                  'assets/rive/Bravo_Animation.riv',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'BravoBall',
                style: const TextStyle(
                  fontFamily: 'PottaOne',
                  fontSize: 40,
                  fontWeight: FontWeight.w400,
                  color: yellow,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Start Small. Dream Big',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkGray,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BravoButton(
                      text: 'Create an account',
                      onPressed: () => setState(() => _step = 1),
                      color: yellow,
                      backColor: AppTheme.primaryDarkYellow,
                      textColor: Colors.white,
                      disabled: false,
                    ),
                    const SizedBox(height: 16),
                    BravoButton(
                      text: 'Login',
                      onPressed: _goToLogin,
                      color: Colors.white,
                      backColor: AppTheme.lightGray,
                      textColor: AppTheme.primaryYellow,
                      disabled: false,
                      borderSide: BorderSide(color: Colors.grey.shade200, width: 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      );
    }

    if (_step == stepPreview) {
      // Preview screen
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 8),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: darkGray),
                    onPressed: _back,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 180,
                child: RiveAnimation.asset(
                  'assets/rive/Bravo_Animation.riv',
                  stateMachines: const ['State Machine 2'],
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Hello! I'm Bravo!",
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: darkGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  "I'll help you improve as a soccer player and achieve your goals.\n\nLet me ask you a few quick questions to create your personalized training plan.",
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.normal,
                    fontSize: 16,
                    color: darkGray,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: BravoButton(
                    text: 'Next',
                    onPressed: _next,
                    color: yellow,
                    backColor: AppTheme.primaryDarkYellow,
                    textColor: Colors.white,
                    disabled: false,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      );
    }

    // Question screens
    if (_step >= stepFirstQuestion && _step < stepRegistration) {
      final qIdx = _step - stepFirstQuestion;
    final question = onboardingQuestions[qIdx];
      final selected = question.isMultiSelect ? _multiAnswers[_step] ?? <int>{} : _answers[_step];
      final progress = (_step - stepFirstQuestion + 1) / (onboardingQuestions.length + 1);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Row(
                children: [
                    if (_step >= stepFirstQuestion)
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
                  TextButton(
                    onPressed: _skip,
                    child: const Text('Skip',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        color: darkGray,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bravo and question
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: RiveAnimation.asset(
                      'assets/rive/Bravo_Animation.riv',
                      stateMachines: const ['State Machine 2'],
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        question.question,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: darkGray,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
              // Scrollable options
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      if (question.isMultiSelect)
                        ...List.generate(question.options.length, (i) {
                          final isSelected = (selected as Set<int>).contains(i);
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  final set = _multiAnswers[_step] ?? <int>{};
                                  if (set.contains(i)) {
                                    set.remove(i);
                                  } else {
                                    set.add(i);
                                  }
                                  _multiAnswers[_step] = set;
                                });
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
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        question.options[i],
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: isSelected ? Colors.white : darkGray,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(Icons.check, color: Colors.white),
                                  ],
                                ),
                              ),
                            ),
                          );
                        })
                      else
            ...List.generate(question.options.length, (i) {
              final isSelected = selected == i;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                child: GestureDetector(
                  onTap: () => _selectOption(i),
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
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            question.options[i],
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: isSelected ? Colors.white : darkGray,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              );
            }),
                    ],
                  ),
                ),
              ),
              // Next button fixed at bottom
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: BravoButton(
                  text: 'Next',
                  onPressed: question.isMultiSelect
                      ? (selected as Set<int>).isNotEmpty ? _next : null
                      : selected != null ? _next : null,
                  color: yellow,
                  backColor: AppTheme.primaryDarkYellow,
                  textColor: Colors.white,
                  disabled: false,
                ),
              ),
            ),
            ],
          ),
        ),
      );
    }

    if (_step == stepRegistration) {
      // Registration form step
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top: Bravo mascot and speech bubble
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: darkGray),
                      onPressed: _back,
                    ),
                    const Spacer(),
                    // Working Skip button
                    TextButton(
                      onPressed: () {
                        // Skip registration and let AuthenticationWrapper handle navigation
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const MyApp()),
                          (route) => false,
                        );
                      },
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          color: darkGray,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: RiveAnimation.asset(
                        'assets/rive/Bravo_Animation.riv',
                        stateMachines: const ['State Machine 2'],
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Text(
                          'Enter your Registration Info below!',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: darkGray,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Scrollable form fields
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
                        }),
                        isPassword: true,
                        yellow: yellow,
                        passwordVisible: _regConfirmPasswordVisible,
                        onToggleVisibility: () => setState(() => _regConfirmPasswordVisible = !_regConfirmPasswordVisible),
                      ),
                      if (_regError.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(_regError, style: const TextStyle(color: Colors.red)),
                        ),
                    ],
                  ),
                ),
              ),
              // Fixed Submit button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: _isSubmitting
                      ? const Center(child: CircularProgressIndicator())
                      : BravoButton(
                          text: 'Submit',
                          onPressed: (_regEmail.isEmpty || _regPassword.isEmpty || _regConfirmPassword.isEmpty)
                              ? null
                              : () async {
                                  setState(() {
                                    _regError = '';
                                  });
                                  if (!_regEmail.contains('@')) {
                                    setState(() => _regError = 'Please enter a valid email.');
                                    return;
                                  } else if (_regPassword.length < 6) {
                                    setState(() => _regError = 'Password must be at least 6 characters.');
                                    return;
                                  } else if (_regPassword != _regConfirmPassword) {
                                    setState(() => _regError = 'Passwords do not match.');
                                    return;
                                  }
                                  setState(() => _isSubmitting = true);
                                  // Gather onboarding answers
                                  final answers = _answers;
                                  final multiAnswers = _multiAnswers;
                                  final onboardingData = OnboardingData(
                                    email: _regEmail,
                                    password: _regPassword,
                                    primaryGoal: onboardingQuestions[0].options[answers[2] ?? 0],
                                    trainingExperience: onboardingQuestions[1].options[answers[3] ?? 0],
                                    position: onboardingQuestions[2].options[answers[4] ?? 0],
                                    ageRange: onboardingQuestions[3].options[answers[5] ?? 0],
                                    strengths: (multiAnswers[6] ?? <int>{}).map((i) => onboardingQuestions[4].options[i]).toList(),
                                    areasToImprove: (multiAnswers[7] ?? <int>{}).map((i) => onboardingQuestions[5].options[i]).toList(),
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
        ),
      );
    }

    // Fallback (should never hit)
    return const SizedBox.shrink();
  }
}

// Custom text field widget for consistent style
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
                onPressed: onToggleVisibility,
              )
            : null,
      ),
    );
  }
} 