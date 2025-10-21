import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../constants/app_theme.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../utils/premium_utils.dart';
import '../../config/app_config.dart';
import '../../services/unified_purchase_service.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({Key? key}) : super(key: key);

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  bool _isPremium = false;
  bool _isLoading = true;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    // Initialize purchase service and check premium status
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Check current premium status
      await _checkPremiumStatus();
      
      if (kDebugMode) {
        print('✅ Services initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing services: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkPremiumStatus() async {
    try {
      // Use the simplified PremiumUtils method
      final isPremium = await PremiumUtils.hasPremiumAccess();
      setState(() {
        _isPremium = isPremium;
      });
      
      if (kDebugMode) {
        print('🔒 Premium status checked: ${isPremium ? 'Premium' : 'Free'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking premium status: $e');
      }
      // Default to no premium if there's an error
      setState(() {
        _isPremium = false;
      });
    }
  }

  Future<void> _purchasePackage(String packageIdentifier, String planName) async {
    if (_isPurchasing) return;

    setState(() {
      _isPurchasing = true;
    });

    // Use the unified purchase service
    final purchaseService = UnifiedPurchaseService.instance;
    final result = await purchaseService.purchaseProduct(
      productType: ProductType.premium,
      packageIdentifier: packageIdentifier,
      productName: planName,
    );

    if (result.success) {
      // Update premium status and show success message
      await _checkPremiumStatus();
      _showSuccessMessage();
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.error ?? 'Purchase failed',
            style: const TextStyle(fontSize: 16),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }

    setState(() {
      _isPurchasing = false;
    });
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🎉 Welcome to Premium! Your subscription is now active and all premium features are unlocked.',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: SnackBarAction(
          label: 'View Features',
          textColor: Colors.white,
          onPressed: () {
            // Refresh the page to show premium status
            setState(() {});
          },
        ),
      ),
    );
  }

  Future<void> _restorePurchases() async {
    // Use the unified purchase service
    final purchaseService = UnifiedPurchaseService.instance;
    final success = await purchaseService.restorePurchases();
    
    if (success) {
      // Check if user now has premium access
      final isPremium = await PremiumUtils.hasPremiumAccess();
      
      if (isPremium) {
        _showSuccessMessage();
        setState(() {
          _isPremium = true;
        });
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
            purchaseService.lastError ?? 'Error restoring purchases',
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
            
            // Premium status indicator
            if (_isPremium) _buildPremiumStatusIndicator(),
            if (_isPremium) const SizedBox(height: 32),
            
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

  Widget _buildPremiumStatusIndicator() {
    return Container(
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
            Icons.verified,
            color: AppTheme.primaryYellow,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You are currently a Premium user!',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryDark,
              ),
            ),
          ),
        ],
      ),
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
        
        // Monthly subscription button
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _isPurchasing ? null : () async {
              await _purchasePackage('PremiumMonthly', 'Monthly');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryYellow,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: _isPurchasing
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Monthly Subscription',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Yearly subscription button
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _isPurchasing ? null : () async {
              await _purchasePackage('PremiumYearly', 'Annual');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryYellow,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: _isPurchasing
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Yearly Subscription',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    // If user is already premium, show different content
    if (_isPremium) {
      return _buildPremiumUserContent();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Restore purchases button
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
        
        const SizedBox(height: 8),
        
        // Trial info
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

  Widget _buildPremiumUserContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Text(
          'Premium Features Unlocked! 🎉',
          style: AppTheme.titleMedium.copyWith(
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Premium features access info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.green,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All Premium Features Active',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '• Unlimited daily sessions\n• Unlimited custom drill creation\n• Ad-free experience\n• Advanced analytics\n• Priority support',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.primaryDark,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Manage subscription button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () {
              // TODO: Navigate to subscription management
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Subscription management coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryDark,
              side: BorderSide(color: AppTheme.primaryDark),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Manage Subscription',
              style: TextStyle(
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
      ],
    );
  }
}
