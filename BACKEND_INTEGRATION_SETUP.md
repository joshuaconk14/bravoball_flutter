# Backend Integration Setup Guide

This guide explains the new backend integration system for the BravoBall Flutter app, allowing you to easily switch between test data and real backend API calls.

## 🚀 Quick Start

### 1. Configure Your Environment

Open `lib/config/app_config.dart` and modify the `appDevCase` variable:

```dart
class AppConfig {
  /// App Development Cases (mirrors Swift appDevCase)
  /// 1: Production
  /// 2: Computer (localhost)  
  /// 3: Phone (Wi-Fi IP)
  static const int appDevCase = 2; // CHANGE THIS TO SWITCH ENVIRONMENTS
  
  /// Debug mode toggle
  static const bool debug = true; // Set false in production
}
```

### 2. Environment Options

- **Case 1 (Production)**: `https://bravoball-backend.onrender.com`
- **Case 2 (Localhost)**: `http://127.0.0.1:8000`
- **Case 3 (Wi-Fi IP)**: `http://192.168.1.100:8000` (update with your IP)

### 3. Data Source Control

The app automatically determines the data source:
- **Test Data**: When `appDevCase = 0` (special debug mode)
- **Backend API**: When `appDevCase = 1, 2, or 3`

## 📁 New File Structure

```
lib/
├── config/
│   └── app_config.dart           # Environment & debug configuration
├── services/
│   ├── api_service.dart          # Base HTTP client with error handling
│   └── drill_api_service.dart    # Drill-specific API endpoints
├── models/
│   └── api_response_models.dart  # Backend response models
└── features/session_generator/
    └── drill_search_view.dart    # Updated with backend integration
```

## 🔧 Key Features Implemented

### 1. **Clean Configuration System**
- Mirrors your Swift `GlobalSettings` structure
- Easy environment switching with single variable change
- Automatic debug information display

### 2. **Drill Search Integration**
- Real backend API calls to your PostgreSQL database
- Fallback to test data for development
- Search with pagination, filtering, and error handling
- Visual indicators showing current data source

### 3. **Robust API Service**
- Timeout handling and retry logic
- Comprehensive error handling
- Detailed debug logging
- Response parsing and validation

### 4. **Debug Tools**
- Environment indicators in the UI
- Debug menu with API status information
- Console logging for API calls and responses
- Visual data source indicators

## 🌐 API Endpoints Used

The app connects to these backend endpoints:

### Public Endpoints (No Auth Required)
- `GET /public/drills/search` - Search drills without authentication

### Authenticated Endpoints (Future)
- `GET /api/drills/search` - Search drills with user authentication
- `GET /api/drills/{id}` - Get specific drill details

## 🔍 How to Test

### 1. **Test with Local Backend**
```dart
// In app_config.dart
static const int appDevCase = 2; // Localhost
static const bool debug = true;
```

Start your local backend server on `http://127.0.0.1:8000` and run the Flutter app. You should see:
- Green "Using Backend API" indicator in search view
- Real drill data from your PostgreSQL database
- Debug console showing API calls

### 2. **Test with Test Data**
```dart
// In app_config.dart  
static const int appDevCase = 0; // Special test mode
static const bool debug = true;
```

The app will use local test data instead of making API calls.

### 3. **Production Mode**
```dart
// In app_config.dart
static const int appDevCase = 1; // Production
static const bool debug = false;
```

## 📱 UI Features

### Debug Indicators
When `debug = true`, you'll see:
- **Search View**: Data source indicator (blue for test data, green for backend)
- **Debug Menu**: Bug icon in app bar with environment information
- **Console Logs**: Detailed API call information

### Search Functionality
- **Real-time search** with 500ms debounce
- **Filtering** by skill and difficulty
- **Pagination** with "Load More" button
- **Pull-to-refresh** support
- **Error handling** with retry options

## 🚨 Troubleshooting

### Common Issues

1. **Network Errors**
   - Check your backend server is running
   - Verify the base URL in `app_config.dart`
   - For Wi-Fi testing, ensure your IP address is correct

2. **No Data Showing**
   - Check the debug indicator to confirm data source
   - Look at console logs for API errors
   - Try switching to test data mode to verify app functionality

3. **CORS Issues**
   - Ensure your backend allows requests from your Flutter app
   - Check browser console for CORS-related errors

### Debug Console Commands

Enable detailed logging by ensuring `AppConfig.logApiCalls = true`:

```
🚀 Starting BravoBall Flutter App
📱 Environment: Localhost (Case 2)
    Base URL: http://127.0.0.1:8000
    Debug Mode: true
    Test Data: false

🔍 Performing drill search:
   Query: "passing"
   Skill Filter: none
   Difficulty Filter: none
   Data Source: Backend API

🌐 API Request: GET http://127.0.0.1:8000/public/drills/search?query=passing&page=1&limit=15
📤 Headers: {Content-Type: application/json, Accept: application/json}
📥 API Response: 200
📥 Body: {"items": [...], "total": 42, ...}

✅ DrillAPI Success: searchDrills - 15 items
🌐 Backend search completed: 15 drills on page 1/3
```

## 🔄 Migration from Test Data

The system seamlessly handles both test data and backend data:

1. **Models**: `DrillModel` remains unchanged for UI compatibility
2. **Conversion**: `DrillApiService.convertToLocalModel()` maps backend responses
3. **Fallback**: Automatic fallback to empty results on API errors
4. **Caching**: Backend data is cached for performance

## 🎯 Next Steps

1. **Run the app** with your local backend
2. **Test search functionality** with real data
3. **Verify pagination** works correctly
4. **Check error handling** by stopping your backend server
5. **Switch environments** to test different configurations

You now have a fully functional drill search system that can seamlessly switch between test data and your real PostgreSQL backend! 🎉 