import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state_service.dart';
import '../../constants/app_theme.dart';
import '../../widgets/info_popup_widget.dart';
import '../../widgets/guest_account_overlay.dart'; // ✅ NEW: Import reusable guest overlay
import '../../utils/haptic_utils.dart';
import '../../utils/skill_utils.dart'; // ✅ ADDED: Import centralized skill utilities
import '../../features/onboarding/onboarding_flow.dart'; // ✅ ADDED: Import OnboardingFlow

class ProgressView extends StatefulWidget {
  const ProgressView({Key? key}) : super(key: key);

  @override
  State<ProgressView> createState() => _ProgressViewState();
}

class _ProgressViewState extends State<ProgressView> with SingleTickerProviderStateMixin {
  DateTime selectedDate = DateTime.now();
  DateTime? _previousDate; // Store previous date for transition
  bool showWeekView = true;
  CompletedSession? selectedSession;
  
  // Animation for month transitions
  late AnimationController _monthTransitionController;
  late Animation<Offset> _slideOutAnimation;
  late Animation<Offset> _slideInAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _monthTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    // Initialize with no animation
    _slideOutAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _monthTransitionController,
      curve: Curves.easeInOut,
    ));
    
    _slideInAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _monthTransitionController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _monthTransitionController.dispose();
    super.dispose();
  }

  void _changeMonth(int monthDelta) async {
    if (_isAnimating) return; // Prevent multiple animations at once
    
    setState(() {
      _isAnimating = true;
      _previousDate = selectedDate;
      
      // Going back in time (monthDelta < 0): October → September
      // - October slides OUT to the RIGHT (positive offset)
      // - September slides IN from the LEFT (negative to zero)
      
      // Going forward in time (monthDelta > 0): September → October
      // - September slides OUT to the LEFT (negative offset)
      // - October slides IN from the RIGHT (positive to zero)
      
      if (monthDelta < 0) {
        // Going BACK
        _slideOutAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(1.0, 0), // Current month slides RIGHT
        ).animate(CurvedAnimation(
          parent: _monthTransitionController,
          curve: Curves.easeInOut,
        ));
        
        _slideInAnimation = Tween<Offset>(
          begin: const Offset(-1.0, 0), // New month starts from LEFT
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _monthTransitionController,
          curve: Curves.easeInOut,
        ));
      } else {
        // Going FORWARD
        _slideOutAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-1.0, 0), // Current month slides LEFT
        ).animate(CurvedAnimation(
          parent: _monthTransitionController,
          curve: Curves.easeInOut,
        ));
        
        _slideInAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0), // New month starts from RIGHT
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _monthTransitionController,
          curve: Curves.easeInOut,
        ));
      }
      
      // Update to new date
      selectedDate = DateTime(selectedDate.year, selectedDate.month + monthDelta, 1);
    });
    
    // Run the animation
    _monthTransitionController.reset();
    await _monthTransitionController.forward();
    
    // Clean up after animation
    setState(() {
      _isAnimating = false;
      _previousDate = null;
    });
    _monthTransitionController.reset();
  }

  void _showSessionResults(CompletedSession session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DrillResultsView(session: session),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateService>(
      builder: (context, appState, child) {
        return Scaffold(
          backgroundColor: AppTheme.primaryYellow,
          body: Stack(
            children: [
              // Main content
              SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header section with day streak
                      _buildHeaderSection(),
                      
                      // White section with calendar
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height * 0.6,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            
                            // Calendar section
                            _buildCalendarSection(),
                            
                            const SizedBox(height: 20),
                            
                            // Progress stats
                            _buildProgressStats(),
                            
                            const SizedBox(height: 40), // Bottom padding instead of Spacer
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // ✅ NEW: Guest mode overlay using reusable widget
              if (appState.isGuestMode) 
                GuestAccountOverlay(
                  title: 'Create an account',
                  description: 'Track your progress and unlock all features by creating an account.',
                  themeColor: AppTheme.primaryYellow,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection() {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Progress title - large
            Text(
              'Progress',
              style: AppTheme.headlineMedium.copyWith(
                color: AppTheme.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            // Streak display (icon, number, and Day Streak in one row, all centered)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Icon(
                  Icons.local_fire_department,
                  color: AppTheme.secondaryOrange,
                  size: 80,
                  ),
                ),
                const SizedBox(width: 10),
                Consumer<AppStateService>(
                  builder: (context, appState, child) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            '${appState.currentStreak}',
                      style: TextStyle(
                        fontFamily: AppTheme.fontPoppins,
                        fontSize: 90,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.white,
                      ),
                          ),
                ),
                        const SizedBox(width: 20),
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            'Day\nStreak',
              style: TextStyle(
                fontFamily: AppTheme.fontPoppins,
                              fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.white,
              ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ],
                    );
                  },
            ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        child: Column(
          children: [
            // Calendar header with info icon moved here
            Row(
              children: [
                Text(
                  'Streak Calendar',
                  style: TextStyle(
                    fontFamily: AppTheme.fontPoppins,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    HapticUtils.lightImpact(); // Light haptic for info
                    _showInfoDialog(context);
                  },
                  child: Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryGray,
                    size: 22,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    HapticUtils.lightImpact(); // Light haptic for view toggle
                    setState(() {
                      showWeekView = !showWeekView;
                    });
                  },
                  child: Row(
                    children: [
                      Text(
                        showWeekView ? 'Week' : 'Month',
                        style: TextStyle(
                          fontFamily: AppTheme.fontPoppins,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        showWeekView ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                        color: AppTheme.primaryDark,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Month navigation (only show in month view)
            if (!showWeekView) ...[
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      HapticUtils.lightImpact(); // Light haptic for month navigation
                      _changeMonth(-1);
                    },
                    icon: Icon(Icons.chevron_left, color: Colors.grey.shade600),
                  ),
                  Expanded(
                    child: Text(
                      _getMonthYearString(selectedDate),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTheme.fontPoppins,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      HapticUtils.lightImpact(); // Light haptic for month navigation
                      _changeMonth(1);
                    },
                    icon: Icon(Icons.chevron_right, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ] else ...[
              // Just show current month for week view
              Text(
                _getMonthYearString(DateTime.now()),
                style: TextStyle(
                  fontFamily: AppTheme.fontPoppins,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDark,
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Day headers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                  .map((day) => SizedBox(
                        width: 30,
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTheme.fontPoppins,
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ))
                  .toList(),
            ),
            
            const SizedBox(height: 10),
            
            // Calendar grid with slide animation
            SizedBox(
              height: showWeekView ? 50 : 264, // Fixed height to prevent layout shifts
              child: ClipRect(
                child: Stack(
                  children: [
                    // Old month sliding out (only show during animation)
                    if (_isAnimating && _previousDate != null)
                      SlideTransition(
                        position: _slideOutAnimation,
                        child: showWeekView 
                          ? _buildWeekViewForDate(_previousDate!) 
                          : _buildMonthViewForDate(_previousDate!),
                      ),
                    
                    // New month sliding in
                    SlideTransition(
                      position: _isAnimating ? _slideInAnimation : _slideOutAnimation,
                      child: showWeekView 
                        ? _buildWeekViewForDate(selectedDate) 
                        : _buildMonthViewForDate(selectedDate),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekViewForDate(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final appState = Provider.of<AppStateService>(context, listen: false);
    
    // 🧠 Debug mental training sessions in calendar
    print('🧠 [CALENDAR] Building week view with ${appState.completedSessions.length} total sessions');
    final mentalTrainingSessions = appState.completedSessions.where((s) => s.sessionType == 'mental_training').length;
    print('🧠 [CALENDAR] Mental training sessions available: $mentalTrainingSessions');
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        final date = startOfWeek.add(Duration(days: index));
        final isToday = _isSameDay(date, now);
        final hasSession = appState.completedSessions.any((s) => _isSameDay(s.date, date));
        
        // 🧠 Debug sessions for this specific day
        final todaySessions = appState.completedSessions.where((s) => _isSameDay(s.date, date)).toList();
        if (todaySessions.isNotEmpty) {
          print('🧠 [CALENDAR] Day ${date.day}: ${todaySessions.length} sessions');
          for (final session in todaySessions) {
            print('   - Type: ${session.sessionType}, Date: ${session.date}, Drills: ${session.drills.length}');
          }
        }
        
        return _buildDayCell(date.day, isToday, hasSession, date: date);
      }),
    );
  }

  Widget _buildMonthViewForDate(DateTime date) {
    final daysInMonth = DateTime(date.year, date.month + 1, 0).day;
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final appState = Provider.of<AppStateService>(context, listen: false);
    return Column(
      children: [
        for (int week = 0; week < 6; week++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (dayOfWeek) {
                final dayNumber = week * 7 + dayOfWeek + 1 - firstWeekday;
                if (dayNumber <= 0 || dayNumber > daysInMonth) {
                  return const SizedBox(width: 30, height: 40);
                }
                final cellDate = DateTime(date.year, date.month, dayNumber);
                final isToday = _isSameDay(cellDate, DateTime.now());
                final hasSession = appState.completedSessions.any((s) => _isSameDay(s.date, cellDate));
                return _buildDayCell(dayNumber, isToday, hasSession, date: cellDate);
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildDayCell(int day, bool isToday, bool hasSession, {DateTime? date}) {
    Color backgroundColor = Colors.transparent;
    Color textColor = AppTheme.primaryDark;
    final appState = Provider.of<AppStateService>(context, listen: false);
    if (hasSession) {
      backgroundColor = AppTheme.secondaryBlue;
      textColor = AppTheme.white;
    }
    return GestureDetector(
      onTap: () {
        if (date != null) {
          final sessions = appState.completedSessions.where(
            (s) => s.date.year == date.year && s.date.month == date.month && s.date.day == date.day,
          );
          
          // 🧠 Debug what sessions are found for this day
          print('🧠 [CALENDAR] Tapped on day ${date!.day}/${date!.month}/${date!.year}');
          print('🧠 [CALENDAR] Found ${sessions.length} sessions for this day');
          
          for (final session in sessions) {
            print('🧠 [CALENDAR] Session: type=${session.sessionType}, date=${session.date}, drills=${session.drills.length}');
            if (session.sessionType == 'mental_training') {
              print('🧠 [CALENDAR] Mental training session found! Will show drill results.');
            }
          }
          
          if (sessions.isNotEmpty) {
            HapticUtils.lightImpact(); // Light haptic for session view
            final session = sessions.first;
            _showSessionResults(session);
          } else {
            print('🧠 [CALENDAR] No sessions found for this day - no drill results to show');
          }
        }
      },
      child: Container(
      width: 30,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: isToday ? Border.all(color: AppTheme.primaryYellow, width: 2) : null,
      ),
      child: Center(
        child: Text(
          day.toString(),
          style: TextStyle(
            fontFamily: AppTheme.fontPoppins,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStats() {
    return Consumer<AppStateService>(
      builder: (context, appState, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Main stats row (existing)
              Row(
            children: [
              Expanded(
                    child: _buildStatCard(
                      value: appState.highestStreak == 1 ? '${appState.highestStreak} day' : '${appState.highestStreak} days',
                      label: 'Highest Streak',
                      icon: Icons.local_fire_department,
                      color: AppTheme.secondaryOrange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      value: '${appState.countOfFullyCompletedSessions}',
                      label: 'Sessions\nCompleted',
                      icon: Icons.fitness_center,
                      color: AppTheme.primaryYellow,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // ✅ NEW: Favorite drill display
              if (appState.favoriteDrill.isNotEmpty)
                _buildFavoriteDrillSection(appState),
              
              const SizedBox(height: 16),
              
              // Enhanced stats grid
              _buildEnhancedStatsGrid(appState),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    // Determine gradient and accent for each stat
    Gradient gradient;
    Color iconBg;
    Color borderColor;
    if (icon == Icons.local_fire_department) {
      // Highest Streak (orange theme)
      gradient = LinearGradient(
        colors: [Colors.orange.shade100, Colors.deepOrange.shade50],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      iconBg = Colors.orange.shade200;
      borderColor = Colors.orange.shade300;
    } else {
      // Sessions Completed (yellow theme)
      gradient = LinearGradient(
        colors: [Colors.yellow.shade100, Colors.amber.shade50],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      iconBg = Colors.yellow.shade200;
      borderColor = Colors.amber.shade300;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
                child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
                  children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 14),
                    Text(
            value,
                      style: TextStyle(
                        fontFamily: AppTheme.fontPoppins,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontPoppins,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatsGrid(AppStateService appState) {
    return Column(
      children: [
        // Group 1: Skill Breakdown (Dribbling, Passing, Shooting, First Touch)
        _buildSkillStatsGroup(appState),
        
        const SizedBox(height: 16),
        
        // Group 2: Session Metrics (Drills per Session, Minutes per Session, Total Time)
        _buildSessionMetricsGroup(appState),
        
        const SizedBox(height: 16),
        
        // Group 3: Personal Stats (Most Improved Skill, Unique Drills, Difficulty Breakdown)
        _buildPositionAndFavoriteGroup(appState),
        
        const SizedBox(height: 16),
        
        // ✅ NEW: Group 4: Mental Training Stats
        _buildMentalTrainingGroup(appState),
      ],
    );
  }

  Widget _buildSkillStatsGroup(AppStateService appState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade50, Colors.grey.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sports_soccer,
                color: Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Drills completed',
                style: TextStyle(
                  fontFamily: AppTheme.fontPoppins,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSkillStatCard(
                  value: '${appState.dribblingDrillsCompleted}',
                  label: 'Dribbling',
                  icon: Icons.directions_run,
                  color: AppTheme.skillDribbling,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSkillStatCard(
                  value: '${appState.passingDrillsCompleted}',
                  label: 'Passing',
                  icon: Icons.arrow_forward,
                  color: AppTheme.skillPassing,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSkillStatCard(
                  value: '${appState.shootingDrillsCompleted}',
                  label: 'Shooting',
                  icon: Icons.sports_soccer,
                  color: AppTheme.skillShooting,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSkillStatCard(
                  value: '${appState.defendingDrillsCompleted}',
                  label: 'Defending',
                  icon: Icons.shield,
                  color: AppTheme.skillDefending,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSkillStatCard(
                  value: '${appState.firstTouchDrillsCompleted}',
                  label: 'First Touch',
                  icon: Icons.touch_app,
                  color: AppTheme.skillFirstTouch,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSkillStatCard(
                  value: '${appState.goalkeepingDrillsCompleted}',
                  label: 'Goalkeeping',
                  icon: Icons.sports_handball,
                  color: AppTheme.skillGoalkeeping,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSkillStatCard(
                  value: '${appState.fitnessDrillsCompleted}',
                  label: 'Fitness',
                  icon: Icons.sports,
                  color: AppTheme.skillFitness,
                ),
              ),
              const SizedBox(width: 12),
              // Empty space to maintain 2-column layout
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionMetricsGroup(AppStateService appState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade50, Colors.grey.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timer,
                color: Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Session Analytics',
                style: TextStyle(
                  fontFamily: AppTheme.fontPoppins,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSessionStatCard(
                  value: appState.drillsPerSession.toInt().toString(),
                  label: 'Average Drills\nper Session',
                  icon: Icons.list_alt,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSessionStatCard(
                  value: appState.minutesPerSession.toInt().toString(),
                  label: 'Average Minutes\nper Session',
                  icon: Icons.timer,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSessionStatCard(
                  value: _formatTotalTime(appState.totalTimeAllSessions),
                  label: 'Total Time\nAll Sessions',
                  icon: Icons.schedule,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              // Empty space to maintain 2-column layout
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPositionAndFavoriteGroup(AppStateService appState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade50, Colors.grey.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person,
                color: Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Personal Stats',
                style: TextStyle(
                  fontFamily: AppTheme.fontPoppins,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // First row: Most Improved Skill and Unique Drills
          Row(
            children: [
              Expanded(
                child: Tooltip(
                  message: appState.mostImprovedSkill.isNotEmpty ? appState.mostImprovedSkill : 'No improvement data yet',
                child: _buildPersonalStatCard(
                    value: appState.mostImprovedSkill.isNotEmpty ? appState.mostImprovedSkill : '—',
                    label: 'Most Improved\nSkill',
                    icon: Icons.trending_up,
                    color: Colors.green,
                    maxLines: 2,
                    valueFontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildPersonalStatCard(
                  value: '${appState.uniqueDrillsCompleted}',
                  label: 'Unique Drills\nCompleted',
                  icon: Icons.star,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Second row: Difficulty breakdown
          Row(
            children: [
              Expanded(
                child: _buildPersonalStatCard(
                  value: '${appState.beginnerDrillsCompleted}',
                  label: 'Beginner',
                  icon: Icons.school,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPersonalStatCard(
                  value: '${appState.intermediateDrillsCompleted}',
                  label: 'Intermediate',
                  icon: Icons.fitness_center,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPersonalStatCard(
                  value: '${appState.advancedDrillsCompleted}',
                  label: 'Advanced',
                  icon: Icons.whatshot,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMentalTrainingGroup(AppStateService appState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade50, Colors.grey.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Mental Training',
                style: TextStyle(
                  fontFamily: AppTheme.fontPoppins,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPersonalStatCard(
                  value: '${appState.mentalTrainingSessions}',
                  label: 'Mental Training\nSessions',
                  icon: Icons.psychology,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPersonalStatCard(
                  value: _formatTotalTime(appState.totalMentalTrainingMinutes),
                  label: 'Total Mental\nTraining Time',
                  icon: Icons.timer,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillStatCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTheme.fontPoppins,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
            label,
                      style: TextStyle(
                        fontFamily: AppTheme.fontPoppins,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
    );
  }

  Widget _buildSessionStatCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
                child: Column(
                  children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
                    Text(
            value,
                      style: TextStyle(
                        fontFamily: AppTheme.fontPoppins,
              fontSize: 18,
                        fontWeight: FontWeight.bold,
              color: color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
            label,
                      style: TextStyle(
                        fontFamily: AppTheme.fontPoppins,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalStatCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    int maxLines = 1,
    double? valueFontSize,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTheme.fontPoppins,
              fontSize: valueFontSize ?? 18,
                        fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontPoppins,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatTotalTime(int totalMinutes) {
    if (totalMinutes < 60) {
      return '${totalMinutes}m';
    } else if (totalMinutes < 1440) { // Less than 24 hours
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    } else {
      final days = totalMinutes ~/ 1440;
      final hours = (totalMinutes % 1440) ~/ 60;
      return hours > 0 ? '${days}d ${hours}h' : '${days}d';
    }
  }

  Widget _buildFavoriteDrillSection(AppStateService appState) {
    final favoriteDrillName = appState.favoriteDrill;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink.shade50, Colors.purple.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.pink.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.pink.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.favorite,
              color: Colors.pink.shade600,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Favorite Drill',
                  style: TextStyle(
                    fontFamily: AppTheme.fontPoppins,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.pink.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  favoriteDrillName,
                  style: TextStyle(
                    fontFamily: AppTheme.fontPoppins,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  String _getMonthYearString(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  void _showInfoDialog(BuildContext context) {
    InfoPopupWidget.show(
      context,
      title: 'Track Your Progress',
      description: 'View your comprehensive training progress with detailed metrics:\n\n• Calendar shows your daily training activity\n• Track your current and highest streaks\n• Monitor drills completed by skill type\n• See your session averages and total training time\n• Discover your most improved skill and unique drills completed\n• View difficulty breakdown (Beginner, Intermediate, Advanced)\n• Find your favorite drills and training patterns\n\nTap on calendar days to view detailed session results.',
      riveFileName: 'Bravo_Animation.riv',
    );
  }
} 

// Add DrillResultsView widget at the end of the file
class DrillResultsView extends StatefulWidget {
  final CompletedSession session;
  const DrillResultsView({Key? key, required this.session}) : super(key: key);

  @override
  State<DrillResultsView> createState() => _DrillResultsViewState();
}

class _DrillResultsViewState extends State<DrillResultsView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _animation = Tween<double>(begin: 0, end: widget.session.totalCompletedDrills / (widget.session.totalDrills == 0 ? 1 : widget.session.totalDrills))
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final percent = session.totalDrills == 0 ? 0.0 : session.totalCompletedDrills / session.totalDrills;
    
    // 🧠 Debug the session being displayed
    print('🧠 [DRILL_RESULTS] Displaying session:');
    print('   Type: ${session.sessionType}');
    print('   Date: ${session.date}');
    print('   Drills: ${session.drills.length}');
    print('   Completed: ${session.totalCompletedDrills}/${session.totalDrills}');
    
    if (session.sessionType == 'mental_training') {
      print('🧠 [DRILL_RESULTS] This is a mental training session!');
      for (int i = 0; i < session.drills.length; i++) {
        final drill = session.drills[i];
        print('   Drill $i: ${drill.drill.title} (${drill.drill.skill})');
      }
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    HapticUtils.lightImpact(); // Light haptic for close
                    Navigator.of(context).pop();
                  },
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(session.date),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Score:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return AnimatedProgressCircle(
                  percent: _animation.value,
                  label: '${session.totalCompletedDrills} / ${session.totalDrills}',
                  color: AppTheme.primaryYellow,
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Drills:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ...session.drills.map((drill) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.primaryYellow,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Drill: ${drill.drill.title}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Skill: ${SkillUtils.formatSkillForDisplay(drill.drill.skill)}', // ✅ UPDATED: Use centralized skill formatting
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    Text(
                      'Duration: ${drill.totalDuration}min    Sets: ${drill.totalSets}    Reps: ${drill.totalReps}',
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    Text(
                      'Equipment: ${drill.drill.equipment.join(", ")}',
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${_monthName(date.month)} ${date.day}, ${date.year}';
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}

class AnimatedProgressCircle extends StatelessWidget {
  final double percent;
  final String label;
  final Color color;
  const AnimatedProgressCircle({Key? key, required this.percent, required this.label, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: CircularProgressIndicator(
              value: percent,
              strokeWidth: 8,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 36,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
} 