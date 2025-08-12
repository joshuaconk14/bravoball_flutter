import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ✅ ADDED: Import for kDebugMode
import '../config/premium_config.dart';
import '../models/premium_models.dart';
import '../constants/app_theme.dart';
import '../utils/haptic_utils.dart'; // ✅ ADDED: Import for haptic feedback

class PremiumUpgradeDialog extends StatefulWidget {
  final String? title;
  final String? description;
  final String? trigger;
  final VoidCallback? onUpgrade;
  final VoidCallback? onDismiss;

  const PremiumUpgradeDialog({
    Key? key,
    this.title,
    this.description,
    this.trigger,
    this.onUpgrade,
    this.onDismiss,
  }) : super(key: key);

  @override
  State<PremiumUpgradeDialog> createState() => _PremiumUpgradeDialogState();
}

class _PremiumUpgradeDialogState extends State<PremiumUpgradeDialog> {
  SubscriptionPlanDetails? _selectedPlan;

  @override
  void initState() {
    super.initState();
    // Auto-select the popular plan (yearly) by default
    _selectedPlan = PremiumConfig.popularPlan;
  }

  @override
  Widget build(BuildContext context) {
    final upgradePrompt = widget.trigger != null 
        ? PremiumConfig.getUpgradePromptForTrigger(widget.trigger!)
        : PremiumConfig.upgradePrompts.first;

    if (upgradePrompt == null) {
      return const SizedBox.shrink(); // Fallback if no prompt found
    }

    return Dialog.fullscreen(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with close button
              _buildFullscreenHeader(context, upgradePrompt),
              
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Header content (star icon, title, description)
                      _buildHeader(upgradePrompt),
                      const SizedBox(height: 32),
                      
                      // Features list
                      _buildFeaturesList(upgradePrompt.features),
                      const SizedBox(height: 32),
                      
                      // Subscription plans
                      _buildSubscriptionPlans(),
                      const SizedBox(height: 32),
                      
                      // Action buttons
                      _buildActionButtons(context, upgradePrompt),
                      
                      // Bottom padding
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(PremiumUpgradePrompt prompt) {
    return Column(
      children: [
        // Premium icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primaryYellow.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.star,
            size: 40,
            color: AppTheme.primaryYellow,
          ),
        ),
        const SizedBox(height: 16),
        
        // Title
        Text(
          widget.title ?? prompt.title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryDark,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        
        // Description
        Text(
          widget.description ?? prompt.description,
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.primaryGray,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ✅ ADDED: Fullscreen header with close button
  Widget _buildFullscreenHeader(BuildContext context, PremiumUpgradePrompt prompt) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Close button
          IconButton(
            onPressed: widget.onDismiss ?? () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: AppTheme.primaryGray,
              size: 28,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              padding: const EdgeInsets.all(8),
            ),
          ),
          
          const Spacer(),
          
          // Premium badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryYellow,
                width: 1,
              ),
            ),
            child: Text(
              'PREMIUM',
              style: TextStyle(
                color: AppTheme.primaryYellow,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList(List<String> features) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Text(
          'Premium Features',
          style: AppTheme.titleMedium.copyWith(
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Features list
        ...features.map((feature) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: AppTheme.primaryYellow,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  feature,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildSubscriptionPlans() {
    final plans = PremiumConfig.subscriptionPlans;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Text(
          'Choose Your Plan',
          style: AppTheme.titleMedium.copyWith(
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Plans
        ...plans.map((plan) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: _buildPlanCard(plan),
        )),
      ],
    );
  }

  Widget _buildPlanCard(SubscriptionPlanDetails plan) {
    final isPopular = plan.isPopular;
    final isSelected = _selectedPlan?.plan == plan.plan;
    
    return GestureDetector(
      onTap: () {
        HapticUtils.lightImpact(); // Light haptic feedback for plan selection
        if (kDebugMode) {
          print('🎯 Plan selected: ${plan.name} (${plan.plan.name})');
        }
        setState(() {
          _selectedPlan = plan;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryYellow.withOpacity(0.2)  // More prominent for selected
              : Colors.grey.shade50,  // Same gray for all non-selected plans
          border: Border.all(
            color: isSelected 
                ? AppTheme.primaryYellow 
                : Colors.grey.shade300,  // Same gray border for all non-selected plans
            width: isSelected ? 3 : 1,  // Only selected gets thick border
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // Selection indicator - more prominent
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryYellow,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryYellow.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            
            Column(
              children: [
                // Popular badge
                if (isPopular) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppTheme.primaryYellow  // Keep yellow when selected
                          : Colors.grey.shade400,  // Gray when not selected
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'MOST POPULAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Plan name
                Text(
                  plan.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected 
                        ? AppTheme.primaryDark 
                        : AppTheme.primaryGray,  // Gray for non-selected plans
                  ),
                ),
                const SizedBox(height: 8),
                
                // Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      plan.formattedPrice,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isSelected 
                            ? AppTheme.primaryYellow  // Bright yellow for selected
                            : AppTheme.primaryDark,  // Dark for non-selected plans
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      plan.durationText,
                      style: TextStyle(
                        fontSize: 16,
                        color: isSelected 
                            ? AppTheme.primaryYellow  // Bright yellow for selected
                            : AppTheme.primaryGray,  // Gray for non-selected plans
                      ),
                    ),
                  ],
                ),
                
                // Savings for yearly plan
                if (plan.savingsPercentage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Save ${plan.savingsPercentage!.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected 
                          ? AppTheme.primaryYellow  // Bright yellow for selected
                          : AppTheme.primaryGray,  // Gray for non-selected plans
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                
                // Monthly equivalent for yearly
                if (plan.plan == SubscriptionPlan.yearly) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${plan.formattedMonthlyPrice}/month',
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected 
                          ? AppTheme.primaryYellow  // Bright yellow for selected
                          : AppTheme.primaryGray,  // Gray for non-selected plans
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

  Widget _buildActionButtons(BuildContext context, PremiumUpgradePrompt prompt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Text(
          'Ready to Upgrade?',
          style: AppTheme.titleMedium.copyWith(
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Selected plan info
        if (_selectedPlan != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryYellow,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryYellow,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Plan: ${_selectedPlan!.name}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                      Text(
                        '${_selectedPlan!.formattedPrice} per ${_selectedPlan!.durationText}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.primaryYellow,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (kDebugMode) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Debug: ${_selectedPlan!.plan.name} (Popular: ${_selectedPlan!.isPopular})',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Upgrade button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _selectedPlan != null 
                ? (widget.onUpgrade ?? () {
                    // TODO: Implement in-app purchase flow
                    if (kDebugMode) {
                      print('🚀 Upgrade button pressed for ${_selectedPlan!.name} - implement purchase flow');
                    }
                  })
                : null, // Disabled if no plan selected
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedPlan != null 
                  ? AppTheme.primaryYellow 
                  : Colors.grey.shade300,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              _selectedPlan != null 
                  ? 'Continue with ${_selectedPlan!.name}'
                  : 'Select a Plan to Continue',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Dismiss button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton(
            onPressed: widget.onDismiss ?? () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryGray,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Maybe Later',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        
        // Trial info
        if (prompt.showTrialOffer && prompt.trialDays != null) ...[
          const SizedBox(height: 16),
          Text(
            '${prompt.trialDays}-day free trial, cancel anytime',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.primaryGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Show the premium upgrade dialog
Future<void> showPremiumUpgradeDialog(
  BuildContext context, {
  String? title,
  String? description,
  String? trigger,
  VoidCallback? onUpgrade,
  VoidCallback? onDismiss,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => PremiumUpgradeDialog(
      title: title,
      description: description,
      trigger: trigger,
      onUpgrade: onUpgrade,
      onDismiss: onDismiss,
    ),
  );
}
