# RevenueCat & StoreKit Implementation Guide

## Overview

This document outlines our RevenueCat and StoreKit implementation for BravoBall, including our unified purchase service architecture and key findings from troubleshooting treat product purchases.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [RevenueCat Configuration](#revenuecat-configuration)
3. [StoreKit Configuration](#storekit-configuration)
4. [Unified Purchase Service](#unified-purchase-service)
5. [Key Findings & Troubleshooting](#key-findings--troubleshooting)
6. [Implementation Details](#implementation-details)
7. [Testing Strategy](#testing-strategy)
8. [Best Practices](#best-practices)

## Architecture Overview

Our app uses a **unified purchase service** that handles both premium subscriptions and treat products through a single, consistent interface.

### Key Components

- **UnifiedPurchaseService**: Centralized purchase handling
- **StoreService**: Manages treat inventory and backend sync
- **RevenueCat**: Handles all App Store/Google Play purchases
- **StoreKit**: Local testing configuration

## RevenueCat Configuration

### API Key
```dart
// In main.dart
final configuration = PurchasesConfiguration('appl_OIYtlnvDkuuhmFAAWJojwiAgBxi');
await Purchases.configure(configuration);
```

### Offerings Structure

We use **two separate offerings** in RevenueCat:

#### 1. Default Offering (`default`)
- **Purpose**: Premium subscriptions
- **Packages**:
  - `PremiumMonthly` → `bravoball_monthly_premium`
  - `PremiumYearly` → `bravoball_yearly_premium`
- **Access**: `offerings.current` (RevenueCat's default)

#### 2. Treats Offering (`bravoball_treats`)
- **Purpose**: Consumable treat packages
- **Packages**:
  - `Treats500` → `bravoball_treats_500`
  - `Treats1000` → `bravoball_treats_1000`
  - `Treats2000` → `bravoball_treats_2000`
- **Access**: `offerings.all['bravoball_treats']` (explicit access required)

### Critical Finding: Offering Access

**Why Premium Works But Treats Failed Initially:**

```dart
// ❌ WRONG - Only looks at default offering
final package = offerings.current!.getPackage(packageIdentifier);

// ✅ CORRECT - Looks at specific offering
final treatsOffering = offerings.all['bravoball_treats'];
final package = treatsOffering.getPackage(packageIdentifier);
```

**Key Insight**: RevenueCat's `offerings.current` automatically points to the offering with identifier `"default"`. Any other offerings require explicit access via `offerings.all['offering_id']`.

## StoreKit Configuration

### Local Testing Setup

Our `ios/BravoBall-StoreKit.storekit` file contains:

```json
{
  "products": [
    {
      "productID": "bravoball_treats_500",
      "referenceName": "BravoBall 500 Treats",
      "type": "Consumable",
      "displayPrice": "4.99"
    },
    {
      "productID": "bravoball_treats_1000", 
      "referenceName": "BravoBall 1000 Treats",
      "type": "Consumable",
      "displayPrice": "9.99"
    },
    {
      "productID": "bravoball_treats_2000",
      "referenceName": "BravoBall 2000 Treats", 
      "type": "Consumable",
      "displayPrice": "19.99"
    }
  ],
  "subscriptionGroups": [
    {
      "subscriptions": [
        {
          "productID": "bravoball_monthly_premium",
          "recurringSubscriptionPeriod": "P1M",
          "displayPrice": "14.99"
        },
        {
          "productID": "bravoball_yearly_premium",
          "recurringSubscriptionPeriod": "P1Y", 
          "displayPrice": "94.99"
        }
      ]
    }
  ]
}
```

### Environment Configuration

```dart
// In app_config.dart
static const bool useLocalStoreKit = true; // Set to false for production
```

## Unified Purchase Service

### Architecture

The `UnifiedPurchaseService` provides a single interface for all purchases:

```dart
class UnifiedPurchaseService extends ChangeNotifier {
  /// Purchase any product (premium subscription or treat package)
  Future<PurchaseResult> purchaseProduct({
    required ProductType productType,
    required String packageIdentifier,
    required String productName,
  });
  
  /// Get available packages for a specific product type
  Future<List<Package>> getAvailablePackages(ProductType productType);
  
  /// Restore previous purchases
  Future<bool> restorePurchases();
}
```

### Product Types

```dart
enum ProductType {
  premium,  // Subscriptions in 'default' offering
  treats,   // Consumables in 'bravoball_treats' offering
}
```

### Usage Examples

#### Premium Subscription Purchase
```dart
final result = await UnifiedPurchaseService.instance.purchaseProduct(
  productType: ProductType.premium,
  packageIdentifier: 'PremiumMonthly',
  productName: 'Monthly Subscription',
);
```

#### Treat Package Purchase
```dart
final result = await UnifiedPurchaseService.instance.purchaseProduct(
  productType: ProductType.treats,
  packageIdentifier: 'Treats1000',
  productName: '1000 Treats',
);
```

### Package Discovery Logic

The service automatically handles different environments:

```dart
// For premium subscriptions
if (offerings.current == null) return [];
return offerings.current!.availablePackages;

// For treat products
final treatsOffering = offerings.all['bravoball_treats'];
if (treatsOffering == null) return [];

// Handle local vs production mapping
if (AppConfig.useLocalStoreKit) {
  // Map package identifiers to product IDs
  treatPackages = treatsOffering.availablePackages
      .where((package) => 
          package.storeProduct.identifier == 'bravoball_treats_500' ||
          package.storeProduct.identifier == 'bravoball_treats_1000' ||
          package.storeProduct.identifier == 'bravoball_treats_2000')
      .toList();
} else {
  // Use RevenueCat package identifiers
  treatPackages = treatsOffering.availablePackages
      .where((package) => package.identifier.startsWith('Treats'))
      .toList();
}

// Sort in desired order: 500, 1000, 2000
treatPackages.sort((a, b) {
  final aAmount = _getTreatAmountFromPackage(a.identifier);
  final bAmount = _getTreatAmountFromPackage(b.identifier);
  return aAmount.compareTo(bAmount);
});
```

## Key Findings & Troubleshooting

### Problem: Treat Products Not Working

**Symptoms:**
- Premium subscriptions worked perfectly
- Treat product purchases failed with "Package not found" errors
- RevenueCat showed products as "Ready to Submit"

**Root Cause:**
Treat products were configured in a separate offering (`bravoball_treats`) but our code was only looking at the `default` offering.

**Solution:**
```dart
// Before (broken)
final package = offerings.current!.getPackage(packageIdentifier);

// After (working)
final treatsOffering = offerings.all['bravoball_treats'];
final package = treatsOffering.getPackage(packageIdentifier);
```

### Environment-Specific Mapping

**Local StoreKit Testing:**
- Uses product IDs: `bravoball_treats_500`, `bravoball_treats_1000`, `bravoball_treats_2000`
- Maps package identifiers to product IDs

**Production:**
- Uses package identifiers: `Treats500`, `Treats1000`, `Treats2000`
- Direct package lookup

### Post-Purchase Handling

**Premium Subscriptions:**
- Handled automatically by RevenueCat
- Entitlements become active immediately
- No additional backend calls needed

**Treat Products:**
- Require manual treat addition to user account
- Calls `StoreService.addTreatsReward()` after successful purchase
- Syncs with backend API

## Implementation Details

### Error Handling

The unified service provides consistent error handling:

```dart
String _getErrorMessage(dynamic error, String productName) {
  if (error is PurchasesError) {
    switch (error.code) {
      case PurchasesErrorCode.purchaseCancelledError:
        return 'Purchase cancelled';
      case PurchasesErrorCode.paymentPendingError:
        return 'Payment is pending';
      case PurchasesErrorCode.productNotAvailableForPurchaseError:
        return '$productName is not available';
      // ... more cases
    }
  }
  return 'Failed to purchase $productName: $error';
}
```

### State Management

```dart
class UnifiedPurchaseService extends ChangeNotifier {
  bool _isPurchasing = false;
  String? _lastError;
  
  bool get isPurchasing => _isPurchasing;
  String? get lastError => _lastError;
}
```

### Purchase Result

```dart
class PurchaseResult {
  final bool success;
  final String productName;
  final String packageIdentifier;
  final String? price;
  final String? error;
  final CustomerInfo? customerInfo;
}
```

## Testing Strategy

### Local Testing
1. Set `useLocalStoreKit = true` in `app_config.dart`
2. Use iOS Simulator with StoreKit configuration file
3. Test both premium subscriptions and treat products
4. Verify package ordering (500, 1000, 2000)

### Production Testing
1. Set `useLocalStoreKit = false` in `app_config.dart`
2. Use TestFlight builds
3. Test with sandbox Apple ID
4. Verify RevenueCat dashboard shows purchases

### Debug Logging

The service provides comprehensive debug logging:

```dart
if (kDebugMode) {
  print('🛒 Unified Purchase: Starting $productType purchase');
  print('   Package: $packageIdentifier');
  print('   Using ${AppConfig.useLocalStoreKit ? 'Local StoreKit' : 'Production'}');
  
  print('🔍 Debug: All available offerings:');
  for (final entry in offerings.all.entries) {
    print('   ${entry.key}: ${entry.value.availablePackages.length} packages');
  }
}
```

## Best Practices

### 1. Offering Organization
- Use `default` offering for main subscriptions
- Use separate offerings for different product categories
- Always access non-default offerings explicitly

### 2. Error Handling
- Provide user-friendly error messages
- Handle cancellation gracefully (not as an error)
- Log detailed errors for debugging

### 3. State Management
- Use ChangeNotifier for reactive UI updates
- Provide loading states for better UX
- Clear errors after successful operations

### 4. Testing
- Test both local StoreKit and production environments
- Verify package ordering and availability
- Test error scenarios (network issues, invalid products)

### 5. Code Organization
- Centralize purchase logic in one service
- Use enums for product types to prevent mistakes
- Separate concerns (purchases vs inventory management)

## Migration Notes

### From Separate Services to Unified Service

**Before:**
- `StoreService.purchaseTreatPackage()`
- `PremiumPage._purchasePackage()`
- Duplicate RevenueCat logic

**After:**
- `UnifiedPurchaseService.purchaseProduct()`
- Single purchase interface
- Consistent error handling

### Removed Files
- `revenuecat_test_app.dart`
- `revenuecat_apple_pay_test.dart`
- `revenuecat_comprehensive_test.dart`
- `revenuecat_config_template.dart`
- Various test documentation files

## Conclusion

Our unified purchase service provides a clean, maintainable solution for handling both premium subscriptions and treat products. The key insight was understanding RevenueCat's offering structure and ensuring we access the correct offering for each product type.

The implementation is production-ready and provides:
- Consistent user experience
- Comprehensive error handling
- Easy testing and debugging
- Maintainable codebase
- Scalable architecture for future product types
