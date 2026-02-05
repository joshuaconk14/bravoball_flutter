import 'package:flutter/material.dart';
import 'package:bravoball_flutter/constants/app_theme.dart';
import 'package:bravoball_flutter/utils/haptic_utils.dart';

/// Reusable confirmation dialog for using store items (streak reviver, streak freeze, etc.)
class ItemUsageConfirmationDialog extends StatelessWidget {
  final String title;
  final String description;
  final String itemName;
  final IconData icon;
  final Color iconColor;
  final String confirmButtonText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isLoading;

  const ItemUsageConfirmationDialog({
    super.key,
    required this.title,
    required this.description,
    required this.itemName,
    required this.icon,
    required this.iconColor,
    this.confirmButtonText = 'Use Item',
    required this.onConfirm,
    this.onCancel,
    this.isLoading = false,
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
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    icon,
                    size: 64,
                    color: iconColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppTheme.fontPoppins,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
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
                    description,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontPoppins,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGray,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          color: iconColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          itemName,
                          style: TextStyle(
                            fontFamily: AppTheme.fontPoppins,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: iconColor,
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
                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () {
                        HapticUtils.mediumImpact();
                        onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: iconColor,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shadowColor: iconColor.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              confirmButtonText,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontPoppins,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Cancel button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: isLoading ? null : () {
                        HapticUtils.lightImpact();
                        Navigator.of(context).pop();
                        onCancel?.call();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                      child: const Text(
                        'Cancel',
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

  /// Show the confirmation dialog
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String description,
    required String itemName,
    required IconData icon,
    required Color iconColor,
    String confirmButtonText = 'Use Item',
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    bool isLoading = false,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: !isLoading,
      builder: (context) => ItemUsageConfirmationDialog(
        title: title,
        description: description,
        itemName: itemName,
        icon: icon,
        iconColor: iconColor,
        confirmButtonText: confirmButtonText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        isLoading: isLoading,
      ),
    );
  }
}

