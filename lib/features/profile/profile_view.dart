import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../config/app_config.dart';
import '../../services/user_manager_service.dart';
import '../../services/login_service.dart';
import '../debug/debug_settings_view.dart';
import '../onboarding/onboarding_flow.dart';
import 'edit_details_view.dart';
import 'change_password_view.dart';
import 'privacy_policy_view.dart';
import 'terms_of_service_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final String appVersion = '1.1.0'; // This would come from package info

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
                      _buildMenuItem(
                        icon: Icons.edit_outlined,
                        title: 'Edit your details',
                        onTap: () => _handleEditDetails(),
                      ),
                      _buildMenuItem(
                        icon: Icons.lock_outline,
                        title: 'Change Password',
                        onTap: () => _handleChangePassword(),
                      ),
                      _buildMenuItem(
                        icon: Icons.share_outlined,
                        title: 'Share With a Friend',
                        onTap: () => _handleShareApp(),
                      ),
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
                        onTap: () => _handleDiscordCommunity(),
                      ),
                      _buildMenuItem(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () => _handlePrivacyPolicy(),
                      ),
                      _buildMenuItem(
                        icon: Icons.description_outlined,
                        title: 'Terms of Service',
                        onTap: () => _handleTermsOfService(),
                      ),
                      _buildMenuItem(
                        icon: Icons.link_outlined,
                        title: 'Follow our Socials',
                        onTap: () => _handleFollowSocials(),
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
                          onTap: () => _handleDebugSettings(),
                        ),
                        _buildDebugMenuItem(
                          icon: Icons.info_outline,
                          title: 'Auth Debug Info',
                          subtitle: userManager.isLoggedIn ? 'Authenticated' : 'Not Authenticated',
                          onTap: () => _showAuthDebugInfo(userManager),
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
                  
                  // Action Buttons
                  _buildActionButtons(),
                  
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
          Container(
            width: 64, // Reduced from 80
            height: 64, // Reduced from 80
            decoration: BoxDecoration(
              color: AppTheme.secondaryBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              size: 36, // Reduced from 48
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 12), // Reduced from 16
          
          // User Email
          Text(
            userManager.email.isNotEmpty ? userManager.email : 'Guest User',
            style: AppTheme.titleLarge.copyWith(
              color: AppTheme.primaryDark,
            ),
          ),
          
          // Login Status
          if (userManager.isLoggedIn) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
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
                  color: Colors.black.withOpacity(0.05),
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12), // Reduced from 16
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6), // Reduced from 8
                decoration: BoxDecoration(
                  color: AppTheme.primaryYellow.withOpacity(0.1),
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

  Widget _buildDebugMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12), // Reduced from 16
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6), // Reduced from 8
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
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

  Widget _buildActionButtons() {
    return Consumer<UserManagerService>(
      builder: (context, userManager, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16), // Reduced from 20
          child: Column(
            children: [
              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handleLogout(userManager),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryYellow,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14), // Reduced from 16
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Logout',
                    style: AppTheme.buttonTextMedium,
                  ),
                ),
              ),
              
              const SizedBox(height: 12), // Reduced from 16
              
              // Delete Account Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handleDeleteAccount(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14), // Reduced from 16
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Delete Account',
                    style: AppTheme.buttonTextMedium,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Action Handlers
  void _handleEditDetails() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EditDetailsView(),
      ),
    );
  }

  void _handleChangePassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ChangePasswordView(),
      ),
    );
  }

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

  void _handleFollowSocials() {
    _showSocialLinksBottomSheet();
  }

  void _handleDeleteAccount() {
    _showDeleteAccountConfirmationDialog();
  }

  void _showDeleteAccountConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Account',
          style: TextStyle(fontFamily: AppTheme.fontPoppins),
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
          style: TextStyle(fontFamily: AppTheme.fontPoppins),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: AppTheme.fontPoppins),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              // Perform account deletion
              final success = await LoginService.shared.deleteAccount();
              
              // Close loading indicator
              if (mounted) {
                Navigator.pop(context);
                
                if (success) {
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account deleted successfully'),
                      backgroundColor: AppTheme.success,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  // Navigate to onboarding and clear stack
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const OnboardingFlow()),
                    (route) => false,
                  );
                } else {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete account. Please try again.'),
                      backgroundColor: AppTheme.error,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                fontFamily: AppTheme.fontPoppins,
                color: AppTheme.error,
              ),
            ),
          ),
        ],
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  void _showComingSoonSnackBar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

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

  void _handleLogout(UserManagerService userManager) {
    _showLogoutConfirmationDialog(userManager);
  }

  void _showLogoutConfirmationDialog(UserManagerService userManager) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Logout',
          style: TextStyle(fontFamily: AppTheme.fontPoppins),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(fontFamily: AppTheme.fontPoppins),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: AppTheme.fontPoppins),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              // Perform logout
              await LoginService.shared.logoutUser();
              
              // Close loading indicator
              if (mounted) {
                Navigator.pop(context);
                // Show success message (optional)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logged out successfully'),
                    backgroundColor: AppTheme.success,
                    duration: Duration(seconds: 2),
                  ),
                );
                // Navigate to onboarding and clear stack
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const OnboardingFlow()),
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(
                fontFamily: AppTheme.fontPoppins,
                color: AppTheme.primaryYellow,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 