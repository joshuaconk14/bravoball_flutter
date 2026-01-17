import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ✅ ADDED: Import for kDebugMode
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';
import '../features/session_generator/session_generator_home_field_view.dart';
import '../features/progression/progress_view.dart';
import '../features/saved_drills/saved_drills_view.dart';
import '../features/profile/profile_view.dart';
import '../features/create_drill/create_drill_sheet.dart';
import '../constants/app_theme.dart';
import '../constants/app_assets.dart';
import '../utils/haptic_utils.dart';
import '../services/app_state_service.dart'; // ✅ ADDED: Import for loading state checking
import '../utils/premium_utils.dart'; // ✅ ADDED: Import premium utils
import '../widgets/guest_account_creation_dialog.dart'; // ✅ ADDED: Import reusable dialog
import '../features/premium/premium_page.dart'; // ✅ ADDED: Import premium page
import '../widgets/offline_banner.dart'; // ✅ ADDED: Import offline banner
import 'package:provider/provider.dart'; // ✅ ADDED: Import for Provider

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

  void _showCreateDrillSheet() async {
    HapticUtils.mediumImpact();
    
    // ✅ ADDED: Check for guest mode and show account creation dialog
    final appState = Provider.of<AppStateService>(context, listen: false);
    if (appState.isGuestMode) {
      GuestAccountCreationDialog.show(
        context: context,
        title: 'Create Account Required',
        description: 'Custom drills are saved to your personal account. Create an account to save and access your drills across all devices.',
        themeColor: AppTheme.primaryYellow,
        icon: Icons.account_circle_outlined,
        showContinueAsGuest: true, // ✅ UPDATED: Show continue as guest option
        continueAsGuestText: 'Continue as Guest',
      );
      return;
    }
    
    // ✅ ADDED: Check premium access for unlimited custom drills
    final hasPremium = await PremiumUtils.instance.hasPremiumAccess();
    
    if (!hasPremium) {
      if (kDebugMode) {
        print('🔒 Premium required for custom drill creation');
      }
      _showCustomDrillLimitUpgradePrompt();
      return;
    }
    
    // Show create drill sheet for authenticated users with remaining custom drill quota
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateDrillSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateService>(
      builder: (context, appState, child) {
        // Show loading screen while initial data is being fetched
        if (appState.isInitialLoad) {
          return _buildLoadingScreen();
        }
        
        return Scaffold(
          body: Column(
            children: [
              // ✅ ADDED: Offline banner at the top
              const OfflineBanner(),
              // Main content
              Expanded(
                child: _widgetOptions[_selectedIndex],
              ),
            ],
          ),
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
          clipBehavior: Clip.none, // ✅ ADDED: Allow overflow so button isn't clipped
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
                  icon: _buildRiveTab(AppAssets.tabHouse, 0),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: _buildRiveTab(AppAssets.tabCalendar, 1),
                  label: 'Progression',
                ),
                BottomNavigationBarItem(
                  icon: const SizedBox.shrink(), // Placeholder for center button
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: _buildRiveTab(AppAssets.tabSaved, 2),
                  label: 'Saved',
                ),
                BottomNavigationBarItem(
                  icon: _buildRiveTab(AppAssets.tabDude, 3),
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
              top: -20, // ✅ LOWERED: Moved from -30 to -20 to avoid blocking toast messages
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _showCreateDrillSheet,
                  child: Container(
                    width: 64, // ✅ REDUCED: Made slightly smaller
                    height: 64, // ✅ REDUCED: Made slightly smaller
                    decoration: BoxDecoration(
                      // ✅ UPDATED: Fun solid color with effects
                      color: AppTheme.primaryYellow,
                      shape: BoxShape.circle,
                      // ✅ ADDED: Subtle border for depth
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 3,
                      ),
                    ),
                    // ✅ SIMPLIFIED: Just the plus icon, no background effects
                    child: const Icon(
                      Icons.add,
                      color: AppTheme.white,
                      size: 42, // ✅ INCREASED: Made slightly bigger
                    ),
                  ),
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

  // Loading screen shown while backend data is being fetched
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo/Animation placeholder
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: Icon(
                Icons.sports_soccer,
                size: 60,
                color: AppTheme.primaryYellow,
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingLarge),
            
            // App Name
            Text(
              'BravoBall',
              style: AppTheme.headlineLarge.copyWith(
                color: AppTheme.primaryYellow,
                fontSize: 36,
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingMedium),
            
            // Loading indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryYellow),
              strokeWidth: 3,
            ),
            
            const SizedBox(height: AppTheme.spacingMedium),
            
            Text(
              'Loading your training data...',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.primaryGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiveTab(String assetPath, int index) {
    final isSelected = _selectedIndex == index;
    final size = isSelected ? 32.0 : 24.0; // Bigger when selected
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: size,
      height: size,
      child: RiveAnimation.asset(
        assetPath,
        fit: BoxFit.contain,
        onInit: (artboard) {
          // Rive asset loaded successfully
          print('Loaded Rive asset: $assetPath');
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

  /// Show custom drill limit upgrade prompt
  void _showCustomDrillLimitUpgradePrompt() {
    // Check if widget is still mounted before navigating
    if (!mounted) {
      if (kDebugMode) {
        print('⚠️ Widget unmounted, cannot navigate to premium page');
      }
      return;
    }
    
    // Navigate to premium page instead of showing dialog
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PremiumPage(),
      ),
    );
  }
} 