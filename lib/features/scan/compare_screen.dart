import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/model/food_product.dart';
import '../../core/model/ai_analysis_model.dart';
import '../../core/services/recommendation_service.dart';
import '../../core/services/ingredient_intelligence_service.dart';
import 'result_screen.dart';

/// DietCompass — Product Comparison Screen
/// ---------------------------------------------------------------------------
/// Compares the currently analyzed product side-by-side with the single
/// best alternative recommended by the DietCompass AI recommendation system.
class CompareScreen extends StatefulWidget {
  const CompareScreen({
    super.key,
    required this.currentProduct,
    this.alternativeProduct,
    this.currentProductImage,
    this.alternativeProductImage,
    this.alternativeCompatibility,
    this.nutritionComparison,
    this.onBack,
  });

  final FoodProduct currentProduct;
  final FoodProduct? alternativeProduct;
  final ImageProvider? currentProductImage;
  final ImageProvider? alternativeProductImage;
  final ProductCompatibility? alternativeCompatibility;
  final ProductNutritionComparison? nutritionComparison;
  final VoidCallback? onBack;

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _ambientCtrl;

  FoodProduct? _bestAlternative;
  ProductCompatibility? _altCompatibility;
  ProductNutritionComparison? _nutritionComparison;
  bool _isLoadingAlternative = false;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _bestAlternative = widget.alternativeProduct;
    _altCompatibility = widget.alternativeCompatibility;
    _nutritionComparison = widget.nutritionComparison;

    if (_bestAlternative == null) {
      _fetchBestAlternative();
    }
  }

  Future<void> _fetchBestAlternative() async {
    setState(() => _isLoadingAlternative = true);
    try {
      final recs = await RecommendationService.instance.getCategoryAwareAlternatives(widget.currentProduct);
      if (mounted) {
        if (recs.isNotEmpty) {
          final top = recs.first;
          setState(() {
            _bestAlternative = top.product;
            _altCompatibility = top.compatibility;
            _nutritionComparison = top.nutritionComparison;
            _isLoadingAlternative = false;
          });
        } else {
          setState(() => _isLoadingAlternative = false);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingAlternative = false);
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _ambientCtrl.dispose();
    super.dispose();
  }

  Animation<double> _fade(double s, double e) => CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(s, e, curve: Curves.easeOut),
      );

  Animation<Offset> _slide(double s, double e) => Tween<Offset>(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _entranceCtrl, curve: Interval(s, e, curve: Curves.easeOutCubic)));

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 390).clamp(0.85, 1.25);
    final colors = context.dcColors;

    return Scaffold(
      backgroundColor: colors.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _BackgroundGradient(),
          SafeArea(
            child: _isLoadingAlternative
                ? _buildLoadingState(scale)
                : (_bestAlternative == null ? _buildUnavailableState(scale) : _buildComparisonContent(scale)),
          ),
        ],
      ),
    );
  }

  // ── 1. Loading State ────────────────────────────────────────────────────────
  Widget _buildLoadingState(double scale) {
    final colors = context.dcColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: colors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: colors.iconPurple.withValues(alpha: 0.15),
                  blurRadius: 20,
                ),
              ],
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(colors.iconPurple),
            ),
          ),
          SizedBox(height: 16 * scale),
          Text(
            'Finding the best healthier alternative...',
            style: TextStyle(
              fontSize: 14 * scale,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            'Scanning same-category products with better nutrition profile',
            style: TextStyle(
              fontSize: 11.5 * scale,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Unavailable State ────────────────────────────────────────────────────
  Widget _buildUnavailableState(double scale) {
    final colors = context.dcColors;
    return Padding(
      padding: EdgeInsets.all(24 * scale),
      child: Column(
        children: [
          _TopBar(uiScale: scale, onBack: widget.onBack),
          const Spacer(),
          Container(
            padding: EdgeInsets.all(24 * scale),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: colors.isDark ? 0.20 : 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 56 * scale,
                  height: 56 * scale,
                  decoration: BoxDecoration(
                    color: colors.surfaceSecondary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.compare_arrows_rounded,
                    size: 28 * scale,
                    color: colors.iconPurple,
                  ),
                ),
                SizedBox(height: 16 * scale),
                Text(
                  'Comparison unavailable',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17 * scale,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: 8 * scale),
                Text(
                  "We couldn't find a suitable alternative with enough product information to compare for ${widget.currentProduct.name}.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13 * scale,
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 20 * scale),
                SizedBox(
                  width: double.infinity,
                  height: 46 * scale,
                  child: ElevatedButton(
                    onPressed: widget.onBack ?? () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.iconPurple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Back to Product Analysis',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // ── 3. Full Comparison Content ──────────────────────────────────────────────
  Widget _buildComparisonContent(double scale) {
    final current = widget.currentProduct;
    final alt = _bestAlternative!;

    final currentScore = RecommendationService.instance.calculateNutritionScore(current);
    final altScore = RecommendationService.instance.calculateNutritionScore(alt);

    final currentCompat = RecommendationService.instance.calculateCompatibilityScore(current);
    final altCompat = _altCompatibility?.score ?? RecommendationService.instance.calculateCompatibilityScore(alt);

    final currentIntel = IngredientIntelligenceService.instance.analyze(current);
    final altIntel = IngredientIntelligenceService.instance.analyze(alt);

    return ListView(
      padding: EdgeInsets.fromLTRB(16 * scale, 8 * scale, 16 * scale, 32 * scale),
      physics: const BouncingScrollPhysics(),
      children: [
        // 1. Top Bar
        FadeTransition(
          opacity: _fade(0.0, 0.25),
          child: _TopBar(uiScale: scale, onBack: widget.onBack),
        ),
        SizedBox(height: 14 * scale),

        // 2. Side-by-Side Product Cards
        FadeTransition(
          opacity: _fade(0.04, 0.35),
          child: SlideTransition(
            position: _slide(0.04, 0.37),
            child: _DualProductCardsRow(
              uiScale: scale,
              currentProduct: current,
              altProduct: alt,
              currentImage: widget.currentProductImage,
              altImage: widget.alternativeProductImage,
              currentScore: currentScore,
              altScore: altScore,
              currentCompat: currentCompat,
              altCompat: altCompat,
              onViewAltDetails: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ResultScreen(
                      product: alt,
                      initialCompatibility: _altCompatibility,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        SizedBox(height: 16 * scale),

        // 3. Why This Alternative Card
        FadeTransition(
          opacity: _fade(0.12, 0.45),
          child: SlideTransition(
            position: _slide(0.12, 0.47),
            child: _WhyThisAlternativeCard(
              uiScale: scale,
              ambientCtrl: _ambientCtrl,
              currentProduct: current,
              altProduct: alt,
              nutritionComparison: _nutritionComparison,
              altCompatibility: _altCompatibility,
              currentScore: currentScore,
              altScore: altScore,
            ),
          ),
        ),
        SizedBox(height: 18 * scale),

        // 4. Detailed Nutrition Comparison Table
        FadeTransition(
          opacity: _fade(0.20, 0.55),
          child: SlideTransition(
            position: _slide(0.20, 0.57),
            child: _NutritionTableCard(
              uiScale: scale,
              currentProduct: current,
              altProduct: alt,
            ),
          ),
        ),
        SizedBox(height: 18 * scale),

        // 5. Health Compatibility Factors Comparison
        FadeTransition(
          opacity: _fade(0.28, 0.65),
          child: SlideTransition(
            position: _slide(0.28, 0.67),
            child: _HealthCompatibilityComparisonCard(
              uiScale: scale,
              currentProduct: current,
              altProduct: alt,
            ),
          ),
        ),
        SizedBox(height: 18 * scale),

        // 6. Ingredient Insights Comparison
        if (currentIntel.hasMeaningfulInsights || altIntel.hasMeaningfulInsights) ...[
          FadeTransition(
            opacity: _fade(0.36, 0.75),
            child: SlideTransition(
              position: _slide(0.36, 0.77),
              child: _IngredientInsightsComparisonCard(
                uiScale: scale,
                currentIntel: currentIntel,
                altIntel: altIntel,
                currentName: current.name,
                altName: alt.name,
              ),
            ),
          ),
          SizedBox(height: 18 * scale),
        ],

        // 7. Action Footer: Switch to Alternative
        FadeTransition(
          opacity: _fade(0.44, 0.85),
          child: SlideTransition(
            position: _slide(0.44, 0.87),
            child: _SwitchToAlternativeButton(
              uiScale: scale,
              altName: alt.name,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ResultScreen(
                      product: alt,
                      initialCompatibility: _altCompatibility,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Background Gradient
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
          colors: [Color(0xFFF1EDFB), Color(0xFFEFF8F3)],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top Bar
// ---------------------------------------------------------------------------
class _TopBar extends StatelessWidget {
  const _TopBar({required this.uiScale, this.onBack});

  final double uiScale;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Row(
      children: [
        GestureDetector(
          onTap: onBack ?? () => Navigator.pop(context),
          child: Container(
            width: 38 * uiScale,
            height: 38 * uiScale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.surface,
              border: Border.all(color: colors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: colors.isDark ? 0.20 : 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back,
              size: 18 * uiScale,
              color: colors.textPrimary,
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
                  Icon(Icons.compare_arrows_rounded, size: 18 * uiScale, color: colors.iconPurple),
                  SizedBox(width: 6 * uiScale),
                  Text(
                    'Product Comparison',
                    style: TextStyle(
                      fontSize: 17 * uiScale,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                'See how your choice compares with a healthier alternative',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11 * uiScale,
                  color: colors.textSecondary,
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
// Side-by-Side Dual Product Cards
// ---------------------------------------------------------------------------
class _DualProductCardsRow extends StatelessWidget {
  const _DualProductCardsRow({
    required this.uiScale,
    required this.currentProduct,
    required this.altProduct,
    this.currentImage,
    this.altImage,
    required this.currentScore,
    required this.altScore,
    required this.currentCompat,
    required this.altCompat,
    required this.onViewAltDetails,
  });

  final double uiScale;
  final FoodProduct currentProduct;
  final FoodProduct altProduct;
  final ImageProvider? currentImage;
  final ImageProvider? altImage;
  final int currentScore;
  final int altScore;
  final int currentCompat;
  final int altCompat;
  final VoidCallback onViewAltDetails;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    final ImageProvider? resolvedCurrentImg = currentImage ??
        (currentProduct.imageUrl.trim().isNotEmpty ? NetworkImage(currentProduct.imageUrl.trim()) : null);

    final ImageProvider? resolvedAltImg = altImage ??
        (altProduct.imageUrl.trim().isNotEmpty ? NetworkImage(altProduct.imageUrl.trim()) : null);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product 1: Current Choice
        Expanded(
          child: _ProductMiniCard(
            uiScale: uiScale,
            tag: 'Your Choice',
            tagColor: colors.iconPurple,
            name: currentProduct.name,
            brand: currentProduct.brand,
            image: resolvedCurrentImg,
            nutritionScore: currentScore,
            compatScore: currentCompat,
            isBestAlternative: false,
          ),
        ),

        // Middle VS circle
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6 * uiScale, vertical: 40 * uiScale),
          child: Container(
            width: 28 * uiScale,
            height: 28 * uiScale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.surface,
              border: Border.all(color: colors.cardBorder, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: colors.iconPurple.withValues(alpha: 0.12),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: Text(
                'VS',
                style: TextStyle(
                  fontSize: 10 * uiScale,
                  fontWeight: FontWeight.w900,
                  color: colors.iconPurple,
                ),
              ),
            ),
          ),
        ),

        // Product 2: Best Alternative
        Expanded(
          child: _ProductMiniCard(
            uiScale: uiScale,
            tag: '⭐ Best Alternative',
            tagColor: colors.iconGreen,
            name: altProduct.name,
            brand: altProduct.brand,
            image: resolvedAltImg,
            nutritionScore: altScore,
            compatScore: altCompat,
            isBestAlternative: true,
            onTapDetails: onViewAltDetails,
          ),
        ),
      ],
    );
  }
}

class _ProductMiniCard extends StatelessWidget {
  const _ProductMiniCard({
    required this.uiScale,
    required this.tag,
    required this.tagColor,
    required this.name,
    required this.brand,
    this.image,
    required this.nutritionScore,
    required this.compatScore,
    required this.isBestAlternative,
    this.onTapDetails,
  });

  final double uiScale;
  final String tag;
  final Color tagColor;
  final String name;
  final String brand;
  final ImageProvider? image;
  final int nutritionScore;
  final int compatScore;
  final bool isBestAlternative;
  final VoidCallback? onTapDetails;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Container(
      padding: EdgeInsets.all(12 * uiScale),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isBestAlternative ? colors.iconGreen.withValues(alpha: 0.35) : colors.cardBorder,
          width: isBestAlternative ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isBestAlternative
                ? colors.iconGreen.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: colors.isDark ? 0.20 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8 * uiScale, vertical: 3 * uiScale),
            decoration: BoxDecoration(
              color: tagColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tag,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5 * uiScale,
                fontWeight: FontWeight.w700,
                color: tagColor,
              ),
            ),
          ),
          SizedBox(height: 8 * uiScale),

          // Thumbnail
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 70 * uiScale,
                height: 70 * uiScale,
                color: colors.surfaceSecondary,
                padding: EdgeInsets.all(4 * uiScale),
                child: image != null
                    ? Image(
                        image: image!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.fastfood_rounded,
                          color: colors.textMuted,
                          size: 30 * uiScale,
                        ),
                      )
                    : Icon(
                        Icons.fastfood_rounded,
                        color: colors.textMuted,
                        size: 30 * uiScale,
                      ),
              ),
            ),
          ),
          SizedBox(height: 8 * uiScale),

          // Title & Brand
          Text(
            name.trim().isNotEmpty ? name : 'Food Product',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5 * uiScale,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
              height: 1.2,
            ),
          ),
          if (brand.trim().isNotEmpty) ...[
            SizedBox(height: 2 * uiScale),
            Text(
              brand.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5 * uiScale,
                fontWeight: FontWeight.w600,
                color: colors.iconPurple,
              ),
            ),
          ],
          SizedBox(height: 10 * uiScale),

          // Score Chips
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 5 * uiScale),
                  decoration: BoxDecoration(
                    color: colors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$nutritionScore',
                        style: TextStyle(
                          fontSize: 14 * uiScale,
                          fontWeight: FontWeight.w900,
                          color: nutritionScore >= 75 ? colors.iconGreen : colors.iconPurple,
                        ),
                      ),
                      Text(
                        'Score',
                        style: TextStyle(
                          fontSize: 8.5 * uiScale,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 6 * uiScale),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 5 * uiScale),
                  decoration: BoxDecoration(
                    color: colors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$compatScore%',
                        style: TextStyle(
                          fontSize: 14 * uiScale,
                          fontWeight: FontWeight.w900,
                          color: compatScore >= 75 ? colors.iconGreen : colors.iconPurple,
                        ),
                      ),
                      Text(
                        'Match',
                        style: TextStyle(
                          fontSize: 8.5 * uiScale,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
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
// Why this alternative? Card
// ---------------------------------------------------------------------------
class _WhyThisAlternativeCard extends StatelessWidget {
  const _WhyThisAlternativeCard({
    required this.uiScale,
    required this.ambientCtrl,
    required this.currentProduct,
    required this.altProduct,
    this.nutritionComparison,
    this.altCompatibility,
    required this.currentScore,
    required this.altScore,
  });

  final double uiScale;
  final AnimationController ambientCtrl;
  final FoodProduct currentProduct;
  final FoodProduct altProduct;
  final ProductNutritionComparison? nutritionComparison;
  final ProductCompatibility? altCompatibility;
  final int currentScore;
  final int altScore;

  String _generatePersonalizedReason() {
    final diffs = <String>[];

    // Sugar
    if (currentProduct.sugar != null && altProduct.sugar != null) {
      final sugarDiff = currentProduct.sugar! - altProduct.sugar!;
      if (sugarDiff >= 3.0) {
        diffs.add('contains ${sugarDiff.toStringAsFixed(0)}g less sugar');
      }
    }

    // Fiber
    if (currentProduct.fiber != null && altProduct.fiber != null) {
      final fiberDiff = altProduct.fiber! - currentProduct.fiber!;
      if (fiberDiff >= 1.5) {
        diffs.add('provides +${fiberDiff.toStringAsFixed(1)}g more dietary fiber');
      }
    }

    // Protein
    if (currentProduct.protein != null && altProduct.protein != null) {
      final proteinDiff = altProduct.protein! - currentProduct.protein!;
      if (proteinDiff >= 2.0) {
        diffs.add('offers +${proteinDiff.toStringAsFixed(1)}g higher protein');
      }
    }

    // Sodium
    if (currentProduct.sodium != null && altProduct.sodium != null) {
      final curMg = currentProduct.sodium! <= 10.0 ? currentProduct.sodium! * 1000 : currentProduct.sodium!;
      final altMg = altProduct.sodium! <= 10.0 ? altProduct.sodium! * 1000 : altProduct.sodium!;
      final sodiumDiff = curMg - altMg;
      if (sodiumDiff >= 150) {
        diffs.add('has ${sodiumDiff.toStringAsFixed(0)}mg lower sodium');
      }
    }

    // Calories
    if (currentProduct.calories != null && altProduct.calories != null) {
      final calDiff = (currentProduct.calories! - altProduct.calories!).round();
      if (calDiff >= 50) {
        diffs.add('saves ~$calDiff calories per serving');
      }
    }

    if (diffs.isNotEmpty) {
      final reasonPart = diffs.join(', ');
      return '${altProduct.name} is a healthier choice for your profile because it $reasonPart while keeping you in the same product category.';
    }

    if (altCompatibility?.summary.trim().isNotEmpty == true) {
      return altCompatibility!.summary.trim();
    }

    if (altScore > currentScore) {
      return '${altProduct.name} provides a superior overall nutritional profile (+${altScore - currentScore} points higher) with cleaner ingredients.';
    }

    return '${altProduct.name} is recommended as a wholesome, category-aligned alternative tailored for your dietary preferences.';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    final reasonText = _generatePersonalizedReason();
    final differentiator = nutritionComparison?.differentiator ?? (altScore > currentScore ? '+${altScore - currentScore} pts Higher Score' : 'Cleaner Ingredients');

    return Container(
      padding: EdgeInsets.all(16 * uiScale),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.20 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6 * uiScale),
                decoration: BoxDecoration(
                  color: colors.iconPurple,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
              ),
              SizedBox(width: 8 * uiScale),
              Expanded(
                child: Text(
                  'Why this alternative?',
                  style: TextStyle(
                    fontSize: 14 * uiScale,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8 * uiScale, vertical: 3 * uiScale),
                decoration: BoxDecoration(
                  color: colors.iconGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  differentiator,
                  style: TextStyle(
                    fontSize: 10 * uiScale,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10 * uiScale),
          Text(
            reasonText,
            style: TextStyle(
              fontSize: 12.5 * uiScale,
              color: colors.textSecondary,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detailed Nutrition Comparison Table
// ---------------------------------------------------------------------------
class _NutritionTableCard extends StatelessWidget {
  const _NutritionTableCard({
    required this.uiScale,
    required this.currentProduct,
    required this.altProduct,
  });

  final double uiScale;
  final FoodProduct currentProduct;
  final FoodProduct altProduct;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    // Generate nutrient comparison rows strictly preserving nulls
    final rows = <_NutrientComparisonRowData>[];

    // 1. Calories (Lower is generally favored for snack/general comparison)
    rows.add(
      _NutrientComparisonRowData(
        label: 'Calories',
        unit: 'kcal',
        valA: currentProduct.calories,
        valB: altProduct.calories,
        isHigherBetter: false,
        icon: Icons.local_fire_department,
        color: colors.iconPurple,
      ),
    );

    // 2. Protein (Higher is better)
    rows.add(
      _NutrientComparisonRowData(
        label: 'Protein',
        unit: 'g',
        valA: currentProduct.protein,
        valB: altProduct.protein,
        isHigherBetter: true,
        icon: Icons.fitness_center,
        color: colors.iconGreen,
      ),
    );

    // 3. Carbohydrates (Lower is generally favored)
    rows.add(
      _NutrientComparisonRowData(
        label: 'Carbohydrates',
        unit: 'g',
        valA: currentProduct.carbohydrates,
        valB: altProduct.carbohydrates,
        isHigherBetter: false,
        icon: Icons.grain,
        color: colors.iconOrange,
      ),
    );

    // 4. Sugar (Lower is better)
    rows.add(
      _NutrientComparisonRowData(
        label: 'Sugar',
        unit: 'g',
        valA: currentProduct.sugar,
        valB: altProduct.sugar,
        isHigherBetter: false,
        icon: Icons.icecream,
        color: const Color(0xFFE0525C),
      ),
    );

    // 5. Fat (Lower is better)
    rows.add(
      _NutrientComparisonRowData(
        label: 'Total Fat',
        unit: 'g',
        valA: currentProduct.fat,
        valB: altProduct.fat,
        isHigherBetter: false,
        icon: Icons.opacity,
        color: colors.iconOrange,
      ),
    );

    // 6. Fiber (Higher is better)
    rows.add(
      _NutrientComparisonRowData(
        label: 'Fiber',
        unit: 'g',
        valA: currentProduct.fiber,
        valB: altProduct.fiber,
        isHigherBetter: true,
        icon: Icons.eco_outlined,
        color: colors.iconGreen,
      ),
    );

    // 7. Sodium (Lower is better)
    double? sodA = currentProduct.sodium;
    if (sodA != null && sodA <= 10.0) sodA = sodA * 1000.0;
    double? sodB = altProduct.sodium;
    if (sodB != null && sodB <= 10.0) sodB = sodB * 1000.0;

    rows.add(
      _NutrientComparisonRowData(
        label: 'Sodium',
        unit: 'mg',
        valA: sodA,
        valB: sodB,
        isHigherBetter: false,
        icon: Icons.water_drop_outlined,
        color: colors.iconBlue,
      ),
    );

    return Container(
      padding: EdgeInsets.all(16 * uiScale),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.20 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.table_chart_rounded, size: 16 * uiScale, color: colors.iconPurple),
              SizedBox(width: 6 * uiScale),
              Text(
                'Nutrition Comparison',
                style: TextStyle(
                  fontSize: 14 * uiScale,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'Per 100g / Serving',
                style: TextStyle(
                  fontSize: 10 * uiScale,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * uiScale),

          // Table Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10 * uiScale, vertical: 8 * uiScale),
            decoration: BoxDecoration(
              color: colors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Nutrient',
                    style: TextStyle(
                      fontSize: 11 * uiScale,
                      fontWeight: FontWeight.w700,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Your Choice',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11 * uiScale,
                      fontWeight: FontWeight.w700,
                      color: colors.iconPurple,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Best Alternative',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11 * uiScale,
                      fontWeight: FontWeight.w700,
                      color: colors.iconGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 6 * uiScale),

          // Table Rows
          ...rows.map((row) => _buildNutrientTableRow(context, row)),
        ],
      ),
    );
  }

  Widget _buildNutrientTableRow(BuildContext context, _NutrientComparisonRowData data) {
    final colors = context.dcColors;
    final hasA = data.valA != null;
    final hasB = data.valB != null;

    final strA = hasA ? '${data.valA!.toStringAsFixed(data.unit == 'mg' || data.unit == 'kcal' ? 0 : 1)} ${data.unit}' : 'Not available';
    final strB = hasB ? '${data.valB!.toStringAsFixed(data.unit == 'mg' || data.unit == 'kcal' ? 0 : 1)} ${data.unit}' : 'Not available';

    bool aIsWinner = false;
    bool bIsWinner = false;

    if (hasA && hasB) {
      if (data.isHigherBetter) {
        if (data.valA! > data.valB! + 0.2) aIsWinner = true;
        if (data.valB! > data.valA! + 0.2) bIsWinner = true;
      } else {
        if (data.valA! + 0.2 < data.valB!) aIsWinner = true;
        if (data.valB! + 0.2 < data.valA!) bIsWinner = true;
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * uiScale, vertical: 9 * uiScale),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.divider),
        ),
      ),
      child: Row(
        children: [
          // Label + Icon
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Icon(data.icon, size: 13 * uiScale, color: data.color),
                SizedBox(width: 6 * uiScale),
                Expanded(
                  child: Text(
                    data.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5 * uiScale,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Value A (Your Choice)
          Expanded(
            flex: 3,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4 * uiScale, vertical: 2 * uiScale),
              decoration: BoxDecoration(
                color: aIsWinner ? colors.iconGreenBg : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (aIsWinner) ...[
                    Icon(Icons.check_rounded, size: 11, color: colors.iconGreen),
                    const SizedBox(width: 2),
                  ],
                  Flexible(
                    child: Text(
                      strA,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11 * uiScale,
                        fontWeight: hasA ? (aIsWinner ? FontWeight.w800 : FontWeight.w600) : FontWeight.w400,
                        color: hasA
                            ? (aIsWinner ? colors.iconGreen : colors.textPrimary)
                            : colors.textMuted,
                        fontStyle: hasA ? FontStyle.normal : FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Value B (Best Alternative)
          Expanded(
            flex: 3,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4 * uiScale, vertical: 2 * uiScale),
              decoration: BoxDecoration(
                color: bIsWinner ? colors.iconGreenBg : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (bIsWinner) ...[
                    Icon(Icons.check_rounded, size: 11, color: colors.iconGreen),
                    const SizedBox(width: 2),
                  ],
                  Flexible(
                    child: Text(
                      strB,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11 * uiScale,
                        fontWeight: hasB ? (bIsWinner ? FontWeight.w800 : FontWeight.w600) : FontWeight.w400,
                        color: hasB
                            ? (bIsWinner ? colors.iconGreen : colors.textPrimary)
                            : colors.textMuted,
                        fontStyle: hasB ? FontStyle.normal : FontStyle.italic,
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

class _NutrientComparisonRowData {
  const _NutrientComparisonRowData({
    required this.label,
    required this.unit,
    required this.valA,
    required this.valB,
    required this.isHigherBetter,
    required this.icon,
    required this.color,
  });

  final String label;
  final String unit;
  final double? valA;
  final double? valB;
  final bool isHigherBetter;
  final IconData icon;
  final Color color;
}

// ---------------------------------------------------------------------------
// Health Compatibility Comparison Card
// ---------------------------------------------------------------------------
class _HealthCompatibilityComparisonCard extends StatelessWidget {
  const _HealthCompatibilityComparisonCard({
    required this.uiScale,
    required this.currentProduct,
    required this.altProduct,
  });

  final double uiScale;
  final FoodProduct currentProduct;
  final FoodProduct altProduct;

  String _calcRating(FoodProduct p, String factor) {
    if (factor == 'Weight Management') {
      final cal = p.calories;
      if (cal == null) return 'Moderate';
      return cal <= 220 ? 'Good' : 'Consider';
    } else if (factor == 'Heart Health') {
      final raw = p.sodium;
      if (raw == null) return 'Good';
      final mg = raw <= 10 ? raw * 1000 : raw;
      return mg <= 400 ? 'Good' : 'Consider';
    } else if (factor == 'Blood Sugar Control') {
      final sug = p.sugar;
      if (sug == null) return 'Moderate';
      return sug <= 5 ? 'Good' : 'Consider';
    } else if (factor == 'Digestive Health') {
      final fib = p.fiber;
      if (fib == null) return 'Good';
      return fib >= 3 ? 'Excellent' : 'Good';
    }
    return 'Good';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    const factors = [
      {'label': 'Weight Management', 'icon': Icons.monitor_weight_outlined},
      {'label': 'Heart Health', 'icon': Icons.favorite_outline},
      {'label': 'Blood Sugar Control', 'icon': Icons.water_drop_outlined},
      {'label': 'Digestive Health', 'icon': Icons.eco_outlined},
    ];

    return Container(
      padding: EdgeInsets.all(16 * uiScale),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.20 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety_outlined, size: 16 * uiScale, color: colors.iconGreen),
              SizedBox(width: 6 * uiScale),
              Text(
                'Personal Health Compatibility',
                style: TextStyle(
                  fontSize: 14 * uiScale,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * uiScale),

          ...factors.map((f) {
            final label = f['label'] as String;
            final icon = f['icon'] as IconData;
            final rateA = _calcRating(currentProduct, label);
            final rateB = _calcRating(altProduct, label);

            final isGoodA = rateA == 'Excellent' || rateA == 'Good';
            final isGoodB = rateB == 'Excellent' || rateB == 'Good';

            return Padding(
              padding: EdgeInsets.only(bottom: 8 * uiScale),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10 * uiScale, vertical: 8 * uiScale),
                decoration: BoxDecoration(
                  color: colors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 14 * uiScale, color: colors.iconPurple),
                    SizedBox(width: 6 * uiScale),
                    Expanded(
                      flex: 4,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11.5 * uiScale,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6 * uiScale, vertical: 2 * uiScale),
                        decoration: BoxDecoration(
                          color: (isGoodA ? colors.iconGreen : colors.iconOrange).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          rateA,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10 * uiScale,
                            fontWeight: FontWeight.w700,
                            color: isGoodA ? colors.iconGreen : colors.iconOrange,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 6 * uiScale),
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6 * uiScale, vertical: 2 * uiScale),
                        decoration: BoxDecoration(
                          color: (isGoodB ? colors.iconGreen : colors.iconOrange).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          rateB,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10 * uiScale,
                            fontWeight: FontWeight.w700,
                            color: isGoodB ? colors.iconGreen : colors.iconOrange,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ingredient Insights Comparison Card
// ---------------------------------------------------------------------------
class _IngredientInsightsComparisonCard extends StatelessWidget {
  const _IngredientInsightsComparisonCard({
    required this.uiScale,
    required this.currentIntel,
    required this.altIntel,
    required this.currentName,
    required this.altName,
  });

  final double uiScale;
  final IngredientIntelligenceResult currentIntel;
  final IngredientIntelligenceResult altIntel;
  final String currentName;
  final String altName;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Container(
      padding: EdgeInsets.all(16 * uiScale),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.20 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined, size: 16 * uiScale, color: colors.iconPurple),
              SizedBox(width: 6 * uiScale),
              Text(
                'Ingredient Insights',
                style: TextStyle(
                  fontSize: 14 * uiScale,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * uiScale),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Product Ingredients Findings
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(10 * uiScale),
                  decoration: BoxDecoration(
                    color: colors.isDark ? const Color(0xFF2E2214) : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.isDark ? const Color(0xFF4D381E) : const Color(0xFFFEF3C7)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Choice',
                        style: TextStyle(
                          fontSize: 11 * uiScale,
                          fontWeight: FontWeight.w700,
                          color: colors.isDark ? const Color(0xFFFDBA74) : const Color(0xFFB45309),
                        ),
                      ),
                      SizedBox(height: 6 * uiScale),
                      if (currentIntel.sugarRelatedIngredients.isNotEmpty)
                        Text(
                          '• ${currentIntel.sugarRelatedIngredients.length} Sugar source(s) detected',
                          style: TextStyle(fontSize: 10.5 * uiScale, color: colors.textSecondary),
                        ),
                      if (currentIntel.additives.isNotEmpty)
                        Text(
                          '• ${currentIntel.additives.length} Additive(s) flagged',
                          style: TextStyle(fontSize: 10.5 * uiScale, color: colors.textSecondary),
                        ),
                      if (!currentIntel.hasSugarRelated && !currentIntel.hasAdditives)
                        Text(
                          '• Standard ingredient profile',
                          style: TextStyle(fontSize: 10.5 * uiScale, color: colors.textSecondary),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 10 * uiScale),

              // Alternative Product Ingredients Findings
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(10 * uiScale),
                  decoration: BoxDecoration(
                    color: colors.isDark ? const Color(0xFF142E1C) : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.isDark ? const Color(0xFF1E4D2C) : const Color(0xFFDCFCE7)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alternative',
                        style: TextStyle(
                          fontSize: 11 * uiScale,
                          fontWeight: FontWeight.w700,
                          color: colors.isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
                        ),
                      ),
                      SizedBox(height: 6 * uiScale),
                      if (altIntel.wholeFoodIngredients.isNotEmpty)
                        Text(
                          '• Rich in whole food ingredients',
                          style: TextStyle(fontSize: 10.5 * uiScale, color: colors.textSecondary),
                        ),
                      if (!altIntel.hasAdditives)
                        Text(
                          '• Free from controversial additives',
                          style: TextStyle(fontSize: 10.5 * uiScale, color: colors.textSecondary),
                        )
                      else
                        Text(
                          '• ${altIntel.additives.length} Additive(s)',
                          style: TextStyle(fontSize: 10.5 * uiScale, color: colors.textSecondary),
                        ),
                      if (!altIntel.hasSugarRelated)
                        Text(
                          '• Minimal or zero hidden sugars',
                          style: TextStyle(fontSize: 10.5 * uiScale, color: colors.textSecondary),
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
// Switch To Alternative Action Button
// ---------------------------------------------------------------------------
class _SwitchToAlternativeButton extends StatelessWidget {
  const _SwitchToAlternativeButton({
    required this.uiScale,
    required this.altName,
    required this.onTap,
  });

  final double uiScale;
  final String altName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return SizedBox(
      width: double.infinity,
      height: 50 * uiScale,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
        label: Text(
          'View Full Analysis for $altName',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13.5 * uiScale,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.iconGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: colors.iconGreen.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
