import 'package:flutter/material.dart';
import 'package:rive/rive.dart' hide LinearGradient, Image;
import '../../constants/app_theme.dart';
import '../../constants/app_assets.dart';
import '../../services/audio_service.dart';
import '../../services/ad_service.dart'; // ✅ ADDED: Import AdService
import '../../utils/haptic_utils.dart';
import '../../services/app_rating_service.dart';
import '../../services/user_manager_service.dart';

class SessionCompletionView extends StatefulWidget {
  final int currentStreak;
  final int completedDrills;
  final int totalDrills;
  final bool isFirstSessionOfDay;
  final int sessionsCompletedToday;
  final int treatsAwarded; // ✅ Treats awarded from backend
  final VoidCallback? onViewProgress;
  final VoidCallback? onBackToHome;

  const SessionCompletionView({
    Key? key,
    required this.currentStreak,
    required this.completedDrills,
    required this.totalDrills,
    required this.isFirstSessionOfDay,
    required this.sessionsCompletedToday,
    required this.treatsAwarded, // ✅ Required - backend provides this
    this.onViewProgress,
    this.onBackToHome,
  });

  @override
  State<SessionCompletionView> createState() => _SessionCompletionViewState();
}

class _SessionCompletionViewState extends State<SessionCompletionView>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _streakController;
  late AnimationController _characterController;
  late AnimationController _treatsController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _streakAnimation;
  late Animation<double> _characterBounceAnimation;
  late Animation<double> _treatsAnimation;

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
    
    _treatsController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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
    
    _treatsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _treatsController,
      curve: Curves.bounceOut,
    ));
    
    // Start animations
    _startAnimations();
    
    // Check and show rating prompt if needed
    _checkAndShowRatingPrompt();
  }

  Future<void> _checkAndShowRatingPrompt() async {
    // Increment session count
    await AppRatingService.instance.incrementSessionCount();
    
    // Wait a bit so user sees the completion celebration first
    await Future.delayed(const Duration(seconds: 3));
    
    // Check if we should show the prompt
    if (await AppRatingService.instance.shouldShowRatingPrompt()) {
      await AppRatingService.instance.requestReview();
    }
  }

  void _startAnimations() async {
    // ✅ IMPROVED: Play success sound right when completion view appears
    AudioService.playSuccess();
    HapticUtils.heavyImpact(); // Add celebration haptic too
    
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
    
    await Future.delayed(const Duration(milliseconds: 300));
    _slideController.forward();
    _characterController.forward();
    
    await Future.delayed(const Duration(milliseconds: 500));
    _streakController.forward();
    
    await Future.delayed(const Duration(milliseconds: 300));
    _treatsController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _streakController.dispose();
    _characterController.dispose();
    _treatsController.dispose();
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
                
                const SizedBox(height: 20),
                
                // Treats reward display with animation (only show for authenticated users)
                if (!UserManagerService.instance.isGuestMode)
                  AnimatedBuilder(
                    animation: _treatsAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _treatsAnimation.value,
                        child: Opacity(
                          opacity: _treatsAnimation.value,
                          child: _buildTreatsReward(),
                        ),
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
      child: Center(
        child: SizedBox(
          width: 120,
          height: 120,
          child: RiveAnimation.asset(
            AppAssets.bravoAnimation,
            fit: BoxFit.contain,
          ),
        ),
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
                color: Colors.orange.withValues(alpha: 0.3),
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
                  color: AppTheme.primaryGreen.withValues(alpha: 0.3),
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
                  color: AppTheme.primaryGreen.withValues(alpha: 0.3),
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
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
                color: Colors.white.withValues(alpha: 0.9),
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
                color: Colors.white.withValues(alpha: 0.3),
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
            color: Colors.white.withValues(alpha: 0.2),
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
            color: Colors.white.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTreatsReward() {
    // ✅ Use treats awarded from backend (dynamic calculation)
    final treatAmount = widget.treatsAwarded;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Treat icon
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.primaryYellow,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryYellow.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              AppAssets.treatIcon,
              width: 34,
              height: 34,
              fit: BoxFit.contain,
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Treat amount
        Text(
          treatAmount.toString(),
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(width: 8),
        
        // "Treats" label
        const Text(
          'Treats',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Plus icon indicator
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '+',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
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