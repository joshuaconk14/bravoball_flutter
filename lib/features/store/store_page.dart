import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:rive/rive.dart';
import 'package:flutter/painting.dart' as painting;
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../widgets/bravo_button.dart';
import '../../utils/haptic_utils.dart';
import '../../utils/premium_utils.dart';
import '../../services/store_service.dart';
import '../../services/ad_service.dart';
import '../premium/premium_page.dart';

class StorePage extends StatefulWidget {
  const StorePage({Key? key}) : super(key: key);

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  bool _isPremium = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
    _initializeStoreService();
  }

  Future<void> _initializeStoreService() async {
    await StoreService.instance.initialize();
  }

  Future<void> _checkPremiumStatus() async {
    try {
      final isPremium = await PremiumUtils.hasPremiumAccess();
      setState(() {
        _isPremium = isPremium;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isPremium = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top bar
          _buildTopBar(context),
          
          // Main content
          Expanded(
            child: Container(
              color: Colors.white,
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
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
                  ),
              ),
            ),
          ],
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
              
              // Treats balance display - matches front page style
              Consumer<StoreService>(
                builder: (context, storeService, child) {
                  return Row(
                    children: [
                      Icon(
                        Icons.diamond,
                        color: Colors.brown,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${storeService.treats}', // Real treat count from API
                        style: TextStyle(
                          fontFamily: AppTheme.fontPoppins,
                          fontSize: 20,
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
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Streak Reviver
                    _buildMyItemSquare(
                      title: 'Streak Reviver',
                      amount: storeService.streakRevivers,
                      icon: Icons.restore,
                      color: AppTheme.secondaryOrange,
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
  }) {
    return Container(
      width: 160, // Increased width for larger squares
      height: 160, // Increased height for larger squares
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
                price: '50 Treats',
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
                price: '100 Treats',
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
        
        // 500 Treats Package
        _buildTreatPackage(
          amount: '500',
          price: '\$5.99',
          onTap: () {
            HapticUtils.mediumImpact();
            _showPurchaseDialog('500 Treats');
          },
        ),
        
        const SizedBox(height: 12),
        
        // 1000 Treats Package
        _buildTreatPackage(
          amount: '1000',
          price: '\$9.99',
          isPopular: true,
          onTap: () {
            HapticUtils.mediumImpact();
            _showPurchaseDialog('1000 Treats');
          },
        ),
        
        const SizedBox(height: 12),
        
        // 2000 Treats Package
        _buildTreatPackage(
          amount: '2000',
          price: '\$19.99',
          onTap: () {
            HapticUtils.mediumImpact();
            _showPurchaseDialog('2000 Treats');
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
                        '15 Treats',
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
                // Diamond icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryYellow,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.diamond,
                    color: AppTheme.white,
                    size: 20,
                  ),
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
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.primaryYellow),
                const SizedBox(height: 16),
                Text(
                  'Loading ad...',
                  style: TextStyle(
                    fontFamily: AppTheme.fontPoppins,
                    fontSize: 16,
                    color: AppTheme.primaryGray,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Show rewarded ad
      final rewardAmount = await AdService.instance.showRewardedAd();
      
      // Close loading dialog
      Navigator.of(context).pop();

      if (rewardAmount > 0) {
        // Add treats to user's account
        final storeService = StoreService.instance;
        await storeService.addTreatsReward(rewardAmount);

        // Show success message
        _showSuccessDialog(
          'Treats Earned!',
          'You earned $rewardAmount treats for watching the ad!',
        );
      } else if (rewardAmount == -1) {
        // Ad failed to load or is disabled
        _showErrorDialog('Ad failed to load. Please try again later.');
      } else {
        // User closed ad early without completing it
        _showErrorDialog('Ad was not completed. Please watch the full ad to earn treats.');
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

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
      treatCost: 50,
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
      treatCost: 100,
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
                    Icon(
                      Icons.diamond,
                      color: Colors.brown,
                      size: 28,
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
