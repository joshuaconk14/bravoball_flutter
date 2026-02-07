import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

/// Reusable loading overlay widget
/// 
/// Displays a simple loading circle overlay with semi-transparent background.
/// Used for purchase transactions, ad loading, and other async operations.
class LoadingOverlay extends StatelessWidget {
  /// Whether to show the overlay
  final bool isLoading;
  
  /// Optional custom background opacity (default: 0.3)
  final double? backgroundOpacity;
  
  /// Optional custom size for the loading circle container (default: 80)
  final double? size;

  const LoadingOverlay({
    Key? key,
    required this.isLoading,
    this.backgroundOpacity,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.black.withOpacity(backgroundOpacity ?? 0.3),
      child: Center(
        child: Container(
          width: size ?? 80,
          height: size ?? 80,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryYellow),
              strokeWidth: 3.0,
            ),
          ),
        ),
      ),
    );
  }
}

