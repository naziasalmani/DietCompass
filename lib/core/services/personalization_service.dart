import 'package:flutter/foundation.dart';
import 'package:diet_compass/features/personalization/lib/onboarding/onboarding_data.dart';
import '../model/personalization_profile.dart';


import 'api_service.dart';
import 'recommendation_service.dart';
import 'storage_service.dart';

/// DietCompass — Personalization Service
///
/// Cloud synchronization layer for dietary and health preferences.
/// Communicates with backend `/api/personalization` using authenticated JWT bearer tokens.
class PersonalizationService extends ChangeNotifier {
  PersonalizationService._();

  static final PersonalizationService instance = PersonalizationService._();

  PersonalizationProfile? _cachedPersonalization;
  int _profileVersion = 1;

  /// Tracks personalization profile version to invalidate personalized analysis cache when preferences change.
  int get profileVersion => _profileVersion;

  void incrementProfileVersion() {
    _profileVersion++;
    RecommendationService.instance.clearCompatibilityCache();
  }


  /// In-memory cached personalization profile for fast UI lookup.
  PersonalizationProfile? get currentPersonalization => _cachedPersonalization;

  /// Loads locally cached PersonalizationProfile from encrypted secure storage if available.
  Future<PersonalizationProfile?> loadLocalPersonalization() async {
    if (_cachedPersonalization != null) return _cachedPersonalization;
    final stored = await StorageService.instance.getPersonalizationProfile();
    if (stored != null) {
      _cachedPersonalization = stored;
      notifyListeners();
    }
    return _cachedPersonalization;
  }

  /// Fetches the authenticated user's personalization profile from MongoDB.
  Future<PersonalizationProfile?> getPersonalization({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      if (_cachedPersonalization != null) return _cachedPersonalization;
      final local = await loadLocalPersonalization();
      if (local != null) return local;
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
        final token = await StorageService.instance.getAccessToken();
        if (token == null || token.isEmpty) {
          debugPrint('[PERSONALIZATION] User logged out during fetch — ignoring response.');
          return profile;
        }
        _cachedPersonalization = profile;
        await StorageService.instance.savePersonalizationProfile(profile);
        notifyListeners();
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
      await StorageService.instance.savePersonalizationProfile(saved);
      incrementProfileVersion();
      notifyListeners();


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
      await StorageService.instance.savePersonalizationProfile(saved);
      incrementProfileVersion();
      notifyListeners();


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
    notifyListeners();
  }
}

