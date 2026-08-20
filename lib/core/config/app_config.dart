import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// DietCompass — Global Application & API Configuration
abstract final class AppConfig {
  /// Optional API URL override.
  ///
  /// Example:
  /// --dart-define=API_BASE_URL=https://dietcompass.onrender.com/api
  static const apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

  /// Web OAuth client ID used by Google Sign-In to mint verifiable ID tokens.
  ///
  /// Can be overridden at build/run time with:
  /// --dart-define=GOOGLE_WEB_CLIENT_ID=...
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '524989513168-6ifogqg44rmlkilb7sp5irrofsj9bflo.apps.googleusercontent.com',
  );

  /// Base API URL.
  ///
  /// This can be dynamically updated if required.
  static String _customBaseUrl = '';

  /// Set a custom base URL.
  ///
  /// Example:
  /// AppConfig.setBaseUrl('https://dietcompass.onrender.com/api');
  static void setBaseUrl(String url) {
    _customBaseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
  }

  /// Get the active API Base URL.
  ///
  /// Priority:
  /// 1. --dart-define API_BASE_URL
  /// 2. Runtime custom URL
  /// 3. Production Render backend
  static String get apiBaseUrl {
    // Build-time override
    if (apiBaseUrlOverride.isNotEmpty) {
      return apiBaseUrlOverride.replaceAll(RegExp(r'/+$'), '');
    }

    // Runtime override
    if (_customBaseUrl.isNotEmpty) {
      return _customBaseUrl;
    }

    // Production backend
    return 'https://dietcompass.onrender.com/api';
  }

  /// Default HTTP timeout duration.
  static const Duration timeoutDuration = Duration(seconds: 15);
}