import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:diet_compass/features/scan/compare_screen.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/model/food_product.dart';

/// DietCompass — AI Result Screen
/// -----------------------------------------------------------------------
/// Shown after [AiAnalysisScreen] completes. Reuses your existing assets:
///   • assets/images/robot_badge.png       — DietCompass robot (banner)
///   • assets/images/product_quaker.png    — the scanned product photo
///   • assets/images/product_saffola.png,
///     assets/images/product_true_elements.png — alternative products
///
/// All content is data-driven via constructor parameters / simple models
/// below (NutrientStat, CompatibilityItem, AlternativeProduct, etc.) so
/// this screen can be wired to a real backend response instead of the
/// sample DietCompass data used for preview.
///
/// Add to pubspec.yaml (skip any already present):
/// ```yaml
/// flutter:
///   assets:
///     - assets/images/robot_badge.png
///     - assets/images/product_quaker.png
///     - assets/images/product_saffola.png
///     - assets/images/product_true_elements.png
/// ```
class NutrientStat {
  const NutrientStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.badge,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final String badge; // e.g. "Good", "Excellent", "Low"
}

class CompatibilityItem {
  const CompatibilityItem({
    required this.icon,
    required this.label,
    required this.rating,
  });

  final IconData icon;
  final String label;
  final String rating; // "Excellent" | "Good" | ...
}

class ProsConsItem {
  const ProsConsItem({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
}

class AlternativeProduct {
  const AlternativeProduct({
    required this.asset,
    required this.name,
    required this.subtitle,
    required this.score,
    required this.differentiator,
  });

  final String asset;
  final String name;
  final String subtitle;
  final int score;
  final String differentiator; // e.g. "More Protein"
}

double _nutritionValue(double? value) {
  return value ?? 0.0;
}

int _calculateScore(FoodProduct product) {
  final protein = _nutritionValue(product.protein);
  final fiber = _nutritionValue(product.fiber);
  final sugar = _nutritionValue(product.sugar);
  final fat = _nutritionValue(product.fat);
  final sodium = _nutritionValue(product.sodium);

  int score = 50;

  if (protein > 5) {
    score += 10;
  }

  if (fiber > 3) {
    score += 10;
  }

  if (sugar > 12) {
    score -= 10;
  }

  if (fat > 20) {
    score -= 5;
  }

  if (sodium > 0.6) {
    score -= 5;
  }

  return score.clamp(0, 100);
}

int _calculateCompatibility(FoodProduct product) {
  final calories = _nutritionValue(product.calories);
  final protein = _nutritionValue(product.protein);
  final fiber = _nutritionValue(product.fiber);
  final sugar = _nutritionValue(product.sugar);
  final sodium = _nutritionValue(product.sodium);

  int score = 50;

  if (sugar <= 5) score += 10;
  if (fiber >= 3) score += 10;
  if (protein >= 5) score += 10;
  if (sodium <= 0.4) score += 10;
  if (calories <= 200) score += 10;

  return score.clamp(0, 100);
}

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,

    // NEW: actual scanned product
    required this.product,
    this.productImage,

    // Existing result-screen data
    this.productName = '',
    this.productSubtitle = '',
    this.servingWeight = '',
    this.servingCount = '',
    this.scannedAt = '',
    this.overallScore = 0,
    this.aiConfidence = 0,
    this.compatibilityPercent = 0,

    this.nutrients = const [],
    this.compatibility = const [],
    this.goodPoints = const [],
    this.watchPoints = const [],
    this.alternatives = const [],

    this.onBack,
    this.onFavoriteTap,
    this.onMoreTap,
    this.onAskAiTap,
    this.onCompareTap,
    this.onAddToPantryTap,
    this.onShareTap,
    this.onAskAiCoachTap,
    this.onGenerateRecipeTap,
    this.onShoppingSuggestionTap,
    this.onViewAllAlternatives,
    this.onAlternativeTap,
  });

  final FoodProduct product;
  final ImageProvider? productImage;

  final String productName;
  final String productSubtitle;
  final String servingWeight;
  final String servingCount;
  final String scannedAt;

  final int overallScore;
  final int aiConfidence;
  final int compatibilityPercent;

  final List<NutrientStat> nutrients;
  final List<CompatibilityItem> compatibility;
  final List<ProsConsItem> goodPoints;
  final List<ProsConsItem> watchPoints;
  final List<AlternativeProduct> alternatives;

  final VoidCallback? onBack;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onMoreTap;
  final VoidCallback? onAskAiTap;
  final VoidCallback? onCompareTap;
  final VoidCallback? onAddToPantryTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onAskAiCoachTap;
  final VoidCallback? onGenerateRecipeTap;
  final VoidCallback? onShoppingSuggestionTap;
  final VoidCallback? onViewAllAlternatives;
  final ValueChanged<int>? onAlternativeTap;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _ambientCtrl;
  bool _favorited = false;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..forward();
    _ambientCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _ambientCtrl.dispose();
    super.dispose();
  }

 List<NutrientStat> _buildNutrients(FoodProduct product) {
  final nutrients = <NutrientStat>[];

  // Calories
  final calories = product.calories;
  String caloriesBadge;

  if (calories <= 100) {
    caloriesBadge = 'Good';
  } else if (calories <= 250) {
    caloriesBadge = 'Moderate';
  } else if (calories <= 400) {
    caloriesBadge = 'High';
  } else {
    caloriesBadge = 'Very High';
  }

  nutrients.add(
    NutrientStat(
      label: 'Calories',
      value: calories.toStringAsFixed(0),
      unit: 'kcal',
      icon: Icons.local_fire_department,
      color: const Color(0xFF6C4EF5),
      badge: caloriesBadge,
    ),
  );

  // Protein
  final protein = product.protein;
  String proteinBadge;

  if (protein >= 10) {
    proteinBadge = 'Good';
  } else if (protein >= 5) {
    proteinBadge = 'Moderate';
  } else if (protein >= 2) {
    proteinBadge = 'High';
  } else {
    proteinBadge = 'Very High';
  }

  nutrients.add(
    NutrientStat(
      label: 'Protein',
      value: protein.toStringAsFixed(1),
      unit: 'g',
      icon: Icons.fitness_center,
      color: const Color(0xFF1E8A4C),
      badge: proteinBadge,
    ),
  );

  // Carbohydrates
  final carbs = product.carbohydrates;
  String carbsBadge;

  if (carbs < 20) {
    carbsBadge = 'Good';
  } else if (carbs <= 50) {
    carbsBadge = 'Moderate';
  } else if (carbs <= 70) {
    carbsBadge = 'High';
  } else {
    carbsBadge = 'Very High';
  }

  nutrients.add(
    NutrientStat(
      label: 'Carbs',
      value: carbs.toStringAsFixed(1),
      unit: 'g',
      icon: Icons.grain,
      color: const Color(0xFFE0862E),
      badge: carbsBadge,
    ),
  );

  // Sugar
  final sugar = product.sugar;
  String sugarBadge;

  if (sugar <= 5) {
    sugarBadge = 'Good';
  } else if (sugar <= 10) {
    sugarBadge = 'Moderate';
  } else if (sugar <= 15) {
    sugarBadge = 'High';
  } else {
    sugarBadge = 'Very High';
  }

  nutrients.add(
    NutrientStat(
      label: 'Sugar',
      value: sugar.toStringAsFixed(1),
      unit: 'g',
      icon: Icons.icecream,
      color: const Color(0xFFE0525C),
      badge: sugarBadge,
    ),
  );

  // Fat
  final fat = product.fat;
  String fatBadge;

  if (fat <= 3) {
    fatBadge = 'Good';
  } else if (fat <= 10) {
    fatBadge = 'Moderate';
  } else if (fat <= 20) {
    fatBadge = 'High';
  } else {
    fatBadge = 'Very High';
  }

  nutrients.add(
    NutrientStat(
      label: 'Fat',
      value: fat.toStringAsFixed(1),
      unit: 'g',
      icon: Icons.opacity,
      color: const Color(0xFFE0862E),
      badge: fatBadge,
    ),
  );

  // Sodium
  // Open Food Facts gives sodium in g/100g.
  // Convert to mg/100g for DietCompass criteria.
  final sodiumMg = product.sodium * 1000;
  String sodiumBadge;

  if (sodiumMg <= 120) {
    sodiumBadge = 'Good';
  } else if (sodiumMg <= 400) {
    sodiumBadge = 'Moderate';
  } else if (sodiumMg <= 800) {
    sodiumBadge = 'High';
  } else {
    sodiumBadge = 'Very High';
  }

  nutrients.add(
    NutrientStat(
      label: 'Sodium',
      value: sodiumMg.toStringAsFixed(0),
      unit: 'mg',
      icon: Icons.water_drop_outlined,
      color: const Color(0xFF3B82F6),
      badge: sodiumBadge,
    ),
  );

  return nutrients;
}

List<CompatibilityItem> _buildCompatibility(FoodProduct product) {
  final calories = _nutritionValue(product.calories);
  final sodium = _nutritionValue(product.sodium);
  final sugar = _nutritionValue(product.sugar);
  final fiber = _nutritionValue(product.fiber);

  return [
    CompatibilityItem(
      icon: Icons.monitor_weight_outlined,
      label: 'Weight Management',
      rating: calories <= 200 ? 'Good' : 'Consider',
    ),
    CompatibilityItem(
      icon: Icons.favorite_outline,
      label: 'Heart Health',
      rating: sodium <= 0.4 ? 'Good' : 'Consider',
    ),
    CompatibilityItem(
      icon: Icons.water_drop_outlined,
      label: 'Blood Sugar Control',
      rating: sugar <= 5 ? 'Good' : 'Consider',
    ),
    CompatibilityItem(
      icon: Icons.eco_outlined,
      label: 'Digestive Health',
      rating: fiber >= 3 ? 'Excellent' : 'Good',
    ),
  ];
}

List<ProsConsItem> _buildGoodPoints(FoodProduct product) {
  final fiber = _nutritionValue(product.fiber);
  final sugar = _nutritionValue(product.sugar);
  final protein = _nutritionValue(product.protein);

  final points = <ProsConsItem>[];

  if (fiber >= 3) {
    points.add(
      const ProsConsItem(
        title: 'Good source of fiber',
        subtitle: 'Supports digestive health',
      ),
    );
  }

  if (sugar <= 5) {
    points.add(
      const ProsConsItem(
        title: 'Low in sugar',
        subtitle: 'Contains relatively little sugar',
      ),
    );
  }

  if (protein >= 5) {
    points.add(
      const ProsConsItem(
        title: 'Good protein content',
        subtitle: 'Provides a useful amount of protein',
      ),
    );
  }

  if (fiber == 0 && sugar == 0 && protein == 0) {
    points.add(
      const ProsConsItem(
        title: 'Nutrition data limited',
        subtitle: 'Some nutritional values are unavailable',
      ),
    );
  }

  return points;
}

List<ProsConsItem> _buildWatchPoints(FoodProduct product) {
  final sugar = _nutritionValue(product.sugar);
  final sodium = _nutritionValue(product.sodium);
  final fat = _nutritionValue(product.fat);

  final points = <ProsConsItem>[];

  if (sugar > 10) {
    points.add(
      const ProsConsItem(
        title: 'High in sugar',
        subtitle: 'Consider limiting frequent consumption',
      ),
    );
  }

  if (sodium > 0.6) {
    points.add(
      const ProsConsItem(
        title: 'Higher sodium',
        subtitle: 'Consider your overall sodium intake',
      ),
    );
  }

  if (fat > 20) {
    points.add(
      const ProsConsItem(
        title: 'Higher fat content',
        subtitle: 'Keep portion size in mind',
      ),
    );
  }

  if (points.isEmpty) {
    points.add(
      const ProsConsItem(
        title: 'No major flags detected',
        subtitle: 'Based on the available nutrition data',
      ),
    );
  }

  return points;
}

  Animation<double> _fade(double s, double e) => CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(s, e, curve: Curves.easeOut),
      );


  Animation<Offset> _slide(double s, double e) => Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _entranceCtrl, curve: Interval(s, e, curve: Curves.easeOutCubic)));

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double scale =
    (size.shortestSide / 390).clamp(0.85, 1.25).toDouble();

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
                  opacity: _fade(0.0, 0.3),
                  child: _TopBar(
                    uiScale: scale,
                    favorited: _favorited,
                    onBack: widget.onBack,
                    onFavoriteTap: () {
                      setState(() => _favorited = !_favorited);
                      widget.onFavoriteTap?.call();
                    },
                    onMoreTap: widget.onMoreTap,
                  ),
                ),
                SizedBox(height: 14 * scale),

                FadeTransition(
                  opacity: _fade(0.04, 0.4),
                  child: SlideTransition(
                    position: _slide(0.04, 0.42),
                    child: _ProductSummaryCard(
  uiScale: scale,
  entranceCtrl: _entranceCtrl,
  product: widget.product,
  image: widget.productImage,
),
                  ),
                ),
                SizedBox(height: 14 * scale),

                FadeTransition(
                  opacity: _fade(0.1, 0.46),
                  child: SlideTransition(
                    position: _slide(0.1, 0.48),
                    child: _GreatChoiceBanner(
                    uiScale: scale,
                    ambientCtrl: _ambientCtrl,
                    product: widget.product,
                    onAskAiTap: widget.onAskAiTap,
                    ),
                  ),
                ),
                SizedBox(height: 20 * scale),

                FadeTransition(
                  opacity: _fade(0.16, 0.52),
                  child: SlideTransition(
                    position: _slide(0.16, 0.54),
                    child: _NutritionSnapshot(uiScale: scale, nutrients: _buildNutrients(widget.product),),
                  ),
                ),
                SizedBox(height: 20 * scale),

                FadeTransition(
                  opacity: _fade(0.24, 0.6),
                  child: SlideTransition(
                    position: _slide(0.24, 0.62),
                    child: _HealthCompatibilityCard(
                      uiScale: scale,
                      entranceCtrl: _entranceCtrl,
                      items: _buildCompatibility(widget.product),
                      percent: _calculateCompatibility(widget.product),
                    ),
                  ),
                ),
                SizedBox(height: 16 * scale),

                FadeTransition(
                  opacity: _fade(0.32, 0.66),
                  child: SlideTransition(
                    position: _slide(0.32, 0.68),
                    child: _GoodVsWatchRow(
                      uiScale: scale,
                      good: _buildGoodPoints(widget.product),
                      watch: _buildWatchPoints(widget.product),
                    ),
                  ),
                ),
                SizedBox(height: 20 * scale),

                FadeTransition(
                  opacity: _fade(0.4, 0.74),
                  child: SlideTransition(
                    position: _slide(0.4, 0.76),
                    child: _AlternativesSection(
                      uiScale: scale,
                      items: widget.alternatives,
                      onViewAll: widget.onViewAllAlternatives,
                      onTap: widget.onAlternativeTap,
                    ),
                  ),
                ),
                SizedBox(height: 18 * scale),

                FadeTransition(
                  opacity: _fade(0.48, 0.8),
                  child: SlideTransition(
                    position: _slide(0.48, 0.82),
                    child: _ActionButtonsRow(
  uiScale: scale,
  onCompareTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CompareScreen(),
      ),
    );
  },
  onAddToPantryTap: widget.onAddToPantryTap,
  onShareTap: () async {
  await SharePlus.instance.share(
    ShareParams(
      text: '''
🥗 I analyzed ${widget.product.name} using DietCompass!

⭐ Overall Score: ${_calculateScore(widget.product)}/100

Download DietCompass and analyze your food too!
''',
    ),
  );
},
),
                  ),
                ),
                SizedBox(height: 16 * scale),

                FadeTransition(
                  opacity: _fade(0.55, 0.9),
                  child: SlideTransition(
                    position: _slide(0.55, 0.92),
                    child: _QuickActionsRow(
                      uiScale: scale,
                      onAskAiCoachTap: widget.onAskAiCoachTap,
                      onGenerateRecipeTap: widget.onGenerateRecipeTap,
                      onShoppingSuggestionTap: widget.onShoppingSuggestionTap,
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
// Glass card helper
// ---------------------------------------------------------------------------
class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.padding,
    this.color,
    this.radius = 22,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color ?? Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.uiScale,
    required this.favorited,
    this.onBack,
    this.onFavoriteTap,
    this.onMoreTap,
  });

  final double uiScale;
  final bool favorited;
  final VoidCallback? onBack;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onMoreTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundGlassButton(
  uiScale: uiScale,
  icon: Icons.arrow_back,
  onTap: () {
    if (onBack != null) {
      onBack!();
    } else {
      Navigator.pop(context);
    }
  },
),
        Expanded(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, size: 16 * uiScale, color: const Color(0xFF6C4EF5)),
                  SizedBox(width: 6 * uiScale),
                  Text(
                    'AI Result',
                    style: TextStyle(fontSize: 17 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E)),
                  ),
                ],
              ),
              Text(
                "Here's what we found for you",
                style: TextStyle(fontSize: 11 * uiScale, color: const Color(0xFF6B6B7B)),
              ),
            ],
          ),
        ),
        _RoundGlassButton(
          uiScale: uiScale,
          icon: favorited ? Icons.favorite : Icons.favorite_border,
          iconColor: favorited ? const Color(0xFFE0525C) : const Color(0xFF1B1B2E),
          onTap: onFavoriteTap,
        ),
        SizedBox(width: 8 * uiScale),
        _RoundGlassButton(uiScale: uiScale, icon: Icons.more_horiz, onTap: onMoreTap),
      ],
    );
  }
}

class _RoundGlassButton extends StatefulWidget {
  const _RoundGlassButton({
    required this.uiScale,
    required this.icon,
    this.iconColor = const Color(0xFF1B1B2E),
    this.onTap,
  });

  final double uiScale;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  State<_RoundGlassButton> createState() => _RoundGlassButtonState();
}

class _RoundGlassButtonState extends State<_RoundGlassButton> {
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
          width: 38 * widget.uiScale,
          height: 38 * widget.uiScale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Icon(widget.icon, size: 17 * widget.uiScale, color: widget.iconColor),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Product summary card + animated rainbow score gauge
// ---------------------------------------------------------------------------
class _ProductSummaryCard extends StatelessWidget {
  const _ProductSummaryCard({
    required this.uiScale,
    required this.entranceCtrl,
    required this.product,
    this.image,
  });

  final double uiScale;
  final AnimationController entranceCtrl;
  final FoodProduct product;
  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    final gaugeAnim = CurvedAnimation(
      parent: entranceCtrl,
      curve: const Interval(
        0.1,
        0.7,
        curve: Curves.easeOutCubic,
      ),
    );

    // Use the actual product image returned from the database/API.
    // Only use the supplied ImageProvider if one exists.
    final ImageProvider? productImage = image ??
        (product.imageUrl.trim().isNotEmpty
            ? NetworkImage(product.imageUrl)
            : null);

    // For now we calculate a simple score from the available nutrition data.
    // We will improve the scoring logic later.
    final overallScore = _calculateScore(product);

    return _GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 74 * uiScale,
              height: 94 * uiScale,
              color: Colors.white,
              padding: EdgeInsets.all(6 * uiScale),
              child: productImage != null
                  ? Image(
                      image: productImage,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return Icon(
                          Icons.fastfood_outlined,
                          size: 34 * uiScale,
                          color: const Color(0xFFB0ACC2),
                        );
                      },
                    )
                  : Icon(
                      Icons.fastfood_outlined,
                      size: 34 * uiScale,
                      color: const Color(0xFFB0ACC2),
                    ),
            ),
          ),

          SizedBox(width: 12 * uiScale),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16.5 * uiScale,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1B1B2E),
                  ),
                ),

                if (product.brand.trim().isNotEmpty) ...[
                  SizedBox(height: 2 * uiScale),
                  Text(
                    product.brand,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12 * uiScale,
                      color: const Color(0xFF6B6B7B),
                    ),
                  ),
                ],

                SizedBox(height: 7 * uiScale),

                Row(
                  children: [
                    Icon(
                      Icons.eco,
                      size: 12 * uiScale,
                      color: const Color(0xFF1E8A4C),
                    ),
                    SizedBox(width: 4 * uiScale),
                    Text(
                      'Scanned Product',
                      style: TextStyle(
                        fontSize: 10.5 * uiScale,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E8A4C),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8 * uiScale),

                Row(
                  children: [
                    Icon(
                      Icons.qr_code_2,
                      size: 12 * uiScale,
                      color: const Color(0xFF9A96A8),
                    ),
                    SizedBox(width: 4 * uiScale),
                    Expanded(
                      child: Text(
                        product.barcode.isNotEmpty
                            ? product.barcode
                            : 'Barcode unavailable',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5 * uiScale,
                          color: const Color(0xFF9A96A8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(width: 6 * uiScale),

          AnimatedBuilder(
            animation: gaugeAnim,
            builder: (context, _) {
              final animatedScore =
                  (overallScore * gaugeAnim.value).round();

              return SizedBox(
                width: 92 * uiScale,
                child: Column(
                  children: [
                    SizedBox(
                      width: 92 * uiScale,
                      height: 72 * uiScale,
                      child: CustomPaint(
                        painter: _RainbowGaugePainter(
                          progress: gaugeAnim.value,
                        ),
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: 22 * uiScale,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$animatedScore',
                                  style: TextStyle(
                                    fontSize: 18 * uiScale,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '/100',
                                  style: TextStyle(
                                    fontSize: 9 * uiScale,
                                    color: const Color(0xFF9A96A8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    Text(
                      'Overall Score',
                      style: TextStyle(
                        fontSize: 9.5 * uiScale,
                        color: const Color(0xFF6B6B7B),
                      ),
                    ),

                    SizedBox(height: 2 * uiScale),

                    if (product.nutriScore != null)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8 * uiScale,
                          vertical: 3 * uiScale,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE4F5E9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Nutri-Score ${product.nutriScore!.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 8.5 * uiScale,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E8A4C),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RainbowGaugePainter extends CustomPainter {
  _RainbowGaugePainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 7);
    final radius = size.width / 2 - 6;
    final bg = Paint()
      ..color = const Color(0xFFEDEAF7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi, math.pi, false, bg);

    final fg = Paint()
      ..shader = const SweepGradient(
        colors: [Color(0xFFE0525C), Color(0xFFE0862E), Color(0xFF34A853), Color(0xFF1E8A4C)],
        startAngle: math.pi,
        endAngle: 2 * math.pi,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi, math.pi * progress, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RainbowGaugePainter oldDelegate) => oldDelegate.progress != progress;
}

// ---------------------------------------------------------------------------
// Great choice banner
// ---------------------------------------------------------------------------
class _GreatChoiceBanner extends StatelessWidget {
  const _GreatChoiceBanner({
    required this.uiScale,
    required this.ambientCtrl,
    required this.product,
    this.onAskAiTap,
  });

  final double uiScale;
  final AnimationController ambientCtrl;
  final FoodProduct product;
  final VoidCallback? onAskAiTap;

  @override
  Widget build(BuildContext context) {
    final score = _calculateCompatibility(product);

final String message;

if (score >= 80) {
  message = 'This product fits well with your health profile.';
} else if (score >= 60) {
  message = 'This product can fit your diet when consumed in moderation.';
} else {
  message = 'This product may not be the best fit for your health goals.';
}

final String title;

if (score >= 80) {
  title = 'Great choice! 🎉';
} else if (score >= 60) {
  title = 'Good option 👍';
} else {
  title = 'Take a closer look 👀';
}
    return _GlassCard(
      color: const Color(0xFFF1ECFB).withValues(alpha: 0.85),
      padding: EdgeInsets.all(14 * uiScale),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: ambientCtrl,
            builder: (context, child) {
              final bob = math.sin(ambientCtrl.value * math.pi) * 4;
              return Transform.translate(offset: Offset(0, -bob), child: child);
            },
           child: Container(
  width: 70 * uiScale,
  height: 70 * uiScale,
  decoration: const BoxDecoration(
    shape: BoxShape.circle,
    color: Colors.white,
  ),
  child: ClipOval(
    child: Image.asset(
      'assets/images/robot_badge.png',
      fit: BoxFit.cover, // fills the circle
      width: double.infinity,
      height: double.infinity,
    ),
  ),
),
          ),
          SizedBox(width: 12 * uiScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
  title,
  style: TextStyle(
    fontSize: 13.5 * uiScale,
    fontWeight: FontWeight.w800,
    color: const Color(0xFF6C4EF5),
  ),
),
                  ],
                ),
                SizedBox(height: 2 * uiScale),
                Text(
  message,
  style: TextStyle(
    fontSize: 10.5 * uiScale,
    height: 1.3,
    color: const Color(0xFF3B3B4F),
  ),
),
              ],
            ),
          ),
          SizedBox(width: 8 * uiScale),
          _AskAiButton(uiScale: uiScale, onTap: onAskAiTap),
        ],
      ),
    );
  }
}

class _AskAiButton extends StatefulWidget {
  const _AskAiButton({required this.uiScale, this.onTap});
  final double uiScale;
  final VoidCallback? onTap;

  @override
  State<_AskAiButton> createState() => _AskAiButtonState();
}

class _AskAiButtonState extends State<_AskAiButton> {
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
          padding: EdgeInsets.symmetric(horizontal: 12 * widget.uiScale, vertical: 10 * widget.uiScale),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline_rounded, size: 13 * widget.uiScale, color: const Color(0xFF6C4EF5)),
              SizedBox(width: 5 * widget.uiScale),
              Text('Ask AI', style: TextStyle(fontSize: 11.5 * widget.uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF6C4EF5))),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Nutrition snapshot (horizontal scroll + dots)
// ---------------------------------------------------------------------------
class _NutritionSnapshot extends StatefulWidget {
  const _NutritionSnapshot({required this.uiScale, required this.nutrients});
  final double uiScale;
  final List<NutrientStat> nutrients;

  @override
  State<_NutritionSnapshot> createState() => _NutritionSnapshotState();
}

class _NutritionSnapshotState extends State<_NutritionSnapshot> {
  final _scrollCtrl = ScrollController();
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      final maxScroll = _scrollCtrl.position.maxScrollExtent;
      if (maxScroll <= 0) return;
      setState(() => _page = (_scrollCtrl.offset / maxScroll).clamp(0.0, 1.0));
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotCount = (widget.nutrients.length / 2).ceil().clamp(1, 6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.graphic_eq_rounded, size: 15 * widget.uiScale, color: const Color(0xFF9B7BFA)),
            SizedBox(width: 6 * widget.uiScale),
            Text('Nutrition Snapshot', style: TextStyle(fontSize: 14.5 * widget.uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
            SizedBox(width: 4 * widget.uiScale),
            Icon(Icons.info_outline, size: 13 * widget.uiScale, color: const Color(0xFFB0ACC2)),
            const Spacer(),
            Text('Per 100 g', style: TextStyle(fontSize: 10.5 * widget.uiScale, color: const Color(0xFF9A96A8))),
          ],
        ),
        SizedBox(height: 10 * widget.uiScale),
        SizedBox(
          height: 108 * widget.uiScale,
          child: ListView.separated(
            controller: _scrollCtrl,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.nutrients.length,
            separatorBuilder: (_, __) => SizedBox(width: 10 * widget.uiScale),
            itemBuilder: (context, i) => _NutrientChip(uiScale: widget.uiScale, stat: widget.nutrients[i]),
          ),
        ),
        SizedBox(height: 8 * widget.uiScale),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(dotCount, (i) {
            final isActiveDot = dotCount == 1 || (i == (_page * (dotCount - 1)).round());
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.symmetric(horizontal: 3 * widget.uiScale),
              width: isActiveDot ? 16 * widget.uiScale : 6 * widget.uiScale,
              height: 6 * widget.uiScale,
              decoration: BoxDecoration(
                color: isActiveDot ? const Color(0xFF6C4EF5) : const Color(0xFFD9D2F0),
                borderRadius: BorderRadius.circular(6),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _NutrientChip extends StatelessWidget {
  const _NutrientChip({required this.uiScale, required this.stat});
  final double uiScale;
  final NutrientStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92 * uiScale,
      padding: EdgeInsets.all(12 * uiScale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(stat.icon, size: 15 * uiScale, color: stat.color),
          SizedBox(height: 6 * uiScale),
          Text(stat.label, style: TextStyle(fontSize: 10.5 * uiScale, color: const Color(0xFF6B6B7B))),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: stat.value, style: TextStyle(fontSize: 15 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
                TextSpan(text: ' ${stat.unit}', style: TextStyle(fontSize: 9.5 * uiScale, color: const Color(0xFF9A96A8))),
              ],
            ),
          ),
          SizedBox(height: 4 * uiScale),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6 * uiScale, vertical: 2 * uiScale),
            decoration: BoxDecoration(color: stat.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Text(stat.badge, style: TextStyle(fontSize: 8.5 * uiScale, fontWeight: FontWeight.w700, color: stat.color)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Health compatibility
// ---------------------------------------------------------------------------
class _HealthCompatibilityCard extends StatelessWidget {
  const _HealthCompatibilityCard({
    required this.uiScale,
    required this.entranceCtrl,
    required this.items,
    required this.percent,
  });

  final double uiScale;
  final AnimationController entranceCtrl;
  final List<CompatibilityItem> items;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final gaugeAnim = CurvedAnimation(parent: entranceCtrl, curve: const Interval(0.3, 0.85, curve: Curves.easeOutCubic));

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Health Compatibility', style: TextStyle(fontSize: 14.5 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
              SizedBox(width: 4 * uiScale),
              Icon(Icons.info_outline, size: 13 * uiScale, color: const Color(0xFFB0ACC2)),
            ],
          ),
          Text('Based on your health profile', style: TextStyle(fontSize: 10.5 * uiScale, color: const Color(0xFF6B6B7B))),
          SizedBox(height: 14 * uiScale),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: items.map((item) => _CompatRow(uiScale: uiScale, item: item)).toList(),
                ),
              ),
              SizedBox(width: 12 * uiScale),
              Container(
                width: 118 * uiScale,
                padding: EdgeInsets.all(12 * uiScale),
                decoration: BoxDecoration(color: const Color(0xFFE4F5E9), borderRadius: BorderRadius.circular(18)),
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: gaugeAnim,
                      builder: (context, _) {
                        final v = (percent * gaugeAnim.value).round();
                        return SizedBox(
                          width: 62 * uiScale,
                          height: 62 * uiScale,
                          child: CustomPaint(
                            painter: _CircularGaugePainter(progress: gaugeAnim.value * (percent / 100), color: const Color(0xFF1E8A4C)),
                            child: Center(
                              child: Text('$v%', style: TextStyle(fontSize: 13.5 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 8 * uiScale),
                    Text('Great Match', textAlign: TextAlign.center, style: TextStyle(fontSize: 11 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1E8A4C))),
                    SizedBox(height: 4 * uiScale),
                    Text(
                      'This food is highly compatible with your health goals.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 9 * uiScale, height: 1.3, color: const Color(0xFF3B3B4F)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompatRow extends StatelessWidget {
  const _CompatRow({required this.uiScale, required this.item});
  final double uiScale;
  final CompatibilityItem item;

  Color get _color => item.rating == 'Excellent' ? const Color(0xFF1E8A4C) : const Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6 * uiScale),
      child: Row(
        children: [
          Icon(item.icon, size: 15 * uiScale, color: const Color(0xFF6C4EF5)),
          SizedBox(width: 8 * uiScale),
          Expanded(
            child: Text(item.label, style: TextStyle(fontSize: 11.5 * uiScale, color: const Color(0xFF3B3B4F))),
          ),
          Text(item.rating, style: TextStyle(fontSize: 10.5 * uiScale, fontWeight: FontWeight.w700, color: _color)),
          SizedBox(width: 3 * uiScale),
          Icon(Icons.check_circle, size: 12 * uiScale, color: _color),
        ],
      ),
    );
  }
}

class _CircularGaugePainter extends CustomPainter {
  _CircularGaugePainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 5;
    final bg = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);

    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, 2 * math.pi * progress, false, fg);
  }

  @override
  bool shouldRepaint(covariant _CircularGaugePainter oldDelegate) => oldDelegate.progress != progress;
}

// ---------------------------------------------------------------------------
// What's Good / Watch Out For
// ---------------------------------------------------------------------------
class _GoodVsWatchRow extends StatelessWidget {
  const _GoodVsWatchRow({required this.uiScale, required this.good, required this.watch});
  final double uiScale;
  final List<ProsConsItem> good;
  final List<ProsConsItem> watch;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ProsConsCard(
            uiScale: uiScale,
            title: "What's Good",
            titleColor: const Color(0xFF1E8A4C),
            bg: const Color(0xFFE9F7EE),
            items: good,
            icon: Icons.check_circle,
            iconColor: const Color(0xFF1E8A4C),
            watermark: Icons.spa_rounded,
          ),
        ),
        SizedBox(width: 12 * uiScale),
        Expanded(
          child: _ProsConsCard(
            uiScale: uiScale,
            title: 'Watch Out For',
            titleColor: const Color(0xFFE0862E),
            bg: const Color(0xFFFCF2E6),
            items: watch,
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFE0862E),
            watermark: Icons.shield_moon_outlined,
          ),
        ),
      ],
    );
  }
}

class _ProsConsCard extends StatelessWidget {
  const _ProsConsCard({
    required this.uiScale,
    required this.title,
    required this.titleColor,
    required this.bg,
    required this.items,
    required this.icon,
    required this.iconColor,
    required this.watermark,
  });

  final double uiScale;
  final String title;
  final Color titleColor;
  final Color bg;
  final List<ProsConsItem> items;
  final IconData icon;
  final Color iconColor;
  final IconData watermark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12 * uiScale),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            bottom: -8,
            child: Icon(watermark, size: 60 * uiScale, color: iconColor.withValues(alpha: 0.12)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12.5 * uiScale, fontWeight: FontWeight.w800, color: titleColor)),
              SizedBox(height: 8 * uiScale),
              ...items.map(
                (item) => Padding(
                  padding: EdgeInsets.only(bottom: 8 * uiScale),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, size: 13 * uiScale, color: iconColor),
                      SizedBox(width: 6 * uiScale),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: TextStyle(fontSize: 10.5 * uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF1B1B2E))),
                            Text(item.subtitle, style: TextStyle(fontSize: 9 * uiScale, color: const Color(0xFF6B6B7B))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Better alternatives
// ---------------------------------------------------------------------------
class _AlternativesSection extends StatelessWidget {
  const _AlternativesSection({
    required this.uiScale,
    required this.items,
    this.onViewAll,
    this.onTap,
  });

  final double uiScale;
  final List<AlternativeProduct> items;
  final VoidCallback? onViewAll;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Better Alternatives for You', style: TextStyle(fontSize: 14.5 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
            const Spacer(),
            GestureDetector(
              onTap: onViewAll,
              child: Row(
                children: [
                  Text('View All', style: TextStyle(fontSize: 12 * uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF6C4EF5))),
                  Icon(Icons.chevron_right, size: 15 * uiScale, color: const Color(0xFF6C4EF5)),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 10 * uiScale),
        Row(
          children: List.generate(items.length, (i) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == items.length - 1 ? 0 : 10 * uiScale),
                child: _AlternativeCard(uiScale: uiScale, item: items[i], onTap: () => onTap?.call(i)),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _AlternativeCard extends StatefulWidget {
  const _AlternativeCard({required this.uiScale, required this.item, this.onTap});
  final double uiScale;
  final AlternativeProduct item;
  final VoidCallback? onTap;

  @override
  State<_AlternativeCard> createState() => _AlternativeCardState();
}

class _AlternativeCardState extends State<_AlternativeCard> {
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
          padding: EdgeInsets.all(10 * widget.uiScale),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 6))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: 1.3,
                  child: Container(
                    color: const Color(0xFFF6F3FC),
                    padding: EdgeInsets.all(4 * widget.uiScale),
                    child: Image.asset(widget.item.asset, fit: BoxFit.contain),
                  ),
                ),
              ),
              SizedBox(height: 6 * widget.uiScale),
              Text(widget.item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11 * widget.uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
              Text(widget.item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9 * widget.uiScale, color: const Color(0xFF9A96A8))),
              SizedBox(height: 4 * widget.uiScale),
              Row(
                children: [
                  Container(width: 5 * widget.uiScale, height: 5 * widget.uiScale, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1E8A4C))),
                  SizedBox(width: 4 * widget.uiScale),
                  Text('${widget.item.score}/100', style: TextStyle(fontSize: 9.5 * widget.uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF1E8A4C))),
                ],
              ),
              SizedBox(height: 3 * widget.uiScale),
              Row(
                children: [
                  Icon(Icons.arrow_upward_rounded, size: 10 * widget.uiScale, color: const Color(0xFF6C4EF5)),
                  Expanded(
                    child: Text(
                      widget.item.differentiator,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 8.5 * widget.uiScale, fontWeight: FontWeight.w600, color: const Color(0xFF6C4EF5)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compare / Add to Pantry / Share
// ---------------------------------------------------------------------------
class _ActionButtonsRow extends StatelessWidget {
  const _ActionButtonsRow({
    required this.uiScale,
    this.onCompareTap,
    this.onAddToPantryTap,
    this.onShareTap,
  });

  final double uiScale;
  final VoidCallback? onCompareTap;
  final VoidCallback? onAddToPantryTap;
  final VoidCallback? onShareTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _OutlineActionButton(uiScale: uiScale, icon: Icons.compare_arrows_rounded, label: 'Compare', onTap: onCompareTap),
        ),
        SizedBox(width: 10 * uiScale),
        Expanded(
          flex: 2,
          child: _PrimaryActionButton(uiScale: uiScale, icon: Icons.add, label: 'Add to Pantry', subtitle: 'Save for meal planning', onTap: onAddToPantryTap),
        ),
        SizedBox(width: 10 * uiScale),
        Expanded(
          child: _OutlineActionButton(uiScale: uiScale, icon: Icons.ios_share_rounded, label: 'Share', onTap: onShareTap),
        ),
      ],
    );
  }
}

class _OutlineActionButton extends StatefulWidget {
  const _OutlineActionButton({required this.uiScale, required this.icon, required this.label, this.onTap});
  final double uiScale;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  State<_OutlineActionButton> createState() => _OutlineActionButtonState();
}

class _OutlineActionButtonState extends State<_OutlineActionButton> {
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
          padding: EdgeInsets.symmetric(vertical: 12 * widget.uiScale),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E0F2)),
          ),
          child: Column(
            children: [
              Icon(widget.icon, size: 17 * widget.uiScale, color: const Color(0xFF6C4EF5)),
              SizedBox(height: 4 * widget.uiScale),
              Text(widget.label, style: TextStyle(fontSize: 10.5 * widget.uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF1B1B2E))),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatefulWidget {
  const _PrimaryActionButton({
    required this.uiScale,
    required this.icon,
    required this.label,
    required this.subtitle,
    this.onTap,
  });

  final double uiScale;
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  State<_PrimaryActionButton> createState() => _PrimaryActionButtonState();
}

class _PrimaryActionButtonState extends State<_PrimaryActionButton> {
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
          padding: EdgeInsets.symmetric(vertical: 10 * widget.uiScale, horizontal: 8 * widget.uiScale),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(colors: [Color(0xFF6C4EF5), Color(0xFF1E8A4C)]),
            boxShadow: [BoxShadow(color: const Color(0xFF6C4EF5).withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 8))],
          ),
          child: Column(
            children: [
              Icon(widget.icon, size: 17 * widget.uiScale, color: Colors.white),
              SizedBox(height: 2 * widget.uiScale),
              Text(widget.label, style: TextStyle(fontSize: 11 * widget.uiScale, fontWeight: FontWeight.w800, color: Colors.white)),
              Text(widget.subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 8 * widget.uiScale, color: Colors.white.withValues(alpha: 0.85))),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick actions
// ---------------------------------------------------------------------------
class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.uiScale,
    this.onAskAiCoachTap,
    this.onGenerateRecipeTap,
    this.onShoppingSuggestionTap,
  });

  final double uiScale;
  final VoidCallback? onAskAiCoachTap;
  final VoidCallback? onGenerateRecipeTap;
  final VoidCallback? onShoppingSuggestionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionTile(
            uiScale: uiScale,
            icon: Icons.smart_toy_outlined,
            color: const Color(0xFF6C4EF5),
            title: 'Ask AI Coach',
            subtitle: 'Get personalized tips',
            onTap: onAskAiCoachTap,
          ),
        ),
        SizedBox(width: 10 * uiScale),
        Expanded(
          child: _QuickActionTile(
            uiScale: uiScale,
            icon: Icons.ramen_dining_outlined,
            color: const Color(0xFF1E8A4C),
            title: 'Generate Recipe',
            subtitle: 'View healthy recipes',
            onTap: onGenerateRecipeTap,
          ),
        ),
        SizedBox(width: 10 * uiScale),
        Expanded(
          child: _QuickActionTile(
            uiScale: uiScale,
            icon: Icons.shopping_bag_outlined,
            color: const Color(0xFFE0862E),
            title: 'Shopping Suggestion',
            subtitle: 'Get better options',
            onTap: onShoppingSuggestionTap,
          ),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatefulWidget {
  const _QuickActionTile({
    required this.uiScale,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final double uiScale;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile> {
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
          padding: EdgeInsets.symmetric(vertical: 12 * widget.uiScale, horizontal: 6 * widget.uiScale),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E0F2)),
          ),
          child: Column(
            children: [
              Icon(widget.icon, size: 18 * widget.uiScale, color: widget.color),
              SizedBox(height: 5 * widget.uiScale),
              Text(widget.title, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9.5 * widget.uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF1B1B2E))),
              Text(widget.subtitle, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 8 * widget.uiScale, color: const Color(0xFF9A96A8))),
            ],
          ),
        ),
      ),
    );
  }
}
