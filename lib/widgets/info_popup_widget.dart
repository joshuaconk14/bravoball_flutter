import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;
import '../constants/app_theme.dart';
import '../utils/haptic_utils.dart';

class InfoPopupWidget extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onClose;
  final String riveFileName;

  const InfoPopupWidget({
    Key? key,
    required this.title,
    required this.description,
    this.onClose,
    this.riveFileName = 'Bravo_Animation.riv',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with Bravo character and title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                children: [
                  // Bravo character animation
                  Container(
                    width: 80,
                    height: 80,
                    child: rive.RiveAnimation.asset(
                      'assets/rive/$riveFileName',
                      fit: BoxFit.contain,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Title
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontPoppins,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Scrollable content without fade gradient
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text(
                  description,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontPoppins,
                    fontSize: 16,
                    color: AppTheme.primaryGray,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            
            // "Got it!" button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticUtils.lightImpact();
                    Navigator.of(context).pop();
                    onClose?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryYellow,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: AppTheme.primaryYellow.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Got it!',
                    style: TextStyle(
                      fontFamily: AppTheme.fontPoppins,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show the info popup as a dialog
  static void show(
    BuildContext context, {
    required String title,
    required String description,
    VoidCallback? onClose,
    String riveFileName = 'Bravo_Animation.riv',
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => InfoPopupWidget(
        title: title,
        description: description,
        onClose: onClose,
        riveFileName: riveFileName,
      ),
    );
  }
} 