import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'lib/config/app_config.dart';

/// Debug script to test treat products configuration
/// Run this to see what offerings and packages are available
void main() async {
  print('🔍 Debug: Treat Products Configuration');
  print('=====================================');
  
  try {
    // Initialize RevenueCat
    final configuration = PurchasesConfiguration('appl_OIYtlnvDkuuhmFAAWJojwiAgBxi');
    await Purchases.configure(configuration);
    
    print('✅ RevenueCat initialized');
    print('🔧 Using Local StoreKit: ${AppConfig.useLocalStoreKit}');
    print('');
    
    // Get all offerings
    final offerings = await Purchases.getOfferings();
    
    print('📦 Available Offerings:');
    print('======================');
    
    if (offerings.all.isEmpty) {
      print('❌ No offerings found!');
      return;
    }
    
    for (final entry in offerings.all.entries) {
      final offeringId = entry.key;
      final offering = entry.value;
      
      print('🏪 Offering: $offeringId');
      print('   Identifier: ${offering.identifier}');
      print('   Description: ${offering.serverDescription}');
      print('   Packages: ${offering.availablePackages.length}');
      
      for (final package in offering.availablePackages) {
        print('     📦 Package: ${package.identifier}');
        print('        Product: ${package.storeProduct.identifier}');
        print('        Price: ${package.storeProduct.priceString}');
        print('        Type: ${package.packageType}');
      }
      print('');
    }
    
    // Check specifically for treats offering
    print('🍪 Treats Offering Check:');
    print('========================');
    
    final treatsOffering = offerings.all['bravoball_treats'];
    if (treatsOffering != null) {
      print('✅ Treats offering found!');
      print('   Identifier: ${treatsOffering.identifier}');
      print('   Packages: ${treatsOffering.availablePackages.length}');
      
      for (final package in treatsOffering.availablePackages) {
        print('   📦 ${package.identifier}: ${package.storeProduct.identifier} - ${package.storeProduct.priceString}');
      }
    } else {
      print('❌ Treats offering NOT found!');
      print('   Available offerings: ${offerings.all.keys.toList()}');
    }
    
    // Test package lookup
    print('');
    print('🔍 Package Lookup Test:');
    print('======================');
    
    if (treatsOffering != null) {
      final testPackages = ['Treats500', 'Treats1000', 'Treats2000'];
      
      for (final packageId in testPackages) {
        final package = treatsOffering.getPackage(packageId);
        if (package != null) {
          print('✅ $packageId: Found - ${package.storeProduct.identifier}');
        } else {
          print('❌ $packageId: NOT FOUND');
        }
      }
    }
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
