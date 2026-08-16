import 'dart:ui';

import 'package:flutter/material.dart';
import 'pdf_service.dart';
import 'calendar_service.dart';

/// DietCompass — AI Weekly Meal Planner Screen
/// -----------------------------------------------------------------------
/// Matches the visual language of the rest of the app: lavender background
/// (0xFFF3F0FB), purple → green brand accents, frosted glassmorphism
/// cards, staggered entrance choreography and small interactive
/// micro-animations (segmented duration selector, animated toggle, day
/// tabs, count-up totals, staggered meal-row reveal).
class MealEntry {
  const MealEntry({
    required this.type,
    required this.name,
    required this.kcal,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.pillBg,
    required this.pillColor,
    this.isVegetarian = true,
  });
  final String type;
  final String name;
  final int kcal;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Color pillBg;
  final Color pillColor;
  final bool isVegetarian;
}

class DayPlan {
  const DayPlan({
    required this.dayLabel,
    required this.dayNumber,
    required this.meals,
    required this.totalCalories,
    required this.proteinG,
    required this.fiberG,
    required this.waterGlasses,
  });
  final String dayLabel;
  final String dayNumber;
  final List<MealEntry> meals;
  final int totalCalories;
  final int proteinG;
  final int fiberG;
  final int waterGlasses;
}

class AiMealPlannerScreen extends StatefulWidget {
  AiMealPlannerScreen({
    super.key,
    this.goalOptions = const ['Weight Loss', 'Weight Gain', 'Maintain Weight', 'Muscle Gain'],
    this.calorieOptions = const ['1500 kcal', '1800 kcal', '2000 kcal', '2200 kcal', '2500 kcal'],
    this.mealTypeOptions = const [
      'Breakfast, Lunch, Dinner, Snacks',
      'Breakfast, Lunch, Dinner',
      'Lunch, Dinner',
    ],
    this.dietOptions = const ['Vegetarian', 'Vegan', 'Non-Vegetarian', 'Eggetarian', 'Keto'],
    this.allergyOptions = const ['None', 'Peanut', 'Tree Nuts', 'Dairy', 'Gluten', 'Soy'],
    this.budgetOptions = const ['Low', 'Moderate', 'High'],
    List<DayPlan>? weekPlan,
    this.onBack,
    this.onCalendarTap,
    this.onExportPdf,
    this.onAddToCalendar,
    this.onRegenerate,
  }) : weekPlan = weekPlan ?? _defaultWeekPlan();

  final List<String> goalOptions;
  final List<String> calorieOptions;
  final List<String> mealTypeOptions;
  final List<String> dietOptions;
  final List<String> allergyOptions;
  final List<String> budgetOptions;
  final List<DayPlan> weekPlan;

  final VoidCallback? onBack;
  final VoidCallback? onCalendarTap;
  final VoidCallback? onExportPdf;
  final VoidCallback? onAddToCalendar;
  final VoidCallback? onRegenerate;

  static List<DayPlan> _defaultWeekPlan() {
    const days = [
      ('Mon', 'Day 1'),
      ('Tue', 'Day 2'),
      ('Wed', 'Day 3'),
      ('Thu', 'Day 4'),
      ('Fri', 'Day 5'),
      ('Sat', 'Day 6'),
      ('Sun', 'Day 7'),
    ];
    final meals = [
      const MealEntry(
        type: 'Breakfast',
        name: 'Banana Oats Bowl',
        kcal: 350,
        icon: Icons.free_breakfast_rounded,
        iconBg: Color(0xFFEDE7FA),
        iconColor: Color(0xFF6C4EF5),
        pillBg: Color(0xFFEDE7FA),
        pillColor: Color(0xFF6C4EF5),
      ),
      const MealEntry(
        type: 'Lunch',
        name: 'Quinoa Veggie Salad',
        kcal: 450,
        icon: Icons.ramen_dining_rounded,
        iconBg: Color(0xFFE3F5EA),
        iconColor: Color(0xFF1E8A4C),
        pillBg: Color(0xFFE3F5EA),
        pillColor: Color(0xFF1E8A4C),
      ),
      const MealEntry(
        type: 'Snack',
        name: 'Apple & Almonds',
        kcal: 150,
        icon: Icons.apple_rounded,
        iconBg: Color(0xFFFCEEDD),
        iconColor: Color(0xFFE0862E),
        pillBg: Color(0xFFFCEEDD),
        pillColor: Color(0xFFE0862E),
      ),
      const MealEntry(
        type: 'Dinner',
        name: 'Paneer Stir Fry with Brown Rice',
        kcal: 550,
        icon: Icons.dinner_dining_rounded,
        iconBg: Color(0xFFEDE7FA),
        iconColor: Color(0xFF6C4EF5),
        pillBg: Color(0xFFEDE7FA),
        pillColor: Color(0xFF6C4EF5),
      ),
    ];
    return days
        .map((d) => DayPlan(
              dayLabel: d.$1,
              dayNumber: d.$2,
              meals: meals,
              totalCalories: 1500,
              proteinG: 65,
              fiberG: 28,
              waterGlasses: 8,
            ))
        .toList();
  }

  @override
  State<AiMealPlannerScreen> createState() => _AiMealPlannerScreenState();
}

class _AiMealPlannerScreenState extends State<AiMealPlannerScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;

  int _durationIndex = 2;
  static const _durations = ['1 Day', '3 Days', '7 Days', '30 Days'];

  late String _goal;
  late String _calories;
  late String _mealType;
  late String _diet;
  late String _allergy;
  late String _budget;
  bool _usePantry = true;
  int _selectedDay = 0;

  @override
  void initState() {
    super.initState();
    _goal = widget.goalOptions.first;
    _calories = widget.calorieOptions.length > 1 ? widget.calorieOptions[1] : widget.calorieOptions.first;
    _mealType = widget.mealTypeOptions.first;
    _diet = widget.dietOptions.first;
    _allergy = widget.allergyOptions.first;
    _budget = widget.budgetOptions.length > 1 ? widget.budgetOptions[1] : widget.budgetOptions.first;

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
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
    final day = widget.weekPlan[_selectedDay.clamp(0, widget.weekPlan.length - 1)];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FB),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _GlassBackdrop(uiScale: scale),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(18 * scale, 8 * scale, 18 * scale, 16 * scale),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      FadeTransition(
                        opacity: _fade(0.0, 0.26),
                        child: SlideTransition(
                          position: _slide(0.0, 0.3),
                          child: _TopHeader(uiScale: scale, onBack: widget.onBack, onCalendarTap: widget.onCalendarTap),
                        ),
                      ),
                      SizedBox(height: 16 * scale),

                      FadeTransition(
                        opacity: _fade(0.06, 0.34),
                        child: SlideTransition(
                          position: _slide(0.06, 0.38),
                          child: _Glass(
                            uiScale: scale,
                            child: _PlanDurationSection(
                              uiScale: scale,
                              durations: _durations,
                              selectedIndex: _durationIndex,
                              onSelected: (i) => setState(() => _durationIndex = i),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16 * scale),

                      FadeTransition(
                        opacity: _fade(0.12, 0.42),
                        child: SlideTransition(
                          position: _slide(0.12, 0.46),
                          child: _Glass(
                            uiScale: scale,
                            child: _PreferencesSection(
                              uiScale: scale,
                              goal: _goal,
                              goalOptions: widget.goalOptions,
                              onGoalChanged: (v) => setState(() => _goal = v),
                              calories: _calories,
                              calorieOptions: widget.calorieOptions,
                              onCaloriesChanged: (v) => setState(() => _calories = v),
                              mealType: _mealType,
                              mealTypeOptions: widget.mealTypeOptions,
                              onMealTypeChanged: (v) => setState(() => _mealType = v),
                              diet: _diet,
                              dietOptions: widget.dietOptions,
                              onDietChanged: (v) => setState(() => _diet = v),
                              allergy: _allergy,
                              allergyOptions: widget.allergyOptions,
                              onAllergyChanged: (v) => setState(() => _allergy = v),
                              budget: _budget,
                              budgetOptions: widget.budgetOptions,
                              onBudgetChanged: (v) => setState(() => _budget = v),
                              usePantry: _usePantry,
                              onUsePantryChanged: (v) => setState(() => _usePantry = v),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16 * scale),

                      FadeTransition(
                        opacity: _fade(0.2, 0.5),
                        child: SlideTransition(
                          position: _slide(0.2, 0.54),
                          child: _Glass(
                            uiScale: scale,
                            child: _WeeklyPlanPreviewSection(
                              uiScale: scale,
                              weekPlan: widget.weekPlan,
                              selectedDay: _selectedDay,
                              onDaySelected: (i) => setState(() => _selectedDay = i),
                              day: day,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                FadeTransition(
                  opacity: _fade(0.5, 0.85),
                  child: _BottomActionBar(
  uiScale: scale,
  onExportPdf: widget.onExportPdf,
  onAddToCalendar: widget.onAddToCalendar,
  onRegenerate: widget.onRegenerate,
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
// Ambient glass backdrop
// ---------------------------------------------------------------------------
class _GlassBackdrop extends StatefulWidget {
  const _GlassBackdrop({required this.uiScale});
  final double uiScale;

  @override
  State<_GlassBackdrop> createState() => _GlassBackdropState();
}

class _GlassBackdropState extends State<_GlassBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uiScale = widget.uiScale;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        return Stack(
          fit: StackFit.expand,
          children: [
            Container(color: const Color(0xFFF3F0FB)),
            Positioned(top: -80 + t * 14, right: -60, child: _blob(200 * uiScale, const Color(0xFF6C4EF5))),
            Positioned(bottom: -60 + t * 12, left: -60, child: _blob(170 * uiScale, const Color(0xFF1E8A4C))),
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
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.16)),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Reusable frosted glass container
// ---------------------------------------------------------------------------
class _Glass extends StatelessWidget {
  const _Glass({required this.uiScale, required this.child, this.padding, this.radius = 22});
  final double uiScale;
  final Widget child;
  final EdgeInsets? padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: padding ?? EdgeInsets.all(16 * uiScale),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.1),
            boxShadow: [
              BoxShadow(color: const Color(0xFF6C4EF5).withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, this.onTap, this.minScale = 0.96});
  final Widget child;
  final VoidCallback? onTap;
  final double minScale;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _scale = widget.minScale),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _scale = 1.0),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top header
// ---------------------------------------------------------------------------
class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.uiScale, this.onBack, this.onCalendarTap});
  final double uiScale;
  final VoidCallback? onBack;
  final VoidCallback? onCalendarTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Pressable(
          onTap: onBack ?? () => Navigator.maybePop(context),
          child: Container(
            width: 42 * uiScale,
            height: 42 * uiScale,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Icon(Icons.arrow_back_rounded, size: 19 * uiScale, color: const Color(0xFF1B1B2E)),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, size: 16 * uiScale, color: const Color(0xFF6C4EF5)),
                  SizedBox(width: 6 * uiScale),
                  Flexible(
                    child: Text(
                      'AI Weekly Meal Planner',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16.5 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4 * uiScale),
              Text(
                'Let AI create a personalized meal plan\nthat fits your goals and lifestyle',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10.5 * uiScale, height: 1.35, color: const Color(0xFF6B6B7B)),
              ),
            ],
          ),
        ),
        _Pressable(
          onTap: onCalendarTap,
          child: Container(
            width: 42 * uiScale,
            height: 42 * uiScale,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6C4EF5), Color(0xFF8467F8)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFF6C4EF5).withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 6))],
            ),
            child: Icon(Icons.calendar_today_rounded, size: 17 * uiScale, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Plan Duration
// ---------------------------------------------------------------------------
class _PlanDurationSection extends StatelessWidget {
  const _PlanDurationSection({
    required this.uiScale,
    required this.durations,
    required this.selectedIndex,
    required this.onSelected,
  });
  final double uiScale;
  final List<String> durations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1. Plan Duration',
          style: TextStyle(fontSize: 14.5 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF6C4EF5)),
        ),
        SizedBox(height: 12 * uiScale),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 340;
            final buttons = List.generate(durations.length, (i) {
              final selected = i == selectedIndex;
              return _Pressable(
                onTap: () => onSelected(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.symmetric(horizontal: 14 * uiScale, vertical: 12 * uiScale),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFEDE7FA) : Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? const Color(0xFF6C4EF5) : const Color(0xFFE3DDF5),
                      width: selected ? 1.6 : 1,
                    ),
                  ),
                  child: Text(
                    durations[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12 * uiScale,
                      fontWeight: FontWeight.w700,
                      color: selected ? const Color(0xFF6C4EF5) : const Color(0xFF1B1B2E),
                    ),
                  ),
                ),
              );
            });
            if (narrow) {
              return Wrap(
                spacing: 8 * uiScale,
                runSpacing: 8 * uiScale,
                children: buttons.map((b) => SizedBox(width: (constraints.maxWidth - 8 * uiScale) / 2, child: b)).toList(),
              );
            }
            return Row(
              children: buttons
                  .map((b) => Expanded(child: Padding(padding: EdgeInsets.symmetric(horizontal: 3 * uiScale), child: b)))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Your Preferences
// ---------------------------------------------------------------------------
class _PreferencesSection extends StatelessWidget {
  const _PreferencesSection({
    required this.uiScale,
    required this.goal,
    required this.goalOptions,
    required this.onGoalChanged,
    required this.calories,
    required this.calorieOptions,
    required this.onCaloriesChanged,
    required this.mealType,
    required this.mealTypeOptions,
    required this.onMealTypeChanged,
    required this.diet,
    required this.dietOptions,
    required this.onDietChanged,
    required this.allergy,
    required this.allergyOptions,
    required this.onAllergyChanged,
    required this.budget,
    required this.budgetOptions,
    required this.onBudgetChanged,
    required this.usePantry,
    required this.onUsePantryChanged,
  });

  final double uiScale;
  final String goal;
  final List<String> goalOptions;
  final ValueChanged<String> onGoalChanged;
  final String calories;
  final List<String> calorieOptions;
  final ValueChanged<String> onCaloriesChanged;
  final String mealType;
  final List<String> mealTypeOptions;
  final ValueChanged<String> onMealTypeChanged;
  final String diet;
  final List<String> dietOptions;
  final ValueChanged<String> onDietChanged;
  final String allergy;
  final List<String> allergyOptions;
  final ValueChanged<String> onAllergyChanged;
  final String budget;
  final List<String> budgetOptions;
  final ValueChanged<String> onBudgetChanged;
  final bool usePantry;
  final ValueChanged<bool> onUsePantryChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '2. Your Preferences',
          style: TextStyle(fontSize: 14.5 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF6C4EF5)),
        ),
        SizedBox(height: 14 * uiScale),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 340;
            final fields = [
              _DropdownField(uiScale: uiScale, icon: Icons.track_changes_rounded, label: 'Goal', value: goal, options: goalOptions, onChanged: onGoalChanged),
              _DropdownField(uiScale: uiScale, icon: Icons.local_fire_department_rounded, label: 'Calories per day', value: calories, options: calorieOptions, onChanged: onCaloriesChanged),
              _DropdownField(uiScale: uiScale, icon: Icons.grid_view_rounded, label: 'Meal Type', value: mealType, options: mealTypeOptions, onChanged: onMealTypeChanged),
              _DropdownField(uiScale: uiScale, icon: Icons.eco_rounded, label: 'Diet Preference', value: diet, options: dietOptions, onChanged: onDietChanged),
              _DropdownField(uiScale: uiScale, icon: Icons.health_and_safety_rounded, label: 'Allergies / Intolerances', value: allergy, options: allergyOptions, onChanged: onAllergyChanged),
              _DropdownField(uiScale: uiScale, icon: Icons.savings_rounded, label: 'Budget (optional)', value: budget, options: budgetOptions, onChanged: onBudgetChanged),
            ];
            if (narrow) {
              return Column(
                children: fields
                    .map((f) => Padding(padding: EdgeInsets.only(bottom: 12 * uiScale), child: f))
                    .toList(),
              );
            }
            final rows = <Widget>[];
            for (int i = 0; i < fields.length; i += 2) {
              rows.add(Padding(
                padding: EdgeInsets.only(bottom: 12 * uiScale),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: fields[i]),
                    SizedBox(width: 12 * uiScale),
                    Expanded(child: i + 1 < fields.length ? fields[i + 1] : const SizedBox.shrink()),
                  ],
                ),
              ));
            }
            return Column(children: rows);
          },
        ),
        SizedBox(height: 4 * uiScale),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shopping_bag_rounded, size: 13 * uiScale, color: const Color(0xFF6C4EF5)),
                      SizedBox(width: 6 * uiScale),
                      Text(
                        'Use pantry ingredients',
                        style: TextStyle(fontSize: 12.5 * uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF1B1B2E)),
                      ),
                    ],
                  ),
                  SizedBox(height: 2 * uiScale),
                  Text(
                    'Prioritize ingredients from your pantry',
                    style: TextStyle(fontSize: 10.5 * uiScale, color: const Color(0xFF6B6B7B)),
                  ),
                ],
              ),
            ),
            _AnimatedToggle(uiScale: uiScale, value: usePantry, onChanged: onUsePantryChanged),
          ],
        ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.uiScale,
    required this.icon,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final double uiScale;
  final IconData icon;
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13 * uiScale, color: const Color(0xFF6C4EF5)),
            SizedBox(width: 6 * uiScale),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5 * uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF1B1B2E)),
              ),
            ),
          ],
        ),
        SizedBox(height: 6 * uiScale),
        PopupMenuButton<String>(
          onSelected: onChanged,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          itemBuilder: (context) => options
              .map((o) => PopupMenuItem(value: o, child: Text(o, style: TextStyle(fontSize: 12.5 * uiScale))))
              .toList(),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12 * uiScale, vertical: 12 * uiScale),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE3DDF5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12 * uiScale, fontWeight: FontWeight.w600, color: const Color(0xFF1B1B2E)),
                  ),
                ),
                Icon(Icons.expand_more_rounded, size: 16 * uiScale, color: const Color(0xFF6B6B7B)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedToggle extends StatelessWidget {
  const _AnimatedToggle({required this.uiScale, required this.value, required this.onChanged});
  final double uiScale;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 46 * uiScale,
        height: 26 * uiScale,
        padding: EdgeInsets.all(3 * uiScale),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: value
              ? const LinearGradient(colors: [Color(0xFF6C4EF5), Color(0xFF8467F8)])
              : null,
          color: value ? null : const Color(0xFFE3DDF5),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20 * uiScale,
            height: 20 * uiScale,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Your Weekly Plan (Preview)
// ---------------------------------------------------------------------------
class _WeeklyPlanPreviewSection extends StatelessWidget {
  const _WeeklyPlanPreviewSection({
    required this.uiScale,
    required this.weekPlan,
    required this.selectedDay,
    required this.onDaySelected,
    required this.day,
  });
  final double uiScale;
  final List<DayPlan> weekPlan;
  final int selectedDay;
  final ValueChanged<int> onDaySelected;
  final DayPlan day;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '3. Your Weekly Plan (Preview)',
                style: TextStyle(fontSize: 14.5 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF6C4EF5)),
              ),
            ),
            Icon(Icons.auto_awesome, size: 12 * uiScale, color: const Color(0xFF6C4EF5)),
            SizedBox(width: 4 * uiScale),
            Text(
              'AI Generated',
              style: TextStyle(fontSize: 10.5 * uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF6C4EF5)),
            ),
          ],
        ),
        SizedBox(height: 14 * uiScale),
        SizedBox(
          height: 58 * uiScale,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: weekPlan.length,
            separatorBuilder: (_, __) => SizedBox(width: 8 * uiScale),
            itemBuilder: (context, i) {
              final selected = i == selectedDay;
              final d = weekPlan[i];
              return _Pressable(
                onTap: () => onDaySelected(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  width: 62 * uiScale,
                  padding: EdgeInsets.symmetric(vertical: 8 * uiScale),
                  decoration: BoxDecoration(
                    gradient: selected ? const LinearGradient(colors: [Color(0xFF6C4EF5), Color(0xFF8467F8)]) : null,
                    color: selected ? null : Colors.white.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(14),
                    border: selected ? null : Border.all(color: const Color(0xFFE3DDF5)),
                    boxShadow: selected
                        ? [BoxShadow(color: const Color(0xFF6C4EF5).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        d.dayLabel,
                        style: TextStyle(
                          fontSize: 12 * uiScale,
                          fontWeight: FontWeight.w800,
                          color: selected ? Colors.white : const Color(0xFF1B1B2E),
                        ),
                      ),
                      SizedBox(height: 2 * uiScale),
                      Text(
                        d.dayNumber,
                        style: TextStyle(
                          fontSize: 9.5 * uiScale,
                          color: selected ? Colors.white.withOpacity(0.9) : const Color(0xFF6B6B7B),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 14 * uiScale),
        Column(
          children: List.generate(day.meals.length, (i) {
            final meal = day.meals[i];
            return TweenAnimationBuilder<double>(
              key: ValueKey('${day.dayLabel}-${meal.type}'),
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 350 + i * 90),
              curve: Curves.easeOutCubic,
              builder: (context, val, child) => Opacity(
                opacity: val,
                child: Transform.translate(offset: Offset(0, (1 - val) * 10), child: child),
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: i == day.meals.length - 1 ? 0 : 12 * uiScale),
                child: _MealRow(uiScale: uiScale, meal: meal),
              ),
            );
          }),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 14 * uiScale),
          child: Divider(height: 1, color: const Color(0xFFE1DAF2)),
        ),
        Row(
          children: [
            Expanded(
              child: _TotalStat(
                uiScale: uiScale,
                icon: Icons.local_fire_department_rounded,
                iconColor: const Color(0xFF6C4EF5),
                label: 'Total Calories',
                value: '${day.totalCalories} kcal',
                valueColor: const Color(0xFF6C4EF5),
              ),
            ),
            Expanded(
              child: _TotalStat(
                uiScale: uiScale,
                icon: Icons.eco_rounded,
                iconColor: const Color(0xFF1E8A4C),
                label: 'Protein',
                value: '${day.proteinG}g',
                valueColor: const Color(0xFF1E8A4C),
              ),
            ),
            Expanded(
              child: _TotalStat(
                uiScale: uiScale,
                icon: Icons.grain_rounded,
                iconColor: const Color(0xFFE0862E),
                label: 'Fiber',
                value: '${day.fiberG}g',
                valueColor: const Color(0xFFE0862E),
              ),
            ),
            Expanded(
              child: _TotalStat(
                uiScale: uiScale,
                icon: Icons.water_drop_rounded,
                iconColor: const Color(0xFF3B82F6),
                label: 'Water',
                value: '${day.waterGlasses} glasses',
                valueColor: const Color(0xFF3B82F6),
              ),
            ),
          ],
        ),
        SizedBox(height: 14 * uiScale),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(14 * uiScale),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE7FA),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30 * uiScale,
                height: 30 * uiScale,
                decoration: const BoxDecoration(color: Color(0xFFDCD0F5), shape: BoxShape.circle),
                child: Icon(Icons.lightbulb_rounded, size: 15 * uiScale, color: const Color(0xFF6C4EF5)),
              ),
              SizedBox(width: 10 * uiScale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This plan is tailored for your goal: Weight Loss',
                      style: TextStyle(fontSize: 11.5 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E)),
                    ),
                    SizedBox(height: 2 * uiScale),
                    Text(
                      'You can edit or regenerate anytime.',
                      style: TextStyle(fontSize: 10.5 * uiScale, color: const Color(0xFF6B6B7B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({required this.uiScale, required this.meal});
  final double uiScale;
  final MealEntry meal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40 * uiScale,
          height: 40 * uiScale,
          decoration: BoxDecoration(color: meal.iconBg, shape: BoxShape.circle),
          child: Icon(meal.icon, size: 18 * uiScale, color: meal.iconColor),
        ),
        SizedBox(width: 12 * uiScale),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meal.type,
                style: TextStyle(fontSize: 13 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E)),
              ),
              SizedBox(height: 2 * uiScale),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      meal.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11 * uiScale, color: const Color(0xFF6B6B7B)),
                    ),
                  ),
                  if (meal.isVegetarian) ...[
                    SizedBox(width: 4 * uiScale),
                    Icon(Icons.eco_rounded, size: 11 * uiScale, color: const Color(0xFF1E8A4C)),
                  ],
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10 * uiScale, vertical: 6 * uiScale),
          decoration: BoxDecoration(color: meal.pillBg, borderRadius: BorderRadius.circular(12)),
          child: Text(
            '${meal.kcal} kcal',
            style: TextStyle(fontSize: 10.5 * uiScale, fontWeight: FontWeight.w800, color: meal.pillColor),
          ),
        ),
      ],
    );
  }
}

class _TotalStat extends StatelessWidget {
  const _TotalStat({
    required this.uiScale,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });
  final double uiScale;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14 * uiScale, color: iconColor),
            SizedBox(width: 4 * uiScale),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 9.5 * uiScale, color: const Color(0xFF6B6B7B)),
              ),
            ),
          ],
        ),
        SizedBox(height: 3 * uiScale),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11.5 * uiScale, fontWeight: FontWeight.w800, color: valueColor),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom action bar — Export PDF / Add to Calendar / Regenerate
// ---------------------------------------------------------------------------
class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.uiScale,
    this.onExportPdf,
    this.onAddToCalendar,
    this.onRegenerate,
  });
  final double uiScale;
  final VoidCallback? onExportPdf;
  final VoidCallback? onAddToCalendar;
  final VoidCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(18 * uiScale, 10 * uiScale, 18 * uiScale, 14 * uiScale),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        border: const Border(top: BorderSide(color: Color(0xFFEDEAF7))),
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 340;
            final exportBtn = _OutlinedActionButton(
              uiScale: uiScale,
              icon: Icons.description_rounded,
              label: 'Export PDF',
              onTap: onExportPdf,
            );
            final calendarBtn = _OutlinedActionButton(
              uiScale: uiScale,
              icon: Icons.calendar_today_rounded,
              label: 'Add to Calendar',
              onTap: onAddToCalendar,
            );
            final regenerateBtn = _FilledActionButton(
              uiScale: uiScale,
              icon: Icons.refresh_rounded,
              label: 'Regenerate',
              onTap: onRegenerate,
            );
            if (narrow) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: exportBtn),
                      SizedBox(width: 10 * uiScale),
                      Expanded(child: calendarBtn),
                    ],
                  ),
                  SizedBox(height: 10 * uiScale),
                  regenerateBtn,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: exportBtn),
                SizedBox(width: 10 * uiScale),
                Expanded(child: calendarBtn),
                SizedBox(width: 10 * uiScale),
                Expanded(child: regenerateBtn),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OutlinedActionButton extends StatelessWidget {
  const _OutlinedActionButton({required this.uiScale, required this.icon, required this.label, this.onTap});
  final double uiScale;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 13 * uiScale),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF6C4EF5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15 * uiScale, color: const Color(0xFF6C4EF5)),
            SizedBox(width: 6 * uiScale),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF6C4EF5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilledActionButton extends StatelessWidget {
  const _FilledActionButton({required this.uiScale, required this.icon, required this.label, this.onTap});
  final double uiScale;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 13 * uiScale),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF6C4EF5), Color(0xFF4A2FD1)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFF6C4EF5).withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15 * uiScale, color: Colors.white),
            SizedBox(width: 6 * uiScale),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5 * uiScale, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
