import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/app_state_service.dart';
import '../widgets/streak_loss_dialog.dart';

/// Manages showing streak-related dialogs
/// This keeps dialog logic out of main.dart and makes it reusable
class StreakDialogManager {
  /// Check if user lost their streak and show dialog if needed
  static void checkAndShowStreakLossDialog(BuildContext context) {
    final appState = AppStateService.instance;
    
    // Check if user just lost their streak
    if (appState.hasJustLostStreak) {
      if (kDebugMode) {
        print('💔 Showing streak loss dialog for previous streak: ${appState.previousStreak}');
      }
      
      // Wait for build to complete before showing dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          _showStreakLossDialog(context);
        }
      });
    }
  }

  /// Show the streak loss dialog
  static void _showStreakLossDialog(BuildContext context) {
    final appState = AppStateService.instance;
    
    StreakLossDialog.show(
      context,
      previousStreak: appState.previousStreak,
      onRestore: () {
        if (kDebugMode) {
          print('🔄 User wants to restore streak');
        }
        appState.markStreakLossDialogShown();
        
        // Navigate to store page to purchase or use streak reviver
        // You can implement navigation here if needed
      },
      onDismiss: () {
        if (kDebugMode) {
          print('❌ User dismissed streak loss dialog');
        }
        appState.markStreakLossDialogShown();
      },
    );
  }
}

