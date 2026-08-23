import 'package:flutter/foundation.dart';
import '../../features/personalization/lib/onboarding/onboarding_data.dart';
import '../model/personalization_profile.dart';
import 'api_service.dart';
import 'recommendation_service.dart';

/// DietCompass — Personalization Service
///
/// Cloud synchronization layer for dietary and health preferences.
/// Communicates with backend `/api/personalization` using authenticated JWT bearer tokens.
class PersonalizationService {
  PersonalizationService._();

  static final PersonalizationService instance = PersonalizationService._();

  PersonalizationProfile? _cachedPersonalization;

  /// In-memory cached personalization profile for fast UI lookup.
  PersonalizationProfile? get currentPersonalization => _cachedPersonalization;

  /// Fetches the authenticated user's personalization profile from MongoDB.
  Future<PersonalizationProfile?> getPersonalization({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedPersonalization != null) {
      return _cachedPersonalization;
    }

    final response = await ApiService.instance.get(
      '/personalization',
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>? ?? response.data!;
      final persJson = data['personalization'] as Map<String, dynamic>?;

      if (persJson != null) {
        final profile = PersonalizationProfile.fromJson(persJson);
        _cachedPersonalization = profile;
        return profile;
      }
      return null;
    }

    throw ApiException(
      response.message ?? 'Failed to retrieve personalization preferences.',
      statusCode: response.statusCode,
      code: response.errorCode,
    );
  }

  /// Saves the complete 7-step onboarding data to MongoDB Atlas.
  Future<PersonalizationProfile> savePersonalization(
    OnboardingData data, {
    bool isCompleted = true,
  }) async {
    final profile = PersonalizationProfile.fromOnboardingData(data, isCompleted: isCompleted);

    final response = await ApiService.instance.put(
      '/personalization',
      body: profile.toJson(),
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      final resData = response.data!['data'] as Map<String, dynamic>? ?? response.data!;
      final persJson = resData['personalization'] as Map<String, dynamic>? ?? profile.toJson();
      final saved = PersonalizationProfile.fromJson(persJson);
      _cachedPersonalization = saved;
      RecommendationService.instance.clearCompatibilityCache();

      debugPrint('\n==============================================');
      debugPrint('[CURRENT PROFILE]');
      debugPrint('diet = ${saved.dietType?.isNotEmpty == true ? saved.dietType : 'None'}');
      debugPrint('goal = ${saved.goals.isNotEmpty ? saved.goals.join(', ') : 'None'}');
      debugPrint('allergies = [${saved.allergies.join(', ')}]');
      debugPrint('==============================================\n');

      return saved;
    }

    throw ApiException(
      response.message ?? 'Failed to save personalization preferences.',
      statusCode: response.statusCode,
      code: response.errorCode,
    );
  }

  /// Partially updates specific personalization preferences.
  Future<PersonalizationProfile> updatePersonalization(Map<String, dynamic> fields) async {
    final response = await ApiService.instance.patch(
      '/personalization',
      body: fields,
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      final resData = response.data!['data'] as Map<String, dynamic>? ?? response.data!;
      final persJson = resData['personalization'] as Map<String, dynamic>? ?? {};
      final saved = PersonalizationProfile.fromJson(persJson);
      _cachedPersonalization = saved;
      RecommendationService.instance.clearCompatibilityCache();

      debugPrint('\n==============================================');
      debugPrint('[CURRENT PROFILE]');
      debugPrint('diet = ${saved.dietType?.isNotEmpty == true ? saved.dietType : 'None'}');
      debugPrint('goal = ${saved.goals.isNotEmpty ? saved.goals.join(', ') : 'None'}');
      debugPrint('allergies = [${saved.allergies.join(', ')}]');
      debugPrint('==============================================\n');

      return saved;
    }

    throw ApiException(
      response.message ?? 'Failed to update personalization preferences.',
      statusCode: response.statusCode,
      code: response.errorCode,
    );
  }

  /// Clears in-memory cache upon user logout.
  void clearCache() {
    _cachedPersonalization = null;
  }
}

