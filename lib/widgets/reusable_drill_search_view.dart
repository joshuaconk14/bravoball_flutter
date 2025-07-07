import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/drill_model.dart';
import '../models/filter_models.dart';
import '../services/app_state_service.dart';
import '../constants/app_theme.dart';
import '../features/session_generator/drill_detail_view.dart';

class ReusableDrillSearchView extends StatefulWidget {
  final String title;
  final String actionButtonText;
  final Function(List<DrillModel>) onDrillsSelected;
  final Function(DrillModel)? isDisabled;
  final Function(DrillModel)? isSelected;
  final bool allowMultipleSelection;

  const ReusableDrillSearchView({
    Key? key,
    required this.title,
    required this.actionButtonText,
    required this.onDrillsSelected,
    this.isDisabled,
    this.isSelected,
    this.allowMultipleSelection = true,
  }) : super(key: key);

  @override
  State<ReusableDrillSearchView> createState() => _ReusableDrillSearchViewState();
}

class _ReusableDrillSearchViewState extends State<ReusableDrillSearchView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedSkillFilter;
  final Set<DrillModel> _selectedDrills = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateService>(
      builder: (context, appState, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: AppTheme.primaryPurple,
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.title,
              style: const TextStyle(
                fontFamily: AppTheme.fontPoppins,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: () {
                  widget.onDrillsSelected(_selectedDrills.toList());
                  Navigator.pop(context);
                },
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontFamily: AppTheme.fontPoppins,
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
              // Search and filter section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryPurple, width: 2),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontPoppins,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search drills...',
                          hintStyle: TextStyle(
                            fontFamily: AppTheme.fontPoppins,
                            color: Colors.grey,
                          ),
                          prefixIcon: Icon(Icons.search, color: AppTheme.primaryPurple),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Skill filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildSkillFilterChip('All', null),
                          const SizedBox(width: 8),
                          ...SkillCategories.categories.map((category) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildSkillFilterChip(category.name, category.name),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Selected drills count
              if (_selectedDrills.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: AppTheme.primaryPurple.withOpacity(0.1),
                  child: Text(
                    '${_selectedDrills.length} drill${_selectedDrills.length == 1 ? '' : 's'} selected',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontPoppins,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ),
              
              // Results
              Expanded(
                child: _buildSearchResults(appState),
              ),
              
              // Action button
              if (_selectedDrills.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onDrillsSelected(_selectedDrills.toList());
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '${widget.actionButtonText} (${_selectedDrills.length})',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontPoppins,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkillFilterChip(String label, String? skillValue) {
    final isSelected = _selectedSkillFilter == skillValue;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSkillFilter = skillValue;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryPurple : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryDarkPurple : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontPoppins,
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(AppStateService appState) {
    List<DrillModel> results;
    
    if (_searchQuery.isNotEmpty) {
      results = appState.searchDrills(_searchQuery);
    } else if (_selectedSkillFilter != null) {
      results = appState.filterDrillsBySkill(_selectedSkillFilter!);
    } else {
      results = appState.availableDrills;
    }
    
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'No drills found for "$_searchQuery"'
                  : 'No drills available',
              style: const TextStyle(
                fontFamily: AppTheme.fontPoppins,
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(
                fontFamily: AppTheme.fontPoppins,
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${results.length} drill${results.length == 1 ? '' : 's'} found',
            style: const TextStyle(
              fontFamily: AppTheme.fontPoppins,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
        
        // Results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final drill = results[index];
              final isCurrentlySelected = _selectedDrills.contains(drill);
              final isDisabled = widget.isDisabled?.call(drill) ?? false;
              final isPreSelected = widget.isSelected?.call(drill) ?? false;
              
              return SelectableDrillCard(
                drill: drill,
                isSelected: isCurrentlySelected,
                isDisabled: isDisabled,
                isPreSelected: isPreSelected,
                onTap: () => _navigateToDrillDetail(context, drill, appState),
                onSelectionChanged: (selected) {
                  setState(() {
                    if (widget.allowMultipleSelection) {
                      if (selected) {
                        _selectedDrills.add(drill);
                      } else {
                        _selectedDrills.remove(drill);
                      }
                    } else {
                      _selectedDrills.clear();
                      if (selected) {
                        _selectedDrills.add(drill);
                      }
                    }
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _navigateToDrillDetail(BuildContext context, DrillModel drill, AppStateService appState) {
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
}

class SelectableDrillCard extends StatelessWidget {
  final DrillModel drill;
  final bool isSelected;
  final bool isDisabled;
  final bool isPreSelected;
  final VoidCallback? onTap;
  final Function(bool) onSelectionChanged;

  const SelectableDrillCard({
    Key? key,
    required this.drill,
    required this.isSelected,
    required this.isDisabled,
    required this.isPreSelected,
    this.onTap,
    required this.onSelectionChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryPurple.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
              ? AppTheme.primaryPurple 
              : isPreSelected 
                  ? AppTheme.secondaryBlue
                  : Colors.grey.shade200,
          width: isSelected || isPreSelected ? 2 : 1,
        ),
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Selection checkbox
                GestureDetector(
                  onTap: isDisabled || isPreSelected 
                      ? null 
                      : () => onSelectionChanged(!isSelected),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppTheme.primaryPurple 
                          : isPreSelected
                              ? AppTheme.secondaryBlue
                              : Colors.transparent,
                      border: Border.all(
                        color: isSelected 
                            ? AppTheme.primaryPurple 
                            : isPreSelected
                                ? AppTheme.secondaryBlue
                                : Colors.grey.shade400,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: isSelected || isPreSelected
                        ? Icon(
                            isPreSelected ? Icons.check : Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Skill indicator
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.getSkillColor(drill.skill),
                    borderRadius: BorderRadius.circular(2),
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
                        style: TextStyle(
                          fontFamily: AppTheme.fontPoppins,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDisabled ? Colors.grey : Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        drill.skill,
                        style: TextStyle(
                          fontFamily: AppTheme.fontPoppins,
                          fontSize: 12,
                          color: isDisabled ? Colors.grey : AppTheme.primaryGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${drill.sets} sets • ${drill.reps} reps • ${drill.duration} min',
                        style: TextStyle(
                          fontFamily: AppTheme.fontPoppins,
                          fontSize: 11,
                          color: isDisabled ? Colors.grey : AppTheme.primaryGray,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Status indicator
                if (isPreSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Already added',
                      style: TextStyle(
                        fontFamily: AppTheme.fontPoppins,
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (isDisabled)
                  const Text(
                    'Not available',
                    style: TextStyle(
                      fontFamily: AppTheme.fontPoppins,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  )
                else
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
} 