import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../utils/haptic_utils.dart';
import '../features/onboarding/onboarding_flow.dart';
import '../views/main_tab_view.dart';

class GuestAccountCreationDialog extends StatelessWidget {
  final String title;
  final String description;
  final Color themeColor;
  final IconData icon;
  final bool showContinueAsGuest;
  final String continueAsGuestText;
  final VoidCallback? onContinueAsGuest;

  const GuestAccountCreationDialog({
    Key? key,
    this.title = 'Great Job!',
    this.description = 'Create an account to save your progress and track your streak.',
    this.themeColor = AppTheme.primaryYellow,
    this.icon = Icons.celebration,
    this.showContinueAsGuest = true,
    this.continueAsGuestText = 'Continue as Guest',
    this.onContinueAsGuest,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: Container(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: themeColor,
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Text(
              title,
              style: AppTheme.headlineSmall.copyWith(
                color: AppTheme.primaryDark,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Description
            Text(
              description,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.primaryGray,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Buttons
            Column(
              children: [
                // Create Account button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticUtils.mediumImpact();
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const OnboardingFlow()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Create Account',
                      style: AppTheme.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (showContinueAsGuest) ...[
                  const SizedBox(height: 12),
                  // Continue as Guest button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        HapticUtils.lightImpact();
                        Navigator.of(context).pop(); // Close dialog
                        if (onContinueAsGuest != null) {
                          onContinueAsGuest!();
                        } else {
                          // Default behavior: navigate to home
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const MainTabView(initialIndex: 0),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        continueAsGuestText,
                        style: AppTheme.labelLarge.copyWith(
                          color: AppTheme.primaryGray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Show the dialog with custom parameters
  static Future<void> show({
    required BuildContext context,
    String title = 'Great Job!',
    String description = 'Create an account to save your progress and track your streak.',
    Color themeColor = AppTheme.primaryYellow,
    IconData icon = Icons.celebration,
    bool showContinueAsGuest = true,
    String continueAsGuestText = 'Continue as Guest',
    VoidCallback? onContinueAsGuest,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Force user to make a choice
      builder: (context) => GuestAccountCreationDialog(
        title: title,
        description: description,
        themeColor: themeColor,
        icon: icon,
        showContinueAsGuest: showContinueAsGuest,
        continueAsGuestText: continueAsGuestText,
        onContinueAsGuest: onContinueAsGuest,
      ),
    );
  }
} 