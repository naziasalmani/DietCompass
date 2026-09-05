import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:diet_compass/core/theme/app_colors.dart';
import 'package:diet_compass/features/scan/result_screen.dart';
import '../../core/model/food_product.dart';
import '../../core/model/ai_analysis_model.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/recommendation_service.dart';
import '../../core/services/product_analysis_engine.dart';


/// DietCompass — AI Analysis Screen
/// -----------------------------------------------------------------------
/// Shown immediately after a product photo is captured on the Scan
/// screen. Displays the captured image, then animates a 5-stage analysis
/// pipeline (Reading Label → Detecting Ingredients → Analyzing Nutrition
/// → Checking Additives → Finding Better Alternatives) plus a live,
/// human-readable insights feed, before handing off to your Nutrition
/// Result screen via [onAnalysisComplete].
///
/// Reuses your existing DietCompass robot asset
/// (assets/images/robot_pointing.png) and defaults the preview image to
/// assets/images/product_quaker.png when no captured photo is supplied.
///
/// -------------------------------------------------------------------
/// BACKEND-READY BY DESIGN
///
/// All progress state lives in [AnalysisProgressController], a plain
/// `ChangeNotifier` — not a timer baked into the widget. Two ways to use it:
///
/// 1. Demo / no backend yet — build with no controller and the screen
///    runs a smooth built-in ~6.5s simulation for you:
///    ```dart
///    AiAnalysisScreen(
///      capturedImage: FileImage(File(capturedPath)),
///      onAnalysisComplete: () => Navigator.pushReplacement(...),
///    )
///    ```
///
/// 2. Real backend — create a controller yourself and push updates as
///    your API/socket reports progress; the UI reacts automatically and
///    the built-in simulation is skipped entirely:
///    ```dart
///    final controller = AnalysisProgressController();
///    // ... as events arrive from your backend:
///    controller.updateStep(0, percent: 100, status: StepStatus.completed);
///    controller.updateStep(1, percent: 60, status: StepStatus.inProgress);
///    // when every step reports StepStatus.completed, the screen
///    // automatically calls onAnalysisComplete.
///    AiAnalysisScreen(controller: controller, capturedImage: ..., onAnalysisComplete: ...)
///    ```
/// -------------------------------------------------------------------
///
/// Add to pubspec.yaml (skip any already present from earlier screens):
/// ```yaml
/// flutter:
///   assets:
///     - assets/images/robot_pointing.png
///     - assets/images/product_quaker.png
/// ```
enum StepStatus { pending, inProgress, completed }

class AnalysisStep {
  AnalysisStep({
    required this.label,
    required this.icon,
    required this.color,
    this.percent = 0,
    this.status = StepStatus.pending,
  });

  final String label;
  final IconData icon;
  final Color color;
  double percent;
  StepStatus status;
}

class InsightItem {
  InsightItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.stepIndex,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  /// Index into [AnalysisProgressController.steps] this insight mirrors —
  /// its status badge always reflects that step's current status.
  final int stepIndex;
}

/// Holds all analysis state for the screen. Plain `ChangeNotifier` so it
/// can be driven by a timer-based simulation (the default) or by real
/// backend events (production).
class AnalysisProgressController extends ChangeNotifier {
  AnalysisProgressController({
    List<AnalysisStep>? steps,
    List<InsightItem>? insights,
    this.estimatedTime = '5 - 10 seconds',
  })  : steps = steps ?? defaultSteps(),
        insights = insights ?? defaultInsights();

  final List<AnalysisStep> steps;
  final List<InsightItem> insights;
  String estimatedTime;

  bool get isComplete =>
      steps.every((s) => s.status == StepStatus.completed);

  void updateStep(int index, {double? percent, StepStatus? status}) {
    final step = steps[index];
    if (percent != null) step.percent = percent.clamp(0, 100);
    if (status != null) {
      step.status = status;
    } else if (percent != null) {
      step.status = percent <= 0
          ? StepStatus.pending
          : (percent >= 100 ? StepStatus.completed : StepStatus.inProgress);
    }
    notifyListeners();
  }

  void setEstimatedTime(String text) {
    estimatedTime = text;
    notifyListeners();
  }

  static List<AnalysisStep> defaultSteps() => [
        AnalysisStep(
          label: 'Reading Label',
          icon: Icons.center_focus_strong,
          color: const Color(0xFF6C4EF5),
        ),
        AnalysisStep(
          label: 'Detecting Ingredients',
          icon: Icons.eco,
          color: const Color(0xFF1E8A4C),
        ),
        AnalysisStep(
          label: 'Analyzing Nutrition',
          icon: Icons.science_outlined,
          color: const Color(0xFF3B82F6),
        ),
        AnalysisStep(
          label: 'Checking Additives',
          icon: Icons.verified_user_outlined,
          color: const Color(0xFF6C4EF5),
        ),
        AnalysisStep(
          label: 'Finding Better Alternatives',
          icon: Icons.bar_chart_rounded,
          color: const Color(0xFFE0862E),
        ),
      ];

  static List<InsightItem> defaultInsights() => [
        InsightItem(
          title: 'Reading nutrition label...',
          subtitle: 'Extracting text from image',
          icon: Icons.title_rounded,
          color: const Color(0xFF6C4EF5),
          stepIndex: 0,
        ),
        InsightItem(
          title: 'Identifying ingredients...',
          subtitle: 'Found 12 ingredients',
          icon: Icons.eco,
          color: const Color(0xFF1E8A4C),
          stepIndex: 1,
        ),
        InsightItem(
          title: 'Detecting additives & sugars...',
          subtitle: 'Analyzing for hidden sugars and additives',
          icon: Icons.hexagon_outlined,
          color: const Color(0xFFE0862E),
          stepIndex: 2,
        ),
        InsightItem(
          title: 'Evaluating health compatibility...',
          subtitle: 'Matching with your health profile',
          icon: Icons.shield_outlined,
          color: const Color(0xFF3B82F6),
          stepIndex: 3,
        ),
        InsightItem(
          title: 'Finding healthier alternatives...',
          subtitle: 'Searching for better options',
          icon: Icons.auto_awesome,
          color: const Color(0xFFE0525C),
          stepIndex: 4,
        ),
      ];
}

class AiAnalysisScreen extends StatefulWidget {
  const AiAnalysisScreen({
  super.key,
  this.capturedImage,
  this.product,
  required this.productName,
  required this.productSubtitle,
    this.servingInfo = '40 g (1 serving)',
    this.imageQualityLabel = 'Good',
    this.foodTypeLabel = 'Healthy Choice',
    this.controller,
    this.simulationDuration = const Duration(milliseconds: 6500),
    this.onCancel,
    this.onAnalysisComplete,
    this.onAskAiTap,
  });

  /// The photo captured on the Scan screen. Falls back to the bundled
  /// oats product photo when not supplied (e.g. while wiring this screen
  /// up before the camera flow feeds it a real image).
  final ImageProvider? capturedImage;

  final FoodProduct? product;

  final String productName;
  final String productSubtitle;
  final String servingInfo;
  final String imageQualityLabel;
  final String foodTypeLabel;

  /// Supply your own controller to drive progress from a real backend.
  /// Leave null to run the built-in simulated pipeline.
  final AnalysisProgressController? controller;

  /// Total duration of the built-in simulation (ignored if [controller]
  /// is supplied).
  final Duration simulationDuration;

  final VoidCallback? onCancel;

  /// Called once every step reaches [StepStatus.completed] — navigate to
  /// your Nutrition Result screen here.
  final VoidCallback? onAnalysisComplete;

  final VoidCallback? onAskAiTap;

  @override
  State<AiAnalysisScreen> createState() => _AiAnalysisScreenState();
}

class _AiAnalysisScreenState extends State<AiAnalysisScreen>
    with TickerProviderStateMixin {
  late final AnalysisProgressController _controller;
  late final bool _ownsController;
  AnimationController? _simCtrl;
  late final AnimationController _entranceCtrl;
  late final AnimationController _ambientCtrl;
  bool _completionHandled = false;
  ProductAiAnalysisResult? _analysisResult;
  ProductCompatibility? _compatibility;
  CanonicalProductAnalysis? _canonicalAnalysis;

  // Each step's [start, end] fraction of the simulation timeline —
  // overlapping like a real pipeline, matching the reference snapshot.
  static const List<List<double>> _simIntervals = [
    [0.0, 0.18],
    [0.08, 0.42],
    [0.32, 0.68],
    [0.58, 0.88],
    [0.82, 1.0],
  ];

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? AnalysisProgressController();
    _controller.addListener(_handleControllerChange);

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _logAndStartAnalysis();

    if (_ownsController) {
      _runSimulation();
    }
  }

  void _logAndStartAnalysis() {
    final product = widget.product;
    final hasNutrition = product?.calories != null ||
        product?.protein != null ||
        product?.carbohydrates != null ||
        product?.fat != null ||
        product?.sugar != null ||
        product?.sodium != null;
    final hasImage = widget.capturedImage != null ||
        (product?.imageUrl.trim().isNotEmpty ?? false);

    debugPrint('\n==============================================');
    debugPrint('[AI PRODUCT ANALYSIS]');
    debugPrint('productName = ${widget.productName}');
    debugPrint('brand = ${widget.productSubtitle}');
    debugPrint('nutritionSource = ${hasNutrition ? "manual/api" : "none"}');
    debugPrint('imageAvailable = $hasImage');
    debugPrint('userProfileLoaded = true');
    debugPrint('==============================================\n');

    if (product != null) {
      _canonicalAnalysis = ProductAnalysisEngine.instance.analyzeProduct(product);
      _compatibility = _canonicalAnalysis!.compatibility;
      
      AiService.instance.analyzeProduct(product).then((res) {
        _analysisResult = res;
      }).catchError((e) {
        debugPrint('[AiAnalysisScreen] Background AI analysis notice: $e');
      }).whenComplete(() {
        debugPrint('\n==============================================');
        debugPrint('[AI ANALYSIS RESULT]');
        debugPrint('productName = ${widget.productName}');
        debugPrint('compatibilityScore = ${_compatibility?.score ?? 0}');
        debugPrint('analysisSource = deterministic');
        debugPrint('==============================================\n');
      });
    }
  }


  void _runSimulation() {
    final sim = AnimationController(
      vsync: this,
      duration: widget.simulationDuration,
    );
    _simCtrl = sim;
    sim.addListener(() {
      final t = sim.value;
      for (var i = 0; i < _controller.steps.length; i++) {
        final range = _simIntervals[i];
        final localT =
            ((t - range[0]) / (range[1] - range[0])).clamp(0.0, 1.0);
        final eased = Curves.easeOut.transform(localT);
        _controller.updateStep(i, percent: eased * 100);
      }
    });
    sim.forward();
  }

  void _handleControllerChange() {
    if (!mounted) return;

    setState(() {});

    if (_controller.isComplete && !_completionHandled) {
      _completionHandled = true;

      final product = widget.product;
      final hasNutrition = product?.calories != null ||
          product?.protein != null ||
          product?.carbohydrates != null ||
          product?.fat != null ||
          product?.sugar != null ||
          product?.sodium != null;
      final hasImage = widget.capturedImage != null ||
          (product?.imageUrl.trim().isNotEmpty ?? false);

      debugPrint('\n==============================================');
      debugPrint('[AI RESULT]');
      debugPrint('productName = ${widget.productName}');
      debugPrint('brand = ${widget.productSubtitle}');
      debugPrint('imageAvailable = $hasImage');
      debugPrint('nutritionAvailable = $hasNutrition');
      debugPrint('source = ${product?.source ?? "manual"}');
      debugPrint('==============================================\n');

      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;

        if (widget.product != null) {
          final canonical = _canonicalAnalysis ?? ProductAnalysisEngine.instance.analyzeProduct(widget.product!);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ResultScreen(
                product: widget.product!,
                productImage: widget.capturedImage,
                initialCompatibility: canonical.compatibility,
                canonicalAnalysis: canonical,
              ),
            ),
          );
        }

      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChange);
    if (_ownsController) _controller.dispose();
    _simCtrl?.dispose();
    _entranceCtrl.dispose();
    _ambientCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 390).clamp(0.85, 1.25);
    final colors = context.dcColors;

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          children: [
            FadeTransition(
              opacity: CurvedAnimation(
                parent: _entranceCtrl,
                curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
              ),
              child: _TopBar(uiScale: scale, onBack: widget.onCancel, onCancel: widget.onCancel),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  18 * scale,
                  4 * scale,
                  18 * scale,
                  24 * scale,
                ),
                physics: const BouncingScrollPhysics(),
                children: [
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _entranceCtrl,
                      curve: const Interval(0.05, 0.5, curve: Curves.easeOut),
                    ),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.08),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _entranceCtrl,
                          curve: const Interval(0.05, 0.55, curve: Curves.easeOutCubic),
                        ),
                      ),
                      child: _ProductCard(
                        uiScale: scale,
                        image: widget.capturedImage,
                        product: widget.product,
                        name: widget.productName,
                        subtitle: widget.productSubtitle,
                        servingInfo: widget.servingInfo,
                        imageQualityLabel: widget.imageQualityLabel,
                        foodTypeLabel: widget.foodTypeLabel,
                      ),
                    ),
                  ),
                  SizedBox(height: 16 * scale),

                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _entranceCtrl,
                      curve: const Interval(0.12, 0.6, curve: Curves.easeOut),
                    ),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.08),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _entranceCtrl,
                          curve: const Interval(0.12, 0.65, curve: Curves.easeOutCubic),
                        ),
                      ),
                      child: _AnalyzingCard(
                        uiScale: scale,
                        controller: _controller,
                        ambientCtrl: _ambientCtrl,
                      ),
                    ),
                  ),
                  SizedBox(height: 18 * scale),

                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _entranceCtrl,
                      curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
                    ),
                    child: _InsightsCard(uiScale: scale, controller: _controller),
                  ),
                  SizedBox(height: 16 * scale),

                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _entranceCtrl,
                      curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
                    ),
                    child: _AskAiBanner(
                      uiScale: scale,
                      ambientCtrl: _ambientCtrl,
                      onTap: widget.onAskAiTap,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------
class _TopBar extends StatelessWidget {
  const _TopBar({required this.uiScale, this.onBack, this.onCancel});
  final double uiScale;
  final VoidCallback? onBack;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Padding(
      padding: EdgeInsets.fromLTRB(16 * uiScale, 8 * uiScale, 16 * uiScale, 4 * uiScale),
      child: Row(
        children: [
          _RoundIconButton(
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
                    Icon(Icons.auto_awesome, size: 15 * uiScale, color: colors.iconPurple),
                    SizedBox(width: 5 * uiScale),
                    Text(
                      'AI Analysis',
                      style: TextStyle(
                        fontSize: 16 * uiScale,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 11 * uiScale, color: colors.textSecondary),
                    children: [
                      const TextSpan(text: 'Our AI is '),
                      TextSpan(
                        text: 'analyzing',
                        style: TextStyle(color: colors.iconPurple, fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: ' your product…'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _CancelPill(uiScale: uiScale, onTap: onCancel),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatefulWidget {
  const _RoundIconButton({required this.uiScale, required this.icon, this.onTap});
  final double uiScale;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  State<_RoundIconButton> createState() => _RoundIconButtonState();
}

class _RoundIconButtonState extends State<_RoundIconButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
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
          child: Icon(widget.icon, size: 18 * widget.uiScale, color: colors.textPrimary),
        ),
      ),
    );
  }
}

class _CancelPill extends StatefulWidget {
  const _CancelPill({required this.uiScale, this.onTap});
  final double uiScale;
  final VoidCallback? onTap;

  @override
  State<_CancelPill> createState() => _CancelPillState();
}

class _CancelPillState extends State<_CancelPill> {
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
          padding: EdgeInsets.symmetric(horizontal: 12 * widget.uiScale, vertical: 9 * widget.uiScale),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: colors.isDark ? 0.20 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.close, size: 14 * widget.uiScale, color: colors.iconPurple),
              SizedBox(width: 4 * widget.uiScale),
              Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 12.5 * widget.uiScale,
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
// Product card (captured image)
// ---------------------------------------------------------------------------
class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.uiScale,
    this.image,
    this.product,
    required this.name,
    required this.subtitle,
    required this.servingInfo,
    required this.imageQualityLabel,
    required this.foodTypeLabel,
  });

  final double uiScale;
  final ImageProvider? image;
  final FoodProduct? product;
  final String name;
  final String subtitle;
  final String servingInfo;
  final String imageQualityLabel;
  final String foodTypeLabel;

  ImageProvider? _resolveImage() {
    if (image != null) return image;
    final imgUrl = product?.imageUrl.trim() ?? '';
    if (imgUrl.isNotEmpty) {
      if (imgUrl.startsWith('http://') || imgUrl.startsWith('https://')) {
        return NetworkImage(imgUrl);
      } else if (imgUrl.startsWith('assets/')) {
        return AssetImage(imgUrl);
      }
    }
    return null;
  }

  Widget _buildPlaceholder(BuildContext context, double uiScale) {
    final colors = context.dcColors;
    return Container(
      color: colors.surfaceSecondary,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fastfood_rounded,
            size: 26 * uiScale,
            color: colors.iconPurple,
          ),
          SizedBox(height: 4 * uiScale),
          Text(
            'No Image',
            style: TextStyle(
              fontSize: 9.5 * uiScale,
              color: colors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    final resolvedImage = _resolveImage();

    return Container(
      padding: EdgeInsets.all(14 * uiScale),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.20 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 78 * uiScale,
              height: 96 * uiScale,
              color: colors.surfaceSecondary,
              child: resolvedImage != null
                  ? Image(
                      image: resolvedImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(context, uiScale),
                    )
                  : _buildPlaceholder(context, uiScale),
            ),
          ),
          SizedBox(width: 12 * uiScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15.5 * uiScale,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: 2 * uiScale),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12 * uiScale, color: colors.textSecondary),
                ),
                SizedBox(height: 4 * uiScale),
                Row(
                  children: [
                    Icon(
                      Icons.scale_outlined,
                      size: 12 * uiScale,
                      color: colors.textMuted,
                    ),
                    SizedBox(width: 4 * uiScale),
                    Expanded(
                      child: Text(
                        servingInfo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11 * uiScale,
                          color: colors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8 * uiScale),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8 * uiScale, vertical: 5 * uiScale),
                  decoration: BoxDecoration(
                    color: colors.iconGreenBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_rounded, size: 12 * uiScale, color: colors.iconGreen),
                      SizedBox(width: 5 * uiScale),
                      Text(
                        'Image Quality',
                        style: TextStyle(fontSize: 10 * uiScale, color: colors.textPrimary),
                      ),
                      SizedBox(width: 4 * uiScale),
                      Text(
                        imageQualityLabel,
                        style: TextStyle(
                          fontSize: 10 * uiScale,
                          fontWeight: FontWeight.w700,
                          color: colors.iconGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 90 * uiScale,
            margin: EdgeInsets.symmetric(horizontal: 6 * uiScale),
            color: colors.divider,
          ),
          Column(
            children: [
              Text(
                'Food type',
                style: TextStyle(fontSize: 10.5 * uiScale, color: colors.textSecondary),
              ),
              SizedBox(height: 8 * uiScale),
              Container(
                width: 44 * uiScale,
                height: 44 * uiScale,
                decoration: BoxDecoration(color: colors.iconGreenBg, shape: BoxShape.circle),
                child: Icon(Icons.eco, color: colors.iconGreen, size: 20 * uiScale),
              ),
              SizedBox(height: 6 * uiScale),
              Text(
                foodTypeLabel,
                style: TextStyle(
                  fontSize: 10.5 * uiScale,
                  fontWeight: FontWeight.w700,
                  color: colors.iconGreen,
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
// "Analyzing..." card: robot + 5-step progress row + estimated time
// ---------------------------------------------------------------------------
class _AnalyzingCard extends StatelessWidget {
  const _AnalyzingCard({
    required this.uiScale,
    required this.controller,
    required this.ambientCtrl,
  });

  final double uiScale;
  final AnalysisProgressController controller;
  final AnimationController ambientCtrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Container(
      padding: EdgeInsets.all(16 * uiScale),
      decoration: BoxDecoration(
        color: colors.iconPurpleBg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedBuilder(
                animation: ambientCtrl,
                builder: (context, child) {
                  final bob = math.sin(ambientCtrl.value * math.pi) * 5;
                  return Transform.translate(offset: Offset(0, -bob), child: child);
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 76 * uiScale,
                      height: 76 * uiScale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.surface.withValues(alpha: 0.5),
                      ),
                    ),
                    Image.asset('assets/images/robot_pointing.png', width: 66 * uiScale),
                  ],
                ),
              ),
              SizedBox(width: 14 * uiScale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 15 * uiScale, color: colors.iconPurple),
                        SizedBox(width: 5 * uiScale),
                        Text(
                          'Analyzing…',
                          style: TextStyle(
                            fontSize: 15.5 * uiScale,
                            fontWeight: FontWeight.w800,
                            color: colors.iconPurple,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4 * uiScale),
                    Text(
                      'DietCompass AI is reading ingredients, checking '
                      'nutrition facts and finding healthier alternatives '
                      'for you.',
                      style: TextStyle(fontSize: 11.5 * uiScale, height: 1.4, color: colors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20 * uiScale),
          _StepRow(uiScale: uiScale, steps: controller.steps),
          SizedBox(height: 16 * uiScale),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14 * uiScale, vertical: 12 * uiScale),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 34 * uiScale,
                  height: 34 * uiScale,
                  decoration: BoxDecoration(color: colors.surfaceSecondary, shape: BoxShape.circle),
                  child: Icon(Icons.timer_outlined, size: 17 * uiScale, color: colors.iconPurple),
                ),
                SizedBox(width: 10 * uiScale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated time',
                        style: TextStyle(fontSize: 10.5 * uiScale, color: colors.textSecondary),
                      ),
                      Text(
                        controller.estimatedTime,
                        style: TextStyle(
                          fontSize: 13 * uiScale,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Stay tuned…',
                      style: TextStyle(
                        fontSize: 12 * uiScale,
                        fontWeight: FontWeight.w700,
                        color: colors.iconPurple,
                      ),
                    ),
                    Text(
                      'Great things take a moment!',
                      style: TextStyle(fontSize: 9.5 * uiScale, color: colors.textSecondary),
                    ),
                  ],
                ),
                SizedBox(width: 8 * uiScale),
                Icon(Icons.hourglass_bottom_rounded, size: 20 * uiScale, color: colors.iconOrange),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.uiScale, required this.steps});
  final double uiScale;
  final List<AnalysisStep> steps;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final leftStep = steps[i ~/ 2];
          final rightStep = steps[i ~/ 2 + 1];
          final lineProgress = ((leftStep.percent / 100) + (rightStep.percent / 100)) / 2;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 26 * uiScale),
              child: Stack(
                children: [
                  Container(height: 3, width: double.infinity, color: colors.divider),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: lineProgress.clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 200),
                    builder: (context, value, child) {
                      return FractionallySizedBox(
                        widthFactor: value,
                        alignment: Alignment.centerLeft,
                        child: child,
                      );
                    },
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colors.iconPurple, colors.iconGreen],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        final step = steps[i ~/ 2];
        return _StepBadge(uiScale: uiScale, step: step);
      }),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.uiScale, required this.step});
  final double uiScale;
  final AnalysisStep step;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    final t = (step.percent / 100).clamp(0.0, 1.0);
    final bg = Color.lerp(colors.surfaceSecondary, step.color, t)!;

    return SizedBox(
      width: 58 * uiScale,
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: t),
            duration: const Duration(milliseconds: 200),
            builder: (context, value, child) {
              return Container(
                width: 52 * uiScale,
                height: 52 * uiScale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.lerp(colors.surfaceSecondary, step.color, value),
                  boxShadow: value > 0.05
                      ? [
                          BoxShadow(
                            color: step.color.withValues(alpha: 0.3 * value),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  step.icon,
                  size: 20 * uiScale,
                  color: Color.lerp(colors.textMuted, Colors.white, value),
                ),
              );
            },
          ),
          SizedBox(height: 6 * uiScale),
          Text(
            step.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9.5 * uiScale,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: 3 * uiScale),
          Text(
            '${step.percent.round()}%',
            style: TextStyle(fontSize: 10.5 * uiScale, fontWeight: FontWeight.w800, color: bg),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Live Analysis Insights list
// ---------------------------------------------------------------------------
class _InsightsCard extends StatelessWidget {
  const _InsightsCard({required this.uiScale, required this.controller});
  final double uiScale;
  final AnalysisProgressController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2 * uiScale),
          child: Row(
            children: [
              Icon(Icons.graphic_eq_rounded, size: 15 * uiScale, color: colors.iconPurple),
              SizedBox(width: 6 * uiScale),
              Text(
                'Live Analysis Insights',
                style: TextStyle(
                  fontSize: 14.5 * uiScale,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(width: 8 * uiScale),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8 * uiScale, vertical: 3 * uiScale),
                decoration: BoxDecoration(
                  color: colors.iconGreenBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Live',
                  style: TextStyle(
                    fontSize: 9.5 * uiScale,
                    fontWeight: FontWeight.w700,
                    color: colors.iconGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12 * uiScale),
        Container(
          padding: EdgeInsets.symmetric(vertical: 6 * uiScale),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
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
            children: List.generate(controller.insights.length, (i) {
              final insight = controller.insights[i];
              final status = controller.steps[insight.stepIndex].status;
              return _InsightRow(
                uiScale: uiScale,
                insight: insight,
                status: status,
                isLast: i == controller.insights.length - 1,
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.uiScale,
    required this.insight,
    required this.status,
    required this.isLast,
  });

  final double uiScale;
  final InsightItem insight;
  final StepStatus status;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12 * uiScale, vertical: 8 * uiScale),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 34 * uiScale,
                  height: 34 * uiScale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: status == StepStatus.pending
                        ? colors.surfaceSecondary
                        : insight.color.withValues(alpha: 0.14),
                  ),
                  child: Icon(
                    insight.icon,
                    size: 15 * uiScale,
                    color: status == StepStatus.pending
                        ? colors.textMuted
                        : insight.color,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.4,
                      margin: EdgeInsets.symmetric(vertical: 4 * uiScale),
                      color: colors.divider,
                    ),
                  ),
              ],
            ),
            SizedBox(width: 12 * uiScale),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 3 * uiScale, bottom: 10 * uiScale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.title,
                      style: TextStyle(
                        fontSize: 12.5 * uiScale,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2 * uiScale),
                    Text(
                      insight.subtitle,
                      style: TextStyle(fontSize: 10.5 * uiScale, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            _StatusBadge(uiScale: uiScale, status: status),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.uiScale, required this.status});
  final double uiScale;
  final StepStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    late final Color bg;
    late final Color fg;
    late final String label;
    late final Widget icon;

    switch (status) {
      case StepStatus.completed:
        bg = colors.iconGreenBg;
        fg = colors.iconGreen;
        label = 'Completed';
        icon = Icon(Icons.check_circle, size: 12 * uiScale, color: fg);
        break;
      case StepStatus.inProgress:
        bg = colors.iconOrangeBg;
        fg = colors.iconOrange;
        label = 'In Progress';
        icon = _SpinningIcon(uiScale: uiScale, color: fg);
        break;
      case StepStatus.pending:
        bg = colors.surfaceSecondary;
        fg = colors.textMuted;
        label = 'Pending';
        icon = const SizedBox.shrink();
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.symmetric(horizontal: 9 * uiScale, vertical: 5 * uiScale),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10 * uiScale, fontWeight: FontWeight.w700, color: fg),
          ),
          if (status != StepStatus.pending) ...[
            SizedBox(width: 4 * uiScale),
            icon,
          ],
        ],
      ),
    );
  }
}

class _SpinningIcon extends StatefulWidget {
  const _SpinningIcon({required this.uiScale, required this.color});
  final double uiScale;
  final Color color;

  @override
  State<_SpinningIcon> createState() => _SpinningIconState();
}

class _SpinningIconState extends State<_SpinningIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _ctrl,
      child: Icon(Icons.autorenew_rounded, size: 12 * widget.uiScale, color: widget.color),
    );
  }
}

// ---------------------------------------------------------------------------
// Ask AI banner
// ---------------------------------------------------------------------------
class _AskAiBanner extends StatelessWidget {
  const _AskAiBanner({required this.uiScale, required this.ambientCtrl, this.onTap});
  final double uiScale;
  final AnimationController ambientCtrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Container(
      padding: EdgeInsets.all(14 * uiScale),
      decoration: BoxDecoration(
        color: colors.iconPurpleBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: ambientCtrl,
            builder: (context, child) {
              final bob = math.sin(ambientCtrl.value * math.pi) * 3;
              return Transform.translate(offset: Offset(0, -bob), child: child);
            },
            child: Image.asset('assets/images/robot_pointing.png', width: 52 * uiScale),
          ),
          SizedBox(width: 12 * uiScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Want to know what we're checking?",
                  style: TextStyle(
                    fontSize: 12.5 * uiScale,
                    fontWeight: FontWeight.w800,
                    color: colors.iconPurple,
                  ),
                ),
                SizedBox(height: 2 * uiScale),
                Text(
                  'Our AI checks 50+ nutrition factors to give you the '
                  'best insights.',
                  style: TextStyle(fontSize: 10.5 * uiScale, height: 1.3, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          SizedBox(width: 8 * uiScale),
          _AskAiButton(uiScale: uiScale, onTap: onTap),
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
          padding: EdgeInsets.symmetric(horizontal: 14 * widget.uiScale, vertical: 11 * widget.uiScale),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(colors: [Color(0xFF6C4EF5), Color(0xFF1E8A4C)]),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 14 * widget.uiScale),
              SizedBox(width: 5 * widget.uiScale),
              Text(
                'Ask AI',
                style: TextStyle(color: Colors.white, fontSize: 12.5 * widget.uiScale, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
