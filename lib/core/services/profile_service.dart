import '../model/user_profile.dart';
import 'api_service.dart';

/// DietCompass — Profile Service
///
/// Cloud synchronization layer for user profile management.
/// Communicates with backend `/api/profile` using authenticated JWT bearer tokens.
class ProfileService {
  ProfileService._();

  static final ProfileService instance = ProfileService._();

  UserProfile? _cachedProfile;

  /// In-memory cached profile for synchronous UI access.
  UserProfile? get currentProfile => _cachedProfile;

  /// Fetches the authenticated user's profile from the backend.
  Future<UserProfile> getProfile({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedProfile != null) {
      return _cachedProfile!;
    }

    final response = await ApiService.instance.get('/profile', requiresAuth: true);

    if (response.success && response.data != null) {
      final resData = response.data!['data'] as Map<String, dynamic>? ?? response.data!;
      final userJson = resData['user'] as Map<String, dynamic>? ?? {};
      final isPersonalizationComplete = resData['isPersonalizationComplete'] == true;

      final profile = UserProfile.fromJson(
        userJson,
        isPersonalizationComplete: isPersonalizationComplete,
      );
      _cachedProfile = profile;
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
    final response = await ApiService.instance.put(
      '/profile',
      body: fields,
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      final resData = response.data!['data'] as Map<String, dynamic>? ?? response.data!;
      final userJson = resData['user'] as Map<String, dynamic>? ?? {};
      final profile = UserProfile.fromJson(
        userJson,
        isPersonalizationComplete: _cachedProfile?.isPersonalizationComplete ?? false,
      );
      _cachedProfile = profile;
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
  }
}
