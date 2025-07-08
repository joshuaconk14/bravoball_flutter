import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/api_response_models.dart';
import 'user_manager_service.dart';

/// Base API Service
/// Handles HTTP requests, authentication, timeouts, and error handling
/// Mirrors the Swift APIService structure
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static ApiService get shared => _instance;

  // MARK: - HTTP Client
  late final http.Client _client;

  /// Initialize the API service
  void initialize() {
    _client = http.Client();
  }

  /// Dispose of the HTTP client
  void dispose() {
    _client.close();
  }

  // MARK: - Generic Request Method
  /// Generic HTTP request method
  /// Similar to Swift's APIService.request method
  Future<ApiResponse<Map<String, dynamic>>> request({
    required String endpoint,
    String method = 'GET',
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    bool requiresAuth = false,
  }) async {
    try {
      // Build the full URL
      final uri = _buildUri(endpoint, queryParameters);
      
      // Prepare headers
      final requestHeaders = await _buildHeaders(headers, requiresAuth);
      
      // Log the request if debugging
      if (AppConfig.logApiCalls) {
        _logRequest(method, uri, requestHeaders, body);
      }

      // Make the HTTP request
      final response = await _makeRequest(
        method: method,
        uri: uri,
        headers: requestHeaders,
        body: body,
      ).timeout(AppConfig.apiTimeout);

      // Log the response if debugging
      if (AppConfig.logApiCalls) {
        _logResponse(response);
      }

      // Handle the response
      return _handleResponse(response);

    } on SocketException catch (e) {
      return ApiResponse.error('Network error: ${e.message}');
    } on HttpException catch (e) {
      return ApiResponse.error('HTTP error: ${e.message}');
    } on FormatException catch (e) {
      return ApiResponse.error('Data format error: ${e.message}');
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  // MARK: - Convenience Methods

  /// GET request
  Future<ApiResponse<Map<String, dynamic>>> get(
    String endpoint, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    bool requiresAuth = false,
  }) {
    return request(
      endpoint: endpoint,
      method: 'GET',
      queryParameters: queryParameters,
      headers: headers,
      requiresAuth: requiresAuth,
    );
  }

  /// POST request
  Future<ApiResponse<Map<String, dynamic>>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool requiresAuth = false,
  }) {
    return request(
      endpoint: endpoint,
      method: 'POST',
      body: body,
      headers: headers,
      requiresAuth: requiresAuth,
    );
  }

  /// PUT request
  Future<ApiResponse<Map<String, dynamic>>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool requiresAuth = false,
  }) {
    return request(
      endpoint: endpoint,
      method: 'PUT',
      body: body,
      headers: headers,
      requiresAuth: requiresAuth,
    );
  }

  /// DELETE request
  Future<ApiResponse<Map<String, dynamic>>> delete(
    String endpoint, {
    Map<String, String>? headers,
    bool requiresAuth = false,
  }) {
    return request(
      endpoint: endpoint,
      method: 'DELETE',
      headers: headers,
      requiresAuth: requiresAuth,
    );
  }

  // MARK: - Private Helper Methods

  /// Build the complete URI with query parameters
  Uri _buildUri(String endpoint, Map<String, String>? queryParameters) {
    final baseUrl = AppConfig.baseUrl;
    
    // Ensure endpoint starts with /
    if (!endpoint.startsWith('/')) {
      endpoint = '/$endpoint';
    }

    final uri = Uri.parse('$baseUrl$endpoint');
    
    if (queryParameters != null && queryParameters.isNotEmpty) {
      return uri.replace(queryParameters: queryParameters);
    }
    
    return uri;
  }

  /// Build request headers
  Future<Map<String, String>> _buildHeaders(
    Map<String, String>? customHeaders,
    bool requiresAuth,
  ) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add custom headers
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    // Add authentication header if required
    if (requiresAuth) {
      final userManager = UserManagerService.instance;
      if (userManager.hasValidToken) {
        headers['Authorization'] = 'Bearer ${userManager.accessToken}';
        
        if (AppConfig.logApiCalls && kDebugMode) {
          print('🔑 Added auth header: Bearer ${userManager.accessToken.substring(0, 20)}...');
        }
      } else if (kDebugMode) {
        print('⚠️ Auth required but no valid token available');
      }
    }

    return headers;
  }

  /// Make the actual HTTP request
  Future<http.Response> _makeRequest({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  }) {
    switch (method.toUpperCase()) {
      case 'GET':
        return _client.get(uri, headers: headers);
      case 'POST':
        return _client.post(
          uri,
          headers: headers,
          body: body != null ? json.encode(body) : null,
        );
      case 'PUT':
        return _client.put(
          uri,
          headers: headers,
          body: body != null ? json.encode(body) : null,
        );
      case 'DELETE':
        return _client.delete(uri, headers: headers);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }

  /// Handle HTTP response
  ApiResponse<Map<String, dynamic>> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    
    try {
      // Try to decode JSON response
      final Map<String, dynamic> responseData;
      if (response.body.isNotEmpty) {
        responseData = json.decode(response.body) as Map<String, dynamic>;
      } else {
        responseData = {};
      }

      // Check if response is successful
      if (statusCode >= 200 && statusCode < 300) {
        return ApiResponse.success(responseData);
      } else {
        // Handle error responses
        final errorMessage = _extractErrorMessage(responseData, statusCode);
        return ApiResponse.error(errorMessage, statusCode);
      }
    } catch (e) {
      // JSON decoding failed
      final errorMessage = 'Failed to parse response: $e';
      return ApiResponse.error(errorMessage, statusCode);
    }
  }

  /// Extract error message from response
  String _extractErrorMessage(Map<String, dynamic>? responseData, int statusCode) {
    if (responseData != null) {
      // Try different error field names
      if (responseData.containsKey('detail')) {
        return responseData['detail'] as String;
      } else if (responseData.containsKey('message')) {
        return responseData['message'] as String;
      } else if (responseData.containsKey('error')) {
        return responseData['error'] as String;
      }
    }

    // Default error messages based on status code
    switch (statusCode) {
      case 400:
        return 'Bad request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not found';
      case 500:
        return 'Internal server error';
      default:
        return 'HTTP error $statusCode';
    }
  }

  /// Log HTTP request for debugging
  void _logRequest(
    String method,
    Uri uri,
    Map<String, String> headers,
    Map<String, dynamic>? body,
  ) {
    if (kDebugMode) {
      print('🌐 API Request: $method $uri');
      print('📤 Headers: $headers');
      if (body != null) {
        print('📤 Body: ${json.encode(body)}');
      }
    }
  }

  /// Log HTTP response for debugging
  void _logResponse(http.Response response) {
    if (kDebugMode) {
      print('📥 API Response: ${response.statusCode}');
      if (response.body.isNotEmpty) {
        try {
          final prettyJson = const JsonEncoder.withIndent('  ').convert(
            json.decode(response.body),
          );
          print('📥 Body: $prettyJson');
        } catch (e) {
          print('📥 Body: ${response.body}');
        }
      }
    }
  }
}

/// Generic API Response wrapper
class ApiResponse<T> {
  final T? data;
  final String? error;
  final int? statusCode;
  final bool isSuccess;

  ApiResponse._({
    this.data,
    this.error,
    this.statusCode,
    required this.isSuccess,
  });

  /// Create a successful response
  factory ApiResponse.success(T data) {
    return ApiResponse._(
      data: data,
      isSuccess: true,
    );
  }

  /// Create an error response
  factory ApiResponse.error(String error, [int? statusCode]) {
    return ApiResponse._(
      error: error,
      statusCode: statusCode,
      isSuccess: false,
    );
  }

  /// Check if the response has data
  bool get hasData => data != null;

  /// Check if the response has an error
  bool get hasError => error != null;
} 