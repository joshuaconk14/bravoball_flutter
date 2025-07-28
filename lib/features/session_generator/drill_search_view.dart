import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../models/drill_model.dart';
import '../../services/app_state_service.dart';
import '../../config/app_config.dart';
import '../../constants/app_theme.dart';
import '../../widgets/drill_card_widget.dart';
import 'drill_detail_view.dart';
import '../../models/filter_models.dart';
import '../../utils/haptic_utils.dart';
import '../../utils/skill_utils.dart';
import '../../utils/preference_utils.dart'; // ✅ ADDED: Import centralized preference utilities

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
    
    if (kDebugMode) {
      print('🔍 Performing drill search:');
      print('   Query: "${_searchQuery.isEmpty ? 'empty' : _searchQuery}"');
      print('   Skill Filter: ${_selectedSkillFilter ?? 'none'}');
      print('   Difficulty Filter: ${_selectedDifficultyFilter ?? 'none'}');
      print('   Data Source: ${AppConfig.useTestData ? 'Test Data' : 'Backend API'}');
    }
    
    appState.searchDrillsWithPagination(
      query: _searchQuery.isEmpty ? null : _searchQuery,
      skill: _selectedSkillFilter,
      difficulty: _selectedDifficultyFilter,
    );
  }

  void _loadMoreResults() {
    final appState = Provider.of<AppStateService>(context, listen: false);
    if (appState.hasMoreSearchResults && !appState.isLoadingMore) {
      if (kDebugMode) {
        print('📄 Loading more search results...');
      }
      appState.loadMoreSearchResults();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          // Debug menu button
          if (AppConfig.shouldShowDebugMenu)
            IconButton(
              icon: const Icon(Icons.bug_report, color: Colors.orange),
              onPressed: () => _showDebugInfo(context),
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
              items: const [
                'Passing',
                'Shooting', 
                'Dribbling',
                'First Touch',
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSkillFilter = value;
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
              items: FilterOptions.difficultyOptions, // ✅ UPDATED: Use FilterOptions for consistency
              onChanged: (value) {
                setState(() {
                  _selectedDifficultyFilter = value;
                });
                _performSearch();
              },
            ),
          ),
          
          const SizedBox(width: AppTheme.spacingSmall),
          
          // Clear Filters
          IconButton(
            onPressed: () {
              setState(() {
                _selectedSkillFilter = null;
                _selectedDifficultyFilter = null;
              });
              _performSearch();
            },
            icon: const Icon(Icons.clear_all, color: AppTheme.primaryGray),
            tooltip: 'Clear filters',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTheme.bodySmall.copyWith(color: AppTheme.primaryGray),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingSmall,
          vertical: AppTheme.spacingXSmall,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text('All', style: AppTheme.bodySmall),
        ),
        ...items.map((item) => DropdownMenuItem<String>(
          value: item,
          child: Text(
            label == 'Difficulty' 
                ? PreferenceUtils.formatDifficultyForDisplay(item) 
                : item, // ✅ UPDATED: Use centralized difficulty formatting
            style: AppTheme.bodySmall
          ),
        )),
      ],
      onChanged: onChanged,
      isExpanded: true,
      style: AppTheme.bodySmall,
    );
  }

  Widget _buildSearchResults() {
    return Consumer<AppStateService>(
      builder: (context, appState, child) {
        return Column(
          children: [
            // Results header
            _buildResultsHeader(appState),
            
            // Results content
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
        if (kDebugMode) {
          print('🔄 Refreshing search results...');
        }
        await appState.refreshSearch();
      },
      child: ListView.builder(
        key: const PageStorageKey('drill_search_list'), // Preserve scroll position
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
              color: Colors.red.shade400,
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              'Error loading drills',
              style: AppTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              error,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.primaryGray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            ElevatedButton(
              onPressed: _performSearch,
              child: const Text('Retry'),
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

  Widget _buildLoadMoreIndicator(AppStateService appState) {
    if (appState.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(AppTheme.spacingMedium),
        child: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryYellow,
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Center(
          child: ElevatedButton(
            onPressed: _loadMoreResults,
            child: const Text('Load More'),
          ),
        ),
      );
    }
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
    final success = appState.addDrillToSession(drill);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${drill.title} added to session'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Session limit reached! You can only add up to 10 drills to a session.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
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
                    // Title and difficulty
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            drill.title,
                            style: AppTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.getSkillColor(drill.skill).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            drill.difficulty,
                            style: AppTheme.labelSmall.copyWith(
                              color: AppTheme.getSkillColor(drill.skill),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Skill and duration
                    Row(
                      children: [
                        Text(
                          SkillUtils.formatSkillForDisplay(drill.skill),
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.getSkillColor(drill.skill),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          ' • ${drill.duration}min',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.primaryGray,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Description
                    Text(
                      drill.description,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.primaryGray,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: AppTheme.spacingSmall),
              
              // Add to session button
              IconButton(
                onPressed: appState.isDrillInSession(drill) 
                    ? null 
                    : () {
                        HapticUtils.lightImpact();
                        _addDrillToSession(drill);
                      },
                icon: Icon(
                  appState.isDrillInSession(drill) 
                      ? Icons.check_circle 
                      : Icons.add_circle_outline,
                  color: appState.isDrillInSession(drill) 
                      ? AppTheme.success 
                      : AppTheme.primaryYellow,
                ),
                tooltip: appState.isDrillInSession(drill) 
                    ? 'Already in session' 
                    : 'Add to session',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDebugInfo(BuildContext context) {
    final appState = Provider.of<AppStateService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Environment: ${AppConfig.environmentName}'),
              Text('Base URL: ${AppConfig.baseUrl}'),
              Text('Use Test Data: ${AppConfig.useTestData}'),
              const SizedBox(height: 16),
              Text('Search Results: ${appState.searchResults.length}'),
              Text('Current Page: ${appState.currentSearchPage}'),
              Text('Total Pages: ${appState.totalSearchPages}'),
              Text('Total Results: ${appState.totalSearchResults}'),
              Text('Has More: ${appState.hasMoreSearchResults}'),
              const SizedBox(height: 16),
              Text('Loading: ${appState.isLoading}'),
              Text('Loading More: ${appState.isLoadingMore}'),
              if (appState.lastError != null) ...[
                const SizedBox(height: 16),
                Text('Last Error: ${appState.lastError}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
} 