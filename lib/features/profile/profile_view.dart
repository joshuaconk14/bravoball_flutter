import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../config/app_config.dart';
import '../../services/user_manager_service.dart';
import '../../services/app_state_service.dart'; // ✅ ADDED: Import AppStateService for friend request count
import '../../widgets/badge_widget.dart'; // ✅ ADDED: Import badge widget
import '../../utils/avatar_helper.dart'; // ✅ ADDED: Import avatar helper
import '../debug/debug_settings_view.dart';
import '../onboarding/onboarding_flow.dart';
import 'privacy_policy_view.dart';
import 'terms_of_service_view.dart';
import 'credits_view.dart';
import 'account_settings_view.dart'; // ✅ ADDED: Import AccountSettingsView
import '../friends/friends_view.dart'; // ✅ ADDED: Import FriendsView
import '../saved_drills/saved_drills_view.dart'; // ✅ ADDED: Import SavedDrillsView
import '../../utils/haptic_utils.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> with WidgetsBindingObserver {
  final String appVersion = '2.0.2'; // This would come from package info

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // ✅ ADDED: Refresh friend request count when ProfileView opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshFriendRequestCount();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // ✅ ADDED: Refresh count when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _refreshFriendRequestCount();
    }
  }

  // ✅ ADDED: Helper method to refresh friend request count
  void _refreshFriendRequestCount() {
    final appState = Provider.of<AppStateService>(context, listen: false);
    if (!appState.isGuestMode) {
      appState.refreshFriendRequestCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserManagerService>(
      builder: (context, userManager, child) {
        return Scaffold(
          backgroundColor: AppTheme.lightGray,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header Section
                  _buildHeader(userManager),
                  
                  const SizedBox(height: 20), // Reduced from 32
                  
                  // Account Section
                  _buildSection(
                    title: 'Account',
                    items: [
                      // ✅ UPDATED: Simplified account section - everything consolidated under Manage Account
                      if (!context.read<UserManagerService>().isGuestMode) ...[
                        _buildMenuItem(
                          icon: Icons.settings_outlined,
                          title: 'Manage Account',
                          onTap: () {
                            HapticUtils.lightImpact(); // Light haptic for account settings
                            _handleAccountSettings();
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.bookmark_outlined,
                          title: 'Saved Drills',
                          onTap: () {
                            HapticUtils.lightImpact(); // Light haptic for saved drills
                            _handleSavedDrills();
                          },
                        ),
                        Consumer<AppStateService>(
                          builder: (context, appState, child) {
                            return _buildMenuItemWithBadge(
                              icon: Icons.people_outlined,
                              title: 'Friends',
                              badgeCount: appState.friendRequestCount,
                              showBadge: appState.hasFriendRequests && !appState.isGuestMode,
                              onTap: () {
                                HapticUtils.lightImpact(); // Light haptic for friends
                                _handleFriends();
                              },
                            );
                          },
                        ),
                      ] else ...[
                        _buildMenuItem(
                          icon: Icons.account_circle_outlined,
                          title: 'Create Account',
                          onTap: () {
                            HapticUtils.mediumImpact(); // Medium haptic for major action
                            _handleCreateAccount();
                          },
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 16), // Reduced from 24
                  
                  // Support Section
                  _buildSection(
                    title: 'Support',
                    items: [
                      _buildMenuItem(
                        icon: Icons.chat_outlined,
                        title: 'Join our Discord',
                        onTap: () {
                          HapticUtils.lightImpact(); // Light haptic for community access
                          _handleDiscordCommunity();
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.share_outlined,
                        title: 'Share With a Friend',
                        onTap: () {
                          HapticUtils.lightImpact(); // Light haptic for sharing
                          _handleShareApp();
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.link_outlined,
                        title: 'Follow our Socials',
                        onTap: () {
                          HapticUtils.lightImpact(); // Light haptic for social links
                          _handleFollowSocials();
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16), // Reduced from 24
                  
                  // Other Section
                  _buildSection(
                    title: 'Other',
                    items: [
                      _buildMenuItem(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () {
                          HapticUtils.lightImpact(); // Light haptic for privacy policy
                          _handlePrivacyPolicy();
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.description_outlined,
                        title: 'Terms of Service',
                        onTap: () {
                          HapticUtils.lightImpact(); // Light haptic for terms of service
                          _handleTermsOfService();
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.attribution_outlined,
                        title: 'Credits & Attributions',
                        onTap: () {
                          HapticUtils.lightImpact();
                          _handleCredits();
                        },
                      ),
                    ],
                  ),
                  
                  // Debug Section (only show in debug mode)
                  if (AppConfig.shouldShowDebugMenu) ...[
                    const SizedBox(height: 16), // Reduced from 24
                    _buildSection(
                      title: 'Developer',
                      items: [
                        _buildDebugMenuItem(
                          icon: Icons.bug_report,
                          title: 'Debug Settings',
                          subtitle: AppConfig.useTestData ? 'Test Mode' : 'Backend Mode',
                          onTap: () {
                            HapticUtils.lightImpact(); // Light haptic for debug settings
                            _handleDebugSettings();
                          },
                        ),
                        _buildDebugMenuItem(
                          icon: Icons.info_outline,
                          title: 'Auth Debug Info',
                          subtitle: userManager.isLoggedIn ? 'Authenticated' : 'Not Authenticated',
                          onTap: () {
                            HapticUtils.lightImpact(); // Light haptic for debug info
                            _showAuthDebugInfo(userManager);
                          },
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 20), // Reduced from 32
                  
                  // Version Info
                  Text(
                    'Version $appVersion',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.primaryGray,
                    ),
                  ),
                  
                  const SizedBox(height: 20), // Reduced from 32
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(UserManagerService userManager) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20), // Reduced from 32
      child: Column(
        children: [
          const SizedBox(height: 12), // Reduced from 20
          
          // Profile Avatar
          Consumer<UserManagerService>(
            builder: (context, userManager, child) {
              final avatarPath = userManager.selectedAvatar ?? AvatarHelper.getDefaultAvatar();
              final bgColor = userManager.avatarBackgroundColor ?? 
                  AvatarHelper.getDefaultBackgroundColor();
              
              return Container(
                width: 64, // Reduced from 80
                height: 64, // Reduced from 80
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bgColor,
                  border: Border.all(
                    color: AppTheme.primaryYellow,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    avatarPath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to default icon if image fails to load
                      return Container(
                        color: bgColor,
                        child: const Icon(
                          Icons.person,
                          size: 36,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 12), // Reduced from 16

          Column(
            children: [
              // ✅ Username
              if (userManager.username.isNotEmpty)
                Text(
                  userManager.username,
                  style: AppTheme.titleLarge.copyWith(
                    color: AppTheme.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              const SizedBox(height: 4), // small spacing between username and email

              // ✅ Email
              Text(
                userManager.email.isNotEmpty ? userManager.email : 'Guest User',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.primaryGray,
                ),
              ),
            ],
          ),
          
          // Login Status
          if (userManager.isLoggedIn) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Authenticated',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> items,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16), // Reduced from 20
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8), // Reduced bottom from 12
            child: Text(
              title,
              style: AppTheme.titleMedium.copyWith(
                color: AppTheme.primaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Section Items
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                
                return Column(
                  children: [
                    item,
                    if (index < items.length - 1)
                      Divider(
                        height: 1,
                        color: Colors.grey.shade200,
                        indent: 16,
                        endIndent: 16,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticUtils.lightImpact(); // Light haptic for profile item interaction
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12), // Reduced from 16
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6), // Reduced from 8
                decoration: BoxDecoration(
                  color: AppTheme.primaryYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryYellow,
                  size: 18, // Reduced from 20
                ),
              ),
              
              const SizedBox(width: 12), // Reduced from 16
              
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.primaryDark,
                  ),
                ),
              ),
              
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.primaryGray,
                size: 14, // Reduced from 16
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ ADDED: Menu item with badge support
  Widget _buildMenuItemWithBadge({
    required IconData icon,
    required String title,
    required int badgeCount,
    required bool showBadge,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticUtils.lightImpact(); // Light haptic for profile item interaction
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12), // Reduced from 16
          child: Row(
            children: [
              BadgeWidget(
                count: badgeCount,
                showBadge: showBadge,
                badgeSize: 14.0,
                child: Container(
                  padding: const EdgeInsets.all(6), // Reduced from 8
                  decoration: BoxDecoration(
                    color: AppTheme.primaryYellow.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryYellow,
                    size: 18, // Reduced from 20
                  ),
                ),
              ),
              
              const SizedBox(width: 12), // Reduced from 16
              
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.primaryDark,
                  ),
                ),
              ),
              
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.primaryGray,
                size: 14, // Reduced from 16
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebugMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticUtils.lightImpact(); // Light haptic for profile item interaction
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12), // Reduced from 16
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6), // Reduced from 8
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.orange,
                  size: 18, // Reduced from 20
                ),
              ),
              
              const SizedBox(width: 12), // Reduced from 16
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.bodyLarge.copyWith(
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTheme.bodySmall.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.primaryGray,
                size: 14, // Reduced from 16
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Action Handlers

  void _handleShareApp() {
    const shareText = 'Check out BravoBall - Your personal soccer training companion!\n\nDownload it here: https://apps.apple.com/app/bravoball';
    
    Clipboard.setData(const ClipboardData(text: shareText));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('App link copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleDiscordCommunity() {
    _launchUrl('https://discord.gg/5afDtqdD');
  }

  void _handlePrivacyPolicy() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyView(),
      ),
    );
  }

  void _handleTermsOfService() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TermsOfServiceView(),
      ),
    );
  }

  void _handleCredits() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreditsView(),
      ),
    );
  }

  void _handleFollowSocials() {
    _showSocialLinksBottomSheet();
  }

  // ✅ NEW: Handle create account for guest users
  void _handleCreateAccount() {
    // Navigate to onboarding flow
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const OnboardingFlow()),
      (route) => false,
    );
  }

  void _handleAccountSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AccountSettingsView(),
      ),
    );
  }

  void _handleSavedDrills() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SavedDrillsView(),
      ),
    );
  }

  void _handleFriends() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FriendsView(),
      ),
    );
  }

  void _handleDebugSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DebugSettingsView(),
      ),
    );
  }

  void _showAuthDebugInfo(UserManagerService userManager) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Debug Info'),
        content: SingleChildScrollView(
          child: Text(
            userManager.debugInfo,
            style: const TextStyle(
              fontFamily: 'Courier',
              fontSize: 12,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticUtils.lightImpact(); // Light haptic for close
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  void _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch URL'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showSocialLinksBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Follow Us',
                style: AppTheme.titleLarge.copyWith(
                  color: AppTheme.primaryDark,
                ),
              ),
              const SizedBox(height: 20),
              
              _buildSocialLink('Instagram', 'https://instagram.com/bravoball'),
              _buildSocialLink('Twitter', 'https://twitter.com/bravoball'),
              _buildSocialLink('Facebook', 'https://facebook.com/bravoball'),
              _buildSocialLink('YouTube', 'https://youtube.com/bravoball'),
              
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSocialLink(String platform, String url) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticUtils.lightImpact(); // Light haptic for tap to close
          Navigator.pop(context);
          _launchUrl(url);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              Icon(
                Icons.link,
                color: AppTheme.primaryYellow,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                platform,
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.primaryDark,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.primaryGray,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 