import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/drill_model.dart';
import '../../widgets/bravo_button.dart';
import '../../widgets/drill_video_player.dart';
import '../../constants/app_theme.dart';
import '../../utils/haptic_utils.dart';
import '../../services/app_state_service.dart';

class DrillDetailView extends StatelessWidget {
  final DrillModel drill;
  final VoidCallback? onAddToSession;
  final bool isInSession;

  const DrillDetailView({
    Key? key,
    required this.drill,
    this.onAddToSession,
    this.isInSession = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateService>(
      builder: (context, appState, child) {
        final isLiked = appState.isDrillLiked(drill);
        final isSavedInCollection = appState.isDrillSavedInAnyCollection(drill); // ✅ NEW: Check if saved
        
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                HapticUtils.lightImpact(); // Light haptic for navigation
                Navigator.pop(context);
              },
            ),
            title: Text(
              drill.title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 18,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            centerTitle: true,
            actions: [
              // Heart button for liking/unliking
              IconButton(
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : Colors.grey.shade600,
                ),
                onPressed: () {
                  HapticUtils.mediumImpact(); // Medium haptic for like action
                  appState.toggleLikedDrill(drill);
                  
                  // Show snackbar feedback
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isLiked ? 'Removed from liked drills' : 'Added to liked drills',
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: isLiked ? Colors.grey.shade600 : Colors.green,
                    ),
                  );
                },
              ),
              // Save button for adding to collections - now shows filled when saved
              IconButton(
                icon: Icon(
                  isSavedInCollection ? Icons.bookmark : Icons.bookmark_border, // ✅ UPDATED: Filled when saved
                  color: isSavedInCollection ? AppTheme.primaryPurple : Colors.grey.shade600, // ✅ UPDATED: Purple when saved
                ),
                onPressed: () {
                  HapticUtils.mediumImpact(); // Medium haptic for save action
                  _showSaveToCollectionDialog(context, appState);
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Video player section
                if (drill.videoUrl.isNotEmpty)
                  Column(
                    children: [
                      DrillVideoPlayer(
                        videoUrl: drill.videoUrl,
                        aspectRatio: 16 / 9,
                        showControls: true,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                
                // Drill header with icon and basic info
                _buildDrillHeader(),
                
                const SizedBox(height: 24),
                
                // Description
                _buildSection(
                  title: 'Description',
                  content: Text(
                    drill.description,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Instructions
                if (drill.instructions.isNotEmpty)
                  _buildSection(
                    title: 'Instructions',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: drill.instructions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final instruction = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppTheme.getSkillColor(drill.skill),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  instruction,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 15,
                                    color: Colors.black87,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                
                const SizedBox(height: 20),
                
                // Tips
                if (drill.tips.isNotEmpty)
                  _buildSection(
                    title: 'Tips',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: drill.tips.map((tip) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.lightbulb_outline,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  tip,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 15,
                                    color: Colors.black87,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                
                const SizedBox(height: 20),
                
                // Equipment needed
                if (drill.equipment.isNotEmpty)
                  _buildSection(
                    title: 'Equipment Needed',
                    content: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: drill.equipment.map((equipment) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getEquipmentIcon(equipment),
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                equipment,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                
                const SizedBox(height: 20),
                
                // Skills developed
                _buildSection(
                  title: 'Skills Developed',
                  content: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: drill.subSkills.map((subSkill) {
                      // ✅ Strip underscores and replace with spaces
                      final displaySubSkill = subSkill.replaceAll('_', ' ');
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.getSkillColor(drill.skill).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.getSkillColor(drill.skill).withOpacity(0.3)),
                        ),
                        child: Text(
                          displaySubSkill,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: AppTheme.getSkillColor(drill.skill),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
          bottomNavigationBar: onAddToSession != null ? Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: BravoButton(
                text: isInSession ? 'Remove from Session' : 'Add to Session',
                onPressed: () {
                  HapticUtils.mediumImpact(); // Medium haptic for add to session
                  onAddToSession?.call();
                },
                color: isInSession ? Colors.red : const Color(0xFFF9CC53),
                backColor: isInSession ? Colors.red.shade700 : AppTheme.primaryDarkYellow,
                textColor: Colors.white,
                height: 52,
                textSize: 16,
              ),
            ),
          ) : null,
        );
      },
    );
  }

  void _showSaveToCollectionDialog(BuildContext context, AppStateService appState) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Save to Collection',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a collection to save "${drill.title}" to:',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              
              // Show existing collections
              if (appState.savedDrillGroups.isNotEmpty) ...[
                const Text(
                  'Existing Collections:',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                
                // List existing collections
                ...appState.savedDrillGroups.map((group) {
                  final isDrillInGroup = group.drills.any((d) => d.id == drill.id);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.folder,
                      color: AppTheme.primaryPurple,
                    ),
                    title: Text(
                      group.name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      '${group.drills.length} drills',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                      ),
                    ),
                    trailing: isDrillInGroup 
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: isDrillInGroup ? null : () {
                      HapticUtils.mediumImpact();
                      appState.addDrillToGroup(group.id, drill);
                      Navigator.pop(context);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added to ${group.name}'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  );
                }).toList(),
                
                const SizedBox(height: 16),
              ],
              
              // Option to create new collection
              const Text(
                'Or create a new collection:',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                HapticUtils.lightImpact();
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                HapticUtils.mediumImpact();
                Navigator.pop(context);
                _showCreateCollectionDialog(context, appState);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'New Collection',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCreateCollectionDialog(BuildContext context, AppStateService appState) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Create New Collection',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(fontFamily: 'Poppins'),
                decoration: const InputDecoration(
                  labelText: 'Collection Name',
                  labelStyle: TextStyle(fontFamily: 'Poppins'),
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                style: const TextStyle(fontFamily: 'Poppins'),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  labelStyle: TextStyle(fontFamily: 'Poppins'),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                HapticUtils.lightImpact();
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  HapticUtils.mediumImpact();
                  
                  // Create new collection
                  appState.createDrillGroup(
                    nameController.text.trim(),
                    descriptionController.text.trim().isEmpty
                        ? 'Custom drill collection'
                        : descriptionController.text.trim(),
                  );
                  
                  // Add drill to the newly created collection
                  final newGroup = appState.savedDrillGroups.last;
                  appState.addDrillToGroup(newGroup.id, drill);
                  
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Created "${nameController.text.trim()}" and added drill'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Create & Add',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDrillHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getSkillColor(drill.skill).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getSkillColor(drill.skill).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Skill icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.getSkillColor(drill.skill),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getSkillIcon(drill.skill),
              color: Colors.white,
              size: 32,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Drill info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drill.skill,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.getSkillColor(drill.skill),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  drill.title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip('${drill.sets} sets'),
                    const SizedBox(width: 8),
                    _buildInfoChip('${drill.reps} reps'),
                    const SizedBox(width: 8),
                    _buildInfoChip('${drill.duration} mins'),
                  ],
                ),
                const SizedBox(height: 8),
                _buildDifficultyBadge(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge() {
    Color badgeColor;
    switch (drill.difficulty.toLowerCase()) {
      case 'beginner':
        badgeColor = Colors.green;
        break;
      case 'intermediate':
        badgeColor = Colors.orange;
        break;
      case 'advanced':
        badgeColor = Colors.red;
        break;
      default:
        badgeColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        drill.difficulty,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  IconData _getSkillIcon(String skill) {
    switch (skill.toLowerCase()) {
      case 'passing':
        return Icons.arrow_forward;
      case 'shooting':
        return Icons.sports_soccer;
      case 'dribbling':
        return Icons.directions_run;
      case 'first touch':
        return Icons.touch_app;
      default:
        return Icons.sports;
    }
  }

  IconData _getEquipmentIcon(String equipment) {
    switch (equipment.toLowerCase()) {
      case 'soccer ball':
        return Icons.sports_soccer;
      case 'cones':
        return Icons.traffic;
      case 'goal':
        return Icons.sports_soccer;
      default:
        return Icons.sports;
    }
  }
} 