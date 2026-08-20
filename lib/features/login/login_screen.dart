import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/// DietCompass — Login Screen
/// -----------------------------------------------------------------------
/// Built directly on the two supplied images:
///   • assets/images/bg_login.png    — full background art: gradient,
///     salad bowl, avocado, blueberries, broccoli, leaves & glow rings.
///   • assets/images/logo_header.png — compass logo + "DietCompass"
///     wordmark + tagline + AI badge (same asset used on the splash
///     screen), with its pre-applied bottom fade so it blends straight
///     into the background behind it.
///
/// Everything below the logo — the glass card, fields, buttons — is real
/// Flutter UI (so it can actually take input, validate, and submit),
/// styled to match the reference mockup exactly.
///
/// Add to pubspec.yaml:
/// ```yaml
/// flutter:
///   assets:
///     - assets/images/bg_login.png
///     - assets/images/logo_header.png
/// ```
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.onLogin,
    this.onGoogleTap,
    this.onAppleTap,
    this.onFacebookTap,
    this.onForgotPassword,
    this.onSignUpTap,
  });

  /// Called with (email, password) when the user submits the form after
  /// it passes validation. Return/await your auth call here; the button
  /// shows a spinner while this future is running.
  final Future<void> Function(String email, String password)? onLogin;

  final VoidCallback? onGoogleTap;
  final VoidCallback? onAppleTap;
  final VoidCallback? onFacebookTap;
  final VoidCallback? onForgotPassword;
  final VoidCallback? onSignUpTap;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  late final AnimationController _entranceCtrl;
  late final AnimationController _breatheCtrl;

  bool _obscure = true;
  bool _loading = false;
  String? _errorMessage;

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
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _entranceCtrl.dispose();
    _breatheCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (widget.onLogin == null) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await widget.onLogin!(_emailCtrl.text.trim(), _passwordCtrl.text);
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          // Strip the 'Exception: ' prefix that _handleLogin wraps
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred. Please try again.';
          _loading = false;
        });
      }
    } finally {
      if (mounted && _loading) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 390).clamp(0.85, 1.25);

    final logoFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    final logoScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    final cardFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.3, 0.85, curve: Curves.easeOut),
    );
    final cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFEFEAFA),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Living background — slow breathing zoom on the supplied art.
          AnimatedBuilder(
            animation: _breatheCtrl,
            builder: (context, child) {
              final t = Curves.easeInOut.transform(_breatheCtrl.value);
              return Transform.scale(scale: 1.0 + t * 0.015, child: child);
            },
            child: Image.asset(
              'assets/images/bg_login.png',
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
                children: [
                  SizedBox(height: 18 * scale),
                  FadeTransition(
                    opacity: logoFade,
                    child: ScaleTransition(
                      scale: logoScale,
                      alignment: Alignment.topCenter,
                      child: Image.asset(
                        'assets/images/logo_header.png',
                        width: size.width * 0.86,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ),
                  SizedBox(height: 22 * scale),
                  FadeTransition(
                    opacity: cardFade,
                    child: SlideTransition(
                      position: cardSlide,
                      child: _GlassCard(
                        uiScale: scale,
                        formKey: _formKey,
                        emailCtrl: _emailCtrl,
                        passwordCtrl: _passwordCtrl,
                        obscure: _obscure,
                        loading: _loading,
                        errorMessage: _errorMessage,
                        onToggleObscure: () =>
                            setState(() => _obscure = !_obscure),
                        onSubmit: _submit,
                        onForgotPassword: widget.onForgotPassword,
                        onGoogleTap: widget.onGoogleTap,
                        onAppleTap: widget.onAppleTap,
                        onFacebookTap: widget.onFacebookTap,
                        onSignUpTap: widget.onSignUpTap,
                        entranceCtrl: _entranceCtrl,
                      ),
                    ),
                  ),
                  SizedBox(height: 16 * scale),
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
// Glassmorphism card containing the whole login form
// ---------------------------------------------------------------------------
class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.uiScale,
    required this.formKey,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscure,
    required this.loading,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.entranceCtrl,
    this.errorMessage,
    this.onForgotPassword,
    this.onGoogleTap,
    this.onAppleTap,
    this.onFacebookTap,
    this.onSignUpTap,
  });

  final double uiScale;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscure;
  final bool loading;
  final String? errorMessage;
  final VoidCallback onToggleObscure;
  final Future<void> Function() onSubmit;
  final AnimationController entranceCtrl;
  final VoidCallback? onForgotPassword;
  final VoidCallback? onGoogleTap;
  final VoidCallback? onAppleTap;
  final VoidCallback? onFacebookTap;
  final VoidCallback? onSignUpTap;

  Animation<double> _fieldFade(double start, double end) => CurvedAnimation(
        parent: entranceCtrl,
        curve: Interval(start, end, curve: Curves.easeOut),
      );

  Animation<Offset> _fieldSlide(double start, double end) => Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: entranceCtrl,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            24 * uiScale,
            28 * uiScale,
            24 * uiScale,
            22 * uiScale,
          ),
          margin: EdgeInsets.symmetric(horizontal: 20 * uiScale),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
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
                FadeTransition(
                  opacity: _fieldFade(0.3, 0.6),
                  child: SlideTransition(
                    position: _fieldSlide(0.3, 0.65),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Welcome Back! ',
                              style: TextStyle(
                                fontSize: 22 * uiScale,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1B1B2E),
                              ),
                            ),
                            Text('🌱', style: TextStyle(fontSize: 20 * uiScale)),
                          ],
                        ),
                        SizedBox(height: 6 * uiScale),
                        Text(
                          'Login to continue your healthy journey',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5 * uiScale,
                            color: const Color(0xFF6B6B7B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 22 * uiScale),

                // Email field
                FadeTransition(
                  opacity: _fieldFade(0.38, 0.68),
                  child: SlideTransition(
                    position: _fieldSlide(0.38, 0.72),
                    child: _AuthTextField(
                      controller: emailCtrl,
                      hint: 'Email or Phone Number',
                      icon: Icons.mail_outline,
                      uiScale: uiScale,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) {
                          return 'Enter your email or phone number';
                        }
                        final emailRegExp = RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        );
                        if (!emailRegExp.hasMatch(value)) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                SizedBox(height: 14 * uiScale),

                // Password field
                FadeTransition(
                  opacity: _fieldFade(0.44, 0.74),
                  child: SlideTransition(
                    position: _fieldSlide(0.44, 0.78),
                    child: _AuthTextField(
                      controller: passwordCtrl,
                      hint: 'Password',
                      icon: Icons.lock_outline,
                      uiScale: uiScale,
                      obscureText: obscure,
                      validator: (v) {
                        final value = v ?? '';
                        if (value.isEmpty) {
                          return 'Enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                      suffix: IconButton(
                        onPressed: onToggleObscure,
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            key: ValueKey(obscure),
                            color: const Color(0xFF9A96A8),
                            size: 20 * uiScale,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8 * uiScale),

                FadeTransition(
                  opacity: _fieldFade(0.5, 0.78),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onForgotPassword,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(10, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: 13 * uiScale,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6C4EF5),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12 * uiScale),

                // ── API/network error message ─────────────────────────────
                if (errorMessage != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 12 * uiScale),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 14 * uiScale,
                        vertical: 10 * uiScale,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFECEE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE0525C).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: const Color(0xFFE0525C),
                            size: 16 * uiScale,
                          ),
                          SizedBox(width: 8 * uiScale),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: TextStyle(
                                fontSize: 12.5 * uiScale,
                                color: const Color(0xFFB02030),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                FadeTransition(
                  opacity: _fieldFade(0.55, 0.85),
                  child: SlideTransition(
                    position: _fieldSlide(0.55, 0.9),
                    child: _LoginButton(
                      loading: loading,
                      uiScale: uiScale,
                      onTap: onSubmit,
                    ),
                  ),
                ),
                SizedBox(height: 20 * uiScale),


                FadeTransition(
                  opacity: _fieldFade(0.6, 0.9),
                  child: Row(
                    children: [
                      const Expanded(child: Divider(color: Color(0xFFE2DEF0))),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10 * uiScale,
                        ),
                        child: Text(
                          'or continue with',
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
                  opacity: _fieldFade(0.65, 0.95),
                  child: SlideTransition(
                    position: _fieldSlide(0.65, 1.0),
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
                  opacity: _fieldFade(0.7, 1.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          fontSize: 13 * uiScale,
                          color: const Color(0xFF6B6B7B),
                        ),
                      ),
                      GestureDetector(
                        onTap: onSignUpTap,
                        child: Text(
                          'Sign Up',
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
                SizedBox(height: 12 * uiScale),

                FadeTransition(
                  opacity: _fieldFade(0.75, 1.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 14 * uiScale,
                        color: const Color(0xFF1E8A4C),
                      ),
                      SizedBox(width: 6 * uiScale),
                      Text(
                        'Your data is secure and 100% private',
                        style: TextStyle(
                          fontSize: 11.5 * uiScale,
                          color: const Color(0xFF6B6B7B),
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
    );
  }
}

// ---------------------------------------------------------------------------
// Styled text field with animated focus border
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
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final double uiScale;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;

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
          color: _focused
              ? const Color(0xFF6C4EF5)
              : const Color(0xFFE4E0F2),
          width: _focused ? 1.6 : 1.2,
        ),
        color: Colors.white.withValues(alpha: 0.9),
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
        style: TextStyle(fontSize: 14.5 * widget.uiScale),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: const Color(0xFFB0ACC2),
            fontSize: 14.5 * widget.uiScale,
          ),
          prefixIcon: Icon(
            widget.icon,
            color: const Color(0xFF6C4EF5),
            size: 20 * widget.uiScale,
          ),
          suffixIcon: widget.suffix,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: 16 * widget.uiScale,
            horizontal: 4,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gradient Login button with press + loading animation
// ---------------------------------------------------------------------------
class _LoginButton extends StatefulWidget {
  const _LoginButton({
    required this.loading,
    required this.uiScale,
    required this.onTap,
  });

  final bool loading;
  final double uiScale;
  final Future<void> Function() onTap;

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton> {
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
                        'Login',
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

// ---------------------------------------------------------------------------
// Social login button
// ---------------------------------------------------------------------------
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

/// Segmented Google "G" mark without requiring a bundled brand asset.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _GoogleGlyphPainter(),
      ),
    );
  }
}

class _GoogleGlyphPainter extends CustomPainter {
  const _GoogleGlyphPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.36;
    final bounds = Rect.fromCircle(center: center, radius: radius);
    final strokeWidth = size.width * 0.22;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(bounds, -math.pi, math.pi / 2, false, paint);
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(bounds, math.pi / 2, math.pi / 2, false, paint);
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(bounds, 0, math.pi / 2, false, paint);
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(bounds, -math.pi / 2, math.pi / 4, false, paint);

    paint.color = const Color(0xFF4285F4);
    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(size.width * 0.84, center.dy),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleGlyphPainter oldDelegate) => false;
}
