import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' as painting;
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../constants/app_theme.dart';
import '../../constants/app_assets.dart';
import '../../widgets/bravo_button.dart';
import '../../widgets/item_usage_confirmation_dialog.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/feature_unavailable_widget.dart';
import '../../utils/haptic_utils.dart';
import '../../utils/premium_utils.dart';
import '../../utils/store_business_rules.dart';
import '../../config/purchase_config.dart';
import '../../config/ad_config.dart';
import '../../services/store_service.dart';
import '../../services/app_state_service.dart';
import '../../services/ad_service.dart';
import '../../services/unified_purchase_service.dart';
import '../../services/connectivity_service.dart';
import '../premium/premium_page.dart';

class StorePage extends StatefulWidget {
  const StorePage({Key? key}) : super(key: key);

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  bool _isPremium = false;
  bool _isLoading = true;
  bool _isLoadingAd = false;
  String? _loadError; // ✅ ADDED: Track loading errors
  
  // ✅ DEBUG ONLY: Override states for testing (null = use real state)
  bool? _debugForceOffline; // null = use real connectivity, true/false = override
  bool? _debugForceError;   // null = use real error state, true = force error

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
    _initializeStoreService();
  }

  Future<void> _initializeStoreService() async {
    try {
      await StoreService.instance.initialize();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ StoreService initialization error: $e');
      }
      if (mounted) {
        setState(() {
          _loadError = 'Failed to load store items. Please try again.';
        });
      }
    }
  }

  Future<void> _checkPremiumStatus() async {
    try {
      final isPremium = await PremiumUtils.instance.hasPremiumAccess();
      if (mounted) {
        setState(() {
          _isPremium = isPremium;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Premium status check error: $e');
      }
      if (mounted) {
        setState(() {
          _isPremium = false;
          _isLoading = false;
          // Only set error if we don't already have one
          _loadError ??= 'Failed to load store. Please try again.';
        });
      }
    }
  }

  /// Retry loading store data
  Future<void> _retryLoad() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
      // ✅ DEBUG: Clear debug overrides on retry
      if (kDebugMode) {
        _debugForceOffline = null;
        _debugForceError = null;
      }
    });
    await _checkPremiumStatus();
    await _initializeStoreService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
        children: [
          // Top bar
          _buildTopBar(context),
          
          // Main content
          Expanded(
            child: Container(
              color: Colors.white,
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : Consumer<ConnectivityService>(
                    builder: (context, connectivity, child) {
                      // ✅ DEBUG: Allow override for testing, fallback to real state
                      final isOffline = _debugForceOffline ?? !connectivity.isOnline;
                      final hasError = _debugForceError ?? (_loadError != null);
                      
                      // Check if offline (real or debug override)
                      if (isOffline) {
                        return _buildUnavailableView(
                          isOffline: true,
                          onRetry: _retryLoad,
                        );
                      }
                      
                      // Check if there was a loading error (real or debug override)
                      if (hasError) {
                        return _buildUnavailableView(
                          isOffline: false,
                          errorMessage: _loadError ?? 'Debug: Simulated error',
                          onRetry: _retryLoad,
                        );
                      }
                      
                      // Normal content
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            // Header section - only show for non-premium users
                            if (!_isPremium) _buildHeader(),
                            
                            // Premium user message - show above My Items
                            if (_isPremium) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                                child: _buildPremiumUserMessage(),
                              ),
                            ],
                            
                            // My Items section
                            _buildMyItemsSection(),
                            
                            // Store items section
                            _buildStoreItems(),
                            
                            const SizedBox(height: 32),
                            
                            // Debug button - only show in debug mode
                            if (kDebugMode) _buildDebugButton(),
                          ],
                        ),
                      );
                    },
                  ),
              ),
            ),
            ],
          ),
          
          // Purchase loading overlay
          Consumer<UnifiedPurchaseService>(
            builder: (context, purchaseService, child) {
              return LoadingOverlay(isLoading: purchaseService.isPurchasing);
            },
          ),
          
          // Ad loading overlay
          LoadingOverlay(isLoading: _isLoadingAd),
          ],
        ),
    );
  }

  /// Build unavailable view based on connectivity or error state
  Widget _buildUnavailableView({
    required bool isOffline,
    String? errorMessage,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: isOffline
            ? FeatureUnavailableWidget.offline(
                featureName: 'Store',
                customDescription: 'You seem to be offline. Check your connection and try again!',
                icon: Icons.shopping_bag_outlined,
                onRetry: onRetry,
              )
            : FeatureUnavailableWidget.loadingError(
                featureName: 'Store',
                customDescription: errorMessage ?? 'Something went wrong. Please try again later.',
                icon: Icons.shopping_bag_outlined,
                onRetry: onRetry,
              ),
      ),
    );
  }

  // Top bar with back button and title
  Widget _buildTopBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade400,
            width: 2.0,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticUtils.heavyImpact();
                  Navigator.of(context).pop();
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.backgroundPrimary,
                  child: Icon(Icons.arrow_back, color: AppTheme.secondaryBlue, size: 28),
                ),
              ),
              
              const Spacer(),
              
              Text(
                'Store',
                style: TextStyle(
                  fontFamily: AppTheme.fontPottaOne,
                  fontSize: 22,
                  color: AppTheme.primaryYellow,
                  fontWeight: FontWeight.w400,
                ),
              ),
              
              const Spacer(),
              
              // ✅ DEBUG: Testing controls (only in debug mode)
              if (kDebugMode) _buildDebugControls(),
              
              if (kDebugMode) const SizedBox(width: 8),
              
              // Treats balance display - matches front page style
              Consumer<StoreService>(
                builder: (context, storeService, child) {
                  return Row(
                    children: [
                      Image.asset(
                        AppAssets.treatIcon,
                        width: 25,
                        height: 25,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${storeService.treats}', // Real treat count from API
                        style: TextStyle(
                          fontFamily: AppTheme.fontPoppins,
                          fontSize: 24,
                          color: Colors.brown,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ DEBUG: Build debug controls for testing unavailable states
  Widget _buildDebugControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Offline toggle
        GestureDetector(
          onTap: () {
            setState(() {
              _debugForceOffline = _debugForceOffline == true ? null : true;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: _debugForceOffline == true ? Colors.red.shade600 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _debugForceOffline == true ? 'OFFLINE' : 'TEST OFFLINE',
              style: TextStyle(
                color: _debugForceOffline == true ? Colors.white : Colors.black87,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                fontFamily: AppTheme.fontPoppins,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        // Error toggle
        GestureDetector(
          onTap: () {
            setState(() {
              _debugForceError = _debugForceError == true ? null : true;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: _debugForceError == true ? Colors.orange.shade600 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _debugForceError == true ? 'ERROR' : 'TEST ERROR',
              style: TextStyle(
                color: _debugForceError == true ? Colors.white : Colors.black87,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                fontFamily: AppTheme.fontPoppins,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Header with premium banner
  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: painting.LinearGradient(
          colors: [
            Color(0xFF9C27B0), // Purple
            Color(0xFF2196F3), // Blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF9C27B0).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticUtils.heavyImpact();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PremiumPage(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Crown icon
                Icon(
                  Icons.workspace_premium,
                  size: 48,
                  color: AppTheme.white,
                ),
                
                const SizedBox(height: 12),
                
                // Premium title
                Text(
                  'Unlock Premium',
                  style: TextStyle(
                    fontFamily: AppTheme.fontPottaOne,
                    fontSize: 28,
                    color: AppTheme.white,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                // Description
                Text(
                  'Get unlimited sessions, remove ads, and unlock all features!',
                  style: TextStyle(
                    fontFamily: AppTheme.fontPoppins,
                    fontSize: 16,
                    color: AppTheme.white.withOpacity(0.95),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Get Premium button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    'Get Premium',
                    style: TextStyle(
                      fontFamily: AppTheme.fontPoppins,
                      fontSize: 16,
                      color: Color(0xFF9C27B0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // My Items section - shows user's current inventory
  Widget _buildMyItemsSection() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, _isPremium ? 16 : 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            'My Items',
            style: TextStyle(
              fontFamily: AppTheme.fontPottaOne,
              fontSize: 20,
              color: AppTheme.primaryYellow,
              fontWeight: FontWeight.w400,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Horizontal scrollable items
          Consumer<StoreService>(
            builder: (context, storeService, child) {
              return SizedBox(
                height: 180, // Increased height for larger squares
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Streak Freezes
                    _buildMyItemSquare(
                      title: 'Streak Freezes',
                      amount: storeService.streakFreezes,
                      icon: Icons.ac_unit,
                      color: AppTheme.secondaryBlue,
                      onTap: () => _useStreakFreeze(context, storeService),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Streak Reviver
                    _buildMyItemSquare(
                      title: 'Streak Reviver',
                      amount: storeService.streakRevivers,
                      icon: Icons.restore,
                      color: AppTheme.secondaryOrange,
                      onTap: () => _useStreakReviver(context, storeService),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Add more items here in the future
                    // _buildMyItemSquare(...),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Individual my item square
  Widget _buildMyItemSquare({
    required String title,
    required int amount,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: amount > 0 ? onTap : null,
      child: Container(
        width: 160, // Increased width for larger squares
        height: 160, // Increased height for larger squares
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: onTap != null && amount > 0
              ? Border.all(color: color.withOpacity(0.3), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: AppTheme.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppTheme.white,
                size: 30,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Title
            Text(
              title,
              style: TextStyle(
                fontFamily: AppTheme.fontPoppins,
                fontSize: 16,
                color: AppTheme.black,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 8),
            
            // Amount
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryYellow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$amount',
                style: TextStyle(
                  fontFamily: AppTheme.fontPoppins,
                  fontSize: 18,
                  color: AppTheme.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  // Store items section
  Widget _buildStoreItems() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bravo's Store section title
          Text(
            'Bravo\'s Store',
            style: TextStyle(
              fontFamily: AppTheme.fontPottaOne,
              fontSize: 20,
              color: AppTheme.primaryYellow,
              fontWeight: FontWeight.w400,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Streak Freeze Item
          Consumer<StoreService>(
            builder: (context, storeService, child) {
              return _buildStoreItem(
                title: 'Streak Freeze',
                description: 'Freeze your streak for 24 hours',
                icon: Icons.ac_unit,
                price: '${StoreBusinessRules.streakFreezeCost} Treats',
                color: AppTheme.secondaryBlue,
                onTap: () {
                  HapticUtils.mediumImpact();
                  _purchaseStreakFreeze(storeService);
                },
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          // Streak Reviver Item
          Consumer<StoreService>(
            builder: (context, storeService, child) {
              return _buildStoreItem(
                title: 'Streak Reviver',
                description: 'Restore your broken streak',
                icon: Icons.restore,
                price: '${StoreBusinessRules.streakReviverCost} Treats',
                color: AppTheme.secondaryOrange,
                onTap: () {
                  HapticUtils.mediumImpact();
                  _purchaseStreakReviver(storeService);
                },
              );
            },
          ),
          
          const SizedBox(height: 30),
          
          // Treat Packages Section
          _buildTreatPackages(),
        ],
      ),
    );
  }

  // Premium user message
  Widget _buildPremiumUserMessage() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: painting.LinearGradient(
          colors: [
            AppTheme.primaryYellow.withOpacity(0.1),
            AppTheme.secondaryBlue.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryYellow.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Crown icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.primaryYellow,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.workspace_premium,
              color: AppTheme.white,
              size: 28,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Premium Active!',
                  style: TextStyle(
                    fontFamily: AppTheme.fontPottaOne,
                    fontSize: 18,
                    color: AppTheme.primaryYellow,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You have access to all premium features',
                  style: TextStyle(
                    fontFamily: AppTheme.fontPoppins,
                    fontSize: 14,
                    color: AppTheme.primaryGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Individual store item
  Widget _buildStoreItem({
    required String title,
    required String description,
    required IconData icon,
    required String price,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.white,
                    size: 30,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: AppTheme.fontPoppins,
                          fontSize: 18,
                          color: AppTheme.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontFamily: AppTheme.fontPoppins,
                          fontSize: 14,
                          color: AppTheme.primaryGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Price
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryYellow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    price,
                    style: TextStyle(
                      fontFamily: AppTheme.fontPoppins,
                      fontSize: 14,
                      color: AppTheme.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Treat packages section
  Widget _buildTreatPackages() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Get More Treats',
          style: TextStyle(
            fontFamily: AppTheme.fontPottaOne,
            fontSize: 20,
            color: AppTheme.primaryYellow,
            fontWeight: FontWeight.w400,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Watch Ad for Treats Button
        _buildWatchAdButton(
          onTap: () async {
            HapticUtils.mediumImpact();
            await _watchAdForTreats();
          },
        ),
        
        const SizedBox(height: 16),
        
        // Treat Packages - Dynamic from RevenueCat
        Consumer<StoreService>(
          builder: (context, storeService, child) {
            return FutureBuilder<List<Package>>(
              future: UnifiedPurchaseService.instance.getAvailablePackages(ProductType.treats),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  // Fallback to static packages if RevenueCat fails
                  return Column(
                    children: [
                      _buildTreatPackage(
                        amount: '${PurchaseConfig.treats500Amount}',
                        price: '\$4.99',
                        onTap: () {
                          HapticUtils.mediumImpact();
                          _purchaseTreatPackage(PurchaseConfig.treats500PackageId);
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildTreatPackage(
                        amount: '${PurchaseConfig.treats1000Amount}',
                        price: '\$9.99',
                        isPopular: true,
                        onTap: () {
                          HapticUtils.mediumImpact();
                          _purchaseTreatPackage(PurchaseConfig.treats1000PackageId);
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildTreatPackage(
                        amount: '${PurchaseConfig.treats2000Amount}',
                        price: '\$19.99',
                        onTap: () {
                          HapticUtils.mediumImpact();
                          _purchaseTreatPackage(PurchaseConfig.treats2000PackageId);
                        },
                      ),
                    ],
                  );
                }
                
                final packages = snapshot.data!;
                return Column(
                  children: packages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final package = entry.value;
                    
                    // Extract amount from package identifier
                    final amount = PurchaseConfig.getTreatAmountFromPackageId(package.identifier).toString();
                    
                    return Column(
                      children: [
                        if (index > 0) const SizedBox(height: 12),
                        _buildTreatPackage(
                          amount: amount,
                          price: package.storeProduct.priceString,
                          isPopular: package.identifier == PurchaseConfig.treats1000PackageId,
                          onTap: () {
                            HapticUtils.mediumImpact();
                            _purchaseTreatPackage(package.identifier);
                          },
                        ),
                      ],
                    );
                  }).toList(),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // Watch ad button
  Widget _buildWatchAdButton({
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Video play icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryYellow,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    color: AppTheme.white,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${StoreBusinessRules.adRewardAmount} Treats',
                        style: TextStyle(
                          fontFamily: AppTheme.fontPoppins,
                          fontSize: 16,
                          color: AppTheme.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Watch an ad',
                        style: TextStyle(
                          fontFamily: AppTheme.fontPoppins,
                          fontSize: 12,
                          color: AppTheme.primaryGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // FREE badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryYellow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'FREE',
                    style: TextStyle(
                      fontFamily: AppTheme.fontPoppins,
                      fontSize: 14,
                      color: AppTheme.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Individual treat package
  Widget _buildTreatPackage({
    required String amount,
    required String price,
    bool isPopular = false,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isPopular ? Border.all(color: AppTheme.primaryYellow, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Treat icon (no golden circle)
                Image.asset(
                  AppAssets.treatIcon,
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
                
                const SizedBox(width: 12),
                
                // Amount
                Text(
                  '$amount Treats',
                  style: TextStyle(
                    fontFamily: AppTheme.fontPoppins,
                    fontSize: 16,
                    color: AppTheme.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const Spacer(),
                
                // Popular badge
                if (isPopular)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'POPULAR',
                      style: TextStyle(
                        fontFamily: AppTheme.fontPoppins,
                        fontSize: 10,
                        color: AppTheme.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                
                // Price
                Text(
                  price,
                  style: TextStyle(
                    fontFamily: AppTheme.fontPoppins,
                    fontSize: 16,
                    color: AppTheme.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Debug button for adding treats
  Widget _buildDebugButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Consumer<StoreService>(
        builder: (context, storeService, child) {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticUtils.mediumImpact();
                  _addDebugTreats(storeService);
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bug_report,
                        color: Colors.red,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'DEBUG: Add 1000 Treats',
                        style: TextStyle(
                          fontFamily: AppTheme.fontPoppins,
                          fontSize: 16,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Watch ad for treats
  Future<void> _watchAdForTreats() async {
    try {
      // Show loading overlay
      setState(() {
        _isLoadingAd = true;
      });

      // Show rewarded ad
      final rewardAmount = await AdService.instance.showRewardedAd();
      
      // Hide loading overlay
      setState(() {
        _isLoadingAd = false;
      });

      if (rewardAmount > 0) {
        // Add treats to user's account using centralized reward function
        final storeService = StoreService.instance;
        final success = await storeService.grantTreatsReward(TreatRewardType.ad);
        
        if (success) {
          // Show success message with centralized reward amount
          final earnedAmount = StoreBusinessRules.adRewardAmount;
          _showSuccessDialog(
            'Treats Earned!',
            'You earned $earnedAmount treats for watching the ad!',
          );
        }
      } else if (rewardAmount == -1) {
        // Ad failed to load or is disabled
        _showErrorDialog('Ad failed to load. Please try again later.');
      } else {
        // User closed ad early without completing it
        _showErrorDialog('Ad was not completed. Please watch the full ad to earn treats.');
      }
    } catch (e) {
      // Hide loading overlay
      setState(() {
        _isLoadingAd = false;
      });

      if (kDebugMode) {
        print('❌ Error watching ad for treats: $e');
      }
      _showErrorDialog('Failed to show ad. Please try again later.');
    }
  }

  // Add debug treats
  Future<void> _addDebugTreats(StoreService storeService) async {
    // Add 1000 treats for debugging (now syncs with backend)
    await storeService.addDebugTreats(1000);
    
    // Show a debug snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🐛 DEBUG: Added 1000 treats! New total: ${storeService.treats}',
          style: TextStyle(
            fontFamily: AppTheme.fontPoppins,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Purchase streak freeze
  Future<void> _purchaseStreakFreeze(StoreService storeService) async {
    // Show confirmation dialog first
    final confirmed = await _showPurchaseConfirmationDialog(
      itemName: 'Streak Freeze',
      treatCost: StoreBusinessRules.streakFreezeCost,
      icon: Icons.ac_unit,
      color: AppTheme.secondaryBlue,
      description: 'Freeze your streak for 24 hours',
    );

    if (!confirmed) return;

    final success = await storeService.purchaseStreakFreeze();
    if (success) {
      _showSuccessDialog('Streak Freeze', 'You now have ${storeService.streakFreezes} streak freezes!');
    } else {
      _showErrorDialog(storeService.error ?? 'Failed to purchase Streak Freeze');
    }
  }

  // Purchase streak reviver
  Future<void> _purchaseStreakReviver(StoreService storeService) async {
    // Show confirmation dialog first
    final confirmed = await _showPurchaseConfirmationDialog(
      itemName: 'Streak Reviver',
      treatCost: StoreBusinessRules.streakReviverCost,
      icon: Icons.restore,
      color: AppTheme.secondaryOrange,
      description: 'Restore your broken streak',
    );

    if (!confirmed) return;

    final success = await storeService.purchaseStreakReviver();
    if (success) {
      _showSuccessDialog('Streak Reviver', 'You now have ${storeService.streakRevivers} streak revivers!');
    } else {
      _showErrorDialog(storeService.error ?? 'Failed to purchase Streak Reviver');
    }
  }

  // Use streak reviver
  Future<void> _useStreakReviver(BuildContext context, StoreService storeService) async {
    HapticUtils.mediumImpact();
    
    // Check if user has any streak revivers
    if (storeService.streakRevivers <= 0) {
      _showErrorDialog('You don\'t have any streak revivers. Purchase one from the store!');
      return;
    }

    // Check if user has a lost streak to restore
    final appState = Provider.of<AppStateService>(context, listen: false);
    if (appState.currentStreak > 0) {
      _showErrorDialog('You already have an active streak! Streak revivers can only be used when you\'ve lost your streak.');
      return;
    }
    
    if (appState.previousStreak <= 0) {
      _showErrorDialog('You don\'t have a previous streak to restore.');
      return;
    }

    // Show confirmation dialog
    await _showUseStreakReviverDialog(context, storeService, appState);
  }

  // Show use streak reviver confirmation dialog
  Future<void> _showUseStreakReviverDialog(
    BuildContext context,
    StoreService storeService,
    AppStateService appState,
  ) async {
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return ItemUsageConfirmationDialog(
            title: 'Restore Your Streak?',
            description: 'Use a Streak Reviver to restore your ${appState.previousStreak}-day streak?',
            itemName: 'Streak Reviver',
            icon: Icons.restore,
            iconColor: AppTheme.secondaryOrange,
            confirmButtonText: 'Restore Streak',
            isLoading: isLoading,
            onConfirm: () async {
              setState(() {
                isLoading = true;
              });

              final result = await storeService.useStreakReviver();
              
              if (result != null) {
                // ✅ Update AppStateService with the returned streak values
                if (result['progress_history'] != null) {
                  appState.updateStreakValues(
                    currentStreak: result['progress_history']['current_streak'] ?? 0,
                    previousStreak: result['progress_history']['previous_streak'] ?? 0,
                  );
                }
                
                if (context.mounted) {
                  Navigator.of(dialogContext).pop();
                  _showSuccessDialog(
                    'Streak Restored!',
                    result['message'] ?? 'Your streak has been restored!',
                  );
                }
              } else {
                // Error
                setState(() {
                  isLoading = false;
                });
                
                if (context.mounted) {
                  Navigator.of(dialogContext).pop();
                  _showErrorDialog(storeService.error ?? 'Failed to use streak reviver');
                }
              }
            },
            onCancel: () {
              // Dialog already closes itself, no need to pop again
            },
          );
        },
      ),
    );
  }

  // Use streak freeze
  Future<void> _useStreakFreeze(BuildContext context, StoreService storeService) async {
    HapticUtils.mediumImpact();
    
    // Check if user has any streak freezes
    if (storeService.streakFreezes <= 0) {
      _showErrorDialog('You don\'t have any streak freezes. Purchase one from the store!');
      return;
    }

    // Check if user has an active streak
    final appState = Provider.of<AppStateService>(context, listen: false);
    if (appState.currentStreak <= 0) {
      _showErrorDialog('You need an active streak to use a streak freeze!');
      return;
    }
    
    // Check if there's already an active freeze for today
    final today = DateTime.now();
    if (appState.activeFreezeDate != null) {
      final freezeDate = appState.activeFreezeDate!;
      if (freezeDate.year == today.year && 
          freezeDate.month == today.month && 
          freezeDate.day == today.day) {
        _showErrorDialog('You already have a streak freeze active for today!');
        return;
      }
    }

    // Show confirmation dialog
    await _showUseStreakFreezeDialog(context, storeService, appState);
  }

  // Show use streak freeze confirmation dialog
  Future<void> _showUseStreakFreezeDialog(
    BuildContext context,
    StoreService storeService,
    AppStateService appState,
  ) async {
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return ItemUsageConfirmationDialog(
            title: 'Protect Your Streak?',
            description: 'Use a Streak Freeze to protect your ${appState.currentStreak}-day streak for today?',
            itemName: 'Streak Freeze',
            icon: Icons.ac_unit,
            iconColor: AppTheme.secondaryBlue,
            confirmButtonText: 'Freeze Streak',
            isLoading: isLoading,
            onConfirm: () async {
              setState(() {
                isLoading = true;
              });

                    final result = await storeService.useStreakFreeze();
                    
                    if (result != null) {
                      // ✅ Freeze date is now automatically updated in StoreService
                
                if (context.mounted) {
                  Navigator.of(dialogContext).pop();
                  _showSuccessDialog(
                    'Streak Protected!',
                    result['message'] ?? 'Your streak is protected for today!',
                  );
                }
              } else {
                // Error
                setState(() {
                  isLoading = false;
                });
                
                if (context.mounted) {
                  Navigator.of(dialogContext).pop();
                  _showErrorDialog(storeService.error ?? 'Failed to use streak freeze');
                }
              }
            },
            onCancel: () {
              // Dialog already closes itself, no need to pop again
            },
          );
        },
      ),
    );
  }

  // Show purchase confirmation dialog
  Future<bool> _showPurchaseConfirmationDialog({
    required String itemName,
    required int treatCost,
    required IconData icon,
    required Color color,
    required String description,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppTheme.white,
                  size: 40,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Title
              Text(
                'Purchase $itemName?',
                style: TextStyle(
                  fontFamily: AppTheme.fontPottaOne,
                  fontSize: 22,
                  color: AppTheme.primaryYellow,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Description
              Text(
                description,
                style: TextStyle(
                  fontFamily: AppTheme.fontPoppins,
                  fontSize: 14,
                  color: AppTheme.primaryGray,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 20),
              
              // Treat cost display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.brown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.brown.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      AppAssets.treatIcon,
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$treatCost Treats',
                      style: TextStyle(
                        fontFamily: AppTheme.fontPoppins,
                        fontSize: 20,
                        color: Colors.brown,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: BravoButton(
                      text: 'Cancel',
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      color: Colors.grey.shade400,
                      backColor: Colors.grey.shade300,
                      textColor: AppTheme.primaryGray,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Confirm button
                  Expanded(
                    child: BravoButton(
                      text: 'Get It!',
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      color: color,
                      backColor: color.withOpacity(0.8),
                      textColor: AppTheme.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ) ?? false; // Return false if dialog is dismissed
  }

  // Show success dialog
  void _showSuccessDialog(String itemName, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Purchase Successful!',
            style: TextStyle(
              fontFamily: AppTheme.fontPottaOne,
              fontSize: 20,
              color: AppTheme.primaryYellow,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            message,
            style: TextStyle(
              fontFamily: AppTheme.fontPoppins,
              fontSize: 16,
              color: AppTheme.primaryGray,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: BravoButton(
                text: 'Awesome!',
                onPressed: () {
                  Navigator.of(context).pop();
                },
                color: AppTheme.primaryYellow,
                backColor: AppTheme.primaryYellow.withOpacity(0.8),
                textColor: AppTheme.white,
              ),
            ),
          ],
        );
      },
    );
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Purchase Failed',
            style: TextStyle(
              fontFamily: AppTheme.fontPottaOne,
              fontSize: 20,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            message,
            style: TextStyle(
              fontFamily: AppTheme.fontPoppins,
              fontSize: 16,
              color: AppTheme.primaryGray,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: BravoButton(
                text: 'Got it!',
                onPressed: () {
                  Navigator.of(context).pop();
                },
                color: Colors.red,
                backColor: Colors.red.withOpacity(0.8),
                textColor: AppTheme.white,
              ),
            ),
          ],
        );
      },
    );
  }

  // Purchase treat package
  Future<void> _purchaseTreatPackage(String packageIdentifier) async {
      // Use the unified purchase service
      final purchaseService = UnifiedPurchaseService.instance;
      final treatAmount = PurchaseConfig.getTreatAmountFromPackageId(packageIdentifier);
      final result = await purchaseService.purchaseProduct(
        productType: ProductType.treats,
        packageIdentifier: packageIdentifier,
        productName: '$treatAmount Treats',
      );
      
      if (result.success) {
        // Show success message
        _showSuccessDialog(
          'Purchase Successful!',
          'You received $treatAmount treats!',
        );
      } else {
        // Show error message
        _showErrorDialog(result.error ?? 'Purchase failed');
      }
  }

  // Show purchase dialog
  void _showPurchaseDialog(String itemName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Coming Soon!',
            style: TextStyle(
              fontFamily: AppTheme.fontPottaOne,
              fontSize: 20,
              color: AppTheme.primaryYellow,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'The $itemName feature will be available soon!',
            style: TextStyle(
              fontFamily: AppTheme.fontPoppins,
              fontSize: 16,
              color: AppTheme.primaryGray,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: BravoButton(
                text: 'Got it!',
                onPressed: () {
                  Navigator.of(context).pop();
                },
                color: AppTheme.primaryYellow,
                backColor: AppTheme.primaryYellow.withOpacity(0.8),
                textColor: AppTheme.white,
              ),
            ),
          ],
        );
      },
    );
  }
}
