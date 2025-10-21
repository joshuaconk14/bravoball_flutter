import 'package:flutter/material.dart';
import 'package:bravoball_flutter/constants/app_theme.dart';
import 'package:bravoball_flutter/utils/haptic_utils.dart';

/// Dialog shown when a user loses their streak
/// Offers option to restore it using a streak reviver
class StreakLossDialog extends StatelessWidget {
  final int previousStreak;
  final VoidCallback? onRestore;
  final VoidCallback? onDismiss;

  const StreakLossDialog({
    super.key,
    required this.previousStreak,
    this.onRestore,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 8,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with icon
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.secondaryOrange.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.heart_broken,
                    size: 64,
                    color: AppTheme.secondaryOrange,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Streak Lost!',
                    style: TextStyle(
                      fontFamily: AppTheme.fontPoppins,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryOrange,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'You lost your streak!',
                    style: TextStyle(
                      fontFamily: AppTheme.fontPoppins,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your previous streak was $previousStreak ${previousStreak == 1 ? 'day' : 'days'}',
                    style: TextStyle(
                      fontFamily: AppTheme.fontPoppins,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.secondaryOrange,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryYellow.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryYellow.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.restore,
                          color: AppTheme.primaryYellow,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Use a Streak Reviver to restore your streak!',
                            style: TextStyle(
                              fontFamily: AppTheme.fontPoppins,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Buttons
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
              child: Column(
                children: [
                  // Restore button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticUtils.mediumImpact();
                        Navigator.of(context).pop();
                        onRestore?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryYellow,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shadowColor: AppTheme.primaryYellow.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restore, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Restore Streak',
                            style: TextStyle(
                              fontFamily: AppTheme.fontPoppins,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Dismiss button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        HapticUtils.lightImpact();
                        Navigator.of(context).pop();
                        onDismiss?.call();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                      child: Text(
                        'Maybe Later',
                        style: TextStyle(
                          fontFamily: AppTheme.fontPoppins,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show the streak loss dialog
  static Future<void> show(
    BuildContext context, {
    required int previousStreak,
    VoidCallback? onRestore,
    VoidCallback? onDismiss,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StreakLossDialog(
        previousStreak: previousStreak,
        onRestore: onRestore,
        onDismiss: onDismiss,
      ),
    );
  }
}
