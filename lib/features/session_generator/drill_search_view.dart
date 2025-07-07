import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/drill_model.dart';
import '../../models/filter_models.dart';
import '../../services/app_state_service.dart';
import '../../widgets/drill_card_widget.dart';
import 'drill_detail_view.dart';

class DrillSearchView extends StatefulWidget {
  const DrillSearchView({Key? key}) : super(key: key);

  @override
  State<DrillSearchView> createState() => _DrillSearchViewState();
}

class _DrillSearchViewState extends State<DrillSearchView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedSkillFilter;
  
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
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Add Drills',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: Colors.black,
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
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search drills...',
                          hintStyle: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.grey,
                          ),
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
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
              
              // Results
              Expanded(
                child: _buildSearchResults(appState),
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
          color: isSelected ? const Color(0xFFF9CC53) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: isSelected ? Colors.black87 : Colors.grey.shade700,
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
      results = appState.drillsNotInSession;
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
                  : 'No more drills available',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
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
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${results.length} drill${results.length == 1 ? '' : 's'} found',
            style: const TextStyle(
              fontFamily: 'Poppins',
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
              return SimpleDrillCard(
                drill: drill,
                onTap: () => _navigateToDrillDetail(context, drill, appState),
                onAdd: () => _addDrillToSession(drill, appState),
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
          onAddToSession: () {
            appState.addDrillToSession(drill);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${drill.title} added to session')),
            );
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _addDrillToSession(DrillModel drill, AppStateService appState) {
    appState.addDrillToSession(drill);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${drill.title} added to session'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'View Session',
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
} 