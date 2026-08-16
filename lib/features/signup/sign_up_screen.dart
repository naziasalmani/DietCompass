import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// DietCompass — Create Account (Sign Up) Screen
/// -----------------------------------------------------------------------
/// Built directly on the two supplied images:
///   • assets/images/bg_signup.png    — background art: gradient, salad
///     bowl, avocado, broccoli, leaves & sparkles.
///   • assets/images/compass_icon.png — the compass mark cropped from the
///     DietCompass logo asset (used here in the small horizontal lockup,
///     exactly like the reference).
///
/// Everything else — the form, the Individual/Family selector, the terms
/// checkbox, validation and the buttons — is real, functional Flutter UI
/// styled to match the reference mockup.
///
/// Add to pubspec.yaml:
/// ```yaml
/// flutter:
///   assets:
///     - assets/images/bg_signup.png
///     - assets/images/compass_icon.png
/// ```
enum AccountType { individual, family }

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({
    super.key,
    this.onBack,
    this.onSignUp,
    this.onGoogleTap,
    this.onAppleTap,
    this.onFacebookTap,
    this.onLoginTap,
    this.onTermsTap,
    this.onPrivacyTap,
    this.onCountryCodeTap,
  });

  final VoidCallback? onBack;

  /// Called with the fully validated form data once the user taps
  /// "Sign Up". Return/await your account-creation call here; the button
  /// shows a spinner while this future is running.
  final Future<void> Function(SignUpFormData data)? onSignUp;

  final VoidCallback? onGoogleTap;
  final VoidCallback? onAppleTap;
  final VoidCallback? onFacebookTap;
  final VoidCallback? onLoginTap;
  final VoidCallback? onTermsTap;
  final VoidCallback? onPrivacyTap;
  final VoidCallback? onCountryCodeTap;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

/// Simple value bag handed back to [SignUpScreen.onSignUp].
class SignUpFormData {
  SignUpFormData({
    required this.fullName,
    required this.username,
    required this.email,
    required this.countryCode,
    required this.phone,
    required this.password,
    required this.accountType,
  });

  final String fullName;
  final String username;
  final String email;
  final String countryCode;
  final String phone;
  final String password;
  final AccountType accountType;
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  late final AnimationController _entranceCtrl;
  late final AnimationController _breatheCtrl;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;
  bool _loading = false;
  AccountType _accountType = AccountType.individual;
  String _countryCode = '+91';
  String _countryFlag = '🇮🇳';

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..forward();
    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _entranceCtrl.dispose();
    _breatheCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms of Service and Privacy '
              'Policy to continue.'),
        ),
      );
      return;
    }
    if (widget.onSignUp == null) return;
    setState(() => _loading = true);
    try {
      await widget.onSignUp!(
        SignUpFormData(
          fullName: _fullNameCtrl.text.trim(),
          username: _usernameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          countryCode: _countryCode,
          phone: _phoneCtrl.text.trim(),
          password: _passwordCtrl.text,
          accountType: _accountType,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 390).clamp(0.85, 1.25);

    final headerFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    final headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
      ),
    );
    final cardFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.25, 0.7, curve: Curves.easeOut),
    );
    final cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.25, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFEFEAFA),
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _breatheCtrl,
            builder: (context, child) {
              final t = Curves.easeInOut.transform(_breatheCtrl.value);
              return Transform.scale(scale: 1.0 + t * 0.015, child: child);
            },
            child: Image.asset(
              'assets/images/bg_signup.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20 * scale,
                      10 * scale,
                      20 * scale,
                      0,
                    ),
                    child: FadeTransition(
                      opacity: headerFade,
                      child: _BackButton(onTap: widget.onBack, uiScale: scale),
                    ),
                  ),
                  SizedBox(height: 14 * scale),

                  // Horizontal logo lockup: icon + wordmark/tagline
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20 * scale),
                    child: FadeTransition(
                      opacity: headerFade,
                      child: SlideTransition(
                        position: headerSlide,
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/images/compass_icon.png',
                              width: 66 * scale,
                              height: 66 * scale,
                            ),
                            SizedBox(width: 14 * scale),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: 24 * scale,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                        fontFamily: 'Roboto',
                                      ),
                                      children: const [
                                        TextSpan(
                                          text: 'Diet',
                                          style: TextStyle(
                                            color: Color(0xFF1B1B2E),
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'Compass',
                                          style: TextStyle(
                                            color: Color(0xFF1E8A4C),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 2 * scale),
                                  RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: 12.5 * scale,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF3B3B4F),
                                      ),
                                      children: const [
                                        TextSpan(text: 'Scan. Analyze. '),
                                        TextSpan(
                                          text: 'Eat Better.',
                                          style: TextStyle(
                                            color: Color(0xFF1E8A4C),
                                          ),
                                        ),
                                        TextSpan(text: ' Live Healthier.'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 22 * scale),

                  // Headline
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20 * scale),
                    child: FadeTransition(
                      opacity: headerFade,
                      child: SlideTransition(
                        position: headerSlide,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Create Your Account ',
                                  style: TextStyle(
                                    fontSize: 22 * scale,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1B1B2E),
                                  ),
                                ),
                                Text('🌱',
                                    style: TextStyle(fontSize: 19 * scale)),
                              ],
                            ),
                            SizedBox(height: 4 * scale),
                            Text(
                              'Join DietCompass and start your healthy '
                              'journey today!',
                              style: TextStyle(
                                fontSize: 13.5 * scale,
                                color: const Color(0xFF6B6B7B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20 * scale),

                  // Form card
                  FadeTransition(
                    opacity: cardFade,
                    child: SlideTransition(
                      position: cardSlide,
                      child: _SignUpCard(
                        uiScale: scale,
                        formKey: _formKey,
                        fullNameCtrl: _fullNameCtrl,
                        usernameCtrl: _usernameCtrl,
                        emailCtrl: _emailCtrl,
                        phoneCtrl: _phoneCtrl,
                        passwordCtrl: _passwordCtrl,
                        confirmCtrl: _confirmCtrl,
                        obscurePassword: _obscurePassword,
                        obscureConfirm: _obscureConfirm,
                        agreedToTerms: _agreedToTerms,
                        loading: _loading,
                        accountType: _accountType,
                        countryCode: _countryCode,
                        countryFlag: _countryFlag,
                        onTogglePassword: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        onToggleConfirm: () => setState(
                          () => _obscureConfirm = !_obscureConfirm,
                        ),
                        onToggleAgree: (v) =>
                            setState(() => _agreedToTerms = v),
                        onAccountTypeChanged: (t) =>
                            setState(() => _accountType = t),
                        onCountryCodeTap: widget.onCountryCodeTap,
                        onSubmit: _submit,
                        onGoogleTap: widget.onGoogleTap,
                        onAppleTap: widget.onAppleTap,
                        onFacebookTap: widget.onFacebookTap,
                        onLoginTap: widget.onLoginTap,
                        onTermsTap: widget.onTermsTap,
                        onPrivacyTap: widget.onPrivacyTap,
                        entranceCtrl: _entranceCtrl,
                      ),
                    ),
                  ),
                  SizedBox(height: 20 * scale),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Back button
// ---------------------------------------------------------------------------
class _BackButton extends StatefulWidget {
  const _BackButton({required this.onTap, required this.uiScale});
  final VoidCallback? onTap;
  final double uiScale;

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.9),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 42 * widget.uiScale,
          height: 42 * widget.uiScale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.9),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_back,
            size: 20 * widget.uiScale,
            color: const Color(0xFF1B1B2E),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The white card containing the whole sign-up form
// ---------------------------------------------------------------------------
class _SignUpCard extends StatelessWidget {
  const _SignUpCard({
    required this.uiScale,
    required this.formKey,
    required this.fullNameCtrl,
    required this.usernameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.agreedToTerms,
    required this.loading,
    required this.accountType,
    required this.countryCode,
    required this.countryFlag,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onToggleAgree,
    required this.onAccountTypeChanged,
    required this.onSubmit,
    required this.entranceCtrl,
    this.onCountryCodeTap,
    this.onGoogleTap,
    this.onAppleTap,
    this.onFacebookTap,
    this.onLoginTap,
    this.onTermsTap,
    this.onPrivacyTap,
  });

  final double uiScale;
  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameCtrl;
  final TextEditingController usernameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final bool obscurePassword;
  final bool obscureConfirm;
  final bool agreedToTerms;
  final bool loading;
  final AccountType accountType;
  final String countryCode;
  final String countryFlag;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final ValueChanged<bool> onToggleAgree;
  final ValueChanged<AccountType> onAccountTypeChanged;
  final Future<void> Function() onSubmit;
  final AnimationController entranceCtrl;
  final VoidCallback? onCountryCodeTap;
  final VoidCallback? onGoogleTap;
  final VoidCallback? onAppleTap;
  final VoidCallback? onFacebookTap;
  final VoidCallback? onLoginTap;
  final VoidCallback? onTermsTap;
  final VoidCallback? onPrivacyTap;

  Animation<double> _fade(BuildContext c, double s, double e) =>
      CurvedAnimation(
        parent: entranceCtrl,
        curve: Interval(s, e, curve: Curves.easeOut),
      );

  Animation<Offset> _slide(double s, double e) => Tween<Offset>(
        begin: const Offset(0, 0.18),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: entranceCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        22 * uiScale,
        26 * uiScale,
        22 * uiScale,
        22 * uiScale,
      ),
      margin: EdgeInsets.symmetric(horizontal: 16 * uiScale),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Full name + Username
            FadeTransition(
              opacity: _fade(context, 0.3, 0.6),
              child: SlideTransition(
                position: _slide(0.3, 0.65),
                child: Row(
                  children: [
                    Expanded(
                      child: _AuthTextField(
                        controller: fullNameCtrl,
                        hint: 'Full Name',
                        icon: Icons.person_outline,
                        uiScale: uiScale,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                    ),
                    SizedBox(width: 12 * uiScale),
                    Expanded(
                      child: _AuthTextField(
                        controller: usernameCtrl,
                        hint: 'Username',
                        icon: Icons.person_outline,
                        uiScale: uiScale,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 14 * uiScale),

            // Email
            FadeTransition(
              opacity: _fade(context, 0.34, 0.64),
              child: SlideTransition(
                position: _slide(0.34, 0.68),
                child: _AuthTextField(
                  controller: emailCtrl,
                  hint: 'Email Address',
                  icon: Icons.mail_outline,
                  uiScale: uiScale,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
              ),
            ),
            SizedBox(height: 14 * uiScale),

            // Phone + country code
            FadeTransition(
              opacity: _fade(context, 0.38, 0.68),
              child: SlideTransition(
                position: _slide(0.38, 0.72),
                child: Row(
                  children: [
                    Expanded(
                      child: _AuthTextField(
                        controller: phoneCtrl,
                        hint: 'Phone Number',
                        icon: Icons.call_outlined,
                        uiScale: uiScale,
                        keyboardType: TextInputType.phone,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                    ),
                    SizedBox(width: 10 * uiScale),
                    _CountryCodeChip(
                      flag: countryFlag,
                      code: countryCode,
                      uiScale: uiScale,
                      onTap: onCountryCodeTap,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 14 * uiScale),

            // Password
            FadeTransition(
              opacity: _fade(context, 0.42, 0.72),
              child: SlideTransition(
                position: _slide(0.42, 0.76),
                child: _AuthTextField(
                  controller: passwordCtrl,
                  hint: 'Password',
                  icon: Icons.lock_outline,
                  uiScale: uiScale,
                  obscureText: obscurePassword,
                  validator: (v) {
                    if (v == null || v.length < 8) {
                      return 'Use at least 8 characters';
                    }
                    return null;
                  },
                  suffix: _EyeToggle(
                    obscured: obscurePassword,
                    uiScale: uiScale,
                    onTap: onTogglePassword,
                  ),
                ),
              ),
            ),
            SizedBox(height: 6 * uiScale),
            FadeTransition(
              opacity: _fade(context, 0.44, 0.72),
              child: Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 13 * uiScale,
                    color: const Color(0xFF6C4EF5),
                  ),
                  SizedBox(width: 5 * uiScale),
                  Expanded(
                    child: Text(
                      'Use 8+ characters with a mix of letters, numbers '
                      '& symbols',
                      style: TextStyle(
                        fontSize: 11 * uiScale,
                        color: const Color(0xFF8B87A0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12 * uiScale),

            // Confirm password
            FadeTransition(
              opacity: _fade(context, 0.46, 0.74),
              child: SlideTransition(
                position: _slide(0.46, 0.78),
                child: _AuthTextField(
                  controller: confirmCtrl,
                  hint: 'Confirm Password',
                  icon: Icons.lock_outline,
                  uiScale: uiScale,
                  obscureText: obscureConfirm,
                  validator: (v) {
                    if (v != passwordCtrl.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  suffix: _EyeToggle(
                    obscured: obscureConfirm,
                    uiScale: uiScale,
                    onTap: onToggleConfirm,
                  ),
                ),
              ),
            ),
            SizedBox(height: 18 * uiScale),

            // Account type
            FadeTransition(
              opacity: _fade(context, 0.5, 0.78),
              child: SlideTransition(
                position: _slide(0.5, 0.82),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'I am signing up as',
                      style: TextStyle(
                        fontSize: 13.5 * uiScale,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1B1B2E),
                      ),
                    ),
                    SizedBox(height: 10 * uiScale),
                    Row(
                      children: [
                        Expanded(
                          child: _AccountTypeCard(
                            selected: accountType == AccountType.individual,
                            icon: Icons.person,
                            iconBg: const Color(0xFFEDE7FA),
                            iconColor: const Color(0xFF6C4EF5),
                            title: 'Individual',
                            subtitle: 'For personal use',
                            uiScale: uiScale,
                            onTap: () => onAccountTypeChanged(
                              AccountType.individual,
                            ),
                          ),
                        ),
                        SizedBox(width: 12 * uiScale),
                        Expanded(
                          child: _AccountTypeCard(
                            selected: accountType == AccountType.family,
                            icon: Icons.groups,
                            iconBg: const Color(0xFFE4F5E9),
                            iconColor: const Color(0xFF1E8A4C),
                            title: 'Family',
                            subtitle: 'Manage family health',
                            uiScale: uiScale,
                            onTap: () =>
                                onAccountTypeChanged(AccountType.family),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 18 * uiScale),

            // Terms checkbox
            FadeTransition(
              opacity: _fade(context, 0.55, 0.82),
              child: _TermsCheckbox(
                value: agreedToTerms,
                uiScale: uiScale,
                onChanged: onToggleAgree,
                onTermsTap: onTermsTap,
                onPrivacyTap: onPrivacyTap,
              ),
            ),
            SizedBox(height: 16 * uiScale),

            // Sign up button
            FadeTransition(
              opacity: _fade(context, 0.6, 0.9),
              child: SlideTransition(
                position: _slide(0.6, 0.95),
                child: _GradientButton(
                  label: 'Sign Up',
                  loading: loading,
                  uiScale: uiScale,
                  onTap: onSubmit,
                ),
              ),
            ),
            SizedBox(height: 20 * uiScale),

            FadeTransition(
              opacity: _fade(context, 0.65, 0.95),
              child: Row(
                children: [
                  const Expanded(child: Divider(color: Color(0xFFE2DEF0))),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10 * uiScale),
                    child: Text(
                      'or sign up with',
                      style: TextStyle(
                        fontSize: 12.5 * uiScale,
                        color: const Color(0xFF9A96A8),
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Color(0xFFE2DEF0))),
                ],
              ),
            ),
            SizedBox(height: 16 * uiScale),

            FadeTransition(
              opacity: _fade(context, 0.7, 1.0),
              child: SlideTransition(
                position: _slide(0.7, 1.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _SocialButton(
                        uiScale: uiScale,
                        onTap: onGoogleTap,
                        label: 'Google',
                        icon: const _GoogleGlyph(),
                      ),
                    ),
                    SizedBox(width: 10 * uiScale),
                    Expanded(
                      child: _SocialButton(
                        uiScale: uiScale,
                        onTap: onAppleTap,
                        label: 'Apple',
                        icon: Icon(
                          Icons.apple,
                          size: 20 * uiScale,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(width: 10 * uiScale),
                    Expanded(
                      child: _SocialButton(
                        uiScale: uiScale,
                        onTap: onFacebookTap,
                        label: 'Facebook',
                        icon: Icon(
                          Icons.facebook,
                          size: 20 * uiScale,
                          color: const Color(0xFF1877F2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 18 * uiScale),

            FadeTransition(
              opacity: _fade(context, 0.75, 1.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(
                      fontSize: 13 * uiScale,
                      color: const Color(0xFF6B6B7B),
                    ),
                  ),
                  GestureDetector(
                    onTap: onLoginTap,
                    child: Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 13 * uiScale,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6C4EF5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Country code chip (flag + code + chevron)
// ---------------------------------------------------------------------------
class _CountryCodeChip extends StatelessWidget {
  const _CountryCodeChip({
    required this.flag,
    required this.code,
    required this.uiScale,
    this.onTap,
  });

  final String flag;
  final String code;
  final double uiScale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54 * uiScale,
        padding: EdgeInsets.symmetric(horizontal: 10 * uiScale),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE4E0F2), width: 1.2),
          color: Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: TextStyle(fontSize: 16 * uiScale)),
            SizedBox(width: 4 * uiScale),
            Text(
              code,
              style: TextStyle(
                fontSize: 13.5 * uiScale,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1B1B2E),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16 * uiScale,
              color: const Color(0xFF9A96A8),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Eye toggle for password fields
// ---------------------------------------------------------------------------
class _EyeToggle extends StatelessWidget {
  const _EyeToggle({
    required this.obscured,
    required this.uiScale,
    required this.onTap,
  });

  final bool obscured;
  final double uiScale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: Icon(
          obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          key: ValueKey(obscured),
          color: const Color(0xFF9A96A8),
          size: 20 * uiScale,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual / Family selectable card
// ---------------------------------------------------------------------------
class _AccountTypeCard extends StatelessWidget {
  const _AccountTypeCard({
    required this.selected,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.uiScale,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final double uiScale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(14 * uiScale),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected ? const Color(0xFFF6F3FE) : Colors.white,
          border: Border.all(
            color: selected ? const Color(0xFF6C4EF5) : const Color(0xFFE4E0F2),
            width: selected ? 1.6 : 1.2,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 16 * uiScale,
                height: 16 * uiScale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? const Color(0xFF6C4EF5) : Colors.white,
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF6C4EF5)
                        : const Color(0xFFCFC9E5),
                    width: 1.4,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38 * uiScale,
                  height: 38 * uiScale,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 19 * uiScale),
                ),
                SizedBox(height: 10 * uiScale),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5 * uiScale,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B1B2E),
                  ),
                ),
                SizedBox(height: 2 * uiScale),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11 * uiScale,
                    color: const Color(0xFF8B87A0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Terms & Privacy checkbox with tappable links
// ---------------------------------------------------------------------------
class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.value,
    required this.uiScale,
    required this.onChanged,
    this.onTermsTap,
    this.onPrivacyTap,
  });

  final bool value;
  final double uiScale;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onTermsTap;
  final VoidCallback? onPrivacyTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 22 * uiScale,
            height: 22 * uiScale,
            margin: EdgeInsets.only(top: 1 * uiScale),
            decoration: BoxDecoration(
              color: value ? const Color(0xFF6C4EF5) : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: value ? const Color(0xFF6C4EF5) : const Color(0xFFCFC9E5),
                width: 1.4,
              ),
            ),
            child: value
                ? Icon(Icons.check, size: 15 * uiScale, color: Colors.white)
                : null,
          ),
        ),
        SizedBox(width: 10 * uiScale),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 12.5 * uiScale,
                color: const Color(0xFF3B3B4F),
                height: 1.4,
              ),
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms of Service',
                  style: const TextStyle(
                    color: Color(0xFF6C4EF5),
                    fontWeight: FontWeight.w700,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = onTermsTap,
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: const TextStyle(
                    color: Color(0xFF6C4EF5),
                    fontWeight: FontWeight.w700,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = onPrivacyTap,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared building blocks (kept local so this screen is self-contained)
// ---------------------------------------------------------------------------
class _AuthTextField extends StatefulWidget {
  const _AuthTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.uiScale,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffix,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final double uiScale;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final TextCapitalization textCapitalization;

  @override
  State<_AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<_AuthTextField> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _focused ? const Color(0xFF6C4EF5) : const Color(0xFFE4E0F2),
          width: _focused ? 1.6 : 1.2,
        ),
        color: Colors.white,
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: const Color(0xFF6C4EF5).withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        textCapitalization: widget.textCapitalization,
        style: TextStyle(fontSize: 14 * widget.uiScale),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: const Color(0xFFB0ACC2),
            fontSize: 13.5 * widget.uiScale,
          ),
          errorStyle: TextStyle(fontSize: 10.5 * widget.uiScale),
          prefixIcon: Icon(
            widget.icon,
            color: const Color(0xFF6C4EF5),
            size: 19 * widget.uiScale,
          ),
          suffixIcon: widget.suffix,
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            vertical: 16 * widget.uiScale,
            horizontal: 4,
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatefulWidget {
  const _GradientButton({
    required this.label,
    required this.loading,
    required this.uiScale,
    required this.onTap,
  });

  final String label;
  final bool loading;
  final double uiScale;
  final Future<void> Function() onTap;

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.loading ? null : widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 54 * widget.uiScale,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF6C4EF5), Color(0xFF1E8A4C)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C4EF5).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: widget.loading
                ? SizedBox(
                    width: 22 * widget.uiScale,
                    height: 22 * widget.uiScale,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16 * widget.uiScale,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 8 * widget.uiScale),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 18 * widget.uiScale,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatefulWidget {
  const _SocialButton({
    required this.uiScale,
    required this.label,
    required this.icon,
    this.onTap,
  });

  final double uiScale;
  final String label;
  final Widget icon;
  final VoidCallback? onTap;

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.93),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 46 * widget.uiScale,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE4E0F2)),
            color: Colors.white,
          ),
          child: Center(child: widget.icon),
        ),
      ),
    );
  }
}

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        colors: [
          Color(0xFF4285F4),
          Color(0xFFEA4335),
          Color(0xFFFBBC05),
          Color(0xFF34A853),
        ],
        stops: [0.0, 0.35, 0.65, 1.0],
      ).createShader(rect),
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}
