import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

/// Reusable widget for displaying feature unavailability messages
/// 
/// Similar to Duolingo's offline/feature unavailable screens, this widget
/// provides a clean, user-friendly way to communicate when a feature
/// is unavailable due to offline status, loading errors, or other reasons.
/// 
/// **Usage Example:**
/// ```dart
/// FeatureUnavailableWidget(
///   title: 'Store is currently unavailable',
///   description: 'You seem to be offline. Check your connection and try again!',
///   icon: Icons.shopping_bag_outlined,
/// )
/// ```
class FeatureUnavailableWidget extends StatelessWidget {
  /// Main heading text (e.g., "Challenges are currently unavailable")
  final String title;
  
  /// Descriptive subtitle explaining why the feature is unavailable
  /// and what the user can do (e.g., "You seem to be offline...")
  final String description;
  
  /// Icon to display above the title (optional)
  /// If not provided, defaults to a generic unavailable icon
  final IconData? icon;
  
  /// Custom widget to display instead of icon (optional)
  /// If provided, takes precedence over icon
  final Widget? illustration;
  
  /// Optional action button text
  /// If provided, displays a button at the bottom
  final String? actionButtonText;
  
  /// Optional callback for action button
  final VoidCallback? onActionPressed;
  
  /// Whether to show a retry button (defaults to false)
  final bool showRetryButton;
  
  /// Callback for retry button
  final VoidCallback? onRetry;
  
  /// Custom padding around the content (defaults to standard spacing)
  final EdgeInsets? padding;

  const FeatureUnavailableWidget({
    Key? key,
    required this.title,
    required this.description,
    this.icon,
    this.illustration,
    this.actionButtonText,
    this.onActionPressed,
    this.showRetryButton = false,
    this.onRetry,
    this.padding,
  }) : super(key: key);

  /// Factory constructor for offline-specific messages
  /// Provides sensible defaults for offline scenarios
  factory FeatureUnavailableWidget.offline({
    required String featureName,
    String? customDescription,
    IconData? icon,
    VoidCallback? onRetry,
  }) {
    return FeatureUnavailableWidget(
      title: '$featureName is currently unavailable',
      description: customDescription ?? 
        'You seem to be offline. Check your connection and try again!',
      icon: icon ?? Icons.wifi_off,
      showRetryButton: true,
      onRetry: onRetry,
    );
  }

  /// Factory constructor for loading error scenarios
  /// Provides sensible defaults for loading failures
  factory FeatureUnavailableWidget.loadingError({
    required String featureName,
    String? customDescription,
    IconData? icon,
    VoidCallback? onRetry,
  }) {
    return FeatureUnavailableWidget(
      title: 'Unable to load $featureName',
      description: customDescription ?? 
        'Something went wrong. Please try again later.',
      icon: icon ?? Icons.error_outline,
      showRetryButton: true,
      onRetry: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLarge,
        vertical: AppTheme.spacingXLarge,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Illustration or Icon
          if (illustration != null)
            illustration!
          else
            _buildIcon(),
          
          const SizedBox(height: AppTheme.spacingXLarge),
          
          // Title
          Text(
            title,
            style: AppTheme.headlineMedium.copyWith(
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppTheme.spacingMedium),
          
          // Description
          Text(
            description,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          
          // Action buttons
          if (showRetryButton || actionButtonText != null) ...[
            const SizedBox(height: AppTheme.spacingXLarge),
            _buildActionButtons(),
          ],
        ],
      ),
    );
  }

  /// Build the icon widget
  Widget _buildIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon ?? Icons.info_outline,
        size: 64,
        color: AppTheme.primaryGray,
      ),
    );
  }

  /// Build action buttons (retry and/or custom action)
  Widget _buildActionButtons() {
    return Column(
      children: [
        if (showRetryButton && onRetry != null)
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.buttonPrimary,
              foregroundColor: AppTheme.textOnPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingXLarge,
                vertical: AppTheme.spacingMedium,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
            ),
            child: Text(
              'Try Again',
              style: AppTheme.buttonTextMedium,
            ),
          ),
        
        if (actionButtonText != null && onActionPressed != null) ...[
          if (showRetryButton && onRetry != null)
            const SizedBox(height: AppTheme.spacingMedium),
          ElevatedButton(
            onPressed: onActionPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.buttonPrimary,
              foregroundColor: AppTheme.textOnPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingXLarge,
                vertical: AppTheme.spacingMedium,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
            ),
            child: Text(
              actionButtonText!,
              style: AppTheme.buttonTextMedium,
            ),
          ),
        ],
      ],
    );
  }
}
