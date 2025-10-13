# RevenueCat Test Setup Guide

This guide will help you set up and test RevenueCat integration with Apple Pay before migrating your main app.

## Prerequisites

1. **RevenueCat Account**: You mentioned you already have this set up ✅
2. **App Store Connect Products**: You mentioned these are configured ✅
3. **Apple Developer Account**: For testing Apple Pay

## Setup Steps

### 1. Get Your RevenueCat API Keys

1. Log into your RevenueCat dashboard
2. Go to your project settings
3. Copy your **Public API Key** (starts with `rcb_` or `pk_`)
4. Update the `_apiKey` constant in `revenuecat_test_app.dart`

### 2. Configure RevenueCat Dashboard

1. **Add your app** to RevenueCat if not already done
2. **Import your App Store Connect products**:
   - Go to Products section in RevenueCat
   - Import your existing products:
     - `bravoball_monthly_premium`
     - `bravoball_yearly_premium`
3. **Create Entitlements**:
   - Create an entitlement called `premium`
   - Attach both monthly and yearly products to this entitlement
4. **Create Offerings**:
   - Create an offering called `default`
   - Add both packages to this offering

### 3. Test on iOS Device

1. **Install the test app**:
   ```bash
   flutter run revenuecat_test_app.dart
   ```

2. **Sign in with Sandbox Apple ID**:
   - Go to Settings > App Store
   - Sign out of your regular Apple ID
   - Sign in with a sandbox Apple ID (create one in App Store Connect if needed)

3. **Test the flow**:
   - Launch the test app
   - Check that RevenueCat initializes successfully
   - Try purchasing a package
   - Test Apple Pay (should work automatically on supported devices)
   - Test restore purchases

## Testing Checklist

### ✅ RevenueCat Initialization
- [ ] App initializes without errors
- [ ] Debug logs show successful connection
- [ ] Customer info loads correctly

### ✅ Product Loading
- [ ] Products appear in the test app
- [ ] Prices display correctly
- [ ] Product titles and descriptions are correct

### ✅ Purchase Flow
- [ ] Purchase button works
- [ ] Apple Pay sheet appears (on supported devices)
- [ ] Purchase completes successfully
- [ ] Customer info updates after purchase

### ✅ Restore Purchases
- [ ] Restore button works
- [ ] Previous purchases are restored
- [ ] Customer info reflects restored purchases

### ✅ Apple Pay Integration
- [ ] Apple Pay appears as payment option
- [ ] Touch ID/Face ID authentication works
- [ ] Purchase completes through Apple Pay

## Troubleshooting

### Common Issues

1. **"No current offering found"**
   - Check that you've created an offering in RevenueCat dashboard
   - Ensure products are attached to the offering

2. **Products not loading**
   - Verify product IDs match exactly between App Store Connect and RevenueCat
   - Check that products are approved in App Store Connect
   - Ensure you're signed in with sandbox Apple ID

3. **Apple Pay not working**
   - Verify Apple Pay is enabled on your device
   - Check that you have a valid payment method added
   - Ensure you're testing on a physical device (not simulator)

4. **Purchase fails**
   - Check RevenueCat dashboard for error logs
   - Verify your sandbox Apple ID has sufficient funds
   - Check that the product is properly configured

### Debug Information

The test app includes comprehensive logging. Check the console for:
- RevenueCat initialization status
- Product loading results
- Purchase flow details
- Error messages

## Migration to Main App

Once testing is successful, you can migrate to your main app by:

1. **Add RevenueCat dependency** to your main `pubspec.yaml`
2. **Create a RevenueCat service** based on the test service
3. **Replace your current purchase service** calls with RevenueCat calls
4. **Update your premium status logic** to use RevenueCat entitlements

## Benefits of RevenueCat

- **Automatic receipt validation**
- **Cross-platform subscription management**
- **Advanced analytics and insights**
- **Webhook support for backend integration**
- **A/B testing for subscription offers**
- **Customer support tools**

## Next Steps

1. Complete the setup steps above
2. Run comprehensive tests
3. Document any issues or questions
4. Plan the migration timeline for your main app

## Support

- RevenueCat Documentation: https://docs.revenuecat.com/
- RevenueCat Community: https://community.revenuecat.com/
- Apple Pay Documentation: https://developer.apple.com/apple-pay/
