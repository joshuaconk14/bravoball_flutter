import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../utils/haptic_utils.dart';
import '../../widgets/bravo_button.dart';
import 'mental_training_timer_view.dart';

class MentalTrainingSetupView extends StatefulWidget {
  const MentalTrainingSetupView({Key? key}) : super(key: key);

  @override
  State<MentalTrainingSetupView> createState() => _MentalTrainingSetupViewState();
}

class _MentalTrainingSetupViewState extends State<MentalTrainingSetupView> 
    with TickerProviderStateMixin {
  int _selectedDuration = 15; // Default to 15 minutes
  
  final List<int> _availableDurations = [5, 10, 15, 20, 25, 30];
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    // Initialize animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryYellow.withValues(alpha: 0.1),
              AppTheme.backgroundPrimary,
              AppTheme.backgroundPrimary,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Custom App Bar
                    _buildCustomAppBar(),
                    
                    const SizedBox(height: 24),
                    
                    // Animated Header Section (now horizontal)
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: _buildHeaderSection(),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Duration Selection Section
                    Expanded(
                      child: _buildDurationSelection(),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Start Button
                    _buildStartButton(),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            HapticUtils.lightImpact();
            Navigator.of(context).pop();
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: AppTheme.primaryGray,
              size: 20,
            ),
          ),
        ),
        Expanded(
          child: Text(
            'Mental Training',
            textAlign: TextAlign.center,
            style: AppTheme.headlineSmall.copyWith(
              color: AppTheme.primaryDark,
            ),
          ),
        ),
        const SizedBox(width: 40), // For balance
      ],
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        // Mental Training Icon - centered and larger
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryYellow,
                      AppTheme.primaryYellow.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryYellow.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.psychology_rounded,
                  size: 50,
                  color: AppTheme.white,
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 24),
        
        // Title - centered
        Text(
          'Stronger Mind, Stronger Game',
          textAlign: TextAlign.center,
          style: AppTheme.headlineSmall.copyWith(
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Description - centered
        Text(
          'Take a break from physical training and build mental strength. We\'ll time your session and provide motivational quotes for accountability. This counts as a completed session toward your progress streak.',
          textAlign: TextAlign.center,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.primaryGray,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your session duration',
          style: AppTheme.titleLarge.copyWith(
            color: AppTheme.primaryDark,
          ),
        ),
        
        const SizedBox(height: 16),
        
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0), // ✅ ADDED: Extra horizontal padding
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0), // ✅ ADDED: Vertical padding for shadows
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.0,
                crossAxisSpacing: 12, // ✅ REDUCED: From 16 to 12 to give more space
                mainAxisSpacing: 16,
              ),
              itemCount: _availableDurations.length,
              itemBuilder: (context, index) {
                final duration = _availableDurations[index];
                final isSelected = duration == _selectedDuration;
                
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 400 + (index * 100)),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: _buildDurationCard(duration, isSelected),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationCard(int duration, bool isSelected) {
    return AnimatedScale(
      scale: isSelected ? 1.02 : 1.0, // ✅ REDUCED: From 1.05 to 1.02 to prevent overflow
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: () {
          HapticUtils.mediumImpact();
          setState(() {
            _selectedDuration = duration;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppTheme.primaryYellow,
                      AppTheme.primaryYellow.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : AppTheme.backgroundSecondary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryYellow
                  : AppTheme.buttonDisabledGray,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryYellow.withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$duration',
                style: AppTheme.headlineLarge.copyWith(
                  color: isSelected ? AppTheme.white : AppTheme.primaryDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'minutes',
                style: AppTheme.bodyLarge.copyWith(
                  color: isSelected 
                      ? AppTheme.white.withValues(alpha: 0.9) 
                      : AppTheme.primaryGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: double.infinity,
            height: 56,
            child: BravoButton(
              text: 'Start Mental Training',
              onPressed: () {
                HapticUtils.heavyImpact();
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        MentalTrainingTimerView(durationMinutes: _selectedDuration),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: animation.drive(
                          Tween(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).chain(CurveTween(curve: Curves.easeInOut)),
                        ),
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                );
              },
              color: AppTheme.primaryYellow,
              backColor: AppTheme.primaryDarkYellow,
              textColor: AppTheme.white,
            ),
          ),
        );
      },
    );
  }
} 