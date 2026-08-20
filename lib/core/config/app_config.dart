import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// DietCompass — Global Application & API Configuration
abstract final class AppConfig {
  /// Optional API URL override, for example:
  /// --dart-define=API_BASE_URL=http://192.168.1.7:5000/api
  static const apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

  /// Web OAuth client ID used by Google Sign-In to mint verifiable ID tokens.
  /// Pass it with --dart-define=GOOGLE_WEB_CLIENT_ID=... at build/run time.
  /// Defaults to the project’s configured web client so Android can authenticate
  /// even when no build-time define is supplied.
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '524989513168-6ifogqg44rmlkilb7sp5irrofsj9bflo.apps.googleusercontent.com',
  );

  /// Base API URL. Can be dynamically updated if connecting from a physical device.
  static String _customBaseUrl = '';

  /// Set a custom base URL (e.g. for physical devices over Wi-Fi: 'http://192.168.1.100:5000/api')
  static void setBaseUrl(String url) {
    _customBaseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
  }

  /// Get the active API Base URL
  static String get apiBaseUrl {
    if (apiBaseUrlOverride.isNotEmpty) {
      return apiBaseUrlOverride.replaceAll(RegExp(r'/+$'), '');
    }

    if (_customBaseUrl.isNotEmpty) {
      return _customBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }

    try {
      if (Platform.isAndroid) {
        // Real Android devices must connect to the machine running the backend on the same Wi‑Fi network.
        // This is the PC's LAN IP in this setup; if it changes, update it here or call AppConfig.setBaseUrl().
        return 'http://10.146.252.182:5000/api';
      }
      if (Platform.isIOS || Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        return 'http://localhost:5000/api';
      }
    } catch (_) {
      // Fallback
    }

    return 'http://10.146.252.182:5000/api';
  }

  /// Default HTTP timeout duration
  static const Duration timeoutDuration = Duration(seconds: 15);
}
