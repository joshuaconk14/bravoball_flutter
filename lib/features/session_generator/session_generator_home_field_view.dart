import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';
import '../../widgets/bravo_button.dart';
import '../../models/drill_model.dart';
import '../../services/app_state_service.dart';
import '../../constants/app_theme.dart';
import 'session_generator_editor_page.dart';
import 'edit_drill_view.dart';

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
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.backgroundPrimary,
                child: Icon(Icons.person, color: AppTheme.secondaryBlue, size: 28),
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
              
              Row(
                children: [
                  Icon(Icons.local_fire_department, color: AppTheme.secondaryOrange, size: 24),
                  const SizedBox(width: 4),
                  Text(
                    '3', // TODO: Replace with actual streak
                    style: TextStyle(
                      fontFamily: AppTheme.fontPoppins,
                      fontSize: 20,
                      color: AppTheme.secondaryOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
            top: 100, // Positioned right above Bravo (who is at 180)
            left: 60,  // More padding from edges to make it more compact
            right: 180, // More padding from edges to make it more compact
            child: _buildSpeechBubble(_getStatusMessage(appState)),
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
    return Padding(
      padding: const EdgeInsets.only(
        left: 32,
        right: 32,
        bottom: 25, // Increased bottom padding to push drill circles further down
      ),
      child: BravoButton(
        text: appState.hasSessionDrills ? 'Begin Training' : 'Create Session',
        onPressed: appState.hasSessionDrills ? () {
          // TODO: Start training session
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Starting training session...')),
          );
        } : null,
        color: appState.hasSessionDrills ? AppTheme.buttonPrimary : AppTheme.buttonDisabled,
        textColor: AppTheme.textOnPrimary,
        height: 56,
        textSize: 25,
        disabled: !appState.hasSessionDrills,
      ),
    );
  }
  
  // Drill path with circles and trophy
  Widget _buildDrillPath(AppStateService appState) {
    final sessionDrills = appState.sessionDrills;
    final hasSessionDrills = sessionDrills.isNotEmpty;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Drill circles
        ...sessionDrills.asMap().entries.map((entry) {
          final index = entry.key;
          final drill = entry.value;
          return Column(
            children: [
              _DrillCircle(
                drill: drill,
                isActive: index == 0, // First drill is active
                isCompleted: false, // TODO: Track completion state
                onTap: () => _openEditDrill(drill),
              ),
              if (index < sessionDrills.length - 1)
                const SizedBox(height: 24),
            ],
          );
        }).toList(),
        
        // Trophy at the end (only show if there are drills)
        if (hasSessionDrills) ...[
          const SizedBox(height: 32),
          _TrophyWidget(
            isUnlocked: false, // TODO: Check if session is complete
            onTap: () {
              // TODO: Show completion dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Complete all drills to unlock the trophy!')),
              );
            },
          ),
        ],
      ],
    );
  }

  // Open edit drill view
  void _openEditDrill(DrillModel drill) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditDrillView(
          drill: drill,
          onSave: () {
            // Provide feedback when drill is updated
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${drill.title} updated successfully!')),
            );
          },
        ),
      ),
    );
  }

  // Status message based on drill count
  String _getStatusMessage(AppStateService appState) {
    final drillCount = appState.sessionDrillCount;
    
    if (drillCount == 0) {
      return 'Click on the soccer bag to\nadd drills to your session!';
    } else if (drillCount == 1) {
      return 'You have 1 drill to complete.';
    } else {
      return 'You have $drillCount drills to complete.';
    }
  }

  // Build a speech bubble with a tail pointing to Bravo
  Widget _buildSpeechBubble(String text) {
    return Column(
      children: [
        // Main bubble
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Reduced padding for more compact look
          decoration: BoxDecoration(
            color: AppTheme.speechBubbleBackground, // Use theme color
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge), // Use theme radius
            boxShadow: [
              BoxShadow(
                color: AppTheme.black.withOpacity(0.2),
                blurRadius: AppTheme.elevationHigh,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            text,
            style: TextStyle(
              fontFamily: AppTheme.fontPoppins,
              fontWeight: FontWeight.bold,
              fontSize: 13, // Smaller font size for compactness
              color: AppTheme.speechBubbleText, // Use theme color
            ),
            textAlign: TextAlign.center,
            maxLines: 2, // Limit to 2 lines to prevent overflow
            overflow: TextOverflow.ellipsis, // Handle overflow gracefully
          ),
        ),
        // Tail pointing down to Bravo
        Container(
          margin: const EdgeInsets.only(left: 15), // Adjusted offset for better alignment
          child: ClipPath(
            clipper: _TriangleClipper(),
            child: Container(
              width: 16, // Slightly smaller tail
              height: 8,  // Slightly smaller tail
              color: AppTheme.speechBubbleBackground, // Use theme color
            ),
          ),
        ),
      ],
    );
  }
}

// Drill circle with skill icon and color
class _DrillCircle extends StatelessWidget {
  final DrillModel drill;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback onTap;

  const _DrillCircle({
    required this.drill,
    required this.isActive,
    required this.isCompleted,
    required this.onTap,
  });

  // Build the drill circle
  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color iconColor;
    IconData iconData;
    
    if (isCompleted) {
      backgroundColor = AppTheme.success;
      iconColor = AppTheme.white;
      iconData = Icons.check;
    } else if (isActive) {
      backgroundColor = AppTheme.white;
      iconColor = AppTheme.getSkillColor(drill.skill);
      iconData = _getSkillIcon(drill.skill);
    } else {
      backgroundColor = AppTheme.buttonDisabled;
      iconColor = AppTheme.primaryGray;
      iconData = _getSkillIcon(drill.skill);
    }

    // Return the drill circle
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: isActive ? Border.all(color: AppTheme.getSkillColor(drill.skill), width: 3) : null,
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
          child: Icon(
            iconData,
            color: iconColor,
            size: 32,
          ),
        ),
      ),
    );
  }

  IconData _getSkillIcon(String skill) {
    // Always return the running soccer player icon for all drills
    return Icons.directions_run;
  }
}

// Trophy widget at the end of the drill path
class _TrophyWidget extends StatelessWidget {
  final bool isUnlocked;
  final VoidCallback onTap;

  const _TrophyWidget({
    required this.isUnlocked,
    required this.onTap,
  });

  // Build the trophy widget
  @override
  Widget build(BuildContext context) {
    // Return the trophy widget
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isUnlocked ? AppTheme.primaryYellow : AppTheme.buttonDisabled,
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
          color: isUnlocked ? AppTheme.white : AppTheme.primaryGray,
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