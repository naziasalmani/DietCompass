import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'storage_service.dart';

/// Standardized API Response
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
    this.errorCode,
    this.rawBody,
    this.contentType,
  });

  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;
  final String? errorCode;
  final String? rawBody;
  final String? contentType;


  dynamic operator [](String key) {
    if (key == 'success') return success;
    if (key == 'message') return message;
    if (key == 'status' || key == 'statusCode') return statusCode;
    if (key == 'code' || key == 'errorCode') return errorCode;
    if (key == 'data') return data;
    if (data is Map) {
      return (data as Map)[key];
    }
    return null;
  }
}

/// Custom Exception thrown by API calls
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code});
  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => message;
}

/// Centralized API HTTP Client for DietCompass
class ApiService {
  ApiService._internal();
  static final ApiService instance = ApiService._internal();

  final http.Client _client = http.Client();

  // Callback to trigger token refresh without circular import
  Future<bool> Function()? onTokenRefreshRequired;

  /// Helper to normalize endpoint strings (e.g. '/api/profile' -> '/profile')
  String _normalizeEndpoint(String endpoint) {
    if (endpoint.startsWith('/api/')) {
      return endpoint.substring(4);
    }
    if (!endpoint.startsWith('/')) {
      return '/$endpoint';
    }
    return endpoint;
  }

  /// Build standard headers with optional Bearer Authorization
  Future<Map<String, String>> _buildHeaders({
    bool requiresAuth = true,
    Map<String, String>? extraHeaders,
    String endpoint = '',
    String method = '',
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      var token = await StorageService.instance.getAccessToken();
      if ((token == null || token.isEmpty) && onTokenRefreshRequired != null) {
        await onTokenRefreshRequired!();
        token = await StorageService.instance.getAccessToken();
      }
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      debugPrint('[PROFILE AUTH DEBUG] tokenExists = ${token != null && token.isNotEmpty}');
      debugPrint('[PROFILE AUTH DEBUG] tokenLength = ${token?.length ?? 0}');
      debugPrint('[PROFILE AUTH DEBUG] authorizationHeaderPresent = ${headers.containsKey('Authorization')}');
      debugPrint('[PROFILE AUTH DEBUG] endpoint = $endpoint');
      debugPrint('[PROFILE AUTH DEBUG] method = $method');
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  /// Perform a GET request
  Future<ApiResponse<Map<String, dynamic>>> get(
    String endpoint, {
    bool requiresAuth = true,
    bool requireAuth = true,
    Map<String, String>? headers,
    bool retryOn401 = true,
    Duration? timeout,
  }) async {
    final auth = requiresAuth && requireAuth;
    return _sendRequest(
      () async {
        final uri = Uri.parse('${AppConfig.apiBaseUrl}${_normalizeEndpoint(endpoint)}');
        final reqHeaders = await _buildHeaders(
          requiresAuth: auth,
          extraHeaders: headers,
          endpoint: endpoint,
          method: 'GET',
        );
        return await _client.get(uri, headers: reqHeaders).timeout(timeout ?? AppConfig.timeoutDuration);
      },
      endpoint: endpoint,
      retryOn401: retryOn401,
    );
  }

  /// Perform a POST request
  Future<ApiResponse<Map<String, dynamic>>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
    bool requireAuth = true,
    Map<String, String>? headers,
    bool retryOn401 = true,
    Duration? timeout,
  }) async {
    final auth = requiresAuth && requireAuth;
    return _sendRequest(
      () async {
        final uri = Uri.parse('${AppConfig.apiBaseUrl}${_normalizeEndpoint(endpoint)}');
        final reqHeaders = await _buildHeaders(
          requiresAuth: auth,
          extraHeaders: headers,
          endpoint: endpoint,
          method: 'POST',
        );
        final encodedBody = body != null ? jsonEncode(body) : null;
        return await _client
            .post(uri, headers: reqHeaders, body: encodedBody)
            .timeout(timeout ?? AppConfig.timeoutDuration);
      },
      endpoint: endpoint,
      retryOn401: retryOn401,
    );
  }

  /// Perform a PUT request
  Future<ApiResponse<Map<String, dynamic>>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
    bool requireAuth = true,
    Map<String, String>? headers,
    bool retryOn401 = true,
    Duration? timeout,
  }) async {
    final auth = requiresAuth && requireAuth;
    return _sendRequest(
      () async {
        final uri = Uri.parse('${AppConfig.apiBaseUrl}${_normalizeEndpoint(endpoint)}');
        final reqHeaders = await _buildHeaders(
          requiresAuth: auth,
          extraHeaders: headers,
          endpoint: endpoint,
          method: 'PUT',
        );
        final encodedBody = body != null ? jsonEncode(body) : null;
        return await _client
            .put(uri, headers: reqHeaders, body: encodedBody)
            .timeout(timeout ?? AppConfig.timeoutDuration);
      },
      endpoint: endpoint,
      retryOn401: retryOn401,
    );
  }

  /// Perform a PATCH request
  Future<ApiResponse<Map<String, dynamic>>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
    bool requireAuth = true,
    Map<String, String>? headers,
    bool retryOn401 = true,
    Duration? timeout,
  }) async {
    final auth = requiresAuth && requireAuth;
    return _sendRequest(
      () async {
        final uri = Uri.parse('${AppConfig.apiBaseUrl}${_normalizeEndpoint(endpoint)}');
        final reqHeaders = await _buildHeaders(
          requiresAuth: auth,
          extraHeaders: headers,
          endpoint: endpoint,
          method: 'PATCH',
        );
        final encodedBody = body != null ? jsonEncode(body) : null;
        return await _client
            .patch(uri, headers: reqHeaders, body: encodedBody)
            .timeout(timeout ?? AppConfig.timeoutDuration);
      },
      endpoint: endpoint,
      retryOn401: retryOn401,
    );
  }

  /// Perform a DELETE request
  Future<ApiResponse<Map<String, dynamic>>> delete(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
    bool requireAuth = true,
    Map<String, String>? headers,
    bool retryOn401 = true,
    Duration? timeout,
  }) async {
    final auth = requiresAuth && requireAuth;
    return _sendRequest(
      () async {
        final uri = Uri.parse('${AppConfig.apiBaseUrl}${_normalizeEndpoint(endpoint)}');
        final reqHeaders = await _buildHeaders(
          requiresAuth: auth,
          extraHeaders: headers,
          endpoint: endpoint,
          method: 'DELETE',
        );
        final encodedBody = body != null ? jsonEncode(body) : null;
        return await _client
            .delete(uri, headers: reqHeaders, body: encodedBody)
            .timeout(timeout ?? AppConfig.timeoutDuration);
      },
      endpoint: endpoint,
      retryOn401: retryOn401,
    );
  }

  /// Internal request runner with timeout, error translation, and 401 refresh retry
  Future<ApiResponse<Map<String, dynamic>>> _sendRequest(
    Future<http.Response> Function() requestFn, {
    required String endpoint,
    required bool retryOn401,
  }) async {
    try {
      final response = await requestFn();
      final statusCode = response.statusCode;

      Map<String, dynamic> responseData = {};
      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            responseData = decoded;
          }
        } catch (_) {
          responseData = {'message': response.body};
        }
      }

      final contentType = response.headers['content-type'] ?? response.headers['Content-Type'] ?? 'application/json';

      // Success
      if (statusCode >= 200 && statusCode < 300) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: responseData,
          message: responseData['message'] as String?,
          statusCode: statusCode,
          rawBody: response.body,
          contentType: contentType,
        );
      }

      // Token Expired / Unauthorized -> Auto Refresh & Retry once
      if (statusCode == 401 && retryOn401 && onTokenRefreshRequired != null) {
        final refreshed = await onTokenRefreshRequired!();
        if (refreshed) {
          // Retry the request with new token
          return await _sendRequest(
            requestFn,
            endpoint: endpoint,
            retryOn401: false, // Prevent infinite retry loops
          );
        }
      }

      return ApiResponse<Map<String, dynamic>>(
        success: false,
        data: responseData,
        message: responseData['message'] as String? ?? 'Request failed with status $statusCode',
        statusCode: statusCode,
        errorCode: responseData['code'] as String?,
        rawBody: response.body,
        contentType: contentType,
      );

    } on SocketException {
      return const ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'No internet connection or server unreachable.',
        statusCode: 0,
      );
    } on TimeoutException {
      return const ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Request timed out. Please try again.',
        statusCode: 408,
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Unexpected network error: ${e.toString()}',
        statusCode: 500,
      );
    }
  }
}
