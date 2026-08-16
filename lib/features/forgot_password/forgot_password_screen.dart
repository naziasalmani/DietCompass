import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// DietCompass — Forgot Password Screen
/// -----------------------------------------------------------------------
/// Built directly on the supplied images:
///   • assets/images/bg_forgot.png   — background art: gradient, leaves,
///     sparkles, blueberries & avocado.
///   • assets/images/logo_header.png — the same compass logo + wordmark +
///     tagline asset used on the splash/login screens.
///
/// The email field, validation, "Send Reset Link" submission (with a
/// loading state and a post-send resend cooldown) and the 3-step
/// explainer are all real, functional Flutter UI matching the reference.
///
/// Add to pubspec.yaml:
/// ```yaml
/// flutter:
///   assets:
///     - assets/images/bg_forgot.png
///     - assets/images/logo_header.png
/// ```
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    this.onBack,
    this.onSendResetLink,
    this.onLoginTap,
  });

  final VoidCallback? onBack;

  /// Called with the entered email once the form validates. Return/await
  /// your API call here; the button shows a spinner while it runs, then
  /// switches to a "sent" state with a resend cooldown.
  final Future<void> Function(String email)? onSendResetLink;

  final VoidCallback? onLoginTap;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _focusNode = FocusNode();

  late final AnimationController _entranceCtrl;
  late final AnimationController _breatheCtrl;

  bool _loading = false;
  bool _sent = false;
  int _cooldown = 0;
  Timer? _timer;
  bool _focused = false;

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
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _focusNode.dispose();
    _entranceCtrl.dispose();
    _breatheCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldown = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (widget.onSendResetLink == null) return;
    setState(() => _loading = true);
    try {
      await widget.onSendResetLink!(_emailCtrl.text.trim());
      if (!mounted) return;
      setState(() {
        _sent = true;
        _loading = false;
      });
      _startCooldown();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 390).clamp(0.85, 1.25);

    final logoFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    final logoScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );
    final headerFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.2, 0.55, curve: Curves.easeOut),
    );
    final headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    final cardFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
    );
    final cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.35, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    final stepsFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
    );
    final buttonFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
    );
    final buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOutCubic),
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
              'assets/images/bg_forgot.png',
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
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20 * scale,
                      10 * scale,
                      20 * scale,
                      0,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FadeTransition(
                        opacity: logoFade,
                        child: _BackButton(
                          onTap: widget.onBack,
                          uiScale: scale,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 4 * scale),

                  FadeTransition(
                    opacity: logoFade,
                    child: ScaleTransition(
                      scale: logoScale,
                      alignment: Alignment.topCenter,
                      child: Image.asset(
                        'assets/images/logo_header.png',
                        width: size.width * 0.78,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ),
                  SizedBox(height: 8 * scale),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 28 * scale),
                    child: FadeTransition(
                      opacity: headerFade,
                      child: SlideTransition(
                        position: headerSlide,
                        child: Column(
                          children: [
                            Text(
                              'Forgot Password?',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24 * scale,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1B1B2E),
                              ),
                            ),
                            SizedBox(height: 8 * scale),
                            Text(
                              "No worries! Enter your registered email "
                              "address and we'll send you a link to reset "
                              "your password.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.5 * scale,
                                height: 1.4,
                                color: const Color(0xFF6B6B7B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 22 * scale),

                  // Email card
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20 * scale),
                    child: FadeTransition(
                      opacity: cardFade,
                      child: SlideTransition(
                        position: cardSlide,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20 * scale),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.07),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Email Address',
                                  style: TextStyle(
                                    fontSize: 14 * scale,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1B1B2E),
                                  ),
                                ),
                                SizedBox(height: 10 * scale),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _focused
                                          ? const Color(0xFF6C4EF5)
                                          : const Color(0xFFE4E0F2),
                                      width: _focused ? 1.8 : 1.2,
                                    ),
                                    boxShadow: _focused
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF6C4EF5)
                                                  .withValues(alpha: 0.14),
                                              blurRadius: 14,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: TextFormField(
                                    controller: _emailCtrl,
                                    focusNode: _focusNode,
                                    keyboardType:
                                        TextInputType.emailAddress,
                                    style: TextStyle(fontSize: 14.5 * scale),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Enter your email address';
                                      }
                                      if (!v.contains('@')) {
                                        return 'Enter a valid email';
                                      }
                                      return null;
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Enter your email address',
                                      hintStyle: TextStyle(
                                        color: const Color(0xFFB0ACC2),
                                        fontSize: 14 * scale,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.mail_outline,
                                        color: const Color(0xFF6C4EF5),
                                        size: 20 * scale,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 16 * scale,
                                        horizontal: 4,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10 * scale),
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.shield_outlined,
                                      size: 14 * scale,
                                      color: const Color(0xFF1E8A4C),
                                    ),
                                    SizedBox(width: 6 * scale),
                                    Expanded(
                                      child: Text(
                                        "We'll send a password reset link "
                                        "to your email.",
                                        style: TextStyle(
                                          fontSize: 12 * scale,
                                          color: const Color(0xFF6B6B7B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 26 * scale),

                  // How it works
                  FadeTransition(
                    opacity: stepsFade,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20 * scale),
                      child: _HowItWorks(uiScale: scale, ctrl: _entranceCtrl),
                    ),
                  ),
                  SizedBox(height: 26 * scale),

                  // Send button
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20 * scale),
                    child: FadeTransition(
                      opacity: buttonFade,
                      child: SlideTransition(
                        position: buttonSlide,
                        child: _SendButton(
                          uiScale: scale,
                          loading: _loading,
                          sent: _sent,
                          cooldown: _cooldown,
                          onTap: (_sent && _cooldown > 0) ? null : _submit,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16 * scale),

                  FadeTransition(
                    opacity: buttonFade,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 28 * scale),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14 * scale,
                            color: const Color(0xFF6C4EF5),
                          ),
                          SizedBox(width: 6 * scale),
                          Flexible(
                            child: Text(
                              "Didn't receive the email? Check your spam "
                              "folder or wait a few minutes.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12 * scale,
                                color: const Color(0xFF6B6B7B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 18 * scale),
                  FadeTransition(
                    opacity: buttonFade,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40 * scale),
                      child: const Divider(color: Color(0xFFE2DEF0)),
                    ),
                  ),
                  SizedBox(height: 14 * scale),
                  FadeTransition(
                    opacity: buttonFade,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Remember your password? ',
                          style: TextStyle(
                            fontSize: 13 * scale,
                            color: const Color(0xFF6B6B7B),
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onLoginTap,
                          child: Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 13 * scale,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF6C4EF5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24 * scale),
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
// "How it works" 3-step explainer with a dashed connector
// ---------------------------------------------------------------------------
class _HowItWorks extends StatelessWidget {
  const _HowItWorks({required this.uiScale, required this.ctrl});
  final double uiScale;
  final AnimationController ctrl;

  static const _steps = [
    (
      icon: Icons.mark_email_read_outlined,
      title: '1. Enter Email',
      body: 'Enter the email linked\nto your account.',
    ),
    (
      icon: Icons.mark_email_unread_outlined,
      title: '2. Check Inbox',
      body: 'Check your email for\nthe reset link.',
    ),
    (
      icon: Icons.lock_reset,
      title: '3. Reset Password',
      body: 'Click the link and set\na new password.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFFD9D2F0))),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12 * uiScale),
              child: Text(
                'How it works',
                style: TextStyle(
                  fontSize: 13 * uiScale,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1B1B2E),
                ),
              ),
            ),
            const Expanded(child: Divider(color: Color(0xFFD9D2F0))),
          ],
        ),
        SizedBox(height: 18 * uiScale),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(_steps.length * 2 - 1, (i) {
            if (i.isOdd) {
              // dashed connector between two step circles
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 24 * uiScale),
                  child: CustomPaint(
                    size: Size(double.infinity, 2),
                    painter: _DashedLinePainter(),
                  ),
                ),
              );
            }
            final step = _steps[i ~/ 2];
            final start = 0.5 + (i ~/ 2) * 0.1;
            final fade = CurvedAnimation(
              parent: ctrl,
              curve: Interval(
                start.clamp(0.0, 1.0),
                (start + 0.3).clamp(0.0, 1.0),
                curve: Curves.easeOutBack,
              ),
            );
            return ScaleTransition(
              scale: fade,
              child: FadeTransition(
                opacity: fade,
                child: SizedBox(
                  width: 96 * uiScale,
                  child: Column(
                    children: [
                      Container(
                        width: 48 * uiScale,
                        height: 48 * uiScale,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEDE7FA),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          step.icon,
                          color: const Color(0xFF6C4EF5),
                          size: 22 * uiScale,
                        ),
                      ),
                      SizedBox(height: 8 * uiScale),
                      Text(
                        step.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5 * uiScale,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1B1B2E),
                        ),
                      ),
                      SizedBox(height: 3 * uiScale),
                      Text(
                        step.body,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10 * uiScale,
                          height: 1.3,
                          color: const Color(0xFF8B87A0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCFC4EF)
      ..strokeWidth = 1.6;
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Gradient "Send Reset Link" button with loading + sent states
// ---------------------------------------------------------------------------
class _SendButton extends StatefulWidget {
  const _SendButton({
    required this.uiScale,
    required this.loading,
    required this.sent,
    required this.cooldown,
    required this.onTap,
  });

  final double uiScale;
  final bool loading;
  final bool sent;
  final int cooldown;
  final VoidCallback? onTap;

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _scale = 0.97),
      onTapUp: disabled ? null : (_) => setState(() => _scale = 1.0),
      onTapCancel: disabled ? null : () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: AnimatedOpacity(
          opacity: disabled && !widget.loading ? 0.6 : 1.0,
          duration: const Duration(milliseconds: 200),
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
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Row(
                        key: ValueKey('${widget.sent}-${widget.cooldown}'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.sent
                                ? Icons.check_circle_outline
                                : Icons.send_rounded,
                            color: Colors.white,
                            size: 18 * widget.uiScale,
                          ),
                          SizedBox(width: 8 * widget.uiScale),
                          Text(
                            widget.sent
                                ? (widget.cooldown > 0
                                    ? 'Resend in ${widget.cooldown}s'
                                    : 'Resend Link')
                                : 'Send Reset Link',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.5 * widget.uiScale,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
