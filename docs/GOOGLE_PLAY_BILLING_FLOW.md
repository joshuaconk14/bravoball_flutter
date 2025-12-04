# Google Play Billing Flow - Complete Guide

## Overview

This document explains the complete Google Play billing flow for BravoBall, including setup, emulator configuration, purchase process, and how RevenueCat integrates with Google Play.

---

## Part 1: Setup & Configuration

### 1. Google Play Console Setup

1. **Create Products:**
   - `bravoball_monthly_premium` (Subscription)
   - `bravoball_yearly_premium` (Subscription)
   - `bravoball_treats_500` (Consumable)
   - `bravoball_treats_1000` (Consumable)
   - `bravoball_treats_2000` (Consumable)

2. **Set up License Testing:**
   - Go to: **Setup → License testing**
   - Add test account emails
   - These accounts can test purchases without real charges

### 2. RevenueCat Dashboard Setup

1. **Configure Products** (match Google Play product IDs)
2. **Create Offerings:**
   - `"default"` offering → Premium subscriptions
   - `"bravoball_treats"` offering → Treat packages
3. **Set up Entitlements** (e.g., `"premium"`)
4. **Link Google Play account**

### 3. App Configuration

Your app initializes RevenueCat in `main.dart`:

```dart
// Initialize RevenueCat with Android API key
final configuration = PurchasesConfiguration('goog_StgyfWJTGVIARJFEHIFtwKUjYLN');
await Purchases.configure(configuration);

// Identify user
await Purchases.logIn(userEmail);
```

---

## Part 2: Emulator Setup

### Why API 34 Works

- **API 35 (Android 15)** has Google account sign-in bugs on emulators
- **API 34 (Android 14)** is stable and reliable
- Google Play Services work correctly on API 34

### Emulator Configuration Steps

1. **Create AVD:**
   - Device: Pixel 7
   - System Image: **API 34 with Google Play icon** (NOT "Google APIs" or "AOSP")

2. **Add Google Account:**
   - Settings → Accounts → Add account → Google
   - Sign in with License Tester email
   - Account must be on device for billing to work

---

## Part 3: Complete Purchase Flow

### Step-by-Step Process

```
1. USER INITIATES PURCHASE
   User taps "Buy 2000 Treats" button
   ↓

2. YOUR APP CALLS UnifiedPurchaseService
   UnifiedPurchaseService.purchaseProduct(
     productType: ProductType.treats,
     packageIdentifier: 'Treats2000'
   )
   ↓

3. REVENUECAT SDK FETCHES OFFERINGS
   revenueCat.getOfferings()
   Returns offerings from RevenueCat backend
   ↓

4. FIND CORRECT PACKAGE
   Searches "bravoball_treats" offering
   Finds package "Treats2000" → maps to "bravoball_treats_2000"
   ↓

5. REVENUECAT INITIATES PURCHASE
   revenueCat.purchase(PurchaseParams.package(package))
   RevenueCat SDK calls Google Play Billing Library
   ↓

6. GOOGLE PLAY BILLING LIBRARY
   - Checks Google account on device
   - Connects to Google Play Services
   - Fetches product details from Google Play
   - Shows Google Play purchase dialog
   - User confirms purchase
   ↓

7. GOOGLE PLAY PROCESSES PAYMENT
   On Emulator: Uses TEST payment method (no real charge)
   In Production: Charges user's payment method
   Returns purchase token to RevenueCat
   ↓

8. REVENUECAT SDK RECEIVES PURCHASE
   Gets purchase token from Google Play
   Sends receipt to RevenueCat backend
   ↓

9. REVENUECAT BACKEND VALIDATES
   - Calls Google Play Developer API
   - Verifies purchase is valid
   - Stores transaction
   - Links to user's RevenueCat customer ID
   - Creates transaction ID (e.g., o1_xxxxx)
   ↓

10. REVENUECAT RETURNS CUSTOMER INFO
    Returns CustomerInfo object with:
    - nonSubscriptionTransactions (new purchase)
    - entitlements (for subscriptions)
    - originalAppUserId (user's email)
    ↓

11. YOUR APP HANDLES POST-PURCHASE
    For Treats:
    - Wait 2 seconds for RevenueCat backend sync
    - Refresh CustomerInfo
    - Call backend to verify purchase
    - Backend validates via RevenueCat API
    - Backend grants treats to user
    
    For Premium Subscriptions:
    - Entitlements automatically active
    - No backend verification needed
```

---

## Part 4: How Google Play is Used

### Google Play's Role

1. **Product Catalog:** Stores your product IDs and prices
2. **Payment Processing:** Handles payment methods
3. **Purchase Validation:** Provides purchase tokens
4. **License Verification:** Validates purchases

### RevenueCat's Role

1. **Abstraction Layer:** Works with Google Play and App Store
2. **Receipt Validation:** Validates purchases server-side
3. **User Management:** Links purchases to user accounts
4. **Cross-Platform:** Same code for iOS and Android

### Your App's Role

1. **UI:** Shows products and handles user interactions
2. **Purchase Initiation:** Calls RevenueCat SDK
3. **Post-Purchase Logic:** Grants features/treats
4. **Backend Verification:** Validates consumables server-side

---

## Part 5: Testing on Emulator

### What Happens on Emulator

1. **Google Account Required:**
   - Must be signed in on device
   - License Tester account works
   - Google Play Services must be active

2. **Test Purchases:**
   - Uses TEST payment methods
   - No real charges
   - Purchases are real but marked as test

3. **Google Play Billing:**
   - Connects to Google Play Services
   - Fetches products from Google Play Console
   - Processes purchase through Google Play
   - Returns purchase token

4. **RevenueCat:**
   - Receives purchase token
   - Validates with Google Play Developer API
   - Stores transaction
   - Returns CustomerInfo to your app

### Differences: Emulator vs Production

| Aspect | Emulator (Test) | Production |
|--------|----------------|------------|
| Accounts | License Tester accounts | Real user accounts |
| Payment | Test payment methods | Real payment methods |
| Product Status | "Draft" or "Active" | Must be "Active" |
| Charges | No real charges | Real charges |
| App Status | Can test immediately | App must be published |

---

## Part 6: Key Components

### Product IDs

**Google Play Product IDs:**
- `bravoball_monthly_premium`
- `bravoball_yearly_premium`
- `bravoball_treats_500`
- `bravoball_treats_1000`
- `bravoball_treats_2000`

**RevenueCat Package Identifiers:**
- `PremiumMonthly`
- `PremiumYearly`
- `Treats500`
- `Treats1000`
- `Treats2000`

### Offerings Structure

```
"default" Offering:
  └── PremiumMonthly → bravoball_monthly_premium
  └── PremiumYearly → bravoball_yearly_premium

"bravoball_treats" Offering:
  └── Treats500 → bravoball_treats_500
  └── Treats1000 → bravoball_treats_1000
  └── Treats2000 → bravoball_treats_2000
```

---

## Part 7: Quick Reference Checklist

### Setup Checklist

- [ ] Google Play Console: Products created
- [ ] RevenueCat Dashboard: Products & offerings configured
- [ ] License Testers: Email added to Google Play Console
- [ ] Emulator: API 34 with Google Play (not Google APIs)
- [ ] Google Account: Signed in on emulator device
- [ ] App: RevenueCat initialized with Android API key

### Testing Checklist

- [ ] Emulator running with API 34
- [ ] Google account signed in on device
- [ ] License Tester account matches emulator account
- [ ] Products configured in both Google Play and RevenueCat
- [ ] App can fetch offerings from RevenueCat
- [ ] Purchase flow works end-to-end

---

## Important Notes

1. **Google account must be on device** (not just Play Store)
2. **API 34 works reliably** - API 35 has sign-in issues
3. **License Testers can test** without real charges
4. **RevenueCat abstracts** Google Play complexity
5. **Backend verification required** for consumables
6. **Subscriptions handled automatically** by RevenueCat

---

## Troubleshooting

### Can't Sign Into Google Account

- **Problem:** "Something went wrong" error
- **Solution:** Use API 34 emulator instead of API 35

### Purchases Not Working

- **Check:** Google account is signed in on device
- **Check:** Account is added to License Testers
- **Check:** Products are configured in both Google Play and RevenueCat
- **Check:** App is using correct RevenueCat API key

### Products Not Loading

- **Check:** Products are "Active" or "Draft" in Google Play Console
- **Check:** Products match between Google Play and RevenueCat
- **Check:** Offerings are configured correctly in RevenueCat

---

## Summary

The Google Play billing flow works like this:

1. **Setup:** Configure products in Google Play Console and RevenueCat
2. **Emulator:** Use API 34 with Google account signed in
3. **Purchase:** User taps buy → RevenueCat → Google Play → Payment → Validation → Grant product
4. **Testing:** Use License Tester accounts for test purchases without charges

This setup allows you to test purchases on emulator with test accounts before going to production.

