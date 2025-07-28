import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/drill_model.dart';
import '../models/filter_models.dart'; // ✅ ADDED: Import filter models for FilterOptions
import '../services/app_state_service.dart';
import '../constants/app_theme.dart';
import '../utils/haptic_utils.dart';
import '../utils/skill_utils.dart'; // ✅ ADDED: Import centralized skill utilities
import '../utils/preference_utils.dart'; // ✅ ADDED: Import centralized preference utilities
import '../features/session_generator/drill_detail_view.dart';

class ReusableDrillSearchView extends StatefulWidget {
  final String title;
  final String actionButtonText;
  final Function(List<DrillModel>) onDrillsSelected;
  final Function(DrillModel)? isDisabled;
  final Function(DrillModel)? isSelected;
  final bool allowMultipleSelection;
  final Color themeColor;

  const ReusableDrillSearchView({
    Key? key,
    required this.title,
    required this.actionButtonText,
    required this.onDrillsSelected,
    this.isDisabled,
    this.isSelected,
    this.allowMultipleSelection = true,
    required this.themeColor,
  });

  @override
  State<ReusableDrillSearchView> createState() => _ReusableDrillSearchViewState();
}

class _ReusableDrillSearchViewState extends State<ReusableDrillSearchView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  String? _selectedSkillFilter;
  String? _selectedDifficultyFilter;
  final Set<DrillModel> _selectedDrills = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performSearch();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final appState = Provider.of<AppStateService>(context, listen: false);
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      if (appState.hasMoreSearchResults && !appState.isLoadingMore) {
        appState.loadMoreSearchResults();
      }
    }
  }

  void _performSearch() {
    final appState = Provider.of<AppStateService>(context, listen: false);
    appState.searchDrillsWithPagination(
      query: _searchQuery.isEmpty ? null : _searchQuery,
      skill: _selectedSkillFilter,
      difficulty: _selectedDifficultyFilter,
    );
  }

  Widget _buildSkillFilterDropdown() {
    // You may want to get this list from your SkillCategories if available
    const skills = [
      'Passing', 'Shooting', 'Dribbling', 'First Touch', 'Defending', 'Goalkeeping', 'Fitness'
    ];
    return Expanded(
      child: DropdownButtonFormField<String>(
        value: _selectedSkillFilter,
        decoration: InputDecoration(
          labelText: 'Skill',
          labelStyle: TextStyle(color: widget.themeColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: widget.themeColor),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items: [
          DropdownMenuItem<String>(
            value: null,
            child: Text('All', style: TextStyle(color: widget.themeColor)),
          ),
          ...skills.map((skill) => DropdownMenuItem<String>(
            value: skill,
            child: Text(skill, style: TextStyle(color: widget.themeColor)),
          )),
        ],
        onChanged: (value) {
          HapticUtils.selectionClick(); // Haptic feedback for filter change
          setState(() {
            _selectedSkillFilter = value;
          });
          _performSearch();
        },
        isExpanded: true,
        style: TextStyle(color: widget.themeColor),
      ),
    );
  }

  Widget _buildDifficultyFilterDropdown() {
    return Expanded(
      child: DropdownButtonFormField<String>(
        value: _selectedDifficultyFilter,
        decoration: InputDecoration(
          labelText: 'Difficulty',
          labelStyle: TextStyle(color: widget.themeColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: widget.themeColor),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items: [
          DropdownMenuItem<String>(
            value: null,
            child: Text('All', style: TextStyle(color: widget.themeColor)),
          ),
          ...FilterOptions.difficultyOptions.map((diff) => DropdownMenuItem<String>( // ✅ UPDATED: Use FilterOptions for consistency
            value: diff,
            child: Text(
              PreferenceUtils.formatDifficultyForDisplay(diff), // ✅ UPDATED: Use centralized difficulty formatting
              style: TextStyle(color: widget.themeColor)
            ),
          )),
        ],
        onChanged: (value) {
          HapticUtils.selectionClick(); // Haptic feedback for filter change
          setState(() {
            _selectedDifficultyFilter = value;
          });
          _performSearch();
        },
        isExpanded: true,
        style: TextStyle(color: widget.themeColor),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildSkillFilterDropdown(),
          const SizedBox(width: 8),
          _buildDifficultyFilterDropdown(),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              HapticUtils.lightImpact(); // Haptic feedback for clearing filters
              setState(() {
                _selectedSkillFilter = null;
                _selectedDifficultyFilter = null;
              });
              _performSearch();
            },
            icon: Icon(Icons.clear_all, color: widget.themeColor),
            tooltip: 'Clear filters',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(AppStateService appState) {
    // Use backend paginated results if available, otherwise fallback to local
    final useBackend = appState.searchResults.isNotEmpty || appState.isLoading || appState.isLoadingMore;
    final results = useBackend
        ? appState.searchResults
        : (_searchQuery.isNotEmpty
            ? appState.searchDrills(_searchQuery)
            : (_selectedSkillFilter != null
                ? appState.filterDrillsBySkill(_selectedSkillFilter!)
                : appState.availableDrills));

    // Show loading indicator for initial search (both backend and local)
    if (appState.isLoading && results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(widget.themeColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Searching drills...',
              style: TextStyle(
                fontFamily: AppTheme.fontPoppins,
                fontSize: 16,
                color: widget.themeColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    
    // Show error state for local searches
    if (appState.lastError != null && !useBackend) {
      return Center(child: Text('Error: ${appState.lastError}'));
    }
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No drills found', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text('Try adjusting your search or filters', style: TextStyle(color: Colors.grey.shade600)),
            // ✅ NEW: Guest-specific message when no results
            if (appState.isGuestMode) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Text(
                  'Guest users have access to 4 drills per category. Create an account for full access to 100+ drills!',
                  style: TextStyle(
                    fontFamily: AppTheme.fontPoppins,
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // ✅ NEW: Loading indicator when refreshing with existing results
        if (appState.isLoading && results.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: widget.themeColor.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(widget.themeColor),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Updating results...',
                  style: TextStyle(
                    fontFamily: AppTheme.fontPoppins,
                    fontSize: 12,
                    color: widget.themeColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        
        // ✅ NEW: Guest mode banner
        if (appState.isGuestMode) _buildGuestBanner(results.length),
        
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              _performSearch();
            },
            child: ListView.builder(
              controller: _scrollController,
              itemCount: results.length + (appState.hasMoreSearchResults && !appState.isGuestMode ? 1 : 0), // ✅ No "load more" for guests
              itemBuilder: (context, index) {
                // ✅ UPDATED: Skip "load more" for guests
                if (index == results.length && appState.hasMoreSearchResults && !appState.isGuestMode) {
                  if (appState.isLoadingMore) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: ElevatedButton(
                          onPressed: () {
                            HapticUtils.lightImpact(); // Light haptic for load more
                            appState.loadMoreSearchResults();
                          },
                          child: const Text('Load More'),
                        ),
                      ),
                    );
                  }
                }
                final drill = results[index];
                final isCurrentlySelected = _selectedDrills.contains(drill);
                final isDisabled = widget.isDisabled?.call(drill) ?? false;
                final isPreSelected = widget.isSelected?.call(drill) ?? false;
                return SelectableDrillCard(
                  drill: drill,
                  isSelected: isCurrentlySelected,
                  isDisabled: isDisabled,
                  isPreSelected: isPreSelected,
                  themeColor: widget.themeColor, // ✅ ADDED: Missing themeColor parameter
                  onSelectionChanged: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDrills.add(drill);
                      } else {
                        _selectedDrills.remove(drill);
                      }
                    });
                  },
                  onTap: () {
                    HapticUtils.lightImpact(); // Light haptic for drill selection
                    _navigateToDrillDetail(context, drill, appState);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ✅ NEW: Build guest banner with limitation info
  Widget _buildGuestBanner(int drillCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.purple.shade50],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue.shade600,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Guest access: Showing $drillCount drills. Create an account for 100+ drills!',
              style: TextStyle(
                fontFamily: AppTheme.fontPoppins,
                fontSize: 12,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateService>(
      builder: (context, appState, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: widget.themeColor,
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
                      color: Colors.black.withValues(alpha: 0.05),
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
                        border: Border.all(color: widget.themeColor, width: 2),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontPoppins,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search drills...',
                          hintStyle: const TextStyle(
                            fontFamily: AppTheme.fontPoppins,
                            color: Colors.grey,
                          ),
                          prefixIcon: Icon(Icons.search, color: widget.themeColor),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                          // Debounce search
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (_searchController.text == value) {
                              _performSearch();
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFilters(),
                  ],
                ),
              ),
              if (_selectedDrills.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: widget.themeColor.withValues(alpha: 0.1),
                  child: Text(
                    '${_selectedDrills.length} drill${_selectedDrills.length == 1 ? '' : 's'} selected',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontPoppins,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ),
              Expanded(
                child: _buildSearchResults(appState),
              ),
              if (_selectedDrills.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () {
                      HapticUtils.mediumImpact(); // Medium haptic for major action
                      widget.onDrillsSelected(_selectedDrills.toList());
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.themeColor,
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

  void _navigateToDrillDetail(BuildContext context, DrillModel drill, AppStateService appState) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DrillDetailView(
          drill: drill,
          isInSession: widget.isSelected?.call(drill) ?? false,
          onAddToSession: null, // Not used in this context
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
  final Color themeColor;

  const SelectableDrillCard({
    Key? key,
    required this.drill,
    required this.isSelected,
    required this.isDisabled,
    required this.isPreSelected,
    this.onTap,
    required this.onSelectionChanged,
    required this.themeColor,
  });

  String _getSkillIconPath(String skill) {
    // Normalize the skill name for better matching
    final normalizedSkill = skill.toLowerCase().replaceAll('_', ' ').trim();
    
    switch (normalizedSkill) {
      case 'passing':
        return 'assets/drill-icons/Player_Passing.png';
      case 'shooting':
        return 'assets/drill-icons/Player_Shooting.png';
      case 'dribbling':
        return 'assets/drill-icons/Player_Dribbling.png';
      case 'first touch':
      case 'firsttouch':
        return 'assets/drill-icons/Player_First_Touch.png';
      case 'defending':
        return 'assets/drill-icons/Player_Defending.png';
      case 'goalkeeping':
        return 'assets/drill-icons/Player_Goalkeeping.png';
      case 'fitness':
        return 'assets/drill-icons/Player_Fitness.png';
      default:
        return 'assets/drill-icons/Player_Dribbling.png';
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: isSelected ? themeColor.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
              ? themeColor 
              : isPreSelected 
                  ? themeColor
                  : Colors.grey.shade200,
          width: isSelected || isPreSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                      : () {
                          HapticUtils.selectionClick(); // Selection haptic for checkbox
                          onSelectionChanged(!isSelected);
                        },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? themeColor 
                          : isPreSelected
                              ? themeColor
                              : Colors.transparent,
                      border: Border.all(
                        color: isSelected 
                            ? themeColor 
                            : isPreSelected
                                ? themeColor
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
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.getSkillColor(drill.skill).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.getSkillColor(drill.skill).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Image.asset(
                    _getSkillIconPath(drill.skill),
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to generic icon if image fails to load
                      return Icon(
                        _getSkillIconFallback(drill.skill),
                        color: AppTheme.getSkillColor(drill.skill),
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
                        SkillUtils.formatSkillForDisplay(drill.skill), // ✅ UPDATED: Use centralized skill formatting
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
                      color: themeColor,
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