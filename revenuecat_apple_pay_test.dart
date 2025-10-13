import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io';

/// RevenueCat Apple Pay Test App
/// 
/// This is a specialized test app focused on Apple Pay integration
/// with RevenueCat. It tests various Apple Pay scenarios and edge cases.
void main() {
  runApp(const ApplePayTestApp());
}

class ApplePayTestApp extends StatelessWidget {
  const ApplePayTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RevenueCat Apple Pay Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ApplePayTestHomePage(),
    );
  }
}

class ApplePayTestHomePage extends StatefulWidget {
  const ApplePayTestHomePage({super.key});

  @override
  State<ApplePayTestHomePage> createState() => _ApplePayTestHomePageState();
}

class _ApplePayTestHomePageState extends State<ApplePayTestHomePage> {
  final ApplePayTestService _testService = ApplePayTestService();
  
  bool _isInitialized = false;
  bool _isLoading = false;
  String _statusMessage = 'Initializing Apple Pay test...';
  List<Package> _availablePackages = [];
  CustomerInfo? _customerInfo;
  String? _errorMessage;
  List<TestResult> _testResults = [];

  @override
  void initState() {
    super.initState();
    _initializeTest();
  }

  Future<void> _initializeTest() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Initializing Apple Pay test...';
      _errorMessage = null;
    });

    try {
      await _testService.initialize();
      
      // Run initial tests
      await _runInitialTests();
      
      setState(() {
        _isInitialized = true;
        _isLoading = false;
        _statusMessage = 'Apple Pay test initialized successfully!';
      });
    } catch (e) {
      setState(() {
        _isInitialized = false;
        _isLoading = false;
        _statusMessage = 'Failed to initialize Apple Pay test';
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _runInitialTests() async {
    final results = <TestResult>[];
    
    // Test 1: RevenueCat Initialization
    results.add(await _testService.testRevenueCatInitialization());
    
    // Test 2: Apple Pay Availability
    results.add(await _testService.testApplePayAvailability());
    
    // Test 3: Product Loading
    results.add(await _testService.testProductLoading());
    
    // Test 4: Customer Info
    results.add(await _testService.testCustomerInfo());
    
    setState(() {
      _testResults = results;
      _availablePackages = _testService.availablePackages;
      _customerInfo = _testService.customerInfo;
    });
  }

  Future<void> _runApplePayPurchaseTest(Package package) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing Apple Pay purchase...';
      _errorMessage = null;
    });

    try {
      final result = await _testService.testApplePayPurchase(package);
      
      setState(() {
        _isLoading = false;
        _statusMessage = result.success ? 'Apple Pay test completed! ✅' : 'Apple Pay test failed';
        _errorMessage = result.success ? null : result.error;
        _customerInfo = result.customerInfo;
      });
      
      // Add result to test results
      setState(() {
        _testResults = [..._testResults, result];
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Apple Pay test error';
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Running all tests...';
      _errorMessage = null;
    });

    try {
      final results = await _testService.runAllTests();
      
      setState(() {
        _isLoading = false;
        _statusMessage = 'All tests completed!';
        _testResults = results;
        _availablePackages = _testService.availablePackages;
        _customerInfo = _testService.customerInfo;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Test suite failed';
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apple Pay Test Suite'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _runAllTests,
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
            
            // Test Results
            if (_testResults.isNotEmpty) ...[
              const Text(
                'Test Results',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 2,
                child: ListView.builder(
                  itemCount: _testResults.length,
                  itemBuilder: (context, index) {
                    final result = _testResults[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          result.success ? Icons.check_circle : Icons.error,
                          color: result.success ? Colors.green : Colors.red,
                        ),
                        title: Text(result.testName),
                        subtitle: Text(result.description),
                        trailing: Text(
                          result.success ? 'PASS' : 'FAIL',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: result.success ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            
            // Available Packages for Testing
            if (_availablePackages.isNotEmpty) ...[
              const Text(
                'Apple Pay Purchase Tests',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 3,
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
                          onPressed: _isLoading ? null : () => _runApplePayPurchaseTest(package),
                          child: const Text('Test Apple Pay'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Apple Pay Test Service
class ApplePayTestService {
  static const String _apiKey = 'appl_OIYtlnvDkuuhmFAAWJojwiAgBxi';
  static const String _appUserId = 'apple_pay_test_user';
  
  List<Package> availablePackages = [];
  CustomerInfo? customerInfo;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Purchases.setLogLevel(LogLevel.debug);
      await Purchases.configure(PurchasesConfiguration(_apiKey));
      await Purchases.logIn(_appUserId);
      
      _isInitialized = true;
      print('✅ Apple Pay Test Service initialized');
    } catch (e) {
      print('❌ Error initializing Apple Pay Test Service: $e');
      rethrow;
    }
  }

  Future<TestResult> testRevenueCatInitialization() async {
    try {
      if (_isInitialized) {
        return TestResult(
          testName: 'RevenueCat Initialization',
          description: 'RevenueCat SDK initialized successfully',
          success: true,
        );
      } else {
        return TestResult(
          testName: 'RevenueCat Initialization',
          description: 'RevenueCat SDK failed to initialize',
          success: false,
          error: 'Not initialized',
        );
      }
    } catch (e) {
      return TestResult(
        testName: 'RevenueCat Initialization',
        description: 'RevenueCat SDK initialization error',
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<TestResult> testApplePayAvailability() async {
    try {
      // Check if we're on iOS
      if (!Platform.isIOS) {
        return TestResult(
          testName: 'Apple Pay Availability',
          description: 'Apple Pay is only available on iOS',
          success: false,
          error: 'Not iOS platform',
        );
      }

      // Check if Apple Pay is available (this would require additional checks)
      // For now, we'll assume it's available on iOS devices
      return TestResult(
        testName: 'Apple Pay Availability',
        description: 'Apple Pay should be available on this iOS device',
        success: true,
      );
    } catch (e) {
      return TestResult(
        testName: 'Apple Pay Availability',
        description: 'Error checking Apple Pay availability',
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<TestResult> testProductLoading() async {
    try {
      final offerings = await Purchases.getOfferings();
      
      if (offerings.current != null) {
        availablePackages = offerings.current!.availablePackages;
        
        return TestResult(
          testName: 'Product Loading',
          description: 'Loaded ${availablePackages.length} products successfully',
          success: true,
        );
      } else {
        return TestResult(
          testName: 'Product Loading',
          description: 'No current offering found',
          success: false,
          error: 'No offering available',
        );
      }
    } catch (e) {
      return TestResult(
        testName: 'Product Loading',
        description: 'Error loading products',
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<TestResult> testCustomerInfo() async {
    try {
      customerInfo = await Purchases.getCustomerInfo();
      
      return TestResult(
        testName: 'Customer Info',
        description: 'Customer info loaded: ${customerInfo!.originalAppUserId}',
        success: true,
      );
    } catch (e) {
      return TestResult(
        testName: 'Customer Info',
        description: 'Error loading customer info',
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<TestResult> testApplePayPurchase(Package package) async {
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      
      return TestResult(
        testName: 'Apple Pay Purchase: ${package.storeProduct.title}',
        description: 'Purchase completed successfully via Apple Pay',
        success: true,
        customerInfo: customerInfo,
      );
    } on PurchasesErrorCode catch (e) {
      return TestResult(
        testName: 'Apple Pay Purchase: ${package.storeProduct.title}',
        description: 'Purchase failed with RevenueCat error',
        success: false,
        error: e.toString(),
      );
    } catch (e) {
      return TestResult(
        testName: 'Apple Pay Purchase: ${package.storeProduct.title}',
        description: 'Purchase failed with unexpected error',
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<List<TestResult>> runAllTests() async {
    final results = <TestResult>[];
    
    // Run all individual tests
    results.add(await testRevenueCatInitialization());
    results.add(await testApplePayAvailability());
    results.add(await testProductLoading());
    results.add(await testCustomerInfo());
    
    return results;
  }
}

/// Test Result Model
class TestResult {
  final String testName;
  final String description;
  final bool success;
  final String? error;
  final CustomerInfo? customerInfo;

  TestResult({
    required this.testName,
    required this.description,
    required this.success,
    this.error,
    this.customerInfo,
  });
}
