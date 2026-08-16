import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import '../home/home_screen.dart';

/// DietCompass — AI Nutrition Coach Screen
/// -----------------------------------------------------------------------
/// Matches the visual language of ScanScreen / ManualEntryScreen /
/// ProfileScreen: lavender background (0xFFF3F0FB), purple → green brand
/// accents, frosted glassmorphism cards, staggered entrance choreography
/// and playful micro-animations (bobbing robot, typing-dots bubble,
/// twinkling sparkles, animated stat count-ups, press-scale everywhere).
///
/// Drop your own images in under assets/images/ — every Image.asset call
/// has an errorBuilder fallback icon so the screen still renders correctly
/// even before the real art is wired in:
///   • assets/images/ai_robot_coach.png     (hero robot + bowl + plant)
///   • assets/images/icon_ai_avatar.png     (small header avatar)
///   • assets/images/img_high_fiber_meals.png
///   • assets/images/img_hydration_tips.png
///   • assets/images/img_protein_snacks.png
///
/// Add to pubspec.yaml:
/// ```yaml
/// flutter:
///   assets:
///     - assets/images/ai_robot_coach.png
///     - assets/images/icon_ai_avatar.png
///     - assets/images/img_high_fiber_meals.png
///     - assets/images/img_hydration_tips.png
///     - assets/images/img_protein_snacks.png
/// ```
class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({
    super.key,
    this.userName = 'Nazia',
    this.caloriesConsumed = 1420,
    this.caloriesGoal = 1800,
    this.fiberConsumed = 22,
    this.fiberGoal = 30,
    this.glassesConsumed = 6,
    this.glassesGoal = 8,
    this.onBack,
    this.onAvatarTap,
    this.onStartConversationTap,
    this.onCategoryTap,
    this.onRecommendedTap,
    this.onSend,
  });

  final String userName;
  final int caloriesConsumed;
  final int caloriesGoal;
  final int fiberConsumed;
  final int fiberGoal;
  final int glassesConsumed;
  final int glassesGoal;

  final VoidCallback? onBack;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onStartConversationTap;
  final ValueChanged<String>? onCategoryTap;
  final ValueChanged<String>? onRecommendedTap;
  final ValueChanged<String>? onSend;

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _ambientCtrl;
  late final AnimationController _dotsCtrl;
  final _inputCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _ambientCtrl.dispose();
    _dotsCtrl.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }

  Animation<double> _fade(double s, double e) => CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(s, e, curve: Curves.easeOut),
      );

  Animation<Offset> _slide(double s, double e) => Tween<Offset>(
        begin: const Offset(0, 0.12),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _entranceCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic),
        ),
      );

  void _handleSend() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    widget.onSend?.call(text);
    _inputCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 390).clamp(0.85, 1.25);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FB),
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _GlassBackdrop(uiScale: scale, ambientCtrl: _ambientCtrl),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      18 * scale,
                      8 * scale,
                      18 * scale,
                      16 * scale,
                    ),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      FadeTransition(
                        opacity: _fade(0.0, 0.26),
                        child: SlideTransition(
                          position: _slide(0.0, 0.3),
                          child: _TopHeader(
                            uiScale: scale,
                            ambientCtrl: _ambientCtrl,
                            onBack: () {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => HomeScreen(),
    ),
  );
},
                            onAvatarTap: widget.onAvatarTap,
                          ),
                        ),
                      ),
                      SizedBox(height: 14 * scale),

                      FadeTransition(
                        opacity: _fade(0.05, 0.36),
                        child: SlideTransition(
                          position: _slide(0.05, 0.4),
                          child: _HeroCard(
                            uiScale: scale,
                            ambientCtrl: _ambientCtrl,
                            dotsCtrl: _dotsCtrl,
                            userName: widget.userName,
                            onStartConversationTap: widget.onStartConversationTap,
                          ),
                        ),
                      ),
                      SizedBox(height: 16 * scale),

                      FadeTransition(
                        opacity: _fade(0.16, 0.46),
                        child: SlideTransition(
                          position: _slide(0.16, 0.5),
                          child: _GlassCard(
                            uiScale: scale,
                            child: _AskMeAboutSection(
                              uiScale: scale,
                              onCategoryTap: widget.onCategoryTap,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16 * scale),

                      FadeTransition(
                        opacity: _fade(0.24, 0.54),
                        child: SlideTransition(
                          position: _slide(0.24, 0.58),
                          child: _TodaysInsightsCard(
                            uiScale: scale,
                            caloriesConsumed: widget.caloriesConsumed,
                            caloriesGoal: widget.caloriesGoal,
                            fiberConsumed: widget.fiberConsumed,
                            fiberGoal: widget.fiberGoal,
                            glassesConsumed: widget.glassesConsumed,
                            glassesGoal: widget.glassesGoal,
                          ),
                        ),
                      ),
                      SizedBox(height: 20 * scale),

                      FadeTransition(
                        opacity: _fade(0.3, 0.58),
                        child: SlideTransition(
                          position: _slide(0.3, 0.62),
                          child: Text(
                            'Recommended for You',
                            style: TextStyle(
                              fontSize: 15.5 * scale,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1B1B2E),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12 * scale),

                      FadeTransition(
                        opacity: _fade(0.34, 0.64),
                        child: SlideTransition(
                          position: _slide(0.34, 0.68),
                          child: _RecommendedSection(
                            uiScale: scale,
                            onRecommendedTap: widget.onRecommendedTap,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                FadeTransition(
                  opacity: _fade(0.5, 0.8),
                  child: SlideTransition(
                    position: _slide(0.5, 0.84),
                    child: _ComposeBar(
                      uiScale: scale,
                      controller: _inputCtrl,
                      onSend: _handleSend,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ambient glass backdrop — soft blurred colour blobs + faint dotted texture
// ---------------------------------------------------------------------------
class _GlassBackdrop extends StatelessWidget {
  const _GlassBackdrop({required this.uiScale, required this.ambientCtrl});
  final double uiScale;
  final AnimationController ambientCtrl;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ambientCtrl,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(ambientCtrl.value);
        return Stack(
          fit: StackFit.expand,
          children: [
            Container(color: const Color(0xFFF3F0FB)),
            Positioned(
              top: 0,
              left: 0,
              child: Opacity(
                opacity: 0.5,
                child: CustomPaint(
                  size: Size(160 * uiScale, 160 * uiScale),
                  painter: _DotGridPainter(color: const Color(0xFF6C4EF5)),
                ),
              ),
            ),
            Positioned(
              top: 30 * uiScale,
              right: -6 * uiScale,
              child: Opacity(
                opacity: 0.18,
                child: Transform.rotate(
                  angle: 0.5,
                  child: Icon(Icons.eco_rounded, size: 90 * uiScale, color: const Color(0xFF6C4EF5)),
                ),
              ),
            ),
            Positioned(
              bottom: 120 * uiScale - t * 10,
              left: -50,
              child: _blob(200 * uiScale, const Color(0xFF6C4EF5)),
            ),
            Positioned(
              bottom: -60 + t * 12,
              right: -60,
              child: _blob(170 * uiScale, const Color(0xFF1E8A4C)),
            ),
          ],
        );
      },
    );
  }

  Widget _blob(double size, Color color) => ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.16),
            ),
          ),
        ),
      );
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.18);
    const spacing = 14.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        final fade = 1 - (math.sqrt(x * x + y * y) / (size.width * 1.2));
        if (fade <= 0) continue;
        paint.color = color.withValues(alpha: 0.16 * fade.clamp(0, 1));
        canvas.drawCircle(Offset(x, y), 1.6, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Reusable frosted glassmorphism card (light, over the lavender backdrop)
// ---------------------------------------------------------------------------
class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.uiScale,
    required this.child,
    this.padding,
    this.color,
    this.borderColor,
  });
  final double uiScale;
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
  borderRadius: BorderRadius.circular(24),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
    child: Container(
      padding: padding ?? EdgeInsets.all(16 * uiScale),
      decoration: BoxDecoration(
        color: (color ?? Colors.white)
            .withValues(alpha: color == null ? 0.62 : 0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.75),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C4EF5).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    ),
  ),
);
  }
}

// ---------------------------------------------------------------------------
// Generic press-scale wrapper
// ---------------------------------------------------------------------------
class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, this.onTap, this.minScale = 0.94});
  final Widget child;
  final VoidCallback? onTap;
  final double minScale;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _scale = widget.minScale),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _scale = 1.0),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top header — back button, title, small AI avatar
// ---------------------------------------------------------------------------
class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.uiScale,
    required this.ambientCtrl,
    this.onBack,
    this.onAvatarTap,
  });
  final double uiScale;
  final AnimationController ambientCtrl;
  final VoidCallback? onBack;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Pressable(
          onTap: onBack ?? () => Navigator.maybePop(context),
          child: Container(
            width: 42 * uiScale,
            height: 42 * uiScale,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.arrow_back_rounded, size: 19 * uiScale, color: const Color(0xFF6C4EF5)),
          ),
        ),
        Expanded(
          child: Text(
            'AI Nutrition Coach',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17.5 * uiScale,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF5233D6),
            ),
          ),
        ),
        _Pressable(
          onTap: onAvatarTap,
          child: AnimatedBuilder(
            animation: ambientCtrl,
            builder: (context, child) {
              final glow = 0.16 + ambientCtrl.value * 0.14;
              return Container(
                width: 42 * uiScale,
                height: 42 * uiScale,
                padding: EdgeInsets.all(2 * uiScale),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C4EF5).withValues(alpha: glow),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Container(
                    color: Colors.transparent,
                    child: Image.asset(
                      'assets/images/icon_ai_avatar.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.smart_toy_rounded,
                        size: 20 * uiScale,
                        color: const Color(0xFF7CF2C0),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Hero card — gradient greeting, robot illustration, typing bubble, CTA
// ---------------------------------------------------------------------------
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.uiScale,
    required this.ambientCtrl,
    required this.dotsCtrl,
    required this.userName,
    this.onStartConversationTap,
  });

  final double uiScale;
  final AnimationController ambientCtrl;
  final AnimationController dotsCtrl;
  final String userName;
  final VoidCallback? onStartConversationTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
  height: 220 * uiScale,
  child: ClipRRect(
    borderRadius: BorderRadius.circular(26),
    child: Stack(
      children: [
        Positioned.fill(
          child: Container(
            padding: EdgeInsets.all(20 * uiScale),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C4EF5), Color(0xFF4A2FD1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Hello $userName! ',
                      style: TextStyle(
                        fontSize: 14 * uiScale,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                    Text('👋', style: TextStyle(fontSize: 14 * uiScale)),
                  ],
                ),
                SizedBox(height: 6 * uiScale),
                SizedBox(
                  width: 190 * uiScale,
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 21 * uiScale,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        color: Colors.white,
                      ),
                      children: const [
                        TextSpan(text: "I'm your "),
                        TextSpan(
                          text: 'AI Nutrition Coach',
                          style: TextStyle(color: Color(0xFF7CF2C0)),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10 * uiScale),
                SizedBox(
                  width: 190 * uiScale,
                  child: Text(
                    'Ask me anything about food, nutrition, diet & your health goals.',
                    style: TextStyle(
                      fontSize: 11.5 * uiScale,
                      height: 1.4,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Twinkling sparkles
        AnimatedBuilder(
          animation: ambientCtrl,
          builder: (context, child) {
            final o1 = (math.sin(ambientCtrl.value * math.pi * 2) + 1) / 2;
            final o2 = (math.cos(ambientCtrl.value * math.pi * 2) + 1) / 2;

            return Stack(
              children: [
                Positioned(
                  top: 40 * uiScale,
                  right: 96 * uiScale,
                  child: Opacity(
                    opacity: 0.4 + o1 * 0.5,
                    child: Icon(
                      Icons.auto_awesome,
                      size: 12 * uiScale,
                      color: Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  top: 96 * uiScale,
                  right: 60 * uiScale,
                  child: Opacity(
                    opacity: 0.4 + o2 * 0.5,
                    child: Icon(
                      Icons.auto_awesome,
                      size: 9 * uiScale,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        Positioned(
          right: -12 * uiScale,
          top: -14 * uiScale,
          child: Opacity(
            opacity: 0.14,
            child: Transform.rotate(
              angle: 0.4,
              child: Icon(
                Icons.eco_rounded,
                size: 120 * uiScale,
                color: Colors.white,
              ),
            ),
          ),
        ),

        Positioned(
          right: 8 * uiScale,
          bottom: 0,
          child: AnimatedBuilder(
            animation: ambientCtrl,
            builder: (context, child) {
              final bob = math.sin(ambientCtrl.value * math.pi) * 5;
              return Transform.translate(
                offset: Offset(0, -bob),
                child: child,
              );
            },
            child: SizedBox(
              width: 148 * uiScale,
              height: 148 * uiScale,
              child: Image.asset(
                'assets/images/ai_robot_coach.jpeg',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.smart_toy_rounded,
                  size: 96 * uiScale,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),

        Positioned(
  left: 20 * uiScale,
  bottom: 20 * uiScale,
  child: _Pressable(
    onTap: onStartConversationTap,
    child: Container(
      padding: EdgeInsets.symmetric(
        horizontal: 18 * uiScale,
        vertical: 13 * uiScale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Start a Conversation',
            style: TextStyle(
              fontSize: 12.5 * uiScale,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF4A2FD1),
            ),
          ),
          SizedBox(width: 8 * uiScale),
          Icon(
            Icons.arrow_forward_rounded,
            size: 16 * uiScale,
            color: const Color(0xFF4A2FD1),
          ),
        ],
      ),
    ),
  ),
),

        Positioned(
          right: 40 * uiScale,
          top: 60 * uiScale,
          child: _TypingBubble(
            uiScale: uiScale,
            dotsCtrl: dotsCtrl,
          ),
        ),
      ],
    ),
  ),
);
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble({required this.uiScale, required this.dotsCtrl});
  final double uiScale;
  final AnimationController dotsCtrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12 * uiScale, vertical: 9 * uiScale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16 * uiScale),
          topRight: Radius.circular(16 * uiScale),
          bottomLeft: Radius.circular(16 * uiScale),
          bottomRight: Radius.circular(3 * uiScale),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: dotsCtrl,
            builder: (context, child) {
              final phase = (dotsCtrl.value + (i * 0.2)) % 1.0;
              final lift = math.sin(phase * math.pi) * 3;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 1.5 * uiScale),
                child: Transform.translate(
                  offset: Offset(0, -lift),
                  child: Container(
                    width: 5.5 * uiScale,
                    height: 5.5 * uiScale,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6C4EF5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "Ask me about" category grid
// ---------------------------------------------------------------------------
class _AskMeAboutSection extends StatelessWidget {
  const _AskMeAboutSection({required this.uiScale, this.onCategoryTap});
  final double uiScale;
  final ValueChanged<String>? onCategoryTap;

  static const _categories = [
    (icon: Icons.restaurant_rounded, label: 'Diet & Nutrition'),
    (icon: Icons.eco_rounded, label: 'Healthy Recipes'),
    (icon: Icons.monitor_weight_rounded, label: 'Weight Management'),
    (icon: Icons.bolt_rounded, label: 'Energy & Fitness'),
    (icon: Icons.health_and_safety_rounded, label: 'Health Conditions'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ask me about',
          style: TextStyle(
            fontSize: 15 * uiScale,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF5233D6),
          ),
        ),
        SizedBox(height: 14 * uiScale),
        Row(
          children: _categories.map((c) {
            return Expanded(
              child: _Pressable(
                onTap: () => onCategoryTap?.call(c.label),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48 * uiScale,
                      height: 48 * uiScale,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE7FA),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(c.icon, size: 21 * uiScale, color: const Color(0xFF6C4EF5)),
                    ),
                    SizedBox(height: 8 * uiScale),
                    Text(
                      c.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 9.5 * uiScale,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                        color: const Color(0xFF1B1B2E),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Today's Insights card — animated stat count-ups + tip banner
// ---------------------------------------------------------------------------
class _TodaysInsightsCard extends StatelessWidget {
  const _TodaysInsightsCard({
    required this.uiScale,
    required this.caloriesConsumed,
    required this.caloriesGoal,
    required this.fiberConsumed,
    required this.fiberGoal,
    required this.glassesConsumed,
    required this.glassesGoal,
  });

  final double uiScale;
  final int caloriesConsumed;
  final int caloriesGoal;
  final int fiberConsumed;
  final int fiberGoal;
  final int glassesConsumed;
  final int glassesGoal;

  @override
  Widget build(BuildContext context) {
    final remaining = caloriesGoal - caloriesConsumed;
    return _GlassCard(
      uiScale: uiScale,
      color: const Color(0xFFEDE7FA),
      borderColor: const Color(0xFFDCD0F5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 13 * uiScale, color: const Color(0xFF6C4EF5)),
              SizedBox(width: 6 * uiScale),
              Text(
                "Today's Insights",
                style: TextStyle(
                  fontSize: 14.5 * uiScale,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1B1B2E),
                ),
              ),
            ],
          ),
          SizedBox(height: 14 * uiScale),
          Row(
  children: [
    Expanded(
      child: _InsightStat(
        uiScale: uiScale,
        icon: Icons.local_fire_department_rounded,
        iconBg: const Color(0xFFEDE0FB),
        iconColor: const Color(0xFF6C4EF5),
        current: caloriesConsumed,
        goal: caloriesGoal,
        label: 'Calories',
      ),
    ),

    SizedBox(
      height: 36 * uiScale,
      child: VerticalDivider(
        color: const Color(0xFFD9D3F2),
        thickness: 1,
      ),
    ),

    Expanded(
      child: _InsightStat(
        uiScale: uiScale,
        icon: Icons.eco_rounded,
        iconBg: const Color(0xFFE3F5EA),
        iconColor: const Color(0xFF1E8A4C),
        current: fiberConsumed,
        goal: fiberGoal,
        label: 'Fiber',
        unit: 'g',
      ),
    ),

    SizedBox(
      height: 36 * uiScale,
      child: VerticalDivider(
        color: const Color(0xFFD9D3F2),
        thickness: 1,
      ),
    ),

    Expanded(
      child: _InsightStat(
        uiScale: uiScale,
        icon: Icons.water_drop_rounded,
        iconBg: const Color(0xFFE3EEFC),
        iconColor: const Color(0xFF3B82F6),
        current: glassesConsumed,
        goal: glassesGoal,
        label: 'Glasses\nWater',
      ),
    ),
  ],
),
          SizedBox(height: 14 * uiScale),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14 * uiScale, vertical: 12 * uiScale),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDCD0F5)),
            ),
            child: Text(
              remaining > 0
                  ? "Great job! You're $remaining calories away from your daily goal. Keep making healthy choices! 💪"
                  : "Nice work! You've hit your calorie goal for today. 🎉",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5 * uiScale,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3E3357),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightStat extends StatelessWidget {
  const _InsightStat({
    required this.uiScale,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.current,
    required this.goal,
    required this.label,
    this.unit = '',
  });

  final double uiScale;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final int current;
  final int goal;
  final String label;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28 * uiScale,
          height: 28 * uiScale,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, size: 15 * uiScale, color: iconColor),
        ),
        SizedBox(width: 5 * uiScale),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: current),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, val, child) => Text(
                  '$val / $goal$unit',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5 * uiScale,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1B1B2E),
                  ),
                ),
              ),
              Text(
  label,
  textAlign: TextAlign.start,
  style: TextStyle(
    fontSize: 10 * uiScale,
    color: const Color(0xFF6B6B7B),
  ),
),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Recommended for You — horizontal row of tinted content cards
// ---------------------------------------------------------------------------
class _RecommendedItem {
  const _RecommendedItem({
    required this.asset,
    required this.fallbackIcon,
    required this.title,
    required this.subtitle,
    required this.bg,
    required this.accent,
  });
  final String asset;
  final IconData fallbackIcon;
  final String title;
  final String subtitle;
  final Color bg;
  final Color accent;

  static const items = [
    _RecommendedItem(
      asset: 'assets/images/img_high_fiber_meals.jpeg',
      fallbackIcon: Icons.eco_rounded,
      title: 'High Fiber Meals',
      subtitle: 'Boost digestion & keep you full longer.',
      bg: Color(0xFFE3F5EA),
      accent: Color(0xFF1E8A4C),
    ),
    _RecommendedItem(
      asset: 'assets/images/img_hydration_tips.jpeg',
      fallbackIcon: Icons.water_drop_rounded,
      title: 'Hydration Tips',
      subtitle: 'Simple ways to drink more water daily.',
      bg: Color(0xFFFCEEE3),
      accent: Color(0xFFE0862E),
    ),
    _RecommendedItem(
      asset: 'assets/images/img_protein_snacks.jpeg',
      fallbackIcon: Icons.grain_rounded,
      title: 'Protein-Rich Snacks',
      subtitle: 'Healthy snack ideas to fuel your day.',
      bg: Color(0xFFE3EEFC),
      accent: Color(0xFF3B82F6),
    ),
  ];
}

class _RecommendedSection extends StatelessWidget {
  const _RecommendedSection({required this.uiScale, this.onRecommendedTap});
  final double uiScale;
  final ValueChanged<String>? onRecommendedTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190 * uiScale,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _RecommendedItem.items.length,
        separatorBuilder: (_, __) => SizedBox(width: 12 * uiScale),
        itemBuilder: (context, i) {
          final item = _RecommendedItem.items[i];
          return _Pressable(
            onTap: () => onRecommendedTap?.call(item.title),
            child: Container(
              width: 148 * uiScale,
              decoration: BoxDecoration(
                color: item.bg,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.all(8 * uiScale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 76 * uiScale,
                      width: double.infinity,
                      child: Image.asset(
                        item.asset,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: item.accent.withValues(alpha: 0.15),
                          alignment: Alignment.center,
                          child: Icon(item.fallbackIcon, size: 30 * uiScale, color: item.accent),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8 * uiScale),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12 * uiScale,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1B1B2E),
                    ),
                  ),
                  SizedBox(height: 3 * uiScale),
                  Expanded(
                    child: Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5 * uiScale,
                        height: 1.3,
                        color: const Color(0xFF6B6B7B),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 24 * uiScale,
                      height: 24 * uiScale,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(Icons.arrow_forward_rounded, size: 13 * uiScale, color: item.accent),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom compose bar — glass pill text field + gradient send button
// ---------------------------------------------------------------------------
class _ComposeBar extends StatefulWidget {
  const _ComposeBar({required this.uiScale, required this.controller, required this.onSend});
  final double uiScale;
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  State<_ComposeBar> createState() => _ComposeBarState();
}

class _ComposeBarState extends State<_ComposeBar> {
  double _sendScale = 1.0;

  @override
  Widget build(BuildContext context) {
    final uiScale = widget.uiScale;
    return Padding(
      padding: EdgeInsets.fromLTRB(18 * uiScale, 0, 18 * uiScale, 14 * uiScale),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8 * uiScale, vertical: 8 * uiScale),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C4EF5).withValues(alpha: 0.14),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(width: 8 * uiScale),
                Icon(Icons.auto_awesome, size: 15 * uiScale, color: const Color(0xFF6C4EF5)),
                SizedBox(width: 8 * uiScale),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    style: TextStyle(fontSize: 12.5 * uiScale, color: const Color(0xFF1B1B2E)),
                    decoration: InputDecoration(
                      hintText: 'Ask anything about nutrition...',
                      hintStyle: TextStyle(fontSize: 12 * uiScale, color: const Color(0xFFB0ACC2)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12 * uiScale),
                    ),
                    onSubmitted: (_) => widget.onSend(),
                  ),
                ),
                GestureDetector(
                  onTapDown: (_) => setState(() => _sendScale = 0.88),
                  onTapUp: (_) => setState(() => _sendScale = 1.0),
                  onTapCancel: () => setState(() => _sendScale = 1.0),
                  onTap: widget.onSend,
                  child: AnimatedScale(
                    scale: _sendScale,
                    duration: const Duration(milliseconds: 110),
                    child: Container(
                      width: 40 * uiScale,
                      height: 40 * uiScale,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6C4EF5), Color(0xFF4A2FD1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_upward_rounded, size: 18 * uiScale, color: Colors.white),
                    ),
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
