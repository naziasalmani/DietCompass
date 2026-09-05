import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../model/auth_user.dart';
import '../model/user_model.dart';
import '../model/user_profile.dart';
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

  /// Clears any previous session data and loads fresh profile & personalization for [user] asynchronously in background.
  Future<void> syncUserSessionData(UserModel user) async {
    // 1. Clear old user's caches first
    ProfileService.instance.clearCache();
    PersonalizationService.instance.clearCache();
    RecommendationService.instance.clearCompatibilityCache();
    ScanHistoryService.instance.clearCache();
    RecipeHistoryService.instance.clearCache();

    // 2. Load fresh user data asynchronously in background (non-blocking)
    loadUserDataInBackground(forceRefresh: true);
  }

  /// Fetches profile, personalization, scan history, and recipe history asynchronously in the background.
  /// Executed concurrently via Future.wait without blocking Splash Screen or main UI.
  Future<void> loadUserDataInBackground({bool forceRefresh = true}) async {
    final user = _currentUser;
    if (user == null) return;

    final totalStopwatch = Stopwatch()..start();

    try {
      int profileMs = 0;
      int personalizationMs = 0;
      int scanHistoryMs = 0;
      int recipeHistoryMs = 0;

      final profileFuture = () async {
        final sw = Stopwatch()..start();
        final res = await ProfileService.instance.getProfile(forceRefresh: forceRefresh).catchError((e) {
          debugPrint('[BACKGROUND USER DATA] Profile fetch error: $e');
          return ProfileService.instance.currentProfile ??
              UserProfile(
                id: user.id,
                fullName: user.fullName,
                username: user.username,
                email: user.email,
                phone: user.phone,
                countryCode: user.countryCode,
                accountType: user.accountType,
              );
        });
        profileMs = sw.elapsedMilliseconds;
        debugPrint('[STARTUP] profile: $profileMs ms');
        return res;
      }();

      final personalizationFuture = () async {
        final sw = Stopwatch()..start();
        final res = await PersonalizationService.instance.getPersonalization(forceRefresh: forceRefresh).catchError((e) {
          debugPrint('[BACKGROUND USER DATA] Personalization fetch error: $e');
          return PersonalizationService.instance.currentPersonalization;
        });
        personalizationMs = sw.elapsedMilliseconds;
        debugPrint('[STARTUP] personalization: $personalizationMs ms');
        return res;
      }();

      final scanHistoryFuture = () async {
        final sw = Stopwatch()..start();
        final res = await ScanHistoryService.instance.getScanHistory(forceRefresh: forceRefresh).catchError((e) {
          debugPrint('[BACKGROUND USER DATA] Scan history fetch error: $e');
          return ScanHistoryService.instance.currentHistory;
        });
        scanHistoryMs = sw.elapsedMilliseconds;
        debugPrint('[STARTUP] scan history: $scanHistoryMs ms');
        return res;
      }();

      final recipeHistoryFuture = () async {
        final sw = Stopwatch()..start();
        final res = await RecipeHistoryService.instance.getRecipeHistory(forceRefresh: forceRefresh).catchError((e) {
          debugPrint('[BACKGROUND USER DATA] Recipe history fetch error: $e');
          return RecipeHistoryService.instance.currentHistory;
        });
        recipeHistoryMs = sw.elapsedMilliseconds;
        debugPrint('[STARTUP] recipe history: $recipeHistoryMs ms');
        return res;
      }();


      await Future.wait([
        profileFuture,
        personalizationFuture,
        scanHistoryFuture,
        recipeHistoryFuture,
      ]);

      if (_currentUser == null || _currentUser!.id != user.id) {
        debugPrint('[BACKGROUND USER DATA] User logged out during background sync — ignoring stale responses.');
        return;
      }

      totalStopwatch.stop();

      debugPrint('\n==============================================');
      debugPrint('[STARTUP] total background initialization: ${totalStopwatch.elapsedMilliseconds} ms');
      debugPrint('[BACKGROUND USER DATA SYNC COMPLETE]');
      debugPrint('userId = ${user.id}');
      debugPrint('==============================================\n');
    } catch (e) {
      debugPrint('[BACKGROUND USER DATA] Error syncing session data: $e');
    }
  }

  /// Restores local authentication session state and cached profiles from encrypted on-device storage ONLY.
  /// Does NOT wait for remote API network calls or splash-blocking requests.
  Future<AuthUser?> restoreLocalSession() async {
    final sw = Stopwatch()..start();

    final hasCredentials = await StorageService.instance.hasStoredCredentials();
    if (!hasCredentials) {
      _currentUser = null;
      _isInitialized = true;
      sw.stop();
      debugPrint('[STARTUP] restore auth: ${sw.elapsedMilliseconds} ms');
      debugPrint('[STARTUP] total critical startup: ${sw.elapsedMilliseconds} ms');
      return null;
    }

    final storedUser = await StorageService.instance.getUser();
    if (storedUser == null) {
      _currentUser = null;
      _isInitialized = true;
      sw.stop();
      debugPrint('[STARTUP] restore auth: ${sw.elapsedMilliseconds} ms');
      debugPrint('[STARTUP] total critical startup: ${sw.elapsedMilliseconds} ms');
      return null;
    }

    _currentUser = storedUser;
    _isInitialized = true;

    // Fast local profile loading from secure storage
    await ProfileService.instance.loadLocalProfile();
    await PersonalizationService.instance.loadLocalPersonalization();

    notifyListeners();

    sw.stop();
    debugPrint('[STARTUP] restore auth: ${sw.elapsedMilliseconds} ms');
    debugPrint('[STARTUP] total critical startup: ${sw.elapsedMilliseconds} ms');

    return AuthUser(
      id: storedUser.id,
      fullName: storedUser.fullName,
      username: storedUser.username,
      email: storedUser.email,
      phone: storedUser.phone,
      countryCode: storedUser.countryCode,
      accountType: storedUser.accountType,
    );
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
        if (_currentUser == null) return null;
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
    debugPrint('[LOGOUT] button pressed');
    debugPrint('[LOGOUT] clearing token');

    final refreshToken = await StorageService.instance.getRefreshToken();

    // 1. Instantly clear local secure storage and memory state
    await StorageService.instance.clearAuth();
    _currentUser = null;

    debugPrint('[LOGOUT] token cleared');
    debugPrint('[LOGOUT] clearing in-memory user state');

    // 2. Clear all user-specific in-memory caches
    ProfileService.instance.clearCache();
    PersonalizationService.instance.clearCache();
    RecommendationService.instance.clearCompatibilityCache();
    ScanHistoryService.instance.clearCache();
    RecipeHistoryService.instance.clearCache();

    // 3. Notify listeners immediately so root gate reacts to UNAUTHENTICATED state
    debugPrint('[LOGOUT] auth state changed to UNAUTHENTICATED');
    notifyListeners();

    debugPrint('[LOGOUT] navigating to LOGIN');

    // 4. Asynchronously perform Google Sign-Out & backend session revocation without blocking UI transition
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('[LOGOUT] Google sign-out notice: $e');
    }

    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        ApiService.instance.post(
          '/auth/logout',
          requiresAuth: false,
          retryOn401: false,
          body: {'refreshToken': refreshToken},
        ).catchError((e) {
          debugPrint('[LOGOUT] Backend session revocation notice: $e');
          return const ApiResponse<Map<String, dynamic>>(
            success: false,
            message: 'Revocation unneeded',
          );
        });

      }
    } catch (e) {
      debugPrint('[LOGOUT] Backend session revocation error: $e');
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
