# BravoBall Premium System - Backend Specification

## 🎯 Overview
This document outlines the backend requirements for implementing the premium subscription system in BravoBall. The backend needs to handle user authentication, subscription management, receipt verification, and premium status validation.

## 🔐 Required Backend Endpoints

### 1. User Authentication
```http
POST /api/auth/login
POST /api/auth/register
POST /api/auth/refresh-token
POST /api/auth/logout
```

### 2. Premium Status Management
```http
GET /api/premium/status
POST /api/premium/validate
POST /api/premium/subscribe
POST /api/premium/cancel
GET /api/premium/subscription-details
```

### 3. Receipt Verification
```http
POST /api/premium/verify-receipt
POST /api/premium/verify-google-play
POST /api/premium/verify-app-store
```

### 4. Usage Tracking
```http
POST /api/premium/track-usage
GET /api/premium/usage-stats
```

## 📊 Database Schema

### Users Table
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    email_verified BOOLEAN DEFAULT FALSE
);
```

### Premium Subscriptions Table
```sql
CREATE TABLE premium_subscriptions (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    status VARCHAR(50) NOT NULL, -- 'free', 'premium', 'trial', 'expired'
    plan_type VARCHAR(50) NOT NULL, -- 'monthly', 'yearly', 'lifetime'
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP,
    trial_end_date TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    platform VARCHAR(20), -- 'ios', 'android', 'web'
    receipt_data TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Usage Tracking Table
```sql
CREATE TABLE usage_tracking (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    feature_type VARCHAR(50) NOT NULL, -- 'custom_drill', 'session', 'premium_feature'
    usage_count INTEGER DEFAULT 1,
    usage_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## 🔑 API Endpoint Specifications

### GET /api/premium/status
**Purpose**: Get current premium status for a user

**Headers**:
```
Authorization: Bearer <jwt_token>
Device-Fingerprint: <device_hash>
App-Version: <app_version>
```

**Response**:
```json
{
  "success": true,
  "data": {
    "status": "premium",
    "plan": "yearly",
    "startDate": "2024-01-15T00:00:00Z",
    "endDate": "2025-01-15T00:00:00Z",
    "trialEndDate": null,
    "isActive": true,
    "features": [
      "noAds",
      "unlimitedDrills",
      "unlimitedCustomDrills",
      "unlimitedSessions",
      "advancedAnalytics"
    ]
  }
}
```

### POST /api/premium/validate
**Purpose**: Validate premium status with server-side checks

**Headers**:
```
Authorization: Bearer <jwt_token>
Device-Fingerprint: <device_hash>
App-Version: <app_version>
```

**Request Body**:
```json
{
  "timestamp": 1705276800000,
  "deviceId": "device_hash_here",
  "appVersion": "1.0.0"
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "status": "premium",
    "lastValidated": "2024-01-15T10:30:00Z",
    "nextValidation": "2024-01-15T15:30:00Z"
  }
}
```

### POST /api/premium/verify-receipt
**Purpose**: Verify in-app purchase receipt

**Headers**:
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Request Body**:
```json
{
  "platform": "ios", // or "android"
  "receiptData": "base64_encoded_receipt",
  "productId": "bravoball_premium_yearly",
  "transactionId": "transaction_id_here"
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "verified": true,
    "subscriptionStatus": "active",
    "expiresAt": "2025-01-15T00:00:00Z",
    "platform": "ios"
  }
}
```

### POST /api/premium/track-usage
**Purpose**: Track feature usage for analytics and limits

**Headers**:
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Request Body**:
```json
{
  "featureType": "custom_drill", // or "session", "premium_feature"
  "usageDate": "2024-01-15",
  "metadata": {
    "drillType": "passing",
    "difficulty": "intermediate"
  }
}
```

## 🔒 Security Requirements

### 1. JWT Authentication
- Use secure JWT tokens with expiration
- Implement token refresh mechanism
- Store tokens securely (httpOnly cookies recommended)

### 2. Device Fingerprinting
- Generate unique device hash on app startup
- Include device fingerprint in all premium requests
- Validate device fingerprint matches user account

### 3. Rate Limiting
- Limit premium validation requests (max 5 per minute per user)
- Implement exponential backoff for failed requests
- Track and block suspicious activity

### 4. Receipt Verification
- **iOS**: Use App Store Server API for receipt validation
- **Android**: Use Google Play Developer API for purchase verification
- Implement server-side receipt caching
- Validate receipt signatures and authenticity

## 📱 Platform-Specific Requirements

### iOS (App Store)
```javascript
// Example App Store Server API call
const response = await fetch('https://api.storekit.itunes.apple.com/inApps/v1/lookup/1234567890', {
  method: 'GET',
  headers: {
    'Authorization': `Bearer ${appStoreToken}`,
    'User-Agent': 'BravoBall/1.0'
  }
});
```

### Android (Google Play)
```javascript
// Example Google Play Developer API call
const response = await fetch(`https://www.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases/subscriptions/${subscriptionId}/tokens/${token}`, {
  method: 'GET',
  headers: {
    'Authorization': `Bearer ${googlePlayToken}`
  }
});
```

## 🚀 Implementation Steps for Backend

### Phase 1: Core Infrastructure
1. Set up user authentication system
2. Create database tables for users and subscriptions
3. Implement JWT token management
4. Set up device fingerprinting

### Phase 2: Premium Management
1. Implement premium status endpoints
2. Create subscription management logic
3. Set up usage tracking system
4. Implement feature gating

### Phase 3: Receipt Verification
1. Integrate with App Store Server API
2. Integrate with Google Play Developer API
3. Implement receipt validation logic
4. Set up subscription renewal handling

### Phase 4: Security & Monitoring
1. Implement rate limiting
2. Set up fraud detection
3. Add comprehensive logging
4. Set up monitoring and alerts

## 📊 Testing Endpoints

### Development/Testing
```http
POST /api/premium/test/set-status
POST /api/premium/test/clear-cache
POST /api/premium/test/simulate-expiry
```

## 🔍 Monitoring & Analytics

### Key Metrics to Track
- Premium conversion rate
- Subscription renewal rates
- Feature usage patterns
- Receipt verification success rates
- API response times
- Error rates by endpoint

### Logging Requirements
- Log all premium-related actions
- Track device fingerprint changes
- Monitor suspicious activity patterns
- Log receipt verification attempts and results

## 📞 Support & Maintenance

### Required Information
- App Store Connect API credentials
- Google Play Console API credentials
- SSL certificates for production
- Monitoring dashboard access
- Backup and recovery procedures

### Maintenance Tasks
- Regular receipt verification audits
- Subscription status reconciliation
- Device fingerprint validation
- Security vulnerability assessments
- Performance optimization

---

**Note**: This specification should be treated as a living document. Update it as requirements evolve and new features are added to the premium system.
