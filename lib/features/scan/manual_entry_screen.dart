import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:diet_compass/core/theme/app_colors.dart';
import 'package:diet_compass/core/model/food_product.dart';
import 'package:diet_compass/core/services/food_service.dart';
import 'package:diet_compass/core/services/nutrition_normalization_service.dart';
import 'package:diet_compass/core/services/scan_history_service.dart';
import 'package:diet_compass/features/scan/ai_analysis_screen.dart';
import 'package:diet_compass/features/scan/camera_scan_screen.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({
    super.key,
    this.onBack,
    this.onScanLabelTap,
    this.onUploadImageTap,
    this.onNeedHelpTap,
    this.onAnalyze,
  });

  final VoidCallback? onBack;
  final VoidCallback? onScanLabelTap;
  final VoidCallback? onUploadImageTap;
  final VoidCallback? onNeedHelpTap;
  final ValueChanged<Map<String, dynamic>>? onAnalyze;

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _ambientCtrl;

  // Product info
  final _productNameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _servingSizeCtrl = TextEditingController();
  String _servingUnit = 'g';

  // Nutrition facts
  bool _perServing = true;
  bool _showMoreNutrients = false;
  final Map<String, TextEditingController> _nutrientCtrls = {
    for (final n in _NutrientField.basics) n.label: TextEditingController(),
  };
  final Map<String, TextEditingController> _extraNutrientCtrls = {
    for (final n in _NutrientField.extras) n.label: TextEditingController(),
  };

  // Ingredients
  final _ingredientsCtrl = TextEditingController();

  // Allergens
  final Set<String> _selectedAllergens = {};
  bool _showOtherInput = false;
  final _otherAllergenCtrl = TextEditingController();

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
    _ingredientsCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _ambientCtrl.dispose();
    _productNameCtrl.dispose();
    _brandCtrl.dispose();
    _servingSizeCtrl.dispose();
    _ingredientsCtrl.dispose();
    _otherAllergenCtrl.dispose();
    for (final c in _nutrientCtrls.values) c.dispose();
    for (final c in _extraNutrientCtrls.values) c.dispose();
    super.dispose();
  }

  Animation<double> _fade(double s, double e) => CurvedAnimation(
    parent: _entranceCtrl,
    curve: Interval(s, e, curve: Curves.easeOut),
  );

  Animation<Offset> _slide(double s, double e) =>
      Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _entranceCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic),
        ),
      );

  double? _parseNutrient(List<String> keys) {
    for (final k in keys) {
      final text =
          _nutrientCtrls[k]?.text.trim() ?? _extraNutrientCtrls[k]?.text.trim();
      if (text != null && text.isNotEmpty) {
        final val = double.tryParse(text);
        if (val != null) return val;
      }
    }
    return null;
  }

  Future<void> _handleAnalyze() async {
    final name = _productNameCtrl.text.trim().isEmpty
        ? 'Unknown Product'
        : _productNameCtrl.text.trim();
    final brand = _brandCtrl.text.trim().isEmpty
        ? 'Manual Entry'
        : _brandCtrl.text.trim();
    final servingSize = _servingSizeCtrl.text.trim().isNotEmpty
        ? '${_servingSizeCtrl.text.trim()} $_servingUnit'.trim()
        : '40 $_servingUnit';

    final calories = _parseNutrient(['Calories', 'Energy']);
    final protein = _parseNutrient(['Protein']);
    final carbs = _parseNutrient([
      'Carbohydrates',
      'Carbs',
      'Total Carbohydrate',
    ]);
    final fat = _parseNutrient(['Total Fat', 'Fat']);
    final satFat = _parseNutrient(['Saturated Fat', 'Sat. Fat', 'Sat Fat']);
    final fiber = _parseNutrient(['Fibre', 'Fiber', 'Dietary Fiber']);
    final sugar = _parseNutrient(['Sugar', 'Sugars', 'Total Sugars']);
    final sodium = _parseNutrient(['Sodium']);
    final ingredients = _ingredientsCtrl.text.trim();
    final allergens = _selectedAllergens.toList();

    final hasNutrients =
        calories != null ||
        protein != null ||
        carbs != null ||
        fat != null ||
        sugar != null ||
        sodium != null;

    debugPrint('\n==============================================');
    debugPrint('[MANUAL ENTRY]');
    debugPrint('productName = $name');
    debugPrint('brand = $brand');
    debugPrint('servingSize = $servingSize');
    debugPrint('nutritionProvided = $hasNutrients');
    debugPrint('ingredientsProvided = ${ingredients.isNotEmpty}');
    debugPrint('==============================================\n');

    final data = <String, dynamic>{
      'productName': name,
      'brand': brand,
      'servingSize': _servingSizeCtrl.text.trim(),
      'servingUnit': _servingUnit,
      'perServing': _perServing,
      'nutrients': {
        for (final e in _nutrientCtrls.entries) e.key: e.value.text,
      },
      'extraNutrients': {
        for (final e in _extraNutrientCtrls.entries) e.key: e.value.text,
      },
      'ingredients': ingredients,
      'allergens': allergens,
    };
    widget.onAnalyze?.call(data);

    // Look up real product to fetch image / real metadata if available
    FoodProduct? matchedProduct;
    final lookupQuery = brand.isNotEmpty && brand != 'Manual Entry'
        ? '$name $brand'.trim()
        : name;

    debugPrint('\n[PRODUCT LOOKUP]');
    debugPrint('query = $lookupQuery');
    debugPrint('source = OpenFoodFacts/USDA/UPC/Gemini');

    if (name.isNotEmpty && name != 'Unknown Product') {
      try {
        final products = await FoodService().searchProducts(
          lookupQuery,
          pageSize: 1,
        );
        if (products.isNotEmpty) {
          matchedProduct = products.first;
        }
      } catch (e) {
        debugPrint('[PRODUCT LOOKUP] Lookup error: $e');
      }
    }

    final resultFound = matchedProduct != null;
    debugPrint('resultFound = $resultFound');

    // Normalize user-entered nutrition data to 100g / 100ml basis
    final normalized = NutritionNormalizationService.instance.normalize(
      calories: calories ?? matchedProduct?.calories,
      protein: protein ?? matchedProduct?.protein,
      carbohydrates: carbs ?? matchedProduct?.carbohydrates,
      fat: fat ?? matchedProduct?.fat,
      saturatedFat: satFat ?? matchedProduct?.saturatedFat,
      fiber: fiber ?? matchedProduct?.fiber,
      sugar: sugar ?? matchedProduct?.sugar,
      sodium: sodium ?? matchedProduct?.sodium,
      salt: null,
      servingSize: servingSize,
      sourceBasis: _perServing ? 'serving' : '100g',
      productName: name,
      brand: brand,
      ingredients: ingredients,
    );

    // Create ONE canonical product preserving normalized nutrition data
    final canonicalProduct = FoodProduct(
      barcode: matchedProduct?.barcode ?? '',
      name: name,
      brand: brand,
      imageUrl: matchedProduct?.imageUrl ?? '',
      ingredients: ingredients.isNotEmpty
          ? ingredients
          : (matchedProduct?.ingredients ?? ''),
      allergens: allergens.isNotEmpty
          ? allergens
          : (matchedProduct?.allergens ?? const []),
      calories: normalized.calories,
      protein: normalized.protein,
      carbohydrates: normalized.carbohydrates,
      fat: normalized.fat,
      saturatedFat: normalized.saturatedFat,
      fiber: normalized.fiber,
      sugar: normalized.sugar,
      sodium: normalized.sodium,
      servingSize: servingSize,
      packageSize: matchedProduct?.packageSize,
      nutritionBasis: normalized.nutritionBasis,
      nutriScore: matchedProduct?.nutriScore,
      novaGroup: matchedProduct?.novaGroup,
      source: 'manual',
    );

    ScanHistoryService.instance.saveScan(canonicalProduct);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiAnalysisScreen(
          product: canonicalProduct,
          productName: canonicalProduct.name,
          productSubtitle: canonicalProduct.brand,
          servingInfo: servingSize,
        ),
      ),
    );
  }

  void _openCameraScan() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const CameraScanScreen(
          source: CameraSource.scan,
          initialMode: ScanMode.ocr,
        ),
      ),
    );
  }

  void _showHelpSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (sheetContext) => _NutritionHelpSheet(
        onScanLabelTap: () {
          Navigator.pop(sheetContext);
          (widget.onScanLabelTap ?? _openCameraScan).call();
        },
        onUploadImageTap: () {
          Navigator.pop(sheetContext);
          widget.onUploadImageTap?.call();
        },
      ),
    );
  }

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
          // Ambient blurred glass blobs for the glassmorphism backdrop
          _GlassBackdrop(uiScale: scale, ambientCtrl: _ambientCtrl),

          SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                18 * scale,
                8 * scale,
                18 * scale,
                28 * scale,
              ),
              physics: const BouncingScrollPhysics(),
              children: [
                FadeTransition(
                  opacity: _fade(0.0, 0.3),
                  child: SlideTransition(
                    position: _slide(0.0, 0.35),
                    child: _TopHeader(
                      uiScale: scale,
                      onBack: widget.onBack ?? () => Navigator.pop(context),
                      onNeedHelpTap: widget.onNeedHelpTap ?? _showHelpSheet,
                    ),
                  ),
                ),
                FadeTransition(
                  opacity: _fade(0.05, 0.35),
                  child: SlideTransition(
                    position: _slide(0.05, 0.4),
                    child: _EntryTabsBar(
                      uiScale: scale,
                      onScanLabelTap: widget.onScanLabelTap ?? _openCameraScan,
                      onUploadImageTap: widget.onUploadImageTap,
                    ),
                  ),
                ),
                SizedBox(height: 18 * scale),

                FadeTransition(
                  opacity: _fade(0.12, 0.42),
                  child: SlideTransition(
                    position: _slide(0.12, 0.46),
                    child: _GlassCard(
                      uiScale: scale,
                      child: _ProductInfoSection(
                        uiScale: scale,
                        productNameCtrl: _productNameCtrl,
                        brandCtrl: _brandCtrl,
                        servingSizeCtrl: _servingSizeCtrl,
                        selectedUnit: _servingUnit,
                        onUnitChanged: (v) => setState(() => _servingUnit = v),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16 * scale),

                FadeTransition(
                  opacity: _fade(0.18, 0.5),
                  child: SlideTransition(
                    position: _slide(0.18, 0.54),
                    child: _GlassCard(
                      uiScale: scale,
                      child: _NutritionFactsSection(
                        uiScale: scale,
                        perServing: _perServing,
                        onToggle: (v) => setState(() => _perServing = v),
                        controllers: _nutrientCtrls,
                        showMore: _showMoreNutrients,
                        onToggleMore: () => setState(
                          () => _showMoreNutrients = !_showMoreNutrients,
                        ),
                        extraControllers: _extraNutrientCtrls,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16 * scale),

                FadeTransition(
                  opacity: _fade(0.24, 0.56),
                  child: SlideTransition(
                    position: _slide(0.24, 0.6),
                    child: _GlassCard(
                      uiScale: scale,
                      child: _IngredientsSection(
                        uiScale: scale,
                        controller: _ingredientsCtrl,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16 * scale),

                FadeTransition(
                  opacity: _fade(0.3, 0.62),
                  child: SlideTransition(
                    position: _slide(0.3, 0.66),
                    child: _GlassCard(
                      uiScale: scale,
                      child: _AllergensSection(
                        uiScale: scale,
                        selected: _selectedAllergens,
                        showOtherInput: _showOtherInput,
                        otherCtrl: _otherAllergenCtrl,
                        onToggleOtherInput: () =>
                            setState(() => _showOtherInput = !_showOtherInput),
                        onToggle: (name) => setState(() {
                          if (_selectedAllergens.contains(name)) {
                            _selectedAllergens.remove(name);
                          } else {
                            _selectedAllergens.add(name);
                          }
                        }),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 18 * scale),

                FadeTransition(
                  opacity: _fade(0.38, 0.7),
                  child: SlideTransition(
                    position: _slide(0.38, 0.74),
                    child: _AiHelperCard(
                      uiScale: scale,
                      ambientCtrl: _ambientCtrl,
                    ),
                  ),
                ),
                SizedBox(height: 18 * scale),

                FadeTransition(
                  opacity: _fade(0.46, 0.8),
                  child: SlideTransition(
                    position: _slide(0.46, 0.84),
                    child: _AnalyzeButton(
                      uiScale: scale,
                      onTap: _handleAnalyze,
                    ),
                  ),
                ),
                SizedBox(height: 10 * scale),

                FadeTransition(
                  opacity: _fade(0.5, 0.85),
                  child: _PrivacyNote(uiScale: scale),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionHelpSheet extends StatelessWidget {
  const _NutritionHelpSheet({
    required this.onScanLabelTap,
    required this.onUploadImageTap,
  });

  final VoidCallback onScanLabelTap;
  final VoidCallback onUploadImageTap;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final colors = context.dcColors;
    return SafeArea(
      top: false,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 720),
        padding: EdgeInsets.fromLTRB(20, 10, 20, 16 + bottomInset),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: colors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'How to Enter Nutrition Facts',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: colors.iconPurple,
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Enter the information exactly as it appears on your food package for the most accurate analysis.',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _HelpSection(
                      number: '1',
                      title: 'PRODUCT NAME',
                      body:
                          'Enter the exact product name printed on the package.\nExample: Dairy Milk Silk',
                    ),
                    const _HelpSection(
                      number: '2',
                      title: 'BRAND',
                      body:
                          "Enter the product's brand/manufacturer.\nExample: Cadbury",
                    ),
                    const _HelpSection(
                      number: '3',
                      title: 'SERVING SIZE',
                      body:
                          'Enter the serving size exactly as shown on the package.\nExample: 40 g\nAvailable units: g / ml / cup.',
                    ),
                    const _HelpSection(
                      number: '4',
                      title: 'NUTRITION FACTS',
                      body:
                          'Per 100 g/ml shows nutrition for a fixed 100 g or 100 ml amount. Per Serving shows nutrition for the serving size listed on the package. Select the option that matches the label before entering values.\n\nYou can enter Calories, Protein, Carbohydrates, Total Fat, Sugar, Fiber, Sodium, and any other values shown.',
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.isDark ? const Color(0xFF221A38) : const Color(0xFFEDE7FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.isDark ? const Color(0xFF382959) : const Color(0xFFD8C9FF)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'IMPORTANT TIP',
                            style: TextStyle(
                              color: colors.iconPurple,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Don't convert the values yourself. Enter them exactly as printed on the package and select Per 100 g/ml or Per Serving accordingly.",
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Prefer an easier way?',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _HelpActionButton(
                      icon: Icons.qr_code_scanner_rounded,
                      label: 'Scan Barcode',
                      onTap: onScanLabelTap,
                    ),
                    const SizedBox(height: 8),
                    _HelpActionButton(
                      icon: Icons.image_outlined,
                      label: 'Upload Nutrition Label',
                      onTap: onUploadImageTap,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.iconPurple,
                          side: BorderSide(color: colors.isDark ? const Color(0xFF382959) : const Color(0xFFD8C9FF)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({
    required this.number,
    required this.title,
    required this.body,
  });

  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.iconPurple,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.iconPurple,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
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

class _HelpActionButton extends StatelessWidget {
  const _HelpActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonalIcon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(
          foregroundColor: colors.iconPurple,
          backgroundColor: colors.iconPurpleBg,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ambient glass backdrop — soft blurred colour blobs behind the frosted cards
// ---------------------------------------------------------------------------
class _GlassBackdrop extends StatelessWidget {
  const _GlassBackdrop({required this.uiScale, required this.ambientCtrl});
  final double uiScale;
  final AnimationController ambientCtrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return AnimatedBuilder(
      animation: ambientCtrl,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(ambientCtrl.value);
        return Stack(
          fit: StackFit.expand,
          children: [
            Container(color: colors.bg),
            Positioned(
              top: -80 + t * 16,
              left: -60,
              child: _blob(220 * uiScale, colors.iconPurple.withValues(alpha: colors.isDark ? 0.12 : 0.22)),
            ),
            Positioned(
              top: 220 - t * 20,
              right: -70,
              child: _blob(190 * uiScale, colors.iconGreen.withValues(alpha: colors.isDark ? 0.12 : 0.22)),
            ),
            Positioned(
              bottom: -60 + t * 12,
              left: -40,
              child: _blob(180 * uiScale, colors.iconBlue.withValues(alpha: colors.isDark ? 0.12 : 0.22)),
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
          color: color,
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Reusable frosted glassmorphism card
// ---------------------------------------------------------------------------
class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.uiScale, required this.child, this.padding});
  final double uiScale;
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding ?? EdgeInsets.all(16 * uiScale),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: colors.isDark ? 0.90 : 0.62),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colors.cardBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: colors.isDark ? 0.20 : 0.05),
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
// Step number badge (1 / 2 / 3 / 4)
// ---------------------------------------------------------------------------
class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.uiScale, required this.number});
  final double uiScale;
  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24 * uiScale,
      height: 24 * uiScale,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF6C4EF5), Color(0xFF8E6EF7)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12.5 * uiScale,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.uiScale,
    required this.number,
    required this.title,
    this.trailing,
  });
  final double uiScale;
  final int number;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Row(
      children: [
        _StepBadge(uiScale: uiScale, number: number),
        SizedBox(width: 8 * uiScale),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15 * uiScale,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Top header — back button, title, subtitle, Need Help pill
// ---------------------------------------------------------------------------
class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.uiScale, this.onBack, this.onNeedHelpTap});
  final double uiScale;
  final VoidCallback? onBack;
  final VoidCallback? onNeedHelpTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CircleIconButton(
          uiScale: uiScale,
          icon: Icons.arrow_back_rounded,
          onTap: onBack,
        ),
        SizedBox(width: 10 * uiScale),
        Expanded(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Manual Nutrition Entry ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17.5 * uiScale,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  Icon(
                    Icons.auto_awesome,
                    size: 14 * uiScale,
                    color: colors.iconPurple,
                  ),
                ],
              ),
              SizedBox(height: 2 * uiScale),
              Text(
                'Enter nutrition facts from any food package',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5 * uiScale,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 6 * uiScale),
        _NeedHelpPill(uiScale: uiScale, onTap: onNeedHelpTap),
      ],
    );
  }
}

class _CircleIconButton extends StatefulWidget {
  const _CircleIconButton({
    required this.uiScale,
    required this.icon,
    this.onTap,
  });
  final double uiScale;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  State<_CircleIconButton> createState() => _CircleIconButtonState();
}

class _CircleIconButtonState extends State<_CircleIconButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.9),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap ?? () => Navigator.maybePop(context),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 40 * widget.uiScale,
          height: 40 * widget.uiScale,
          decoration: BoxDecoration(
            color: colors.surface,
            shape: BoxShape.circle,
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
            widget.icon,
            size: 18 * widget.uiScale,
            color: colors.iconPurple,
          ),
        ),
      ),
    );
  }
}

class _NeedHelpPill extends StatefulWidget {
  const _NeedHelpPill({required this.uiScale, this.onTap});
  final double uiScale;
  final VoidCallback? onTap;

  @override
  State<_NeedHelpPill> createState() => _NeedHelpPillState();
}

class _NeedHelpPillState extends State<_NeedHelpPill> {
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
          padding: EdgeInsets.symmetric(
            horizontal: 9 * widget.uiScale,
            vertical: 7 * widget.uiScale,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.help_outline_rounded,
                size: 12 * widget.uiScale,
                color: colors.iconPurple,
              ),
              SizedBox(width: 4 * widget.uiScale),
              Text(
                'Need Help?',
                style: TextStyle(
                  fontSize: 10.5 * widget.uiScale,
                  fontWeight: FontWeight.w700,
                  color: colors.iconPurple,
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
// Tabs bar — Scan Label / Upload Image / Manual Entry
// ---------------------------------------------------------------------------
class _EntryTabsBar extends StatelessWidget {
  const _EntryTabsBar({
    required this.uiScale,
    this.onScanLabelTap,
    this.onUploadImageTap,
  });
  final double uiScale;
  final VoidCallback? onScanLabelTap;
  final VoidCallback? onUploadImageTap;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      uiScale: uiScale,
      padding: EdgeInsets.symmetric(
        horizontal: 6 * uiScale,
        vertical: 6 * uiScale,
      ),
      child: Row(
        children: [
          _EntryTab(
            uiScale: uiScale,
            icon: Icons.qr_code_scanner_rounded,
            label: 'Scan Label',
            selected: false,
            onTap: onScanLabelTap,
          ),
          _EntryTab(
            uiScale: uiScale,
            icon: Icons.image_outlined,
            label: 'Upload Image',
            selected: false,
            onTap: onUploadImageTap,
          ),
          _EntryTab(
            uiScale: uiScale,
            icon: Icons.edit_note_rounded,
            label: 'Manual Entry',
            selected: true,
            onTap: null,
          ),
        ],
      ),
    );
  }
}

class _EntryTab extends StatelessWidget {
  const _EntryTab({
    required this.uiScale,
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
  });
  final double uiScale;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(vertical: 10 * uiScale),
          decoration: BoxDecoration(
            color: selected
                ? colors.surface.withValues(alpha: 0.85)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: selected
                ? Border(
                    bottom: BorderSide(
                      color: colors.iconPurple,
                      width: 2,
                    ),
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16 * uiScale,
                color: selected
                    ? colors.iconPurple
                    : colors.textMuted,
              ),
              SizedBox(height: 3 * uiScale),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5 * uiScale,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected
                      ? colors.iconPurple
                      : colors.textSecondary,
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
// Reusable frosted text field
// ---------------------------------------------------------------------------
class _GlassTextField extends StatelessWidget {
  const _GlassTextField({
    required this.uiScale,
    required this.controller,
    required this.hint,
    this.icon,
    this.trailing,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
  });

  final double uiScale;
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final Widget? trailing;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.cardBorder),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 12.5 * uiScale,
          color: colors.textPrimary,
        ),
        decoration: InputDecoration(
          counterText: '',
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 12 * uiScale,
            color: colors.textMuted,
          ),
          prefixIcon: icon == null
              ? null
              : Padding(
                  padding: EdgeInsets.only(
                    left: 12 * uiScale,
                    right: 6 * uiScale,
                  ),
                  child: Icon(
                    icon,
                    size: 16 * uiScale,
                    color: colors.iconPurple,
                  ),
                ),
          prefixIconConstraints: BoxConstraints(minWidth: 32 * uiScale),
          suffixIcon: trailing,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: icon == null ? 14 * uiScale : 4 * uiScale,
            vertical: 13 * uiScale,
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.uiScale,
    required this.text,
    this.required = false,
  });
  final double uiScale;
  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Padding(
      padding: EdgeInsets.only(bottom: 6 * uiScale),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 12 * uiScale,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
          children: [
            TextSpan(text: text),
            if (required)
              TextSpan(
                text: ' *',
                style: TextStyle(color: colors.iconOrange),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 1 — Product Information
// ---------------------------------------------------------------------------
class _ProductInfoSection extends StatelessWidget {
  const _ProductInfoSection({
    required this.uiScale,
    required this.productNameCtrl,
    required this.brandCtrl,
    required this.servingSizeCtrl,
    required this.selectedUnit,
    required this.onUnitChanged,
  });

  final double uiScale;
  final TextEditingController productNameCtrl;
  final TextEditingController brandCtrl;
  final TextEditingController servingSizeCtrl;
  final String selectedUnit;
  final ValueChanged<String> onUnitChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          uiScale: uiScale,
          number: 1,
          title: 'Product Information',
        ),
        SizedBox(height: 14 * uiScale),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 340;
            final nameField = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel(
                  uiScale: uiScale,
                  text: 'Product Name',
                  required: true,
                ),
                _GlassTextField(
                  uiScale: uiScale,
                  controller: productNameCtrl,
                  hint: 'Enter product name',
                  icon: Icons.deblur_rounded,
                ),
              ],
            );

            final brandField = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel(uiScale: uiScale, text: 'Brand (Optional)'),
                _GlassTextField(
                  uiScale: uiScale,
                  controller: brandCtrl,
                  hint: 'Enter brand name',
                  icon: Icons.storefront_rounded,
                ),
              ],
            );
            if (narrow) {
              return Column(
                children: [
                  nameField,
                  SizedBox(height: 12 * uiScale),
                  brandField,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: nameField),
                SizedBox(width: 12 * uiScale),
                Expanded(child: brandField),
              ],
            );
          },
        ),
        SizedBox(height: 12 * uiScale),
        _FieldLabel(uiScale: uiScale, text: 'Serving Size', required: true),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _GlassTextField(
                uiScale: uiScale,
                controller: servingSizeCtrl,
                hint: 'e.g., 40 g / 1 cup / 100 ml',
                icon: Icons.restaurant_rounded,
              ),
            ),
            SizedBox(width: 10 * uiScale),
            _UnitToggleGroup(
              uiScale: uiScale,
              selected: selectedUnit,
              onChanged: onUnitChanged,
            ),
          ],
        ),
      ],
    );
  }
}

class _UnitToggleGroup extends StatelessWidget {
  const _UnitToggleGroup({
    required this.uiScale,
    required this.selected,
    required this.onChanged,
  });
  final double uiScale;
  final String selected;
  final ValueChanged<String> onChanged;

  static const _units = ['g', 'ml', 'cup'];

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Container(
      padding: EdgeInsets.all(3 * uiScale),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _units.map((u) {
          final isSelected = u == selected;
          return GestureDetector(
            onTap: () => onChanged(u),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              margin: EdgeInsets.symmetric(horizontal: 2 * uiScale),
              padding: EdgeInsets.symmetric(
                horizontal: 10 * uiScale,
                vertical: 9 * uiScale,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.iconPurple
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                u,
                style: TextStyle(
                  fontSize: 11.5 * uiScale,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : colors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 2 — Nutrition Facts
// ---------------------------------------------------------------------------
class _NutrientField {
  const _NutrientField(this.label, this.unit, this.asset, this.color);
  final String label;
  final String unit;
  final String asset;
  final Color color;

  static const basics = [
    _NutrientField(
      'Calories',
      'kcal',
      'assets/images/calories.jpeg',
      Color(0xFFE0862E),
    ),
    _NutrientField(
      'Protein',
      'g',
      'assets/images/protein.jpeg',
      Color(0xFF1E8A4C),
    ),
    _NutrientField(
      'Carbohydrates',
      'g',
      'assets/images/carbohydrate.jpeg',
      Color(0xFF6C4EF5),
    ),
    _NutrientField(
      'Total Fat',
      'g',
      'assets/images/fat.jpeg',
      Color(0xFFE0B32E),
    ),
    _NutrientField('Fibre', 'g', 'assets/images/fibre.jpeg', Color(0xFF1E8A4C)),
    _NutrientField('Sugar', 'g', 'assets/images/sugar.jpeg', Color(0xFFE84D6B)),
    _NutrientField(
      'Sodium',
      'mg',
      'assets/images/sodium.jpeg',
      Color(0xFF3B82F6),
    ),
  ];

  static const extras = [
    _NutrientField(
      'Saturated Fat',
      'g',
      'assets/images/saturated_fat.jpeg',
      Color(0xFFE0B32E),
    ),
    _NutrientField(
      'Cholesterol',
      'mg',
      'assets/images/cholesterol.jpeg',
      Color(0xFFE0862E),
    ),
    _NutrientField(
      'Calcium',
      'mg',
      'assets/images/calcium.jpeg',
      Color(0xFFB0ACC2),
    ),
    _NutrientField('Iron', 'mg', 'assets/images/iron.jpeg', Color(0xFF6B6B7B)),
  ];
}

class _NutritionFactsSection extends StatelessWidget {
  const _NutritionFactsSection({
    required this.uiScale,
    required this.perServing,
    required this.onToggle,
    required this.controllers,
    required this.showMore,
    required this.onToggleMore,
    required this.extraControllers,
  });

  final double uiScale;
  final bool perServing;
  final ValueChanged<bool> onToggle;
  final Map<String, TextEditingController> controllers;
  final bool showMore;
  final VoidCallback onToggleMore;
  final Map<String, TextEditingController> extraControllers;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  _StepBadge(uiScale: uiScale, number: 2),
                  SizedBox(width: 8 * uiScale),
                  Flexible(
                    child: Text(
                      'Nutrition Facts',
                      style: TextStyle(
                        fontSize: 15 * uiScale,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(width: 4 * uiScale),
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14 * uiScale,
                    color: colors.textMuted,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 10 * uiScale),
        _PerServingToggle(
          uiScale: uiScale,
          perServing: perServing,
          onToggle: onToggle,
        ),
        SizedBox(height: 14 * uiScale),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth < 340 ? 2 : 4;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _NutrientField.basics.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 10 * uiScale,
                crossAxisSpacing: 10 * uiScale,
                childAspectRatio: 1.45,
              ),
              itemBuilder: (context, i) {
                final n = _NutrientField.basics[i];
                return _NutrientCell(
                  uiScale: uiScale,
                  field: n,
                  controller: controllers[n.label]!,
                );
              },
            );
          },
        ),
        SizedBox(height: 12 * uiScale),
        GestureDetector(
          onTap: onToggleMore,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12 * uiScale,
              vertical: 12 * uiScale,
            ),
            decoration: BoxDecoration(
              color: colors.iconPurpleBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 26 * uiScale,
                  height: 26 * uiScale,
                  decoration: BoxDecoration(
                    color: colors.iconPurple,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    size: 15 * uiScale,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 10 * uiScale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add More Nutrients',
                        style: TextStyle(
                          fontSize: 12.5 * uiScale,
                          fontWeight: FontWeight.w800,
                          color: colors.iconPurple,
                        ),
                      ),
                      Text(
                        'Saturated Fat, Cholesterol, Calcium, Iron & more',
                        style: TextStyle(
                          fontSize: 10.5 * uiScale,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: showMore ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20 * uiScale,
                    color: colors.iconPurple,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: showMore
              ? Padding(
                  padding: EdgeInsets.only(top: 12 * uiScale),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = constraints.maxWidth < 340 ? 2 : 4;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _NutrientField.extras.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          mainAxisSpacing: 10 * uiScale,
                          crossAxisSpacing: 10 * uiScale,
                          childAspectRatio: 0.92,
                        ),
                        itemBuilder: (context, i) {
                          final n = _NutrientField.extras[i];
                          return _NutrientCell(
                            uiScale: uiScale,
                            field: n,
                            controller: extraControllers[n.label]!,
                            fallbackIcon: Icons.science_outlined,
                          );
                        },
                      );
                    },
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _PerServingToggle extends StatelessWidget {
  const _PerServingToggle({
    required this.uiScale,
    required this.perServing,
    required this.onToggle,
  });
  final double uiScale;
  final bool perServing;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Container(
      padding: EdgeInsets.all(3 * uiScale),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(vertical: 9 * uiScale),
                decoration: BoxDecoration(
                  color: !perServing
                      ? colors.iconPurple
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Per 100g',
                  style: TextStyle(
                    fontSize: 11.5 * uiScale,
                    fontWeight: FontWeight.w700,
                    color: !perServing ? Colors.white : colors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(vertical: 9 * uiScale),
                decoration: BoxDecoration(
                  color: perServing
                      ? colors.iconPurple
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add,
                      size: 12 * uiScale,
                      color: perServing
                          ? Colors.white
                          : colors.textSecondary,
                    ),
                    SizedBox(width: 3 * uiScale),
                    Text(
                      'Per Serving',
                      style: TextStyle(
                        fontSize: 11.5 * uiScale,
                        fontWeight: FontWeight.w700,
                        color: perServing
                            ? Colors.white
                            : colors.textSecondary,
                      ),
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

class _NutrientCell extends StatelessWidget {
  const _NutrientCell({
    required this.uiScale,
    required this.field,
    required this.controller,
    this.fallbackIcon,
  });
  final double uiScale;
  final _NutrientField field;
  final TextEditingController controller;
  final IconData? fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Container(
      padding: EdgeInsets.all(6 * uiScale),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              field.asset.isNotEmpty
                  ? Image.asset(
                      field.asset,
                      width: 70 * uiScale,
                      height: 70 * uiScale,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        fallbackIcon ?? Icons.circle,
                        size: 30 * uiScale,
                        color: field.color,
                      ),
                    )
                  : Icon(
                      fallbackIcon ?? Icons.circle,
                      size: 14 * uiScale,
                      color: field.color,
                    ),
            ],
          ),
          SizedBox(height: 2 * uiScale),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(
                    fontSize: 13 * uiScale,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '0',
                    hintStyle: TextStyle(color: colors.textMuted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              Text(
                field.unit,
                style: TextStyle(
                  fontSize: 9.5 * uiScale,
                  color: colors.textMuted,
                  fontWeight: FontWeight.w600,
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
// Section 3 — Ingredients
// ---------------------------------------------------------------------------
class _IngredientsSection extends StatelessWidget {
  const _IngredientsSection({required this.uiScale, required this.controller});
  final double uiScale;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(uiScale: uiScale, number: 3, title: 'Ingredients'),
        SizedBox(height: 12 * uiScale),
        _GlassTextField(
          uiScale: uiScale,
          controller: controller,
          hint: 'Enter ingredients listed on the package...',
          maxLines: 4,
          maxLength: 500,
        ),
        SizedBox(height: 4 * uiScale),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${controller.text.length}/500',
            style: TextStyle(
              fontSize: 10 * uiScale,
              color: colors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Section 4 — Allergens
// ---------------------------------------------------------------------------
class _AllergenItem {
  const _AllergenItem(this.name, this.asset, this.color, {this.fallbackIcon});
  final String name;
  final String asset;
  final Color color;
  final IconData? fallbackIcon;

  static const items = [
    _AllergenItem('Milk', 'assets/images/milk.jpeg', Color(0xFF3B82F6)),
    _AllergenItem('Egg', 'assets/images/egg.jpeg', Color(0xFFE0862E)),
    _AllergenItem('Peanut', 'assets/images/peanut.jpeg', Color(0xFFB2662E)),
    _AllergenItem(
      'Tree Nuts',
      'assets/images/tree_nut.jpeg',
      Color(0xFF8A5A2E),
    ),
    _AllergenItem('Soy', 'assets/images/soy.jpeg', Color(0xFF1E8A4C)),
    _AllergenItem('Wheat', 'assets/images/wheat.jpeg', Color(0xFFE0B32E)),
    _AllergenItem('Fish', 'assets/images/fish.jpeg', Color(0xFF3B82F6)),
    _AllergenItem(
      'Shellfish',
      'assets/images/shellfish.jpeg',
      Color(0xFFE84D6B),
      fallbackIcon: Icons.set_meal_rounded,
    ),
    _AllergenItem('Sesame', 'assets/images/sesame.jpeg', Color(0xFFE0862E)),
    _AllergenItem('Other', 'assets/images/other.jpeg', Color(0xFF6C4EF5)),
  ];
}

class _AllergensSection extends StatelessWidget {
  const _AllergensSection({
    required this.uiScale,
    required this.selected,
    required this.onToggle,
    required this.showOtherInput,
    required this.otherCtrl,
    required this.onToggleOtherInput,
  });

  final double uiScale;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final bool showOtherInput;
  final TextEditingController otherCtrl;
  final VoidCallback onToggleOtherInput;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StepBadge(uiScale: uiScale, number: 4),
            SizedBox(width: 8 * uiScale),
            Text(
              'Allergens',
              style: TextStyle(
                fontSize: 15 * uiScale,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            SizedBox(width: 6 * uiScale),
            Expanded(
              child: Text(
                'Select all that apply',
                style: TextStyle(
                  fontSize: 10.5 * uiScale,
                  color: colors.textSecondary,
                ),
              ),
            ),
            GestureDetector(
              onTap: onToggleOtherInput,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 9 * uiScale,
                  vertical: 6 * uiScale,
                ),
                decoration: BoxDecoration(
                  color: colors.iconPurpleBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add,
                      size: 12 * uiScale,
                      color: colors.iconPurple,
                    ),
                    SizedBox(width: 3 * uiScale),
                    Text(
                      'Add Other',
                      style: TextStyle(
                        fontSize: 10.5 * uiScale,
                        fontWeight: FontWeight.w700,
                        color: colors.iconPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: showOtherInput
              ? Padding(
                  padding: EdgeInsets.only(
                    top: 10 * uiScale,
                    bottom: 4 * uiScale,
                  ),
                  child: _GlassTextField(
                    uiScale: uiScale,
                    controller: otherCtrl,
                    hint: 'Type a custom allergen...',
                    icon: Icons.edit_rounded,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        SizedBox(height: 12 * uiScale),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth < 340 ? 2 : 4;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _AllergenItem.items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 10 * uiScale,
                crossAxisSpacing: 10 * uiScale,
                childAspectRatio: 1.55,
              ),
              itemBuilder: (context, i) {
                final a = _AllergenItem.items[i];
                final isSelected = selected.contains(a.name);
                return _AllergenChip(
                  uiScale: uiScale,
                  item: a,
                  selected: isSelected,
                  onTap: () => onToggle(a.name),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _AllergenChip extends StatelessWidget {
  const _AllergenChip({
    required this.uiScale,
    required this.item,
    required this.selected,
    required this.onTap,
  });
  final double uiScale;
  final _AllergenItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: 9 * uiScale,
          vertical: 8 * uiScale,
        ),
        decoration: BoxDecoration(
          color: selected
              ? colors.iconPurpleBg
              : colors.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? colors.iconPurple : colors.cardBorder,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            item.asset.isNotEmpty
                ? Image.asset(
                    item.asset,
                    width: 70 * uiScale,
                    height: 70 * uiScale,
                    errorBuilder: (_, __, ___) => Icon(
                      item.fallbackIcon ?? Icons.circle,
                      size: 14 * uiScale,
                      color: item.color,
                    ),
                  )
                : Icon(
                    item.fallbackIcon ?? Icons.circle,
                    size: 14 * uiScale,
                    color: item.color,
                  ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 15 * uiScale,
              height: 15 * uiScale,
              decoration: BoxDecoration(
                color: selected ? colors.iconPurple : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: selected
                      ? colors.iconPurple
                      : colors.cardBorder,
                  width: 1.4,
                ),
              ),
              child: selected
                  ? Icon(Icons.check, size: 11 * uiScale, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AI helper card (real robot image, floating)
// ---------------------------------------------------------------------------
class _AiHelperCard extends StatelessWidget {
  const _AiHelperCard({required this.uiScale, required this.ambientCtrl});
  final double uiScale;
  final AnimationController ambientCtrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 35 * uiScale),
          child: _GlassCard(
            uiScale: uiScale,
            child: Padding(
              padding: EdgeInsets.only(
                left: 95 * uiScale, // space for robot
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Let AI do the heavy lifting!',
                          style: TextStyle(
                            fontSize: 15 * uiScale,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(width: 4 * uiScale),
                      Icon(
                        Icons.auto_awesome,
                        size: 14 * uiScale,
                        color: colors.iconPurple,
                      ),
                    ],
                  ),
                  SizedBox(height: 6 * uiScale),
                  Text(
                    'Our AI will analyze the nutrition data and provide health insights, product rating and healthier options.',
                    style: TextStyle(
                      fontSize: 11.5 * uiScale,
                      height: 1.4,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          left: -8 * uiScale,
          top: 20 * uiScale,
          child: AnimatedBuilder(
            animation: ambientCtrl,
            builder: (context, child) {
              final bob = math.sin(ambientCtrl.value * math.pi) * 5;

              return Transform.translate(offset: Offset(0, -bob), child: child);
            },
            child: Image.asset(
              'assets/images/robot_pointing.png',
              width: 130 * uiScale,
              height: 150 * uiScale,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom gradient CTA — "Analyze with AI"
// ---------------------------------------------------------------------------
class _AnalyzeButton extends StatefulWidget {
  const _AnalyzeButton({required this.uiScale, this.onTap});
  final double uiScale;
  final VoidCallback? onTap;

  @override
  State<_AnalyzeButton> createState() => _AnalyzeButtonState();
}

class _AnalyzeButtonState extends State<_AnalyzeButton> {
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
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16 * widget.uiScale),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF6C4EF5), Color(0xFF1E8A4C)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C4EF5).withValues(alpha: 0.32),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 16 * widget.uiScale,
              ),
              SizedBox(width: 8 * widget.uiScale),
              Text(
                'Analyze with AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15 * widget.uiScale,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: 8 * widget.uiScale),
              Container(
                width: 26 * widget.uiScale,
                height: 26 * widget.uiScale,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 14 * widget.uiScale,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({required this.uiScale});
  final double uiScale;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          size: 12 * uiScale,
          color: colors.textMuted,
        ),
        SizedBox(width: 5 * uiScale),
        Text(
          'Your data is private and secure with us.',
          style: TextStyle(
            fontSize: 10.5 * uiScale,
            color: colors.textMuted,
          ),
        ),
      ],
    );
  }
}
