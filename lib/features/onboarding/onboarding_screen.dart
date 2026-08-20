import 'dart:math' as math;

import 'package:flutter/material.dart';


/// DietCompass — Onboarding
/// -----------------------------------------------------------------------
/// A 3-page onboarding flow built directly on the supplied reference
/// illustrations (used exactly as provided, only cropped to drop the
/// baked-in page dots so a real, dynamic dot indicator can drive them):
///   • assets/images/illus_scan.png   — "Scan. Analyze. Eat Better."
///   • assets/images/illus_ai.png     — "AI Guidance, Just for You"
///   • assets/images/illus_track.png  — "Track. Improve. Live Healthier."
///
/// Tapping "Next" advances the PageView; on the final page the button
/// becomes "Get Started" and calls [onComplete]. "Skip" jumps straight to
/// [onComplete] as well (standard onboarding convention) — pass [onSkip]
/// if you'd rather it jump to the last page instead.
///
/// Add to pubspec.yaml:
/// ```yaml
/// flutter:
///   assets:
///     - assets/images/illus_scan.png
///     - assets/images/illus_ai.png
///     - assets/images/illus_track.png
/// ```
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete, this.onSkip});

  /// Called when the user finishes the last page (or taps Skip, unless
  /// [onSkip] is provided).
  final VoidCallback onComplete;

  /// Optional custom Skip behavior. Defaults to [onComplete].
  final VoidCallback? onSkip;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _entranceCtrl;
  late final AnimationController _floatCtrl;

  int _page = 0;
  double _pageOffset = 0;

  static final List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      asset: 'assets/images/illus_scan.png',
      imageAspect: 900 / 1280,
      headline: const [
        TextSpan(text: 'Scan. Analyze.\n'),
        TextSpan(
          text: 'Eat Better.',
          style: TextStyle(color: Color(0xFF1E8A4C)),
        ),
      ],
      subtitle: 'Scan any food label or product and get instant '
          'AI-powered nutrition insights you can trust.',
      buttonLabel: 'Next',
    ),
    _OnboardingPageData(
      asset: 'assets/images/illus_ai.png',
      imageAspect: 840 / 1280,
      headline: const [
        TextSpan(text: 'AI Guidance\n'),
        TextSpan(
          text: 'Just for You',
          style: TextStyle(color: Color(0xFF6C4EF5)),
        ),
      ],
      subtitle: 'Get personalized recommendations, healthier '
          'alternatives, and meal ideas tailored to your goals '
          'and preferences.',
      buttonLabel: 'Next',
    ),
    _OnboardingPageData(
      asset: 'assets/images/illus_track.png',
      imageAspect: 740 / 1360,
      headline: const [
        TextSpan(text: 'Track. Improve.\n'),
        TextSpan(
          text: 'Live Healthier.',
          style: TextStyle(color: Color(0xFF1E8A4C)),
        ),
      ],
      subtitle: 'Track your nutrition, monitor progress, and build '
          'better habits for a healthier, happier you.',
      buttonLabel: 'Get Started',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController()..addListener(_onScroll);

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entranceCtrl.forward(from: 0);
    });
  }

  void _onScroll() {
    if (!_pageController.hasClients) return;
    final page = _pageController.page;
    if (page != null) {
      setState(() => _pageOffset = page);
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    _entranceCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
    );
  }

  void _handlePrimaryButton() {
    if (_page == _pages.length - 1) {
      widget.onComplete();
    } else {
      _goToPage(_page + 1);
    }
  }

  void _handleSkip() {
    if (widget.onSkip != null) {
      widget.onSkip!();
    } else {
      widget.onComplete();
    }
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 390).clamp(0.85, 1.25);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F3FC),
      body: Stack(
        children: [
          // Page content
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (i) {
              setState(() => _page = i);
              _entranceCtrl.forward(from: 0);
            },
            itemBuilder: (context, index) {
              final parallax = (_pageOffset - index).clamp(-1.0, 1.0);
              return _OnboardingPage(
                data: _pages[index],
                isActive: index == _page,
                entranceCtrl: _entranceCtrl,
                floatCtrl: _floatCtrl,
                parallax: parallax,
                uiScale: scale,
              );
            },
          ),

          // Skip button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 20 * scale,
            child: _SkipButton(onTap: _handleSkip),
          ),

          // Bottom controls: dots + primary button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  28 * scale,
                  0,
                  28 * scale,
                  22 * scale,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DotsIndicator(
                      count: _pages.length,
                      pageOffset: _pageOffset,
                      uiScale: scale,
                    ),
                    SizedBox(height: 20 * scale),
                    _PrimaryButton(
                      label: _pages[_page].buttonLabel,
                      onTap: _handlePrimaryButton,
                      uiScale: scale,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.asset,
    required this.imageAspect,
    required this.headline,
    required this.subtitle,
    required this.buttonLabel,
  });

  final String asset;
  final double imageAspect; // width / height
  final List<TextSpan> headline;
  final String subtitle;
  final String buttonLabel;
}

// ---------------------------------------------------------------------------
// A single onboarding page: illustration + headline + subtitle, staggered
// entrance animation, gentle idle float, and subtle horizontal parallax
// driven by the PageView's scroll offset.
// ---------------------------------------------------------------------------
class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.data,
    required this.isActive,
    required this.entranceCtrl,
    required this.floatCtrl,
    required this.parallax,
    required this.uiScale,
  });

  final _OnboardingPageData data;
  final bool isActive;
  final AnimationController entranceCtrl;
  final AnimationController floatCtrl;
  final double parallax; // -1..1, 0 when centered
  final double uiScale;

  @override
  Widget build(BuildContext context) {
    final imageFade = isActive
        ? CurvedAnimation(
            parent: entranceCtrl,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
          )
        : const AlwaysStoppedAnimation(1.0);
    final imageScale = isActive
        ? Tween<double>(begin: 0.92, end: 1.0).animate(
            CurvedAnimation(
              parent: entranceCtrl,
              curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
            ),
          )
        : const AlwaysStoppedAnimation(1.0);
    final textFade = isActive
        ? CurvedAnimation(
            parent: entranceCtrl,
            curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
          )
        : const AlwaysStoppedAnimation(1.0);
    final textSlide = isActive
        ? Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
            .animate(
            CurvedAnimation(
              parent: entranceCtrl,
              curve: const Interval(0.35, 0.9, curve: Curves.easeOutCubic),
            ),
          )
        : const AlwaysStoppedAnimation(Offset.zero);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF4F1FC), Color(0xFFF7F5FC)],
        ),
      ),
      child: Stack(
        children: [
          // faint corner decorations, consistent with the rest of the app
          Positioned(
            top: 60,
            left: 16,
            child: Opacity(
              opacity: 0.22,
              child: CustomPaint(
                size: const Size(70, 70),
                painter: _DotGridPainter(),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Opacity(
              opacity: 0.16,
              child: CustomPaint(
                size: const Size(140, 140),
                painter: _ArcLinesPainter(),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(top: 56 * uiScale),
              child: Column(
                children: [
                  // Illustration — fade/scale entrance + idle float +
                  // parallax drift as adjacent pages are dragged into view.
                  Expanded(
                    child: FadeTransition(
                      opacity: imageFade,
                      child: ScaleTransition(
                        scale: imageScale,
                        child: AnimatedBuilder(
                          animation: floatCtrl,
                          builder: (context, child) {
                            final bob =
                                math.sin(floatCtrl.value * math.pi) *
                                    6 *
                                    uiScale;
                            return Transform.translate(
                              offset: Offset(parallax * -28 * uiScale, -bob),
                              child: child,
                            );
                          },
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: data.imageAspect,
                              child: Image.asset(
                                data.asset,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Headline + subtitle
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      28 * uiScale,
                      0,
                      28 * uiScale,
                      150 * uiScale, // leaves room for dots + button overlay
                    ),
                    child: FadeTransition(
                      opacity: textFade,
                      child: SlideTransition(
                        position: textSlide,
                        child: Column(
                          children: [
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 26 * uiScale,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                  color: const Color(0xFF1B1B2E),
                                  fontFamily: 'Roboto',
                                ),
                                children: data.headline,
                              ),
                            ),
                            SizedBox(height: 12 * uiScale),
                            Text(
                              data.subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14 * uiScale,
                                color: const Color(0xFF6B6B7B),
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
// Skip button
// ---------------------------------------------------------------------------
class _SkipButton extends StatefulWidget {
  const _SkipButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_SkipButton> createState() => _SkipButtonState();
}

class _SkipButtonState extends State<_SkipButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.92),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            'Skip',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6C4EF5).withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dot page indicator — smoothly interpolates width/color with scroll offset
// ---------------------------------------------------------------------------
class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({
    required this.count,
    required this.pageOffset,
    required this.uiScale,
  });

  final int count;
  final double pageOffset;
  final double uiScale;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final dist = (pageOffset - i).abs().clamp(0.0, 1.0);
        final active = 1 - dist;
        final width = lerpDouble(8, 24, active) * uiScale;
        final color = Color.lerp(
          const Color(0xFFD9D2F0),
          const Color(0xFF6C4EF5),
          active,
        )!;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: EdgeInsets.symmetric(horizontal: 4 * uiScale),
          height: 8 * uiScale,
          width: width,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }

  double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

// ---------------------------------------------------------------------------
// Primary pill button (Next / Get Started) with press animation
// ---------------------------------------------------------------------------
class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({
    required this.label,
    required this.onTap,
    required this.uiScale,
  });

  final String label;
  final VoidCallback onTap;
  final double uiScale;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          width: double.infinity,
          height: 56 * widget.uiScale,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [Color(0xFF7C5CFC), Color(0xFF5B3FE0)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C4EF5).withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  widget.label,
                  key: ValueKey(widget.label),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16 * widget.uiScale,
                    fontWeight: FontWeight.w700,
                  ),
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
    );
  }
}

// ---------------------------------------------------------------------------
// Shared decorative painters (match the splash screen's corner accents)
// ---------------------------------------------------------------------------
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF7C5CFC);
    const spacing = 10.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ArcLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF7C5CFC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int i = 0; i < 4; i++) {
      final r = 20.0 + i * 22;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(size.width, 0), radius: r),
        math.pi / 2,
        math.pi / 2,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
