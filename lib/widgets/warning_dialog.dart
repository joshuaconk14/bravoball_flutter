import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../utils/haptic_utils.dart';

class WarningDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? cancelText;
  final String? continueText;
  final VoidCallback? onCancel;
  final VoidCallback? onContinue;
  final Color? warningColor;
  final IconData? warningIcon;

  const WarningDialog({
    Key? key,
    required this.title,
    required this.content,
    this.cancelText,
    this.continueText,
    this.onCancel,
    this.onContinue,
    this.warningColor,
    this.warningIcon,
  }) : super(key: key);

  // ✅ CONVENIENCE CONSTRUCTOR: For session progress warning
  factory WarningDialog.sessionProgress({
    required int progressDrills,
    required int totalDrills,
    VoidCallback? onCancel,
    VoidCallback? onContinue,
  }) {
    return WarningDialog(
      title: 'Progress may be lost,\nbe careful!',
      content: 'You have progress in $progressDrills of $totalDrills drill${totalDrills == 1 ? '' : 's'}.\n\nChanging your training preferences will reset all progress in your current session.\n\nAdding and removing untouched drills will not affect your progress.',
      cancelText: 'Cancel',
      continueText: 'Continue',
      onCancel: onCancel,
      onContinue: onContinue,
      warningColor: AppTheme.secondaryOrange,
      warningIcon: Icons.warning_amber_rounded,
    );
  }

  // ✅ CONVENIENCE CONSTRUCTOR: For general warnings
  factory WarningDialog.general({
    required String title,
    required String content,
    String? cancelText,
    String? continueText,
    VoidCallback? onCancel,
    VoidCallback? onContinue,
    Color? warningColor,
    IconData? warningIcon,
  }) {
    return WarningDialog(
      title: title,
      content: content,
      cancelText: cancelText ?? 'Cancel',
      continueText: continueText ?? 'Continue',
      onCancel: onCancel,
      onContinue: onContinue,
      warningColor: warningColor ?? AppTheme.secondaryOrange,
      warningIcon: warningIcon ?? Icons.warning_amber_rounded,
    );
  }

  // ✅ STATIC METHOD: Show the warning dialog
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String content,
    String? cancelText,
    String? continueText,
    VoidCallback? onCancel,
    VoidCallback? onContinue,
    Color? warningColor,
    IconData? warningIcon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return WarningDialog(
          title: title,
          content: content,
          cancelText: cancelText,
          continueText: continueText,
          onCancel: onCancel,
          onContinue: onContinue,
          warningColor: warningColor,
          warningIcon: warningIcon,
        );
      },
    );
  }

  // ✅ STATIC METHOD: Show session progress warning
  static Future<bool?> showSessionProgress({
    required BuildContext context,
    required int progressDrills,
    required int totalDrills,
    VoidCallback? onCancel,
    VoidCallback? onContinue,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return WarningDialog.sessionProgress(
          progressDrills: progressDrills,
          totalDrills: totalDrills,
          onCancel: onCancel,
          onContinue: onContinue,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            warningIcon ?? Icons.warning_amber_rounded,
            color: warningColor ?? AppTheme.secondaryOrange,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: AppTheme.fontPoppins,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        content,
        style: TextStyle(
          fontFamily: AppTheme.fontPoppins,
          fontSize: 14,
          color: Colors.black54,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            HapticUtils.lightImpact();
            onCancel?.call();
            Navigator.of(context).pop(false);
          },
          child: Text(
            cancelText ?? 'Cancel',
            style: TextStyle(
              fontFamily: AppTheme.fontPoppins,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryGray,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            HapticUtils.mediumImpact();
            onContinue?.call();
            Navigator.of(context).pop(true);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: warningColor ?? AppTheme.secondaryOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text(
            continueText ?? 'Continue',
            style: TextStyle(
              fontFamily: AppTheme.fontPoppins,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    );
  }
} 