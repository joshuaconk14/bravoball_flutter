import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io';

/// RevenueCat Test App
/// 
/// This is a standalone test application for validating RevenueCat integration
/// and Apple Pay functionality. It's completely separate from the main app
/// but uses the same product IDs and configuration.
/// 
/// To run this test app:
/// 1. Make sure you have your RevenueCat API keys set up
/// 2. Update the RevenueCat configuration below
/// 3. Run: flutter run revenuecat_test_app.dart
void main() {
  runApp(const RevenueCatTestApp());
}

class RevenueCatTestApp extends StatelessWidget {
  const RevenueCatTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RevenueCat Test App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const RevenueCatTestHomePage(),
    );
  }
}

class RevenueCatTestHomePage extends StatefulWidget {
  const RevenueCatTestHomePage({super.key});

  @override
  State<RevenueCatTestHomePage> createState() => _RevenueCatTestHomePageState();
}

class _RevenueCatTestHomePageState extends State<RevenueCatTestHomePage> {
  final RevenueCatTestService _testService = RevenueCatTestService();
  
  bool _isInitialized = false;
  bool _isLoading = false;
  String _statusMessage = 'Initializing RevenueCat...';
  List<Package> _availablePackages = [];
  CustomerInfo? _customerInfo;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeRevenueCat();
  }

  Future<void> _initializeRevenueCat() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Initializing RevenueCat...';
      _errorMessage = null;
    });

    try {
      await _testService.initialize();
      
      // Get available packages
      final packages = await _testService.getAvailablePackages();
      
      // Get customer info
      final customerInfo = await _testService.getCustomerInfo();
      
      setState(() {
        _isInitialized = true;
        _isLoading = false;
        _statusMessage = 'RevenueCat initialized successfully!';
        _availablePackages = packages;
        _customerInfo = customerInfo;
      });
    } catch (e) {
      setState(() {
        _isInitialized = false;
        _isLoading = false;
        _statusMessage = 'Failed to initialize RevenueCat';
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _makePurchase(Package package) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Processing purchase...';
      _errorMessage = null;
    });

    try {
      final customerInfo = await _testService.makePurchase(package);
      
      if (customerInfo != null) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Purchase successful! ✅';
          _customerInfo = customerInfo;
        });
      } else {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Purchase failed';
          _errorMessage = 'Purchase was cancelled or failed';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Purchase error';
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Restoring purchases...';
      _errorMessage = null;
    });

    try {
      final customerInfo = await _testService.restorePurchases();
      
      if (customerInfo != null) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Purchases restored successfully! ✅';
          _customerInfo = customerInfo;
        });
      } else {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Restore failed';
          _errorMessage = 'Restore was cancelled or failed';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Restore error';
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RevenueCat Test App'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _initializeRevenueCat,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isInitialized ? Icons.check_circle : Icons.error,
                          color: _isInitialized ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Status: $_statusMessage',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Error: $_errorMessage',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    if (_isLoading) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Customer Info Card
            if (_customerInfo != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Customer Info',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text('User ID: ${_customerInfo!.originalAppUserId}'),
                      Text('Active Subscriptions: ${_customerInfo!.activeSubscriptions.length}'),
                      if (_customerInfo!.activeSubscriptions.isNotEmpty)
                        Text('Products: ${_customerInfo!.activeSubscriptions.join(', ')}'),
                      Text('Entitlements: ${_customerInfo!.entitlements.active.keys.join(', ')}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Available Packages
            if (_availablePackages.isNotEmpty) ...[
              const Text(
                'Available Packages',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _availablePackages.length,
                  itemBuilder: (context, index) {
                    final package = _availablePackages[index];
                    return Card(
                      child: ListTile(
                        title: Text(package.storeProduct.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(package.storeProduct.description),
                            Text(
                              '${package.storeProduct.priceString} / ${package.packageType}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: _isLoading ? null : () => _makePurchase(package),
                          child: const Text('Purchase'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            
            // Restore Button
            if (_isInitialized) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _restorePurchases,
                  icon: const Icon(Icons.restore),
                  label: const Text('Restore Purchases'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// RevenueCat Test Service
/// 
/// This service handles all RevenueCat operations for testing.
/// It's designed to be easily integrated into your main app later.
class RevenueCatTestService {
  static const String _apiKey = 'appl_OIYtlnvDkuuhmFAAWJojwiAgBxi'; // Your RevenueCat API key
  static const String _appUserId = 'test_user_123'; // Test user ID
  
  // Product IDs - these should match your App Store Connect products
  static const String monthlyPremiumId = 'bravoball_monthly_premium';
  static const String yearlyPremiumId = 'bravoball_yearly_premium';
  
  bool _isInitialized = false;

  /// Initialize RevenueCat
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configure RevenueCat
      await Purchases.setLogLevel(LogLevel.debug); // Enable debug logging
      
      // Initialize with your API key
      await Purchases.configure(PurchasesConfiguration(_apiKey));
      
      // Set user ID (optional, RevenueCat will generate one if not set)
      await Purchases.logIn(_appUserId);
      
      _isInitialized = true;
      
      print('✅ RevenueCat initialized successfully');
      print('🔑 API Key: ${_apiKey.substring(0, 10)}...');
      print('👤 User ID: $_appUserId');
    } catch (e) {
      print('❌ Error initializing RevenueCat: $e');
      rethrow;
    }
  }

  /// Get available packages
  Future<List<Package>> getAvailablePackages() async {
    if (!_isInitialized) {
      throw Exception('RevenueCat not initialized');
    }

    try {
      final offerings = await Purchases.getOfferings();
      
      if (offerings.current != null) {
        return offerings.current!.availablePackages;
      } else {
        print('⚠️ No current offering found');
        return [];
      }
    } catch (e) {
      print('❌ Error getting packages: $e');
      rethrow;
    }
  }

  /// Get customer info
  Future<CustomerInfo> getCustomerInfo() async {
    if (!_isInitialized) {
      throw Exception('RevenueCat not initialized');
    }

    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      print('❌ Error getting customer info: $e');
      rethrow;
    }
  }

  /// Make a purchase
  Future<CustomerInfo?> makePurchase(Package package) async {
    if (!_isInitialized) {
      throw Exception('RevenueCat not initialized');
    }

    try {
      final customerInfo = await Purchases.purchasePackage(package);
      return customerInfo;
    } on PurchasesErrorCode catch (e) {
      print('❌ Purchase error: $e');
      return null;
    } catch (e) {
      print('❌ Purchase error: $e');
      return null;
    }
  }

  /// Restore purchases
  Future<CustomerInfo?> restorePurchases() async {
    if (!_isInitialized) {
      throw Exception('RevenueCat not initialized');
    }

    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo;
    } catch (e) {
      print('❌ Restore error: $e');
      return null;
    }
  }

  /// Check if user has premium access
  bool hasPremiumAccess(CustomerInfo customerInfo) {
    // Check if user has any active entitlements
    return customerInfo.entitlements.active.isNotEmpty;
  }

  /// Get premium status details
  Map<String, dynamic> getPremiumStatus(CustomerInfo customerInfo) {
    final activeEntitlements = customerInfo.entitlements.active;
    
    return {
      'hasPremium': activeEntitlements.isNotEmpty,
      'activeEntitlements': activeEntitlements.keys.toList(),
      'activeSubscriptions': customerInfo.activeSubscriptions,
      'allPurchaseDates': customerInfo.allPurchaseDates,
      'latestExpirationDate': customerInfo.latestExpirationDate,
    };
  }
}

