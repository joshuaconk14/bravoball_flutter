import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart'; // ✅ ADDED: Import for video picker
import 'dart:io'; // ✅ ADDED: Import for File support
import '../../models/drill_model.dart';
import '../../widgets/bravo_button.dart';
import '../../widgets/drill_video_background.dart'; // ✅ ADDED: Import video background widget
import '../../constants/app_theme.dart';
import '../../utils/haptic_utils.dart';
import '../../utils/skill_utils.dart';
import '../../services/app_state_service.dart';
import '../../services/custom_drill_service.dart'; // ✅ ADDED: Import custom drill service
import '../../widgets/save_to_collection_dialog.dart';
import '../create_drill/edit_custom_drill_sheet.dart'; // ✅ ADDED: Import edit custom drill sheet

class DrillDetailView extends StatefulWidget {
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
  State<DrillDetailView> createState() => _DrillDetailViewState();
}

class _DrillDetailViewState extends State<DrillDetailView>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  // ✅ ADDED: Track current sheet position for click cycling
  double _currentSheetSize = 0.4;
  final List<double> _snapSizes = [0.2, 0.4, 0.8];
  late DraggableScrollableController _sheetController; // ✅ FIXED: Proper controller management

  // ✅ ADDED: Video editing functionality for custom drills
  final ImagePicker _picker = ImagePicker();
  bool _isVideoLoading = false;
  String? _updatedVideoPath;

  @override
  void initState() {
    super.initState();
    _sheetController = DraggableScrollableController(); // ✅ ADDED: Initialize controller
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _sheetController.dispose(); // ✅ ADDED: Dispose sheet controller
    super.dispose();
  }

  // ✅ FIXED: Method to cycle through sheet positions when handle is tapped
  void _cycleSheetPosition() {
    final currentIndex = _snapSizes.indexOf(_currentSheetSize);
    final nextIndex = (currentIndex + 1) % _snapSizes.length;
    final nextSize = _snapSizes[nextIndex];
    
    _sheetController.animateTo(
      nextSize,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    setState(() {
      _currentSheetSize = nextSize;
    });
    
    HapticUtils.lightImpact();
  }

  // ✅ ADDED: Video editing methods for custom drills
  Future<void> _pickNewVideo() async {
    try {
      setState(() {
        _isVideoLoading = true;
      });

      final video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 1),
      );

      if (video != null) {
        final file = File(video.path);
        final exists = await file.exists();
        
        if (exists) {
          // Update the custom drill with new video
          await _updateCustomDrillVideo(video.path);
        } else {
          _showErrorMessage('Selected video file not found');
        }
      }
    } catch (e) {
      _showErrorMessage('Error selecting video: ${e.toString()}');
    } finally {
      setState(() {
        _isVideoLoading = false;
      });
    }
  }

  Future<void> _updateCustomDrillVideo(String newVideoPath) async {
    try {
      final customDrillService = CustomDrillService.shared;
      final success = await customDrillService.updateCustomDrillVideo(
        widget.drill.id,
        newVideoPath,
      );

      if (success) {
        setState(() {
          _updatedVideoPath = newVideoPath;
        });

        // Refresh custom drills in app state
        final appState = Provider.of<AppStateService>(context, listen: false);
        await appState.refreshCustomDrillsFromBackend();

        HapticUtils.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        _showErrorMessage('Failed to update video. Please try again.');
      }
    } catch (e) {
      _showErrorMessage('Error updating video: ${e.toString()}');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ UPDATED: Use updated video path if available for custom drills
    final videoUrlToUse = widget.drill.isCustom && _updatedVideoPath != null 
        ? _updatedVideoPath! 
        : widget.drill.videoUrl;
        
    return DrillVideoBackground(
      videoUrl: videoUrlToUse,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              HapticUtils.lightImpact();
              Navigator.pop(context);
            },
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) async {
                if (value == 'like') {
                  HapticUtils.lightImpact();
                  final appState = Provider.of<AppStateService>(context, listen: false);
                  final wasLiked = appState.isDrillLiked(widget.drill);
                  appState.toggleLikedDrill(widget.drill);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(wasLiked 
                        ? 'Removed ${widget.drill.title} from liked drills' 
                        : 'Added ${widget.drill.title} to liked drills'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (value == 'session') {
                  HapticUtils.mediumImpact();
                  final appState = Provider.of<AppStateService>(context, listen: false);
                  final wasInSession = appState.isDrillInSession(widget.drill);
                  
                  if (wasInSession) {
                    appState.removeDrillFromSession(widget.drill);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Removed ${widget.drill.title} from session'),
                        duration: const Duration(seconds: 2),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    final success = appState.addDrillToSession(widget.drill);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added ${widget.drill.title} to session'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Session limit reached! You can only add up to 10 drills to a session.'),
                          duration: Duration(seconds: 3),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                } else if (value == 'add_to_group') {
                  HapticUtils.lightImpact();
                  SaveToCollectionDialog.show(context, widget.drill);
                } else if (value == 'edit_video' && widget.drill.isCustom) {
                  HapticUtils.lightImpact();
                  _pickNewVideo();
                } else if (value == 'edit_drill' && widget.drill.isCustom) {
                  HapticUtils.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditCustomDrillSheet(drill: widget.drill),
                    ),
                  );
                }
              },
              itemBuilder: (context) {
                final appState = Provider.of<AppStateService>(context, listen: false);
                final isLiked = appState.isDrillLiked(widget.drill);
                final isInSession = appState.isDrillInSession(widget.drill);
                
                List<PopupMenuEntry<String>> menuItems = [
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

                // ✅ ADDED: Add "Edit Video" option for custom drills only
                if (widget.drill.isCustom) {
                  menuItems.add(
                    PopupMenuItem(
                      value: 'edit_video',
                      child: Row(
                        children: [
                          _isVideoLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primaryYellow,
                                  ),
                                )
                              : Icon(
                                  Icons.videocam_outlined,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                          const SizedBox(width: 8),
                          Text(_isVideoLoading ? 'Updating...' : 'Edit Video'),
                        ],
                      ),
                    ),
                  );
                }

                // ✅ ADDED: Add "Edit Drill" option for custom drills only
                if (widget.drill.isCustom) {
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
                          Text('Edit Drill'),
                        ],
                      ),
                    ),
                  );
                }

                return menuItems;
              },
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return Stack(
            children: [
              // ✅ UPDATED: Draggable bottom sheet with proper controller
              Positioned.fill(
                child: DraggableScrollableSheet(
                  initialChildSize: 0.4, // Start at 40% of screen height
                  minChildSize: 0.2, // Can be collapsed to 20% 
                  maxChildSize: 0.8, // Can be expanded to 80%
                  snap: true, // Snap to positions
                  snapSizes: const [0.2, 0.4, 0.8], // Snap points
                  controller: _sheetController, // ✅ FIXED: Use proper controller
                  builder: (context, scrollController) {
                    return Transform.translate(
                      offset: Offset(0, MediaQuery.of(context).size.height * 0.4 * _slideAnimation.value),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildDraggableBottomSheet(scrollController),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDraggableBottomSheet(ScrollController scrollController) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        children: [
          // ✅ ENHANCED: Clickable handle bar that cycles through positions
          GestureDetector(
            onTap: _cycleSheetPosition, // ✅ FIXED: Direct method call
            child: Container(
              width: double.infinity, // Make entire top area clickable
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // ✅ IMPROVED: Scrollable content that works even when minimized
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                // Allow scroll events to bubble up properly
                return false;
              },
              child: SingleChildScrollView(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(), // ✅ ADDED: Ensure always scrollable
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drill header
                    _buildDrillHeader(),
                    
                    const SizedBox(height: 24),
                    
                    // Description
                    _buildSection(
                      title: 'Description',
                      content: Text(
                        widget.drill.description,
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
                    if (widget.drill.instructions.isNotEmpty)
                      _buildSection(
                        title: 'Instructions',
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: widget.drill.instructions.asMap().entries.map((entry) {
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
                                      color: AppTheme.getSkillColor(widget.drill.skill),
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
                                        fontSize: 14,
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
                    if (widget.drill.tips.isNotEmpty)
                      _buildSection(
                        title: 'Tips',
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: widget.drill.tips.map((tip) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: AppTheme.getSkillColor(widget.drill.skill),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      tip,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
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
                    
                    // Equipment
                    if (widget.drill.equipment.isNotEmpty)
                      _buildSection(
                        title: 'Equipment',
                        content: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.drill.equipment.map((equipment) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                equipment,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    
                    const SizedBox(height: 20),
                    
                    
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrillHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.drill.title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        
        // Skill badge and stats
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.getSkillColor(widget.drill.skill).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.getSkillColor(widget.drill.skill).withOpacity(0.3),
                ),
              ),
              child: Text(
                SkillUtils.formatSkillForDisplay(widget.drill.skill),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: AppTheme.getSkillColor(widget.drill.skill),
                ),
              ),
            ),
            const Spacer(),
            _buildStatChip('${widget.drill.sets} sets', Icons.repeat),
            const SizedBox(width: 8),
            _buildStatChip('${widget.drill.reps} reps', Icons.fitness_center),
            const SizedBox(width: 8),
            _buildStatChip('${widget.drill.duration} min', Icons.schedule),
          ],
        ),
      ],
    );
  }

  Widget _buildStatChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
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
        const SizedBox(height: 8),
        content,
      ],
    );
  }
} 