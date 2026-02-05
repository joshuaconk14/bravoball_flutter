import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../services/user_manager_service.dart';
import '../../services/login_service.dart';
import '../../widgets/bravo_button.dart';
import '../onboarding/onboarding_flow.dart';
import '../../utils/haptic_utils.dart';
import 'edit_details_view.dart';
import 'change_password_view.dart';
import 'avatar_selection_view.dart'; // ✅ ADDED: Import avatar selection view

class AccountSettingsView extends StatelessWidget {
  const AccountSettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        title: const Text(
          'Manage Account',
          style: AppTheme.titleLarge,
        ),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryDark),
          onPressed: () {
            HapticUtils.lightImpact();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Profile Settings Section
              _buildSection(
                title: 'Profile Settings',
                items: [
                  _buildMenuItem(
                    icon: Icons.face_outlined,
                    title: 'Change Avatar',
                    subtitle: 'Select your profile picture',
                    onTap: () {
                      HapticUtils.lightImpact();
                      _handleChangeAvatar(context);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.edit_outlined,
                    title: 'Edit your details',
                    subtitle: 'Update your personal information',
                    onTap: () {
                      HapticUtils.lightImpact();
                      _handleEditDetails(context);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    subtitle: 'Update your account password',
                    onTap: () {
                      HapticUtils.lightImpact();
                      _handleChangePassword(context);
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Account Management Section
              _buildSection(
                title: 'Account Management',
                items: [
                  _buildMenuItem(
                    icon: Icons.logout_outlined,
                    title: 'Logout',
                    subtitle: 'Sign out of your account',
                    onTap: () {
                      HapticUtils.mediumImpact();
                      _handleLogout(context);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.delete_forever_outlined,
                    title: 'Delete Account',
                    subtitle: 'Permanently delete your account and all data',
                    isDestructive: true,
                    onTap: () {
                      HapticUtils.heavyImpact();
                      _handleDeleteAccount(context);
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Warning text
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_outlined,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Account deletion is permanent and cannot be undone. All your data will be lost.',
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> items,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
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
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final iconColor = isDestructive ? AppTheme.error : AppTheme.primaryGray;
    final titleColor = isDestructive ? AppTheme.error : AppTheme.primaryDark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.bodyLarge.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.primaryGray,
                      ),
                    ),
                  ],
                ),
              ),
              
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

  void _handleLogout(BuildContext context) {
    _showLogoutConfirmationDialog(context);
  }

  void _handleDeleteAccount(BuildContext context) {
    _showDeleteAccountConfirmationDialog(context);
  }

  void _handleEditDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EditDetailsView(),
      ),
    );
  }

  void _handleChangePassword(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ChangePasswordView(),
      ),
    );
  }

  void _handleChangeAvatar(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AvatarSelectionView(),
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
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
            onPressed: () {
              HapticUtils.lightImpact();
              Navigator.pop(context);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: AppTheme.fontPoppins),
            ),
          ),
          TextButton(
            onPressed: () async {
              HapticUtils.mediumImpact();
              Navigator.pop(context);
              
              // Perform logout and navigate immediately
              final success = await LoginService.shared.logoutUser();
              
              if (success && context.mounted) {
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

  void _showDeleteAccountConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Account',
          style: TextStyle(fontFamily: AppTheme.fontPoppins),
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
          style: TextStyle(fontFamily: AppTheme.fontPoppins),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticUtils.lightImpact();
              Navigator.pop(context);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: AppTheme.fontPoppins),
            ),
          ),
          TextButton(
            onPressed: () async {
              HapticUtils.heavyImpact();
              Navigator.pop(context); // Close confirmation dialog
              
              // Store the navigator context before async operation
              final navigator = Navigator.of(context);
              
              // Show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return const _DeletingAccountDialog();
                },
              );
              
              // Perform account deletion
              final success = await LoginService.shared.deleteAccount();
              
              // Close loading dialog
              if (context.mounted) {
                Navigator.of(context).pop();
              }
              
              if (success) {
                // ✅ FORCE NAVIGATION - Use stored navigator and add delay to ensure cleanup completes
                await Future.delayed(const Duration(milliseconds: 100));
                
                // Force navigation using multiple approaches to ensure it works
                try {
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const OnboardingFlow()),
                    (route) => false,
                  );
                } catch (e) {
                  // If first approach fails, try with current context
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const OnboardingFlow()),
                      (route) => false,
                    );
                  }
                }
              } else if (context.mounted) {
                // Show error message if deletion failed
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to delete account. Please try again.'),
                    backgroundColor: Colors.red,
                  ),
                );
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
}

/// Loading dialog for account deletion - matches GuestAccountCreationDialog design
class _DeletingAccountDialog extends StatelessWidget {
  const _DeletingAccountDialog();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent dismissing with back button
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Container(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Loading spinner in circular container (matches icon design)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.error),
                    strokeWidth: 3.0,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Title (matches guest dialog title style)
              Text(
                'Deleting Account...',
                style: AppTheme.headlineSmall.copyWith(
                  color: AppTheme.primaryDark,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Description (matches guest dialog description style)
              Text(
                'Please wait while we securely remove your account and all associated data.',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.primaryGray,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 