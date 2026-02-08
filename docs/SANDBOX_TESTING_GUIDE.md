# Sandbox Testing Guide for RevenueCat User Identification

## Overview
This guide walks you through testing the RevenueCat user identification fixes in the sandbox environment to verify that purchases don't transfer between users.

## How RevenueCat User Identification Works

**Key Understanding:**
- **Sandbox Apple ID** = Used for App Store payment authentication (can be the same for all test users)
- **BravoBall Account Email** = Used by RevenueCat as the customer identifier (must be different for each user)

When you call `Purchases.logIn(email)`, RevenueCat uses that email as the customer ID, NOT the Apple ID. So:
- User A (`wwww@gmail.com`) → RevenueCat Customer ID = `wwww@gmail.com`
- User B (`jc@gmail.com`) → RevenueCat Customer ID = `jc@gmail.com`
- Both can use the same sandbox Apple ID for payments, but purchases are tracked separately by email

This is why you only need **1 sandbox Apple ID** but **2 different BravoBall accounts** (different emails).

### 1. App Store Connect Setup
- ✅ Products created in App Store Connect:
  - `bravoball_monthly_premium` (Auto-Renewable Subscription)
  - `bravoball_yearly_premium` (Auto-Renewable Subscription)
  - `bravoball_treats_500` (Consumable)
  - `bravoball_treats_1000` (Consumable)
  - `bravoball_treats_2000` (Consumable)
- ✅ Products are "Ready to Submit" or "Approved"
- ✅ Products are associated with your app bundle ID

### 2. RevenueCat Dashboard Setup
- ✅ Products configured in RevenueCat dashboard
- ✅ Offerings configured:
  - `default` offering with premium subscriptions
  - `bravoball_treats` offering with treat packages
- ✅ Entitlements configured (e.g., `premium` entitlement)

### 3. Sandbox Test Account
Create **1 sandbox Apple ID** in App Store Connect:
- **Sandbox Apple ID**: Any email (e.g., `sandbox-test@example.com`)
- This is used for App Store payment authentication only

**How to create sandbox account:**
1. Go to App Store Connect → Users and Access → Sandbox Testers
2. Click "+" to add new sandbox tester
3. Use any email address (can be fake email)
4. Note: Sandbox accounts are separate from regular Apple IDs

**Important:** You'll create **2 different BravoBall accounts** (with different emails) to test user separation. The sandbox Apple ID is just for payment authentication - RevenueCat uses your BravoBall account email as the customer identifier.

## Step-by-Step Testing Instructions

### Step 1: Change Configuration to Sandbox Mode

**File: `lib/config/app_config.dart`**

```dart
/// StoreKit Configuration - Set to true for local testing, false for production
static const bool useLocalStoreKit = false; // ✅ Changed to false for sandbox testing
```

### Step 2: Build for Testing

**Option A: TestFlight (Recommended)**
```bash
# Build for TestFlight
flutter build ios --release
# Then upload to App Store Connect via Xcode or Transporter
```

**Option B: Physical Device (Development Build)**
```bash
# Build and install on physical device
flutter run --release
# Or build via Xcode and install via USB
```

**Option C: Simulator (Limited - may not work for sandbox)**
```bash
# Note: Sandbox testing on simulator is limited
# Use physical device or TestFlight for best results
flutter run --release
```

### Step 3: Sign Out of App Store on Device

**Important:** Before testing, sign out of your regular Apple ID on the device:
1. Settings → App Store → Sign Out
2. This ensures sandbox accounts are used

### Step 4: Test User Switching Flow

#### Test Scenario 1: User A Makes Purchase

1. **Install app** (TestFlight or development build)
2. **Create/Login as BravoBall User A** (`wwww@gmail.com`)
   - Create a new account or login with `wwww@gmail.com`
   - Watch console logs for:
     ```
     🔍 LoginService: Identifying user with RevenueCat...
     ✅ LoginService: User identified with RevenueCat as: wwww@gmail.com
     ```
3. **Make a purchase** (premium subscription or treats)
   - Go to Store page
   - Purchase premium subscription or treat package
   - When prompted, sign in with **sandbox Apple ID** (same one for all purchases)
4. **Verify in RevenueCat Dashboard**
   - Go to RevenueCat dashboard → Customers
   - Search for `wwww@gmail.com`
   - Verify purchase appears under this user
   - Note the Customer ID (should be `wwww@gmail.com`)

#### Test Scenario 2: User B Logs In (Should NOT Get User A's Purchases)

1. **Logout User A**
   - Watch console logs for:
     ```
     🚪 UserManager: Resetting RevenueCat user on logout...
     ✅ UserManager: RevenueCat user reset successfully
     ```
2. **Create/Login as BravoBall User B** (`jc@gmail.com`)
   - Create a new account or login with `jc@gmail.com` (different email!)
   - Watch console logs for:
     ```
     🔍 LoginService: Identifying user with RevenueCat...
     ⚠️ LoginService: Different user (wwww@gmail.com) logged in to RevenueCat, logging out first...
     ✅ LoginService: User identified with RevenueCat as: jc@gmail.com
     ```
3. **Verify User B has NO purchases**
   - Check Store page - should show no premium access
   - Check RevenueCat dashboard - User B should have separate customer record
   - User B's Customer ID should be `jc@gmail.com` (different from User A)

#### Test Scenario 3: User B Makes Purchase

1. **Make a purchase as User B**
   - Purchase premium subscription or treats
   - Sign in with **sandbox Apple ID** (same sandbox account as User A - that's fine!)
2. **Verify purchases are separate**
   - RevenueCat dashboard should show:
     - User A (`wwww@gmail.com`) has their purchases
     - User B (`jc@gmail.com`) has their own purchases
     - **No cross-contamination**
   - **Key Point**: Even though both users used the same sandbox Apple ID for payment, RevenueCat correctly separates purchases by the email passed to `Purchases.logIn(email)`

### Step 5: Verify in RevenueCat Dashboard

**Check Customer Records:**
1. Go to RevenueCat Dashboard → Customers
2. Search for each test user email
3. Verify:
   - ✅ Each user has their own customer record
   - ✅ Purchases are correctly attributed to each user
   - ✅ User IDs match email addresses (not anonymous IDs)
   - ✅ No purchases are shared between users

**Check Transactions:**
1. Go to RevenueCat Dashboard → Transactions
2. Filter by customer email
3. Verify transactions are correctly associated with the right user

## Debugging Tips

### Check Console Logs

Look for these key log messages:

**On Login:**
```
🔍 LoginService: Identifying user with RevenueCat...
⚠️ LoginService: Different user (...) logged in to RevenueCat, logging out first...
✅ LoginService: User identified with RevenueCat as: [email]
```

**On Logout:**
```
🚪 UserManager: Resetting RevenueCat user on logout...
✅ UserManager: RevenueCat user reset successfully
```

**On App Start:**
```
🔍 Main: Identifying returning user with RevenueCat...
⚠️ Main: Different user (...) logged in to RevenueCat, logging out first...
✅ Main: Returning user identified with RevenueCat as: [email]
```

### Common Issues

**Issue: Still seeing anonymous IDs**
- **Cause**: Sandbox environment may take time to sync
- **Fix**: Wait 5-10 minutes, restart app, check again

**Issue: Purchases not appearing**
- **Cause**: Products not properly configured in App Store Connect
- **Fix**: Verify products are "Ready to Submit" and associated with app

**Issue: Can't sign in with sandbox account**
- **Cause**: Not signed out of regular Apple ID
- **Fix**: Sign out of App Store in Settings first

**Issue: User identification not working**
- **Cause**: `useLocalStoreKit` still set to `true`
- **Fix**: Set `useLocalStoreKit = false` in `app_config.dart`

## Expected Results

### ✅ Success Indicators:
- Each user has separate RevenueCat customer record
- User IDs match email addresses (not anonymous)
- Purchases are correctly attributed to each user
- No purchase transfer between users
- Console logs show proper user identification

### ❌ Failure Indicators:
- Both users show same purchases
- User IDs are anonymous (`$RCAnonymousID:...`)
- Purchases transfer from User A to User B
- Console logs show errors during user identification

## Testing Checklist

- [ ] Changed `useLocalStoreKit = false` in `app_config.dart`
- [ ] Built app for TestFlight or physical device
- [ ] Signed out of regular Apple ID on device
- [ ] Created 1 sandbox test account in App Store Connect
- [ ] Created 2 different BravoBall accounts (different emails) in your app
- [ ] Tested User A login and purchase
- [ ] Verified User A's purchase in RevenueCat dashboard
- [ ] Tested User A logout
- [ ] Tested User B login (should NOT see User A's purchases)
- [ ] Verified User B has separate customer record
- [ ] Tested User B purchase
- [ ] Verified purchases remain separate in RevenueCat dashboard
- [ ] Checked console logs for proper user identification

## Next Steps After Testing

Once sandbox testing confirms user identification works:

1. **Keep `useLocalStoreKit = false`** for production builds
2. **Submit to App Store** for review
3. **Monitor RevenueCat dashboard** in production
4. **Set up production monitoring** for user identification issues

## Reverting to Local Testing

To switch back to local StoreKit testing:
```dart
// lib/config/app_config.dart
static const bool useLocalStoreKit = true; // Back to local testing
```

Note: User identification won't work in local StoreKit mode (always uses anonymous IDs), but purchase flow can still be tested.

