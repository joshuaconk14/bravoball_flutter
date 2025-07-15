import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';
import 'dart:ui' as ui show Gradient;
import 'package:flutter/painting.dart' as painting;
import '../../widgets/bravo_button.dart';
import '../../widgets/guest_account_overlay.dart'; // ✅ NEW: Import reusable guest overlay
import '../../widgets/circular_drill_button.dart'; // ✅ NEW: Import circular drill button
import '../../widgets/warning_dialog.dart'; // ✅ NEW: Import reusable warning dialog
import '../../models/editable_drill_model.dart';
import '../../services/app_state_service.dart';
import '../../services/audio_service.dart';
import '../../constants/app_theme.dart';
import '../../utils/haptic_utils.dart';
import 'session_generator_editor_page.dart';
import 'edit_drill_view.dart';
import 'drill_follow_along_view.dart';
import 'session_completion_view.dart';
import '../../views/main_tab_view.dart';
import 'package:flutter/foundation.dart'; // Added for kDebugMode
import '../mental_training/mental_training_setup_view.dart'; // Added for MentalTrainingSetupView

class SessionGeneratorHomeFieldView extends StatefulWidget {
  const SessionGeneratorHomeFieldView({Key? key}) : super(key: key);

  @override
  State<SessionGeneratorHomeFieldView> createState() => _SessionGeneratorHomeFieldViewState();
}

class _SessionGeneratorHomeFieldViewState extends State<SessionGeneratorHomeFieldView> {
  // ✅ NEW: Calculate dynamic spacing between drill buttons based on their sizes
  double _getSpacingForButton(
    EditableDrillModel currentDrill, 
    EditableDrillModel? nextDrill, 
    bool sessionComplete, 
    EditableDrillModel? nextIncompleteDrill,
  ) {
    // Determine current button size
    final bool isCurrentActive = !sessionComplete && nextIncompleteDrill?.drill.id == currentDrill.drill.id;
    final double currentButtonSize = isCurrentActive ? 90 : (currentDrill.isCompleted ? 70 : 80); // ✅ UPDATED: Use new larger sizes
    
    // Determine next button size
    double nextButtonSize = 80; // ✅ UPDATED: Updated default size
    if (nextDrill != null) {
      final bool isNextActive = !sessionComplete && nextIncompleteDrill?.drill.id == nextDrill.drill.id;
      nextButtonSize = isNextActive ? 90 : (nextDrill.isCompleted ? 70 : 80); // ✅ UPDATED: Use new larger sizes
    }
    
    // Base spacing - reduced for closer spacing
    double baseSpacing = 18; // ✅ UPDATED: Reduced from 24 to 20
    
    // Adjust spacing based on button sizes to create visually even spacing
    // Larger buttons need more space to look balanced
    if (currentButtonSize == 90 || nextButtonSize == 90) { // ✅ UPDATED: Use new active size
      baseSpacing = 24; // ✅ UPDATED: Reduced from 30 to 24 for closer spacing
    } else if (currentButtonSize == 70 && nextButtonSize == 70) { // ✅ UPDATED: Use new completed size
      baseSpacing = 18; // ✅ UPDATED: Reduced from 22 to 18 for closer spacing
    } else if ((currentButtonSize == 70 && nextButtonSize == 80) || 
               (currentButtonSize == 80 && nextButtonSize == 70)) { // ✅ UPDATED: Use new sizes
      baseSpacing = 18; // ✅ UPDATED: Reduced from 24 to 20 for closer spacing
    }
    
    return baseSpacing;
  }

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
                  HapticUtils.heavyImpact(); // Heavy haptic for major navigation
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
                  HapticUtils.heavyImpact(); // Heavy haptic for major navigation  
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
            right: 190, // Give enough space
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
                // ✅ NEW: Check for session progress before allowing access
                if (appState.hasSessionProgress && !appState.isSessionComplete) {
                  HapticUtils.mediumImpact();
                  _showSessionProgressWarning(context, appState);
                } else {
                  // ✅ REMOVED: Trophy restriction - users can always access backpack
                  HapticUtils.mediumImpact(); // Medium haptic for drill editor access
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SessionGeneratorEditorPage(),
                    ),
                  );
                }
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
          
          // Mental Training Alternative - positioned directly above backpack as a glowing option
          Positioned(
            top: 122, // Positioned directly above the backpack
            right: screenWidth * 0.28, // Same horizontal position as backpack
            child: GestureDetector(
              onTap: () {
                HapticUtils.mediumImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MentalTrainingSetupView(),
                  ),
                );
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: painting.RadialGradient(
                    colors: [
                      AppTheme.primaryYellow,
                      AppTheme.primaryYellow.withOpacity(0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryYellow.withOpacity(0.6),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: AppTheme.primaryYellow.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.psychology_rounded,
                  size: 28,
                  color: AppTheme.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Drill path with circles and trophy
  Widget _buildDrillPath(AppStateService appState) {
    final editableSessionDrills = appState.editableSessionDrills;
    final hasSessionDrills = editableSessionDrills.isNotEmpty;
    final sessionComplete = appState.isSessionComplete;
    final nextIncompleteDrill = appState.getNextIncompleteDrill();
    
    // ✅ NEW: Show placeholder when no drills exist
    if (!hasSessionDrills) {
      return _buildEmptyStatePlaceholder();
    }
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Drill circles
        ...editableSessionDrills.asMap().entries.map((entry) {
          final index = entry.key;
          final editableDrill = entry.value;
          final isActive = !sessionComplete && nextIncompleteDrill?.drill.id == editableDrill.drill.id;
          
          // ✅ UPDATED: Dynamic sizing based on drill state
          final double buttonSize;
          final double iconSize;
          
          if (isActive) {
            // Active drill - make it bigger to stand out
            buttonSize = 90; // ✅ UPDATED: Increased from 80 to 90
            iconSize = 45; // ✅ UPDATED: Increased from 40 to 45
          } else if (editableDrill.isCompleted) {
            // Completed drill - make it smaller and less prominent
            buttonSize = 70; // ✅ UPDATED: Increased from 60 to 70
            iconSize = 35; // ✅ UPDATED: Increased from 30 to 35
          } else {
            // Incomplete drill - normal size
            buttonSize = 80; // ✅ UPDATED: Increased from 70 to 80
            iconSize = 40; // ✅ UPDATED: Increased from 35 to 40
          }
          
          return Column(
            children: [
              CircularDrillButton(
                skill: editableDrill.drill.skill,
                isActive: isActive,
                isCompleted: editableDrill.isCompleted,
                disabled: false,
                size: buttonSize,
                iconSize: iconSize,
                showProgress: editableDrill.progress > 0 || editableDrill.isCompleted,
                progress: editableDrill.progress,
                onPressed: () => _openFollowAlong(editableDrill, appState),
              ),
              if (index < editableSessionDrills.length - 1)
                SizedBox(
                  height: _getSpacingForButton(
                    editableDrill, 
                    index < editableSessionDrills.length - 1 ? editableSessionDrills[index + 1] : null,
                    sessionComplete,
                    nextIncompleteDrill,
                  ),
                ),
            ],
          );
        }).toList(),
        
        // Trophy at the end (only show if there are drills)
        if (hasSessionDrills) ...[
          const SizedBox(height: 32),
          _TrophyWidget(
            isUnlocked: appState.isSessionComplete,
            isAlreadyCompleted: appState.currentSessionCompleted,
            isLarge: sessionComplete && !appState.currentSessionCompleted,
            isGlowing: sessionComplete && !appState.currentSessionCompleted,
            onTap: () async {
              if (kDebugMode) {
                print('🏆 Trophy tapped!');
                print('  - isSessionComplete:  [38;5;10m${appState.isSessionComplete} [0m');
                print('  - currentSessionCompleted:  [38;5;10m${appState.currentSessionCompleted} [0m');
                print('  - isGuestMode: ${appState.isGuestMode}');
                print('  - Total drills: ${appState.editableSessionDrills.length}');
                print('  - Fully completed drills: ${appState.editableSessionDrills.where((d) => d.isFullyCompleted).length}');
                print('  - Completed drills: ${appState.editableSessionDrills.where((d) => d.isCompleted).length}');
                for (int i = 0; i < appState.editableSessionDrills.length; i++) {
                  final drill = appState.editableSessionDrills[i];
                  print('    Drill $i: ${drill.drill.title} - setsDone: ${drill.setsDone}/${drill.totalSets}, isCompleted: ${drill.isCompleted}, isFullyCompleted: ${drill.isFullyCompleted}');
                }
              }
              
              // ✅ NEW: Check if guest mode - show overlay instead of completion
              if (appState.isGuestMode && appState.isSessionComplete) {
                HapticUtils.mediumImpact();
                GuestAccountOverlay.show(
                  context: context,
                  title: 'Create an account to earn rewards',
                  description: 'Track your progress, earn achievements, and unlock all features by creating an account.',
                  themeColor: AppTheme.primaryYellow,
                  showDismissButton: true,
                );
                return;
              }
              
              if (appState.currentSessionCompleted) {
                HapticUtils.lightImpact();
                _showSessionComplete();
              } else if (appState.isSessionComplete) {
                HapticUtils.mediumImpact();
                // ✅ Play success sound for first-time session completion
                AudioService.playSuccess();
                await appState.completeSession();
                _showSessionComplete();
              } else {
                HapticUtils.lightImpact();
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

  // ✅ NEW: Build placeholder for when no drills exist
  Widget _buildEmptyStatePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        
        // Placeholder drill circles with dotted connecting lines
        ..._buildPlaceholderDrillsWithLines(),
        
        // Dotted line before trophy
        _buildDottedLine(),
        
        const SizedBox(height: 12),
        
        // Placeholder trophy
        _buildPlaceholderTrophy(),
        
        const SizedBox(height: 20),
      ],
    );
  }

  // ✅ NEW: Build placeholder drill circles with connecting dotted lines
  List<Widget> _buildPlaceholderDrillsWithLines() {
    final placeholderSkills = ['dribbling', 'passing', 'shooting'];
    final List<Widget> placeholders = [];
    
    for (int i = 0; i < placeholderSkills.length; i++) {
      // Add drill circle
      placeholders.add(
        Opacity(
          opacity: 0.3, // Make it very transparent
          child: CircularDrillButton(
            skill: placeholderSkills[i],
            isActive: false,
            isCompleted: false,
            disabled: true, // Make it non-interactive
            size: 80,
            iconSize: 40,
            showProgress: false,
            progress: 0.0,
            onPressed: () {}, // Empty function since it's disabled
          ),
        ),
      );
      
      // Add connecting dotted line (except after last drill)
      if (i < placeholderSkills.length - 1) {
        placeholders.add(_buildDottedLine());
      }
    }
    
    return placeholders;
  }

  // ✅ NEW: Build dotted connecting line
  Widget _buildDottedLine() {
    return Container(
      height: 24,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) => Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            color: AppTheme.primaryGray.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        )),
      ),
    );
  }

  // ✅ NEW: Build placeholder trophy (grayed out version of actual trophy)
  Widget _buildPlaceholderTrophy() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.buttonDisabledGray.withOpacity(0.5),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.primaryGray.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Icon(
        Icons.emoji_events,
        size: 48,
        color: AppTheme.primaryGray.withOpacity(0.4),
      ),
    );
  }

  // Open follow-along view instead of edit drill view
  void _openFollowAlong(EditableDrillModel editableDrill, AppStateService appState) {
    final nextIncompleteDrill = appState.getNextIncompleteDrill();
    
    // Only allow follow-along for the current active drill or already done drills
    if (nextIncompleteDrill?.drill.id == editableDrill.drill.id || editableDrill.isDone) {
      HapticUtils.mediumImpact(); // Medium haptic for drill interaction
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DrillFollowAlongView(
            editableDrill: editableDrill,
            onDrillCompleted: () {
            },
            onSessionCompleted: () async {
              // Handle session completion
              await appState.completeSession();
              _showSessionComplete();
            },
          ),
        ),
      );
    } else {
      // Show edit drill view for inactive drills
      HapticUtils.lightImpact(); // Light haptic for edit access
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
          completedDrills: appState.editableSessionDrills.where((drill) => drill.isFullyCompleted).length,
          totalDrills: appState.editableSessionDrills.length,
          isFirstSessionOfDay: isFirstSessionOfDay,
          sessionsCompletedToday: sessionsToday, // ✅ Use actual count, not incremented
          onViewProgress: () {
            appState.resetDrillProgressForNewSession();
            // Navigate to progress tab (index 1)
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const MainTabView(initialIndex: 1),
              ),
              (route) => false,
            );
          },
          onBackToHome: () {
            appState.resetDrillProgressForNewSession();
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

  // ✅ NEW: Show warning dialog when user tries to edit session with progress
  void _showSessionProgressWarning(BuildContext context, AppStateService appState) {
    final progressDrills = appState.editableSessionDrills.where((drill) => drill.setsDone > 0 || drill.isCompleted).length;
    final totalDrills = appState.editableSessionDrills.length;
    
    WarningDialog.showSessionProgress(
      context: context,
      progressDrills: progressDrills,
      totalDrills: totalDrills,
    ).then((result) {
      // Handle the dialog result
      if (result == true) {
        // User clicked continue - navigate to session editor
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const SessionGeneratorEditorPage(),
          ),
        );
      }
      // If result is false or null, user cancelled - do nothing
    });
  }

  // Status message based on drill count
  Widget _buildStatusMessage(AppStateService appState) {
    final editableSessionDrills = appState.editableSessionDrills;
    final hasSessionDrills = editableSessionDrills.isNotEmpty;
    
    String message;
    if (!hasSessionDrills) {
      message = "Try a drill session or mental training!";
    } else if (appState.currentSessionCompleted) {
      // Check if drills have been reset (all progress is 0)
      final allDrillsReset = editableSessionDrills.every((drill) => 
        drill.setsDone == 0 && !drill.isCompleted
      );
      
      if (allDrillsReset) {
        message = "Ready for another session! Or take a mental training break.";
      } else {
        message = "Session complete! Consider mental training for recovery.";
      }
    } else if (appState.isSessionComplete) {
      message = "Well done! Tap the trophy!";
    } else {
      final incompleteDrills = editableSessionDrills.where((drill) => !drill.isDone).length;
      message = "You have $incompleteDrills drill${incompleteDrills == 1 ? '' : 's'}! Or try mental training.";
    }

    return Column(
      children: [
        // Main bubble
        Container(
          constraints: const BoxConstraints(
            maxWidth: 260, // Increased from 180 for more space
            minWidth: 120,  // Ensure minimum width
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Slightly more vertical padding
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

// Trophy widget at the end of the drill path
class _TrophyWidget extends StatelessWidget {
  final bool isUnlocked;
  final bool isAlreadyCompleted;
  final bool isLarge;
  final bool isGlowing;
  final VoidCallback onTap;

  const _TrophyWidget({
    required this.isUnlocked,
    required this.isAlreadyCompleted,
    this.isLarge = false,
    this.isGlowing = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color iconColor;
    if (isAlreadyCompleted || isUnlocked) {
      backgroundColor = AppTheme.primaryYellow;
      iconColor = AppTheme.white;
    } else {
      backgroundColor = AppTheme.buttonDisabledGray;
      iconColor = AppTheme.primaryGray;
    }

    final double size = isLarge ? 110 : 80;
    final double iconSize = isLarge ? 64 : 48;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isGlowing)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.7, end: 1.0),
              duration: const Duration(seconds: 1),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Container(
                  width: size * value + 24,
                  height: size * value + 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryYellow.withOpacity(0.5),
                        blurRadius: 32 * value,
                        spreadRadius: 10 * value,
                      ),
                    ],
                  ),
                );
              },
              onEnd: () {},
            ),
          Container(
            width: size,
            height: size,
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
              size: iconSize,
              color: iconColor,
            ),
          ),
        ],
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