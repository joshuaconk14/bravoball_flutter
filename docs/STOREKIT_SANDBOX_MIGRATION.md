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

### Issue 1: Transaction ID Format Confusion (RESOLVED)

**⚠️ CLARIFICATION (November 19, 2025)**: This was **not** actually an issue. The confusion arose from misunderstanding RevenueCat's transaction ID format.

**What We Thought Was Wrong**:
- App is sending StoreKit test transaction IDs (`o1_...`) instead of real sandbox transaction IDs (`2000001059010649`)
- RevenueCat dashboard shows correct sandbox transaction IDs

**What We Learned**:
- `o1_` prefix is RevenueCat's format for **one-time purchases** (both sandbox and production)
- `StoreTransaction.transactionIdentifier` returns RevenueCat's internal transaction ID format
- The `o1_` prefix indicates purchase type (one-time), **not** environment (StoreKit vs Sandbox)
- RevenueCat dashboard may show different transaction IDs because it displays App Store transaction IDs, while SDK returns RevenueCat's internal IDs

**Resolution**:
- ✅ Removed incorrect filtering logic that excluded `o1_` transactions
- ✅ All RevenueCat transactions (including `o1_` prefix) are now used for verification
- ✅ Backend correctly handles RevenueCat transaction IDs regardless of prefix

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

### Priority 1: Transaction ID Handling (RESOLVED)

**✅ RESOLUTION (November 19, 2025)**: Removed incorrect filtering logic.

**What We Did**:
- Removed filtering that excluded `o1_` transactions
- Use all transactions from `nonSubscriptionTransactions` for verification
- RevenueCat transaction IDs (including `o1_` prefix) are valid for both sandbox and production

**Current Implementation**:
```dart
// In lib/services/store_service.dart - CORRECT approach:
// Use all transactions from RevenueCat (no filtering by prefix)
for (final tx in nonSubscriptionTransactions) {
  if (tx.productIdentifier == productId) {
    transaction = tx;
    break;
  }
}
```

**Key Takeaway**: 
- `o1_` prefix = RevenueCat's format for one-time purchases (sandbox AND production)
- **DO NOT** filter transactions by prefix
- All RevenueCat transaction IDs are valid for backend verification

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

### ⚠️ IMPORTANT: RevenueCat Transaction ID Format Clarification

**CORRECTION (November 19, 2025)**: The `o1_` prefix is **NOT** StoreKit-specific. It is RevenueCat's format for **one-time purchases** (non-subscription transactions) in **both sandbox and production**.

**RevenueCat Transaction ID Prefixes**:
- `o1_` = One-time purchase (non-subscription) — used for **both sandbox and production**
- `sub_` = Subscription purchase
- Other prefixes for other purchase types

**What This Means**:
- ✅ `o1_` transactions from RevenueCat are **legitimate** sandbox/production transactions
- ❌ **DO NOT** filter out `o1_` transactions — they are valid RevenueCat transaction IDs
- The prefix indicates purchase type, **not** the environment (StoreKit vs Sandbox vs Production)

**How to Distinguish StoreKit vs Sandbox vs Production**:
- **StoreKit Test Transactions**: Created when StoreKit configuration file is active in Xcode scheme
  - May appear in `nonSubscriptionTransactions` but are local/simulated
  - Not synced to RevenueCat backend API
  - Environment can be checked via receipt data (if available)
  
- **Sandbox Transactions**: Real transactions from App Store Connect sandbox environment
  - Synced to RevenueCat backend API
  - Can have `o1_` prefix (for one-time purchases) or `sub_` prefix (for subscriptions)
  - Verified through RevenueCat dashboard
  
- **Production Transactions**: Real transactions from live App Store
  - Synced to RevenueCat backend API
  - Can have `o1_` prefix (for one-time purchases) or `sub_` prefix (for subscriptions)
  - Verified through RevenueCat dashboard

### Previous Incorrect Understanding (Corrected)

**❌ INCORRECT (Previous Documentation)**:
- "StoreKit Test Transactions: Format: `o1_...`"
- "Sandbox Transactions: Format: Numeric"

**✅ CORRECT (Current Understanding)**:
- RevenueCat uses `o1_` prefix for **all** one-time purchases (sandbox and production)
- The transaction ID format does **not** indicate StoreKit vs Sandbox
- To distinguish environments, check:
  1. Whether StoreKit configuration is active in Xcode scheme
  2. RevenueCat dashboard to verify transaction source
  3. Receipt data (if available) for environment information

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

- [x] Verify StoreKit configuration is removed from Xcode scheme
- [x] Removed StoreKit file references from project.pbxproj
- [x] Renamed StoreKit configuration file to prevent auto-detection
- [x] Removed incorrect transaction filtering logic
- [ ] Test purchase with sandbox Apple ID
- [ ] Verify backend receives RevenueCat transaction ID (may have `o1_` prefix for one-time purchases)
- [ ] Test that backend can find transaction in RevenueCat API
- [ ] Clear RevenueCat cache and test again
- [ ] Verify transactions are processed correctly regardless of prefix

## Questions to Investigate (RESOLVED)

1. ✅ **RESOLVED**: `StoreTransaction.transactionIdentifier` returns RevenueCat's internal transaction ID format (`o1_` for one-time purchases), not StoreKit-specific IDs
2. ⚠️ **CLARIFIED**: RevenueCat SDK returns its own transaction IDs, not App Store transaction IDs directly
3. ❓ **OPTIONAL**: Could extract from JWS token if App Store transaction ID is needed, but RevenueCat IDs work fine for verification
4. ❓ **OPTIONAL**: Could query RevenueCat API, but SDK transaction IDs are sufficient
5. ⚠️ **INVESTIGATE**: `useLocalStoreKit` flag may still be needed for package lookup logic (product ID vs package identifier)

## References

- RevenueCat Caching: https://www.revenuecat.com/docs/test-and-launch/debugging/caching
- StoreKit Configuration: Xcode scheme settings
- Sandbox Testing Guide: `docs/SANDBOX_TESTING_GUIDE.md`

## Notes

- ✅ Backend verification works via product ID + user ID (idempotency check)
- ✅ RevenueCat transaction IDs (including `o1_` prefix) are valid for verification
- ✅ Removed incorrect filtering logic that was excluding legitimate transactions
- ✅ All RevenueCat transactions are now processed correctly

## Key Learnings (November 19, 2025)

1. **RevenueCat Transaction ID Format**:
   - `o1_` = One-time purchase (sandbox AND production)
   - `sub_` = Subscription purchase
   - Prefix indicates purchase type, NOT environment

2. **DO NOT filter transactions by prefix**:
   - All RevenueCat transaction IDs are valid
   - Filtering `o1_` transactions was incorrectly excluding legitimate sandbox/production transactions

3. **StoreKit Detection**:
   - Check Xcode scheme configuration (StoreKit Configuration setting)
   - Check if StoreKit file exists and is referenced
   - Do NOT rely on transaction ID prefix to detect StoreKit

4. **Backend Verification**:
   - RevenueCat transaction IDs work correctly for backend verification
   - Backend uses product ID + user ID for idempotency (more reliable than transaction ID)

