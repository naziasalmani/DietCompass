import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../scan/scan_screen.dart';
import '../ai/ai_recommendation_screen.dart';
import '../pantry/pantry_screen.dart';

/// DietCompass — Dashboard Screen
/// -----------------------------------------------------------------------
/// Reuses assets/images/robot_badge.png for the AI Insight banner.
///
/// You mentioned you'll be adding photos yourself — the "Top Foods This
/// Week" list takes an [imageAsset] path per item (e.g.
/// 'assets/images/food_oats_fruits.png'). Paths that aren't in your
/// assets yet simply fall back to a soft bowl icon instead of crashing,
/// so you can drop real photos in whenever you have them; just declare
/// them in pubspec.yaml once added.
///
/// Add to pubspec.yaml (skip any already present):
/// ```yaml
/// flutter:
///   assets:
///     - assets/images/robot_badge.png
///     # add your own "top foods" photos here as you capture them:
///     # - assets/images/food_oats_fruits.png
///     # - assets/images/food_boiled_eggs.png
///     # - assets/images/food_moong_dal.png
/// ```
class NutrientSummaryItem {
  const NutrientSummaryItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.current,
    required this.target,
    required this.unit,
    required this.barColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final num current;
  final num target;
  final String unit;
  final Color barColor;

  double get fraction => (current / target).clamp(0, 1).toDouble();
}

class GoalProgressItem {
  const GoalProgressItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.progressLabel,
    required this.fraction,
    required this.barColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String progressLabel;
  final double fraction;
  final Color barColor;
}

class TopFoodItem {
  const TopFoodItem({required this.imageAsset, required this.name, required this.timesLabel});
  final String imageAsset;
  final String name;
  final String timesLabel;
}

class MacroSlice {
  const MacroSlice({required this.label, required this.percent, required this.color});
  final String label;
  final double percent;
  final Color color;
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.userName = 'Nazia',
    this.avatarImage,
    this.nutritionScore = 92,
    this.streakDays = 12,
    this.nutrients = const [
      NutrientSummaryItem(icon: Icons.local_fire_department, iconColor: Color(0xFF6C4EF5), iconBg: Color(0xFFEDE7FA), label: 'Calories', current: 1420, target: 1800, unit: 'kcal', barColor: Color(0xFF6C4EF5)),
      NutrientSummaryItem(icon: Icons.fitness_center, iconColor: Color(0xFF1E8A4C), iconBg: Color(0xFFE4F5E9), label: 'Protein', current: 68, target: 100, unit: 'g', barColor: Color(0xFF1E8A4C)),
      NutrientSummaryItem(icon: Icons.grain, iconColor: Color(0xFF3B82F6), iconBg: Color(0xFFE3EEFC), label: 'Carbs', current: 160, target: 250, unit: 'g', barColor: Color(0xFF3B82F6)),
      NutrientSummaryItem(icon: Icons.opacity, iconColor: Color(0xFFE0862E), iconBg: Color(0xFFFCF2E0), label: 'Fat', current: 45, target: 60, unit: 'g', barColor: Color(0xFFE0862E)),
      NutrientSummaryItem(icon: Icons.eco, iconColor: Color(0xFF1E8A4C), iconBg: Color(0xFFE4F5E9), label: 'Fiber', current: 22, target: 30, unit: 'g', barColor: Color(0xFF1E8A4C)),
      NutrientSummaryItem(icon: Icons.water_drop, iconColor: Color(0xFF3B82F6), iconBg: Color(0xFFE3EEFC), label: 'Water', current: 6, target: 8, unit: 'glasses', barColor: Color(0xFF3B82F6)),
    ],
    this.weeklyCalories = const [1200, 1750, 1050, 1500, 1300, 1420, 400],
    this.weekdayLabels = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    this.highlightedDayIndex = 5,
    this.macroSlices = const [
      MacroSlice(label: 'Carbs', percent: 50, color: Color(0xFF6C4EF5)),
      MacroSlice(label: 'Protein', percent: 19, color: Color(0xFF1E8A4C)),
      MacroSlice(label: 'Fat', percent: 28, color: Color(0xFFE0862E)),
      MacroSlice(label: 'Others', percent: 3, color: Color(0xFF3B82F6)),
    ],
    this.macroCalories = '1,420',
    this.aiInsight = "Great job! Your protein intake is on track. Try "
        'increasing fiber-rich foods for better digestion.',
    this.topFoods = const [
      TopFoodItem(imageAsset: 'assets/images/food_oats_fruits.png', name: 'Oats with Fruits', timesLabel: '5 times'),
      TopFoodItem(imageAsset: 'assets/images/food_boiled_eggs.png', name: 'Boiled Eggs', timesLabel: '4 times'),
      TopFoodItem(imageAsset: 'assets/images/food_moong_dal.png', name: 'Moong Dal', timesLabel: '3 times'),
    ],
    this.goals = const [
      GoalProgressItem(icon: Icons.eco, iconColor: Color(0xFF1E8A4C), iconBg: Color(0xFFE4F5E9), label: 'Lose Weight', progressLabel: '5 / 7 kg', fraction: 0.71, barColor: Color(0xFF1E8A4C)),
      GoalProgressItem(icon: Icons.directions_run, iconColor: Color(0xFFE0862E), iconBg: Color(0xFFFCF2E0), label: 'Daily Steps', progressLabel: '6,250 / 10,000 steps', fraction: 0.63, barColor: Color(0xFFE0862E)),
      GoalProgressItem(icon: Icons.water_drop, iconColor: Color(0xFF3B82F6), iconBg: Color(0xFFE3EEFC), label: 'Water Intake', progressLabel: '6 / 8 glasses', fraction: 0.75, barColor: Color(0xFF3B82F6)),
    ],
    this.onNotificationTap,
    this.onCalendarTap,
    this.onNutrientSeeDetails,
    this.onViewInsightsTap,
    this.onTopFoodsSeeAll,
    this.onTopFoodTap,
    this.onEditGoalsTap,
    this.onCaloriesRangeTap,
    this.onMacroRangeTap,
    this.onNavTap,
    this.initialNavIndex = 4,
  });

  final String userName;
  final ImageProvider? avatarImage;
  final int nutritionScore;
  final int streakDays;
  final List<NutrientSummaryItem> nutrients;
  final List<num> weeklyCalories;
  final List<String> weekdayLabels;
  final int highlightedDayIndex;
  final List<MacroSlice> macroSlices;
  final String macroCalories;
  final String aiInsight;
  final List<TopFoodItem> topFoods;
  final List<GoalProgressItem> goals;

  final VoidCallback? onNotificationTap;
  final VoidCallback? onCalendarTap;
  final VoidCallback? onNutrientSeeDetails;
  final VoidCallback? onViewInsightsTap;
  final VoidCallback? onTopFoodsSeeAll;
  final ValueChanged<int>? onTopFoodTap;
  final VoidCallback? onEditGoalsTap;
  final VoidCallback? onCaloriesRangeTap;
  final VoidCallback? onMacroRangeTap;
  final ValueChanged<int>? onNavTap;
  final int initialNavIndex;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _ambientCtrl;
  late int _navIndex;

  @override
  void initState() {
    super.initState();
    _navIndex = widget.initialNavIndex;
    _entranceCtrl = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 1700),
)..value = 1.0;
    _ambientCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat(reverse: true);
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
      backgroundColor: const Color(0xFFEFEAFA),
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

  SafeArea(
            bottom: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16 * scale, 8 * scale, 16 * scale, 110 * scale),
              physics: const BouncingScrollPhysics(),
              children: [
                FadeTransition(
                  opacity: _fade(0.0, 0.25),
                  child: _Header(
                    uiScale: scale,
                    userName: widget.userName,
                    avatarImage: widget.avatarImage,
                    onNotificationTap: widget.onNotificationTap,
                    onCalendarTap: widget.onCalendarTap,
                  ),
                ),
                SizedBox(height: 18 * scale),

                FadeTransition(
                  opacity: _fade(0.03, 0.3),
                  child: Text('Your Overview', style: TextStyle(fontSize: 16.5 * scale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
                ),
                SizedBox(height: 10 * scale),

                FadeTransition(
                  opacity: _fade(0.06, 0.4),
                  child: SlideTransition(
                    position: _slide(0.06, 0.42),
                    child: _OverviewRow(
                      uiScale: scale,
                      entranceCtrl: _entranceCtrl,
                      score: widget.nutritionScore,
                      streakDays: widget.streakDays,
                      ambientCtrl: _ambientCtrl,
                    ),
                  ),
                ),
                SizedBox(height: 20 * scale),

                FadeTransition(
                  opacity: _fade(0.14, 0.46),
                  child: Row(
                    children: [
                      Text('Nutrient Summary', style: TextStyle(fontSize: 15.5 * scale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
                      const Spacer(),
                      GestureDetector(
                        onTap: widget.onNutrientSeeDetails,
                        child: Row(
                          children: [
                            Text('See Details', style: TextStyle(fontSize: 12 * scale, fontWeight: FontWeight.w700, color: const Color(0xFF6C4EF5))),
                            Icon(Icons.chevron_right, size: 15 * scale, color: const Color(0xFF6C4EF5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10 * scale),

                FadeTransition(
                  opacity: _fade(0.16, 0.5),
                  child: SlideTransition(
                    position: _slide(0.16, 0.52),
                    child: _NutrientGrid(uiScale: scale, entranceCtrl: _entranceCtrl, items: widget.nutrients),
                  ),
                ),
                SizedBox(height: 18 * scale),

                FadeTransition(
                  opacity: _fade(0.24, 0.58),
                  child: SlideTransition(
                    position: _slide(0.24, 0.6),
                    child: _CaloriesTrendCard(
                      uiScale: scale,
                      entranceCtrl: _entranceCtrl,
                      values: widget.weeklyCalories,
                      labels: widget.weekdayLabels,
                      highlightIndex: widget.highlightedDayIndex,
                      onRangeTap: widget.onCaloriesRangeTap,
                    ),
                  ),
                ),
                SizedBox(height: 14 * scale),

                FadeTransition(
                  opacity: _fade(0.3, 0.64),
                  child: SlideTransition(
                    position: _slide(0.3, 0.66),
                    child: _MacroDistributionCard(
                      uiScale: scale,
                      entranceCtrl: _entranceCtrl,
                      slices: widget.macroSlices,
                      centerCalories: widget.macroCalories,
                      onRangeTap: widget.onMacroRangeTap,
                    ),
                  ),
                ),
                SizedBox(height: 18 * scale),

                FadeTransition(
                  opacity: _fade(0.46, 0.8),
                  child: SlideTransition(
                    position: _slide(0.46, 0.82),
                    child: _TwoColumnLists(
                      uiScale: scale,
                      topFoods: widget.topFoods,
                      goals: widget.goals,
                      onTopFoodsSeeAll: widget.onTopFoodsSeeAll,
                      onTopFoodTap: widget.onTopFoodTap,
                      onEditGoalsTap: widget.onEditGoalsTap,
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
    case 0:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
      break;

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
      // Already on Dashboard.
      break;
  }

  widget.onNavTap?.call(i);
},
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Background: gradient + dotted pattern + drifting leaves (reused style)
// ---------------------------------------------------------------------------
class _BackgroundDecor extends StatelessWidget {
  const _BackgroundDecor();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEFEAFA), Color(0xFFF3F0FB)],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          bottom: 0,
          width: 70,
          child: Opacity(
            opacity: 0.35,
            child: CustomPaint(painter: _DotColumnPainter()),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          width: 90,
          height: 220,
          child: Opacity(
            opacity: 0.25,
            child: CustomPaint(painter: _DotColumnPainter()),
          ),
        ),
        Positioned(
          top: 190,
          right: 10,
          child: Opacity(
            opacity: 0.3,
            child: Icon(Icons.eco_rounded, size: 90, color: const Color(0xFFB9A6F2)),
          ),
        ),
      ],
    );
  }
}

class _DotColumnPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF7C5CFC);
    const spacing = 13.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 2.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Glass card helper
// ---------------------------------------------------------------------------
class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.padding, this.radius = 20});
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: padding ?? const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.6)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 18, offset: const Offset(0, 8))],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------
class _Header extends StatelessWidget {
  const _Header({
    required this.uiScale,
    required this.userName,
    this.avatarImage,
    this.onNotificationTap,
    this.onCalendarTap,
  });

  final double uiScale;
  final String userName;
  final ImageProvider? avatarImage;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onCalendarTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52 * uiScale,
          height: 52 * uiScale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Color(0xFF6C4EF5), Color(0xFF1E8A4C)]),
            image: avatarImage != null ? DecorationImage(image: avatarImage!, fit: BoxFit.cover) : null,
          ),
          child: avatarImage == null
              ? Center(
                  child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 19 * uiScale)),
                )
              : null,
        ),
        SizedBox(width: 12 * uiScale),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Hello, $userName! ', style: TextStyle(fontSize: 17 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
                  Text('👋', style: TextStyle(fontSize: 15 * uiScale)),
                ],
              ),
              Text('Track your progress & build healthier habits.',
                  style: TextStyle(fontSize: 11 * uiScale, height: 1.3, color: const Color(0xFF6B6B7B))),
            ],
          ),
        ),
        SizedBox(width: 8 * uiScale),
        _HeaderIconButton(uiScale: uiScale, icon: Icons.notifications_none_rounded, showDot: true, onTap: onNotificationTap),
        SizedBox(width: 8 * uiScale),
        _HeaderIconButton(uiScale: uiScale, icon: Icons.calendar_today_outlined, onTap: onCalendarTap),
      ],
    );
  }
}

class _HeaderIconButton extends StatefulWidget {
  const _HeaderIconButton({required this.uiScale, required this.icon, this.showDot = false, this.onTap});
  final double uiScale;
  final IconData icon;
  final bool showDot;
  final VoidCallback? onTap;

  @override
  State<_HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<_HeaderIconButton> {
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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40 * widget.uiScale,
              height: 40 * widget.uiScale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Icon(widget.icon, size: 17 * widget.uiScale, color: const Color(0xFF6C4EF5)),
            ),
            if (widget.showDot)
              Positioned(
                top: 1,
                right: 3,
                child: Container(
                  width: 8 * widget.uiScale,
                  height: 8 * widget.uiScale,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFE0525C), border: Border.all(color: Colors.white, width: 1.4)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overview row: Nutrition Score gauge + Streak
// ---------------------------------------------------------------------------
class _OverviewRow extends StatelessWidget {
  const _OverviewRow({
    required this.uiScale,
    required this.entranceCtrl,
    required this.score,
    required this.streakDays,
    required this.ambientCtrl,
  });

  final double uiScale;
  final AnimationController entranceCtrl;
  final int score;
  final int streakDays;
  final AnimationController ambientCtrl;

  @override
Widget build(BuildContext context) {
  return Row(
    children: [
      Expanded(
        child: _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nutrition Score',
                style: TextStyle(
                  fontSize: 12.5 * uiScale,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF6C4EF5),
                ),
              ),
              SizedBox(height: 8 * uiScale),
              Text(
                '$score / 100',
                style: TextStyle(
                  fontSize: 30 * uiScale,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1B1B2E),
                ),
              ),
              SizedBox(height: 6 * uiScale),
              Text(
                'Excellent',
                style: TextStyle(
                  fontSize: 10 * uiScale,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E8A4C),
                ),
              ),
            ],
          ),
        ),
      ),

      SizedBox(width: 12 * uiScale),

      Expanded(
        child: _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Streak',
                style: TextStyle(
                  fontSize: 12.5 * uiScale,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF6C4EF5),
                ),
              ),
              SizedBox(height: 8 * uiScale),
              Icon(
                Icons.local_fire_department,
                color: const Color(0xFFE0862E),
                size: 28 * uiScale,
              ),
              SizedBox(height: 8 * uiScale),
              Text(
                '$streakDays days',
                style: TextStyle(
                  fontSize: 20 * uiScale,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1B1B2E),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
}

class _RingGaugePainter extends CustomPainter {
  _RingGaugePainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 6;
    final bg = Paint()
      ..color = const Color(0xFFE4DCF9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);

    final fg = Paint()
      ..color = const Color(0xFF6C4EF5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, 2 * math.pi * progress, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingGaugePainter oldDelegate) => oldDelegate.progress != progress;
}

// ---------------------------------------------------------------------------
// Nutrient summary grid
// ---------------------------------------------------------------------------
class _NutrientGrid extends StatelessWidget {
  const _NutrientGrid({required this.uiScale, required this.entranceCtrl, required this.items});
  final double uiScale;
  final AnimationController entranceCtrl;
  final List<NutrientSummaryItem> items;

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(parent: entranceCtrl, curve: const Interval(0.2, 0.7, curve: Curves.easeOut));
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10 * uiScale,
        crossAxisSpacing: 10 * uiScale,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, i) => _NutrientTile(uiScale: uiScale, item: items[i], anim: anim),
    );
  }
}

class _NutrientTile extends StatelessWidget {
  const _NutrientTile({required this.uiScale, required this.item, required this.anim});
  final double uiScale;
  final NutrientSummaryItem item;
  final Animation<double> anim;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      radius: 16,
      padding: EdgeInsets.all(10 * uiScale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30 * uiScale,
            height: 30 * uiScale,
            decoration: BoxDecoration(color: item.iconBg, shape: BoxShape.circle),
            child: Icon(item.icon, size: 14 * uiScale, color: item.iconColor),
          ),
          SizedBox(height: 6 * uiScale),
          Text(item.label, style: TextStyle(fontSize: 10.5 * uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF1B1B2E))),
          Text('${item.current} / ${item.target}', style: TextStyle(fontSize: 9.5 * uiScale, color: const Color(0xFF6B6B7B))),
          Text(item.unit, style: TextStyle(fontSize: 8.5 * uiScale, color: const Color(0xFF9A96A8))),
          SizedBox(height: 6 * uiScale),
          AnimatedBuilder(
            animation: anim,
            builder: (context, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: item.fraction * anim.value,
                  minHeight: 4 * uiScale,
                  backgroundColor: const Color(0xFFEDEAF7),
                  valueColor: AlwaysStoppedAnimation(item.barColor),
                ),
              );
            },
          ),
          SizedBox(height: 3 * uiScale),
          AnimatedBuilder(
            animation: anim,
            builder: (context, _) {
              return Text('${(item.fraction * anim.value * 100).round()}%',
                  style: TextStyle(fontSize: 9 * uiScale, fontWeight: FontWeight.w700, color: item.barColor));
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Calories trend line chart
// ---------------------------------------------------------------------------
class _CaloriesTrendCard extends StatelessWidget {
  const _CaloriesTrendCard({
    required this.uiScale,
    required this.entranceCtrl,
    required this.values,
    required this.labels,
    required this.highlightIndex,
    this.onRangeTap,
  });

  final double uiScale;
  final AnimationController entranceCtrl;
  final List<num> values;
  final List<String> labels;
  final int highlightIndex;
  final VoidCallback? onRangeTap;

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(parent: entranceCtrl, curve: const Interval(0.3, 0.85, curve: Curves.easeOutCubic));
    final maxVal = 2000.0;

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Calories Trend', style: TextStyle(fontSize: 13.5 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF6C4EF5))),
              const Spacer(),
              GestureDetector(
                onTap: onRangeTap,
                child: Row(
                  children: [
                    Text('This Week', style: TextStyle(fontSize: 10.5 * uiScale, color: const Color(0xFF6B6B7B))),
                    Icon(Icons.keyboard_arrow_down, size: 14 * uiScale, color: const Color(0xFF6B6B7B)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * uiScale),
          SizedBox(
            height: 160 * uiScale,
            child: AnimatedBuilder(
              animation: anim,
              builder: (context, _) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _LineChartPainter(
                    values: values,
                    labels: labels,
                    maxVal: maxVal,
                    progress: anim.value,
                    highlightIndex: highlightIndex,
                    uiScale: uiScale,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.values,
    required this.labels,
    required this.maxVal,
    required this.progress,
    required this.highlightIndex,
    required this.uiScale,
  });

  final List<num> values;
  final List<String> labels;
  final double maxVal;
  final double progress;
  final int highlightIndex;
  final double uiScale;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 34.0;
    const bottomPad = 20.0;
    final chartW = size.width - leftPad;
    final chartH = size.height - bottomPad;

    final labelStyle = TextStyle(color: const Color(0xFF9A96A8), fontSize: 9.5 * uiScale);
    for (int i = 0; i <= 4; i++) {
      final v = (maxVal / 4 * i).round();
      final y = chartH - (chartH * i / 4);
      final tp = TextPainter(
        text: TextSpan(text: '$v', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));

      final gridPaint = Paint()
        ..color = const Color(0xFFE4E0F2)
        ..strokeWidth = 1;
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);
    }

    if (values.isEmpty) return;
    final n = values.length;
    final visibleCount = (n * progress).clamp(1, n);
    final points = <Offset>[];
    for (int i = 0; i < n; i++) {
      final x = leftPad + (chartW * i / (n - 1));
      final v = values[i].toDouble().clamp(0, maxVal);
      final y = chartH - (chartH * v / maxVal);
      points.add(Offset(x, y));
    }

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, leftPad + chartW * (visibleCount - 1) / math.max(1, n - 1), size.height));

    final fillPath = Path()..moveTo(points.first.dx, chartH);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, chartH);
    fillPath.close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF6C4EF5).withOpacity(0.25), const Color(0xFF6C4EF5).withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartH));
    canvas.drawPath(fillPath, fillPaint);

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    final linePaint = Paint()
      ..color = const Color(0xFF6C4EF5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = Colors.white;
    final dotBorder = Paint()
      ..color = const Color(0xFF6C4EF5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final p in points) {
      canvas.drawCircle(p, 4, dotPaint);
      canvas.drawCircle(p, 4, dotBorder);
    }
    canvas.restore();

    for (int i = 0; i < n; i++) {
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(points[i].dx - tp.width / 2, chartH + 4));
    }

    if (progress > 0.85 && highlightIndex < points.length) {
      final hp = points[highlightIndex];
      final label = '${values[highlightIndex]} kcal';
      final tp = TextPainter(
        text: TextSpan(text: label, style: TextStyle(color: Colors.white, fontSize: 10 * uiScale, fontWeight: FontWeight.w700)),
        textDirection: TextDirection.ltr,
      )..layout();
      final boxW = tp.width + 16;
      final boxH = tp.height + 10;
      final boxRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(hp.dx, hp.dy - boxH), width: boxW, height: boxH),
        const Radius.circular(8),
      );
      final tooltipPaint = Paint()..color = const Color(0xFF6C4EF5);
      canvas.drawRRect(boxRect, tooltipPaint);
      tp.paint(canvas, Offset(boxRect.left + 8, boxRect.top + 5));
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => oldDelegate.progress != progress;
}

// ---------------------------------------------------------------------------
// Macro distribution donut chart
// ---------------------------------------------------------------------------
class _MacroDistributionCard extends StatelessWidget {
  const _MacroDistributionCard({
    required this.uiScale,
    required this.entranceCtrl,
    required this.slices,
    required this.centerCalories,
    this.onRangeTap,
  });

  final double uiScale;
  final AnimationController entranceCtrl;
  final List<MacroSlice> slices;
  final String centerCalories;
  final VoidCallback? onRangeTap;

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(parent: entranceCtrl, curve: const Interval(0.35, 0.9, curve: Curves.easeOutCubic));

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Macro Distribution', style: TextStyle(fontSize: 13.5 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF6C4EF5))),
              const Spacer(),
              GestureDetector(
                onTap: onRangeTap,
                child: Row(
                  children: [
                    Text('Today', style: TextStyle(fontSize: 10.5 * uiScale, color: const Color(0xFF6B6B7B))),
                    Icon(Icons.keyboard_arrow_down, size: 14 * uiScale, color: const Color(0xFF6B6B7B)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14 * uiScale),
          Row(
            children: [
              AnimatedBuilder(
                animation: anim,
                builder: (context, _) {
                  return SizedBox(
                    width: 110 * uiScale,
                    height: 110 * uiScale,
                    child: CustomPaint(
                      painter: _DonutPainter(slices: slices, progress: anim.value),
                      child: Center(
                        child: Text.rich(
                          TextSpan(children: [
                            TextSpan(text: centerCalories, style: TextStyle(fontSize: 15 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
                            TextSpan(text: '\nkcal', style: TextStyle(fontSize: 9.5 * uiScale, color: const Color(0xFF9A96A8))),
                          ]),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(width: 16 * uiScale),
              Expanded(
                child: Column(
                  children: slices.map((s) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 5 * uiScale),
                      child: Row(
                        children: [
                          Container(width: 9 * uiScale, height: 9 * uiScale, decoration: BoxDecoration(shape: BoxShape.circle, color: s.color)),
                          SizedBox(width: 8 * uiScale),
                          Expanded(child: Text(s.label, style: TextStyle(fontSize: 11.5 * uiScale, color: const Color(0xFF3B3B4F)))),
                          Text('${s.percent.round()}%', style: TextStyle(fontSize: 11.5 * uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF1B1B2E))),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.slices, required this.progress});
  final List<MacroSlice> slices;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 6;
    var startAngle = -math.pi / 2;
    final totalSweep = 2 * math.pi * progress;
    var sweptSoFar = 0.0;
    final total = slices.fold<double>(0, (sum, s) => sum + s.percent);

    for (final s in slices) {
      final sliceSweep = (s.percent / total) * 2 * math.pi;
      final remaining = totalSweep - sweptSoFar;
      final drawSweep = remaining.clamp(0, sliceSweep).toDouble();
      if (drawSweep <= 0) break;
      final paint = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, drawSweep, false, paint);
      startAngle += sliceSweep;
      sweptSoFar += sliceSweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.progress != progress;
}

class _InsightSparkles extends StatelessWidget {
  const _InsightSparkles({required this.controller});
  final AnimationController controller;

  static const _positions = [Offset(0.3, 0.15), Offset(0.55, 0.55), Offset(0.75, 0.2)];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return IgnorePointer(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return Stack(
                children: List.generate(_positions.length, (i) {
                  final phase = (controller.value + i / _positions.length) % 1;
                  final opacity = (math.sin(phase * math.pi * 2) + 1) / 2;
                  final pos = _positions[i];
                  return Positioned(
                    left: constraints.maxWidth * pos.dx,
                    top: constraints.maxHeight * pos.dy,
                    child: Opacity(
                      opacity: 0.2 + opacity * 0.6,
                      child: const Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                    ),
                  );
                }),
              );
            },
          ),
        );
      },
    );
  }
}

class _ViewInsightsButton extends StatefulWidget {
  const _ViewInsightsButton({required this.uiScale, this.onTap});
  final double uiScale;
  final VoidCallback? onTap;

  @override
  State<_ViewInsightsButton> createState() => _ViewInsightsButtonState();
}

class _ViewInsightsButtonState extends State<_ViewInsightsButton> {
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
          padding: EdgeInsets.symmetric(horizontal: 14 * widget.uiScale, vertical: 10 * widget.uiScale),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('View Insights', style: TextStyle(fontSize: 11.5 * widget.uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF6C4EF5))),
              SizedBox(width: 5 * widget.uiScale),
              Icon(Icons.arrow_forward, size: 13 * widget.uiScale, color: const Color(0xFF6C4EF5)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Two-column lists: Top Foods This Week + Goal Progress
// ---------------------------------------------------------------------------
class _TwoColumnLists extends StatelessWidget {
  const _TwoColumnLists({
    required this.uiScale,
    required this.topFoods,
    required this.goals,
    this.onTopFoodsSeeAll,
    this.onTopFoodTap,
    this.onEditGoalsTap,
  });

  final double uiScale;
  final List<TopFoodItem> topFoods;
  final List<GoalProgressItem> goals;
  final VoidCallback? onTopFoodsSeeAll;
  final ValueChanged<int>? onTopFoodTap;
  final VoidCallback? onEditGoalsTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Top Foods This Week', style: TextStyle(fontSize: 13.5 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF6C4EF5))),
                  const Spacer(),
                  GestureDetector(
                    onTap: onTopFoodsSeeAll,
                    child: Row(
                      children: [
                        Text('See All', style: TextStyle(fontSize: 11 * uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF6C4EF5))),
                        Icon(Icons.chevron_right, size: 14 * uiScale, color: const Color(0xFF6C4EF5)),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8 * uiScale),
              ...List.generate(topFoods.length, (i) {
                final food = topFoods[i];
                return _TopFoodRow(uiScale: uiScale, food: food, onTap: () => onTopFoodTap?.call(i));
              }),
            ],
          ),
        ),
        SizedBox(height: 14 * uiScale),
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Goal Progress', style: TextStyle(fontSize: 13.5 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF6C4EF5))),
                  const Spacer(),
                  GestureDetector(
                    onTap: onEditGoalsTap,
                    child: Row(
                      children: [
                        Text('Edit Goals', style: TextStyle(fontSize: 11 * uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF6C4EF5))),
                        Icon(Icons.chevron_right, size: 14 * uiScale, color: const Color(0xFF6C4EF5)),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8 * uiScale),
              ...goals.map((g) => _GoalRow(uiScale: uiScale, goal: g)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopFoodRow extends StatefulWidget {
  const _TopFoodRow({required this.uiScale, required this.food, this.onTap});
  final double uiScale;
  final TopFoodItem food;
  final VoidCallback? onTap;

  @override
  State<_TopFoodRow> createState() => _TopFoodRowState();
}

class _TopFoodRowState extends State<_TopFoodRow> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8 * widget.uiScale),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 42 * widget.uiScale,
                  height: 42 * widget.uiScale,
                  color: const Color(0xFFF6F3FC),
                  padding: EdgeInsets.all(4 * widget.uiScale),
                  child: Image.asset(
                    widget.food.imageAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.ramen_dining_outlined, size: 18 * widget.uiScale, color: const Color(0xFF9A96A8)),
                  ),
                ),
              ),
              SizedBox(width: 10 * widget.uiScale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.food.name, style: TextStyle(fontSize: 12.5 * widget.uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF1B1B2E))),
                    Text(widget.food.timesLabel, style: TextStyle(fontSize: 10.5 * widget.uiScale, fontWeight: FontWeight.w600, color: const Color(0xFF1E8A4C))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 16 * widget.uiScale, color: const Color(0xFFB0ACC2)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.uiScale, required this.goal});
  final double uiScale;
  final GoalProgressItem goal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8 * uiScale),
      child: Row(
        children: [
          Container(
            width: 36 * uiScale,
            height: 36 * uiScale,
            decoration: BoxDecoration(color: goal.iconBg, shape: BoxShape.circle),
            child: Icon(goal.icon, size: 16 * uiScale, color: goal.iconColor),
          ),
          SizedBox(width: 10 * uiScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goal.label, style: TextStyle(fontSize: 12 * uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF1B1B2E))),
                Text(goal.progressLabel, style: TextStyle(fontSize: 10 * uiScale, color: const Color(0xFF6B6B7B))),
                SizedBox(height: 4 * uiScale),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: goal.fraction),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 5 * uiScale,
                        backgroundColor: const Color(0xFFEDEAF7),
                        valueColor: AlwaysStoppedAnimation(goal.barColor),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(width: 8 * uiScale),
          Text('${(goal.fraction * 100).round()}%', style: TextStyle(fontSize: 11.5 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom nav bar
// ---------------------------------------------------------------------------
class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.uiScale, required this.selectedIndex, required this.onTap});
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
        margin: EdgeInsets.fromLTRB(10 * uiScale, 0, 10 * uiScale, 10 * uiScale),
        padding: EdgeInsets.symmetric(vertical: 8 * uiScale),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
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
                padding: EdgeInsets.symmetric(horizontal: selected ? 10 * uiScale : 6 * uiScale, vertical: 6 * uiScale),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFEDE7FA) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, size: 18 * uiScale, color: selected ? const Color(0xFF6C4EF5) : const Color(0xFFB0ACC2)),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      child: selected
                          ? Padding(
                              padding: EdgeInsets.only(top: 2 * uiScale),
                              child: Text(item.label, style: TextStyle(fontSize: 8.5 * uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF6C4EF5))),
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
