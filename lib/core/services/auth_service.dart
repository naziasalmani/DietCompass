import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../model/auth_user.dart';
import '../model/user_model.dart';
import '../config/app_config.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'profile_service.dart';
import 'personalization_service.dart';
import 'recommendation_service.dart';
import 'scan_history_service.dart';
import 'recipe_history_service.dart';

/// DietCompass — Centralized Authentication Service
/// Manages user authentication lifecycle, token persistence, and reactive auth state.
class AuthService extends ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
  serverClientId: AppConfig.googleWebClientId,
  scopes: ['email', 'profile'],
);
  AuthService._internal() {
    // Wire ApiService auto-refresh interceptor
    ApiService.instance.onTokenRefreshRequired = refreshSession;
  }
  static final AuthService instance = AuthService._internal();

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Clears any previous session data and loads fresh profile & personalization for [user].
  Future<void> syncUserSessionData(UserModel user) async {
    // 1. Clear old user's caches first
    ProfileService.instance.clearCache();
    PersonalizationService.instance.clearCache();
    RecommendationService.instance.clearCompatibilityCache();
    ScanHistoryService.instance.clearCache();
    RecipeHistoryService.instance.clearCache();

    // 2. Fetch fresh profile, personalization and scan history for the newly authenticated user
    try {
      final profile = await ProfileService.instance.getProfile(
        forceRefresh: true,
      );
      final pers = await PersonalizationService.instance.getPersonalization(
        forceRefresh: true,
      );
      await ScanHistoryService.instance.getScanHistory(forceRefresh: true);
      await RecipeHistoryService.instance.getRecipeHistory(forceRefresh: true);

      final diet = pers?.dietType?.isNotEmpty == true
          ? pers!.dietType!
          : (profile.dietType.isNotEmpty ? profile.dietType : 'Balanced');
      final goal = pers?.goals.isNotEmpty == true
          ? pers!.goals.join(', ')
          : 'Maintain Weight';
      final allergies = pers?.allergies.toList() ?? [];

      debugPrint('\n==============================================');
      debugPrint('[AUTH USER]');
      debugPrint('userId = ${user.id}');
      debugPrint('profileLoaded = true\n');
      debugPrint('[CURRENT PROFILE]');
      debugPrint('diet = $diet');
      debugPrint('goal = $goal');
      debugPrint('allergies = [${allergies.join(', ')}]');
      debugPrint('==============================================\n');
    } catch (e) {
      debugPrint(
        '[AUTH USER] Warning: Failed to sync personalization on auth: $e',
      );
    }
  }

  /// Initialize and verify authentication state on app startup
  Future<bool> checkAuthStatus() async {
    _setLoading(true);
    try {
      final hasCredentials = await StorageService.instance
          .hasStoredCredentials();
      if (!hasCredentials) {
        _currentUser = null;
        _isInitialized = true;
        _setLoading(false);
        return false;
      }

      // 1. Try to fetch user with current access token
      final meUser = await getCurrentUser();
      if (meUser != null) {
        _currentUser = meUser;
        _isInitialized = true;
        _setLoading(false);
        notifyListeners();
        return true;
      }

      // 2. If access token failed/expired, try refreshing session
      final refreshed = await refreshSession();
      if (refreshed) {
        final refreshedUser = await getCurrentUser();
        if (refreshedUser != null) {
          _currentUser = refreshedUser;
          _isInitialized = true;
          _setLoading(false);
          notifyListeners();
          return true;
        }
      }

      // 3. If refresh failed, clear invalid credentials
      await StorageService.instance.clearAuth();
      _currentUser = null;
      ProfileService.instance.clearCache();
      PersonalizationService.instance.clearCache();
      RecommendationService.instance.clearCompatibilityCache();
      _isInitialized = true;
      _setLoading(false);
      notifyListeners();
      return false;
    } catch (_) {
      _currentUser = null;
      ProfileService.instance.clearCache();
      PersonalizationService.instance.clearCache();
      RecommendationService.instance.clearCompatibilityCache();
      _isInitialized = true;
      _setLoading(false);
      return false;
    }
  }

  /// Probes for a valid stored session, refreshes if needed, and returns AuthUser
  Future<AuthUser?> tryRestoreSession() async {
    final authenticated = await checkAuthStatus();
    if (!authenticated || _currentUser == null) return null;
    return AuthUser(
      id: _currentUser!.id,
      fullName: _currentUser!.fullName,
      username: _currentUser!.username,
      email: _currentUser!.email,
      phone: _currentUser!.phone,
      countryCode: _currentUser!.countryCode,
      accountType: _currentUser!.accountType,
    );
  }

  /// Register a new user
  Future<AuthUser> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
    String phone = '',
    String countryCode = '+91',
    String accountType = 'individual',
  }) async {
    _setLoading(true);
    try {
      final response = await ApiService.instance.post(
        '/auth/register',
        requiresAuth: false,
        body: {
          'fullName': fullName.trim(),
          'username': username.trim().toLowerCase(),
          'email': email.trim().toLowerCase(),
          'password': password,
          'phone': phone.trim(),
          'countryCode': countryCode.trim(),
          'accountType': accountType,
        },
      );

      if (response.success && response.data != null) {
        final data = response.data!['data'] as Map<String, dynamic>?;
        if (data != null) {
          final userJson = data['user'] as Map<String, dynamic>;
          final tokensJson = data['tokens'] as Map<String, dynamic>;

          final user = UserModel.fromJson(userJson);
          final tokens = AuthTokens.fromJson(tokensJson);

          debugPrint('[LOGIN AUTH DEBUG] loginSuccess = true');
          debugPrint(
            '[LOGIN AUTH DEBUG] tokenReceived = ${tokens.accessToken.isNotEmpty}',
          );
          debugPrint(
            '[LOGIN AUTH DEBUG] tokenLength = ${tokens.accessToken.length}',
          );

          // Save securely
          var storageWriteCompleted = false;
          try {
            await StorageService.instance.saveTokens(
              accessToken: tokens.accessToken,
              refreshToken: tokens.refreshToken,
            );
            final tokenReadable =
                (await StorageService.instance.getAccessToken())?.isNotEmpty ==
                true;
            debugPrint('[AUTH LOGIN]');
            debugPrint('status = success');
            debugPrint('tokenReceived = ${tokens.accessToken.isNotEmpty}');
            debugPrint('tokenSaved = true');
            debugPrint('tokenReadable = $tokenReadable');
            storageWriteCompleted = true;
          } finally {
            debugPrint(
              '[LOGIN AUTH DEBUG] storageWriteCompleted = $storageWriteCompleted',
            );
          }
          await StorageService.instance.saveUser(user);

          _currentUser = user;
          await syncUserSessionData(user);
          _setLoading(false);
          notifyListeners();
          debugPrint('authState = AUTHENTICATED');
          debugPrint('navigationTarget = HOME');

          return AuthUser(
            id: user.id,
            fullName: user.fullName,
            username: user.username,
            email: user.email,
            phone: user.phone,
            countryCode: user.countryCode,
            accountType: user.accountType,
          );
        }
      }

      _setLoading(false);
      throw ApiException(
        response.message ?? 'Registration failed. Please try again.',
        statusCode: response.statusCode,
        code: response.errorCode,
      );
    } catch (e) {
      _setLoading(false);
      if (e is ApiException) rethrow;
      throw ApiException('Unable to register: ${e.toString()}');
    }
  }

  /// Login with email, username, or phone number and password
  Future<AuthUser> login({
    required String identifier,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final response = await ApiService.instance.post(
        '/auth/login',
        requiresAuth: false,
        body: {
          'identifier': identifier.trim(),
          // Keep the legacy field for deployed backends that have not yet
          // been updated to accept the unified identifier field.
          'email': identifier.trim(),
          'password': password,
          'deviceInfo': 'DietCompass Flutter Mobile',
        },
      );

      if (response.success && response.data != null) {
        final data = response.data!['data'] as Map<String, dynamic>?;
        if (data != null) {
          final userJson = data['user'] as Map<String, dynamic>;
          final tokensJson = data['tokens'] as Map<String, dynamic>;

          final user = UserModel.fromJson(userJson);
          final tokens = AuthTokens.fromJson(tokensJson);

          debugPrint('[LOGIN AUTH DEBUG] loginSuccess = true');
          debugPrint(
            '[LOGIN AUTH DEBUG] tokenReceived = ${tokens.accessToken.isNotEmpty}',
          );
          debugPrint(
            '[LOGIN AUTH DEBUG] tokenLength = ${tokens.accessToken.length}',
          );

          // Save securely
          var storageWriteCompleted = false;
          try {
            await StorageService.instance.saveTokens(
              accessToken: tokens.accessToken,
              refreshToken: tokens.refreshToken,
            );
            final tokenReadable =
                (await StorageService.instance.getAccessToken())?.isNotEmpty ==
                true;
            debugPrint('[AUTH LOGIN]');
            debugPrint('status = success');
            debugPrint('tokenReceived = ${tokens.accessToken.isNotEmpty}');
            debugPrint('tokenSaved = true');
            debugPrint('tokenReadable = $tokenReadable');
            storageWriteCompleted = true;
          } finally {
            debugPrint(
              '[LOGIN AUTH DEBUG] storageWriteCompleted = $storageWriteCompleted',
            );
          }
          await StorageService.instance.saveUser(user);

          _currentUser = user;
          await syncUserSessionData(user);
          _setLoading(false);
          notifyListeners();
          debugPrint('authState = AUTHENTICATED');
          debugPrint('navigationTarget = HOME');

          return AuthUser(
            id: user.id,
            fullName: user.fullName,
            username: user.username,
            email: user.email,
            phone: user.phone,
            countryCode: user.countryCode,
            accountType: user.accountType,
          );
        }
      }

      _setLoading(false);
      throw ApiException(
        response.message ??
            'Invalid credentials. Please check your email and password.',
        statusCode: response.statusCode,
        code: response.errorCode,
      );
    } catch (e) {
      _setLoading(false);
      if (e is ApiException) rethrow;
      throw ApiException('Unable to login: ${e.toString()}');
    }
  }

  /// Opens the native Google account picker and exchanges the selected
  /// account's verified ID token for a DietCompass session.
  Future<AuthUser?> loginWithGoogle() async {
    _setLoading(true);

    final serverClientIdConfigured = AppConfig.googleWebClientId.isNotEmpty;
    debugPrint('\n==============================================');
    debugPrint('[GOOGLE AUTH CONFIG]');
    debugPrint('package = com.example.diet_compass');
    debugPrint('serverClientIdConfigured = $serverClientIdConfigured');
    debugPrint('googleSignInInitialization = success');
    debugPrint('==============================================\n');

    try {
      await _googleSignIn.signOut();
      debugPrint('========== GOOGLE SIGN-IN DEBUG ==========');
debugPrint('package = com.example.diet_compass');
debugPrint('webClientId = ${AppConfig.googleWebClientId}');
debugPrint('googleSignIn = $_googleSignIn');
debugPrint('==========================================');

      final account = await _googleSignIn.signIn();
      if (account == null) return null;

      final idToken = (await account.authentication).idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const ApiException(
          'Google did not return a valid account token.',
        );
      }

      final response = await ApiService.instance.post(
        '/auth/google',
        requiresAuth: false,
        body: {'idToken': idToken},
      );
      if (!response.success || response.data == null) {
        throw ApiException(
          response.message ?? 'Unable to sign in with Google.',
          statusCode: response.statusCode,
          code: response.errorCode,
        );
      }

      final data = response.data!['data'] as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      final tokens = AuthTokens.fromJson(
        data['tokens'] as Map<String, dynamic>,
      );
      await StorageService.instance.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      await StorageService.instance.saveUser(user);
      _currentUser = user;
      await syncUserSessionData(user);
      notifyListeners();
      return AuthUser(
        id: user.id,
        fullName: user.fullName,
        username: user.username,
        email: user.email,
        phone: user.phone,
        countryCode: user.countryCode,
        accountType: user.accountType,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      if (e is PlatformException &&
          e.code == 'sign_in_failed' &&
          e.message?.contains('ApiException: 10') == true) {
        throw const ApiException(
          'Google Sign-In is not configured for this Android app. Register '
          'package com.example.diet_compass and the debug SHA-1 certificate '
          'in the same Google Cloud/Firebase project as the web client ID.',
        );
      }
      throw ApiException('Unable to sign in with Google: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch currently authenticated user profile from backend
  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await ApiService.instance.get(
        '/auth/me',
        requiresAuth: true,
        retryOn401: false,
      );

      if (response.success && response.data != null) {
        final data = response.data!['data'] as Map<String, dynamic>?;
        if (data != null && data['user'] != null) {
          final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
          _currentUser = user;
          await StorageService.instance.saveUser(user);
          await syncUserSessionData(user);
          notifyListeners();
          return user;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Refresh JWT Access Token using active Refresh Token
  Future<bool> refreshSession() async {
    try {
      final currentRefreshToken = await StorageService.instance
          .getRefreshToken();
      if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
        return false;
      }

      final response = await ApiService.instance.post(
        '/auth/refresh',
        requiresAuth: false,
        retryOn401: false,
        body: {
          'refreshToken': currentRefreshToken,
          'deviceInfo': 'DietCompass Flutter Mobile',
        },
      );

      if (response.success && response.data != null) {
        final data = response.data!['data'] as Map<String, dynamic>?;
        if (data != null && data['tokens'] != null) {
          final tokensJson = data['tokens'] as Map<String, dynamic>;
          final tokens = AuthTokens.fromJson(tokensJson);

          // Save rotated tokens securely
          await StorageService.instance.saveTokens(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
          );
          return true;
        }
      }

      // If refresh failed (e.g. revoked session), clear credentials
      await StorageService.instance.clearAuth();
      _currentUser = null;
      ProfileService.instance.clearCache();
      PersonalizationService.instance.clearCache();
      RecommendationService.instance.clearCompatibilityCache();
      ScanHistoryService.instance.clearCache();
      RecipeHistoryService.instance.clearCache();
      notifyListeners();
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Logout the current device session
  Future<void> logout() async {
    try {
      final refreshToken = await StorageService.instance.getRefreshToken();
      // Notify backend to revoke session
      await ApiService.instance.post(
        '/auth/logout',
        requiresAuth: true,
        retryOn401: false,
        body: {
          ...?(refreshToken == null
              ? null
              : <String, dynamic>{'refreshToken': refreshToken}),
        },
      );
    } catch (_) {
      // Continue local cleanup even if network fails
    } finally {
      await StorageService.instance.clearAuth();
      _currentUser = null;
      ProfileService.instance.clearCache();
      PersonalizationService.instance.clearCache();
      RecommendationService.instance.clearCompatibilityCache();
      ScanHistoryService.instance.clearCache();
      RecipeHistoryService.instance.clearCache();
      notifyListeners();
      debugPrint('[AUTH LOGOUT]');
      debugPrint('logoutStarted = true');
      debugPrint('tokensCleared = true');
      debugPrint(
        'tokenStillPresent = ${(await StorageService.instance.getAccessToken())?.isNotEmpty == true}',
      );
      debugPrint('authState = UNAUTHENTICATED');
      debugPrint('navigationTarget = LOGIN');
    }
  }

  /// Request password reset email
  Future<void> forgotPassword(String email) async {
    try {
      final response = await ApiService.instance.post(
        '/auth/forgot-password',
        requiresAuth: false,
        body: {'email': email.trim().toLowerCase()},
      );

      if (!response.success) {
        throw ApiException(
          response.message ??
              'Failed to send password reset email. Please try again.',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// Submit new password with reset token
  Future<AuthResult> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await ApiService.instance.post(
        '/auth/reset-password/$token',
        requiresAuth: false,
        body: {'password': newPassword},
      );

      if (response.success) {
        return AuthResult.success(
          message:
              response.message ??
              'Password reset successful. You can now log in.',
        );
      }

      return AuthResult.failure(
        message:
            response.message ??
            'Password reset failed. Token may have expired.',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return AuthResult.failure(message: 'Network error: ${e.toString()}');
    }
  }
}
