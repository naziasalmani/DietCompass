import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../model/user_model.dart';

/// DietCompass — Secure Storage Service
/// Manages encrypted on-device persistence for JWT Access Tokens, Refresh Tokens,
/// and local User Profile caching.
class StorageService {
  StorageService._internal();
  static final StorageService instance = StorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _keyAccessToken = 'dc_access_token';
  static const String _keyRefreshToken = 'dc_refresh_token';
  static const String _keyUserData = 'dc_user_profile';
  static const String _keyIntroOnboardingSeen = 'dc_intro_onboarding_seen';

  /// Check whether the device-level introductory onboarding has been completed
  Future<bool> hasSeenIntroOnboarding() async {
    final val = await _storage.read(key: _keyIntroOnboardingSeen);
    return val == 'true';
  }

  /// Mark device-level introductory onboarding as seen
  Future<void> setIntroOnboardingSeen(bool seen) async {
    await _storage.write(key: _keyIntroOnboardingSeen, value: seen.toString());
  }

  /// Save Access and Refresh Token pair securely
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _keyAccessToken, value: accessToken),
      _storage.write(key: _keyRefreshToken, value: refreshToken),
    ]);

    final storedAccessToken = await getAccessToken();
    final tokenStored =
        storedAccessToken == accessToken && accessToken.isNotEmpty;
    debugPrint('[TOKEN STORAGE DEBUG] tokenStored = $tokenStored');
    debugPrint(
      '[TOKEN STORAGE DEBUG] tokenLength = ${storedAccessToken?.length ?? 0}',
    );
    if (!tokenStored) {
      throw StateError('Access token could not be persisted securely.');
    }
  }

  /// Retrieve the stored Access Token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  /// Retrieve the stored Refresh Token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  /// Save serialized User Profile
  Future<void> saveUser(UserModel user) async {
    final jsonStr = jsonEncode(user.toJson());
    await _storage.write(key: _keyUserData, value: jsonStr);
  }

  /// Retrieve cached User Profile
  Future<UserModel?> getUser() async {
    try {
      final jsonStr = await _storage.read(key: _keyUserData);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final Map<String, dynamic> jsonMap = jsonDecode(jsonStr);
      return UserModel.fromJson(jsonMap);
    } catch (_) {
      return null;
    }
  }

  /// Check if authentication credentials exist in secure storage
  Future<bool> hasStoredCredentials() async {
    final refreshToken = await getRefreshToken();
    return refreshToken != null && refreshToken.isNotEmpty;
  }

  /// Clear all stored authentication tokens and user profile
  Future<void> clearAuth() async {
    await Future.wait([
      _storage.delete(key: _keyAccessToken),
      _storage.delete(key: _keyRefreshToken),
      _storage.delete(key: _keyUserData),
    ]);
  }

  /// Save user-specific scan history to local secure storage
  Future<void> saveLocalScanHistory(String userId, String jsonString) async {
    try {
      final key = 'dc_scan_history_$userId';
      await _storage.write(key: key, value: jsonString);
    } catch (e) {
      debugPrint('[StorageService] Error saving local scan history: $e');
    }
  }

  /// Retrieve user-specific scan history from local secure storage
  Future<String?> getLocalScanHistory(String userId) async {
    try {
      final key = 'dc_scan_history_$userId';
      return await _storage.read(key: key);
    } catch (e) {
      debugPrint('[StorageService] Error reading local scan history: $e');
      return null;
    }
  }
}
