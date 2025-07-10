import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/drill_model.dart';
import '../../models/editable_drill_model.dart';
import '../../models/filter_models.dart';
import '../../services/app_state_service.dart';
import '../../widgets/filter_widgets.dart';
import '../../widgets/drill_card_widget.dart';
import 'drill_detail_view.dart';
import 'drill_search_view.dart';
import 'edit_drill_view.dart';
import '../../constants/app_theme.dart';

class SessionGeneratorEditorPage extends StatefulWidget {
  const SessionGeneratorEditorPage({Key? key}) : super(key: key);

  @override
  State<SessionGeneratorEditorPage> createState() => _SessionGeneratorEditorPageState();
}

class _SessionGeneratorEditorPageState extends State<SessionGeneratorEditorPage> {
  final ScrollController _filterScrollController = ScrollController();
  bool _showScrollIndicator = true;

  @override
  void initState() {
    super.initState();
    _filterScrollController.addListener(_onFilterScroll);
  }

  @override
  void dispose() {
    _filterScrollController.removeListener(_onFilterScroll);
    _filterScrollController.dispose();
    super.dispose();
  }

  void _onFilterScroll() {
    if (_filterScrollController.hasClients) {
      final isAtEnd = _filterScrollController.position.pixels >= 
          _filterScrollController.position.maxScrollExtent - 10; // Small buffer
      
      if (_showScrollIndicator == isAtEnd) {
        setState(() {
          _showScrollIndicator = !isAtEnd;
        });
      }
    }
  }

  // Build the session generator editor page
  @override
  Widget build(BuildContext context) {
    // Return the session generator editor page
    return Consumer<AppStateService>(
      builder: (context, appState, child) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryLightBlue,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.white, size: 28),
          onPressed: () => _showInfoDialog(context),
        ),
        title: const Text(
          'Edit Session',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Done',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter section with shadow (fixed)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selected skills display
                if (appState.preferences.selectedSkills.isNotEmpty)
                  _buildSelectedSkillsSection(appState),
                if (appState.preferences.selectedSkills.isNotEmpty)
                  const SizedBox(height: 12),
                // Filter chips
                _buildFilterChips(appState),
              ],
            ),
          ),
          // Drills section (scrollable)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 32),
              children: [
                _buildSessionDrillsSection(appState),
                if (appState.sessionDrills.isNotEmpty)
                  const SizedBox(height: 20),
                if (appState.sessionDrills.isNotEmpty)
                  _buildAddMoreDrillsButton(appState),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: appState.sessionDrills.isEmpty || true
          ? FloatingActionButton(
              backgroundColor: AppTheme.primaryLightBlue,
              foregroundColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DrillSearchView(),
                  ),
                );
              },
              child: const Icon(Icons.add, size: 32),
              tooltip: 'Add Drills',
            )
          : null,
    );
  },
);
  }

  // Build the selected skills section
  Widget _buildSelectedSkillsSection(AppStateService appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Focus Skills',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
          children: appState.preferences.selectedSkills.map((skill) {
            return Chip(
              label: Text(
                skill,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              backgroundColor: Colors.blue.shade50,
                  deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                final newSkills = Set<String>.from(appState.preferences.selectedSkills);
                newSkills.remove(skill);
                appState.updateSkillsFilter(newSkills);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // Build the filter chips
  Widget _buildFilterChips(AppStateService appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Training Preferences',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        // Filter chips for training preferences
        Stack(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: _filterScrollController,
              child: Row(
                children: [
                  // Skills filter chip (first)
                  FilterChipWidget(
                    filterType: FilterType.difficulty, // Using difficulty as placeholder
                    displayText: appState.preferences.selectedSkills.isEmpty
                        ? 'Skills'
                        : 'Skills (${appState.preferences.selectedSkills.length})',
                    isSelected: appState.preferences.selectedSkills.isNotEmpty,
                    onTap: () => _showSkillsSheet(context, appState),
                  ),
                  const SizedBox(width: 8),
                  FilterChipWidget(
                    filterType: FilterType.time,
                    displayText: appState.preferences.selectedTime ?? 'Time',
                    isSelected: appState.preferences.selectedTime != null,
                    onTap: () => _showFilterSheet(context, FilterType.time, appState),
                  ),
                  const SizedBox(width: 8),
                  FilterChipWidget(
                    filterType: FilterType.equipment,
                    displayText: appState.preferences.selectedEquipment.isEmpty
                        ? 'Equipment'
                        : 'Equipment (${appState.preferences.selectedEquipment.length})',
                    isSelected: appState.preferences.selectedEquipment.isNotEmpty,
                    onTap: () => _showFilterSheet(context, FilterType.equipment, appState),
                  ),
                  const SizedBox(width: 8),
                  FilterChipWidget(
                    filterType: FilterType.trainingStyle,
                    displayText: appState.preferences.selectedTrainingStyle ?? 'Style',
                    isSelected: appState.preferences.selectedTrainingStyle != null,
                    onTap: () => _showFilterSheet(context, FilterType.trainingStyle, appState),
                  ),
                  const SizedBox(width: 8),
                  FilterChipWidget(
                    filterType: FilterType.location,
                    displayText: appState.preferences.selectedLocation ?? 'Location',
                    isSelected: appState.preferences.selectedLocation != null,
                    onTap: () => _showFilterSheet(context, FilterType.location, appState),
                  ),
                  const SizedBox(width: 8),
                  FilterChipWidget(
                    filterType: FilterType.difficulty,
                    displayText: appState.preferences.selectedDifficulty ?? 'Difficulty',
                    isSelected: appState.preferences.selectedDifficulty != null,
                    onTap: () => _showFilterSheet(context, FilterType.difficulty, appState),
                  ),
                  const SizedBox(width: 60), // Extra space for scroll indicator
                ],
              ),
            ),
            // Enhanced scroll indicator on the right
            if (_showScrollIndicator)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0.8),
                        Colors.white,
                      ],
                      stops: const [0.0, 0.2, 0.6, 1.0],
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_right,
                          color: Colors.grey.shade600,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // Build the session drills section
  Widget _buildSessionDrillsSection(AppStateService appState) {
    if (appState.sessionDrills.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 32),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryLightBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.folder, size: 48, color: AppTheme.primaryLightBlue),
          ),
          const SizedBox(height: 18),
          const Text(
            'No drills in this session',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add drills to this session to get started',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w400,
              fontSize: 15,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: 200,
            height: 56,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 22),
              label: const Text(
                'Add Drills',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  overflow: TextOverflow.visible,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLightBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DrillSearchView(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Spacer(),
            if (appState.editableSessionDrills.isNotEmpty) ...[
              Text(
                '${appState.editableSessionDrills.length} drill${appState.editableSessionDrills.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear Session'),
                      content: const Text('Are you sure you want to remove all drills from your session?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            appState.clearSession();
                            Navigator.pop(context);
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.clear_all, size: 14, color: Colors.red.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Clear',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (appState.editableSessionDrills.isEmpty)
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fitness_center, size: 32, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'Set your preferences above\nto generate a training session',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: appState.editableSessionDrills.length,
            onReorder: (oldIndex, newIndex) {
              appState.reorderSessionDrills(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final editableDrill = appState.editableSessionDrills[index];
              return Padding(
                key: Key(editableDrill.drill.id),
                padding: const EdgeInsets.only(bottom: 8),
                child: DraggableDrillCard(
                  drill: editableDrill.drill,
                  sets: editableDrill.totalSets,
                  reps: editableDrill.totalReps,
                  duration: editableDrill.totalDuration,
                  isDraggable: true,
                  onTap: () => _navigateToDrillDetail(context, editableDrill, appState),
                  onDelete: () => appState.removeDrillFromSession(editableDrill.drill),
                ),
              );
            },
          ),
      ],
    );
  }

  // Build the add more drills button
  Widget _buildAddMoreDrillsButton(AppStateService appState) {
    final availableDrillsCount = appState.drillsNotInSession.length;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.purple.shade50],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DrillSearchView(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.add_circle_outline,
                    color: Colors.blue.shade700,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add More Drills',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Browse $availableDrillsCount more drills to customize your session',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Navigate to the drill detail view
  void _navigateToDrillDetail(BuildContext context, EditableDrillModel drill, AppStateService appState) {
    final isInSession = appState.isDrillInSession(drill.drill);
    
    if (isInSession) {
      // Find the EditableDrillModel for this drill
      final editableDrill = appState.editableSessionDrills.firstWhere(
        (ed) => ed.drill.id == drill.drill.id,
        orElse: () => EditableDrillModel(
          drill: drill.drill,
          setsDone: 0,
          totalSets: drill.totalSets,
          totalReps: drill.totalReps,
          totalDuration: drill.totalDuration,
          isCompleted: false,
        ),
      );
      
      // Navigate to EditDrillView for session drills
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditDrillView(
            editableDrill: editableDrill,
            onSave: () {
              // Optional: Add any additional logic when drill is saved
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${drill.drill.title} updated in session')),
              );
            },
          ),
        ),
      );
    } else {
      // Navigate to DrillDetailView for drills not in session
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DrillDetailView(
            drill: drill.drill,
            isInSession: isInSession,
            onAddToSession: () {
              appState.addDrillToSession(drill.drill);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${drill.drill.title} added to session')),
              );
              Navigator.pop(context);
            },
          ),
        ),
      );
    }
  }

  // Show the filter sheet
  void _showFilterSheet(BuildContext context, FilterType filterType, AppStateService appState) {
    showFilterSheet(context, filterType);
  }

  // Show the skills sheet
  void _showSkillsSheet(BuildContext context, AppStateService appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Skills',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            // Sub-skill selector
            Expanded(
              child: Consumer<AppStateService>(
                builder: (context, appState, child) {
                  return SkillSelector(
                    selectedSkills: appState.preferences.selectedSkills,
                    onChanged: (skills) {
                      appState.updateSkillsFilter(skills);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF9CC53),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Show the info dialog
  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session Generator'),
        content: const Text(
          'Set your training preferences and we\'ll automatically generate '
          'a personalized session for you. You can then add more drills '
          'from our full catalog to customize your workout.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
} 