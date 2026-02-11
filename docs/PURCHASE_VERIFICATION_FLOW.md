# Purchase Verification Flow - Complete Guide

**Last Updated**: November 19, 2025

## Overview

This document explains the complete flow of how purchase verification works in BravoBall, from the initial purchase through backend verification using RevenueCat.

## Key Concepts

### RevenueCat Transaction IDs

- **`o1_` prefix** = RevenueCat's format for **one-time purchases** (non-subscription)
  - Used for **both sandbox and production** environments
  - Examples: `o1_bJI5hCFcWcJFp2SxdQUyIw`, `o1_KtNA-wnSMWzrj_em1iieuw`
  - **NOT** StoreKit-specific - this is RevenueCat's internal transaction ID format

- **`sub_` prefix** = RevenueCat's format for **subscription purchases**
  - Used for **both sandbox and production** environments

### Store Transaction ID vs RevenueCat Transaction ID

- **RevenueCat Transaction ID** (`o1_...`): RevenueCat's internal identifier
  - Returned by `StoreTransaction.transactionIdentifier`
  - Used by frontend to identify transactions in CustomerInfo
  - Unique per RevenueCat transaction
  - **Note**: Frontend sends this to backend, but backend uses Store Transaction ID for lookup

- **Store Transaction ID** (numeric, e.g., `2000001059005684`): App Store's transaction identifier
  - Stored in RevenueCat backend API
  - **Used by backend to find transactions in RevenueCat API**
  - Used by Apple/Google for transaction tracking
  - Found in RevenueCat API response under `store_transaction_id` field

## Complete Purchase Verification Flow

### Step 1: User Initiates Purchase

```
User taps "Buy 2000 Treats"
  ↓
UnifiedPurchaseService.purchaseProduct() called
  ↓
RevenueCat SDK: revenueCat.purchase(PurchaseParams.package(package))
```

### Step 2: RevenueCat Processes Purchase

```
RevenueCat SDK receives purchase request
  ↓
RevenueCat creates transaction with ID: o1_bJI5hCFcWcJFp2SxdQUyIw
  ↓
RevenueCat sends receipt to RevenueCat backend API
  ↓
RevenueCat backend syncs with App Store/Google Play
  ↓
Backend stores transaction with:
  - RevenueCat ID: o1_bJI5hCFcWcJFp2SxdQUyIw (for frontend reference)
  - Store Transaction ID: 2000001059005684 (used by backend for lookup)
  - Product ID: bravoball_treats_2000
  - User ID: $RCAnonymousID:... or email
```

**Important**: RevenueCat backend sync takes **2-5 seconds** for consumable products.

### Step 3: Get CustomerInfo After Purchase

```dart
// In unified_purchase_service.dart
final customerInfo = await revenueCat.purchase(PurchaseParams.package(package));
```

This returns `CustomerInfo` with:
- `nonSubscriptionTransactions`: List of all one-time purchase transactions
- Each transaction has `transactionIdentifier` (RevenueCat ID like `o1_...`)

### Step 4: Refresh CustomerInfo (Critical Step)

**Why**: RevenueCat backend needs time to sync the new transaction.

```dart
// Wait for RevenueCat backend to sync
await Future.delayed(const Duration(seconds: 2));

// Refresh to get latest transaction data
refreshedCustomerInfo = await revenueCat.getCustomerInfo();
```

**Result**: `refreshedCustomerInfo.nonSubscriptionTransactions` now includes the new transaction.

### Step 5: Find the Most Recent Transaction

**Problem**: User may have multiple transactions for the same product. We need the **most recent** one.

**Solution**: Sort transactions by purchase date and pick the newest.

```dart
// In store_service.dart - verifyAndGrantTreatPurchase()

// 1. Get all transactions from CustomerInfo
final nonSubscriptionTransactions = customerInfo.nonSubscriptionTransactions;

// 2. Filter transactions for this specific product
final productTransactions = nonSubscriptionTransactions
    .where((tx) => tx.productIdentifier == productId)
    .toList();

// 3. Sort by purchase date (most recent first)
productTransactions.sort((a, b) {
  final aDate = a.purchaseDate is DateTime 
      ? a.purchaseDate as DateTime 
      : DateTime.parse(a.purchaseDate.toString());
  final bDate = b.purchaseDate is DateTime 
      ? b.purchaseDate as DateTime 
      : DateTime.parse(b.purchaseDate.toString());
  return bDate.compareTo(aDate); // Descending order (newest first)
});

// 4. Pick the most recent transaction
transaction = productTransactions.first;
```

**Why This Matters**:
- User makes Purchase #1 → Gets transaction `o1_abc123`
- User makes Purchase #2 → Gets transaction `o1_xyz789`
- Without sorting, we might pick `o1_abc123` (old) instead of `o1_xyz789` (new)
- With sorting, we always get `o1_xyz789` (most recent)

### Step 6: Send Verification Request to Backend

```dart
final response = await ApiService.shared.post(
  '/api/store/verify-treat-purchase',
  body: {
    'product_id': productId,                    // e.g., 'bravoball_treats_2000'
    'package_identifier': packageIdentifier,   // e.g., 'Treats2000'
    'treat_amount': treatAmount,                // e.g., 2000
    'transaction_id': transaction.transactionIdentifier,  // e.g., 'o1_xyz789'
    'revenue_cat_user_id': customerInfo.originalAppUserId,
    'platform': 'ios',
    // ...
  },
);
```

### Step 7: Backend Verification Process

```
Backend receives verification request
  ↓
Backend queries RevenueCat API:
  GET https://api.revenuecat.com/v1/subscribers/{user_id}
  ↓
RevenueCat API returns CustomerInfo with:
  - non_subscriptions array
  - Each entry has:
    * RevenueCat transaction ID (o1_...)
    * Store transaction ID (numeric)
    * Product ID
    * Purchase date
  ↓
Backend searches for transaction:
  1. Find user's non_subscriptions from RevenueCat API
  2. Filter by product_id: bravoball_treats_2000
  3. Extract Store Transaction ID from RevenueCat API response
     - RevenueCat API returns: `store_transaction_id: 2000001059005684`
  4. Find transaction using Store Transaction ID: 2000001059005684
     - **Note**: Backend uses Store Transaction ID (numeric), not RevenueCat ID (o1_...)
  5. Verify transaction exists and is valid
  ↓
Backend grants treats and returns success
```

### Step 8: Backend Idempotency Check

**Important**: Backend checks if transaction was already processed.

```python
# Backend checks if transaction was already processed
if transaction_already_processed(transaction_id, user_id):
    return current_treat_balance  # Don't add treats again
else:
    add_treats_to_user(user_id, treat_amount)
    mark_transaction_processed(transaction_id, user_id)
    return new_treat_balance
```

**Why**: Prevents duplicate treat grants if user retries verification.

## Code Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ 1. User Taps "Buy 2000 Treats"                             │
└───────────────────────┬─────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. UnifiedPurchaseService.purchaseProduct()                │
│    - Calls RevenueCat SDK: purchase()                       │
└───────────────────────┬─────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. RevenueCat SDK Processes Purchase                       │
│    - Creates transaction: o1_xyz789                         │
│    - Sends to RevenueCat backend                            │
│    - Backend syncs with App Store (2-5 seconds)            │
└───────────────────────┬─────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Get CustomerInfo from Purchase Result                   │
│    - customerInfo.nonSubscriptionTransactions               │
│    - May not include new transaction yet (sync delay)       │
└───────────────────────┬─────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. Refresh CustomerInfo (CRITICAL)                         │
│    - Wait 2 seconds for backend sync                       │
│    - Call revenueCat.getCustomerInfo()                      │
│    - Now includes new transaction                          │
└───────────────────────┬─────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. Find Most Recent Transaction                             │
│    - Filter by productId: bravoball_treats_2000             │
│    - Sort by purchaseDate (newest first)                    │
│    - Pick first transaction (most recent)                   │
│    - Result: o1_xyz789                                     │
└───────────────────────┬─────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 7. Send Verification to Backend                            │
│    POST /api/store/verify-treat-purchase                    │
│    - transaction_id: o1_xyz789 (RevenueCat ID)            │
│    - product_id: bravoball_treats_2000                      │
│    - treat_amount: 2000                                     │
└───────────────────────┬─────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 8. Backend Queries RevenueCat API                          │
│    GET /v1/subscribers/{user_id}                           │
│    - Gets user's non_subscriptions                         │
│    - Filters by product_id: bravoball_treats_2000          │
│    - Extracts Store Transaction ID from API response        │
│    - Finds transaction using Store Transaction ID           │
│      (numeric: 2000001059005684, not o1_xyz789)            │
│    - Verifies it's valid                                    │
│    - Checks idempotency (already processed?)                │
└───────────────────────┬─────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 9. Backend Grants Treats                                   │
│    - Adds 2000 treats to user account                      │
│    - Marks transaction as processed                         │
│    - Returns success with new balance                       │
└─────────────────────────────────────────────────────────────┘
```

## Critical Implementation Details

### 1. Always Refresh CustomerInfo After Purchase

**Why**: RevenueCat backend needs time to sync new transactions.

```dart
// ✅ CORRECT: Refresh CustomerInfo
await Future.delayed(const Duration(seconds: 2));
refreshedCustomerInfo = await revenueCat.getCustomerInfo();
```

**Without refresh**: May use stale CustomerInfo missing the new transaction.

### 2. Always Sort Transactions by Date

**Why**: User may have multiple transactions for the same product.

```dart
// ✅ CORRECT: Sort by date (newest first)
productTransactions.sort((a, b) {
  final aDate = a.purchaseDate is DateTime 
      ? a.purchaseDate as DateTime 
      : DateTime.parse(a.purchaseDate.toString());
  final bDate = b.purchaseDate is DateTime 
      ? b.purchaseDate as DateTime 
      : DateTime.parse(b.purchaseDate.toString());
  return bDate.compareTo(aDate); // Descending order
});
transaction = productTransactions.first; // Most recent
```

**Without sorting**: May pick an old transaction instead of the new one.

### 3. Backend Uses Store Transaction ID for Lookup

**Important**: Backend finds transactions using **Store Transaction ID** (numeric), not RevenueCat ID (`o1_...`).

```
Frontend sends: transaction_id = o1_xyz789 (RevenueCat ID)
  ↓
Backend queries RevenueCat API
  GET /v1/subscribers/{user_id}
  ↓
Backend gets non_subscriptions array:
  [
    {
      "id": "o1_xyz789",                    // RevenueCat ID (from frontend)
      "store_transaction_id": "2000001059005684",  // Store Transaction ID
      "product_id": "bravoball_treats_2000"
    }
  ]
  ↓
Backend extracts Store Transaction ID: 2000001059005684
  ↓
Backend finds transaction using Store Transaction ID: 2000001059005684
  (NOT using RevenueCat ID o1_xyz789)
```

**Why**: Store Transaction ID is the authoritative identifier from App Store/Google Play, while RevenueCat ID is RevenueCat's internal format.

### 4. Backend Idempotency Check

**Why**: Prevents duplicate grants if verification is retried.

```python
# Backend checks if transaction was already processed
if transaction_exists_in_database(transaction_id, user_id):
    return current_balance  # Already processed
else:
    process_transaction()  # New transaction
```

## Common Issues and Solutions

### Issue 1: Same Transaction ID Sent for Multiple Purchases

**Symptoms**:
- Backend logs show same `o1_...` ID for different purchases
- Backend says "Transaction already processed"

**Root Cause**: Not sorting transactions by date, picking old transaction.

**Solution**: ✅ **FIXED** - Sort transactions by purchase date (newest first).

### Issue 2: Transaction Not Found in RevenueCat

**Symptoms**:
- Backend can't find transaction in RevenueCat API
- "Transaction not found" error

**Root Cause**: CustomerInfo not refreshed, RevenueCat backend hasn't synced yet.

**Solution**: ✅ **FIXED** - Refresh CustomerInfo with 2-second delay after purchase.

### Issue 3: Filtering Out Valid Transactions

**Symptoms**:
- Transactions with `o1_` prefix filtered out
- "No transaction found" error

**Root Cause**: Incorrectly assuming `o1_` means StoreKit.

**Solution**: ✅ **FIXED** - Removed filtering, `o1_` is RevenueCat's format for one-time purchases.

## Testing Checklist

- [x] Purchase completes successfully
- [x] CustomerInfo refreshed after purchase
- [x] Most recent transaction selected (not old one)
- [x] Unique transaction ID sent for each purchase
- [x] Backend finds transaction in RevenueCat API
- [x] Treats granted correctly
- [x] Idempotency check prevents duplicate grants
- [x] Multiple purchases get different transaction IDs

## Related Documentation

- `docs/REVENUECAT_TRANSACTION_IDS.md` - RevenueCat transaction ID format guide
- `docs/STOREKIT_SANDBOX_MIGRATION.md` - StoreKit to sandbox migration guide
- `docs/SANDBOX_TESTING_GUIDE.md` - Sandbox testing instructions

## Summary

**Key Takeaways**:

1. **RevenueCat creates `o1_` IDs** for one-time purchases (sandbox AND production)
2. **Refresh CustomerInfo** after purchase to get latest transaction data
3. **Sort transactions by date** to find the most recent one
4. **Frontend sends RevenueCat ID** (`o1_...`) to backend for reference
5. **Backend extracts Store Transaction ID** (numeric) from RevenueCat API response
6. **Backend finds transactions** using Store Transaction ID (numeric), not RevenueCat ID
7. **Idempotency check** prevents duplicate grants

The complete flow ensures each purchase gets its own unique transaction ID and is properly verified through RevenueCat's backend API.

