import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../constants/app_theme.dart';
import '../../config/premium_config.dart';
import '../../models/premium_models.dart';
import 'purchase_flow_widget.dart';
import '../../services/purchase_service.dart';


class PremiumPage extends StatefulWidget {
  const PremiumPage({Key? key}) : super(key: key);

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  SubscriptionPlanDetails? _selectedPlan;

  @override
  void initState() {
    super.initState();
    // Auto-select the popular plan (yearly) by default
    _selectedPlan = PremiumConfig.popularPlan;
    
    // Initialize purchase service
    _initializePurchaseService();
  }

  Future<void> _initializePurchaseService() async {
    try {
      await PurchaseService.instance.initialize();
      if (kDebugMode) {
        print('✅ Purchase service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing purchase service: $e');
      }
    }
  }

  void _showPurchaseFlow() {
    if (_selectedPlan == null) return;

    if (kDebugMode) {
      print('🛒 Showing purchase flow for: ${_selectedPlan!.name}');
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: PurchaseFlowWidget(
          selectedPlan: _selectedPlan!,
          onPurchaseSuccess: () {
            if (kDebugMode) {
              print('✅ Purchase successful - closing dialog');
            }
            Navigator.of(context).pop();
            // TODO: Update user's premium status and show success message
            _showSuccessMessage();
          },
          onPurchaseCancelled: () {
            if (kDebugMode) {
              print('🚫 Purchase cancelled - closing dialog');
            }
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🎉 Welcome to Premium! Your subscription is now active.',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _restorePurchases() async {
    if (kDebugMode) {
      print('🔄 Restoring previous purchases...');
    }

    try {
      final result = await PurchaseService.instance.restorePurchases();
      
      if (result.success) {
        if (result.hasRestoredPurchases) {
          _showSuccessMessage();
          if (kDebugMode) {
            print('✅ Restored ${result.restoredPurchaseCount} purchases');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No previous purchases found to restore.',
                style: TextStyle(fontSize: 16),
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to restore purchases: ${result.errorMessage}',
              style: const TextStyle(fontSize: 16),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error restoring purchases: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error restoring purchases: $e',
            style: const TextStyle(fontSize: 16),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Upgrade to Premium'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            // Header content (star icon, title, description)
            _buildHeader(),
            const SizedBox(height: 32),
            
            // Features list
            _buildFeaturesList(),
            const SizedBox(height: 32),
            
            // Subscription plans
            _buildSubscriptionPlans(),
            const SizedBox(height: 32),
            
            // Action buttons
            _buildActionButtons(context),
            
            // Bottom padding
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
          'Unlock Your Full Potential',
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
          'Unlock unlimited sessions, custom drills, and premium features to take your training to the next level!',
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.primaryGray,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      'Ad-free',
      'Unlimited daily sessions',
      'Unlimited custom drill creation',
      'Advanced analytics and progress tracking',
      'Priority customer support',
      'Early access to new features'
    ];
    
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
              ? AppTheme.primaryYellow.withOpacity(0.2)
              : Colors.grey.shade50,
          border: Border.all(
            color: isSelected 
                ? AppTheme.primaryYellow 
                : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // Selection indicator
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
                          ? AppTheme.primaryYellow
                          : Colors.grey.shade400,
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
                        : AppTheme.primaryGray,
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
                            ? AppTheme.primaryYellow
                            : AppTheme.primaryDark,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      plan.durationText,
                      style: TextStyle(
                        fontSize: 16,
                        color: isSelected 
                            ? AppTheme.primaryYellow
                            : AppTheme.primaryGray,
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
                          ? AppTheme.primaryYellow
                          : AppTheme.primaryGray,
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
                          ? AppTheme.primaryYellow
                          : AppTheme.primaryGray,
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

  Widget _buildActionButtons(BuildContext context) {
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
                ? () => _showPurchaseFlow()
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedPlan != null 
                  ? AppTheme.primaryYellow 
                  : AppTheme.primaryYellow.withOpacity(0.3),
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
        
        // Restore purchases button
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => _restorePurchases(),
          child: Text(
            'Restore Previous Purchases',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.primaryGray,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        
        // Trial info
        const SizedBox(height: 16),
        const Text(
          '7-day free trial, cancel anytime',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.primaryGray,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
