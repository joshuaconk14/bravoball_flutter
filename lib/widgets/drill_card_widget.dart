import 'package:flutter/material.dart';
import '../models/drill_model.dart';
import '../constants/app_theme.dart'; // Fixed import path for AppTheme
import '../utils/haptic_utils.dart';
import '../utils/skill_utils.dart'; // ✅ ADDED: Import centralized skill utilities
import 'package:provider/provider.dart'; // Added for Provider
import '../services/app_state_service.dart'; // Added for AppStateService
import 'save_to_collection_dialog.dart'; // ✅ ADDED: Import reusable dialog
import 'package:flutter/foundation.dart'; // Added for kDebugMode
import '../features/create_drill/edit_custom_drill_sheet.dart'; // ✅ ADDED: Import edit custom drill sheet

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
    // ✅ UPDATED: Use Consumer to get latest drill data for reactive updates
    return Consumer<AppStateService>(
      builder: (context, appState, child) {
        // Get the latest version of the drill from app state
        final currentDrill = appState.getUpdatedDrill(drill);
        
        return _buildCardContent(context, currentDrill);
      },
    );
  }
  
  Widget _buildCardContent(BuildContext context, DrillModel currentDrill) {
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
                // ✅ IMPROVED: Drag area includes both handle and soccer player image
                if (isDraggable)
                  ReorderableDragStartListener(
                    index: 0, // This will be overridden by the ReorderableListView
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Drag handle
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(right: 8),
                          child: Icon(
                            Icons.drag_handle,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                        ),
                        // Skill indicator - now also draggable
                        Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.getSkillColor(currentDrill.skill).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.getSkillColor(currentDrill.skill).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Image.asset(
                            _getSkillIconPath(currentDrill.skill),
                            width: 40,
                            height: 40,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback to generic icon if image fails to load
                              return Icon(
                                _getSkillIconFallback(currentDrill.skill),
                                color: AppTheme.getSkillColor(currentDrill.skill),
                                size: 24,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // Non-draggable version - just show the skill indicator
                  Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(4),
                    margin: const EdgeInsets.only(left: 8), // Match spacing when not draggable
                    decoration: BoxDecoration(
                      color: AppTheme.getSkillColor(currentDrill.skill).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.getSkillColor(currentDrill.skill).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Image.asset(
                      _getSkillIconPath(currentDrill.skill),
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to generic icon if image fails to load
                        return Icon(
                          _getSkillIconFallback(currentDrill.skill),
                          color: AppTheme.getSkillColor(currentDrill.skill),
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
                        currentDrill.title,
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
                        SkillUtils.formatSkillForDisplay(currentDrill.skill), // ✅ UPDATED: Use centralized skill formatting
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${sets ?? currentDrill.sets} sets • ${reps ?? currentDrill.reps} reps • ${duration ?? currentDrill.duration} min',
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
                          HapticUtils.lightImpact(); // Light haptic for like action
                          final appState = Provider.of<AppStateService>(context, listen: false);
                          final wasLiked = appState.isDrillLiked(currentDrill);
                          appState.toggleLikedDrill(currentDrill);
                          
                          // Show feedback message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(wasLiked 
                                ? 'Removed ${currentDrill.title} from liked drills' 
                                : 'Added ${currentDrill.title} to liked drills'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else if (value == 'session') {
                          HapticUtils.mediumImpact(); // Medium haptic for session action
                          final appState = Provider.of<AppStateService>(context, listen: false);
                          final wasInSession = appState.isDrillInSession(currentDrill);
                          
                          if (wasInSession) {
                            appState.removeDrillFromSession(currentDrill);
                            // Show feedback message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Removed ${currentDrill.title} from session'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            final success = appState.addDrillToSession(currentDrill);
                            if (success) {
                              // Show feedback message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added ${currentDrill.title} to session'),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              // Show limit warning message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Session limit reached! You can only add up to 10 drills to a session.'),
                                  duration: const Duration(seconds: 3),
                                  backgroundColor: Colors.orange,
                                  action: SnackBarAction(
                                    label: 'OK',
                                    textColor: Colors.white,
                                    onPressed: () {},
                                  ),
                                ),
                              );
                            }
                          }
                        } else if (value == 'add_to_group') {
                          HapticUtils.lightImpact(); // Light haptic for collection action
                          final appState = Provider.of<AppStateService>(context, listen: false);
                          SaveToCollectionDialog.show(context, currentDrill);
                        } else if (value == 'edit_drill' && currentDrill.isCustom) {
                          HapticUtils.lightImpact(); // Light haptic for edit action
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditCustomDrillSheet(drill: currentDrill),
                            ),
                          );
                        }
                      },
                      itemBuilder: (context) {
                        final appState = Provider.of<AppStateService>(context, listen: false);
                        final isLiked = appState.isDrillLiked(currentDrill);
                        final isInSession = appState.isDrillInSession(currentDrill);
                        
                        List<PopupMenuItem<String>> menuItems = [
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
                          PopupMenuItem(
                            value: 'add_to_group',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.folder_outlined,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text('Add to Collection'),
                              ],
                            ),
                          ),
                        ];

                        // ✅ ADDED: Add "Edit Drill" option for custom drills only
                        if (currentDrill.isCustom) {
                          menuItems.add(
                            PopupMenuItem(
                              value: 'edit_drill',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Edit Drill'),
                                ],
                              ),
                            ),
                          );
                        }

                        return menuItems;
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

    // ✅ IMPROVED: No longer wrap entire card - only drag handle is draggable
    return cardWithIcons;
  }

  String _getSkillIconPath(String skill) {
    if (kDebugMode) {
      print('🔍 [ICON_DEBUG] Skill: "$skill" (length: ${skill.length})');
      print('🔍 [ICON_DEBUG] Skill.toLowerCase(): "${skill.toLowerCase()}"');
    }
    
    // Normalize the skill name for better matching
    final normalizedSkill = skill.toLowerCase().replaceAll('_', ' ').trim();
    
    if (kDebugMode) {
      print('🔍 [ICON_DEBUG] Normalized skill: "$normalizedSkill"');
    }
    
    switch (normalizedSkill) {
      case 'passing':
        if (kDebugMode) print('🔍 [ICON_DEBUG] Matched: passing');
        return 'assets/drill-icons/Player_Passing.png';
      case 'shooting':
        if (kDebugMode) print('🔍 [ICON_DEBUG] Matched: shooting');
        return 'assets/drill-icons/Player_Shooting.png';
      case 'dribbling':
        if (kDebugMode) print('🔍 [ICON_DEBUG] Matched: dribbling');
        return 'assets/drill-icons/Player_Dribbling.png';
      case 'first touch':
      case 'firsttouch':
        if (kDebugMode) print('🔍 [ICON_DEBUG] Matched: first touch');
        return 'assets/drill-icons/Player_First_Touch.png';
      case 'defending':
        if (kDebugMode) print('🔍 [ICON_DEBUG] Matched: defending');
        return 'assets/drill-icons/Player_Defending.png';
      case 'goalkeeping':
        if (kDebugMode) print('🔍 [ICON_DEBUG] Matched: goalkeeping');
        return 'assets/drill-icons/Player_Goalkeeping.png';
      case 'fitness':
        if (kDebugMode) print('🔍 [ICON_DEBUG] Matched: fitness');
        return 'assets/drill-icons/Player_Fitness.png';
      default:
        if (kDebugMode) print('🔍 [ICON_DEBUG] No match found, using dribbling fallback');
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
      case 'goalkeeping':
        return Icons.sports_handball;
      case 'fitness':
        return Icons.sports;
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
    // ✅ UPDATED: Use Consumer to get latest drill data for reactive updates
    return Consumer<AppStateService>(
      builder: (context, appState, child) {
        // Get the latest version of the drill from app state
        final currentDrill = appState.getUpdatedDrill(drill);
        
        return _buildCardContent(context, currentDrill);
      },
    );
  }
  
  Widget _buildCardContent(BuildContext context, DrillModel currentDrill) {
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
                    color: AppTheme.getSkillColor(currentDrill.skill).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.getSkillColor(currentDrill.skill).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Image.asset(
                    _getSkillIconPath(currentDrill.skill),
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to generic icon if image fails to load
                      return Icon(
                        _getSkillIconFallback(currentDrill.skill),
                        color: AppTheme.getSkillColor(currentDrill.skill),
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
                        currentDrill.title,
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
                        SkillUtils.formatSkillForDisplay(currentDrill.skill), // ✅ UPDATED: Use centralized skill formatting
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${currentDrill.sets} sets • ${currentDrill.reps} reps • ${currentDrill.duration} min',
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
        return Icons.sports;
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