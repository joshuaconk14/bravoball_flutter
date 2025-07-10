import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/drill_model.dart';
import '../../models/editable_drill_model.dart';
import '../../services/app_state_service.dart';
import '../../constants/app_theme.dart';
import '../../widgets/drill_video_player.dart';
import 'drill_detail_view.dart';

class EditDrillView extends StatefulWidget {
  final EditableDrillModel editableDrill;
  final VoidCallback? onSave; // Optional callback when changes are saved

  const EditDrillView({
    Key? key,
    required this.editableDrill,
    this.onSave,
  }) : super(key: key);

  @override
  State<EditDrillView> createState() => _EditDrillViewState();
}

class _EditDrillViewState extends State<EditDrillView> {
  late int sets;
  late int reps;
  late int duration;
  
  @override
  void initState() {
    super.initState();
    sets = widget.editableDrill.totalSets;
    reps = widget.editableDrill.totalReps;
    duration = widget.editableDrill.totalDuration;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Drill',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: () => _showDrillDetails(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 32),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Details',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Video placeholder (like in Swift app)
                  _buildVideoSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Drill title
                  Text(
                    widget.editableDrill.drill.title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Skill badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getSkillColor(widget.editableDrill.drill.skill).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getSkillColor(widget.editableDrill.drill.skill).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      widget.editableDrill.drill.skill,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: _getSkillColor(widget.editableDrill.drill.skill),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Edit controls
                  _buildEditControls(),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          
          // Save Changes button
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildVideoSection() {
    if (widget.drill.videoUrl.isNotEmpty) {
      return DrillVideoPlayer(
        videoUrl: widget.drill.videoUrl,
        aspectRatio: 16 / 9,
        showControls: true,
      );
    } else {
      // Fallback placeholder when no video URL
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off,
              size: 48,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              'No video available',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildEditControls() {
    return Column(
      children: [
        _buildControlRow('Sets', sets, (value) => setState(() => sets = value)),
        const SizedBox(height: 16),
        _buildControlRow('Reps', reps, (value) => setState(() => reps = value)),
        const SizedBox(height: 16),
        _buildControlRow('Minutes', duration, (value) => setState(() => duration = value)),
      ],
    );
  }

  Widget _buildControlRow(String label, int value, Function(int) onChanged) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    if (value > 1) onChanged(value - 1);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: value > 1 ? Colors.grey.shade300 : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.remove,
                      color: value > 1 ? Colors.black54 : Colors.grey.shade400,
                      size: 16,
                    ),
                  ),
                ),
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                GestureDetector(
                  onTap: () => onChanged(value + 1),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.black54,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _saveChanges,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.buttonPrimary,
            foregroundColor: AppTheme.textOnPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
          ),
          child: Text(
            'Save Changes',
            style: AppTheme.buttonTextMedium,
          ),
        ),
      ),
    );
  }

  void _saveChanges() {
    // Update the drill in the session using AppStateService
    final appState = Provider.of<AppStateService>(context, listen: false);
    
    // Only update if the drill is actually in the session
    if (appState.isDrillInSession(widget.editableDrill.drill)) {
      appState.updateDrillInSession(
        widget.editableDrill.drill.id,
        sets: sets,
        reps: reps,
        duration: duration,
      );
      
      // Call the onSave callback if provided
      widget.onSave?.call();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Drill updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
    
    Navigator.pop(context);
  }

  void _showDrillDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DrillDetailView(
          drill: widget.editableDrill.drill,
          isInSession: true,
        ),
      ),
    );
  }

  Color _getSkillColor(String skill) {
    return AppTheme.getSkillColor(skill);
  }
} 