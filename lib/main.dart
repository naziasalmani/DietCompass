import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'core/model/auth_user.dart';
import 'core/services/api_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/personalization_service.dart';
import 'core/services/profile_service.dart';
import 'core/services/storage_service.dart';
import 'features/forgot_password/forgot_password_screen.dart';
import 'features/forgot_password/reset_password_screen.dart';
import 'features/home/home_screen.dart';
import 'features/login/login_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'package:diet_compass/features/personalization/lib/onboarding/onboarding_data.dart';
import 'package:diet_compass/features/personalization/lib/onboarding/onboarding_flow.dart';
import 'features/signup/sign_up_screen.dart';
import 'features/splash/splash_screen.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

/// Deep-link scheme used for password-reset links.
/// Backend CLIENT_URL must be set to "dietcompass://"
/// Reset URLs will be: `dietcompass://reset-password/<token>`
const _kDeepLinkScheme = 'dietcompass';
const _kResetPasswordPath = 'reset-password';

final _rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.instance.initialize();
  runApp(const DietCompassApp());
}

class DietCompassApp extends StatelessWidget {
  const DietCompassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'DietCompass',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: _rootScaffoldMessengerKey,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeController.instance.themeMode,
          home: const AppFlow(),
        );
      },
    );
  }
}

// ── AppFlow ───────────────────────────────────────────────────────────────────
//
// Manages the top-level auth & personalization state for the entire app.
//
// State machine:
//   _AppState.splash          → showing the animated splash screen & running background init
//   _AppState.auth            → unauthenticated → show onboarding / login
//   _AppState.personalization → authenticated user needing to complete 7-step flow
//   _AppState.home            → authenticated & personalized → show HomeScreen

enum _AppState { splash, auth, personalization, home }

class AppFlow extends StatefulWidget {
  const AppFlow({super.key});

  @override
  State<AppFlow> createState() => _AppFlowState();
}

class _AppFlowState extends State<AppFlow> {
  _AppState _state = _AppState.splash;
  AuthUser? _user;
  OnboardingData? _initialPersonalizationData;
  bool _hasSeenIntroOnboarding = false;
  String? _splashError;

  // Separate navigator keys for authenticated and unauthenticated flows.
  final _authenticatedNavigatorKey = GlobalKey<NavigatorState>();
  final _unauthenticatedNavigatorKey = GlobalKey<NavigatorState>();

  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    AuthService.instance.addListener(_handleAuthStateChanged);
    _initDeepLinks();
    _initializeStartup();
  }

  @override
  void dispose() {
    AuthService.instance.removeListener(_handleAuthStateChanged);
    super.dispose();
  }

  void _handleAuthStateChanged() {
    if (!mounted) return;

    final user = AuthService.instance.currentUser;
    debugPrint(
      '[LOGOUT] auth state observed by root gate: isAuthenticated = '
      '${AuthService.instance.isAuthenticated}',
    );

    if (user != null && _state == _AppState.auth) {
      _authenticatedNavigatorKey.currentState?.popUntil((r) => r.isFirst);
      setState(() {
        _user = AuthUser(
          id: user.id,
          fullName: user.fullName,
          username: user.username,
          email: user.email,
          phone: user.phone,
          countryCode: user.countryCode,
          accountType: user.accountType,
        );
        _state = _AppState.home;
      });
      return;
    }

    if (user == null &&
        _state != _AppState.splash &&
        _state != _AppState.auth) {
      _authenticatedNavigatorKey.currentState?.popUntil((r) => r.isFirst);
      _unauthenticatedNavigatorKey.currentState?.popUntil((r) => r.isFirst);
      setState(() {
        _user = null;
        _initialPersonalizationData = null;
        _state = _AppState.auth;
      });
    }
  }

  // ── Deep link setup ───────────────────────────────────────────────────────

  void _initDeepLinks() {
    _appLinks = AppLinks();

    // Handle links that opened the app from a terminated state.
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });

    // Handle links while the app is running.
    _appLinks.uriLinkStream.listen(_handleDeepLink);
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme != _kDeepLinkScheme &&
        uri.scheme != 'http' &&
        uri.scheme != 'https') {
      return;
    }

    // Support dietcompass://reset-password?token=XYZ
    // and dietcompass://reset-password/<token>
    String token = uri.queryParameters['token'] ?? '';

    if (token.isEmpty) {
      final segments = uri.pathSegments;

      if (segments.length >= 2 && segments[0] == _kResetPasswordPath) {
        token = segments[1];
      } else if (segments.isNotEmpty &&
          segments[0] == _kResetPasswordPath &&
          uri.hasQuery) {
        token = uri.queryParameters['token'] ?? '';
      }
    }

    if (token.isNotEmpty) {
      final navigator =
          _state == _AppState.home
              ? _authenticatedNavigatorKey.currentState
              : _unauthenticatedNavigatorKey.currentState;

      navigator?.push(
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(token: token),
        ),
      );
    }
  }

  // ── Startup Initialization ─────────────────────────────────────────────────

  /// Restores local session and immediately routes without waiting for remote API requests.
  Future<void> _initializeStartup() async {
    if (_splashError != null) {
      setState(() => _splashError = null);
    }

    try {
      // 1. Check intro onboarding state from local secure storage
      final introSeen = await StorageService.instance.hasSeenIntroOnboarding();
      _hasSeenIntroOnboarding = introSeen;

      // 2. Restore local authentication session (NO REMOTE API CALLS)
      final user = await AuthService.instance.restoreLocalSession();

      if (user == null) {
        if (!mounted) return;
        setState(() => _state = _AppState.auth);
        return;
      }

      _user = user;

      // 3. Immediately transition to Home UI without waiting for remote data
      if (!mounted) return;
      setState(() => _state = _AppState.home);

      // 4. Trigger non-blocking background user data synchronization
      AuthService.instance.loadUserDataInBackground(forceRefresh: true);
    } catch (e) {
      debugPrint('Startup initialization error: $e');

      if (!mounted) return;

      // Fallback: If local restoration encounters an error, route to auth
      setState(() => _state = _AppState.auth);
    }
  }

  // ── Auth callbacks ────────────────────────────────────────────────────────

  /// Called by LoginScreen.onLogin — authenticates and checks personalization.
  Future<void> _handleLogin(String identifier, String password) async {
    try {
      final user = await AuthService.instance.login(
        identifier: identifier,
        password: password,
      );

      if (!mounted) return;

      _user = user;

      // Fetch cloud profile to check if personalization is complete
      try {
        final profile = await ProfileService.instance.getProfile(
          forceRefresh: true,
        );

        if (!mounted) return;

        if (profile.isPersonalizationComplete) {
          await PersonalizationService.instance.getPersonalization(
            forceRefresh: true,
          );

          setState(() => _state = _AppState.home);
        } else {
          final pers =
              await PersonalizationService.instance.getPersonalization(
                forceRefresh: true,
              );

          _initialPersonalizationData =
              pers?.toOnboardingData() ??
              (OnboardingData()..fullName = profile.fullName);

          setState(() => _state = _AppState.personalization);
        }
      } catch (_) {
        if (!mounted) return;
        setState(() => _state = _AppState.home);
      }
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> _handleGoogleLogin() async {
    try {
      final user = await AuthService.instance.loginWithGoogle();

      if (!mounted || user == null) return;

      _user = user;

      try {
        final profile = await ProfileService.instance.getProfile(
          forceRefresh: true,
        );

        if (!mounted) return;

        debugPrint(
          '[GOOGLE LOGIN] personalizationComplete = '
          '${profile.isPersonalizationComplete}',
        );

        if (profile.isPersonalizationComplete) {
          await PersonalizationService.instance.getPersonalization(
            forceRefresh: true,
          );

          setState(() => _state = _AppState.home);
        } else {
          final pers =
              await PersonalizationService.instance.getPersonalization(
                forceRefresh: true,
              );

          _initialPersonalizationData =
              pers?.toOnboardingData() ??
              (OnboardingData()..fullName = profile.fullName);

          setState(() => _state = _AppState.personalization);
        }
      } catch (_) {
        if (mounted) {
          setState(() => _state = _AppState.home);
        }
      }
    } on ApiException catch (e) {
      debugPrint('Google sign-in failed: ${e.message}');

      if (!mounted) return;

      _rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFE0525C),
        ),
      );
    } catch (e) {
      debugPrint('Google sign-in failed: $e');

      if (!mounted) return;

      _rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Google sign-in failed. Please try again.'),
          backgroundColor: Color(0xFFE0525C),
        ),
      );
    }
  }

  /// Called by SignUpScreen.onSignUp — registers a new account, stores tokens,
  /// then navigates to the 7-step personalization flow with cloud persistence.
  Future<void> _handleSignUp(SignUpFormData data) async {
    try {
      final user = await AuthService.instance.register(
        fullName: data.fullName,
        username: data.username,
        email: data.email,
        phone: data.phone,
        countryCode: data.countryCode,
        password: data.password,
        accountType: data.accountType == AccountType.individual
            ? 'individual'
            : 'family',
      );

      if (!mounted) return;

      _user = user;
      _initialPersonalizationData =
          OnboardingData()..fullName = data.fullName;

      setState(() => _state = _AppState.personalization);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Called when 7-step personalization is completed.
  Future<void> _handlePersonalizationComplete(
    OnboardingData data,
  ) async {
    try {
      await PersonalizationService.instance.savePersonalization(
        data,
        isCompleted: true,
      );

      // Refresh user profile in memory
      await ProfileService.instance.getProfile(forceRefresh: true);
    } catch (e) {
      debugPrint('Personalization sync error (handled safely): $e');
    }

    if (!mounted) return;

    setState(() => _state = _AppState.home);
  }

  /// Called when user chooses to skip personalization.
  Future<void> _handlePersonalizationSkip() async {
    try {
      final fallbackData =
          _initialPersonalizationData ?? OnboardingData();

      await PersonalizationService.instance.savePersonalization(
        fallbackData,
        isCompleted: true,
      );

      await ProfileService.instance.getProfile(forceRefresh: true);
    } catch (e) {
      debugPrint('Personalization skip sync error: $e');
    }

    if (!mounted) return;

    setState(() => _state = _AppState.home);
  }

  /// Called by ForgotPasswordScreen.onSendResetLink.
  Future<void> _handleForgotPassword(String email) async {
    try {
      await AuthService.instance.forgotPassword(email);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Logs out the current device session and returns to the auth flow.
  Future<void> _handleLogout() async {
    debugPrint('[LOGOUT] button pressed');

    _authenticatedNavigatorKey.currentState?.popUntil((r) => r.isFirst);
    _unauthenticatedNavigatorKey.currentState?.popUntil((r) => r.isFirst);

    await AuthService.instance.logout();

    if (!mounted) return;

    setState(() {
      _user = null;
      _initialPersonalizationData = null;
      _state = _AppState.auth;
    });

    debugPrint('[LOGOUT] root gate updated: _state = _AppState.auth');
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Splash state: renders DietCompass branding and covers background initialization.
    if (_state == _AppState.splash) {
      return SplashScreen(
        errorMessage: _splashError,
        onRetry: _initializeStartup,
        statusMessage: 'Preparing your personalized experience...',
      );
    }

    // Personalization flow state
    // (New user or incomplete personalization)
    if (_state == _AppState.personalization) {
      return OnboardingFlow(
        initialData: _initialPersonalizationData,
        onComplete: _handlePersonalizationComplete,
        onSkipAll: _handlePersonalizationSkip,
      );
    }

    // Authenticated & Personalized: HomeScreen wrapped in Navigator.
    if (_state == _AppState.home) {
      return KeyedSubtree(
        key: const ValueKey('authenticated'),
        child: _AuthenticatedApp(
          user: _user!,
          onLogout: _handleLogout,
          navigatorKey: _authenticatedNavigatorKey,
        ),
      );
    }

    // Unauthenticated flow: Onboarding (if first install) →
    // Login / Signup / ForgotPassword.
    return KeyedSubtree(
      key: const ValueKey('unauthenticated'),
      child: _UnauthenticatedApp(
        hasSeenIntroOnboarding: _hasSeenIntroOnboarding,
        onIntroOnboardingComplete: () async {
          await StorageService.instance.setIntroOnboardingSeen(true);

          if (mounted) {
            setState(() => _hasSeenIntroOnboarding = true);
          }
        },
        onLogin: _handleLogin,
        onGoogleLogin: _handleGoogleLogin,
        onSignUp: _handleSignUp,
        onForgotPassword: _handleForgotPassword,
        navigatorKey: _unauthenticatedNavigatorKey,
      ),
    );
  }
}

// ── Authenticated sub-app ─────────────────────────────────────────────────────

class _AuthenticatedApp extends StatelessWidget {
  const _AuthenticatedApp({
    required this.user,
    required this.onLogout,
    required this.navigatorKey,
  });

  final AuthUser user;
  final Future<void> Function() onLogout;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (_) => HomeScreen(
          userName: user.displayName,
          onLogout: onLogout,
        ),
      ),
    );
  }
}

// ── Unauthenticated sub-app ───────────────────────────────────────────────────

class _UnauthenticatedApp extends StatelessWidget {
  const _UnauthenticatedApp({
    required this.hasSeenIntroOnboarding,
    required this.onIntroOnboardingComplete,
    required this.onLogin,
    required this.onGoogleLogin,
    required this.onSignUp,
    required this.onForgotPassword,
    required this.navigatorKey,
  });

  final bool hasSeenIntroOnboarding;
  final VoidCallback onIntroOnboardingComplete;
  final Future<void> Function(String email, String password) onLogin;
  final Future<void> Function() onGoogleLogin;
  final Future<void> Function(SignUpFormData data) onSignUp;
  final Future<void> Function(String email) onForgotPassword;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (_) {
          if (!hasSeenIntroOnboarding) {
            return OnboardingScreen(
              onComplete: () {
                onIntroOnboardingComplete();

                navigatorKey.currentState?.pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => _buildLoginScreen(),
                  ),
                );
              },
              onSkip: () {
                onIntroOnboardingComplete();

                navigatorKey.currentState?.pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => _buildLoginScreen(),
                  ),
                );
              },
            );
          }

          return _buildLoginScreen();
        },
      ),
    );
  }

  Widget _buildLoginScreen() {
    return LoginScreen(
      onLogin: onLogin,
      onGoogleTap: onGoogleLogin,
      onSignUpTap: () {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => _buildSignUpScreen(),
          ),
        );
      },
      onForgotPassword: () {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => _buildForgotPasswordScreen(),
          ),
        );
      },
    );
  }

  Widget _buildSignUpScreen() {
    return SignUpScreen(
      onBack: () => navigatorKey.currentState?.pop(),
      onSignUp: onSignUp,
      onGoogleTap: onGoogleLogin,
      onLoginTap: () => navigatorKey.currentState?.pop(),
    );
  }

  Widget _buildForgotPasswordScreen() {
    return ForgotPasswordScreen(
      onBack: () => navigatorKey.currentState?.pop(),
      onSendResetLink: onForgotPassword,
      onLoginTap: () => navigatorKey.currentState?.pop(),
    );
  }
}