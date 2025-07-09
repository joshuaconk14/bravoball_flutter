import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../services/app_state_service.dart';
import '../../models/drill_group_model.dart';
import '../../models/drill_model.dart';
import '../../widgets/drill_card_widget.dart';
import '../../widgets/reusable_drill_search_view.dart';
import '../session_generator/drill_detail_view.dart';

class DrillGroupDetailView extends StatefulWidget {
  final DrillGroup group;

  const DrillGroupDetailView({
    Key? key,
    required this.group,
  }) : super(key: key);

  @override
  State<DrillGroupDetailView> createState() => _DrillGroupDetailViewState();
}

class _DrillGroupDetailViewState extends State<DrillGroupDetailView> {
  bool _isEditMode = false;
  bool _isEditingGroupInfo = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateService>(
      builder: (context, appState, child) {
        // Get the latest version of the group
        final currentGroup = widget.group.isLikedDrillsGroup 
            ? appState.likedDrillsGroup
            : appState.getDrillGroup(widget.group.id) ?? widget.group;

        return Scaffold(
          backgroundColor: AppTheme.primaryPurple,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(currentGroup, appState),
                
                // Content
                Expanded(
                  child: Container(
                    width: double.infinity,
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
                        
                        // Group info and stats
                        _buildGroupInfo(currentGroup),
                        
                        const SizedBox(height: 20),
                        
                        // Drills list or empty state
                        Expanded(
                          child: currentGroup.drills.isEmpty 
                              ? _buildEmptyState(currentGroup, appState)
                              : _buildDrillsList(currentGroup, appState),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Floating action button to add drills
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddDrillsDialog(currentGroup, appState),
            backgroundColor: AppTheme.primaryPurple,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildHeader(DrillGroup group, AppStateService appState) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          
          // Header row
          Row(
            children: [
              // Back button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Edit mode toggle (only for custom groups)
              if (!group.isLikedDrillsGroup)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () {
                      if (_isEditMode) {
                        // If we're in edit mode, finish editing
                        _finishEditingGroupInfo(appState);
                      } else {
                        // Start editing group info
                        _startEditingGroupInfo(group);
                      }
                    },
                    icon: Icon(
                      _isEditMode ? Icons.done : Icons.edit,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Group icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  group.isLikedDrillsGroup ? Icons.favorite : Icons.folder,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group name - editable when in edit mode
                    if (_isEditMode)
                      TextField(
                        controller: _nameController,
                        style: AppTheme.headlineMedium.copyWith(
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                        ),
                        maxLines: 1,
                      )
                    else
                      Text(
                        group.name,
                        style: AppTheme.headlineMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${group.drills.length} drill${group.drills.length == 1 ? '' : 's'}',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupInfo(DrillGroup group) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (group.description.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.lightGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isEditMode
                  ? TextField(
                      controller: _descriptionController,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.primaryDark,
                      ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.primaryPurple.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.primaryPurple.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.primaryPurple, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Enter description...',
                        hintStyle: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primaryGray.withOpacity(0.6),
                        ),
                      ),
                      maxLines: 3,
                    )
                  : Text(
                      group.description,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.primaryDark,
                      ),
                    ),
            ),
          
          if (group.drills.isNotEmpty) ...[
            const SizedBox(height: 16),
            
            // Skills breakdown
            Row(
              children: [
                Text(
                  'Skills covered:',
                  style: AppTheme.titleSmall.copyWith(
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: group.drills
                        .map((drill) => drill.skill)
                        .toSet()
                        .map((skill) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.getSkillColor(skill).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.getSkillColor(skill).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                skill,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontPoppins,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.getSkillColor(skill),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDrillsList(DrillGroup group, AppStateService appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // List header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                'Drills',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.primaryDark,
                ),
              ),
              const Spacer(),
              if (_isEditMode && !group.isLikedDrillsGroup)
                Text(
                  'Edit group info • Tap drills to remove',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.primaryGray,
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Drills list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: group.drills.length,
            itemBuilder: (context, index) {
              final drill = group.drills[index];
              return _buildDrillItem(drill, group, appState);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDrillItem(DrillModel drill, DrillGroup group, AppStateService appState) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Stack(
        children: [
          DraggableDrillCard(
            drill: drill,
            onTap: () => _navigateToDrillDetail(drill),
            onDelete: _isEditMode && !group.isLikedDrillsGroup
                ? () => _removeDrillFromGroup(drill, group, appState)
                : null,
          ),
          
          // Liked drill overlay for liked drills group
          if (group.isLikedDrillsGroup)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  appState.toggleLikedDrill(drill);
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
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
                  child: Icon(
                    Icons.favorite,
                    color: AppTheme.secondaryRed,
                    size: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(DrillGroup group, AppStateService appState) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                group.isLikedDrillsGroup ? Icons.favorite_border : Icons.folder_open,
                size: 48,
                color: AppTheme.primaryPurple,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              group.isLikedDrillsGroup 
                  ? 'No liked drills yet'
                  : 'No drills in this collection',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.primaryDark,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              group.isLikedDrillsGroup
                  ? 'Like drills from the session generator to see them here'
                  : 'Add drills to this collection to get started',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.primaryGray,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            ElevatedButton.icon(
              onPressed: () => _showAddDrillsDialog(group, appState),
              icon: const Icon(Icons.add),
              label: Text(group.isLikedDrillsGroup ? 'Browse Drills' : 'Add Drills'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDrillDetail(DrillModel drill) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DrillDetailView(
          drill: drill,
          isInSession: false,
        ),
      ),
    );
  }

  void _removeDrillFromGroup(DrillModel drill, DrillGroup group, AppStateService appState) {
    appState.removeDrillFromGroup(group.id, drill);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${drill.title} removed from ${group.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAddDrillsDialog(DrillGroup group, AppStateService appState) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReusableDrillSearchView(
          title: group.isLikedDrillsGroup 
              ? 'Like Drills' 
              : 'Add to ${group.name}',
          actionButtonText: group.isLikedDrillsGroup ? 'Like Drills' : 'Add to Collection',
          onDrillsSelected: (selectedDrills) {
            if (group.isLikedDrillsGroup) {
              // For liked drills, toggle each drill's liked status
              for (final drill in selectedDrills) {
                if (!appState.isDrillLiked(drill)) {
                  appState.toggleLikedDrill(drill);
                }
              }
            } else {
              // For custom groups, add drills to the group
              appState.addDrillsToGroup(group.id, selectedDrills);
            }
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${selectedDrills.length} drill${selectedDrills.length == 1 ? '' : 's'} '
                  '${group.isLikedDrillsGroup ? 'liked' : 'added to ${group.name}'}',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          isSelected: (drill) {
            // Check if drill is already in this group
            return group.drills.any((d) => d.id == drill.id);
          },
        ),
      ),
    );
  }

  void _startEditingGroupInfo(DrillGroup group) {
    setState(() {
      _isEditMode = true;
      _nameController.text = group.name;
      _descriptionController.text = group.description;
    });
  }

  void _finishEditingGroupInfo(AppStateService appState) {
    if (_nameController.text.trim().isNotEmpty) {
      appState.editDrillGroup(
        widget.group.id,
        _nameController.text.trim(),
        _descriptionController.text.trim(),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group updated successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    
    setState(() {
      _isEditMode = false;
    });
  }
} 