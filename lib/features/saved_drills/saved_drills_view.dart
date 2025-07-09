import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../services/app_state_service.dart';
import '../../models/drill_group_model.dart';
import '../../widgets/reusable_drill_search_view.dart';
import 'drill_group_detail_view.dart';

class SavedDrillsView extends StatefulWidget {
  const SavedDrillsView({Key? key}) : super(key: key);

  @override
  State<SavedDrillsView> createState() => _SavedDrillsViewState();
}

class _SavedDrillsViewState extends State<SavedDrillsView> {
  String? _editingGroupId;
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
        return Scaffold(
          backgroundColor: AppTheme.primaryPurple,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Centered title
                      Text(
                        'Saved Drills',
                        style: AppTheme.headlineMedium.copyWith(
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      // Add button row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: () {
                                _showCreateGroupDialog(context, appState);
                              },
                              icon: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Organize your favorite drills into collections',
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Text(
                                'Your Drill Collections',
                                style: AppTheme.headlineSmall.copyWith(
                                  color: AppTheme.primaryDark,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () {
                                  _showInfoDialog(context);
                                },
                                icon: const Icon(
                                  Icons.info_outline,
                                  color: AppTheme.primaryGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: _buildGroupsGrid(appState),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupsGrid(AppStateService appState) {
    final allGroups = [appState.likedDrillsGroup, ...appState.savedDrillGroups];
    
    if (allGroups.isEmpty || (allGroups.length == 1 && allGroups.first.drills.isEmpty)) {
      return _buildEmptyState(appState);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.9,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: allGroups.length,
        itemBuilder: (context, index) {
          final group = allGroups[index];
          return _buildGroupCard(group, appState);
        },
      ),
    );
  }

  Widget _buildGroupCard(DrillGroup group, AppStateService appState) {
    return GestureDetector(
      onTap: _editingGroupId == group.id ? null : () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DrillGroupDetailView(group: group),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: group.isLikedDrillsGroup 
                          ? AppTheme.secondaryRed.withOpacity(0.1)
                          : AppTheme.primaryPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      group.isLikedDrillsGroup ? Icons.favorite : Icons.folder,
                      color: group.isLikedDrillsGroup 
                          ? AppTheme.secondaryRed 
                          : AppTheme.primaryPurple,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  if (!group.isLikedDrillsGroup)
                    if (_editingGroupId == group.id)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _finishEditingGroup(group, appState),
                            icon: const Icon(
                              Icons.check,
                              color: Colors.green,
                              size: 20,
                            ),
                          ),
                          IconButton(
                            onPressed: _cancelEditing,
                            icon: const Icon(
                              Icons.close,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                        ],
                      )
                    else
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _startEditingGroup(group);
                          } else if (value == 'delete') {
                            _showDeleteConfirmation(group, appState);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: AppTheme.primaryPurple),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                        child: Icon(
                          Icons.more_vert,
                          color: Colors.grey.shade600,
                        ),
                      ),
                ],
              ),
              const SizedBox(height: 16),
              // Group name - editable when in edit mode
              if (_editingGroupId == group.id)
                TextField(
                  controller: _nameController,
                  style: AppTheme.titleMedium.copyWith(
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
                  ),
                  maxLines: 1,
                )
              else
                Text(
                  group.name,
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.primaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              Text(
                '${group.drills.length} drill${group.drills.length == 1 ? '' : 's'}',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.primaryGray,
                ),
              ),
              const SizedBox(height: 8),
              // Group description - editable when in edit mode
              if (_editingGroupId == group.id)
                TextField(
                  controller: _descriptionController,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.primaryGray,
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
                  ),
                  maxLines: 2,
                )
              else
                Text(
                  group.description,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.primaryGray,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const Spacer(),
              if (group.drills.isNotEmpty)
                Wrap(
                  spacing: 4,
                  children: group.drills
                      .map((drill) => drill.skill)
                      .toSet()
                      .take(3)
                      .map((skill) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.getSkillColor(skill).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              skill,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontPoppins,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ))
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppStateService appState) {
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
              child: const Icon(
                Icons.folder_copy_outlined,
                size: 48,
                color: AppTheme.primaryPurple,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No drill collections yet',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first collection to organize your favorite drills',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.primaryGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _showCreateGroupDialog(context, appState);
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Collection'),
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

  void _showCreateGroupDialog(BuildContext context, AppStateService appState) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Create New Collection',
          style: TextStyle(fontFamily: AppTheme.fontPoppins),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(fontFamily: AppTheme.fontPoppins),
              decoration: const InputDecoration(
                labelText: 'Collection Name',
                labelStyle: TextStyle(fontFamily: AppTheme.fontPoppins),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              style: const TextStyle(fontFamily: AppTheme.fontPoppins),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                labelStyle: TextStyle(fontFamily: AppTheme.fontPoppins),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: AppTheme.fontPoppins),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                appState.createDrillGroup(
                  nameController.text,
                  descriptionController.text.isEmpty
                      ? 'Custom drill collection'
                      : descriptionController.text,
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Create',
              style: TextStyle(fontFamily: AppTheme.fontPoppins),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(DrillGroup group, AppStateService appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Collection',
          style: TextStyle(fontFamily: AppTheme.fontPoppins),
        ),
        content: Text(
          'Are you sure you want to delete "${group.name}"? This action cannot be undone.',
          style: const TextStyle(fontFamily: AppTheme.fontPoppins),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: AppTheme.fontPoppins),
            ),
          ),
          TextButton(
            onPressed: () {
              appState.deleteDrillGroup(group.id);
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                fontFamily: AppTheme.fontPoppins,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Saved Drills',
          style: TextStyle(fontFamily: AppTheme.fontPoppins),
        ),
        content: const Text(
          'Organize your favorite drills into collections for easy access.\n\n'
          '• Heart icon shows your liked drills\n'
          '• Create custom collections with the + button\n'
          '• Tap any collection to view and manage drills',
          style: TextStyle(fontFamily: AppTheme.fontPoppins),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Got it',
              style: TextStyle(fontFamily: AppTheme.fontPoppins),
            ),
          ),
        ],
      ),
    );
  }

  void _startEditingGroup(DrillGroup group) {
    setState(() {
      _editingGroupId = group.id;
      _nameController.text = group.name;
      _descriptionController.text = group.description;
    });
  }

  void _finishEditingGroup(DrillGroup group, AppStateService appState) {
    if (_nameController.text.trim().isNotEmpty) {
      appState.editDrillGroup(
        group.id,
        _nameController.text.trim(),
        _descriptionController.text.trim(),
      );
    }
    setState(() {
      _editingGroupId = null;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingGroupId = null;
    });
  }
} 