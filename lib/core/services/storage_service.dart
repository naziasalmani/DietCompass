import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../model/user_model.dart';
import '../model/user_profile.dart';
import '../model/personalization_profile.dart';

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
  static const String _keyCloudProfile = 'dc_cloud_profile';
  static const String _keyPersonalization = 'dc_personalization_profile';
  static const String _keyIntroOnboardingSeen = 'dc_intro_onboarding_seen';

  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  UserModel? _cachedUser;
  UserProfile? _cachedUserProfile;
  PersonalizationProfile? _cachedPersonalizationProfile;

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
    _cachedAccessToken = accessToken;
    _cachedRefreshToken = refreshToken;

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
    if (_cachedAccessToken != null && _cachedAccessToken!.isNotEmpty) {
      return _cachedAccessToken;
    }
    _cachedAccessToken = await _storage.read(key: _keyAccessToken);
    return _cachedAccessToken;
  }

  /// Retrieve the stored Refresh Token
  Future<String?> getRefreshToken() async {
    if (_cachedRefreshToken != null && _cachedRefreshToken!.isNotEmpty) {
      return _cachedRefreshToken;
    }
    _cachedRefreshToken = await _storage.read(key: _keyRefreshToken);
    return _cachedRefreshToken;
  }

  /// Save serialized User Profile
  Future<void> saveUser(UserModel user) async {
    _cachedUser = user;
    final jsonStr = jsonEncode(user.toJson());
    await _storage.write(key: _keyUserData, value: jsonStr);
  }

  /// Retrieve cached User Profile
  Future<UserModel?> getUser() async {
    if (_cachedUser != null) {
      return _cachedUser;
    }
    try {
      final jsonStr = await _storage.read(key: _keyUserData);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final Map<String, dynamic> jsonMap = jsonDecode(jsonStr);
      _cachedUser = UserModel.fromJson(jsonMap);
      return _cachedUser;
    } catch (_) {
      return null;
    }
  }

  /// Save serialized User Profile domain model
  Future<void> saveUserProfile(UserProfile profile) async {
    _cachedUserProfile = profile;
    final jsonStr = jsonEncode(profile.toJson());
    await _storage.write(key: _keyCloudProfile, value: jsonStr);
  }

  /// Retrieve cached User Profile domain model
  Future<UserProfile?> getUserProfile() async {
    if (_cachedUserProfile != null) {
      return _cachedUserProfile;
    }
    try {
      final jsonStr = await _storage.read(key: _keyCloudProfile);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final Map<String, dynamic> jsonMap = jsonDecode(jsonStr);
      _cachedUserProfile = UserProfile.fromJson(jsonMap);
      return _cachedUserProfile;
    } catch (_) {
      return null;
    }
  }

  /// Save serialized Personalization Profile domain model
  Future<void> savePersonalizationProfile(PersonalizationProfile profile) async {
    _cachedPersonalizationProfile = profile;
    final jsonStr = jsonEncode(profile.toJson());
    await _storage.write(key: _keyPersonalization, value: jsonStr);
  }

  /// Retrieve cached Personalization Profile domain model
  Future<PersonalizationProfile?> getPersonalizationProfile() async {
    if (_cachedPersonalizationProfile != null) {
      return _cachedPersonalizationProfile;
    }
    try {
      final jsonStr = await _storage.read(key: _keyPersonalization);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final Map<String, dynamic> jsonMap = jsonDecode(jsonStr);
      _cachedPersonalizationProfile = PersonalizationProfile.fromJson(jsonMap);
      return _cachedPersonalizationProfile;
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
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _cachedUser = null;
    _cachedUserProfile = null;
    _cachedPersonalizationProfile = null;
    await Future.wait([
      _storage.delete(key: _keyAccessToken),
      _storage.delete(key: _keyRefreshToken),
      _storage.delete(key: _keyUserData),
      _storage.delete(key: _keyCloudProfile),
      _storage.delete(key: _keyPersonalization),
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

  /// Save user-specific recipe generation history to local secure storage
  Future<void> saveLocalRecipeHistory(String userId, String jsonString) async {
    try {
      final key = 'dc_recipe_history_$userId';
      await _storage.write(key: key, value: jsonString);
    } catch (e) {
      debugPrint('[StorageService] Error saving local recipe history: $e');
    }
  }

  /// Retrieve user-specific recipe generation history from local secure storage
  Future<String?> getLocalRecipeHistory(String userId) async {
    try {
      final key = 'dc_recipe_history_$userId';
      return await _storage.read(key: key);
    } catch (e) {
      debugPrint('[StorageService] Error reading local recipe history: $e');
      return null;
    }
  }

  /// Save local profile image path
  Future<void> saveProfileImagePath(String? path) async {
    try {
      if (path == null || path.isEmpty) {
        await _storage.delete(key: 'dc_profile_image_path');
      } else {
        await _storage.write(key: 'dc_profile_image_path', value: path);
      }
    } catch (e) {
      debugPrint('[StorageService] Error saving profile image path: $e');
    }
  }

  /// Retrieve local profile image path
  Future<String?> getProfileImagePath() async {
    try {
      return await _storage.read(key: 'dc_profile_image_path');
    } catch (e) {
      debugPrint('[StorageService] Error reading profile image path: $e');
      return null;
    }
  }

  /// Save selected ThemeMode
  Future<void> saveThemeMode(ThemeMode mode) async {
    try {
      final val = mode == ThemeMode.system
          ? 'system'
          : (mode == ThemeMode.dark ? 'dark' : 'light');
      await _storage.write(key: 'dc_theme_mode', value: val);
    } catch (e) {
      debugPrint('[StorageService] Error saving theme mode: $e');
    }
  }

  /// Retrieve selected ThemeMode
  Future<ThemeMode?> getThemeMode() async {
    try {
      final val = await _storage.read(key: 'dc_theme_mode');
      if (val == 'dark') return ThemeMode.dark;
      if (val == 'system') return ThemeMode.system;
      if (val == 'light') return ThemeMode.light;
      return null;
    } catch (e) {
      debugPrint('[StorageService] Error reading theme mode: $e');
      return null;
    }
  }
}
