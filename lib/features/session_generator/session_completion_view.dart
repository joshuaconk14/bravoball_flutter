import 'package:flutter/material.dart';
import 'package:rive/rive.dart' hide LinearGradient;
import '../../constants/app_theme.dart';
import '../../widgets/bravo_button.dart';
import '../../views/main_tab_view.dart';

class SessionCompletionView extends StatefulWidget {
  final int currentStreak;
  final int completedDrills;
  final int totalDrills;
  final bool isFirstSessionOfDay;
  final int sessionsCompletedToday;
  final VoidCallback? onViewProgress;
  final VoidCallback? onBackToHome;

  const SessionCompletionView({
    Key? key,
    required this.currentStreak,
    required this.completedDrills,
    required this.totalDrills,
    required this.isFirstSessionOfDay,
    required this.sessionsCompletedToday,
    this.onViewProgress,
    this.onBackToHome,
  }) : super(key: key);

  @override
  State<SessionCompletionView> createState() => _SessionCompletionViewState();
}

class _SessionCompletionViewState extends State<SessionCompletionView>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _streakController;
  late AnimationController _characterController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _streakAnimation;
  late Animation<double> _characterBounceAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _streakController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _characterController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    
    _streakAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _streakController,
      curve: Curves.bounceOut,
    ));
    
    _characterBounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _characterController,
      curve: Curves.elasticOut,
    ));
    
    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
    
    await Future.delayed(const Duration(milliseconds: 300));
    _slideController.forward();
    _characterController.forward();
    
    await Future.delayed(const Duration(milliseconds: 500));
    _streakController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _streakController.dispose();
    _characterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryYellow,      // Use correct app yellow
              AppTheme.primaryDarkYellow,  // Use correct app dark yellow
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 15), // Reduced from 16
                
                // Success title
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: const Text(
                        "You've completed your session!",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 24, // Reduced from 28
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
                
                // Bravo character with Rive animation - smaller
                SlideTransition(
                  position: _slideAnimation,
                  child: AnimatedBuilder(
                    animation: _characterBounceAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _characterBounceAnimation.value,
                        child: AnimatedBuilder(
                          animation: _fadeAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _fadeAnimation.value,
                              child: _buildBravoCharacter(),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 16), // Reduced from 30
                
                // Streak display with animation
                AnimatedBuilder(
                  animation: _streakAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _streakAnimation.value,
                      child: _buildStreakDisplay(),
                    );
                  },
                ),
                
                const SizedBox(height: 8), // Reduced from 16
                
                // Day streak text
                AnimatedBuilder(
                  animation: _streakAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _streakAnimation.value,
                      child: const Text(
                        'Day Streak',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20, // Reduced from 24
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 16), // Reduced from 30
                
                // Session summary - more compact
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: _buildSessionSummary(),
                    );
                  },
                ),
                
                const Spacer(), // Use spacer to push buttons to bottom
                
                // Action buttons - always visible at bottom
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: _buildActionButtons(),
                    );
                  },
                ),
                
                const SizedBox(height: 16), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBravoCharacter() {
    return Container(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Grass base with shadow
          Positioned(
            bottom: 0,
            child: Container(
              width: 140,
              height: 25,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          
          // Bravo character using Rive animation
          Positioned(
            bottom: 15,
            child: SizedBox(
              width: 120,
              height: 120,
              child: RiveAnimation.asset(
                'assets/rive/Bravo_Animation.riv',
                fit: BoxFit.contain,
              ),
            ),
          ),
          
          // Soccer ball with animation
          Positioned(
            bottom: 16, // Reduced from 20
            right: 16, // Reduced from 20
            child: AnimatedBuilder(
              animation: _characterController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _characterController.value * 2 * 3.14159,
                  child: Container(
                    width: 28, // Reduced from 35
                    height: 28, // Reduced from 35
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Soccer ball pattern
                        Center(
                          child: Container(
                            width: 10, // Reduced from 12
                            height: 10, // Reduced from 12
                            decoration: BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6, // Reduced from 8
                          left: 6, // Reduced from 8
                          child: Container(
                            width: 4, // Reduced from 6
                            height: 4, // Reduced from 6
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6, // Reduced from 8
                          right: 6, // Reduced from 8
                          child: Container(
                            width: 4, // Reduced from 6
                            height: 4, // Reduced from 6
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 6, // Reduced from 8
                          left: 6, // Reduced from 8
                          child: Container(
                            width: 4, // Reduced from 6
                            height: 4, // Reduced from 6
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 6, // Reduced from 8
                          right: 6, // Reduced from 8
                          child: Container(
                            width: 4, // Reduced from 6
                            height: 4, // Reduced from 6
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Fire icon
        Container(
          width: 50, // Reduced from 60
          height: 50, // Reduced from 60
          decoration: BoxDecoration(
            color: Colors.orange.shade500,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_fire_department,
            color: Colors.white,
            size: 28, // Reduced from 35
          ),
        ),
        
        const SizedBox(width: 16), // Reduced from 20
        
        // Streak number
        Text(
          widget.currentStreak.toString(),
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 56, // Reduced from 64
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(width: 12), // Reduced from 15
        
        // Conditional indicator based on first session or additional sessions
        if (widget.isFirstSessionOfDay)
          // Show +1 for first session of the day
          Container(
            width: 44, // Reduced from 50
            height: 44, // Reduced from 50
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '+1',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14, // Reduced from 16
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          )
        else
          // Show checkmark for additional sessions
          Container(
            width: 44, // Reduced from 50
            height: 44, // Reduced from 50
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSessionSummary() {
    return Container(
      padding: const EdgeInsets.all(16), // Reduced from 20
      margin: const EdgeInsets.symmetric(horizontal: 5), // Reduced from 10
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            widget.isFirstSessionOfDay 
                ? 'Session Complete!' 
                : 'Another Session Complete!',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18, // Reduced from 20
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          if (!widget.isFirstSessionOfDay) ...[
            const SizedBox(height: 4),
            Text(
              '${widget.sessionsCompletedToday} session${widget.sessionsCompletedToday == 1 ? '' : 's'} completed today!',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
          
          const SizedBox(height: 12), // Reduced from 16
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSummaryItem(
                'Drills Completed',
                '${widget.completedDrills}/${widget.totalDrills}',
                Icons.check_circle,
              ),
              Container(
                width: 1,
                height: 32, // Reduced from 40
                color: Colors.white.withOpacity(0.3),
              ),
              _buildSummaryItem(
                'Current Streak',
                '${widget.currentStreak} day${widget.currentStreak == 1 ? '' : 's'}',
                Icons.local_fire_department,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6), // Reduced from 8
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 16, // Reduced from 20
          ),
        ),
        const SizedBox(height: 6), // Reduced from 8
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14, // Reduced from 16
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10, // Reduced from 11
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // View Progress button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: widget.onViewProgress,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryYellow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: widget.onBackToHome,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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