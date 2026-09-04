import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../ai/ai_recommendation_screen.dart';
import 'package:diet_compass/features/scan/compare_screen.dart';
import '../recipe_generator/recipe_generator_screen.dart';
import '../../core/model/food_product.dart';
import '../../core/model/ai_analysis_model.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/pantry_storage_service.dart';
import '../../core/services/recommendation_service.dart';
import '../../core/services/scan_history_service.dart';

import '../../core/services/ingredient_intelligence_service.dart';
import '../../core/services/product_category_service.dart';
import 'services/product_share_service.dart';
import 'widgets/product_share_card.dart';
import 'widgets/product_ai_coach_sheet.dart';

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
class NutrientStat {
  const NutrientStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.badge,
    this.isAvailable = true,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final String badge; // e.g. "Good", "Excellent", "Low", "Unavailable"
  final bool isAvailable;
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

int _calculateScore(FoodProduct product) {
  return RecommendationService.instance.calculateNutritionScore(product);
}

int _calculateCompatibility(FoodProduct product) {
  return RecommendationService.instance.calculateCompatibilityScore(product);
}

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,

    // NEW: actual scanned product
    required this.product,
    this.productImage,
    this.initialCompatibility,

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
  final ProductCompatibility? initialCompatibility;

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
  bool _isInPantry = false;
  ProductAiAnalysis? _aiAnalysis;
  ProductCompatibility? _compatibility;
  List<PersonalizedRecommendation> _recommendations = [];
  final GlobalKey _shareCardKey = GlobalKey();
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    // SINGLE SOURCE OF TRUTH: Initialize compatibility immediately so score never jumps/flickers
    _compatibility = widget.initialCompatibility ??
        RecommendationService.instance.evaluateCompatibility(widget.product);
    _checkPantryStatus();
    _saveToScanHistory();
    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..forward();
    _ambientCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat(reverse: true);
    _loadAiIntelligence();
  }

  Future<void> _saveToScanHistory() async {
    try {
      final score = _compatibility?.score ?? _calculateScore(widget.product);
      await ScanHistoryService.instance.saveScan(widget.product, score: score);
    } catch (e) {
      debugPrint('[ResultScreen] Error saving scan history: $e');
    }
  }

  Future<void> _checkPantryStatus() async {
    final inPantry = await PantryStorageService.instance.isProductInPantry(widget.product);
    if (mounted) {
      setState(() => _isInPantry = inPantry);
    }
  }

  Future<void> _handleShare() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final overallScore = _calculateScore(widget.product);
      final compatibilityScore = _compatibility?.score ?? _calculateCompatibility(widget.product);
      final nutrients = _buildNutrients(widget.product);
      final compatibility = _buildCompatibility(widget.product);
      final goodPoints = _buildGoodPoints(widget.product);
      final watchPoints = _buildWatchPoints(widget.product);
      final recommendation = _aiAnalysis?.summary.trim().isNotEmpty == true
          ? _aiAnalysis!.summary.trim()
          : (_compatibility?.recommendation.trim().isNotEmpty == true
              ? _compatibility!.recommendation.trim()
              : (overallScore >= 70
                  ? 'Great product choice aligning well with your dietary guidelines and nutrient profile.'
                  : 'Consider enjoying in moderation or pairing with whole foods to balance nutrition.'));

      await ProductShareService.instance.shareProductAnalysis(
        context: context,
        product: widget.product,
        overallScore: overallScore,
        compatibilityScore: compatibilityScore,
        nutrients: nutrients,
        compatibility: compatibility,
        goodPoints: goodPoints,
        watchPoints: watchPoints,
        aiRecommendation: recommendation,
        boundaryKey: _shareCardKey,
      );
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _handleCompare() async {
    FoodProduct? bestAlt;
    ProductCompatibility? altComp;
    ProductNutritionComparison? nutrComp;

    if (_recommendations.isNotEmpty) {
      final top = _recommendations.first;
      bestAlt = top.product;
      altComp = top.compatibility;
      nutrComp = top.nutritionComparison;
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompareScreen(
          currentProduct: widget.product,
          currentProductImage: widget.productImage,
          alternativeProduct: bestAlt,
          alternativeCompatibility: altComp,
          nutritionComparison: nutrComp,
        ),
      ),
    );
  }

  Future<void> _addToPantry() async {
    if (_isInPantry) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.product.name} is already in your pantry ✓'),
          backgroundColor: const Color(0xFF1E8A4C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    await PantryStorageService.instance.addProduct(widget.product);
    if (!mounted) return;
    setState(() => _isInPantry = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${widget.product.name} added to your pantry ✓',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E8A4C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _handleGenerateRecipe() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeGeneratorScreen(
          sourceProduct: widget.product,
          initialProduct: widget.product,
        ),
      ),
    );
  }

  void _handleAskAiCoach() {
    ProductAiCoachSheet.show(
      context,
      product: widget.product,
      compatibility: widget.initialCompatibility ?? _compatibility,
      overallScore: _calculateScore(widget.product),
      goodPoints: _buildGoodPoints(widget.product).map((p) => p.title).toList(),
      watchPoints: _buildWatchPoints(widget.product).map((p) => p.title).toList(),
      alternatives: _aiAnalysis?.healthierAlternatives ?? const [],
    );
  }

  Future<void> _loadAiIntelligence() async {
    try {
      final res = await AiService.instance.analyzeProduct(widget.product);
      if (mounted) {
        // Strict category validation: filter any cross-category recommendations (cap to 3 for ResultScreen)
        final validAiRecs = res.recommendations.where((r) {
          return ProductCategoryService.instance.isProductSimilarCategory(widget.product, r.product);
        }).take(3).toList();

        setState(() {
          _aiAnalysis = res.analysis;
          // CRITICAL: Preserve single source of truth compatibility from RecommendationService
          // Never overwrite client's personalized calculation with backend's separate calculation
          _compatibility ??= res.compatibility;
          _recommendations = validAiRecs;
        });
      }
    } catch (_) {
      // Graceful fallback
    }

    // If recommendations are empty, query real category-aware alternatives dynamically (1-3 for ResultScreen)
    if (_recommendations.isEmpty) {
      try {
        final dynamicRecs = await RecommendationService.instance.getCategoryAwareAlternatives(widget.product, limit: 3);
        if (mounted && dynamicRecs.isNotEmpty) {
          setState(() => _recommendations = dynamicRecs.take(3).toList());
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _ambientCtrl.dispose();
    super.dispose();
  }

 List<NutrientStat> _buildNutrients(FoodProduct product) {
  final nutrients = <NutrientStat>[];

  // 1. Calories
  if (product.calories == null) {
    nutrients.add(
      const NutrientStat(
        label: 'Calories',
        value: 'Unavailable',
        unit: '',
        icon: Icons.local_fire_department,
        color: Color(0xFF9A96A8),
        badge: 'Unknown',
        isAvailable: false,
      ),
    );
  } else {
    final calories = product.calories!;
    String caloriesBadge;
    Color color = const Color(0xFF6C4EF5);
    if (calories <= 100) {
      caloriesBadge = 'Low';
      color = const Color(0xFF1E8A4C);
    } else if (calories <= 250) {
      caloriesBadge = 'Moderate';
    } else if (calories <= 400) {
      caloriesBadge = 'High';
      color = const Color(0xFFE0862E);
    } else {
      caloriesBadge = 'Very High';
      color = const Color(0xFFE0525C);
    }
    nutrients.add(
      NutrientStat(
        label: 'Calories',
        value: calories.toStringAsFixed(0),
        unit: 'kcal',
        icon: Icons.local_fire_department,
        color: color,
        badge: caloriesBadge,
        isAvailable: true,
      ),
    );
  }

  // 2. Protein
  if (product.protein == null) {
    nutrients.add(
      const NutrientStat(
        label: 'Protein',
        value: 'Unavailable',
        unit: '',
        icon: Icons.fitness_center,
        color: Color(0xFF9A96A8),
        badge: 'Unknown',
        isAvailable: false,
      ),
    );
  } else {
    final protein = product.protein!;
    String proteinBadge;
    Color color = const Color(0xFF1E8A4C);
    if (protein >= 10) {
      proteinBadge = 'High';
    } else if (protein >= 5) {
      proteinBadge = 'Good';
    } else if (protein >= 2) {
      proteinBadge = 'Moderate';
    } else {
      proteinBadge = 'Low';
      color = const Color(0xFF9A96A8);
    }
    nutrients.add(
      NutrientStat(
        label: 'Protein',
        value: protein.toStringAsFixed(1),
        unit: 'g',
        icon: Icons.fitness_center,
        color: color,
        badge: proteinBadge,
        isAvailable: true,
      ),
    );
  }

  // 3. Carbohydrates
  if (product.carbohydrates == null) {
    nutrients.add(
      const NutrientStat(
        label: 'Carbs',
        value: 'Unavailable',
        unit: '',
        icon: Icons.grain,
        color: Color(0xFF9A96A8),
        badge: 'Unknown',
        isAvailable: false,
      ),
    );
  } else {
    final carbs = product.carbohydrates!;
    String carbsBadge;
    Color color = const Color(0xFFE0862E);
    if (carbs < 20) {
      carbsBadge = 'Low';
      color = const Color(0xFF1E8A4C);
    } else if (carbs <= 50) {
      carbsBadge = 'Moderate';
    } else if (carbs <= 70) {
      carbsBadge = 'High';
    } else {
      carbsBadge = 'Very High';
      color = const Color(0xFFE0525C);
    }
    nutrients.add(
      NutrientStat(
        label: 'Carbs',
        value: carbs.toStringAsFixed(1),
        unit: 'g',
        icon: Icons.grain,
        color: color,
        badge: carbsBadge,
        isAvailable: true,
      ),
    );
  }

  // 4. Sugar (Strict: distinguish true 0.0g from null / missing)
  if (product.sugar == null) {
    nutrients.add(
      const NutrientStat(
        label: 'Sugar',
        value: 'Unavailable',
        unit: '',
        icon: Icons.icecream,
        color: Color(0xFF9A96A8),
        badge: 'Unknown',
        isAvailable: false,
      ),
    );
  } else {
    final sugar = product.sugar!;
    String sugarBadge;
    Color color;
    if (sugar <= 0.5) {
      sugarBadge = 'Zero Sugar';
      color = const Color(0xFF1E8A4C);
    } else if (sugar <= 5) {
      sugarBadge = 'Low Sugar';
      color = const Color(0xFF1E8A4C);
    } else if (sugar <= 12) {
      sugarBadge = 'Moderate';
      color = const Color(0xFFE0862E);
    } else {
      sugarBadge = 'High Sugar';
      color = const Color(0xFFE0525C);
    }
    nutrients.add(
      NutrientStat(
        label: 'Sugar',
        value: sugar.toStringAsFixed(1),
        unit: 'g',
        icon: Icons.icecream,
        color: color,
        badge: sugarBadge,
        isAvailable: true,
      ),
    );
  }

  // 5. Fat
  if (product.fat == null) {
    nutrients.add(
      const NutrientStat(
        label: 'Fat',
        value: 'Unavailable',
        unit: '',
        icon: Icons.opacity,
        color: Color(0xFF9A96A8),
        badge: 'Unknown',
        isAvailable: false,
      ),
    );
  } else {
    final fat = product.fat!;
    String fatBadge;
    Color color = const Color(0xFFE0862E);
    if (fat <= 3) {
      fatBadge = 'Low';
      color = const Color(0xFF1E8A4C);
    } else if (fat <= 10) {
      fatBadge = 'Moderate';
    } else if (fat <= 20) {
      fatBadge = 'High';
    } else {
      fatBadge = 'Very High';
      color = const Color(0xFFE0525C);
    }
    nutrients.add(
      NutrientStat(
        label: 'Fat',
        value: fat.toStringAsFixed(1),
        unit: 'g',
        icon: Icons.opacity,
        color: color,
        badge: fatBadge,
        isAvailable: true,
      ),
    );
  }

  // 6. Fiber
  if (product.fiber == null) {
    nutrients.add(
      const NutrientStat(
        label: 'Fiber',
        value: 'Unavailable',
        unit: '',
        icon: Icons.eco_outlined,
        color: Color(0xFF9A96A8),
        badge: 'Unknown',
        isAvailable: false,
      ),
    );
  } else {
    final fiber = product.fiber!;
    String fiberBadge;
    Color color = const Color(0xFF1E8A4C);
    if (fiber >= 6) {
      fiberBadge = 'High';
    } else if (fiber >= 3) {
      fiberBadge = 'Good';
    } else {
      fiberBadge = 'Low';
      color = const Color(0xFF9A96A8);
    }
    nutrients.add(
      NutrientStat(
        label: 'Fiber',
        value: fiber.toStringAsFixed(1),
        unit: 'g',
        icon: Icons.eco_outlined,
        color: color,
        badge: fiberBadge,
        isAvailable: true,
      ),
    );
  }

  // 7. Sodium
  if (product.sodium == null) {
    nutrients.add(
      const NutrientStat(
        label: 'Sodium',
        value: 'Unavailable',
        unit: '',
        icon: Icons.water_drop_outlined,
        color: Color(0xFF9A96A8),
        badge: 'Unknown',
        isAvailable: false,
      ),
    );
  } else {
    final rawSodium = product.sodium!;
    final sodiumMg = rawSodium <= 10.0 ? rawSodium * 1000.0 : rawSodium;
    String sodiumBadge;
    Color color = const Color(0xFF3B82F6);
    if (sodiumMg <= 140) {
      sodiumBadge = 'Low';
      color = const Color(0xFF1E8A4C);
    } else if (sodiumMg <= 400) {
      sodiumBadge = 'Moderate';
    } else if (sodiumMg <= 800) {
      sodiumBadge = 'High';
      color = const Color(0xFFE0862E);
    } else {
      sodiumBadge = 'Very High';
      color = const Color(0xFFE0525C);
    }
    nutrients.add(
      NutrientStat(
        label: 'Sodium',
        value: sodiumMg.toStringAsFixed(0),
        unit: 'mg',
        icon: Icons.water_drop_outlined,
        color: color,
        badge: sodiumBadge,
        isAvailable: true,
      ),
    );
  }

  return nutrients;
}

List<CompatibilityItem> _buildCompatibility(FoodProduct product) {
  if (_compatibility != null && _compatibility!.items.isNotEmpty) {
    return _compatibility!.items.map((item) {
      IconData icon = Icons.health_and_safety_outlined;
      final lower = item.label.toLowerCase();
      if (lower.contains('diet')) {
        icon = Icons.restaurant_outlined;
      } else if (lower.contains('allergy') || lower.contains('safe')) {
        icon = Icons.shield_outlined;
      } else if (lower.contains('goal') || lower.contains('weight') || lower.contains('muscle')) {
        icon = Icons.flag_outlined;
      } else if (lower.contains('nutrient') || lower.contains('balance') || lower.contains('sugar')) {
        icon = Icons.insights_outlined;
      }
      return CompatibilityItem(
        icon: icon,
        label: item.label,
        rating: item.rating,
      );
    }).toList();
  }

  final calories = product.calories ?? 0.0;
  final rawSodium = product.sodium ?? 0.0;
  final sodium = rawSodium <= 10.0 ? rawSodium * 1000.0 : rawSodium;
  final sugar = product.sugar ?? 0.0;
  final fiber = product.fiber ?? 0.0;

  return [
    CompatibilityItem(
      icon: Icons.monitor_weight_outlined,
      label: 'Weight Management',
      rating: product.calories != null && calories <= 220 ? 'Good' : 'Consider',
    ),
    CompatibilityItem(
      icon: Icons.favorite_outline,
      label: 'Heart Health',
      rating: product.sodium != null && sodium <= 400 ? 'Good' : 'Consider',
    ),
    CompatibilityItem(
      icon: Icons.water_drop_outlined,
      label: 'Blood Sugar Control',
      rating: product.sugar != null && sugar <= 5 ? 'Good' : 'Consider',
    ),
    CompatibilityItem(
      icon: Icons.eco_outlined,
      label: 'Digestive Health',
      rating: product.fiber != null && fiber >= 3 ? 'Excellent' : 'Good',
    ),
  ];
}

List<ProsConsItem> _buildGoodPoints(FoodProduct product) {
  final points = <ProsConsItem>[];

  if (_aiAnalysis != null && _aiAnalysis!.pros.isNotEmpty) {
    for (final pro in _aiAnalysis!.pros) {
      points.add(
        ProsConsItem(
          title: pro,
          subtitle: 'AI Verified Nutritional Benefit',
        ),
      );
    }
    return points;
  }

  if (product.fiber != null && product.fiber! >= 3) {
    points.add(
      const ProsConsItem(
        title: 'Good source of fiber',
        subtitle: 'Supports digestive health',
      ),
    );
  }

  if (product.sugar != null && product.sugar! <= 5) {
    points.add(
      const ProsConsItem(
        title: 'Low in sugar',
        subtitle: 'Contains relatively little sugar',
      ),
    );
  }

  if (product.protein != null && product.protein! >= 5) {
    points.add(
      const ProsConsItem(
        title: 'Good protein content',
        subtitle: 'Provides a useful amount of protein',
      ),
    );
  }

  if (points.isEmpty) {
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
  final points = <ProsConsItem>[];

  if (_aiAnalysis != null) {
    for (final warning in _aiAnalysis!.allergenWarnings) {
      points.add(
        ProsConsItem(
          title: '⚠️ Allergen Alert',
          subtitle: warning,
        ),
      );
    }
    for (final sugar in _aiAnalysis!.disguisedSugars) {
      points.add(
        ProsConsItem(
          title: 'Hidden Sugar: ${sugar.name}',
          subtitle: sugar.description,
        ),
      );
    }
    for (final additive in _aiAnalysis!.harmfulAdditives) {
      points.add(
        ProsConsItem(
          title: 'Additive Concern: ${additive.name}',
          subtitle: additive.concern,
        ),
      );
    }
    for (final claim in _aiAnalysis!.claimVerifications) {
      points.add(
        ProsConsItem(
          title: 'Claim "${claim.claim}": ${claim.status}',
          subtitle: claim.explanation,
        ),
      );
    }
    if (points.isNotEmpty) return points;
  }

  if (product.sugar != null && product.sugar! > 10) {
    points.add(
      const ProsConsItem(
        title: 'High in sugar',
        subtitle: 'Consider limiting frequent consumption',
      ),
    );
  }

  if (product.sodium != null) {
    final raw = product.sodium!;
    final mg = raw <= 10.0 ? raw * 1000.0 : raw;
    if (mg > 400) {
      points.add(
        const ProsConsItem(
          title: 'Higher sodium',
          subtitle: 'Consider your overall sodium intake',
        ),
      );
    }
  }

  if (product.fat != null && product.fat! > 20) {
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

    final intel = IngredientIntelligenceService.instance.analyze(widget.product);
    final colors = context.dcColors;

    return Scaffold(
      backgroundColor: colors.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _BackgroundGradient(),
          // Hidden offscreen RepaintBoundary for generating high-definition share cards
          Positioned(
            left: -99999,
            top: -99999,
            child: RepaintBoundary(
              key: _shareCardKey,
              child: SizedBox(
                width: 420,
                child: Material(
                  type: MaterialType.transparency,
                  child: ProductShareCard(
                    product: widget.product,
                    overallScore: _calculateScore(widget.product),
                    compatibilityScore: _compatibility?.score ?? _calculateCompatibility(widget.product),
                    nutrients: _buildNutrients(widget.product),
                    compatibility: _buildCompatibility(widget.product),
                    goodPoints: _buildGoodPoints(widget.product),
                    watchPoints: _buildWatchPoints(widget.product),
                    aiRecommendation: _aiAnalysis?.summary.trim().isNotEmpty == true
                        ? _aiAnalysis!.summary.trim()
                        : (_compatibility?.recommendation.trim().isNotEmpty == true
                            ? _compatibility!.recommendation.trim()
                            : (_calculateScore(widget.product) >= 70
                                ? 'Great product choice aligning well with your dietary guidelines and nutrient profile.'
                                : 'Consider enjoying in moderation or pairing with whole foods to balance nutrition.')),
                    productImage: widget.productImage,
                  ),
                ),
              ),
            ),
          ),
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
                      compatibility: _compatibility,
                      onAskAiTap: widget.onAskAiTap,
                    ),
                  ),
                ),
                SizedBox(height: 20 * scale),

                FadeTransition(
                  opacity: _fade(0.16, 0.52),
                  child: SlideTransition(
                    position: _slide(0.16, 0.54),
                    child: _NutritionSnapshot(
                      uiScale: scale,
                      nutrients: _buildNutrients(widget.product),
                      basisLabel: widget.product.normalizedBasisLabel,
                    ),
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
                      percent: _compatibility?.score ?? _calculateCompatibility(widget.product),
                      compatibility: _compatibility,
                    ),
                  ),
                ),

                if (intel.hasMeaningfulInsights) ...[
                  SizedBox(height: 16 * scale),
                  FadeTransition(
                    opacity: _fade(0.26, 0.63),
                    child: SlideTransition(
                      position: _slide(0.26, 0.65),
                      child: _IngredientIntelligenceSection(
                        uiScale: scale,
                        intelligence: intel,
                      ),
                    ),
                  ),
                ],

                if (intel.hasClaimChecks) ...[
                  SizedBox(height: 16 * scale),
                  FadeTransition(
                    opacity: _fade(0.28, 0.65),
                    child: SlideTransition(
                      position: _slide(0.28, 0.67),
                      child: _ClaimCheckSection(
                        uiScale: scale,
                        claimChecks: intel.claimChecks,
                      ),
                    ),
                  ),
                ],

                if (widget.product.discrepancies.isNotEmpty) ...[
                  SizedBox(height: 16 * scale),
                  FadeTransition(
                    opacity: _fade(0.30, 0.67),
                    child: SlideTransition(
                      position: _slide(0.30, 0.69),
                      child: _DiscrepancyAlertSection(
                        uiScale: scale,
                        discrepancies: widget.product.discrepancies,
                      ),
                    ),
                  ),
                ],

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
                      recommendations: _recommendations,
                      onViewAll: widget.onViewAllAlternatives,
                      onTap: widget.onAlternativeTap,
                      onRecommendationTap: (rec) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ResultScreen(
                              product: rec.product,
                              initialCompatibility: rec.compatibility,
                            ),
                          ),
                        );
                      },
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
                      isInPantry: _isInPantry,
                      onCompareTap: widget.onCompareTap ?? _handleCompare,
                      onAddToPantryTap: widget.onAddToPantryTap ?? _addToPantry,
                      onShareTap: widget.onShareTap ?? _handleShare,
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
                      onAskAiCoachTap: widget.onAskAiCoachTap ?? _handleAskAiCoach,
                      onGenerateRecipeTap: widget.onGenerateRecipeTap ?? _handleGenerateRecipe,
                      onShoppingSuggestionTap: widget.onShoppingSuggestionTap ?? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AiShoppingScreen(
                              referenceProduct: widget.product,
                            ),
                          ),
                        );
                      },
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
    final colors = context.dcColors;
    if (colors.isDark) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF13111C), Color(0xFF0D0C14)],
          ),
        ),
      );
    }
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
    final colors = context.dcColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color ?? colors.surface.withValues(alpha: colors.isDark ? 0.90 : 0.72),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: colors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: colors.isDark ? 0.20 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
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
    final colors = context.dcColors;
    return Row(
      children: [
        _RoundGlassButton(
          uiScale: uiScale,
          icon: Icons.arrow_back,
          iconColor: colors.textPrimary,
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
                  Icon(Icons.auto_awesome, size: 16 * uiScale, color: colors.iconPurple),
                  SizedBox(width: 6 * uiScale),
                  Text(
                    'AI Result',
                    style: TextStyle(fontSize: 17 * uiScale, fontWeight: FontWeight.w800, color: colors.textPrimary),
                  ),
                ],
              ),
              Text(
                "Here's what we found for you",
                style: TextStyle(fontSize: 11 * uiScale, color: colors.textSecondary),
              ),
            ],
          ),
        ),
        _RoundGlassButton(
          uiScale: uiScale,
          icon: favorited ? Icons.favorite : Icons.favorite_border,
          iconColor: favorited ? const Color(0xFFE0525C) : colors.textPrimary,
          onTap: onFavoriteTap,
        ),
        SizedBox(width: 8 * uiScale),
        _RoundGlassButton(uiScale: uiScale, icon: Icons.more_horiz, iconColor: colors.textPrimary, onTap: onMoreTap),
      ],
    );
  }
}

class _RoundGlassButton extends StatefulWidget {
  const _RoundGlassButton({
    required this.uiScale,
    required this.icon,
    this.iconColor,
    this.onTap,
  });

  final double uiScale;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  State<_RoundGlassButton> createState() => _RoundGlassButtonState();
}

class _RoundGlassButtonState extends State<_RoundGlassButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    final effIconColor = widget.iconColor ?? colors.textPrimary;
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
            color: colors.surface,
            border: Border.all(color: colors.cardBorder),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: colors.isDark ? 0.20 : 0.06), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Icon(widget.icon, size: 17 * widget.uiScale, color: effIconColor),
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
    final colors = context.dcColors;
    final gaugeAnim = CurvedAnimation(
      parent: entranceCtrl,
      curve: const Interval(
        0.1,
        0.7,
        curve: Curves.easeOutCubic,
      ),
    );

    final ImageProvider? productImage = image ??
        (product.imageUrl.trim().isNotEmpty
            ? (product.imageUrl.startsWith('assets/')
                ? AssetImage(product.imageUrl) as ImageProvider
                : NetworkImage(product.imageUrl) as ImageProvider)
            : null);

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
              color: colors.surfaceSecondary,
              padding: EdgeInsets.all(6 * uiScale),
              child: productImage != null
                  ? Image(
                      image: productImage,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return Icon(
                          Icons.fastfood_outlined,
                          size: 34 * uiScale,
                          color: colors.textMuted,
                        );
                      },
                    )
                  : Icon(
                      Icons.fastfood_outlined,
                      size: 34 * uiScale,
                      color: colors.textMuted,
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
                    color: colors.textPrimary,
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
                      color: colors.textSecondary,
                    ),
                  ),
                ],

                SizedBox(height: 7 * uiScale),

                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6 * uiScale,
                  runSpacing: 4 * uiScale,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.eco,
                          size: 12 * uiScale,
                          color: colors.iconGreen,
                        ),
                        SizedBox(width: 4 * uiScale),
                        Text(
                          'Scanned Product',
                          style: TextStyle(
                            fontSize: 10.5 * uiScale,
                            fontWeight: FontWeight.w700,
                            color: colors.iconGreen,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6 * uiScale, vertical: 2 * uiScale),
                      decoration: BoxDecoration(
                        color: product.dataConfidence == DataConfidence.high
                            ? const Color(0xFFE4F5E9)
                            : (product.dataConfidence == DataConfidence.moderate
                                ? const Color(0xFFFEF3E2)
                                : const Color(0xFFFDE8E8)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5 * uiScale,
                            height: 5 * uiScale,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: product.dataConfidence == DataConfidence.high
                                  ? const Color(0xFF1E8A4C)
                                  : (product.dataConfidence == DataConfidence.moderate
                                      ? const Color(0xFFD97706)
                                      : const Color(0xFFE0525C)),
                            ),
                          ),
                          SizedBox(width: 3.5 * uiScale),
                          Text(
                            '${product.dataConfidence.label} Confidence',
                            style: TextStyle(
                              fontSize: 8.5 * uiScale,
                              fontWeight: FontWeight.w700,
                              color: product.dataConfidence == DataConfidence.high
                                  ? const Color(0xFF1E8A4C)
                                  : (product.dataConfidence == DataConfidence.moderate
                                      ? const Color(0xFFD97706)
                                      : const Color(0xFFE0525C)),
                            ),
                          ),
                        ],
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
                      color: colors.textMuted,
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
                          color: colors.textMuted,
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
                          trackColor: colors.divider,
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
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '/100',
                                  style: TextStyle(
                                    fontSize: 9 * uiScale,
                                    color: colors.textMuted,
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
                        color: colors.textSecondary,
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
                          color: colors.iconGreenBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Nutri-Score ${product.nutriScore!.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 8.5 * uiScale,
                            fontWeight: FontWeight.w700,
                            color: colors.iconGreen,
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
  _RainbowGaugePainter({required this.progress, this.trackColor = const Color(0xFFEDEAF7)});
  final double progress;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 7);
    final radius = size.width / 2 - 6;
    final bg = Paint()
      ..color = trackColor
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
  bool shouldRepaint(covariant _RainbowGaugePainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.trackColor != trackColor;
}

// ---------------------------------------------------------------------------
// Great choice banner
// ---------------------------------------------------------------------------
class _GreatChoiceBanner extends StatelessWidget {
  const _GreatChoiceBanner({
    required this.uiScale,
    required this.ambientCtrl,
    required this.product,
    this.compatibility,
    this.onAskAiTap,
  });

  final double uiScale;
  final AnimationController ambientCtrl;
  final FoodProduct product;
  final ProductCompatibility? compatibility;
  final VoidCallback? onAskAiTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    final score = compatibility?.score ?? _calculateCompatibility(product);
    final hasAllergyAlert = compatibility != null && compatibility!.allergyAlerts.isNotEmpty;
    final hasDietAlert = compatibility != null && compatibility!.dietaryAlerts.isNotEmpty;

    final String title;
    final String message;

    if (hasAllergyAlert) {
      title = 'Allergen Alert ⚠️';
      message = compatibility!.allergyAlerts.first;
    } else if (hasDietAlert) {
      title = 'Diet Conflict ⚠️';
      message = compatibility!.dietaryAlerts.first;
    } else if (score >= 80) {
      title = 'Great choice! 🎉';
      message = compatibility?.summary.isNotEmpty == true
          ? compatibility!.summary
          : 'This product fits well with your health profile.';
    } else if (score >= 60) {
      title = 'Good option 👍';
      message = compatibility?.summary.isNotEmpty == true
          ? compatibility!.summary
          : 'This product can fit your diet when consumed in moderation.';
    } else {
      title = 'Take a closer look 👀';
      message = compatibility?.summary.isNotEmpty == true
          ? compatibility!.summary
          : 'This product may not be the best fit for your health goals.';
    }

    final isAlert = hasAllergyAlert || hasDietAlert;

    return _GlassCard(
      color: isAlert
          ? (colors.isDark ? const Color(0xFF331616).withValues(alpha: 0.9) : const Color(0xFFFDE8E8).withValues(alpha: 0.9))
          : (colors.isDark ? const Color(0xFF221A38).withValues(alpha: 0.85) : const Color(0xFFF1ECFB).withValues(alpha: 0.85)),
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.surface,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/robot_badge.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => Icon(
                    isAlert ? Icons.warning_amber_rounded : Icons.smart_toy_outlined,
                    size: 32 * uiScale,
                    color: isAlert ? const Color(0xFFE0525C) : colors.iconPurple,
                  ),
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
                        color: isAlert ? const Color(0xFFE0525C) : colors.iconPurple,
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
                    color: isAlert ? (colors.isDark ? const Color(0xFFFCA5A5) : const Color(0xFF9B2C2C)) : colors.textSecondary,
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
    final colors = context.dcColors;
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
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline_rounded, size: 13 * widget.uiScale, color: colors.iconPurple),
              SizedBox(width: 5 * widget.uiScale),
              Text('Ask AI', style: TextStyle(fontSize: 11.5 * widget.uiScale, fontWeight: FontWeight.w700, color: colors.iconPurple)),
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
  const _NutritionSnapshot({
    required this.uiScale,
    required this.nutrients,
    this.basisLabel = 'Per 100 g',
  });
  final double uiScale;
  final List<NutrientStat> nutrients;
  final String basisLabel;

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
    final colors = context.dcColors;
    final dotCount = (widget.nutrients.length / 2).ceil().clamp(1, 6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.graphic_eq_rounded, size: 15 * widget.uiScale, color: colors.iconPurple),
            SizedBox(width: 6 * widget.uiScale),
            Text('Nutrition Snapshot', style: TextStyle(fontSize: 14.5 * widget.uiScale, fontWeight: FontWeight.w800, color: colors.textPrimary)),
            SizedBox(width: 4 * widget.uiScale),
            Icon(Icons.info_outline, size: 13 * widget.uiScale, color: colors.textMuted),
            const Spacer(),
            Text(widget.basisLabel, style: TextStyle(fontSize: 10.5 * widget.uiScale, color: colors.textSecondary)),
          ],
        ),
        SizedBox(height: 10 * widget.uiScale),
        SizedBox(
          height: 138 * widget.uiScale,
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
                color: isActiveDot ? colors.iconPurple : colors.divider,
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
    final colors = context.dcColors;
    return Container(
      width: 100 * uiScale,
      padding: EdgeInsets.symmetric(horizontal: 9 * uiScale, vertical: 6 * uiScale),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.20 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(stat.icon, size: 15 * uiScale, color: stat.color),
          SizedBox(height: 6 * uiScale),
          Text(
            stat.label,
            style: TextStyle(
              fontSize: 10.5 * uiScale,
              color: colors.textSecondary,
            ),
          ),
          if (stat.isAvailable)
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: stat.value,
                    style: TextStyle(
                      fontSize: 14.5 * uiScale,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (stat.unit.isNotEmpty)
                    TextSpan(
                      text: ' ${stat.unit}',
                      style: TextStyle(
                        fontSize: 9 * uiScale,
                        color: colors.textMuted,
                      ),
                    ),
                ],
              ),
            )
          else
            Padding(
              padding: EdgeInsets.symmetric(vertical: 2 * uiScale),
              child: Text(
                'Unavailable',
                style: TextStyle(
                  fontSize: 10.5 * uiScale,
                  fontWeight: FontWeight.w700,
                  color: colors.textMuted,
                ),
              ),
            ),
          SizedBox(height: 4 * uiScale),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6 * uiScale, vertical: 2 * uiScale),
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              stat.badge,
              style: TextStyle(
                fontSize: 8.5 * uiScale,
                fontWeight: FontWeight.w700,
                color: stat.color,
              ),
            ),
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
    this.compatibility,
  });

  final double uiScale;
  final AnimationController entranceCtrl;
  final List<CompatibilityItem> items;
  final int percent;
  final ProductCompatibility? compatibility;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    final gaugeAnim = CurvedAnimation(parent: entranceCtrl, curve: const Interval(0.3, 0.85, curve: Curves.easeOutCubic));

    final effectivePercent = compatibility?.score ?? percent;
    final status = compatibility?.status ??
        (effectivePercent >= 80
            ? 'Great Match'
            : (effectivePercent >= 60
                ? 'Good Match'
                : (effectivePercent >= 40 ? 'Moderate Match' : 'Consider Alternatives')));

    final hasAllergyRisk = compatibility != null && compatibility!.allergyAlerts.isNotEmpty;
    final hasDietConflict = compatibility != null && compatibility!.dietaryAlerts.isNotEmpty;

    final Color statusColor;
    final Color statusBg;

    if (hasAllergyRisk || hasDietConflict || status.contains('Incompatible') || status.contains('Risk')) {
      statusColor = const Color(0xFFE0525C);
      statusBg = colors.isDark ? const Color(0xFF331616) : const Color(0xFFFDE8E8);
    } else if (effectivePercent >= 80) {
      statusColor = colors.iconGreen;
      statusBg = colors.iconGreenBg;
    } else if (effectivePercent >= 60) {
      statusColor = colors.iconBlue;
      statusBg = colors.iconBlueBg;
    } else if (effectivePercent >= 40) {
      statusColor = colors.iconOrange;
      statusBg = colors.iconOrangeBg;
    } else {
      statusColor = const Color(0xFFE0525C);
      statusBg = colors.isDark ? const Color(0xFF331616) : const Color(0xFFFDE8E8);
    }

    final recommendation = compatibility?.recommendation ??
        (effectivePercent >= 80
            ? 'This food is highly compatible with your health goals.'
            : (effectivePercent >= 60
                ? 'Acceptable in moderation with your health goals.'
                : 'Review highlighted nutrients to match your personal diet.'));

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Personalized Compatibility',
                style: TextStyle(
                  fontSize: 14.5 * uiScale,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(width: 4 * uiScale),
              Icon(Icons.auto_awesome, size: 14 * uiScale, color: colors.iconPurple),
            ],
          ),
          Text(
            'Dynamically calculated against your cloud profile & goals',
            style: TextStyle(fontSize: 10.5 * uiScale, color: colors.textSecondary),
          ),
          if (hasAllergyRisk) ...[
            SizedBox(height: 10 * uiScale),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 10 * uiScale, vertical: 8 * uiScale),
              decoration: BoxDecoration(
                color: colors.isDark ? const Color(0xFF331616) : const Color(0xFFFDE8E8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF8B4B4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 16 * uiScale, color: const Color(0xFFE0525C)),
                  SizedBox(width: 6 * uiScale),
                  Expanded(
                    child: Text(
                      compatibility!.allergyAlerts.join('; '),
                      style: TextStyle(
                        fontSize: 11 * uiScale,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFE0525C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                width: 120 * uiScale,
                padding: EdgeInsets.all(12 * uiScale),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(18)),
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: gaugeAnim,
                      builder: (context, _) {
                        final v = (effectivePercent * gaugeAnim.value).round();
                        return SizedBox(
                          width: 62 * uiScale,
                          height: 62 * uiScale,
                          child: CustomPaint(
                            painter: _CircularGaugePainter(
                              progress: gaugeAnim.value * (effectivePercent / 100),
                              color: statusColor,
                              trackColor: colors.divider,
                            ),
                            child: Center(
                              child: Text(
                                '$v%',
                                style: TextStyle(
                                  fontSize: 13.5 * uiScale,
                                  fontWeight: FontWeight.w800,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 8 * uiScale),
                    Text(
                      status,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5 * uiScale,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                    SizedBox(height: 4 * uiScale),
                    Text(
                      recommendation,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 8.5 * uiScale, height: 1.3, color: colors.textSecondary),
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

  Color get _color {
    final lower = item.rating.toLowerCase();
    if (lower.contains('excellent') || lower == 'safe') {
      return const Color(0xFF1E8A4C);
    } else if (lower.contains('good')) {
      return const Color(0xFF3B82F6);
    } else if (lower.contains('consider')) {
      return const Color(0xFFE0862E);
    } else {
      return const Color(0xFFE0525C);
    }
  }

  IconData get _icon {
    final lower = item.rating.toLowerCase();
    if (lower.contains('excellent') || lower == 'safe') {
      return Icons.check_circle;
    } else if (lower.contains('good')) {
      return Icons.check_circle_outline;
    } else if (lower.contains('consider')) {
      return Icons.help_outline;
    } else {
      return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6 * uiScale),
      child: Row(
        children: [
          Icon(item.icon, size: 15 * uiScale, color: colors.iconPurple),
          SizedBox(width: 8 * uiScale),
          Expanded(
            child: Text(item.label, style: TextStyle(fontSize: 11.5 * uiScale, color: colors.textPrimary)),
          ),
          Text(item.rating, style: TextStyle(fontSize: 10.5 * uiScale, fontWeight: FontWeight.w700, color: _color)),
          SizedBox(width: 3 * uiScale),
          Icon(_icon, size: 12 * uiScale, color: _color),
        ],
      ),
    );
  }
}


class _CircularGaugePainter extends CustomPainter {
  _CircularGaugePainter({required this.progress, required this.color, this.trackColor = const Color(0x99FFFFFF)});
  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 5;
    final bg = Paint()
      ..color = trackColor
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
  bool shouldRepaint(covariant _CircularGaugePainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.color != color || oldDelegate.trackColor != trackColor;
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
    final colors = context.dcColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ProsConsCard(
            uiScale: uiScale,
            title: "What's Good",
            titleColor: colors.iconGreen,
            bg: colors.isDark ? const Color(0xFF1B2A22) : const Color(0xFFE9F7EE),
            items: good,
            icon: Icons.check_circle,
            iconColor: colors.iconGreen,
            watermark: Icons.spa_rounded,
          ),
        ),
        SizedBox(width: 12 * uiScale),
        Expanded(
          child: _ProsConsCard(
            uiScale: uiScale,
            title: 'Watch Out For',
            titleColor: colors.iconOrange,
            bg: colors.isDark ? const Color(0xFF2C2219) : const Color(0xFFFCF2E6),
            items: watch,
            icon: Icons.warning_amber_rounded,
            iconColor: colors.iconOrange,
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
    final colors = context.dcColors;
    return Container(
      padding: EdgeInsets.all(12 * uiScale),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.cardBorder),
      ),
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
                            Text(item.title, style: TextStyle(fontSize: 10.5 * uiScale, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                            Text(item.subtitle, style: TextStyle(fontSize: 9 * uiScale, color: colors.textSecondary)),
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
    this.items = const [],
    this.recommendations = const [],
    this.onViewAll,
    this.onTap,
    this.onRecommendationTap,
  });

  final double uiScale;
  final List<AlternativeProduct> items;
  final List<PersonalizedRecommendation> recommendations;
  final VoidCallback? onViewAll;
  final ValueChanged<int>? onTap;
  final ValueChanged<PersonalizedRecommendation>? onRecommendationTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    final displayRecs = recommendations.take(3).toList();
    final displayItems = items.take(3).toList();
    final hasRecs = displayRecs.isNotEmpty;
    final count = hasRecs ? displayRecs.length : displayItems.length;

    if (count == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Better Alternatives for You',
              style: TextStyle(
                fontSize: 14.5 * uiScale,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            SizedBox(width: 4 * uiScale),
            Icon(Icons.auto_awesome, size: 13 * uiScale, color: colors.iconPurple),
            const Spacer(),
            if (onViewAll != null)
              GestureDetector(
                onTap: onViewAll,
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 12 * uiScale,
                        fontWeight: FontWeight.w700,
                        color: colors.iconPurple,
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 15 * uiScale, color: colors.iconPurple),
                  ],
                ),
              ),
          ],
        ),
        SizedBox(height: 10 * uiScale),
        Row(
          children: List.generate(count, (i) {
            final rec = hasRecs ? displayRecs[i] : null;
            final legacyItem = !hasRecs ? displayItems[i] : null;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == count - 1 ? 0 : 10 * uiScale),
                child: rec != null
                    ? _PersonalizedRecommendationCard(
                        uiScale: uiScale,
                        item: rec,
                        onTap: () {
                          if (onRecommendationTap != null) {
                            onRecommendationTap!(rec);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ResultScreen(
                                  product: rec.product,
                                  initialCompatibility: rec.compatibility,
                                ),
                              ),
                            );
                          }
                        },
                      )
                    : _AlternativeCard(
                        uiScale: uiScale,
                        item: legacyItem!,
                        onTap: () => onTap?.call(i),
                      ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _PersonalizedRecommendationCard extends StatefulWidget {
  const _PersonalizedRecommendationCard({
    required this.uiScale,
    required this.item,
    this.onTap,
  });

  final double uiScale;
  final PersonalizedRecommendation item;
  final VoidCallback? onTap;

  @override
  State<_PersonalizedRecommendationCard> createState() =>
      _PersonalizedRecommendationCardState();
}

class _PersonalizedRecommendationCardState
    extends State<_PersonalizedRecommendationCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    final prod = widget.item.product;
    final comp = widget.item.compatibility;
    final score = comp.score;
    final hasImage = prod.imageUrl.isNotEmpty && prod.imageUrl.startsWith('http');

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
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: colors.isDark ? 0.20 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: 1.3,
                  child: Container(
                    color: colors.surfaceSecondary,
                    padding: EdgeInsets.all(4 * widget.uiScale),
                    child: hasImage
                        ? Image.network(
                            prod.imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.eco_rounded,
                              size: 28 * widget.uiScale,
                              color: colors.iconGreen,
                            ),
                          )
                        : Icon(
                            Icons.eco_rounded,
                            size: 28 * widget.uiScale,
                            color: colors.iconGreen,
                          ),

                  ),
                ),
              ),
              SizedBox(height: 6 * widget.uiScale),
              Text(
                prod.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11 * widget.uiScale,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                prod.brand.isNotEmpty ? prod.brand : 'Better Choice',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9 * widget.uiScale,
                  color: colors.textSecondary,
                ),
              ),
              SizedBox(height: 4 * widget.uiScale),
              Row(
                children: [
                  Container(
                    width: 5 * widget.uiScale,
                    height: 5 * widget.uiScale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.iconGreen,
                    ),
                  ),
                  SizedBox(width: 4 * widget.uiScale),
                  Text(
                    '$score/100',
                    style: TextStyle(
                      fontSize: 9.5 * widget.uiScale,
                      fontWeight: FontWeight.w700,
                      color: colors.iconGreen,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3 * widget.uiScale),
              Row(
                children: [
                  Icon(
                    Icons.arrow_upward_rounded,
                    size: 10 * widget.uiScale,
                    color: colors.iconPurple,
                  ),
                  SizedBox(width: 2 * widget.uiScale),
                  Expanded(
                    child: Text(
                      widget.item.differentiator.isNotEmpty
                          ? widget.item.differentiator
                          : 'Better Nutrition',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 8.5 * widget.uiScale,
                        fontWeight: FontWeight.w600,
                        color: colors.iconPurple,
                      ),
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
    final colors = context.dcColors;
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
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.cardBorder),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: colors.isDark ? 0.20 : 0.05), blurRadius: 10, offset: const Offset(0, 6))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: 1.3,
                    child: Container(
                      color: colors.surfaceSecondary,
                      padding: EdgeInsets.all(4 * widget.uiScale),
                      child: widget.item.asset.isNotEmpty
                          ? Image.asset(
                              widget.item.asset,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(
                                  Icons.eco_rounded,
                                  color: colors.iconPurple,
                                  size: 24,
                                ),
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.eco_rounded,
                                color: colors.iconPurple,
                                size: 24,
                              ),
                            ),
                    ),
                ),
              ),
              SizedBox(height: 6 * widget.uiScale),
              Text(widget.item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11 * widget.uiScale, fontWeight: FontWeight.w800, color: colors.textPrimary)),
              Text(widget.item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9 * widget.uiScale, color: colors.textSecondary)),
              SizedBox(height: 4 * widget.uiScale),
              Row(
                children: [
                  Container(width: 5 * widget.uiScale, height: 5 * widget.uiScale, decoration: BoxDecoration(shape: BoxShape.circle, color: colors.iconGreen)),
                  SizedBox(width: 4 * widget.uiScale),
                  Text('${widget.item.score}/100', style: TextStyle(fontSize: 9.5 * widget.uiScale, fontWeight: FontWeight.w700, color: colors.iconGreen)),
                ],
              ),
              SizedBox(height: 3 * widget.uiScale),
              Row(
                children: [
                  Icon(Icons.arrow_upward_rounded, size: 10 * widget.uiScale, color: colors.iconPurple),
                  Expanded(
                    child: Text(
                      widget.item.differentiator,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 8.5 * widget.uiScale, fontWeight: FontWeight.w600, color: colors.iconPurple),
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
    this.isInPantry = false,
    this.onCompareTap,
    this.onAddToPantryTap,
    this.onShareTap,
  });

  final double uiScale;
  final bool isInPantry;
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
          child: _PrimaryActionButton(
            uiScale: uiScale,
            icon: isInPantry ? Icons.check_circle_rounded : Icons.add,
            label: isInPantry ? 'In Pantry ✓' : 'Add to Pantry',
            subtitle: isInPantry ? 'Saved to your pantry' : 'Save for meal planning',
            isSuccess: isInPantry,
            onTap: onAddToPantryTap,
          ),
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
    final colors = context.dcColors;
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
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.cardBorder),
          ),
          child: Column(
            children: [
              Icon(widget.icon, size: 17 * widget.uiScale, color: colors.iconPurple),
              SizedBox(height: 4 * widget.uiScale),
              Text(widget.label, style: TextStyle(fontSize: 10.5 * widget.uiScale, fontWeight: FontWeight.w700, color: colors.textPrimary)),
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
    this.isSuccess = false,
    this.onTap,
  });

  final double uiScale;
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSuccess;
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
            gradient: LinearGradient(
              colors: widget.isSuccess
                  ? const [Color(0xFF16A34A), Color(0xFF15803D)]
                  : const [Color(0xFF6C4EF5), Color(0xFF1E8A4C)],
            ),
            boxShadow: [
              BoxShadow(
                color: (widget.isSuccess ? const Color(0xFF16A34A) : const Color(0xFF6C4EF5)).withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
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
    final colors = context.dcColors;
    return Row(
      children: [
        Expanded(
          child: _QuickActionTile(
            uiScale: uiScale,
            icon: Icons.smart_toy_outlined,
            color: colors.iconPurple,
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
            color: colors.iconGreen,
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
            color: colors.iconOrange,
            title: 'Ai Recommendation',
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
    final colors = context.dcColors;
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
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.cardBorder),
          ),
          child: Column(
            children: [
              Icon(widget.icon, size: 18 * widget.uiScale, color: widget.color),
              SizedBox(height: 5 * widget.uiScale),
              Text(widget.title, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9.5 * widget.uiScale, fontWeight: FontWeight.w700, color: colors.textPrimary)),
              Text(widget.subtitle, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 8 * widget.uiScale, color: colors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// INGREDIENT INTELLIGENCE SECTION
// ---------------------------------------------------------------------------
class _IngredientIntelligenceSection extends StatelessWidget {
  const _IngredientIntelligenceSection({
    required this.uiScale,
    required this.intelligence,
  });

  final double uiScale;
  final IngredientIntelligenceResult intelligence;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(7 * uiScale),
                decoration: BoxDecoration(
                  color: colors.iconPurpleBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.psychology_outlined,
                  size: 18 * uiScale,
                  color: colors.iconPurple,
                ),
              ),
              SizedBox(width: 8 * uiScale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ingredient Intelligence',
                      style: TextStyle(
                        fontSize: 14.5 * uiScale,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      'Automated ingredient breakdown & alternate name detection',
                      style: TextStyle(
                        fontSize: 9.5 * uiScale,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7 * uiScale, vertical: 3 * uiScale),
                decoration: BoxDecoration(
                  color: colors.iconPurpleBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Verified',
                  style: TextStyle(
                    fontSize: 9 * uiScale,
                    fontWeight: FontWeight.w700,
                    color: colors.iconPurple,
                  ),
                ),
              ),
            ],
          ),

          if (intelligence.hasSugarRelated) ...[
            SizedBox(height: 14 * uiScale),
            Container(
              padding: EdgeInsets.all(12 * uiScale),
              decoration: BoxDecoration(
                color: colors.isDark ? const Color(0xFF2E1C12) : const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.isDark ? const Color(0xFF4D2C1A) : const Color(0xFFFFEDD5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 15 * uiScale,
                        color: colors.isDark ? const Color(0xFFFDBA74) : const Color(0xFFEA580C),
                      ),
                      SizedBox(width: 6 * uiScale),
                      Expanded(
                        child: Text(
                          'Sugar-Related Ingredients Identified',
                          style: TextStyle(
                            fontSize: 12 * uiScale,
                            fontWeight: FontWeight.w800,
                            color: colors.isDark ? const Color(0xFFFDBA74) : const Color(0xFF9A3412),
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6 * uiScale, vertical: 2 * uiScale),
                        decoration: BoxDecoration(
                          color: colors.isDark ? const Color(0xFF4D2C1A) : const Color(0xFFFFEDD5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${intelligence.sugarRelatedIngredients.length} Found',
                          style: TextStyle(
                            fontSize: 8.5 * uiScale,
                            fontWeight: FontWeight.w700,
                            color: colors.isDark ? const Color(0xFFFDBA74) : const Color(0xFFC2410C),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8 * uiScale),
                  Wrap(
                    spacing: 6 * uiScale,
                    runSpacing: 6 * uiScale,
                    children: intelligence.sugarRelatedIngredients.map((item) {
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 8 * uiScale, vertical: 4 * uiScale),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.isDark ? const Color(0xFF4D2C1A) : const Color(0xFFFED7AA)),
                        ),
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 10.5 * uiScale,
                            fontWeight: FontWeight.w700,
                            color: colors.isDark ? const Color(0xFFFDBA74) : const Color(0xFF9A3412),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 8 * uiScale),
                  Text(
                    'Sugar-related ingredients identified under alternate ingredient names. These ingredients contribute to the total carbohydrate and sugar content.',
                    style: TextStyle(
                      fontSize: 9.5 * uiScale,
                      height: 1.35,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (intelligence.hasAdditives) ...[
            SizedBox(height: 12 * uiScale),
            Container(
              padding: EdgeInsets.all(12 * uiScale),
              decoration: BoxDecoration(
                color: colors.isDark ? const Color(0xFF2E1414) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.isDark ? const Color(0xFF4D1A1A) : const Color(0xFFFEE2E2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.science_outlined,
                        size: 15 * uiScale,
                        color: colors.isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                      ),
                      SizedBox(width: 6 * uiScale),
                      Expanded(
                        child: Text(
                          'Formulated Additives & Preservatives',
                          style: TextStyle(
                            fontSize: 12 * uiScale,
                            fontWeight: FontWeight.w800,
                            color: colors.isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8 * uiScale),
                  ...intelligence.additives.map((additive) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 6 * uiScale),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: EdgeInsets.only(top: 4 * uiScale),
                            width: 5 * uiScale,
                            height: 5 * uiScale,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                            ),
                          ),
                          SizedBox(width: 6 * uiScale),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${additive.name}: ',
                                    style: TextStyle(
                                      fontSize: 10 * uiScale,
                                      fontWeight: FontWeight.w800,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  TextSpan(
                                    text: additive.explanation,
                                    style: TextStyle(
                                      fontSize: 9.5 * uiScale,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          if (intelligence.wholeFoodIngredients.isNotEmpty) ...[
            SizedBox(height: 12 * uiScale),
            Container(
              padding: EdgeInsets.all(12 * uiScale),
              decoration: BoxDecoration(
                color: colors.isDark ? const Color(0xFF142E1C) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.isDark ? const Color(0xFF1E4D2C) : const Color(0xFFDCFCE7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.spa_outlined,
                        size: 15 * uiScale,
                        color: colors.iconGreen,
                      ),
                      SizedBox(width: 6 * uiScale),
                      Expanded(
                        child: Text(
                          'Wholesome Primary Ingredients',
                          style: TextStyle(
                            fontSize: 12 * uiScale,
                            fontWeight: FontWeight.w800,
                            color: colors.iconGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8 * uiScale),
                  Wrap(
                    spacing: 6 * uiScale,
                    runSpacing: 6 * uiScale,
                    children: intelligence.wholeFoodIngredients.map((item) {
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 8 * uiScale, vertical: 4 * uiScale),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.isDark ? const Color(0xFF1E4D2C) : const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, size: 11 * uiScale, color: colors.iconGreen),
                            SizedBox(width: 3 * uiScale),
                            Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 10 * uiScale,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CLAIM CHECK SECTION
// ---------------------------------------------------------------------------
class _ClaimCheckSection extends StatelessWidget {
  const _ClaimCheckSection({
    required this.uiScale,
    required this.claimChecks,
  });

  final double uiScale;
  final List<ClaimVerificationItem> claimChecks;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(7 * uiScale),
                decoration: BoxDecoration(
                  color: colors.iconGreenBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.verified_outlined,
                  size: 18 * uiScale,
                  color: colors.iconGreen,
                ),
              ),
              SizedBox(width: 8 * uiScale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Claim Check',
                      style: TextStyle(
                        fontSize: 14.5 * uiScale,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      'Comparison of front-of-pack claims vs nutrition facts',
                      style: TextStyle(
                        fontSize: 9.5 * uiScale,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * uiScale),
          ...claimChecks.map((check) {
            final isVerified = check.status.toLowerCase() == 'verified';
            final Color statusColor = isVerified ? colors.iconGreen : colors.iconOrange;
            final Color bg = isVerified ? (colors.isDark ? const Color(0xFF142E1C) : const Color(0xFFF0FDF4)) : (colors.isDark ? const Color(0xFF2E2214) : const Color(0xFFFFFBEB));
            final Color border = isVerified ? (colors.isDark ? const Color(0xFF1E4D2C) : const Color(0xFFDCFCE7)) : (colors.isDark ? const Color(0xFF4D381E) : const Color(0xFFFEF3C7));

            return Container(
              margin: EdgeInsets.only(bottom: 8 * uiScale),
              padding: EdgeInsets.all(11 * uiScale),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isVerified ? Icons.check_circle : Icons.info_outline,
                        size: 14 * uiScale,
                        color: statusColor,
                      ),
                      SizedBox(width: 5 * uiScale),
                      Expanded(
                        child: Text(
                          '"${check.claim}"',
                          style: TextStyle(
                            fontSize: 11.5 * uiScale,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6 * uiScale, vertical: 2 * uiScale),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          check.status,
                          style: TextStyle(
                            fontSize: 8.5 * uiScale,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6 * uiScale),
                  Text(
                    check.explanation,
                    style: TextStyle(
                      fontSize: 9.5 * uiScale,
                      height: 1.35,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DISCREPANCY ALERT SECTION
// ---------------------------------------------------------------------------
class _DiscrepancyAlertSection extends StatelessWidget {
  const _DiscrepancyAlertSection({
    required this.uiScale,
    required this.discrepancies,
  });

  final double uiScale;
  final List<String> discrepancies;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Container(
      padding: EdgeInsets.all(13 * uiScale),
      decoration: BoxDecoration(
        color: colors.isDark ? const Color(0xFF2E2214) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.isDark ? const Color(0xFF4D381E) : const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 18 * uiScale,
                color: colors.iconOrange,
              ),
              SizedBox(width: 8 * uiScale),
              Expanded(
                child: Text(
                  'Data Discrepancy Alert',
                  style: TextStyle(
                    fontSize: 12.5 * uiScale,
                    fontWeight: FontWeight.w800,
                    color: colors.iconOrange,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8 * uiScale),
          ...discrepancies.map((disc) {
            return Padding(
              padding: EdgeInsets.only(bottom: 4 * uiScale),
              child: Text(
                '• $disc',
                style: TextStyle(
                  fontSize: 10 * uiScale,
                  height: 1.35,
                  color: colors.textSecondary,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
