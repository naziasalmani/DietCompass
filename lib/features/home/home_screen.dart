import 'dart:math' as math;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../ai/ai_recommendation_screen.dart';
import '../scan/scan_screen.dart';
import '../scan/camera_scan_screen.dart';
import '../scan/result_screen.dart';
import '../scan/scan_history_screen.dart';
import '../pantry/pantry_screen.dart';
import '../profile/profile_screen.dart';
import '../scan/compare_screen.dart';
import '../dashboard/DashboardScreen.dart';
import '../recipe_generator/recipe_generator_screen.dart';
import '../ai_coach/ai_coach_screen.dart';
import '../ai_coach/voice_assistant_modal.dart';
import '../profile/notifications_screen.dart';
import '../../core/model/food_product.dart';
import '../../core/model/health_compass_data.dart';
import '../../core/model/scan_history_item.dart';
import '../../core/services/scan_history_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.userName = 'Nazia',
    this.avatarUrl,
    this.healthCompassData,
    this.recentScans = const [],
    this.onScanTap,
    this.onNotificationTap,
    this.onSearchSubmitted,
    this.onMicTap,
    this.onExploreAiHub,
    this.onAiHubCardTap,
    this.onViewAllScans,
    this.onProductTap,
    this.onChatNowTap,
    this.onNavTap,
    this.initialNavIndex = 0,
    /// Callback invoked when the user confirms logout from ProfileScreen.
    /// Should revoke the backend session and navigate to the login screen.
    this.onLogout,
  });

  final String userName;
  final String? avatarUrl;
  final HealthCompassData? healthCompassData;
  final List<RecentScan> recentScans;

  final VoidCallback? onScanTap;
  final VoidCallback? onNotificationTap;
  final ValueChanged<String>? onSearchSubmitted;
  final VoidCallback? onMicTap;
  final VoidCallback? onExploreAiHub;
  final ValueChanged<int>? onAiHubCardTap;
  final VoidCallback? onViewAllScans;
  final ValueChanged<int>? onProductTap;
  final VoidCallback? onChatNowTap;
  final ValueChanged<int>? onNavTap;
  final int initialNavIndex;
  final Future<void> Function()? onLogout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class RecentScan {
  const RecentScan({
    required this.name,
    required this.time,
    required this.score,
    required this.asset,
    this.barcode = '',
    this.brand = '',
    this.product,
  });

  final String name;
  final String time;
  final int score;
  final String asset;
  final String barcode;
  final String brand;
  final FoodProduct? product;

  factory RecentScan.fromHistoryItem(ScanHistoryItem item) {
    return RecentScan(
      name: item.productName,
      time: item.formattedTime,
      score: item.score,
      asset: item.imageUrl.isNotEmpty ? item.imageUrl : '',
      barcode: item.barcode,
      brand: item.brand,
      product: item.toFoodProduct(),
    );
  }

  FoodProduct toFoodProduct() {
    if (product != null) return product!;
    return FoodProduct(
      barcode: barcode,
      name: name,
      brand: brand,
      imageUrl: asset.startsWith('http') ? asset : '',
      ingredients: '',
      allergens: const [],
      calories: null,
      protein: null,
      carbohydrates: null,
      fat: null,
      fiber: null,
      sugar: null,
      sodium: null,
    );
  }
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _ambientCtrl;
  late int _navIndex;
  List<RecentScan> _liveRecentScans = [];
  bool _isLoadingScans = false;

   Future<void> _pickCompareImages() async {

    final ImagePicker picker = ImagePicker();

    final List<XFile> images = await picker.pickMultiImage(
      limit: 2,
    );

    if (!mounted) return;

    if (images.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select exactly 2 product images."),
        ),
      );
      return;
    }

    final prod1 = FoodProduct(
      barcode: '',
      name: "Product 1",
      brand: "Selected Image",
      imageUrl: '',
      ingredients: '',
      allergens: const [],
      calories: null,
      protein: null,
      carbohydrates: null,
      fat: null,
      fiber: null,
      sugar: null,
      sodium: null,
    );
    final prod2 = FoodProduct(
      barcode: '',
      name: "Product 2",
      brand: "Selected Image",
      imageUrl: '',
      ingredients: '',
      allergens: const [],
      calories: null,
      protein: null,
      carbohydrates: null,
      fat: null,
      fiber: null,
      sugar: null,
      sodium: null,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompareScreen(
          currentProduct: prod1,
          currentProductImage: FileImage(File(images[0].path)),
          alternativeProduct: prod2,
          alternativeProductImage: FileImage(File(images[1].path)),
          onBack: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => HomeScreen(userName: widget.userName),
              ),
            );
          },
        ),
      ),
    );
  }


  HealthCompassData? _liveCompassData;

  @override
  void initState() {
    super.initState();
    _navIndex = widget.initialNavIndex;
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    if (widget.recentScans.isNotEmpty) {
      _liveRecentScans = widget.recentScans;
    } else if (ScanHistoryService.instance.currentHistory.isNotEmpty) {
      _liveRecentScans = ScanHistoryService.instance.currentHistory
          .take(3)
          .map((i) => RecentScan.fromHistoryItem(i))
          .toList();
    }
    if (widget.healthCompassData != null) {
      _liveCompassData = widget.healthCompassData;
    } else if (ScanHistoryService.instance.currentHistory.isNotEmpty) {
      _liveCompassData = ScanHistoryService.instance.computeHealthCompass();
    }
    ScanHistoryService.instance.addListener(_onScanHistoryChanged);
    _loadRecentScans();
  }

  void _onScanHistoryChanged() {
    if (!mounted) return;
    setState(() {
      if (widget.recentScans.isEmpty) {
        _liveRecentScans = ScanHistoryService.instance.currentHistory
            .take(3)
            .map((i) => RecentScan.fromHistoryItem(i))
            .toList();
        _isLoadingScans = false;
      }
      if (widget.healthCompassData == null) {
        _liveCompassData = ScanHistoryService.instance.computeHealthCompass();
      }
    });
  }

  Future<void> _loadRecentScans() async {
    setState(() => _isLoadingScans = _liveRecentScans.isEmpty && widget.recentScans.isEmpty);
    try {
      final items = await ScanHistoryService.instance.getScanHistory();
      if (mounted) {
        setState(() {
          if (widget.recentScans.isEmpty) {
            _liveRecentScans =
                items.take(3).map((i) => RecentScan.fromHistoryItem(i)).toList();
          } else {
            _liveRecentScans = widget.recentScans;
          }
          if (widget.healthCompassData == null) {
            _liveCompassData = ScanHistoryService.instance.computeHealthCompass(customHistory: items);
          }
          _isLoadingScans = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingScans = false);
    }
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  void _openVoiceAssistant() {
    showVoiceAssistantModal(
      context,
      userName: widget.userName,
    );
  }

  @override
  void dispose() {
    ScanHistoryService.instance.removeListener(_onScanHistoryChanged);
    _entranceCtrl.dispose();
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

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 390).clamp(0.85, 1.25);

    final colors = context.dcColors;

    return Scaffold(
      backgroundColor: colors.bg,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (!colors.isDark)
            Positioned.fill(
              child: Image.asset(
                'assets/images/home_bg.jpeg',
                fit: BoxFit.cover,
              ),
            )
          else
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF13111C),
                      Color(0xFF0D0C14),
                    ],
                  ),
                ),
              ),
            ),
          _DriftingLeaves(controller: _ambientCtrl),

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
                  opacity: _fade(0.0, 0.35),
                  child: SlideTransition(
                    position: _slide(0.0, 0.4),
                    child: _HeaderRow(
                      uiScale: scale,
                      name: widget.userName,
                      greeting: _greeting,
                      avatarUrl: widget.avatarUrl,
                      onNotificationTap: widget.onNotificationTap ?? _openNotifications,
                      onLogout: widget.onLogout,
                    ),
                  ),
                ),
                SizedBox(height: 16 * scale),

                FadeTransition(
                  opacity: _fade(0.06, 0.4),
                  child: SlideTransition(
                    position: _slide(0.06, 0.44),
                    child: _SearchBar(
                      uiScale: scale,
                      onSubmitted: widget.onSearchSubmitted,
                      onMicTap: _openVoiceAssistant,
                    ),

                  ),
                ),
                SizedBox(height: 16 * scale),

                FadeTransition(
                  opacity: _fade(0.12, 0.48),
                  child: SlideTransition(
                    position: _slide(0.12, 0.52),
                    child: _HeroBanner(
                      uiScale: scale,
                      onScanTap: widget.onScanTap ?? () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                           builder: (_) => const CameraScanScreen(
  source: CameraSource.home,
),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 24 * scale),

                FadeTransition(
                  opacity: _fade(0.2, 0.55),
                  child: SlideTransition(
                    position: _slide(0.2, 0.6),
                    child: _AiHubSection(
                      uiScale: scale,
                      onExploreAll: widget.onExploreAiHub,
                      onCardTap: (index) {
  switch (index) {
    case 0:
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const AiCoachScreen(),
    ),
  );
  break;

    case 1:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const RecipeGeneratorScreen(),
        ),
      );
      break;

    case 2:
  _pickCompareImages();
  break;

    case 3:
      // AI Shopping Assistant
      break;
  }
},
                    ),
                  ),
                ),
                SizedBox(height: 28 * scale),

                FadeTransition(
                  opacity: _fade(0.3, 0.65),
                  child: SlideTransition(
                    position: _slide(0.3, 0.7),
                    child: _HealthCompassCard(
                      uiScale: scale,
                      data: widget.healthCompassData ??
                          _liveCompassData ??
                          ScanHistoryService.instance.computeHealthCompass(),
                      entranceCtrl: _entranceCtrl,
                      onScanTap: widget.onScanTap ??
                          () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CameraScanScreen(
                                    source: CameraSource.home,
                                  ),
                                ),
                              ).then((_) => _loadRecentScans()),
                    ),
                  ),
                ),
                SizedBox(height: 22 * scale),

                FadeTransition(
                  opacity: _fade(0.4, 0.75),
                  child: SlideTransition(
                    position: _slide(0.4, 0.8),
                    child: _RecentScansSection(
                      uiScale: scale,
                      scans: _liveRecentScans.isNotEmpty
                          ? _liveRecentScans
                          : widget.recentScans,
                      onViewAll: widget.onViewAllScans ??
                          () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ScanHistoryScreen(),
                                ),
                              ).then((_) => _loadRecentScans()),
                      onProductTap: (index) {
                        if (widget.onProductTap != null) {
                          widget.onProductTap!(index);
                          return;
                        }
                        final list = _liveRecentScans.isNotEmpty
                            ? _liveRecentScans
                            : widget.recentScans;
                        if (list.length > index) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ResultScreen(
                                product: list[index].toFoodProduct(),
                              ),
                            ),
                          ).then((_) => _loadRecentScans());
                        }
                      },
                      onScanProductTap: widget.onScanTap ??
                          () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CameraScanScreen(
                                    source: CameraSource.home,
                                  ),
                                ),
                              ).then((_) => _loadRecentScans()),
                    ),
                  ),
                ),
                SizedBox(height: 20 * scale),

                FadeTransition(
                  opacity: _fade(0.5, 0.85),
                  child: SlideTransition(
                    position: _slide(0.5, 0.9),
                    child: _CoachPromptBanner(
                      uiScale: scale,
                      ambientCtrl: _ambientCtrl,
                      onChatNow: widget.onChatNowTap ?? () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AiCoachScreen(),
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
      bottomNavigationBar: _BottomNavBar(
        uiScale: scale,
        selectedIndex: _navIndex,

  onTap: (i) {
  setState(() => _navIndex = i);

  switch (i) {
    case 1:
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => ScanScreen(),
    ),
  );
  break;

    case 2:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AiShoppingScreen(),
        ),
      );
      break;

       case 3:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PantryScreen(),
        ),
      );
      break;

      case 4:
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const DashboardScreen(),
      ),
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
// Background: soft gradient + reused corner decorations (consistent with
// the rest of the app's visual language).
// ---------------------------------------------------------------------------
class _BackgroundGradient extends StatelessWidget {
  const _BackgroundGradient();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF5F0FF), Color(0xFFF2FFF7)],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: Opacity(
            opacity: 0.18,
            child: CustomPaint(
              size: const Size(80, 80),
              painter: _DotGridPainter(),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Opacity(
            opacity: 0.14,
            child: CustomPaint(
              size: const Size(100, 100),
              painter: _DotGridPainter(),
            ),
          ),
        ),
      ],
    );
  }
}

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

class _DriftingLeaves extends StatelessWidget {
  const _DriftingLeaves({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final t = controller.value;
          final dy = math.sin(t * math.pi) * 5;
          return Stack(
            children: [
              Positioned(
                top: 90 + dy,
                right: 26,
                child: Transform.rotate(
                  angle: 0.3,
                  child: Icon(
                    Icons.eco_rounded,
                    size: 16,
                    color: const Color(0xFF8FD6B0).withOpacity(0.55),
                  ),
                ),
              ),
              Positioned(
                bottom: 140 - dy,
                left: 18,
                child: Transform.rotate(
                  angle: -0.2,
                  child: Icon(
                    Icons.eco_rounded,
                    size: 14,
                    color: const Color(0xFFB9A6F2).withOpacity(0.5),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header: avatar + greeting + notification bell
// ---------------------------------------------------------------------------
class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.uiScale,
    required this.name,
    required this.greeting,
    required this.avatarUrl,
    this.onNotificationTap,
    this.onLogout,
  });

  final double uiScale;
  final String name;
  final String greeting;
  final String? avatarUrl;
  final VoidCallback? onNotificationTap;
  final Future<void> Function()? onLogout;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Row(
      children: [
        GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(onLogout: onLogout),
      ),
    );
  },
  child: Container(
    width: 48 * uiScale,
    height: 48 * uiScale,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: [colors.iconPurple, colors.iconGreen],
      ),
      image: avatarUrl != null
          ? DecorationImage(
              image: NetworkImage(avatarUrl!),
              fit: BoxFit.cover,
            )
          : null,
    ),
    child: avatarUrl == null
        ? Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18 * uiScale,
              ),
            ),
          )
        : null,
  ),
),
        SizedBox(width: 12 * uiScale),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      '$greeting, $name! ',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17 * uiScale,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Text('👋', style: TextStyle(fontSize: 15 * uiScale)),
                ],
              ),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 12.5 * uiScale,
                    color: colors.textSecondary,
                  ),
                  children: [
                    const TextSpan(text: 'Your AI companion for a '),
                    TextSpan(
                      text: 'healthier you',
                      style: TextStyle(
                        color: colors.iconPurple,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8 * uiScale),
        _NotificationBell(uiScale: uiScale, onTap: onNotificationTap),
      ],
    );
  }
}

class _NotificationBell extends StatefulWidget {
  const _NotificationBell({required this.uiScale, this.onTap});
  final double uiScale;
  final VoidCallback? onTap;

  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

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
          width: 44 * widget.uiScale,
          height: 44 * widget.uiScale,
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
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 20 * widget.uiScale,
                color: colors.textPrimary,
              ),
              Positioned(
                top: 10 * widget.uiScale,
                right: 11 * widget.uiScale,
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (context, _) {
                    final t = _pulseCtrl.value;
                    return Container(
                      width: 8 * widget.uiScale,
                      height: 8 * widget.uiScale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.lerp(
                          const Color(0xFFE0525C),
                          const Color(0xFFFF8A93),
                          t,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE0525C)
                                .withValues(alpha: 0.5 * (1 - t)),
                            blurRadius: 4 + t * 4,
                            spreadRadius: t * 2,
                          ),
                        ],
                      ),
                    );
                  },
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
// Search bar
// ---------------------------------------------------------------------------
class _SearchBar extends StatefulWidget {
  const _SearchBar({
    required this.uiScale,
    this.onSubmitted,
    this.onMicTap,
  });

  final double uiScale;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onMicTap;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Row(
      children: [
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 50 * widget.uiScale,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _focused
                    ? colors.iconPurple
                    : colors.cardBorder,
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: colors.isDark ? 0.20 : 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: TextField(
              focusNode: _focusNode,
              onSubmitted: widget.onSubmitted,
              style: TextStyle(
                fontSize: 13.5 * widget.uiScale,
                color: colors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search food, recipes or ask AI...',
                hintStyle: TextStyle(
                  color: colors.textMuted,
                  fontSize: 13 * widget.uiScale,
                ),
                prefixIcon: Icon(
                  Icons.auto_awesome,
                  size: 18 * widget.uiScale,
                  color: colors.iconPurple,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 14 * widget.uiScale,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 10 * widget.uiScale),
        _MicButton(uiScale: widget.uiScale, onTap: widget.onMicTap),
      ],
    );
  }
}

class _MicButton extends StatefulWidget {
  const _MicButton({required this.uiScale, this.onTap});
  final double uiScale;
  final VoidCallback? onTap;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton> {
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
          width: 50 * widget.uiScale,
          height: 50 * widget.uiScale,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [colors.iconGreen, const Color(0xFF2FAE68)],
            ),
            boxShadow: [
              BoxShadow(
                color: colors.iconGreen.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.mic_none_rounded,
            color: const Color(0xFFFFFEFF),
            size: 22 * widget.uiScale,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero banner (real image) + real "Scan a Product" button overlay
// ---------------------------------------------------------------------------
class _HeroBanner extends StatefulWidget {
  const _HeroBanner({required this.uiScale, this.onScanTap});
  final double uiScale;
  final VoidCallback? onScanTap;

  @override
  State<_HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<_HeroBanner> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 808 / 455,
            child: Image.asset(
              'assets/images/home_hero_banner.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            left: 10,
            bottom: 10,
            child: SizedBox(
              width: 155,
              child: GestureDetector(
                onTapDown: (_) => setState(() => _scale = 0.95),
                onTapUp: (_) => setState(() => _scale = 1.0),
                onTapCancel: () => setState(() => _scale = 1.0),
                onTap: widget.onScanTap,
                child: AnimatedScale(
  scale: _scale,
  duration: const Duration(milliseconds: 100),
  child: Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 10,
    ),
    decoration: BoxDecoration(
      color: const Color(0xFF10142B),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'Scan a Product',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11.5 * widget.uiScale,
            ),
          ),
        ),
        SizedBox(width: 6 * widget.uiScale),
        Icon(
          Icons.qr_code_scanner_rounded,
          color: const Color(0xFF5CE0A0),
          size: 15 * widget.uiScale,
        ),
      ],
    ),
  ),
), // AnimatedScale
              ), // GestureDetector
            ), // SizedBox
          ), // Positioned
        ], // Stack children
      ), // Stack
    ); // ClipRRect
  }
}
                        
// ---------------------------------------------------------------------------
// AI Hub grid
// ---------------------------------------------------------------------------
class _AiHubSection extends StatelessWidget {
  const _AiHubSection({
    required this.uiScale,
    this.onExploreAll,
    this.onCardTap,
  });

  final double uiScale;
  final VoidCallback? onExploreAll;
  final ValueChanged<int>? onCardTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;

    final cards = [
      (
        icon: Icons.forum_rounded,
        bg: colors.isDark ? const Color(0xFF26203D) : const Color(0xFFEDE7FA),
        fg: colors.iconPurple,
        title: 'AI Nutrition Coach',
        subtitle: 'Ask anything about\nfood, nutrition or your diet.',
      ),
      (
        icon: Icons.ramen_dining_rounded,
        bg: colors.isDark ? const Color(0xFF33241C) : const Color(0xFFFCEBE0),
        fg: colors.iconOrange,
        title: 'Recipe Generator',
        subtitle: 'Get healthy recipes\nusing ingredients in your pantry.',
      ),
      (
        icon: Icons.balance_rounded,
        bg: colors.isDark ? const Color(0xFF1B283D) : const Color(0xFFE3EEFC),
        fg: colors.iconBlue,
        title: 'Compare Products',
        subtitle: 'Compare products\n& choose the healthier one.',
      ),
      (
        icon: Icons.add_shopping_cart_rounded,
        bg: colors.isDark ? const Color(0xFF1B3326) : const Color(0xFFE4F5E9),
        fg: colors.iconGreen,
        title: 'AI Product Recommendations',
        subtitle: 'Find healthier products that match your goals.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome,
              size: 16 * uiScale,
              color: colors.iconPurple,
            ),
            SizedBox(width: 6 * uiScale),
            Text(
              'AI Hub',
              style: TextStyle(
                fontSize: 16 * uiScale,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onExploreAll,
              child: Row(
                children: [
                  Text(
                    'Explore All',
                    style: TextStyle(
                      fontSize: 12.5 * uiScale,
                      fontWeight: FontWeight.w700,
                      color: colors.iconPurple,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 16 * uiScale,
                    color: colors.iconPurple,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 2 * uiScale),
        Text(
          'Smart tools to guide your health journey',
          style: TextStyle(
            fontSize: 12 * uiScale,
            color: colors.textSecondary,
          ),
        ),
        SizedBox(height: 12 * uiScale),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12 * uiScale,
            crossAxisSpacing: 12 * uiScale,
            childAspectRatio: 1.02,
          ),
          itemBuilder: (context, i) {
            final c = cards[i];
            return _AiHubCard(
              uiScale: uiScale,
              icon: c.icon,
              bg: c.bg,
              fg: c.fg,
              title: c.title,
              subtitle: c.subtitle,
              onTap: () {
  if (i == 3) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const AiShoppingScreen(),
      ),
    );
  } else {
    onCardTap?.call(i);
  }
},
            );
          },
        ),
      ],
    );
  }
}

class _AiHubCard extends StatefulWidget {
  const _AiHubCard({
    required this.uiScale,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final double uiScale;
  final IconData icon;
  final Color bg;
  final Color fg;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  State<_AiHubCard> createState() => _AiHubCardState();
}

class _AiHubCardState extends State<_AiHubCard> {
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
          padding: EdgeInsets.all(14 * widget.uiScale),
          decoration: BoxDecoration(
            color: widget.bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34 * widget.uiScale,
                height: 34 * widget.uiScale,
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: widget.fg,
                  size: 17 * widget.uiScale,
                ),
              ),
              const Spacer(),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 12.5 * widget.uiScale,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: 3 * widget.uiScale),
              Text(
                widget.subtitle,
                style: TextStyle(
                  fontSize: 10 * widget.uiScale,
                  height: 1.3,
                  color: colors.textSecondary,
                ),
              ),
              SizedBox(height: 6 * widget.uiScale),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 22 * widget.uiScale,
                  height: 22 * widget.uiScale,
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 12 * widget.uiScale,
                    color: widget.fg,
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
// Your Health Compass card: dynamic average compatibility gauge + real metrics
// ---------------------------------------------------------------------------
class _HealthCompassCard extends StatelessWidget {
  const _HealthCompassCard({
    required this.uiScale,
    required this.data,
    required this.entranceCtrl,
    this.onScanTap,
  });

  final double uiScale;
  final HealthCompassData data;
  final AnimationController entranceCtrl;
  final VoidCallback? onScanTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    final gaugeAnim = CurvedAnimation(
      parent: entranceCtrl,
      curve: const Interval(0.35, 0.95, curve: Curves.easeOutCubic),
    );

    final hasScans = data.hasScans;
    final displayScore = data.averageCompatibility ?? 0;
    final statusLabel = data.compatibilityLabel;
    final statusBadgeColor = data.statusBadgeColor;
    final statusBadgeBg = data.statusBadgeBackgroundColor;
    final statusBadgeIcon = data.statusBadgeIcon;

    return Container(
      padding: EdgeInsets.all(20 * uiScale),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: colors.isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF6C4EF5).withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.15 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: YOUR HEALTH COMPASS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8 * uiScale),
                    decoration: BoxDecoration(
                      color: colors.iconPurpleBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.explore_rounded,
                      size: 18 * uiScale,
                      color: colors.iconPurple,
                    ),
                  ),
                  SizedBox(width: 10 * uiScale),
                  Text(
                    "YOUR HEALTH COMPASS",
                    style: TextStyle(
                      fontSize: 16 * uiScale,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              Tooltip(
                message: "Calculated from your real scan history and product analyses.",
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 19 * uiScale,
                  color: colors.textMuted,
                ),
              ),
            ],
          ),

          SizedBox(height: 22 * uiScale),

          // 2. Average Compatibility Gauge Section
          Center(
            child: AnimatedBuilder(
              animation: gaugeAnim,
              builder: (context, _) {
                final animatedScore = hasScans
                    ? (displayScore * gaugeAnim.value).round()
                    : 0;
                final progress = hasScans
                    ? gaugeAnim.value * (displayScore / 100.0)
                    : 0.0;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 220 * uiScale,
                      height: 145 * uiScale,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          CustomPaint(
                            size: Size(220 * uiScale, 145 * uiScale),
                            painter: _CompassGaugePainter(
                              progress: progress,
                              hasScans: hasScans,
                              isDark: colors.isDark,
                            ),
                          ),
                          Positioned(
                            top: 34 * uiScale,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: hasScans ? '$animatedScore' : '--',
                                        style: TextStyle(
                                          fontSize: 36 * uiScale,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.6,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' /100',
                                        style: TextStyle(
                                          fontSize: 16 * uiScale,
                                          fontWeight: FontWeight.w700,
                                          color: colors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 5 * uiScale),
                                Text(
                                  'Average Compatibility',
                                  style: TextStyle(
                                    fontSize: 13 * uiScale,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12 * uiScale),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16 * uiScale,
                        vertical: 7 * uiScale,
                      ),
                      decoration: BoxDecoration(
                        color: statusBadgeBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: statusBadgeColor.withValues(alpha: 0.25),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusBadgeIcon,
                            size: 15 * uiScale,
                            color: statusBadgeColor,
                          ),
                          SizedBox(width: 6 * uiScale),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 13 * uiScale,
                              fontWeight: FontWeight.w800,
                              color: statusBadgeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // If brand new user with no scans, show gentle encouraging empty message
          if (!hasScans) ...[
            SizedBox(height: 14 * uiScale),
            Center(
              child: Text(
                'Start scanning products to build your health insights.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5 * uiScale,
                  color: colors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],

          SizedBox(height: 22 * uiScale),

          // Divider
          Container(
            height: 1.2,
            color: colors.divider,
          ),

          SizedBox(height: 20 * uiScale),

          // 3. 2x2 Grid of 4 Dynamic Metrics
          Row(
            children: [
              Expanded(
                child: _HealthCompassMetricTile(
                  uiScale: uiScale,
                  value: '${data.productsAnalyzed}',
                  line1: 'Products',
                  line2: 'Analyzed',
                  icon: Icons.inventory_2_rounded,
                  accentColor: colors.iconPurple,
                  bgColor: colors.surfaceSecondary,
                  borderColor: colors.cardBorder,
                ),
              ),
              SizedBox(width: 12 * uiScale),
              Expanded(
                child: _HealthCompassMetricTile(
                  uiScale: uiScale,
                  value: '${data.ingredientsFlagged}',
                  line1: 'Ingredients',
                  line2: 'Flagged',
                  icon: Icons.flag_rounded,
                  accentColor: colors.iconRed,
                  bgColor: colors.surfaceSecondary,
                  borderColor: colors.cardBorder,
                ),
              ),
            ],
          ),

          SizedBox(height: 12 * uiScale),

          Row(
            children: [
              Expanded(
                child: _HealthCompassMetricTile(
                  uiScale: uiScale,
                  value: '${data.betterAlternatives}',
                  line1: 'Better',
                  line2: 'Alternatives',
                  icon: Icons.swap_horiz_rounded,
                  accentColor: colors.iconGreen,
                  bgColor: colors.surfaceSecondary,
                  borderColor: colors.cardBorder,
                ),
              ),
              SizedBox(width: 12 * uiScale),
              Expanded(
                child: _HealthCompassMetricTile(
                  uiScale: uiScale,
                  value: '${data.scansThisWeek}',
                  line1: 'Scans',
                  line2: 'This Week',
                  icon: Icons.calendar_today_rounded,
                  accentColor: colors.iconOrange,
                  bgColor: colors.surfaceSecondary,
                  borderColor: colors.cardBorder,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HealthCompassMetricTile extends StatelessWidget {
  const _HealthCompassMetricTile({
    required this.uiScale,
    required this.value,
    required this.line1,
    required this.line2,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
    required this.borderColor,
  });

  final double uiScale;
  final String value;
  final String line1;
  final String line2;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 14 * uiScale,
        vertical: 14 * uiScale,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24 * uiScale,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  color: colors.textPrimary,
                ),
              ),
              Container(
                padding: EdgeInsets.all(7 * uiScale),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 18 * uiScale,
                  color: accentColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * uiScale),
          Text(
            '$line1\n$line2',
            style: TextStyle(
              fontSize: 12.5 * uiScale,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassGaugePainter extends CustomPainter {
  _CompassGaugePainter({
    required this.progress,
    required this.hasScans,
    this.isDark = false,
  });

  final double progress; // 0..1
  final bool hasScans;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.78);
    final radius = size.width / 2 - 16;

    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF28253A) : const Color(0xFFEDEAF7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    // 210 degrees arc spanning from 165 to 375 deg (bottom-left to bottom-right)
    const startAngle = math.pi * 0.85;
    const sweepAngle = math.pi * 1.30;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    if (hasScans && progress > 0.001) {
      final fgPaint = Paint()
        ..shader = const SweepGradient(
          colors: [Color(0xFF6C4EF5), Color(0xFF1E8A4C)],
          startAngle: 0,
          endAngle: math.pi * 1.5,
          transform: GradientRotation(startAngle),
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * progress.clamp(0.0, 1.0),
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CompassGaugePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.hasScans != hasScans || oldDelegate.isDark != isDark;
}

// ---------------------------------------------------------------------------
// Recent scans
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
  final List<RecentScan> scans;
  final VoidCallback? onViewAll;
  final ValueChanged<int>? onProductTap;
  final VoidCallback? onScanProductTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.history_rounded,
              size: 16 * uiScale,
              color: colors.iconGreen,
            ),
            SizedBox(width: 6 * uiScale),
            Text(
              'Recent Scans',
              style: TextStyle(
                fontSize: 16 * uiScale,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
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
                      color: colors.iconPurple,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 16 * uiScale,
                    color: colors.iconPurple,
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
            padding: EdgeInsets.symmetric(
              horizontal: 16 * uiScale,
              vertical: 16 * uiScale,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: colors.isDark ? 0.15 : 0.04),
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
                    color: colors.iconGreenBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: colors.iconGreen,
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
                          color: colors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2 * uiScale),
                      Text(
                        'Scan a product to see your scan history here.',
                        style: TextStyle(
                          fontSize: 11.5 * uiScale,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: onScanProductTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.iconGreen,
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
          Row(
            children: List.generate(scans.length, (i) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: i == scans.length - 1 ? 0 : 10 * uiScale,
                  ),
                  child: _ProductCard(
                    uiScale: uiScale,
                    scan: scans[i],
                    onTap: () => onProductTap?.call(i),
                  ),
                ),
              );
            }),
          ),
      ],
    );
  }
}

class _ProductCard extends StatefulWidget {
  const _ProductCard({
    required this.uiScale,
    required this.scan,
    this.onTap,
  });

  final double uiScale;
  final RecentScan scan;
  final VoidCallback? onTap;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  double _scale = 1.0;

  Color get _scoreColor {
    final s = widget.scan.score;
    if (s >= 90) return const Color(0xFF1E8A4C);
    if (s >= 75) return const Color(0xFFE0862E);
    return const Color(0xFFE0525C);
  }

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
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: colors.isDark ? 0.20 : 0.05),
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
                  aspectRatio: 1.1,
                  child: Container(
                    color: colors.surfaceSecondary,
                    padding: EdgeInsets.all(6 * widget.uiScale),
                    child: widget.scan.asset.startsWith('http')
                        ? Image.network(
                            widget.scan.asset,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(
                                Icons.inventory_2_outlined,
                                size: 32 * widget.uiScale,
                                color: colors.textMuted,
                              ),
                            ),
                          )
                        : (widget.scan.asset.isNotEmpty && widget.scan.asset.startsWith('assets/')
                            ? Image.asset(widget.scan.asset, fit: BoxFit.contain)
                            : Center(
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  size: 32 * widget.uiScale,
                                  color: colors.textMuted,
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
                      widget.scan.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5 * widget.uiScale,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: 3 * widget.uiScale),
                    Text(
                      widget.scan.time,
                      style: TextStyle(
                        fontSize: 9 * widget.uiScale,
                        color: colors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 3 * widget.uiScale),
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
                          '${widget.scan.score}/100',
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
// AI coach prompt banner
// ---------------------------------------------------------------------------
class _CoachPromptBanner extends StatelessWidget {
  const _CoachPromptBanner({
    required this.uiScale,
    required this.ambientCtrl,
    this.onChatNow,
  });

  final double uiScale;
  final AnimationController ambientCtrl;
  final VoidCallback? onChatNow;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Container(
      padding: EdgeInsets.all(14 * uiScale),
      decoration: BoxDecoration(
        color: colors.isDark ? const Color(0xFF1F1B38) : const Color(0xFFF1ECFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: ambientCtrl,
            builder: (context, child) {
              final bob = math.sin(ambientCtrl.value * math.pi) * 3;
              return Transform.translate(offset: Offset(0, -bob), child: child);
            },
            child: _MiniRobot(uiScale: uiScale),
          ),
          SizedBox(width: 12 * uiScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need personalized advice?',
                  style: TextStyle(
                    fontSize: 13 * uiScale,
                    fontWeight: FontWeight.w800,
                    color: colors.iconPurple,
                  ),
                ),
                SizedBox(height: 2 * uiScale),
                Text(
                  'Chat with your AI Nutrition Coach for expert '
                  'recommendations.',
                  style: TextStyle(
                    fontSize: 10.5 * uiScale,
                    height: 1.3,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8 * uiScale),
          _ChatNowButton(uiScale: uiScale, onTap: onChatNow),
        ],
      ),
    );
  }
}

class _MiniRobot extends StatelessWidget {
  const _MiniRobot({required this.uiScale});

  final double uiScale;

  @override
  Widget build(BuildContext context) {
    // Keep the layout footprint small (so the purple banner height
    // doesn't grow) but render the robot image larger visually using
    // an OverflowBox. The surrounding Row will size itself to
    // `layoutSize` while the image can overflow and appear bigger.
    final layoutSize = 70 * uiScale;
    final visualSize = 150 * uiScale;
    return SizedBox(
      width: layoutSize,
      height: layoutSize,
      child: OverflowBox(
        maxWidth: visualSize,
        maxHeight: visualSize,
        alignment: Alignment.center,
        child: Image.asset(
          'assets/images/ai_robot.png',
          width: visualSize,
          height: visualSize,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _ChatNowButton extends StatefulWidget {
  const _ChatNowButton({required this.uiScale, this.onTap});
  final double uiScale;
  final VoidCallback? onTap;

  @override
  State<_ChatNowButton> createState() => _ChatNowButtonState();
}

class _ChatNowButtonState extends State<_ChatNowButton> {
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
          padding: EdgeInsets.symmetric(
            horizontal: 12 * widget.uiScale,
            vertical: 10 * widget.uiScale,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [colors.iconPurple, colors.iconGreen],
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 13 * widget.uiScale,
              ),
              SizedBox(width: 4 * widget.uiScale),
              Text(
                'Chat Now',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.5 * widget.uiScale,
                  fontWeight: FontWeight.w700,
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
// Bottom navigation bar
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
    final colors = context.dcColors;
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
          color: colors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: colors.isDark ? 0.25 : 0.08),
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
                      ? colors.iconGreenBg
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
                          ? colors.iconGreen
                          : colors.textMuted,
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
                                  color: colors.iconGreen,
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
