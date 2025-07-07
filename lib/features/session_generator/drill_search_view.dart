import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/drill_model.dart';
import '../../services/app_state_service.dart';
import '../../services/test_data_service.dart';
import '../../constants/app_theme.dart';
import '../../widgets/drill_card_widget.dart';
import 'drill_detail_view.dart';

class DrillSearchView extends StatefulWidget {
  const DrillSearchView({Key? key}) : super(key: key);

  @override
  State<DrillSearchView> createState() => _DrillSearchViewState();
}

class _DrillSearchViewState extends State<DrillSearchView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _searchQuery = '';
  String? _selectedSkillFilter;
  String? _selectedDifficultyFilter;
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Load initial results
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
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreResults();
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

  void _loadMoreResults() {
    final appState = Provider.of<AppStateService>(context, listen: false);
    if (appState.hasMoreSearchResults && !appState.isLoadingMore) {
      appState.loadMoreSearchResults();
    }
  }

  @override
  Widget build(BuildContext context) {
        return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
          appBar: AppBar(
        title: const Text(
          'Search Drills',
          style: AppTheme.titleLarge,
        ),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        actions: [
          Consumer<AppStateService>(
            builder: (context, appState, child) {
              if (appState.isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryYellow,
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ],
          ),
          body: Column(
            children: [
          // Search Header
          _buildSearchHeader(),
          
          // Filters
          _buildFilters(),
          
          // Search Results
          Expanded(
            child: _buildSearchResults(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
                child: Column(
                  children: [
          // Search Bar
          TextField(
                        controller: _searchController,
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
            decoration: InputDecoration(
              hintText: 'Search drills...',
              hintStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.primaryGray),
              prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGray),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppTheme.primaryGray),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                        _performSearch();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppTheme.lightGray,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMedium,
                vertical: AppTheme.spacingSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
      child: Row(
        children: [
          // Skill Filter
          Expanded(
            child: _buildFilterDropdown(
              label: 'Skill',
              value: _selectedSkillFilter,
              items: ['All Skills', ...TestDataService.getAvailableSkills()],
              allValue: 'All Skills',
              onChanged: (value) {
                setState(() {
                  _selectedSkillFilter = value == 'All Skills' ? null : value;
                });
                _performSearch();
              },
            ),
          ),
          
          const SizedBox(width: AppTheme.spacingSmall),
          
          // Difficulty Filter
          Expanded(
            child: _buildFilterDropdown(
              label: 'Difficulty',
              value: _selectedDifficultyFilter,
              items: TestDataService.getAvailableDifficulties(),
              allValue: 'All Levels',
              onChanged: (value) {
                setState(() {
                  _selectedDifficultyFilter = value == 'All Levels' ? null : value;
                });
                _performSearch();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required String allValue,
    required Function(String?) onChanged,
  }) {
    // Ensure the value matches one of the items
    final displayValue = value ?? allValue;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.primaryGray.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text(
            label,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.primaryGray),
          ),
          value: displayValue,
          isExpanded: true,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: AppTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            // Convert "All" options back to null for filtering
            if (newValue == allValue) {
              onChanged(null);
            } else {
              onChanged(newValue);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Consumer<AppStateService>(
      builder: (context, appState, child) {
        return Column(
          children: [
            // Results Header
            _buildResultsHeader(appState),
            
            // Results List
              Expanded(
              child: _buildResultsList(appState),
              ),
            ],
        );
      },
    );
  }

  Widget _buildResultsHeader(AppStateService appState) {
    if (appState.isLoading && !appState.hasSearchResults) {
      return const SizedBox(); // Don't show header while initial loading
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMedium,
        vertical: AppTheme.spacingSmall,
      ),
      child: Row(
        children: [
          Text(
            '${appState.totalSearchResults} drill${appState.totalSearchResults == 1 ? '' : 's'} found',
            style: AppTheme.labelLarge.copyWith(color: AppTheme.primaryGray),
          ),
          const Spacer(),
          if (appState.totalSearchPages > 1)
            Text(
              'Page ${appState.currentSearchPage} of ${appState.totalSearchPages}',
              style: AppTheme.labelMedium.copyWith(color: AppTheme.primaryGray),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsList(AppStateService appState) {
    // Initial loading state
    if (appState.isLoading && !appState.hasSearchResults) {
      return _buildLoadingView();
    }

    // Error state
    if (appState.lastError != null && !appState.hasSearchResults) {
      return _buildErrorView(appState.lastError!);
    }

    // Empty state
    if (!appState.hasSearchResults && !appState.isLoading) {
      return _buildEmptyView();
    }

    // Results list with pagination
    return RefreshIndicator(
      onRefresh: () async {
        await appState.refreshSearch();
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        itemCount: appState.searchResults.length + (appState.hasMoreSearchResults ? 1 : 0),
        itemBuilder: (context, index) {
          // Load more indicator
          if (index == appState.searchResults.length) {
            return _buildLoadMoreIndicator(appState);
          }

          final drill = appState.searchResults[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
            child: _buildDrillCard(drill, appState),
          );
        },
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.primaryYellow,
          ),
          SizedBox(height: AppTheme.spacingMedium),
          Text(
            'Loading drills...',
            style: AppTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreIndicator(AppStateService appState) {
    if (appState.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(AppTheme.spacingLarge),
        child: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryYellow,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingMedium),
      child: ElevatedButton(
        onPressed: _loadMoreResults,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryYellow,
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMedium),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
        child: const Text(
          'Load More Drills',
          style: AppTheme.buttonTextMedium,
        ),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.error,
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              'Oops! Something went wrong',
              style: AppTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              error,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.primaryGray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            ElevatedButton(
              onPressed: _performSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryYellow,
              ),
              child: const Text(
                'Try Again',
                style: AppTheme.buttonTextMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
      return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              'No drills found',
              style: AppTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'Try adjusting your search terms or filters'
                  : 'No drills match your current filters',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.primaryGray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDrillDetail(DrillModel drill) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DrillDetailView(drill: drill),
      ),
    );
  }

  void _addDrillToSession(DrillModel drill) {
    final appState = Provider.of<AppStateService>(context, listen: false);
    appState.addDrillToSession(drill);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${drill.title} added to session'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildDrillCard(DrillModel drill, AppStateService appState) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: InkWell(
        onTap: () => _navigateToDrillDetail(drill),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Row(
            children: [
              // Skill icon/color indicator
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.getSkillColor(drill.skill),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const SizedBox(width: AppTheme.spacingMedium),
              
              // Drill info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drill.title,
                      style: AppTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildChip(drill.skill, AppTheme.getSkillColor(drill.skill)),
                        const SizedBox(width: 8),
                        _buildChip(drill.difficulty, AppTheme.primaryGray),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      drill.description,
                      style: AppTheme.bodySmall.copyWith(color: AppTheme.primaryGray),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Action button
              Column(
                children: [
                  Text(
                    '${drill.duration}min',
                    style: AppTheme.labelMedium.copyWith(color: AppTheme.primaryGray),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: appState.isDrillInSession(drill) 
                        ? null 
                        : () => _addDrillToSession(drill),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appState.isDrillInSession(drill) 
                          ? AppTheme.primaryGray 
                          : AppTheme.primaryYellow,
                      minimumSize: const Size(60, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                    ),
                    child: Text(
                      appState.isDrillInSession(drill) ? 'Added' : 'Add',
                      style: AppTheme.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: AppTheme.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
} 