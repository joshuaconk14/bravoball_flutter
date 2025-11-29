import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../constants/app_assets.dart';
import '../../views/main_tab_view.dart';
import '../../utils/haptic_utils.dart';
import '../../services/audio_service.dart';

/// View that displays the breakdown of treats awarded after session completion
class TreatRewardBreakdownView extends StatefulWidget {
  final int treatsAwarded;
  final Map<String, dynamic>? treatBreakdown;
  final bool treatsAlreadyGranted;
  final VoidCallback? onViewProgress;
  final VoidCallback? onBackToHome;

  const TreatRewardBreakdownView({
    Key? key,
    required this.treatsAwarded,
    this.treatBreakdown,
    this.treatsAlreadyGranted = false,
    this.onViewProgress,
    this.onBackToHome,
  }) : super(key: key);

  @override
  State<TreatRewardBreakdownView> createState() => _TreatRewardBreakdownViewState();
}

class _TreatRewardBreakdownViewState extends State<TreatRewardBreakdownView>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _treatsController;
  late AnimationController _breakdownController;
  late AnimationController _buttonsController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _treatsAnimation;
  late Animation<double> _breakdownAnimation;
  late Animation<double> _buttonsAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _treatsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _breakdownController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _buttonsController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    // Initialize animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    
    _treatsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _treatsController,
      curve: Curves.bounceOut,
    ));
    
    _breakdownAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _breakdownController,
      curve: Curves.easeOut,
    ));
    
    _buttonsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonsController,
      curve: Curves.easeOut,
    ));
    
    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    // Play subtle success sound
    AudioService.playSuccess();
    HapticUtils.lightImpact();
    
    await Future.delayed(const Duration(milliseconds: 100));
    _fadeController.forward();
    
    await Future.delayed(const Duration(milliseconds: 200));
    _slideController.forward();
    
    await Future.delayed(const Duration(milliseconds: 300));
    _treatsController.forward();
    
    await Future.delayed(const Duration(milliseconds: 400));
    _breakdownController.forward();
    
    await Future.delayed(const Duration(milliseconds: 300));
    _buttonsController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _treatsController.dispose();
    _breakdownController.dispose();
    _buttonsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Extract breakdown data with defaults
    final drillsCompleted = widget.treatBreakdown?['drills_completed'] ?? 0;
    final difficultyBonus = widget.treatBreakdown?['difficulty_bonus'] ?? 0;
    final completionBonus = widget.treatBreakdown?['completion_bonus'] ?? 0;
    final streakMultiplier = (widget.treatBreakdown?['streak_multiplier'] ?? 1.0).toDouble();
    final baseTreats = widget.treatBreakdown?['base_treats'] ?? 0;
    final totalBeforeStreak = widget.treatBreakdown?['total_before_streak'] ?? 0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryYellow,
              AppTheme.primaryDarkYellow,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Title with fade animation
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: const Text(
                        'Treat Breakdown',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 18),
                
                // Total treats awarded with slide and scale animation
                SlideTransition(
                  position: _slideAnimation,
                  child: AnimatedBuilder(
                    animation: _treatsAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _treatsAnimation.value,
                        child: Opacity(
                          opacity: _treatsAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  AppAssets.treatIcon,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  widget.treatsAwarded.toString(),
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Treats',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 18),
                
                // Breakdown details - fit everything without scrolling
                Expanded(
                  child: AnimatedBuilder(
                    animation: _breakdownAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _breakdownAnimation.value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - _breakdownAnimation.value)),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(32),
                                topRight: Radius.circular(32),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, -4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Breakdown',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryDark,
                                  ),
                                ),
                                
                                const SizedBox(height: 14),
                                
                                // Note if treats were already granted
                                if (widget.treatsAlreadyGranted)
                                  AnimatedBuilder(
                                    animation: _fadeAnimation,
                                    builder: (context, child) {
                                      return Opacity(
                                        opacity: _fadeAnimation.value,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                          margin: const EdgeInsets.only(bottom: 14),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryYellow.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: AppTheme.primaryYellow.withOpacity(0.3),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                color: AppTheme.primaryYellow,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'You\'ve already completed a session today, no treats granted.',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: AppTheme.primaryDark.withOpacity(0.8),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                
                                // Drills Completed (informational, separate)
                                if (drillsCompleted > 0) ...[
                                  _buildBreakdownRow(
                                    label: 'Drills Completed',
                                    value: drillsCompleted.toString(),
                                    icon: Icons.check_circle_outline,
                                    color: AppTheme.primaryDark,
                                    delay: 0,
                                    isInfo: true,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                
                                // Bonus Treats Table
                                AnimatedBuilder(
                                  animation: _breakdownAnimation,
                                  builder: (context, child) {
                                    return Opacity(
                                      opacity: _breakdownAnimation.value,
                                      child: Transform.translate(
                                        offset: Offset(0, 20 * (1 - _breakdownAnimation.value)),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: AppTheme.lightGray,
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: AppTheme.primaryDark.withOpacity(0.1),
                                              width: 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.05),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            children: [
                                              // Base treats
                                              _buildTableRow(
                                                label: 'Base Treats',
                                                value: baseTreats.toString(),
                                                icon: Icons.star_outline,
                                                delay: 100,
                                                isFirst: true,
                                                isLast: difficultyBonus == 0 && completionBonus == 0,
                                              ),
                                              
                                              if (difficultyBonus > 0)
                                                _buildTableRow(
                                                  label: 'Difficulty Bonus',
                                                  value: '+$difficultyBonus',
                                                  icon: Icons.trending_up,
                                                  color: AppTheme.primaryPurple,
                                                  delay: 200,
                                                  isLast: completionBonus == 0,
                                                ),
                                              
                                              if (completionBonus > 0)
                                                _buildTableRow(
                                                  label: 'Completion Bonus',
                                                  value: '+$completionBonus',
                                                  icon: Icons.emoji_events,
                                                  color: AppTheme.primaryYellow,
                                                  delay: 300,
                                                  isLast: true,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // Subtotal before streak
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.lightGray,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Subtotal',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryDark,
                                        ),
                                      ),
                                      Text(
                                        totalBeforeStreak.toString(),
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                if (streakMultiplier > 1.0) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.primaryYellow.withOpacity(0.3),
                                          AppTheme.primaryYellow.withOpacity(0.15),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppTheme.primaryYellow,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryYellow.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.local_fire_department,
                                              color: AppTheme.primaryYellow,
                                              size: 22,
                                            ),
                                            const SizedBox(width: 10),
                                            const Text(
                                              'Streak Multiplier',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.primaryDark,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '${streakMultiplier.toStringAsFixed(1)}x',
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                
                                const Spacer(),
                                
                                // Navigation buttons with animation
                                AnimatedBuilder(
                                  animation: _buttonsAnimation,
                                  builder: (context, child) {
                                    return Opacity(
                                      opacity: _buttonsAnimation.value,
                                      child: Transform.translate(
                                        offset: Offset(0, 20 * (1 - _buttonsAnimation.value)),
                                        child: _buildNavigationButtons(context),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBreakdownRow({
    required String label,
    required String value,
    required IconData icon,
    Color? color,
    int delay = 0,
    bool isInfo = false, // For informational rows (not bonuses)
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, animationValue, child) {
        return Opacity(
          opacity: animationValue,
          child: Transform.translate(
            offset: Offset(20 * (1 - animationValue), 0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: isInfo 
                    ? AppTheme.lightGray.withOpacity(0.5)
                    : AppTheme.lightGray,
                borderRadius: BorderRadius.circular(12),
                border: isInfo 
                    ? Border.all(
                        color: AppTheme.primaryDark.withOpacity(0.1),
                        width: 1,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        icon,
                        color: color ?? AppTheme.primaryDark,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: isInfo ? FontWeight.w500 : FontWeight.w500,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: color ?? AppTheme.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableRow({
    required String label,
    required String value,
    required IconData icon,
    Color? color,
    int delay = 0,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, animationValue, child) {
        return Opacity(
          opacity: animationValue,
          child: Transform.translate(
            offset: Offset(20 * (1 - animationValue), 0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  top: isFirst 
                      ? BorderSide.none
                      : BorderSide(
                          color: AppTheme.primaryDark.withOpacity(0.1),
                          width: 1,
                        ),
                  bottom: isLast
                      ? BorderSide.none
                      : BorderSide(
                          color: AppTheme.primaryDark.withOpacity(0.1),
                          width: 1,
                        ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        icon,
                        color: color ?? AppTheme.primaryDark,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: color ?? AppTheme.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    return Column(
      children: [
        // View Progress button
        Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: widget.onViewProgress ?? () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const MainTabView(initialIndex: 1),
                ),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryYellow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              'View Progress',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Back to Home button
        Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: widget.onBackToHome ?? () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const MainTabView(initialIndex: 0),
                ),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Back to Home Page',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
