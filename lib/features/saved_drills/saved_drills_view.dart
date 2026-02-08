import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../services/app_state_service.dart';
import '../../models/drill_group_model.dart';
import '../../models/drill_model.dart'; // ✅ ADDED: Import DrillModel
import '../../widgets/reusable_drill_search_view.dart';
import '../../widgets/info_popup_widget.dart';
import '../../widgets/guest_account_overlay.dart'; // ✅ NEW: Import reusable guest overlay
import '../../utils/haptic_utils.dart';
import '../../utils/skill_utils.dart'; // ✅ ADDED: Import centralized skill utilities
import '../../features/onboarding/onboarding_flow.dart'; // ✅ ADDED: Import OnboardingFlow
import 'drill_group_detail_view.dart';
import '../../widgets/warning_dialog.dart'; // ✅ ADDED: Import WarningDialog
import '../../widgets/drill_card_widget.dart'; // ✅ ADDED: Import drill card widget
import '../../features/session_generator/drill_detail_view.dart'; // ✅ ADDED: Import DrillDetailView

class SavedDrillsView extends StatefulWidget {
  const SavedDrillsView({Key? key}) : super(key: key);

  @override
  State<SavedDrillsView> createState() => _SavedDrillsViewState();
}

class _SavedDrillsViewState extends State<SavedDrillsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateService>(
      builder: (context, appState, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppTheme.primaryDark),
              onPressed: () {
                HapticUtils.lightImpact();
                Navigator.of(context).pop();
              },
            ),
            title: Text(
              'Saved Drills',
              style: AppTheme.titleMedium.copyWith(
                color: AppTheme.primaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.add, color: AppTheme.primaryDark),
                onPressed: () {
                  HapticUtils.mediumImpact();
                  _showCreateGroupDialog(context, appState);
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              // Main content
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Tab bar
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: AppTheme.primaryYellow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: AppTheme.primaryDark,
                        unselectedLabelColor: AppTheme.primaryGray,
                        labelStyle: const TextStyle(
                          fontFamily: AppTheme.fontPoppins,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontFamily: AppTheme.fontPoppins,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        tabs: const [
                          Tab(text: 'Collections'),
                          Tab(text: 'Custom Drills'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Tab content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Collections tab
                          _buildCollectionsTab(appState),
                          // Custom drills tab
                          _buildCustomDrillsTab(appState),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // ✅ NEW: Guest mode overlay using reusable widget
              if (appState.isGuestMode) 
                GuestAccountOverlay(
                  title: 'Create an account',
                  description: 'Save your favorite drills and create collections by creating an account.',
                  themeColor: AppTheme.primaryYellow,
                ),
            ],
          ),
        );
      },
    );
  }

  // Collections tab content
  Widget _buildCollectionsTab(AppStateService appState) {
    return Column(
      children: [
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
                  HapticUtils.lightImpact(); // Light haptic for info
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
    );
  }

  // Custom drills tab content
  Widget _buildCustomDrillsTab(AppStateService appState) {
    final customDrills = appState.customDrills;
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                'Custom Drills',
                style: AppTheme.headlineSmall.copyWith(
                  color: AppTheme.primaryDark,
                ),
              ),
              const Spacer(),
              Text(
                '${customDrills.length} drill${customDrills.length == 1 ? '' : 's'}',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.primaryGray,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: customDrills.isEmpty
              ? _buildEmptyCustomDrillsState()
              : _buildCustomDrillsList(customDrills, appState),
        ),
      ],
    );
  }

  Widget _buildEmptyCustomDrillsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryGray.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.sports_soccer_outlined,
                size: 48,
                color: AppTheme.primaryGray,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No custom drills yet',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first custom drill to see it here',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.primaryGray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomDrillsList(List<DrillModel> customDrills, AppStateService appState) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: customDrills.length,
      itemBuilder: (context, index) {
        final drill = customDrills[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DraggableDrillCard(
            drill: drill,
            onTap: () {
              HapticUtils.mediumImpact();
              // Navigate to drill detail view
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DrillDetailView(
                    drill: drill,
                    isInSession: appState.isDrillInSession(drill),
                    onAddToSession: null,
                  ),
                ),
              );
            },
            onDelete: () {
              HapticUtils.lightImpact();
              _showDeleteCustomDrillDialog(drill, appState);
            },
            showOverlayIcons: true,
          ),
        );
      },
    );
  }

  void _showDeleteCustomDrillDialog(DrillModel drill, AppStateService appState) {
    WarningDialog.show(
      context: context,
      title: 'Delete Custom Drill',
      content: 'Are you sure you want to delete "${drill.title}"? This action cannot be undone.',
      cancelText: 'Cancel',
      continueText: 'Delete',
      warningColor: Colors.red,
      warningIcon: Icons.delete_forever,
      onCancel: () {
        HapticUtils.lightImpact();
      },
      onContinue: () {
        HapticUtils.mediumImpact();
        appState.deleteCustomDrill(drill.id);
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
      onTap: () {
        HapticUtils.mediumImpact(); // Medium haptic for group navigation
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
              color: Colors.black.withValues(alpha: 0.08),
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
                          ? AppTheme.secondaryRed.withValues(alpha: 0.1)
                          : AppTheme.primaryGray.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      group.isLikedDrillsGroup ? Icons.favorite : Icons.folder,
                      color: group.isLikedDrillsGroup 
                          ? AppTheme.secondaryRed 
                          : AppTheme.primaryGray,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  // ✅ Only show ellipses button for non-liked drill groups
                  if (!group.isLikedDrillsGroup)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        HapticUtils.lightImpact(); // Light haptic for delete initiation
                        _showDeleteConfirmation(group, appState);
                      }
                    },
                    itemBuilder: (context) => [
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
              const Spacer(),
              if (!group.isLikedDrillsGroup && group.drills.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: group.drills
                      .map((drill) => drill.skill)
                      .toSet()
                      .take(3)
                      .map((skill) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.getSkillColor(skill).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              SkillUtils.formatSkillForDisplay(skill),
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
                color: AppTheme.primaryGray.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.folder_copy_outlined,
                size: 48,
                color: AppTheme.primaryGray,
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
                HapticUtils.mediumImpact(); // Medium haptic for create collection
                _showCreateGroupDialog(context, appState);
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Collection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryYellow,
                foregroundColor: AppTheme.primaryDark,
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
    final existingNames = appState.savedDrillGroups.map((g) => g.name.toLowerCase()).toSet();

    showDialog(
      context: context,
      builder: (dialogContext) {
        String? errorText;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
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
                    decoration: InputDecoration(
                      labelText: 'Collection Name',
                      labelStyle: const TextStyle(fontFamily: AppTheme.fontPoppins),
                      errorText: errorText,
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
                  onPressed: () {
                    HapticUtils.lightImpact();
                    Navigator.pop(dialogContext);
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: AppTheme.fontPoppins,
                      color: AppTheme.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    if (existingNames.contains(name.toLowerCase())) {
                      setState(() => errorText = 'A collection with this name already exists.');
                      return;
                    }
                    HapticUtils.mediumImpact();
                    appState.createDrillGroup(
                      name,
                      descriptionController.text.isEmpty
                          ? 'Custom drill collection'
                          : descriptionController.text,
                    );
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryYellow,
                    foregroundColor: AppTheme.primaryDark,
                  ),
                  child: const Text(
                    'Create',
                    style: TextStyle(
                      fontFamily: AppTheme.fontPoppins,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(DrillGroup group, AppStateService appState) {
    WarningDialog.show(
      context: context,
      title: 'Delete Collection',
      content: 'Are you sure you want to delete "${group.name}"? This action cannot be undone.',
      cancelText: 'Cancel',
      continueText: 'Delete',
      warningColor: Colors.red,
      warningIcon: Icons.delete_forever,
      onCancel: () {
        HapticUtils.lightImpact();
      },
      onContinue: () {
        HapticUtils.mediumImpact();
        appState.deleteDrillGroup(group.id);
      },
    );
  }

  void _showInfoDialog(BuildContext context) {
    InfoPopupWidget.show(
      context,
      title: 'Your Drill Collections',
      description: 'Create collections to organize your favorite drills for easy access.\n\nHeart drills you like and create custom playlists with the + button.',
      riveFileName: 'Bravo_Animation.riv',
    );
  }

  // ✅ REMOVED: _buildGuestOverlay method - now using reusable widget
} 