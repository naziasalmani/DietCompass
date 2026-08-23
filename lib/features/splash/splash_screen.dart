import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/// DietCompass — Splash Screen
/// -----------------------------------------------------------------------
/// Built directly on top of the two supplied design images:
///   • assets/images/bg_robot.png    — full background art: gradient,
///     floating food chips, leaves and the AI robot mascot.
///   • assets/images/logo_header.png — compass logo + "DietCompass"
///     wordmark + tagline + "AI-Powered Nutrition Assistant" badge,
///     pre-processed with a soft bottom fade so it blends seamlessly
///     into bg_robot.png below it.
///
/// Nothing here is redrawn or redesigned — both images are used exactly
/// as provided. Everything else (the glowing pulse behind the robot, the
/// shimmering progress bar, sparkle twinkles, the glassmorphism card and
/// all entrance/looping animation) is layered on top with Flutter so the
/// static art becomes a living, premium splash sequence.
///
/// Add to pubspec.yaml:
/// ```yaml
/// flutter:
///   assets:
///     - assets/images/bg_robot.png
///     - assets/images/logo_header.png
/// ```
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.onFinished,
    this.errorMessage,
    this.onRetry,
    this.statusMessage = 'Preparing your personalized experience...',
  });

  final VoidCallback? onFinished;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String statusMessage;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // One-shot entrance choreography.
  late final AnimationController _entranceCtrl;

  // Continuous ambient loops.
  late final AnimationController _breatheCtrl; // whole-art float/breathe
  late final AnimationController _glowCtrl; // pulsing glow behind robot
  late final AnimationController _sweepCtrl; // slow diagonal light sweep
  late final AnimationController _sparkleCtrl; // twinkling sparkles
  late final AnimationController _progressCtrl; // loading bar fill

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..forward();

    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _sweepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _sparkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _logoFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _cardFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _progressCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFinished?.call();
      }
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _breatheCtrl.dispose();
    _glowCtrl.dispose();
    _sweepCtrl.dispose();
    _sparkleCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final scale = (screenSize.shortestSide / 390).clamp(0.8, 1.3);

    return Scaffold(
      backgroundColor: const Color(0xFFEDE7FA),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ---- Layer 1: the real background + robot artwork ----
          // A slow, subtle scale/translate "breathing" loop brings the
          // static illustration to life (the robot, food chips and
          // leaves all move together as one living scene).
          AnimatedBuilder(
            animation: _breatheCtrl,
            builder: (context, child) {
              final t = Curves.easeInOut.transform(_breatheCtrl.value);
              final scaleAmt = 1.0 + t * 0.02;
              final dy = t * 6;
              return Transform.translate(
                offset: Offset(0, -dy),
                child: Transform.scale(scale: scaleAmt, child: child),
              );
            },
            child: Image.asset(
              'assets/images/bg_robot.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // ---- Layer 2: soft pulsing glow behind the robot ----
          // Robot sits roughly at the horizontal/vertical center of the
          // artwork's upper-mid section — glow is aligned to that spot.
          AnimatedBuilder(
            animation: _glowCtrl,
            builder: (context, _) {
              final g = _glowCtrl.value;
              return Align(
                alignment: const Alignment(0, -0.18),
                child: Container(
                  width: screenSize.width * (0.72 + g * 0.08),
                  height: screenSize.width * (0.72 + g * 0.08),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.22 + g * 0.10),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // ---- Layer 3: slow diagonal light sweep for premium sheen ----
          AnimatedBuilder(
            animation: _sweepCtrl,
            builder: (context, _) {
              final t = _sweepCtrl.value;
              return IgnorePointer(
                child: Opacity(
                  opacity: 0.5,
                  child: ShaderMask(
                    blendMode: BlendMode.softLight,
                    shaderCallback: (rect) {
                      return LinearGradient(
                        begin: Alignment(-1.6 + t * 3.2, -1),
                        end: Alignment(-0.6 + t * 3.2, 1),
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.55),
                          Colors.transparent,
                        ],
                        stops: const [0.35, 0.5, 0.65],
                      ).createShader(rect);
                    },
                    child: Container(color: Colors.white.withValues(alpha: 0.001)),
                  ),
                ),
              );
            },
          ),

          // ---- Layer 4: twinkling sparkles over the scene ----
          _SparkleField(controller: _sparkleCtrl),

          // ---- Layer 5: UI chrome (logo, glass card, progress bar / error) ----
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                SizedBox(height: 8 * scale),
                // Logo header image — fades + scales in on launch.
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    alignment: Alignment.topCenter,
                    child: Image.asset(
                      'assets/images/logo_header.png',
                      width: screenSize.width,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                ),
                const Spacer(),
                if (widget.errorMessage != null) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                    child: _ErrorCard(
                      message: widget.errorMessage!,
                      onRetry: widget.onRetry ?? () {},
                      uiScale: scale,
                    ),
                  ),
                  SizedBox(height: 28 * scale),
                ] else ...[
                  // Glassmorphism info card.
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                    child: FadeTransition(
                      opacity: _cardFade,
                      child: SlideTransition(
                        position: _cardSlide,
                        child: _GlassCard(uiScale: scale),
                      ),
                    ),
                  ),
                  SizedBox(height: 18 * scale),
                  Padding(
                    padding: EdgeInsets.only(bottom: 28 * scale),
                    child: _ProgressSection(
                      controller: _progressCtrl,
                      uiScale: scale,
                      statusMessage: widget.statusMessage,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sparkles overlay
// ---------------------------------------------------------------------------
class _SparkleField extends StatelessWidget {
  const _SparkleField({required this.controller});
  final AnimationController controller;

  static const _positions = [
    Offset(0.84, 0.14),
    Offset(0.1, 0.24),
    Offset(0.88, 0.36),
    Offset(0.09, 0.5),
    Offset(0.8, 0.58),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return IgnorePointer(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return Stack(
                children: List.generate(_positions.length, (i) {
                  final phase =
                      (controller.value + i / _positions.length) % 1;
                  final opacity = (math.sin(phase * math.pi * 2) + 1) / 2;
                  final pos = _positions[i];
                  return Positioned(
                    left: constraints.maxWidth * pos.dx,
                    top: constraints.maxHeight * pos.dy,
                    child: Opacity(
                      opacity: 0.2 + opacity * 0.6,
                      child: Icon(
                        Icons.auto_awesome,
                        size: 10 + opacity * 5,
                        color: Colors.white,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Glassmorphism card ("Better Choices, Better You.")
// ---------------------------------------------------------------------------
class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.uiScale});
  final double uiScale;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.all(16 * uiScale),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40 * uiScale,
                height: 40 * uiScale,
                decoration: const BoxDecoration(
                  color: Color(0xFFEDE7FA),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite,
                  color: const Color(0xFF6C4EF5),
                  size: 18 * uiScale,
                ),
              ),
              SizedBox(width: 12 * uiScale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 15.5 * uiScale,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1B1B2E),
                        ),
                        children: const [
                          TextSpan(text: 'Better Choices, '),
                          TextSpan(
                            text: 'Better You.',
                            style: TextStyle(color: Color(0xFF6C4EF5)),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 4 * uiScale),
                    Text(
                      'Make smarter food choices with AI insights '
                      'tailored just for you.',
                      style: TextStyle(
                        fontSize: 12.5 * uiScale,
                        color: const Color(0xFF5B5B6B),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error Card ("Unable to initialize DietCompass")
// ---------------------------------------------------------------------------
class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
    required this.uiScale,
  });

  final String message;
  final VoidCallback onRetry;
  final double uiScale;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.all(20 * uiScale),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44 * uiScale,
                height: 44 * uiScale,
                decoration: const BoxDecoration(
                  color: Color(0xFFFDE8E8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_off_rounded,
                  color: const Color(0xFFE0525C),
                  size: 22 * uiScale,
                ),
              ),
              SizedBox(height: 12 * uiScale),
              Text(
                'Unable to initialize DietCompass',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16 * uiScale,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1B1B2E),
                ),
              ),
              SizedBox(height: 6 * uiScale),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13 * uiScale,
                  color: const Color(0xFF5B5B6B),
                  height: 1.35,
                ),
              ),
              SizedBox(height: 16 * uiScale),
              SizedBox(
                width: double.infinity,
                height: 46 * uiScale,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                  label: Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 14 * uiScale,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C4EF5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Progress bar with shimmering gradient fill
// ---------------------------------------------------------------------------
class _ProgressSection extends StatelessWidget {
  const _ProgressSection({
    required this.controller,
    required this.uiScale,
    this.statusMessage = 'Preparing your personalized experience...',
  });
  final AnimationController controller;
  final double uiScale;
  final String statusMessage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40 * uiScale),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 6 * uiScale,
              color: Colors.white.withValues(alpha: 0.45),
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: controller.value,
                      child: const _ShimmerBar(),
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 10 * uiScale),
          Text(
            statusMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5 * uiScale,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6C4EF5),
              shadows: const [
                Shadow(color: Colors.white, blurRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBar extends StatefulWidget {
  const _ShimmerBar();

  @override
  State<_ShimmerBar> createState() => _ShimmerBarState();
}

class _ShimmerBarState extends State<_ShimmerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (context, _) {
        return ShaderMask(
          shaderCallback: (rect) {
            final sweep = _shimmerCtrl.value;
            return LinearGradient(
              begin: Alignment(-1.5 + sweep * 3, 0),
              end: Alignment(-0.5 + sweep * 3, 0),
              colors: const [
                Color(0xFF6C4EF5),
                Colors.white,
                Color(0xFF1E8A4C),
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C4EF5), Color(0xFF1E8A4C)],
              ),
            ),
          ),
        );
      },
    );
  }
}
