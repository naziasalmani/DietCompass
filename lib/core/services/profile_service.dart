import '../model/user_profile.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'recommendation_service.dart';
import 'storage_service.dart';

/// DietCompass — Profile Service
///
/// Cloud synchronization layer for user profile management.
/// Communicates with backend `/api/profile` using authenticated JWT bearer tokens.
class ProfileService extends ChangeNotifier {
  ProfileService._();

  static final ProfileService instance = ProfileService._();

  UserProfile? _cachedProfile;
  int _profileVersion = 1;

  /// Tracks user profile version to invalidate personalized analysis cache when profile changes.
  int get profileVersion => _profileVersion;

  void incrementProfileVersion() {
    _profileVersion++;
    RecommendationService.instance.clearCompatibilityCache();
  }


  /// In-memory cached profile for synchronous UI access.
  UserProfile? get currentProfile => _cachedProfile;

  /// Loads locally cached UserProfile from encrypted secure storage if available.
  Future<UserProfile?> loadLocalProfile() async {
    if (_cachedProfile != null) return _cachedProfile;
    final stored = await StorageService.instance.getUserProfile();
    if (stored != null) {
      _cachedProfile = stored;
      notifyListeners();
    }
    return _cachedProfile;
  }

  /// Fetches the authenticated user's profile from the backend.
  Future<UserProfile> getProfile({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      if (_cachedProfile != null) return _cachedProfile!;
      final local = await loadLocalProfile();
      if (local != null) return local;
    }

    final response = await ApiService.instance.get(
      '/profile',
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      final resData =
          response.data!['data'] as Map<String, dynamic>? ?? response.data!;
      final userJson = resData['user'] as Map<String, dynamic>? ?? {};
      final isPersonalizationComplete =
          resData['isPersonalizationComplete'] == true;

      final profile = UserProfile.fromJson(
        userJson,
        isPersonalizationComplete: isPersonalizationComplete,
      );

      final token = await StorageService.instance.getAccessToken();
      if (token == null || token.isEmpty) {
        debugPrint('[PROFILE] User logged out during fetch — ignoring response.');
        return profile;
      }

      _cachedProfile = profile;
      await StorageService.instance.saveUserProfile(profile);
      notifyListeners();
      return profile;
    }

    throw ApiException(
      response.message ?? 'Failed to retrieve profile.',
      statusCode: response.statusCode,
      code: response.errorCode,
    );
  }

  /// Updates profile attributes on the cloud backend.
  Future<UserProfile> updateProfile(Map<String, dynamic> fields) async {
    final token = await StorageService.instance.getAccessToken();
    debugPrint(
      '[PROFILE AUTH DEBUG] tokenExists = ${token?.isNotEmpty == true}',
    );
    debugPrint('[PROFILE AUTH DEBUG] tokenLength = ${token?.length ?? 0}');
    debugPrint(
      '[PROFILE AUTH DEBUG] authorizationHeaderPresent = ${token?.isNotEmpty == true}',
    );
    debugPrint('[PROFILE AUTH DEBUG] endpoint = /profile');
    debugPrint('[PROFILE AUTH DEBUG] method = PUT');
    final response = await ApiService.instance.put(
      '/profile',
      body: fields,
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      final resData =
          response.data!['data'] as Map<String, dynamic>? ?? response.data!;
      final userJson = resData['user'] as Map<String, dynamic>? ?? {};
      final profile = UserProfile.fromJson(
        userJson,
        isPersonalizationComplete:
            _cachedProfile?.isPersonalizationComplete ?? false,
      );
      _cachedProfile = profile;
      await StorageService.instance.saveUserProfile(profile);
      incrementProfileVersion();
      notifyListeners();

      return profile;
    }

    throw ApiException(
      response.message ?? 'Failed to update profile.',
      statusCode: response.statusCode,
      code: response.errorCode,
    );
  }

  /// Clears the in-memory cached profile upon user logout.
  void clearCache() {
    _cachedProfile = null;
    notifyListeners();
  }
}
