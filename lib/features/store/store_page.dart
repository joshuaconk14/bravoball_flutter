import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:flutter/painting.dart' as painting;
import '../../constants/app_theme.dart';
import '../../widgets/bravo_button.dart';
import '../../utils/haptic_utils.dart';
import '../premium/premium_page.dart';

class StorePage extends StatefulWidget {
  const StorePage({Key? key}) : super(key: key);

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Header section
                    _buildHeader(),
                    
                    // Store items section
                    _buildStoreItems(),
                    
                    const SizedBox(height: 32),
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
              
              // Placeholder for balance or other info
              Container(
                width: 36,
                height: 36,
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

  // Store items section
  Widget _buildStoreItems() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Streak Freeze Item
          _buildStoreItem(
            title: 'Streak Freeze',
            description: 'Freeze your streak for 24 hours',
            icon: Icons.ac_unit,
            price: '50 Treats',
            color: AppTheme.secondaryBlue,
            onTap: () {
              HapticUtils.mediumImpact();
              _showPurchaseDialog('Streak Freeze');
            },
          ),
          
          const SizedBox(height: 20),
          
          // Streak Recovery Item
          _buildStoreItem(
            title: 'Streak Recovery',
            description: 'Restore your broken streak',
            icon: Icons.restore,
            price: '100 Treats',
            color: AppTheme.secondaryOrange,
            onTap: () {
              HapticUtils.mediumImpact();
              _showPurchaseDialog('Streak Recovery');
            },
          ),
          
          const SizedBox(height: 30),
          
          // Treat Packages Section
          _buildTreatPackages(),
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
          onTap: () {
            HapticUtils.mediumImpact();
            _showPurchaseDialog('Watch Ad');
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
