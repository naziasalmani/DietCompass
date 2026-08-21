import 'dart:math' as math;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../ai/ai_recommendation_screen.dart';
import '../scan/scan_screen.dart';
import '../scan/camera_scan_screen.dart';
import '../pantry/pantry_screen.dart';
import '../profile/profile_screen.dart';
import '../scan/compare_screen.dart';
import '../dashboard/DashboardScreen.dart';
import '../recipe_generator/recipe_generator_screen.dart';
import '../ai_coach/ai_coach_screen.dart';
import '../ai_coach/voice_assistant_modal.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.userName = 'Nazia',
    this.avatarUrl,
    this.nutritionScore = 92,
    this.macros = const [
      MacroStat(label: 'Calories', value: 1420, target: 1800, unit: 'kcal', icon: Icons.local_fire_department, color: Color(0xFF6C4EF5)),
      MacroStat(label: 'Protein', value: 68, target: 100, unit: 'g', icon: Icons.fitness_center, color: Color(0xFF1E8A4C)),
      MacroStat(label: 'Fiber', value: 22, target: 30, unit: 'g', icon: Icons.eco, color: Color(0xFFE0862E)),
      MacroStat(label: 'Sugar', value: 24, target: 50, unit: 'g', icon: Icons.icecream, color: Color(0xFFE0525C)),
      MacroStat(label: 'Water', value: 6, target: 8, unit: 'glasses', icon: Icons.water_drop, color: Color(0xFF3B82F6)),
      MacroStat(label: 'Sodium', value: 1180, target: 2000, unit: 'mg', icon: Icons.grain, color: Color(0xFFE0862E)),
    ],
    this.recentScans = const [
      RecentScan(
        name: 'Maggi 2-Minute Noodles',
        time: 'Today, 9:30 AM',
        score: 89,
        asset: 'assets/images/product_maggi.png',
      ),
      RecentScan(
        name: 'Amul Taaza Toned Milk',
        time: 'Today, 8:45 AM',
        score: 92,
        asset: 'assets/images/product_amul.png',
      ),
      RecentScan(
        name: 'Quaker Oats 500 g',
        time: 'Yesterday',
        score: 98,
        asset: 'assets/images/product_quaker.png',
      ),
    ],
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
  final int nutritionScore;
  final List<MacroStat> macros;
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

class MacroStat {
  const MacroStat({
    required this.label,
    required this.value,
    required this.target,
    required this.unit,
    required this.icon,
    required this.color,
  });

  final String label;
  final num value;
  final num target;
  final String unit;
  final IconData icon;
  final Color color;
}

class RecentScan {
  const RecentScan({
    required this.name,
    required this.time,
    required this.score,
    required this.asset,
  });

  final String name;
  final String time;
  final int score;
  final String asset;
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _ambientCtrl;
  late int _navIndex;

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

    Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => CompareScreen(
      onBack: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => HomeScreen(userName: widget.userName),
          ),
        );
      },
      productA: ComparisonProduct(
        image: FileImage(File(images[0].path)),
        name: "Product 1",
        brand: "Scanned Product",
        tag: ProductTag.healthyChoice,
        servingInfo: "-",
        scannedAt: "Just now",
        score: 0,
        scoreLabel: "Analyzing...",
      ),
      productB: ComparisonProduct(
        image: FileImage(File(images[1].path)),
        name: "Product 2",
        brand: "Scanned Product",
        tag: ProductTag.considerLess,
        servingInfo: "-",
        scannedAt: "Just now",
        score: 0,
        scoreLabel: "Analyzing...",
      ),
    ),
  ),
);
  }


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
  }

  void _openVoiceAssistant() {
    showVoiceAssistantModal(
      context,
      userName: widget.userName,
    );
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

    return Scaffold(
  backgroundColor: const Color(0xFFF3F0FB),
  extendBody: true,
  body: Stack(
    fit: StackFit.expand,
    children: [

      Positioned.fill(
  child: Image.asset(
    'assets/images/home_bg.jpeg',
    fit: BoxFit.cover,
  ),
),

//     const _BackgroundGradient(),
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
                      onNotificationTap: widget.onNotificationTap,
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
                    child: _NutritionScoreCard(
                      uiScale: scale,
                      score: widget.nutritionScore,
                      macros: widget.macros,
                      entranceCtrl: _entranceCtrl,
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
                      scans: widget.recentScans,
                      onViewAll: widget.onViewAllScans,
                      onProductTap: widget.onProductTap,
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
                      onChatNow: widget.onChatNowTap,
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
      gradient: const LinearGradient(
        colors: [Color(0xFF6C4EF5), Color(0xFF1E8A4C)],
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
                        color: const Color(0xFF1B1B2E),
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
                    color: const Color(0xFF6B6B7B),
                  ),
                  children: const [
                    TextSpan(text: 'Your AI companion for a '),
                    TextSpan(
                      text: 'healthier you',
                      style: TextStyle(
                        color: Color(0xFF6C4EF5),
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
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
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
                color: const Color(0xFF1B1B2E),
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
                                .withOpacity(0.5 * (1 - t)),
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
    return Row(
      children: [
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 50 * widget.uiScale,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _focused
                    ? const Color(0xFF6C4EF5)
                    : Colors.white,
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: TextField(
              focusNode: _focusNode,
              onSubmitted: widget.onSubmitted,
              style: TextStyle(fontSize: 13.5 * widget.uiScale),
              decoration: InputDecoration(
                hintText: 'Search food, recipes or ask AI...',
                hintStyle: TextStyle(
                  color: const Color(0xFFB0ACC2),
                  fontSize: 13 * widget.uiScale,
                ),
                prefixIcon: Icon(
                  Icons.auto_awesome,
                  size: 18 * widget.uiScale,
                  color: const Color(0xFF9B7BFA),
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
            gradient: const LinearGradient(
              colors: [Color(0xFF1E8A4C), Color(0xFF2FAE68)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E8A4C).withOpacity(0.3),
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

  static const _cards = [
    (
      icon: Icons.forum_rounded,
      bg: Color(0xFFEDE7FA),
      fg: Color(0xFF6C4EF5),
      title: 'AI Nutrition Coach',
      subtitle: 'Ask anything about\nfood, nutrition or your diet.',
    ),
    (
      icon: Icons.ramen_dining_rounded,
      bg: Color(0xFFFCEBE0),
      fg: Color(0xFFE0862E),
      title: 'Recipe Generator',
      subtitle: 'Get healthy recipes\nusing ingredients in your pantry.',
    ),
    (
      icon: Icons.balance_rounded,
      bg: Color(0xFFE3EEFC),
      fg: Color(0xFF3B82F6),
      title: 'Compare Products',
      subtitle: 'Compare products\n& choose the healthier one.',
    ),
    (
      icon: Icons.add_shopping_cart_rounded,
      bg: Color(0xFFE4F5E9),
      fg: Color(0xFF1E8A4C),
      title: 'AI Product Recommendations',
      subtitle: 'Find healthier products that match your goals.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome,
              size: 16 * uiScale,
              color: const Color(0xFF9B7BFA),
            ),
            SizedBox(width: 6 * uiScale),
            Text(
              'AI Hub',
              style: TextStyle(
                fontSize: 16 * uiScale,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1B1B2E),
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
        SizedBox(height: 2 * uiScale),
        Text(
          'Smart tools to guide your health journey',
          style: TextStyle(
            fontSize: 12 * uiScale,
            color: const Color(0xFF6B6B7B),
          ),
        ),
        SizedBox(height: 12 * uiScale),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12 * uiScale,
            crossAxisSpacing: 12 * uiScale,
            childAspectRatio: 1.02,
          ),
          itemBuilder: (context, i) {
            final c = _cards[i];
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
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34 * widget.uiScale,
                height: 34 * widget.uiScale,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
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
                  color: const Color(0xFF1B1B2E),
                ),
              ),
              SizedBox(height: 3 * widget.uiScale),
              Text(
                widget.subtitle,
                style: TextStyle(
                  fontSize: 10 * widget.uiScale,
                  height: 1.3,
                  color: const Color(0xFF6B6B7B),
                ),
              ),
              SizedBox(height: 6 * widget.uiScale),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 22 * widget.uiScale,
                  height: 22 * widget.uiScale,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
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
// Today's Nutrition Score card: animated gauge + macro grid
// ---------------------------------------------------------------------------
class _NutritionScoreCard extends StatelessWidget {
  const _NutritionScoreCard({
    required this.uiScale,
    required this.score,
    required this.macros,
    required this.entranceCtrl,
  });

  final double uiScale;
  final int score;
  final List<MacroStat> macros;
  final AnimationController entranceCtrl;

  @override
  Widget build(BuildContext context) {
    final gaugeAnim = CurvedAnimation(
      parent: entranceCtrl,
      curve: const Interval(0.45, 0.95, curve: Curves.easeOutCubic),
    );

    return Container(
      padding: EdgeInsets.all(16 * uiScale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Today's Nutrition Score",
                style: TextStyle(
                  fontSize: 14.5 * uiScale,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1B1B2E),
                ),
              ),
              SizedBox(width: 4 * uiScale),
              Icon(
                Icons.info_outline,
                size: 14 * uiScale,
                color: const Color(0xFFB0ACC2),
              ),
            ],
          ),
          SizedBox(height: 14 * uiScale),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 108 * uiScale,
                height: 108 * uiScale,
                child: AnimatedBuilder(
                  animation: gaugeAnim,
                  builder: (context, _) {
                    final animatedScore = (score * gaugeAnim.value).round();
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: Size(108 * uiScale, 108 * uiScale),
                          painter: _GaugePainter(
                            progress: gaugeAnim.value * (score / 100),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '$animatedScore',
                                    style: TextStyle(
                                      fontSize: 26 * uiScale,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1B1B2E),
                                    ),
                                  ),
                                  TextSpan(
                                    text: '/100',
                                    style: TextStyle(
                                      fontSize: 12 * uiScale,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF9A96A8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 2 * uiScale),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8 * uiScale,
                                vertical: 2 * uiScale,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE4F5E9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    size: 10 * uiScale,
                                    color: const Color(0xFF1E8A4C),
                                  ),
                                  SizedBox(width: 3 * uiScale),
                                  Text(
                                    'Excellent',
                                    style: TextStyle(
                                      fontSize: 9.5 * uiScale,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1E8A4C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(width: 10 * uiScale),
              Expanded(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: macros.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8 * uiScale,
                    crossAxisSpacing: 8 * uiScale,
                    childAspectRatio: 2.0,
                  ),
                  itemBuilder: (context, i) {
                    return _MacroTile(
                      uiScale: uiScale,
                      stat: macros[i],
                      anim: gaugeAnim,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroTile extends StatelessWidget {
  const _MacroTile({
    required this.uiScale,
    required this.stat,
    required this.anim,
  });

  final double uiScale;
  final MacroStat stat;
  final Animation<double> anim;

  @override
  Widget build(BuildContext context) {
    final frac = (stat.value / stat.target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Icon(stat.icon, size: 11 * uiScale, color: stat.color),
            SizedBox(width: 4 * uiScale),
            Text(
              stat.label,
              style: TextStyle(
                fontSize: 9.5 * uiScale,
                color: const Color(0xFF6B6B7B),
              ),
            ),
          ],
        ),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${stat.value}',
                style: TextStyle(
                  fontSize: 12.5 * uiScale,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1B1B2E),
                ),
              ),
              TextSpan(
                text: ' / ${stat.target} ${stat.unit}',
                style: TextStyle(
                  fontSize: 9 * uiScale,
                  color: const Color(0xFF9A96A8),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 3 * uiScale),
        AnimatedBuilder(
          animation: anim,
          builder: (context, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: frac * anim.value,
                minHeight: 4 * uiScale,
                backgroundColor: const Color(0xFFEDEAF7),
                valueColor: AlwaysStoppedAnimation(stat.color),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.progress});
  final double progress; // 0..1

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 6;
    final bgPaint = Paint()
      ..color = const Color(0xFFEDEAF7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      bgPaint,
    );

    final fgPaint = Paint()
      ..shader = const SweepGradient(
        colors: [Color(0xFF6C4EF5), Color(0xFF1E8A4C)],
        startAngle: 0,
        endAngle: math.pi * 1.5,
        transform: GradientRotation(math.pi * 0.75),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5 * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.progress != progress;
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
  });

  final double uiScale;
  final List<RecentScan> scans;
  final VoidCallback? onViewAll;
  final ValueChanged<int>? onProductTap;

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
              color: const Color(0xFF1E8A4C),
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
                  aspectRatio: 1.1,
                  child: Container(
                    color: Colors.white,
                    padding: EdgeInsets.all(6 * widget.uiScale),
                    child: Image.asset(widget.scan.asset, fit: BoxFit.contain),
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
                        color: const Color(0xFF1B1B2E),
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: 3 * widget.uiScale),
                    Text(
                      widget.scan.time,
                      style: TextStyle(
                        fontSize: 9 * widget.uiScale,
                        color: const Color(0xFF9A96A8),
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
    return Container(
      padding: EdgeInsets.all(14 * uiScale),
      decoration: BoxDecoration(
        color: const Color(0xFFF1ECFB),
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
                    color: const Color(0xFF6C4EF5),
                  ),
                ),
                SizedBox(height: 2 * uiScale),
                Text(
                  'Chat with your AI Nutrition Coach for expert '
                  'recommendations.',
                  style: TextStyle(
                    fontSize: 10.5 * uiScale,
                    height: 1.3,
                    color: const Color(0xFF6B6B7B),
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
            gradient: const LinearGradient(
              colors: [Color(0xFF6C4EF5), Color(0xFF1E8A4C)],
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
              color: Colors.black.withOpacity(0.08),
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
