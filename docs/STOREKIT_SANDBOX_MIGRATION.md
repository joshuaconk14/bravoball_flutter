# StoreKit to Sandbox Migration - November 17, 2025

## Overview
This document outlines the migration from StoreKit testing to real sandbox testing, the issues encountered, and recommended next steps.

## What We Did Today

### 1. Merged Staging Branch
- **Date**: November 17, 2025
- **Branch**: `pointsSystemTest8` ← `upstream/staging`
- **Result**: Successfully merged 8 commits from staging
- **Key Changes**:
  - Updated `app_config.dart` - TestFlight/production configuration
  - Updated `permission_service.dart` - Android permission simplification
  - Updated `pubspec.yaml` - Version bump to `2.0.1+34`, rive updated to `0.13.20`
  - Preserved our `store_service.dart` improvements (debug logging, error handling)

### 2. Removed StoreKit Configuration from Xcode
- **Issue**: App was using StoreKit testing even with sandbox Apple ID
- **Root Cause**: Xcode scheme had `BravoBall-StoreKit.storekit` configured
- **Solution**: Removed StoreKit configuration from Xcode scheme
  - File: `ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme`
  - Removed `<StoreKitConfigurationFileReference>` from LaunchAction
- **Result**: Scheme file updated, StoreKit configuration removed

### 3. Fixed Purchase Verification Timing
- **Issue**: Backend couldn't find transactions in RevenueCat API immediately after purchase
- **Root Cause**: RevenueCat backend API takes 3-5 seconds to sync transactions
- **Solution**: Added 3-second delay + CustomerInfo refresh before backend verification
  - File: `lib/services/unified_purchase_service.dart`
  - Added delay and refresh logic for treat purchases

## What Went Wrong

### Issue 1: StoreKit Transaction IDs Still Being Sent
**Problem**: 
- App is sending StoreKit test transaction IDs (`o1_...`) instead of real sandbox transaction IDs (`2000001059010649`)
- RevenueCat dashboard shows correct sandbox transaction IDs
- Backend verification works (uses product ID + user ID for idempotency), but wrong transaction ID is sent

**Evidence**:
```
RevenueCat Logs: INFO: 💰 Finishing transaction '2000001059010649' (sandbox)
JWS Token: "transactionId":"2000001059010649" (sandbox)
Flutter Code: Transaction: o1_bJI5hCFcWcJFp2SxdQUyIw (StoreKit test ID)
```

**Root Cause (Uncertain)**:
1. **Most Likely**: `StoreTransaction.transactionIdentifier` returns cached StoreKit transaction IDs from previous purchases when StoreKit was configured
2. **Alternative**: `StoreTransaction.transactionIdentifier` might return RevenueCat's internal transaction ID format, not the App Store transaction ID
3. **Alternative**: Multiple transactions exist (old StoreKit + new sandbox), and code picks the wrong one

**Current Code** (`lib/services/store_service.dart:482-486`):
```dart
for (final tx in nonSubscriptionTransactions) {
  if (tx.productIdentifier == productId) {
    transaction = tx;  // ← Picks FIRST match, might be old StoreKit transaction
    break;
  }
}
```

### Issue 2: RevenueCat CustomerInfo Caching
- RevenueCat caches `CustomerInfo` to reduce API calls
- Cache updates: every 5 minutes (foreground), 25 hours (background), or after purchase
- Old StoreKit transactions may persist in cache even after removing StoreKit configuration

## Current Status

### ✅ What's Working
- Backend verification succeeds (uses product ID + user ID for idempotency)
- Treats are being granted correctly
- Sandbox purchases are completing successfully
- RevenueCat dashboard shows correct sandbox transaction IDs

### ⚠️ What's Not Ideal
- Wrong transaction ID being sent to backend (`o1_...` instead of `2000001059010649`)
- Backend can't verify transactions by transaction ID (relies on product ID + user ID)
- Potential confusion in logs/debugging

## Recommended Next Steps

### Priority 1: Fix Transaction ID Extraction

**Option A: Filter Out StoreKit Transactions** (Recommended)
```dart
// In lib/services/store_service.dart, modify transaction selection:
// Find the transaction for this product, excluding StoreKit test transactions
for (final tx in nonSubscriptionTransactions) {
  if (tx.productIdentifier == productId) {
    // Skip StoreKit test transactions (they start with "o1_")
    if (!tx.transactionIdentifier.startsWith('o1_')) {
      transaction = tx;
      break;
    }
  }
}

// If no non-StoreKit transaction found, use most recent real transaction
if (transaction == null && nonSubscriptionTransactions.isNotEmpty) {
  final realTransactions = nonSubscriptionTransactions
      .where((tx) => !tx.transactionIdentifier.startsWith('o1_'))
      .toList();
  
  if (realTransactions.isNotEmpty) {
    // Sort by purchase date (most recent first)
    realTransactions.sort((a, b) {
      final aDate = a.purchaseDate is DateTime 
          ? a.purchaseDate as DateTime 
          : DateTime.parse(a.purchaseDate.toString());
      final bDate = b.purchaseDate is DateTime 
          ? b.purchaseDate as DateTime 
          : DateTime.parse(b.purchaseDate.toString());
      return bDate.compareTo(aDate);
    });
    transaction = realTransactions.first;
  }
}
```

**Option B: Extract from JWS Token** (If Option A doesn't work)
- The JWS token contains the real transaction ID in its payload
- Would require decoding the JWS token to extract `transactionId` field
- More complex but guaranteed to get correct ID

**Option C: Use RevenueCat API Response** (Most reliable)
- After purchase, query RevenueCat's API directly for the transaction
- Use the transaction ID from RevenueCat's API response instead of `StoreTransaction`
- Requires additional API call but ensures accuracy

### Priority 2: Clear RevenueCat Cache

**Add cache invalidation** before purchase verification:
```dart
// In lib/services/unified_purchase_service.dart, before verification:
// Invalidate RevenueCat cache to ensure fresh data
try {
  await Purchases.invalidateCustomerInfoCache();
  final refreshedCustomerInfo = await revenueCat.getCustomerInfo();
  // Use refreshedCustomerInfo instead of original customerInfo
} catch (e) {
  // Fallback to original customerInfo if cache invalidation fails
}
```

### Priority 3: Add Debug Logging

**Add comprehensive logging** to understand what's in `StoreTransaction`:
```dart
if (kDebugMode) {
  print('🔍 All non-subscription transactions:');
  for (final tx in nonSubscriptionTransactions) {
    print('   Product: ${tx.productIdentifier}');
    print('   Transaction ID: ${tx.transactionIdentifier}');
    print('   Purchase Date: ${tx.purchaseDate}');
    print('   Transaction object: $tx');
    print('   Transaction type: ${tx.runtimeType}');
    print('   ---');
  }
}
```

### Priority 4: Investigate `useLocalStoreKit` Flag

**Current Status**: 
- `useLocalStoreKit` flag exists but doesn't control StoreKit usage
- StoreKit usage is controlled by Xcode scheme configuration
- Flag only affects package lookup logic (product ID vs package identifier)

**Recommendation**: 
- Test if flag is still needed
- If not needed, remove it
- If needed, rename to `useProductIdLookup` to reflect actual purpose

## Technical Details

### StoreKit vs Sandbox Transaction IDs

**StoreKit Test Transactions**:
- Format: `o1_...` (e.g., `o1_bJI5hCFcWcJFp2SxdQUyIw`)
- Environment: `"xcode"` in receipt
- Not synced to RevenueCat backend API
- Local/simulated transactions

**Sandbox Transactions**:
- Format: Numeric (e.g., `2000001059010649`)
- Environment: `"Sandbox"` in receipt
- Synced to RevenueCat backend API
- Real App Store Connect transactions

### RevenueCat Transaction Flow

1. **Purchase Completes** → RevenueCat SDK receives transaction
2. **SDK Processes** → Sends receipt to RevenueCat backend
3. **Backend Syncs** → Takes 3-5 seconds for consumables
4. **API Query** → Backend can query RevenueCat API for transaction
5. **Client Cache** → `CustomerInfo` cached locally (may contain old transactions)

### Files Modified Today

1. `lib/services/unified_purchase_service.dart`
   - Added 3-second delay before backend verification
   - Added CustomerInfo refresh logic
   - Added transaction logging

2. `ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme`
   - Removed StoreKit configuration file reference

3. `lib/config/app_config.dart`
   - Updated from staging merge (TestFlight config)
   - Restored localhost settings (`appDevCase = 3`)

## Testing Checklist

- [ ] Verify StoreKit configuration is removed from Xcode scheme
- [ ] Test purchase with sandbox Apple ID
- [ ] Check logs for transaction ID format (should be numeric, not `o1_`)
- [ ] Verify backend receives correct transaction ID
- [ ] Test that backend can find transaction in RevenueCat API
- [ ] Clear RevenueCat cache and test again
- [ ] Verify no StoreKit transactions in `nonSubscriptionTransactions` array

## Questions to Investigate

1. Why does `StoreTransaction.transactionIdentifier` return StoreKit IDs even in sandbox?
2. Is there a property on `StoreTransaction` that contains the App Store transaction ID?
3. Should we extract transaction ID from JWS token instead?
4. Can we query RevenueCat API directly for the transaction ID?
5. Is `useLocalStoreKit` flag still needed?

## References

- RevenueCat Caching: https://www.revenuecat.com/docs/test-and-launch/debugging/caching
- StoreKit Configuration: Xcode scheme settings
- Sandbox Testing Guide: `docs/SANDBOX_TESTING_GUIDE.md`

## Notes

- Backend verification currently works via product ID + user ID (idempotency check)
- Transaction ID mismatch doesn't break functionality, but should be fixed for accuracy
- Consider implementing Option A (filter StoreKit transactions) as quick fix
- Long-term: investigate proper way to get App Store transaction ID from RevenueCat SDK

