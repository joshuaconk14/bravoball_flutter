import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';
import '../../widgets/bravo_button.dart';
import '../../models/drill_model.dart';
import '../../models/editable_drill_model.dart';
import '../../services/app_state_service.dart';
import '../../constants/app_theme.dart';
import 'session_generator_editor_page.dart';
import 'edit_drill_view.dart';
import 'drill_follow_along_view.dart';
import 'session_completion_view.dart';
import '../../views/main_tab_view.dart';

class SessionGeneratorHomeFieldView extends StatefulWidget {
  const SessionGeneratorHomeFieldView({Key? key}) : super(key: key);

  @override
  State<SessionGeneratorHomeFieldView> createState() => _SessionGeneratorHomeFieldViewState();
}

class _SessionGeneratorHomeFieldViewState extends State<SessionGeneratorHomeFieldView> {
  // Build the home field view
  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateService>(
      builder: (context, appState, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // Top bar (white, compact)
              _buildTopBar(context),
              
              // Main scrollable content
              Expanded(
                child: Container(
                  color: AppTheme.backgroundField,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // Field area with controlled height
                        _buildFieldArea(context, appState),
                        
                        // Begin button
                        _buildBeginButton(appState),
                        
                        // Drill circles and trophy
                        _buildDrillPath(appState),
                        
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Top bar with BravoBall logo and profile/fire icons
  Widget _buildTopBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade400,
            width: 2.0,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const MainTabView(initialIndex: 3),
                    ),
                    (route) => false,
                  );
                },
                child: CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.backgroundPrimary,
                child: Icon(Icons.person, color: AppTheme.secondaryBlue, size: 28),
                ),
              ),
              
              const Spacer(),
              
              Text(
                'BravoBall',
                style: TextStyle(
                  fontFamily: AppTheme.fontPottaOne,
                  fontSize: 22,
                  color: AppTheme.primaryYellow,
                  fontWeight: FontWeight.w400,
                ),
              ),
              
              const Spacer(),
              
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const MainTabView(initialIndex: 1),
                    ),
                    (route) => false,
                  );
                },
                child: Consumer<AppStateService>(
                  builder: (context, appState, child) {
                    return Row(
                      children: [
                        Icon(Icons.local_fire_department, color: AppTheme.secondaryOrange, size: 24),
                        const SizedBox(width: 4),
                        Text(
                          '${appState.currentStreak}', // Use actual streak from AppStateService
                          style: TextStyle(
                            fontFamily: AppTheme.fontPoppins,
                            fontSize: 20,
                            color: AppTheme.secondaryOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build the field area with Rive animation, Bravo character, and backpack
  Widget _buildFieldArea(BuildContext context, AppStateService appState) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return SizedBox(
      height: 320, // Reduced height for more compact layout
      child: Stack(
        clipBehavior: Clip.none, // Allow content to overflow to show the top of the field
        children: [
          // Rive grass field background - positioned to show goal at the top
          Positioned(
            top: 160, // Positive offset to push field down and show goal at top
            left: 0,
            right: 0,
            child: SizedBox(
              height: 380, // Reduced height for appropriate field size
              child: RiveAnimation.asset(
                'assets/rive/Grass_Field.riv',
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Status message bubble - speech bubble coming from Bravo
          Positioned(
            top: 100, // Positioned right above Bravo 
            left: 70,  // Aligned with Bravo's position
            right: 180, // Give enough space
            child: _buildStatusMessage(appState),
          ),
          
          // Bravo in middle field area
          Positioned(
            top: 180, // Moved up to be closer to goal area
            left: screenWidth * 0.25,
            child: SizedBox(
              width: 110,
              height: 110,
              child: RiveAnimation.asset(
                'assets/rive/Bravo_Animation.riv',
                fit: BoxFit.contain,
              ),
            ),
          ),
          
          // Backpack in middle field area
          Positioned(
            top: 200, // Moved up to be closer to goal area
            right: screenWidth * 0.25,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SessionGeneratorEditorPage(),
                  ),
                );
              },
              child: SizedBox(
                width: 90,
                height: 90,
                child: RiveAnimation.asset(
                  'assets/rive/Backpack.riv',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Begin button
  Widget _buildBeginButton(AppStateService appState) {
    final hasSessionDrills = appState.editableSessionDrills.isNotEmpty;
    final sessionInProgress = appState.hasSessionProgress;
    
    return Padding(
      padding: const EdgeInsets.only(
        left: 32,
        right: 32,
        bottom: 25, // Increased bottom padding to push drill circles further down
      ),
      child: SizedBox(
        width: 180, // Fixed width to match Bravo + backpack width
        child: BravoButton(
          text: sessionInProgress ? 'Continue Training' : (hasSessionDrills ? 'Begin Training' : 'Create Session'),
          onPressed: hasSessionDrills ? () {
            if (!appState.sessionInProgress) {
              appState.startSession();
            }
            
            final nextDrill = appState.getNextIncompleteDrill();
            if (nextDrill != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DrillFollowAlongView(
                    editableDrill: nextDrill,
                    onDrillCompleted: () {
                      appState.updateDrillProgress(
                        nextDrill.drill.id,
                        isCompleted: true,
                      );
                    },
                    onSessionCompleted: () {
                      appState.completeSession();
                      _showSessionComplete();
                    },
                  ),
                ),
              );
            }
          } : () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SessionGeneratorEditorPage(),
              ),
            );
          },
          color: hasSessionDrills ? AppTheme.buttonPrimary : AppTheme.buttonDisabledGray,
          backColor: hasSessionDrills ? AppTheme.primaryDarkYellow : AppTheme.buttonDisabledDarkGray,
          textColor: AppTheme.textOnPrimary,
          height: 50, // Reduced from 56 to 50
          textSize: 15, // Reduced from 25 to 16
          disabled: !hasSessionDrills,
        ),
      ),
    );
  }
  
  // Drill path with circles and trophy
  Widget _buildDrillPath(AppStateService appState) {
    final editableSessionDrills = appState.editableSessionDrills;
    final hasSessionDrills = editableSessionDrills.isNotEmpty;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Drill circles
        ...editableSessionDrills.asMap().entries.map((entry) {
          final index = entry.key;
          final editableDrill = entry.value;
          final nextIncompleteDrill = appState.getNextIncompleteDrill();
          final isActive = nextIncompleteDrill?.drill.id == editableDrill.drill.id;
          
          return Column(
            children: [
              _DrillCircle(
                editableDrill: editableDrill,
                isActive: isActive,
                isCompleted: editableDrill.isCompleted,
                onTap: () => _openFollowAlong(editableDrill, appState),
              ),
              if (index < editableSessionDrills.length - 1)
                const SizedBox(height: 24),
            ],
          );
        }).toList(),
        
        // Trophy at the end (only show if there are drills)
        if (hasSessionDrills) ...[
          const SizedBox(height: 32),
          _TrophyWidget(
            isUnlocked: appState.isSessionComplete,
            isAlreadyCompleted: appState.currentSessionCompleted, // ✅ NEW: Pass completion state
            onTap: () {
              if (appState.currentSessionCompleted) {
                // ✅ Session already completed, just show completion view
                _showSessionComplete();
              } else if (appState.isSessionComplete) {
                // ✅ Session can be completed now
                appState.completeSession();
                _showSessionComplete();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Complete all drills to unlock the trophy!')),
                );
              }
            },
          ),
        ],
      ],
    );
  }

  // Open follow-along view instead of edit drill view
  void _openFollowAlong(EditableDrillModel editableDrill, AppStateService appState) {
    final nextIncompleteDrill = appState.getNextIncompleteDrill();
    
    // Only allow follow-along for the current active drill
    if (nextIncompleteDrill?.drill.id == editableDrill.drill.id || editableDrill.isCompleted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DrillFollowAlongView(
            editableDrill: editableDrill,
            onDrillCompleted: () {
              // Update progress in app state
              appState.updateDrillProgress(
                editableDrill.drill.id,
                isCompleted: true,
              );
            },
            onSessionCompleted: () {
              // Handle session completion
              appState.completeSession();
              _showSessionComplete();
            },
          ),
        ),
      );
    } else {
      // Show edit drill view for inactive drills
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EditDrillView(
            editableDrill: editableDrill,
            onSave: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${editableDrill.drill.title} updated successfully!')),
              );
            },
          ),
        ),
      );
    }
  }

  void _showSessionComplete() {
    final appState = Provider.of<AppStateService>(context, listen: false);
    
    // ✅ FIXED: Use actual count without adding extra increment
    final sessionsToday = appState.sessionsCompletedToday;
    final isFirstSessionOfDay = sessionsToday == 1; // First session if count is exactly 1
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionCompletionView(
          currentStreak: appState.currentStreak, // Use actual streak from AppStateService
          completedDrills: appState.editableSessionDrills.where((drill) => drill.isCompleted).length,
          totalDrills: appState.editableSessionDrills.length,
          isFirstSessionOfDay: isFirstSessionOfDay,
          sessionsCompletedToday: sessionsToday, // ✅ Use actual count, not incremented
          onViewProgress: () {
            // Navigate to progress tab (index 1)
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const MainTabView(initialIndex: 1),
              ),
              (route) => false,
            );
          },
          onBackToHome: () {
            // Navigate back to home tab (index 0)
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const MainTabView(initialIndex: 0),
              ),
              (route) => false,
            );
          },
        ),
      ),
    );
  }

  // Status message based on drill count
  Widget _buildStatusMessage(AppStateService appState) {
    final editableSessionDrills = appState.editableSessionDrills;
    final hasSessionDrills = editableSessionDrills.isNotEmpty;
    
    String message;
    if (!hasSessionDrills) {
      message = "Click on the soccer bag to add drills to your session!";
    } else if (appState.currentSessionCompleted) {
      // ✅ UPDATED: Message for already completed session
      message = "Session complete! Click the trophy to view your progress.";
    } else if (appState.isSessionComplete) {
      message = "Well done! Click on the trophy to claim your prize.";
    } else {
      final incompleteDrills = editableSessionDrills.where((drill) => !drill.isCompleted).length;
      message = "You have $incompleteDrills drill${incompleteDrills == 1 ? '' : 's'} to complete.";
    }

    return Column(
      children: [
        // Main bubble
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.speechBubbleBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Speech bubble tail pointing down to Bravo
        Container(
          margin: const EdgeInsets.only(left: 15),
          child: ClipPath(
            clipper: _TriangleClipper(),
            child: Container(
              width: 16,
              height: 8,
              color: AppTheme.speechBubbleBackground,
            ),
          ),
        ),
      ],
    );
  }
}

// Drill circle with skill icon and color
class _DrillCircle extends StatelessWidget {
  final EditableDrillModel editableDrill;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback onTap;

  const _DrillCircle({
    required this.editableDrill,
    required this.isActive,
    required this.isCompleted,
    required this.onTap,
  });

  // Build the drill circle
  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color iconColor;
    Widget iconWidget;
    
    if (isCompleted) {
      backgroundColor = AppTheme.success;
      iconColor = AppTheme.white;
      iconWidget = Icon(
        Icons.check,
        color: iconColor,
        size: 36,
      );
    } else if (isActive) {
      backgroundColor = AppTheme.white;
      iconColor = AppTheme.getSkillColor(editableDrill.drill.skill);
      iconWidget = _buildDrillIcon();
    } else {
      backgroundColor = AppTheme.buttonDisabledGray;
      iconColor = AppTheme.primaryGray;
      iconWidget = _buildDrillIcon(disabled: true);
    }

    // Return the drill circle with progress ring
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress ring (only show if there's progress or completed)
          if (editableDrill.progress > 0 || isCompleted)
            SizedBox(
              width: 90, // Increased from 80
              height: 90, // Increased from 80
              child: CircularProgressIndicator(
                value: editableDrill.progress,
                strokeWidth: 6,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? AppTheme.success : AppTheme.buttonPrimary,
                ),
              ),
            ),
          
          // Main drill circle
          Container(
            width: 80, // Increased from 70
            height: 80, // Increased from 70
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              border: isActive ? Border.all(color: AppTheme.getSkillColor(editableDrill.drill.skill), width: 3) : null,
              boxShadow: [
                if (isActive || isCompleted)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Center(
              child: iconWidget,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrillIcon({bool disabled = false}) {
    final skill = editableDrill.drill.skill;
    final iconColor = disabled ? AppTheme.primaryGray : AppTheme.getSkillColor(skill);
    
    final iconWidget = Image.asset(
      _getSkillIconPath(skill),
      width: 40,
      height: 40,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to generic icon if image fails to load
        return Icon(
          _getSkillIconFallback(skill),
          color: iconColor,
          size: 28,
        );
      },
    );
    
    // Wrap in Opacity for disabled state instead of using color tinting
    return disabled 
      ? Opacity(
          opacity: 0.4,
          child: iconWidget,
        )
      : iconWidget;
  }

  String _getSkillIconPath(String skill) {
    switch (skill.toLowerCase()) {
      case 'passing':
        return 'assets/drill-icons/Player_Passing.png';
      case 'shooting':
        return 'assets/drill-icons/Player_Shooting.png';
      case 'dribbling':
        return 'assets/drill-icons/Player_Dribbling.png';
      case 'first touch':
        return 'assets/drill-icons/Player_First_Touch.png';
      case 'defending':
        return 'assets/drill-icons/Player_Dribbling.png'; // Use dribbling as fallback for defending
      case 'fitness':
        return 'assets/drill-icons/Player_Dribbling.png'; // Use dribbling as fallback for fitness
      default:
        return 'assets/drill-icons/Player_Dribbling.png'; // Fallback to dribbling icon
    }
  }

  IconData _getSkillIconFallback(String skill) {
    switch (skill.toLowerCase()) {
      case 'passing':
        return Icons.sports_soccer;
      case 'shooting':
        return Icons.sports_basketball;
      case 'dribbling':
        return Icons.directions_run;
      case 'first touch':
        return Icons.touch_app;
      case 'defending':
        return Icons.shield;
      case 'fitness':
        return Icons.fitness_center;
      default:
        return Icons.help_outline;
    }
  }
}

// Trophy widget at the end of the drill path
class _TrophyWidget extends StatelessWidget {
  final bool isUnlocked;
  final bool isAlreadyCompleted;
  final VoidCallback onTap;

  const _TrophyWidget({
    required this.isUnlocked,
    required this.isAlreadyCompleted,
    required this.onTap,
  });

  // Build the trophy widget
  @override
  Widget build(BuildContext context) {
    // Determine trophy color based on state
    Color backgroundColor;
    Color iconColor;
    
    if (isAlreadyCompleted || isUnlocked) {
      // Completed or can be completed - bright yellow trophy
      backgroundColor = AppTheme.primaryYellow;
      iconColor = AppTheme.white;
    } else {
      // Locked - gray trophy
      backgroundColor = AppTheme.buttonDisabledGray;
      iconColor = AppTheme.primaryGray;
    }

    // Return the trophy widget
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.black.withOpacity(0.2),
              blurRadius: AppTheme.elevationHigh,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.emoji_events,
          size: 48,
          color: iconColor,
        ),
      ),
    );
  }
}

// Custom clipper for the speech bubble tail
class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width / 2, size.height); // Bottom point
    path.lineTo(0, 0); // Top left
    path.lineTo(size.width, 0); // Top right
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
} 