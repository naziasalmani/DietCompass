import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:diet_compass/features/scan/compare_screen.dart';
import '../home/home_screen.dart';

/// DietCompass — Compare Products Screen
/// -----------------------------------------------------------------------
/// Reuses your existing assets:
///   • assets/images/robot_badge.png       — DietCompass robot (AI banner)
///   • assets/images/product_true_elements.png — Product 1
///   • assets/images/product_quaker.png         — Product 2
///
/// Everything is data-driven via [ComparisonProduct] / [NutrientRow], so
/// this screen can compare any two scanned products from your backend,
/// not just the sample pair used for preview.
///
/// Add to pubspec.yaml (skip any already present):
/// ```yaml
/// flutter:
///   assets:
///     - assets/images/robot_badge.png
///     - assets/images/product_true_elements.png
///     - assets/images/product_quaker.png
/// ```
enum ProductTag { healthyChoice, considerLess }

class ComparisonProduct {
  const ComparisonProduct({
    required this.image,
    required this.name,
    required this.brand,
    required this.tag,
    required this.servingInfo,
    required this.scannedAt,
    required this.score,
    required this.scoreLabel,
  });

  final ImageProvider image;
  final String name;
  final String brand;
  final ProductTag tag;
  final String servingInfo;
  final String scannedAt;
  final int score;
  final String scoreLabel;
}

enum Trend { higherIsBetter, lowerIsBetter, neutral }

class NutrientRow {
  const NutrientRow({
    required this.icon,
    required this.label,
    required this.leftValue40g,
    required this.rightValue40g,
    required this.leftValue100g,
    required this.rightValue100g,
    required this.unit,
    required this.trend,
  });

  final IconData icon;
  final String label;
  final num leftValue40g;
  final num rightValue40g;
  final num leftValue100g;
  final num rightValue100g;
  final String unit;
  final Trend trend;
}

class CompareScreen extends StatefulWidget {
  const CompareScreen({
    super.key,
    this.productA = const ComparisonProduct(
      image: AssetImage('assets/images/product_true_elements.png'),
      name: 'Steel Cut Oats',
      brand: 'True Elements',
      tag: ProductTag.healthyChoice,
      servingInfo: '40 g (1 serving)',
      scannedAt: 'Scanned today, 9:41 AM',
      score: 89,
      scoreLabel: 'Excellent',
    ),
    this.productB = const ComparisonProduct(
      image: AssetImage('assets/images/product_quaker.png'),
      name: 'Quaker Oats',
      brand: 'Quaker',
      tag: ProductTag.considerLess,
      servingInfo: '40 g (1 serving)',
      scannedAt: 'Scanned today, 9:40 AM',
      score: 72,
      scoreLabel: 'Good',
    ),
    this.nutrients = const [
      NutrientRow(icon: Icons.local_fire_department, label: 'Calories', leftValue40g: 150, rightValue40g: 160, leftValue100g: 375, rightValue100g: 400, unit: 'kcal', trend: Trend.lowerIsBetter),
      NutrientRow(icon: Icons.fitness_center, label: 'Protein', leftValue40g: 5.2, rightValue40g: 4.1, leftValue100g: 13.0, rightValue100g: 10.3, unit: 'g', trend: Trend.higherIsBetter),
      NutrientRow(icon: Icons.grain, label: 'Carbohydrates', leftValue40g: 27, rightValue40g: 28, leftValue100g: 67.5, rightValue100g: 70, unit: 'g', trend: Trend.lowerIsBetter),
      NutrientRow(icon: Icons.eco, label: 'Dietary Fiber', leftValue40g: 4.1, rightValue40g: 2.6, leftValue100g: 10.3, rightValue100g: 6.5, unit: 'g', trend: Trend.higherIsBetter),
      NutrientRow(icon: Icons.icecream, label: 'Sugars', leftValue40g: 1.0, rightValue40g: 3.8, leftValue100g: 2.5, rightValue100g: 9.5, unit: 'g', trend: Trend.lowerIsBetter),
      NutrientRow(icon: Icons.opacity, label: 'Total Fat', leftValue40g: 3.0, rightValue40g: 3.2, leftValue100g: 7.5, rightValue100g: 8.0, unit: 'g', trend: Trend.lowerIsBetter),
      NutrientRow(icon: Icons.shield_outlined, label: 'Sodium', leftValue40g: 5, rightValue40g: 120, leftValue100g: 12.5, rightValue100g: 300, unit: 'mg', trend: Trend.lowerIsBetter),
    ],
    this.winnerName = 'Steel Cut Oats',
    this.winnerReason = 'Better nutritional profile',
    this.keyAdvantages = const ['More fiber', 'Less sugar', 'Lower sodium', 'No artificial additives'],
    this.bestFor = const ['Weight management', 'Heart health', 'Better digestion', 'Sustained energy'],
    this.aiRecommendation = 'Steel Cut Oats is the healthier choice! It has more fiber, '
        'less sugar, and no added ingredients.',
    this.onBack,
    this.onHowItWorksTap,
    this.onFavoriteA,
    this.onFavoriteB,
    this.onViewDetailsTap,
    this.onAddBothToPantry,
    this.onViewDetailedAnalysis,
  });

  final ComparisonProduct productA;
  final ComparisonProduct productB;
  final List<NutrientRow> nutrients;
  final String winnerName;
  final String winnerReason;
  final List<String> keyAdvantages;
  final List<String> bestFor;
  final String aiRecommendation;

  final VoidCallback? onBack;
  final VoidCallback? onHowItWorksTap;
  final VoidCallback? onFavoriteA;
  final VoidCallback? onFavoriteB;
  final VoidCallback? onViewDetailsTap;
  final VoidCallback? onAddBothToPantry;
  final VoidCallback? onViewDetailedAnalysis;

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _ambientCtrl;
  bool _favA = false;
  bool _favB = false;
  bool _per100g = false;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();
    _ambientCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _ambientCtrl.dispose();
    super.dispose();
  }

  Animation<double> _fade(double s, double e) =>
      CurvedAnimation(parent: _entranceCtrl, curve: Interval(s, e, curve: Curves.easeOut));

  Animation<Offset> _slide(double s, double e) => Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
      .animate(CurvedAnimation(parent: _entranceCtrl, curve: Interval(s, e, curve: Curves.easeOutCubic)));

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 390).clamp(0.85, 1.25);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FB),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _BackgroundGradient(),
          SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16 * scale, 8 * scale, 16 * scale, 28 * scale),
              physics: const BouncingScrollPhysics(),
              children: [
                FadeTransition(
                  opacity: _fade(0.0, 0.25),
                  child: _TopBar(uiScale: scale, onBack: widget.onBack, onHowItWorksTap: widget.onHowItWorksTap),
                ),
                SizedBox(height: 16 * scale),

                FadeTransition(
                  opacity: _fade(0.04, 0.4),
                  child: SlideTransition(
                    position: _slide(0.04, 0.42),
                    child: _CompareCardsRow(
                      uiScale: scale,
                      entranceCtrl: _entranceCtrl,
                      productA: widget.productA,
                      productB: widget.productB,
                      favA: _favA,
                      favB: _favB,
                      onFavA: () {
                        setState(() => _favA = !_favA);
                        widget.onFavoriteA?.call();
                      },
                      onFavB: () {
                        setState(() => _favB = !_favB);
                        widget.onFavoriteB?.call();
                      },
                    ),
                  ),
                ),
                SizedBox(height: 20 * scale),

                FadeTransition(
                  opacity: _fade(0.14, 0.5),
                  child: SlideTransition(
                    position: _slide(0.14, 0.52),
                    child: _AiRecommendationBanner(
                      uiScale: scale,
                      ambientCtrl: _ambientCtrl,
                      text: widget.aiRecommendation,
                      onViewDetailsTap: widget.onViewDetailsTap,
                    ),
                  ),
                ),
                SizedBox(height: 20 * scale),

                FadeTransition(
                  opacity: _fade(0.22, 0.6),
                  child: SlideTransition(
                    position: _slide(0.22, 0.62),
                    child: _NutritionComparisonCard(
                      uiScale: scale,
                      nutrients: widget.nutrients,
                      per100g: _per100g,
                      onToggle: (v) => setState(() => _per100g = v),
                    ),
                  ),
                ),
                SizedBox(height: 18 * scale),

                FadeTransition(
                  opacity: _fade(0.32, 0.68),
                  child: SlideTransition(
                    position: _slide(0.32, 0.7),
                    child: _WinnerBanner(
                      uiScale: scale,
                      ambientCtrl: _ambientCtrl,
                      winnerName: widget.winnerName,
                      reason: widget.winnerReason,
                    ),
                  ),
                ),
                SizedBox(height: 12 * scale),

                FadeTransition(
                  opacity: _fade(0.4, 0.74),
                  child: SlideTransition(
                    position: _slide(0.4, 0.76),
                    child: _InfoListsRow(
                      uiScale: scale,
                      keyAdvantages: widget.keyAdvantages,
                      bestFor: widget.bestFor,
                    ),
                  ),
                ),
                SizedBox(height: 18 * scale),

                FadeTransition(
                  opacity: _fade(0.5, 0.85),
                  child: SlideTransition(
                    position: _slide(0.5, 0.88),
                    child: _BottomButtonsRow(
                      uiScale: scale,
                      onAddBothToPantry: widget.onAddBothToPantry,
                      onViewDetailedAnalysis: widget.onViewDetailedAnalysis,
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
// Background
// ---------------------------------------------------------------------------
class _BackgroundGradient extends StatelessWidget {
  const _BackgroundGradient();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF1EDFB), Color(0xFFEFFAF3)],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------
class _TopBar extends StatelessWidget {
  const _TopBar({required this.uiScale, this.onBack, this.onHowItWorksTap});
  final double uiScale;
  final VoidCallback? onBack;
  final VoidCallback? onHowItWorksTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundButton(
  uiScale: uiScale,
  icon: Icons.arrow_back,
  onTap: () {
    if (onBack != null) {
      onBack!();
    } else {
      Navigator.of(context).maybePop();
    }
  },
),
        Expanded(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.balance_rounded, size: 17 * uiScale, color: const Color(0xFF6C4EF5)),
                  SizedBox(width: 6 * uiScale),
                  Text('Compare Products',
                      style: TextStyle(fontSize: 16.5 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
                ],
              ),
              Text('Choose the healthier option for you',
                  style: TextStyle(fontSize: 10.5 * uiScale, color: const Color(0xFF6B6B7B))),
            ],
          ),
        ),
        _HowItWorksPill(uiScale: uiScale, onTap: onHowItWorksTap),
      ],
    );
  }
}

class _RoundButton extends StatefulWidget {
  const _RoundButton({required this.uiScale, required this.icon, this.onTap, this.iconColor = const Color(0xFF1B1B2E)});
  final double uiScale;
  final IconData icon;
  final VoidCallback? onTap;
  final Color iconColor;

  @override
  State<_RoundButton> createState() => _RoundButtonState();
}

class _RoundButtonState extends State<_RoundButton> {
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
          width: 40 * widget.uiScale,
          height: 40 * widget.uiScale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Icon(widget.icon, size: 18 * widget.uiScale, color: widget.iconColor),
        ),
      ),
    );
  }
}

class _HowItWorksPill extends StatefulWidget {
  const _HowItWorksPill({required this.uiScale, this.onTap});
  final double uiScale;
  final VoidCallback? onTap;

  @override
  State<_HowItWorksPill> createState() => _HowItWorksPillState();
}

class _HowItWorksPillState extends State<_HowItWorksPill> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.94),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12 * widget.uiScale, vertical: 9 * widget.uiScale),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.help_outline, size: 14 * widget.uiScale, color: const Color(0xFF6C4EF5)),
              SizedBox(width: 5 * widget.uiScale),
              Text('How it works',
                  style: TextStyle(fontSize: 11.5 * widget.uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF6C4EF5))),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Product comparison cards + VS badge
// ---------------------------------------------------------------------------
class _CompareCardsRow extends StatelessWidget {
  const _CompareCardsRow({
    required this.uiScale,
    required this.entranceCtrl,
    required this.productA,
    required this.productB,
    required this.favA,
    required this.favB,
    required this.onFavA,
    required this.onFavB,
  });

  final double uiScale;
  final AnimationController entranceCtrl;
  final ComparisonProduct productA;
  final ComparisonProduct productB;
  final bool favA;
  final bool favB;
  final VoidCallback onFavA;
  final VoidCallback onFavB;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ProductCompareCard(
                uiScale: uiScale,
                entranceCtrl: entranceCtrl,
                product: productA,
                badgeLabel: 'Product 1',
                badgeColor: const Color(0xFF1E8A4C),
                cardTint: const Color(0xFFEAF7EF),
                borderTint: const Color(0xFFBFE6CC),
                gaugeColor: const Color(0xFF1E8A4C),
                favorited: favA,
                onFavTap: onFavA,
                gaugeDelay: 0.1,
              ),
            ),
            SizedBox(width: 12 * uiScale),
            Expanded(
              child: _ProductCompareCard(
                uiScale: uiScale,
                entranceCtrl: entranceCtrl,
                product: productB,
                badgeLabel: 'Product 2',
                badgeColor: const Color(0xFFE0525C),
                cardTint: const Color(0xFFFCEFEF),
                borderTint: const Color(0xFFF3CBCB),
                gaugeColor: const Color(0xFFE0525C),
                favorited: favB,
                onFavTap: onFavB,
                gaugeDelay: 0.2,
              ),
            ),
          ],
        ),
        _VsBadge(uiScale: uiScale, entranceCtrl: entranceCtrl),
      ],
    );
  }
}

class _VsBadge extends StatelessWidget {
  const _VsBadge({required this.uiScale, required this.entranceCtrl});
  final double uiScale;
  final AnimationController entranceCtrl;

  @override
  Widget build(BuildContext context) {
    final scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: entranceCtrl, curve: const Interval(0.1, 0.4, curve: Curves.easeOutBack)),
    );
    return ScaleTransition(
      scale: scaleAnim,
      child: Container(
        width: 40 * uiScale,
        height: 40 * uiScale,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE4E0F2), width: 1.4),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Center(
          child: Text('VS', style: TextStyle(fontSize: 12 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF6C4EF5))),
        ),
      ),
    );
  }
}

class _ProductCompareCard extends StatelessWidget {
  const _ProductCompareCard({
    required this.uiScale,
    required this.entranceCtrl,
    required this.product,
    required this.badgeLabel,
    required this.badgeColor,
    required this.cardTint,
    required this.borderTint,
    required this.gaugeColor,
    required this.favorited,
    required this.onFavTap,
    required this.gaugeDelay,
  });

  final double uiScale;
  final AnimationController entranceCtrl;
  final ComparisonProduct product;
  final String badgeLabel;
  final Color badgeColor;
  final Color cardTint;
  final Color borderTint;
  final Color gaugeColor;
  final bool favorited;
  final VoidCallback onFavTap;
  final double gaugeDelay;

  @override
  Widget build(BuildContext context) {
    final isHealthy = product.tag == ProductTag.healthyChoice;
    final gaugeAnim = CurvedAnimation(
      parent: entranceCtrl,
      curve: Interval(gaugeDelay, gaugeDelay + 0.4, curve: Curves.easeOutCubic),
    );

    return Container(
      padding: EdgeInsets.all(12 * uiScale),
      decoration: BoxDecoration(
        color: cardTint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderTint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8 * uiScale, vertical: 3 * uiScale),
                decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: Text(badgeLabel, style: TextStyle(fontSize: 9.5 * uiScale, fontWeight: FontWeight.w700, color: badgeColor)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onFavTap,
                child: Icon(
                  favorited ? Icons.favorite : Icons.favorite_border,
                  size: 16 * uiScale,
                  color: favorited ? const Color(0xFFE0525C) : const Color(0xFF9A96A8),
                ),
              ),
            ],
          ),
          SizedBox(height: 8 * uiScale),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: 84 * uiScale,
              color: Colors.white,
              padding: EdgeInsets.all(6 * uiScale),
              child: Image(image: product.image, fit: BoxFit.contain),
            ),
          ),
          SizedBox(height: 8 * uiScale),
          Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13.5 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
          Text(product.brand, style: TextStyle(fontSize: 10.5 * uiScale, color: const Color(0xFF6B6B7B))),
          SizedBox(height: 5 * uiScale),
          Row(
            children: [
              Icon(isHealthy ? Icons.eco : Icons.error_outline, size: 11 * uiScale, color: badgeColor),
              SizedBox(width: 4 * uiScale),
              Expanded(
                child: Text(
                  isHealthy ? 'Healthy Choice' : 'Consider Less',
                  style: TextStyle(fontSize: 9.5 * uiScale, fontWeight: FontWeight.w700, color: badgeColor),
                ),
              ),
            ],
          ),
          SizedBox(height: 6 * uiScale),
          Row(
            children: [
              Icon(Icons.local_dining_outlined, size: 10.5 * uiScale, color: const Color(0xFF9A96A8)),
              SizedBox(width: 4 * uiScale),
              Expanded(
                child: Text(product.servingInfo, style: TextStyle(fontSize: 9.5 * uiScale, color: const Color(0xFF9A96A8))),
              ),
            ],
          ),
          SizedBox(height: 3 * uiScale),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 10 * uiScale, color: const Color(0xFF9A96A8)),
              SizedBox(width: 4 * uiScale),
              Expanded(
                child: Text(product.scannedAt, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9 * uiScale, color: const Color(0xFF9A96A8))),
              ),
            ],
          ),
          SizedBox(height: 10 * uiScale),
          Container(
            padding: EdgeInsets.symmetric(vertical: 10 * uiScale, horizontal: 8 * uiScale),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: gaugeAnim,
                  builder: (context, _) {
                    final v = (product.score * gaugeAnim.value).round();
                    return SizedBox(
                      width: 52 * uiScale,
                      height: 52 * uiScale,
                      child: CustomPaint(
                        painter: _ScoreArcPainter(progress: gaugeAnim.value * (product.score / 100), color: gaugeColor),
                        child: Center(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: '$v', style: TextStyle(fontSize: 15 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
                                TextSpan(text: '\n/100', style: TextStyle(fontSize: 7 * uiScale, color: const Color(0xFF9A96A8))),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(width: 8 * uiScale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Overall Score', style: TextStyle(fontSize: 9.5 * uiScale, color: const Color(0xFF6B6B7B))),
                      SizedBox(height: 3 * uiScale),
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 10 * uiScale, color: gaugeColor),
                          SizedBox(width: 3 * uiScale),
                          Flexible(
                            child: Text(product.scoreLabel, overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 10.5 * uiScale, fontWeight: FontWeight.w700, color: gaugeColor)),
                          ),
                        ],
                      ),
                    ],
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

class _ScoreArcPainter extends CustomPainter {
  _ScoreArcPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 4;
    final bg = Paint()
      ..color = const Color(0xFFEDEAF7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi * 0.75, math.pi * 1.5, false, bg);

    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi * 0.75, math.pi * 1.5 * progress, false, fg);
  }

  @override
  bool shouldRepaint(covariant _ScoreArcPainter oldDelegate) => oldDelegate.progress != progress;
}

// ---------------------------------------------------------------------------
// AI recommendation banner
// ---------------------------------------------------------------------------
class _AiRecommendationBanner extends StatelessWidget {
  const _AiRecommendationBanner({
    required this.uiScale,
    required this.ambientCtrl,
    required this.text,
    this.onViewDetailsTap,
  });

  final double uiScale;
  final AnimationController ambientCtrl;
  final String text;
  final VoidCallback? onViewDetailsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14 * uiScale),
      decoration: BoxDecoration(color: const Color(0xFFF1ECFB), borderRadius: BorderRadius.circular(20)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: ambientCtrl,
            builder: (context, child) {
              final bob = math.sin(ambientCtrl.value * math.pi) * 4;
              return Transform.translate(offset: Offset(0, -bob), child: child);
            },
            child: Container(
              width: 46 * uiScale,
              height: 46 * uiScale,
              padding: EdgeInsets.all(3 * uiScale),
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              child: Image.asset('assets/images/robot_badge.png'),
            ),
          ),
          SizedBox(width: 12 * uiScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 13 * uiScale, color: const Color(0xFF6C4EF5)),
                    SizedBox(width: 5 * uiScale),
                    Text('AI Recommendation',
                        style: TextStyle(fontSize: 13 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF6C4EF5))),
                  ],
                ),
                SizedBox(height: 4 * uiScale),
                Text(text, style: TextStyle(fontSize: 11 * uiScale, height: 1.4, color: const Color(0xFF3B3B4F))),
                SizedBox(height: 10 * uiScale),
                _ViewDetailsButton(uiScale: uiScale, onTap: onViewDetailsTap),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewDetailsButton extends StatefulWidget {
  const _ViewDetailsButton({required this.uiScale, this.onTap});
  final double uiScale;
  final VoidCallback? onTap;

  @override
  State<_ViewDetailsButton> createState() => _ViewDetailsButtonState();
}

class _ViewDetailsButtonState extends State<_ViewDetailsButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14 * widget.uiScale, vertical: 9 * widget.uiScale),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('View Details', style: TextStyle(fontSize: 11.5 * widget.uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF6C4EF5))),
              SizedBox(width: 4 * widget.uiScale),
              Icon(Icons.chevron_right, size: 15 * widget.uiScale, color: const Color(0xFF6C4EF5)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Nutrition comparison table
// ---------------------------------------------------------------------------
class _NutritionComparisonCard extends StatelessWidget {
  const _NutritionComparisonCard({
    required this.uiScale,
    required this.nutrients,
    required this.per100g,
    required this.onToggle,
  });

  final double uiScale;
  final List<NutrientRow> nutrients;
  final bool per100g;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14 * uiScale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8 * uiScale,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bar_chart_rounded, size: 15 * uiScale, color: const Color(0xFF9B7BFA)),
                  SizedBox(width: 6 * uiScale),
                  Text('Nutrition Comparison',
                      style: TextStyle(fontSize: 14 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
                ],
              ),
              SizedBox(width: 12 * uiScale),
              _ServingToggle(uiScale: uiScale, per100g: per100g, onToggle: onToggle),
            ],
          ),
          SizedBox(height: 12 * uiScale),
          ...List.generate(nutrients.length, (i) {
            final n = nutrients[i];
            return _NutrientCompareRow(uiScale: uiScale, nutrient: n, per100g: per100g, isLast: i == nutrients.length - 1);
          }),
          SizedBox(height: 10 * uiScale),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14 * uiScale,
            runSpacing: 4 * uiScale,
            children: [
              _Legend(uiScale: uiScale, icon: Icons.arrow_upward_rounded, color: const Color(0xFF1E8A4C), label: 'Higher is better'),
              _Legend(uiScale: uiScale, icon: Icons.arrow_downward_rounded, color: const Color(0xFFE0525C), label: 'Lower is better'),
              _Legend(uiScale: uiScale, icon: Icons.remove_rounded, color: const Color(0xFF9A96A8), label: 'Neutral'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServingToggle extends StatelessWidget {
  const _ServingToggle({required this.uiScale, required this.per100g, required this.onToggle});
  final double uiScale;
  final bool per100g;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3 * uiScale),
      decoration: BoxDecoration(color: const Color(0xFFF1EEF9), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleOption(uiScale: uiScale, label: 'Per 40 g (1 serving)', selected: !per100g, onTap: () => onToggle(false)),
          _ToggleOption(uiScale: uiScale, label: 'Per 100 g', selected: per100g, onTap: () => onToggle(true)),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({required this.uiScale, required this.label, required this.selected, required this.onTap});
  final double uiScale;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 10 * uiScale, vertical: 7 * uiScale),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6C4EF5) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10 * uiScale,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : const Color(0xFF6B6B7B),
          ),
        ),
      ),
    );
  }
}

class _NutrientCompareRow extends StatelessWidget {
  const _NutrientCompareRow({
    required this.uiScale,
    required this.nutrient,
    required this.per100g,
    required this.isLast,
  });

  final double uiScale;
  final NutrientRow nutrient;
  final bool per100g;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final left = per100g ? nutrient.leftValue100g : nutrient.leftValue40g;
    final right = per100g ? nutrient.rightValue100g : nutrient.rightValue40g;

    final leftBetter = nutrient.trend == Trend.neutral
        ? null
        : nutrient.trend == Trend.higherIsBetter
            ? left >= right
            : left <= right;

    Color colorFor(bool? isBetter) {
      if (isBetter == null) return const Color(0xFF1B1B2E);
      return isBetter ? const Color(0xFF1E8A4C) : const Color(0xFFE0525C);
    }

    IconData trendIcon() {
      switch (nutrient.trend) {
        case Trend.higherIsBetter:
          return Icons.arrow_upward_rounded;
        case Trend.lowerIsBetter:
          return Icons.arrow_downward_rounded;
        case Trend.neutral:
          return Icons.remove_rounded;
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 10 * uiScale),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF1EEF9))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: '$left', style: TextStyle(fontSize: 13.5 * uiScale, fontWeight: FontWeight.w800, color: colorFor(leftBetter))),
                  TextSpan(text: ' ${nutrient.unit}', style: TextStyle(fontSize: 9.5 * uiScale, color: const Color(0xFF9A96A8))),
                ]),
              ),
            ),
          ),
          SizedBox(
            width: 96 * uiScale,
            child: Column(
              children: [
                Icon(nutrient.icon, size: 15 * uiScale, color: const Color(0xFF6C4EF5)),
                SizedBox(height: 2 * uiScale),
                Text(nutrient.label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9.5 * uiScale, color: const Color(0xFF3B3B4F))),
              ],
            ),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: '$right', style: TextStyle(fontSize: 13.5 * uiScale, fontWeight: FontWeight.w800, color: colorFor(leftBetter == null ? null : !leftBetter))),
                TextSpan(text: ' ${nutrient.unit}', style: TextStyle(fontSize: 9.5 * uiScale, color: const Color(0xFF9A96A8))),
              ]),
            ),
          ),
          SizedBox(width: 6 * uiScale),
          Container(
            width: 22 * uiScale,
            height: 22 * uiScale,
            decoration: BoxDecoration(color: const Color(0xFFE4F5E9), shape: BoxShape.circle),
            child: Icon(trendIcon(), size: 12 * uiScale, color: const Color(0xFF1E8A4C)),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.uiScale, required this.icon, required this.color, required this.label});
  final double uiScale;
  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12 * uiScale, color: color),
        SizedBox(width: 4 * uiScale),
        Text(label, style: TextStyle(fontSize: 9.5 * uiScale, color: const Color(0xFF6B6B7B))),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Winner banner
// ---------------------------------------------------------------------------
class _WinnerBanner extends StatelessWidget {
  const _WinnerBanner({required this.uiScale, required this.ambientCtrl, required this.winnerName, required this.reason});
  final double uiScale;
  final AnimationController ambientCtrl;
  final String winnerName;
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16 * uiScale),
      decoration: BoxDecoration(color: const Color(0xFFE9F7EE), borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: ambientCtrl,
            builder: (context, _) {
              return Positioned(
                right: 8,
                top: 6 + math.sin(ambientCtrl.value * math.pi) * 3,
                child: Icon(Icons.auto_awesome, size: 14 * uiScale, color: const Color(0xFF1E8A4C).withValues(alpha: 0.4)),
              );
            },
          ),
          Positioned(right: 30, bottom: 10, child: Icon(Icons.circle, size: 8 * uiScale, color: const Color(0xFF1E8A4C).withValues(alpha: 0.2))),
          Row(
            children: [
              Container(
                width: 48 * uiScale,
                height: 48 * uiScale,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(Icons.emoji_events_rounded, color: const Color(0xFFE0862E), size: 24 * uiScale),
              ),
              SizedBox(width: 12 * uiScale),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Winner', style: TextStyle(fontSize: 11.5 * uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF3B3B4F))),
                  Text(winnerName, style: TextStyle(fontSize: 19 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1E8A4C))),
                  Text(reason, style: TextStyle(fontSize: 10.5 * uiScale, color: const Color(0xFF3B3B4F))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Key Advantage / Best For
// ---------------------------------------------------------------------------
class _InfoListsRow extends StatelessWidget {
  const _InfoListsRow({required this.uiScale, required this.keyAdvantages, required this.bestFor});
  final double uiScale;
  final List<String> keyAdvantages;
  final List<String> bestFor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _InfoListCard(
            uiScale: uiScale,
            icon: Icons.star_rounded,
            iconColor: const Color(0xFFE0862E),
            title: 'Key Advantage',
            items: keyAdvantages,
            checkColor: const Color(0xFF1E8A4C),
          ),
        ),
        SizedBox(width: 12 * uiScale),
        Expanded(
          child: _InfoListCard(
            uiScale: uiScale,
            icon: Icons.person_rounded,
            iconColor: const Color(0xFF6C4EF5),
            title: 'Best For',
            items: bestFor,
            checkColor: const Color(0xFF6C4EF5),
          ),
        ),
      ],
    );
  }
}

class _InfoListCard extends StatelessWidget {
  const _InfoListCard({
    required this.uiScale,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.items,
    required this.checkColor,
  });

  final double uiScale;
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<String> items;
  final Color checkColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12 * uiScale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15 * uiScale, color: iconColor),
              SizedBox(width: 6 * uiScale),
              Text(title, style: TextStyle(fontSize: 12 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
            ],
          ),
          SizedBox(height: 8 * uiScale),
          ...items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 6 * uiScale),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, size: 13 * uiScale, color: checkColor),
                  SizedBox(width: 6 * uiScale),
                  Expanded(
                    child: Text(item, style: TextStyle(fontSize: 10.5 * uiScale, color: const Color(0xFF3B3B4F))),
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
// Bottom buttons
// ---------------------------------------------------------------------------
class _BottomButtonsRow extends StatelessWidget {
  const _BottomButtonsRow({required this.uiScale, this.onAddBothToPantry, this.onViewDetailedAnalysis});
  final double uiScale;
  final VoidCallback? onAddBothToPantry;
  final VoidCallback? onViewDetailedAnalysis;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _OutlineButton(uiScale: uiScale, icon: Icons.inventory_2_outlined, label: 'Add Both to Pantry', onTap: onAddBothToPantry),
        ),
        SizedBox(width: 12 * uiScale),
        Expanded(
          child: _PrimaryButton(uiScale: uiScale, icon: Icons.bar_chart_rounded, label: 'View Detailed Analysis', onTap: onViewDetailedAnalysis),
        ),
      ],
    );
  }
}

class _OutlineButton extends StatefulWidget {
  const _OutlineButton({required this.uiScale, required this.icon, required this.label, this.onTap});
  final double uiScale;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  State<_OutlineButton> createState() => _OutlineButtonState();
}

class _OutlineButtonState extends State<_OutlineButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14 * widget.uiScale, horizontal: 8 * widget.uiScale),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E0F2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 16 * widget.uiScale, color: const Color(0xFF6C4EF5)),
              SizedBox(width: 6 * widget.uiScale),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5 * widget.uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF1B1B2E)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({required this.uiScale, required this.icon, required this.label, this.onTap});
  final double uiScale;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14 * widget.uiScale, horizontal: 8 * widget.uiScale),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(colors: [Color(0xFF6C4EF5), Color(0xFF1E8A4C)]),
            boxShadow: [BoxShadow(color: const Color(0xFF6C4EF5).withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 8))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 16 * widget.uiScale, color: Colors.white),
              SizedBox(width: 6 * widget.uiScale),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5 * widget.uiScale, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
              SizedBox(width: 4 * widget.uiScale),
              Icon(Icons.arrow_forward, size: 13 * widget.uiScale, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
