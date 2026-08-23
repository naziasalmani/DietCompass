import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'ai_analysis_screen.dart';
import 'camera_scan_screen.dart';
import 'manual_entry_screen.dart';
import '../home/home_screen.dart';
import '../ai/ai_recommendation_screen.dart';
import '../pantry/pantry_screen.dart';
import '../dashboard/DashboardScreen.dart';
import 'result_screen.dart';
import 'scan_history_screen.dart';
import '../../core/model/scan_history_item.dart';
import '../../core/services/scan_history_service.dart';
import '../../core/services/product_image_analyzer.dart';

/// DietCompass — Scan Screen
/// -----------------------------------------------------------------------
/// Built directly on the supplied images:
///   • assets/images/bg_scan.jpeg             — full page background art
///   • assets/images/scan_hero.png            — phone/oats-bag hero
///     illustration with the AI Powered / Smart Analysis / Trusted
///     Results badges baked in
///   • assets/images/robot_badge.png          — small circular robot
///     avatar (header)
///   • assets/images/robot_pointing.png       — pointing robot mascot
///     (tips card), background-removed
///   • assets/images/icon_barcode.png         — Scan Barcode icon
///   • assets/images/icon_nutrition_label.png — Scan Nutrition Label icon
///   • assets/images/icon_gallery.png         — Import from Gallery icon
///   • assets/images/icon_manual_entry.png    — Manual Entry icon
///   • assets/images/product_amul.png, product_quaker.png,
///     product_maggi.png — reused from the home screen for Recent Scans
///
/// The "Scan Product" CTA, quick-action cards, recent scans row and tips
/// card are real, functional, animated Flutter UI matching the reference.
///
/// Add to pubspec.yaml:
/// 
///yaml
/// flutter:
///   assets:
///     - assets/images/bg_scan.jpeg
///     - assets/images/scan_hero.png
///     - assets/images/robot_badge.png
///     - assets/images/robot_pointing.png
///     - assets/images/icon_barcode.png
///     - assets/images/icon_nutrition_label.png
///     - assets/images/icon_gallery.png
///     - assets/images/icon_manual_entry.png
///

class ScanScreen extends StatefulWidget {
  const ScanScreen({
    super.key,
    this.userName = 'Nazia',
    this.onAiAssistantTap,
    this.onScanProductTap,
    this.onScanBarcodeTap,
    this.onScanLabelTap,
    this.onImportGalleryTap,
    this.onManualEntryTap,
    this.onViewAllScans,
    this.onProductTap,
    this.onNavTap,
    this.initialNavIndex = 1,
  });

  final String userName;
  final VoidCallback? onAiAssistantTap;
  final VoidCallback? onScanProductTap;
  final VoidCallback? onScanBarcodeTap;
  final VoidCallback? onScanLabelTap;
  final VoidCallback? onImportGalleryTap;
  final VoidCallback? onManualEntryTap;
  final VoidCallback? onViewAllScans;
  final ValueChanged<int>? onProductTap;
  final ValueChanged<int>? onNavTap;
  final int initialNavIndex;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _breatheCtrl;
  late final AnimationController _ambientCtrl;
  late int _navIndex;
  List<ScanHistoryItem> _liveScans = [];
  bool _isLoadingScans = false;

  @override
  void initState() {
    super.initState();
    _navIndex = widget.initialNavIndex;
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);
    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    if (ScanHistoryService.instance.currentHistory.isNotEmpty) {
      _liveScans = ScanHistoryService.instance.currentHistory.take(5).toList();
    }
    ScanHistoryService.instance.addListener(_onScanHistoryChanged);
    _loadScans();
  }

  void _onScanHistoryChanged() {
    if (!mounted) return;
    setState(() {
      _liveScans = ScanHistoryService.instance.currentHistory.take(5).toList();
      _isLoadingScans = false;
    });
  }

  Future<void> _loadScans() async {
    setState(() => _isLoadingScans = _liveScans.isEmpty);
    try {
      final items = await ScanHistoryService.instance.getScanHistory(limit: 5);
      if (mounted) {
        setState(() {
          _liveScans = items;
          _isLoadingScans = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingScans = false);
    }
  }

  @override
  void dispose() {
    ScanHistoryService.instance.removeListener(_onScanHistoryChanged);
    _entranceCtrl.dispose();
    _breatheCtrl.dispose();
    _ambientCtrl.dispose();
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 390).clamp(0.85, 1.25);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FB),
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _breatheCtrl,
            builder: (context, child) {
              final t = Curves.easeInOut.transform(_breatheCtrl.value);
              return Transform.scale(scale: 1.0 + t * 0.015, child: child);
            },
            child: Image.asset(
              'assets/images/bg_scan.jpeg',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          SafeArea(
            bottom: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                18 * scale,
                12 * scale,
                18 * scale,
                110 * scale,
              ),
              physics: const BouncingScrollPhysics(),
              children: [
                FadeTransition(
                  opacity: _fade(0.0, 0.3),
                  child: SlideTransition(
                    position: _slide(0.0, 0.35),
                    child: _HeaderRow(
                      uiScale: scale,
                      name: widget.userName,
                      onAiAssistantTap: widget.onAiAssistantTap,
                    ),
                  ),
                ),
                SizedBox(height: 22 * scale),

                FadeTransition(
                  opacity: _fade(0.08, 0.4),
                  child: SlideTransition(
                    position: _slide(0.08, 0.44),
                    child: _HeadlineBlock(uiScale: scale),
                  ),
                ),
                SizedBox(height: 18 * scale),

                FadeTransition(
                  opacity: _fade(0.15, 0.48),
                  child: SlideTransition(
                    position: _slide(0.15, 0.52),
                    child: _HeroIllustration(uiScale: scale),
                  ),
                ),
                SizedBox(height: 20 * scale),

                FadeTransition(
                  opacity: _fade(0.22, 0.55),
                  child: SlideTransition(
                    position: _slide(0.22, 0.6),
                    child: _ScanProductCta(
                      uiScale: scale,
                      onTap: () {
  Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => const CameraScanScreen(
      source: CameraSource.scan,
    ),
  ),
);
},
                    ),
                  ),
                ),
                SizedBox(height: 20 * scale),

                FadeTransition(
                  opacity: _fade(0.3, 0.62),
                  child: SlideTransition(
                    position: _slide(0.3, 0.66),
                    child: _QuickActionsGrid(
                      uiScale: scale,
                      onScanBarcode: widget.onScanBarcodeTap,
                      onScanLabel: widget.onScanLabelTap,
                     onImportGallery: () async {
  final XFile? image = await ImagePicker().pickImage(
    source: ImageSource.gallery,
  );

  if (image == null) return;

  final analyzer = ProductImageAnalyzer();

  try {
    final product = await analyzer.analyze(image);

    if (!mounted) return;

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not identify the product. Please upload a clearer image.',
          ),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AiAnalysisScreen(
          capturedImage: FileImage(
            File(image.path),
          ),
          product: product,
          productName: product.name,
          productSubtitle: product.brand ?? 'Food Product',
          servingInfo: 'Serving information unavailable',
          foodTypeLabel: 'Food Product',
        ),
      ),
    );
  } finally {
    await analyzer.dispose();
  }
},
                      onManualEntry: () {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => ManualEntryScreen(),
    ),
  );
},
                    ),
                  ),
                ),
                SizedBox(height: 22 * scale),

                FadeTransition(
                  opacity: _fade(0.38, 0.7),
                  child: SlideTransition(
                    position: _slide(0.38, 0.74),
                    child: _RecentScansSection(
                      uiScale: scale,
                      scans: _liveScans,
                      onViewAll: widget.onViewAllScans ??
                          () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ScanHistoryScreen(),
                                ),
                              ).then((_) => _loadScans()),
                      onProductTap: (index) {
                        if (widget.onProductTap != null) {
                          widget.onProductTap!(index);
                          return;
                        }
                        if (_liveScans.length > index) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ResultScreen(
                                product: _liveScans[index].toFoodProduct(),
                              ),
                            ),
                          ).then((_) => _loadScans());
                        }
                      },
                      onScanProductTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CameraScanScreen(
                            source: CameraSource.scan,
                          ),
                        ),
                      ).then((_) => _loadScans()),
                    ),
                  ),
                ),
                SizedBox(height: 20 * scale),

                FadeTransition(
                  opacity: _fade(0.46, 0.8),
                  child: SlideTransition(
                    position: _slide(0.46, 0.85),
                    child: _TipsCard(uiScale: scale, ambientCtrl: _ambientCtrl),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNavBar(
        uiScale: scale,
        selectedIndex: _navIndex,
        onTap: (i) {
  if (_navIndex == i) return;

  setState(() => _navIndex = i);

  switch (i) {
case 0:
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => HomeScreen(userName: widget.userName)),
  );
  break;

case 1:
  // Already on Scan
  break;

case 2:
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const AiShoppingScreen()),
  );
  break;

case 3:
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => PantryScreen()),
  );
  break;

case 4:
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => DashboardScreen()),
  );
  break;
}

  widget.onNavTap?.call(i);
},
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header: robot avatar + greeting + AI Assistant pill
// ---------------------------------------------------------------------------
class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.uiScale,
    required this.name,
    this.onAiAssistantTap,
  });

  final double uiScale;
  final String name;
  final VoidCallback? onAiAssistantTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       Container(
  width: 60 * uiScale,
  height: 60 * uiScale,
  decoration: const BoxDecoration(
  shape: BoxShape.circle,
),
  clipBehavior: Clip.antiAlias,
  child: ClipOval(
    child: SizedBox(
      width: 60 * uiScale,
      height: 60 * uiScale,
      child: Image.asset(
        'assets/images/robot_badge.png',
        fit: BoxFit.cover,
      ),
    ),
  ),
),
        SizedBox(width: 10 * uiScale),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Hi $name! ',
                    style: TextStyle(
                      fontSize: 17 * uiScale,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1B1B2E),
                    ),
                  ),
                  Text('👋', style: TextStyle(fontSize: 15 * uiScale)),
                ],
              ),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 12.5 * uiScale,
                    color: const Color(0xFF6B6B7B),
                  ),
                  children: const [
                    TextSpan(text: 'Ready to make '),
                    TextSpan(
                      text: 'healthier choices',
                      style: TextStyle(
                        color: Color(0xFF6C4EF5),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(text: ' today?'),
                  ],
                ),
              ),
            ],
          ),
        ),
        _AiAssistantPill(uiScale: uiScale, onTap: onAiAssistantTap),
      ],
    );
  }
}

class _AiAssistantPill extends StatefulWidget {
  const _AiAssistantPill({required this.uiScale, this.onTap});
  final double uiScale;
  final VoidCallback? onTap;

  @override
  State<_AiAssistantPill> createState() => _AiAssistantPillState();
}

class _AiAssistantPillState extends State<_AiAssistantPill> {
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
          padding: EdgeInsets.symmetric(
            horizontal: 10 * widget.uiScale,
            vertical: 8 * widget.uiScale,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE7FA),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 12 * widget.uiScale,
                color: const Color(0xFF6C4EF5),
              ),
              SizedBox(width: 4 * widget.uiScale),
              Text(
                'AI Assistant',
                style: TextStyle(
                  fontSize: 11 * widget.uiScale,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6C4EF5),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 14 * widget.uiScale,
                color: const Color(0xFF6C4EF5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Headline block
// ---------------------------------------------------------------------------
class _HeadlineBlock extends StatelessWidget {
  const _HeadlineBlock({required this.uiScale});
  final double uiScale;

 @override
Widget build(BuildContext context) {
  return const SizedBox();
}
}

// ---------------------------------------------------------------------------
// Hero illustration (real image)
// ---------------------------------------------------------------------------
class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration({required this.uiScale});
  final double uiScale;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: AspectRatio(
        aspectRatio: 900 / 600,
        child: Image.asset(
          'assets/images/scan_hero.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gradient "Scan Product" CTA
// ---------------------------------------------------------------------------
class _ScanProductCta extends StatefulWidget {
  const _ScanProductCta({required this.uiScale, this.onTap});
  final double uiScale;
  final VoidCallback? onTap;

  @override
  State<_ScanProductCta> createState() => _ScanProductCtaState();
}

class _ScanProductCtaState extends State<_ScanProductCta> {
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
          padding: EdgeInsets.all(16 * widget.uiScale),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFF6C4EF5), Color(0xFF1E8A4C)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C4EF5).withValues(alpha: 0.3),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52 * widget.uiScale,
                height: 52 * widget.uiScale,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: const Color(0xFF6C4EF5),
                  size: 24 * widget.uiScale,
                ),
              ),
              SizedBox(width: 14 * widget.uiScale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan Product',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.5 * widget.uiScale,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2 * widget.uiScale),
                    Text(
                      'Scan label or barcode to analyze nutrition '
                      'instantly',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11.5 * widget.uiScale,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 34 * widget.uiScale,
                height: 34 * widget.uiScale,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 17 * widget.uiScale,
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
// Quick actions grid (real icon images)
// ---------------------------------------------------------------------------
class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({
    required this.uiScale,
    this.onScanBarcode,
    this.onScanLabel,
    this.onImportGallery,
    this.onManualEntry,
  });

  final double uiScale;
  final VoidCallback? onScanBarcode;
  final VoidCallback? onScanLabel;
  final VoidCallback? onImportGallery;
  final VoidCallback? onManualEntry;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        asset: 'assets/images/icon_barcode.png',
        title: 'Scan Barcode',
        subtitle: 'Scan product\nbarcode',
        color: const Color(0xFF6C4EF5),
        onTap: onScanBarcode,
      ),
      (
        asset: 'assets/images/icon_nutrition_label.png',
        title: 'Scan Nutrition\nLabel',
        subtitle: 'Scan & analyze\nnutrition facts',
        color: const Color(0xFF1E8A4C),
        onTap: onScanLabel,
      ),
      (
        asset: 'assets/images/icon_gallery.png',
        title: 'Import from\nGallery',
        subtitle: 'Upload image\nfrom gallery',
        color: const Color(0xFF3B82F6),
        onTap: onImportGallery,
      ),
      (
        asset: 'assets/images/icon_manual_entry.png',
        title: 'Manual Entry',
        subtitle: 'Enter nutrition\ndetails manually',
        color: const Color(0xFFE0862E),
        onTap: onManualEntry,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12 * uiScale,
        crossAxisSpacing: 12 * uiScale,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, i) {
        final item = items[i];
        return _QuickActionCard(
          uiScale: uiScale,
          asset: item.asset,
          title: item.title,
          subtitle: item.subtitle,
          color: item.color,
          onTap: item.onTap,
        );
      },
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  const _QuickActionCard({
    required this.uiScale,
    required this.asset,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  final double uiScale;
  final String asset;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
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
          padding: EdgeInsets.all(12 * widget.uiScale),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(widget.asset, height: 40 * widget.uiScale),
              const Spacer(),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 12 * widget.uiScale,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: const Color(0xFF1B1B2E),
                ),
              ),
              SizedBox(height: 3 * widget.uiScale),
              Expanded(
                child: Text(
                  widget.subtitle,
                  style: TextStyle(
                    fontSize: 10 * widget.uiScale,
                    height: 1.25,
                    color: const Color(0xFF6B6B7B),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 22 * widget.uiScale,
                  height: 22 * widget.uiScale,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 12 * widget.uiScale,
                    color: widget.color,
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
// Recent scans (reuses the product photos from the home screen)
// ---------------------------------------------------------------------------
class _RecentScansSection extends StatelessWidget {
  const _RecentScansSection({
    required this.uiScale,
    required this.scans,
    this.onViewAll,
    this.onProductTap,
    this.onScanProductTap,
  });

  final double uiScale;
  final List<ScanHistoryItem> scans;
  final VoidCallback? onViewAll;
  final ValueChanged<int>? onProductTap;
  final VoidCallback? onScanProductTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.history_rounded,
              size: 16 * uiScale,
              color: const Color(0xFF1B1B2E),
            ),
            SizedBox(width: 6 * uiScale),
            Text(
              'Recent Scans',
              style: TextStyle(
                fontSize: 16 * uiScale,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1B1B2E),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onViewAll,
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 12.5 * uiScale,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6C4EF5),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 16 * uiScale,
                    color: const Color(0xFF6C4EF5),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 12 * uiScale),
        if (scans.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16 * uiScale),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10 * uiScale),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E8A4C).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: const Color(0xFF1E8A4C),
                    size: 20 * uiScale,
                  ),
                ),
                SizedBox(width: 12 * uiScale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No scans yet',
                        style: TextStyle(
                          fontSize: 13.5 * uiScale,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1B1B2E),
                        ),
                      ),
                      SizedBox(height: 2 * uiScale),
                      Text(
                        'Scan a product to see your history.',
                        style: TextStyle(
                          fontSize: 11.5 * uiScale,
                          color: const Color(0xFF8C8CA1),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: onScanProductTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E8A4C),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 14 * uiScale,
                      vertical: 8 * uiScale,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Scan',
                    style: TextStyle(
                      fontSize: 12.5 * uiScale,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 178 * uiScale,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: scans.length,
              separatorBuilder: (_, __) => SizedBox(width: 10 * uiScale),
              itemBuilder: (context, i) {
                final s = scans[i];
                return SizedBox(
                  width: 118 * uiScale,
                  child: _ProductCard(
                    uiScale: uiScale,
                    name: s.productName,
                    time: s.formattedTime,
                    score: s.score,
                    imageUrl: s.imageUrl,
                    onTap: () => onProductTap?.call(i),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ProductCard extends StatefulWidget {
  const _ProductCard({
    required this.uiScale,
    required this.name,
    required this.time,
    required this.score,
    required this.imageUrl,
    this.onTap,
  });

  final double uiScale;
  final String name;
  final String time;
  final int score;
  final String imageUrl;
  final VoidCallback? onTap;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  double _scale = 1.0;

  Color get _scoreColor {
    if (widget.score >= 90) return const Color(0xFF1E8A4C);
    if (widget.score >= 75) return const Color(0xFFE0862E);
    return const Color(0xFFE0525C);
  }

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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: AspectRatio(
                  aspectRatio: 1.15,
                  child: Container(
                    color: Colors.white,
                    padding: EdgeInsets.all(6 * widget.uiScale),
                    child: widget.imageUrl.startsWith('http')
                        ? Image.network(
                            widget.imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(
                                Icons.inventory_2_outlined,
                                size: 28 * widget.uiScale,
                                color: const Color(0xFFB0B0C4),
                              ),
                            ),
                          )
                        : (widget.imageUrl.isNotEmpty && widget.imageUrl.startsWith('assets/')
                            ? Image.asset(widget.imageUrl, fit: BoxFit.contain)
                            : Center(
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  size: 28 * widget.uiScale,
                                  color: const Color(0xFFB0B0C4),
                                ),
                              )),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  8 * widget.uiScale,
                  4 * widget.uiScale,
                  8 * widget.uiScale,
                  8 * widget.uiScale,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5 * widget.uiScale,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1B1B2E),
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: 2 * widget.uiScale),
                    Text(
                      widget.time,
                      style: TextStyle(
                        fontSize: 9 * widget.uiScale,
                        color: const Color(0xFF9A96A8),
                      ),
                    ),
                    SizedBox(height: 2 * widget.uiScale),
                    Row(
                      children: [
                        Container(
                          width: 5 * widget.uiScale,
                          height: 5 * widget.uiScale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _scoreColor,
                          ),
                        ),
                        SizedBox(width: 4 * widget.uiScale),
                        Text(
                          '${widget.score}/100',
                          style: TextStyle(
                            fontSize: 9.5 * widget.uiScale,
                            fontWeight: FontWeight.w700,
                            color: _scoreColor,
                          ),
                        ),
                      ],
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
// Tips card (real robot image)
// ---------------------------------------------------------------------------
class _TipsCard extends StatelessWidget {
  const _TipsCard({required this.uiScale, required this.ambientCtrl});
  final double uiScale;
  final AnimationController ambientCtrl;

  static const _tips = [
    'Ensure good lighting',
    'Focus on nutrition label or ingredients',
    'Hold camera steady',
    'Avoid glare and shadows',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16 * uiScale),
      decoration: BoxDecoration(
        color: const Color(0xFFF1ECFB),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -6,
            top: -6,
            child: Icon(
              Icons.verified_user_rounded,
              size: 64 * uiScale,
              color: const Color(0xFF6C4EF5).withValues(alpha: 0.08),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedBuilder(
                animation: ambientCtrl,
                builder: (context, child) {
                  final bob = math.sin(ambientCtrl.value * math.pi) * 4;
                  return Transform.translate(
                    offset: Offset(0, -bob),
                    child: child,
                  );
                },
                child: SizedBox(
  width: 100 * uiScale,
  height: 130 * uiScale,
  child: Image.asset(
    'assets/images/robot_pointing.png',
    fit: BoxFit.cover,
  ),
),
              ),
              SizedBox(width: 12 * uiScale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan Better, Get Better Results',
                      style: TextStyle(
                        fontSize: 13.5 * uiScale,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF6C4EF5),
                      ),
                    ),
                    SizedBox(height: 8 * uiScale),
                    ..._tips.map(
                      (t) => Padding(
                        padding: EdgeInsets.only(bottom: 5 * uiScale),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14 * uiScale,
                              color: const Color(0xFF1E8A4C),
                            ),
                            SizedBox(width: 6 * uiScale),
                            Expanded(
                              child: Text(
                                t,
                                style: TextStyle(
                                  fontSize: 11.5 * uiScale,
                                  color: const Color(0xFF3B3B4F),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

// ---------------------------------------------------------------------------
// Bottom navigation bar (same pattern as the home screen; Scan tab active)
// ---------------------------------------------------------------------------
class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.uiScale,
    required this.selectedIndex,
    required this.onTap,
  });

  final double uiScale;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  static const _items = [
  (icon: Icons.home_rounded, label: 'Home'),
  (icon: Icons.qr_code_scanner_rounded, label: 'Scan'),
  (icon: Icons.smart_toy_rounded, label: 'AI'),
  (icon: Icons.kitchen_rounded, label: 'Pantry'),
  (icon: Icons.pie_chart_rounded, label: 'Dashboard'),
];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.fromLTRB(
          14 * uiScale,
          0,
          14 * uiScale,
          10 * uiScale,
        ),
        padding: EdgeInsets.symmetric(vertical: 8 * uiScale),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            final selected = i == selectedIndex;
            final item = _items[i];
            return GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(
                  horizontal: selected ? 12 * uiScale : 8 * uiScale,
                  vertical: 6 * uiScale,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFE4F5E9)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 20 * uiScale,
                      color: selected
                          ? const Color(0xFF1E8A4C)
                          : const Color(0xFFB0ACC2),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      child: selected
                          ? Padding(
                              padding: EdgeInsets.only(top: 3 * uiScale),
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 9.5 * uiScale,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E8A4C),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
