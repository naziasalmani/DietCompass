import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../onboarding/onboarding_screen.dart';
import 'widgets/compass_logo.dart';
import 'widgets/floating_robot_section.dart';
import 'widgets/glass_info_card.dart';
import 'widgets/particles_layer.dart';
import 'widgets/shimmer_loading_bar.dart';
import 'widgets/splash_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _loadingDuration = Duration(milliseconds: 3200);

  late final AnimationController _logoController;
  late final AnimationController _titleController;
  late final AnimationController _taglineController;
  late final AnimationController _badgeController;
  late final AnimationController _heroController;
  late final AnimationController _cardController;
  late final AnimationController _loadingController;
  late final AnimationController _floatController;
  late final AnimationController _orbitController;
  late final AnimationController _particlesController;
  late final AnimationController _shimmerController;
  late final AnimationController _exitController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoRotation;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _taglinePart1;
  late final Animation<double> _taglinePart2;
  late final Animation<double> _badgeOpacity;
  late final Animation<double> _heroOpacity;
  late final Animation<double> _cardOpacity;
  late final Animation<double> _cardSlide;
  late final Animation<double> _loadingOpacity;
  late final Animation<double> _loadingProgress;
  late final Animation<double> _floatOffset;
  late final Animation<double> _exitFade;
  late final Animation<double> _exitScale;

  Timer? _navigationTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _startSequence();
  }

  void _initControllers() {
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _loadingController = AnimationController(
      vsync: this,
      duration: _loadingDuration,
    );
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 18000),
    );
    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_logoController);

    _logoRotation = Tween<double>(begin: -0.12, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOutCubic),
    );

    _taglinePart1 = CurvedAnimation(
      parent: _taglineController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _taglinePart2 = CurvedAnimation(
      parent: _taglineController,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
    );

    _badgeOpacity = CurvedAnimation(
      parent: _badgeController,
      curve: Curves.easeOut,
    );

    _heroOpacity = CurvedAnimation(
      parent: _heroController,
      curve: Curves.easeOut,
    );

    _cardOpacity = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOut,
    );
    _cardSlide = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
    );

    _loadingOpacity = CurvedAnimation(
      parent: _loadingController,
      curve: const Interval(0.0, 0.15, curve: Curves.easeOut),
    );
    _loadingProgress = CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOutCubic,
    );

    _floatOffset = Tween<double>(begin: 6, end: -6).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOut),
    );
    _exitScale = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOut),
    );
  }

  Future<void> _startSequence() async {
    _floatController.repeat(reverse: true);
    _orbitController.repeat();
    _particlesController.repeat();
    _shimmerController.repeat();

    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    unawaited(_logoController.forward());
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;

    unawaited(_titleController.forward());
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;

    unawaited(_taglineController.forward());
    unawaited(_badgeController.forward());
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;

    unawaited(_heroController.forward());
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;

    unawaited(_cardController.forward());
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    unawaited(_loadingController.forward());

    _navigationTimer = Timer(
      _loadingDuration + const Duration(milliseconds: 400),
      _transitionToOnboarding,
    );
  }

  Future<void> _transitionToOnboarding() async {
    if (_navigated || !mounted) return;
    _navigated = true;

    await _exitController.forward();
    if (!mounted) return;

    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 700),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: const OnboardingScreen(),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _logoController.dispose();
    _titleController.dispose();
    _taglineController.dispose();
    _badgeController.dispose();
    _heroController.dispose();
    _cardController.dispose();
    _loadingController.dispose();
    _floatController.dispose();
    _orbitController.dispose();
    _particlesController.dispose();
    _shimmerController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _exitController,
        builder: (context, child) {
          return Opacity(
            opacity: _exitFade.value,
            child: Transform.scale(
              scale: _exitScale.value,
              child: child,
            ),
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            const SplashBackground(),
            ParticlesLayer(animation: _particlesController),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 28),
                  _buildBrandingSection(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: FadeTransition(
                      opacity: _heroOpacity,
                      child: AnimatedBuilder(
                        animation: Listenable.merge([
                          _floatController,
                          _orbitController,
                        ]),
                        builder: (context, _) {
                          return FloatingRobotSection(
                            floatOffset: _floatOffset.value,
                            orbitAngle: _orbitController.value * 6.28318,
                          );
                        },
                      ),
                    ),
                  ),
                  GlassInfoCard(
                    opacity: _cardOpacity.value,
                    slideOffset: _cardSlide.value,
                  ),
                  const SizedBox(height: 28),
                  ShimmerLoadingBar(
                    progress: _loadingProgress.value,
                    shimmerPhase: _shimmerController.value,
                    opacity: _loadingOpacity.value,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandingSection() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _logoController,
          builder: (context, _) {
            return CompassLogo(
              scale: _logoScale.value,
              rotation: _logoRotation.value,
            );
          },
        ),
        const SizedBox(height: 16),
        FadeTransition(
          opacity: _titleOpacity,
          child: SlideTransition(
            position: _titleSlide,
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
                children: const [
                  TextSpan(
                    text: 'Diet',
                    style: TextStyle(color: AppColors.charcoal),
                  ),
                  TextSpan(
                    text: 'Compass',
                    style: TextStyle(color: AppColors.forestGreen),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        AnimatedBuilder(
          animation: _taglineController,
          builder: (context, _) {
            return Column(
              children: [
                Opacity(
                  opacity: _taglinePart1.value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - _taglinePart1.value) * 8),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                        children: const [
                          TextSpan(
                            text: 'Scan. Analyze. ',
                            style: TextStyle(color: AppColors.deepPurple),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Opacity(
                  opacity: _taglinePart2.value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - _taglinePart2.value) * 8),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                        children: const [
                          TextSpan(
                            text: 'Eat Better. ',
                            style: TextStyle(
                              color: AppColors.forestGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: 'Live Healthier.',
                            style: TextStyle(color: AppColors.forestGreen),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        AiBadge(opacity: _badgeOpacity.value),
      ],
    );
  }
}
