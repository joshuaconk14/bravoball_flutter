import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../utils/haptic_utils.dart';
import '../features/onboarding/onboarding_flow.dart';
import '../views/main_tab_view.dart';

class GuestAccountOverlay extends StatelessWidget {
  final String title;
  final String description;
  final Color themeColor;
  final bool showDismissButton;

  const GuestAccountOverlay({
    Key? key,
    this.title = 'Create an account',
    this.description = 'Unlock all features by creating an account.',
    this.themeColor = AppTheme.primaryYellow,
    this.showDismissButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_circle_outlined,
                size: 50,
                color: themeColor,
              ),
              const SizedBox(height: 15),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: AppTheme.fontPoppins,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTheme.fontPoppins,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  HapticUtils.mediumImpact(); // Medium haptic for major action
                  // Navigate to onboarding flow (create account page)
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const OnboardingFlow()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Create Account',
                  style: TextStyle(
                    fontFamily: AppTheme.fontPoppins,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (showDismissButton) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    HapticUtils.lightImpact(); // Light haptic for button press
                    // Navigate to main home page
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const MainTabView(initialIndex: 0)),
                      (route) => false,
                    );
                  },
                  child: const Text(
                    'Continue as Guest',
                    style: TextStyle(
                      fontFamily: AppTheme.fontPoppins,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryGray,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Show the overlay as a modal
  static void show({
    required BuildContext context,
    String title = 'Create an account',
    String description = 'Unlock all features by creating an account.',
    Color themeColor = AppTheme.primaryYellow,
    bool showDismissButton = true,
  }) {
    showDialog(
      context: context,
      barrierDismissible: showDismissButton,
      builder: (context) => GuestAccountOverlay(
        title: title,
        description: description,
        themeColor: themeColor,
        showDismissButton: showDismissButton,
      ),
    );
  }
} 