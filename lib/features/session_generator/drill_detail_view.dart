import 'package:flutter/material.dart';
import '../../models/drill_model.dart';
import '../../widgets/bravo_button.dart';
import '../../widgets/drill_video_player.dart';
import '../../constants/app_theme.dart';

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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
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
                              color: _getSkillColor(drill.skill),
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
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getSkillColor(drill.skill).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getSkillColor(drill.skill).withOpacity(0.3)),
                    ),
                    child: Text(
                      subSkill,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: _getSkillColor(drill.skill),
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
            onPressed: onAddToSession,
            color: isInSession ? Colors.red : const Color(0xFFF9CC53),
            backColor: isInSession ? Colors.red.shade700 : AppTheme.primaryDarkYellow,
            textColor: Colors.white,
            height: 52,
            textSize: 16,
          ),
        ),
      ) : null,
    );
  }

  Widget _buildDrillHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getSkillColor(drill.skill).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getSkillColor(drill.skill).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Skill icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _getSkillColor(drill.skill),
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
                    color: _getSkillColor(drill.skill),
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

  Color _getSkillColor(String skill) {
    switch (skill.toLowerCase()) {
      case 'passing':
        return Colors.blue;
      case 'shooting':
        return Colors.red;
      case 'dribbling':
        return Colors.green;
      case 'first touch':
        return Colors.purple;
      default:
        return Colors.grey;
    }
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