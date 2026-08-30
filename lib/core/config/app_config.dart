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
  /// This MUST be the Web application OAuth Client ID,
  /// not the Android OAuth Client ID.
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
    '524989513168-1n4a7ofhk707jnq7s8bctctlsc1quifj.apps.googleusercontent.com',
  );

  /// Official DietCompass support and feedback email address.
  /// Configurable via --dart-define=SUPPORT_EMAIL=<email>
  static const supportEmail = String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: 'support@dietcompass.app',
  );

  /// Base API URL.
  ///
  /// Priority:
  /// 1. --dart-define API_BASE_URL
  /// 2. Runtime custom URL
  /// 3. Production Render backend
  static String _customBaseUrl = '';

  /// Set a custom base URL.
  ///
  /// Example:
  /// AppConfig.setBaseUrl('https://dietcompass.onrender.com/api');
  static void setBaseUrl(String url) {
    _customBaseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
  }

  /// Get the active API Base URL.
  static String get apiBaseUrl {
    if (apiBaseUrlOverride.isNotEmpty) {
      return apiBaseUrlOverride.replaceAll(RegExp(r'/+$'), '');
    }

    if (_customBaseUrl.isNotEmpty) {
      return _customBaseUrl;
    }

    return 'https://dietcompass.onrender.com/api';
  }

  /// Default HTTP timeout duration.
  static const Duration timeoutDuration = Duration(seconds: 15);
}