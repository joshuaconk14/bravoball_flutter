import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../config/purchase_config.dart';
import '../../models/premium_models.dart';
import '../../models/purchase_models.dart';
import '../../services/purchase_service.dart';
import '../../constants/app_theme.dart';
import '../../utils/haptic_utils.dart';

class PurchaseFlowWidget extends StatefulWidget {
  final SubscriptionPlanDetails selectedPlan;
  final VoidCallback? onPurchaseSuccess;
  final VoidCallback? onPurchaseCancelled;

  const PurchaseFlowWidget({
    Key? key,
    required this.selectedPlan,
    this.onPurchaseSuccess,
    this.onPurchaseCancelled,
  }) : super(key: key);

  @override
  State<PurchaseFlowWidget> createState() => _PurchaseFlowWidgetState();
}

class _PurchaseFlowWidgetState extends State<PurchaseFlowWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  PurchaseState _purchaseState = PurchaseState.initial;
  String? _errorMessage;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    // Listen to purchase state changes
    _setupPurchaseListeners();
    
    // Start entrance animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupPurchaseListeners() {
    // Listen to purchase state changes
    PurchaseService.instance.purchaseStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _purchaseState = state;
        });
        
        if (kDebugMode) {
          print('🔄 Purchase state changed: ${state.name}');
        }
      }
    });

    // Listen to purchase results
    PurchaseService.instance.purchaseResultStream.listen((result) {
      if (mounted) {
        if (result.success) {
          _handlePurchaseSuccess(result);
        } else {
          _handlePurchaseError(result.errorMessage ?? 'Purchase failed');
        }
      }
    });
  }

  void _handlePurchaseSuccess(PurchaseResult result) {
    if (kDebugMode) {
      print('✅ Purchase successful: ${result.transactionId}');
    }

    // Provide haptic feedback
    if (PurchaseConfig.enableHapticFeedback) {
      HapticUtils.heavyImpact();
    }

    // Show success state briefly
    setState(() {
      _purchaseState = PurchaseState.success;
      _errorMessage = null;
      _isProcessing = false;
    });

    // Call success callback after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && widget.onPurchaseSuccess != null) {
        widget.onPurchaseSuccess!();
      }
    });
  }

  void _handlePurchaseError(String error) {
    if (kDebugMode) {
      print('❌ Purchase error: $error');
    }

    // Provide haptic feedback
    if (PurchaseConfig.enableHapticFeedback) {
      HapticUtils.heavyImpact();
    }

    setState(() {
      _purchaseState = PurchaseState.failed;
      _errorMessage = error;
      _isProcessing = false;
    });
  }

  Future<void> _startPurchase() async {
    if (_isProcessing) return;

    if (kDebugMode) {
      print('🛒 Starting purchase for: ${widget.selectedPlan.name}');
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Get the product ID for the selected plan
      final planType = widget.selectedPlan.plan.name;
      final productId = PurchaseConfig.getProductId(planType);
      
      if (productId == null) {
        throw Exception('Product not available for ${widget.selectedPlan.name}');
      }

      // Start the purchase
      final result = await PurchaseService.instance.purchaseProduct(productId);
      
      if (!result.success) {
        _handlePurchaseError(result.errorMessage ?? 'Failed to start purchase');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error starting purchase: $e');
      }
      _handlePurchaseError('Error starting purchase: $e');
    }
  }

  void _cancelPurchase() {
    if (kDebugMode) {
      print('🚫 Purchase cancelled by user');
    }

    // Provide haptic feedback
    if (PurchaseConfig.enableHapticFeedback) {
      HapticUtils.lightImpact();
    }

    if (widget.onPurchaseCancelled != null) {
      widget.onPurchaseCancelled!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: _buildContent(),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    switch (_purchaseState) {
      case PurchaseState.initial:
        return _buildInitialState();
      case PurchaseState.loading:
        return _buildLoadingState();
      case PurchaseState.purchasing:
        return _buildPurchasingState();
      case PurchaseState.success:
        return _buildSuccessState();
      case PurchaseState.failed:
        return _buildFailedState();
      case PurchaseState.cancelled:
        return _buildCancelledState();
      case PurchaseState.restored:
        return _buildRestoredState();
      default:
        return _buildInitialState();
    }
  }

  Widget _buildInitialState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 24),
          
          // Plan details
          _buildPlanDetails(),
          const SizedBox(height: 24),
          
          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryYellow),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading products...',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.primaryGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchasingState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryYellow),
          ),
          const SizedBox(height: 16),
          Text(
            'Processing payment...',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.primaryDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please complete the payment in the store dialog',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.primaryGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _cancelPurchase,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Success icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 50,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            'Payment Successful!',
            style: AppTheme.titleLarge.copyWith(
              color: AppTheme.primaryDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          Text(
            PurchaseConfig.getSuccessMessage(
              widget.selectedPlan.plan.name,
            ),
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.primaryGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Continue button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                if (widget.onPurchaseSuccess != null) {
                  widget.onPurchaseSuccess!();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Error icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 50,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            'Payment Failed',
            style: AppTheme.titleLarge.copyWith(
              color: AppTheme.primaryDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          Text(
            _errorMessage ?? 'An error occurred during payment',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.primaryGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Retry and cancel buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _cancelPurchase,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _startPurchase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryYellow,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cancelled icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cancel_outlined,
              size: 50,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            'Purchase Cancelled',
            style: AppTheme.titleLarge.copyWith(
              color: AppTheme.primaryDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          Text(
            'You can try again anytime',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.primaryGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Try again button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _startPurchase,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryYellow,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestoredState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Restored icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restore,
              size: 50,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            'Purchase Restored',
            style: AppTheme.titleLarge.copyWith(
              color: AppTheme.primaryDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          Text(
            'Your previous purchase has been restored',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.primaryGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Continue button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                if (widget.onPurchaseSuccess != null) {
                  widget.onPurchaseSuccess!();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Lock icon
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppTheme.primaryYellow.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lock_open,
            size: 30,
            color: AppTheme.primaryYellow,
          ),
        ),
        const SizedBox(height: 16),
        
        Text(
          'Complete Your Purchase',
          style: AppTheme.titleLarge.copyWith(
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        
        Text(
          'You\'re just one step away from unlocking premium features!',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.primaryGray,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPlanDetails() {
    return Container(
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
                  widget.selectedPlan.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDark,
                  ),
                ),
                Text(
                  '${widget.selectedPlan.formattedPrice} per ${widget.selectedPlan.durationText}',
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
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Purchase button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _startPurchase,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryYellow,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Pay ${widget.selectedPlan.formattedPrice}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Cancel button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton(
            onPressed: _isProcessing ? null : _cancelPurchase,
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.primaryGray,
              ),
            ),
          ),
        ),
        
        // Terms and conditions
        const SizedBox(height: 16),
        Text(
          'By continuing, you agree to our Terms of Service and Privacy Policy',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.primaryGray.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
