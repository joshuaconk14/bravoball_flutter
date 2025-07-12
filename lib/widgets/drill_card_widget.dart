import 'package:flutter/material.dart';
import '../models/drill_model.dart';
import '../constants/app_theme.dart'; // Fixed import path for AppTheme
import '../utils/haptic_utils.dart';
import 'package:provider/provider.dart'; // Added for Provider
import '../services/app_state_service.dart'; // Added for AppStateService

class DraggableDrillCard extends StatelessWidget {
  final DrillModel drill;
  final int? sets;
  final int? reps;
  final int? duration;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isDraggable;
  final bool showOverlayIcons;

  const DraggableDrillCard({
    Key? key,
    required this.drill,
    this.sets,
    this.reps,
    this.duration,
    this.onTap,
    this.onDelete,
    this.isDraggable = false,
    this.showOverlayIcons = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (onTap != null) {
              HapticUtils.mediumImpact(); // Medium haptic for drill interaction
              onTap!();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Drag handle (only show if draggable)
                if (isDraggable)
                  Container(
                    padding: const EdgeInsets.all(4),
                    margin: const EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.drag_handle,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  ),
                // Skill indicator - replaced with custom icon
                Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.getSkillColor(drill.skill).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.getSkillColor(drill.skill).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Image.asset(
                    _getSkillIconPath(drill.skill),
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to generic icon if image fails to load
                      return Icon(
                        _getSkillIconFallback(drill.skill),
                        color: AppTheme.getSkillColor(drill.skill),
                        size: 24,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Drill content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drill.title,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        drill.skill,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${sets ?? drill.sets} sets • ${reps ?? drill.reps} reps • ${duration ?? drill.duration} min',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onDelete != null)
                      IconButton(
                        onPressed: () {
                          if (onDelete != null) {
                            HapticUtils.lightImpact(); // Light haptic for delete action
                            onDelete!();
                          }
                        },
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade400,
                          size: 20,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    // Replace chevron with ellipsis button
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.grey.shade600, size: 20),
                      onSelected: (value) async {
                        if (value == 'like') {
                          final appState = Provider.of<AppStateService>(context, listen: false);
                          appState.toggleLikedDrill(drill);
                        } else if (value == 'session') {
                          final appState = Provider.of<AppStateService>(context, listen: false);
                          if (appState.isDrillInSession(drill)) {
                            appState.removeDrillFromSession(drill);
                          } else {
                            appState.addDrillToSession(drill);
                          }
                        }
                      },
                      itemBuilder: (context) {
                        final appState = Provider.of<AppStateService>(context, listen: false);
                        final isLiked = appState.isDrillLiked(drill);
                        final isInSession = appState.isDrillInSession(drill);
                        return [
                          PopupMenuItem(
                            value: 'like',
                            child: Row(
                              children: [
                                Icon(
                                  isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: isLiked ? Colors.red : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(isLiked ? 'Unlike' : 'Like'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'session',
                            child: Row(
                              children: [
                                Icon(
                                  isInSession ? Icons.fitness_center : Icons.add_circle_outline,
                                  color: isInSession ? Colors.blue : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(isInSession ? 'Remove from Session' : 'Add to Session'),
                              ],
                            ),
                          ),
                        ];
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Add like and session icons in the top right corner of the card
    final cardWithIcons = showOverlayIcons
        ? Stack(
            children: [
              cardContent,
              Positioned(
                top: 8,
                right: 8,
                child: Builder(
                  builder: (context) {
                    final appState = Provider.of<AppStateService>(context, listen: false);
                    final isLiked = appState.isDrillLiked(drill);
                    final isInSession = appState.isDrillInSession(drill);
                    if (!isLiked && !isInSession) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isInSession)
                            Icon(Icons.fitness_center, color: Colors.blue, size: 18),
                          if (isLiked)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(Icons.favorite, color: Colors.red, size: 18),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          )
        : cardContent;

    // If draggable, wrap with ReorderableDragStartListener
    if (isDraggable) {
      return ReorderableDragStartListener(
        index: 0, // This will be overridden by the ReorderableListView
        child: cardWithIcons,
      );
    }

    return cardWithIcons;
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
        return Icons.help_outline; // Fallback icon
    }
  }
}

class SimpleDrillCard extends StatelessWidget {
  final DrillModel drill;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  const SimpleDrillCard({
    Key? key,
    required this.drill,
    this.onTap,
    this.onAdd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (onTap != null) {
              HapticUtils.mediumImpact(); // Medium haptic for drill interaction
              onTap!();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Skill indicator - replaced with custom icon
                Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.getSkillColor(drill.skill).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.getSkillColor(drill.skill).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Image.asset(
                    _getSkillIconPath(drill.skill),
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to generic icon if image fails to load
                      return Icon(
                        _getSkillIconFallback(drill.skill),
                        color: AppTheme.getSkillColor(drill.skill),
                        size: 24,
                      );
                    },
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Drill content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drill.title,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        drill.skill,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${drill.sets} sets • ${drill.reps} reps • ${drill.duration} min',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Add button
                if (onAdd != null)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    child: ElevatedButton(
                      onPressed: () {
                        if (onAdd != null) {
                          HapticUtils.mediumImpact(); // Medium haptic for add action
                          onAdd!();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF9CC53),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Add',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Arrow icon
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
        return Icons.help_outline; // Fallback icon
    }
  }
}

class DrillDropTarget extends StatelessWidget {
  final VoidCallback onAccept;
  final Widget child;

  const DrillDropTarget({
    Key? key,
    required this.onAccept,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DragTarget<DrillModel>(
      onAccept: (drill) => onAccept(),
      builder: (context, candidateData, rejectedData) {
        return Container(
          decoration: BoxDecoration(
            border: candidateData.isNotEmpty
                ? Border.all(color: Colors.blue, width: 2)
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        );
      },
    );
  }
} 