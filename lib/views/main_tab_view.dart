import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';
import '../features/session_generator/session_generator_home_field_view.dart';
import '../features/progression/progress_view.dart';
import '../features/saved_drills/saved_drills_view.dart';
import '../features/profile/profile_view.dart';
import '../features/create_drill/create_drill_sheet.dart';
import '../constants/app_theme.dart';
import '../utils/haptic_utils.dart';

class MainTabView extends StatefulWidget {
  final int initialIndex;
  
  const MainTabView({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  late int _selectedIndex;

  static final List<Widget> _widgetOptions = <Widget>[
    const SessionGeneratorHomeFieldView(),
    const ProgressView(),
    const SavedDrillsView(),
    const ProfileView(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    HapticUtils.heavyImpact(); // Heavy haptic for major navigation
  }

  void _showCreateDrillSheet() {
    HapticUtils.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateDrillSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade400,
              width: 2.0,
            ),
          ),
        ),
        child: Stack(
          children: [
            BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: AppTheme.primaryYellow,
              unselectedItemColor: Colors.grey.shade600,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              items: [
                BottomNavigationBarItem(
                  icon: _buildRiveTab('Tab_House.riv', 0),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: _buildRiveTab('Tab_Calendar.riv', 1),
                  label: 'Progression',
                ),
                BottomNavigationBarItem(
                  icon: const SizedBox.shrink(), // Placeholder for center button
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: _buildRiveTab('Tab_Saved.riv', 2),
                  label: 'Saved',
                ),
                BottomNavigationBarItem(
                  icon: _buildRiveTab('Tab_Dude.riv', 3),
                  label: 'Profile',
                ),
              ],
              currentIndex: _selectedIndex >= 2 ? _selectedIndex + 1 : _selectedIndex,
              onTap: (index) {
                if (index == 2) {
                  // Center button tapped
                  _showCreateDrillSheet();
                } else if (index > 2) {
                  // Adjust index for right side items
                  _onItemTapped(index - 1);
                } else {
                  // Left side items
                  _onItemTapped(index);
                }
              },
            ),
            // Center create drill button
            Positioned(
              top: -20,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _showCreateDrillSheet,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryYellow,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryYellow.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add,
                      color: AppTheme.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiveTab(String assetName, int index) {
    final isSelected = _selectedIndex == index;
    final size = isSelected ? 32.0 : 24.0; // Bigger when selected
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: size,
      height: size,
      child: RiveAnimation.asset(
        'assets/rive/$assetName',
        fit: BoxFit.contain,
        onInit: (artboard) {
          // Rive asset loaded successfully
          print('Loaded Rive asset: $assetName');
        },
        // Add fallback in case of errors
        placeHolder: Icon(
          _getFallbackIcon(index),
          size: size,
          color: isSelected ? AppTheme.primaryYellow : Colors.grey.shade600,
        ),
      ),
    );
  }

  IconData _getFallbackIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home;
      case 1:
        return Icons.show_chart;
      case 2:
        return Icons.bookmark;
      case 3:
        return Icons.person;
      default:
        return Icons.circle;
    }
  }
} 