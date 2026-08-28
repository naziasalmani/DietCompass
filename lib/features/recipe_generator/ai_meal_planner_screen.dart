import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/model/meal_plan_model.dart';
import '../../core/services/meal_plan_service.dart';
import 'pdf_service.dart';
import 'calendar_service.dart';
import 'recipe_detail_screen.dart';

/// DietCompass — AI Personalized Multi-Day Meal Planner Screen
/// -----------------------------------------------------------------------
/// Generates real dynamic meal plans (1, 3, 7, 30 days) adhering to user
/// preferences, pantry availability, calorie targets, and dietary safety.
class AiMealPlannerScreen extends StatefulWidget {
  const AiMealPlannerScreen({
    super.key,
    this.initialPlan,
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
    this.onBack,
    this.onCalendarTap,
    this.onExportPdf,
    this.onAddToCalendar,
    this.onRegenerate,
  });

  final MealPlanResponse? initialPlan;
  final List<String> goalOptions;
  final List<String> calorieOptions;
  final List<String> mealTypeOptions;
  final List<String> dietOptions;
  final List<String> allergyOptions;
  final List<String> budgetOptions;

  final VoidCallback? onBack;
  final VoidCallback? onCalendarTap;
  final VoidCallback? onExportPdf;
  final VoidCallback? onAddToCalendar;
  final VoidCallback? onRegenerate;

  @override
  State<AiMealPlannerScreen> createState() => _AiMealPlannerScreenState();
}

class _AiMealPlannerScreenState extends State<AiMealPlannerScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;

  int _durationIndex = 2;
  static const _durations = ['1 Day', '3 Days', '7 Days', '30 Days'];
  static const _durationDaysMap = [1, 3, 7, 30];

  late String _goal;
  late String _calories;
  late String _mealType;
  late String _diet;
  late String _allergy;
  late String _budget;
  bool _usePantry = true;
  int _selectedDay = 0;

  MealPlanResponse? _plan;
  bool _isLoading = false;
  bool _calendarAdded = false;

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

    if (widget.initialPlan != null) {
      _plan = widget.initialPlan;
      _syncDurationWithPlan(_plan!);
    } else {
      _fetchMealPlan();
    }
  }

  void _syncDurationWithPlan(MealPlanResponse p) {
    if (p.durationDays == 1) _durationIndex = 0;
    else if (p.durationDays == 3) _durationIndex = 1;
    else if (p.durationDays == 7) _durationIndex = 2;
    else if (p.durationDays == 30) _durationIndex = 3;
  }

  Future<void> _fetchMealPlan() async {
    setState(() {
      _isLoading = true;
      _calendarAdded = false;
    });

    final targetDays = _durationDaysMap[_durationIndex];
    final calNum = int.tryParse(_calories.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1800;

    final plan = await MealPlanService.instance.generateMealPlan(
      durationDays: targetDays,
      goal: _goal,
      calories: calNum,
      mealType: _mealType,
      diet: _diet,
      allergy: _allergy,
      budget: _budget,
      usePantry: _usePantry,
    );

    if (mounted) {
      setState(() {
        _plan = plan;
        _isLoading = false;
        _selectedDay = 0;
      });
    }
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

  Future<void> _handleExportPdf() async {
    if (_plan != null) {
      await PdfService.exportMealPlan(_plan);
      widget.onExportPdf?.call();
    }
  }

  Future<void> _handleAddToCalendar() async {
    if (_plan == null) return;

    final result = await CalendarService.addMealPlan(_plan);
    widget.onAddToCalendar?.call();

    if (mounted) {
      setState(() {
        if (result.isSuccess) {
          _calendarAdded = true;
        }
      });

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                result.isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                color: result.isSuccess ? const Color(0xFF1E8A4C) : const Color(0xFFE0525C),
              ),
              const SizedBox(width: 8),
              Text(
                result.isSuccess ? 'Added to Calendar' : 'Calendar Sync',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: Text(result.message),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C4EF5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }

  void _openMealDetail(MealPlanMeal meal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recipe: meal.toRecipe()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 390).clamp(0.85, 1.25);
    final days = _plan?.days ?? [];
    final currentDay = days.isNotEmpty ? days[_selectedDay.clamp(0, days.length - 1)] : null;

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
                          child: _TopHeader(
                            uiScale: scale,
                            onBack: widget.onBack,
                            onCalendarTap: widget.onCalendarTap ?? _handleAddToCalendar,
                          ),
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
                              onSelected: (i) {
                                if (_durationIndex != i) {
                                  setState(() => _durationIndex = i);
                                  _fetchMealPlan();
                                }
                              },
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
                              onGoalChanged: (v) {
                                setState(() => _goal = v);
                                _fetchMealPlan();
                              },
                              calories: _calories,
                              calorieOptions: widget.calorieOptions,
                              onCaloriesChanged: (v) {
                                setState(() => _calories = v);
                                _fetchMealPlan();
                              },
                              mealType: _mealType,
                              mealTypeOptions: widget.mealTypeOptions,
                              onMealTypeChanged: (v) {
                                setState(() => _mealType = v);
                                _fetchMealPlan();
                              },
                              diet: _diet,
                              dietOptions: widget.dietOptions,
                              onDietChanged: (v) {
                                setState(() => _diet = v);
                                _fetchMealPlan();
                              },
                              allergy: _allergy,
                              allergyOptions: widget.allergyOptions,
                              onAllergyChanged: (v) {
                                setState(() => _allergy = v);
                                _fetchMealPlan();
                              },
                              budget: _budget,
                              budgetOptions: widget.budgetOptions,
                              onBudgetChanged: (v) {
                                setState(() => _budget = v);
                                _fetchMealPlan();
                              },
                              usePantry: _usePantry,
                              onUsePantryChanged: (v) {
                                setState(() => _usePantry = v);
                                _fetchMealPlan();
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16 * scale),

                      if (_isLoading)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 40 * scale),
                          child: Center(
                            child: Column(
                              children: [
                                const CircularProgressIndicator(color: Color(0xFF6C4EF5)),
                                SizedBox(height: 14 * scale),
                                Text(
                                  'AI is crafting your ${_durations[_durationIndex]} meal plan...',
                                  style: TextStyle(
                                    fontSize: 13 * scale,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF6C4EF5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (currentDay != null)
                        FadeTransition(
                          opacity: _fade(0.2, 0.5),
                          child: SlideTransition(
                            position: _slide(0.2, 0.54),
                            child: _Glass(
                              uiScale: scale,
                              child: _WeeklyPlanPreviewSection(
                                uiScale: scale,
                                plan: _plan!,
                                selectedDay: _selectedDay,
                                onDaySelected: (i) => setState(() => _selectedDay = i),
                                day: currentDay,
                                onMealTap: _openMealDetail,
                              ),
                            ),
                          ),
                        )
                      else
                        Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 30 * scale),
                            child: Text(
                              'No meal plan available. Tap Regenerate to create one.',
                              style: TextStyle(fontSize: 12.5 * scale, color: const Color(0xFF6B6B7B)),
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
                    calendarAdded: _calendarAdded,
                    isLoading: _isLoading,
                    onExportPdf: _handleExportPdf,
                    onAddToCalendar: _handleAddToCalendar,
                    onRegenerate: () {
                      _fetchMealPlan();
                      widget.onRegenerate?.call();
                    },
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
                      'AI Meal Planner',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16.5 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4 * uiScale),
              Text(
                'Personalized nutrition plan crafted for your goals',
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
                  padding: EdgeInsets.symmetric(horizontal: 12 * uiScale, vertical: 11 * uiScale),
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
// 3. Your Plan (Preview)
// ---------------------------------------------------------------------------
class _WeeklyPlanPreviewSection extends StatelessWidget {
  const _WeeklyPlanPreviewSection({
    required this.uiScale,
    required this.plan,
    required this.selectedDay,
    required this.onDaySelected,
    required this.day,
    required this.onMealTap,
  });
  final double uiScale;
  final MealPlanResponse plan;
  final int selectedDay;
  final ValueChanged<int> onDaySelected;
  final MealPlanDay day;
  final ValueChanged<MealPlanMeal> onMealTap;

  @override
  Widget build(BuildContext context) {
    final weekPlan = plan.days;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '3. Your ${plan.durationDays}-Day Plan',
                style: TextStyle(fontSize: 14.5 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF6C4EF5)),
              ),
            ),
            Icon(Icons.auto_awesome, size: 12 * uiScale, color: const Color(0xFF6C4EF5)),
            SizedBox(width: 4 * uiScale),
            Text(
              plan.geminiPowered ? 'Gemini AI Orchestrated' : 'Personalized AI Plan',
              style: TextStyle(fontSize: 10.5 * uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF6C4EF5)),
            ),
          ],
        ),
        SizedBox(height: 14 * uiScale),

        // Dynamic Day Tabs (Scrollable for 1, 3, 7, 30 days)
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
                  width: 66 * uiScale,
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

        // Meals List
        Column(
          children: List.generate(day.meals.length, (i) {
            final meal = day.meals[i];
            return TweenAnimationBuilder<double>(
              key: ValueKey('${day.dayNumber}-${meal.type}-${meal.title}'),
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 350 + i * 90),
              curve: Curves.easeOutCubic,
              builder: (context, val, child) => Opacity(
                opacity: val,
                child: Transform.translate(offset: Offset(0, (1 - val) * 10), child: child),
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: i == day.meals.length - 1 ? 0 : 12 * uiScale),
                child: _MealRow(
                  uiScale: uiScale,
                  meal: meal,
                  onTap: () => onMealTap(meal),
                ),
              ),
            );
          }),
        ),

        Padding(
          padding: EdgeInsets.symmetric(vertical: 14 * uiScale),
          child: const Divider(height: 1, color: Color(0xFFE1DAF2)),
        ),

        // Daily Totals Row
        Row(
          children: [
            Expanded(
              child: _TotalStat(
                uiScale: uiScale,
                icon: Icons.local_fire_department_rounded,
                iconColor: const Color(0xFF6C4EF5),
                label: 'Daily Calories',
                value: '${day.dailyCalories} kcal',
                valueColor: const Color(0xFF6C4EF5),
              ),
            ),
            Expanded(
              child: _TotalStat(
                uiScale: uiScale,
                icon: Icons.eco_rounded,
                iconColor: const Color(0xFF1E8A4C),
                label: 'Protein',
                value: '${day.dailyProtein}g',
                valueColor: const Color(0xFF1E8A4C),
              ),
            ),
            Expanded(
              child: _TotalStat(
                uiScale: uiScale,
                icon: Icons.grain_rounded,
                iconColor: const Color(0xFFE0862E),
                label: 'Fiber',
                value: '${day.dailyFiber}g',
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

        // Dynamic AI Summary Card
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
                child: Icon(Icons.auto_awesome, size: 15 * uiScale, color: const Color(0xFF6C4EF5)),
              ),
              SizedBox(width: 10 * uiScale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Meal Plan Summary',
                      style: TextStyle(fontSize: 11.5 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E)),
                    ),
                    SizedBox(height: 3 * uiScale),
                    Text(
                      plan.summary,
                      style: TextStyle(fontSize: 10.5 * uiScale, height: 1.35, color: const Color(0xFF4A4A5A)),
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
  const _MealRow({required this.uiScale, required this.meal, this.onTap});
  final double uiScale;
  final MealPlanMeal meal;
  final VoidCallback? onTap;

  IconData _getTypeIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('breakfast')) return Icons.free_breakfast_rounded;
    if (t.contains('lunch')) return Icons.ramen_dining_rounded;
    if (t.contains('snack')) return Icons.apple_rounded;
    return Icons.dinner_dining_rounded;
  }

  Color _getTypeColor(String type) {
    final t = type.toLowerCase();
    if (t.contains('breakfast')) return const Color(0xFF6C4EF5);
    if (t.contains('lunch')) return const Color(0xFF1E8A4C);
    if (t.contains('snack')) return const Color(0xFFE0862E);
    return const Color(0xFF7C5CFC);
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor(meal.type);

    return _Pressable(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8 * uiScale),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDEAF7)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 48 * uiScale,
                height: 48 * uiScale,
                child: _buildMealImage(meal.image, uiScale),
              ),
            ),
            SizedBox(width: 10 * uiScale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6 * uiScale, vertical: 2 * uiScale),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          meal.type,
                          style: TextStyle(
                            fontSize: 9 * uiScale,
                            fontWeight: FontWeight.w800,
                            color: typeColor,
                          ),
                        ),
                      ),
                      if (meal.isVegetarian) ...[
                        SizedBox(width: 4 * uiScale),
                        Icon(Icons.eco_rounded, size: 11 * uiScale, color: const Color(0xFF1E8A4C)),
                      ],
                    ],
                  ),
                  SizedBox(height: 3 * uiScale),
                  Text(
                    meal.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12 * uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF1B1B2E)),
                  ),
                  SizedBox(height: 2 * uiScale),
                  Text(
                    '${meal.proteinGrams}g Protein • ${meal.fiberGrams}g Fiber',
                    style: TextStyle(fontSize: 9.5 * uiScale, color: const Color(0xFF6B6B7B)),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8 * uiScale, vertical: 5 * uiScale),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE7FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${meal.calories} kcal',
                style: TextStyle(fontSize: 10 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF6C4EF5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealImage(String asset, double uiScale) {
    if (asset.isEmpty) {
      return _imageFallback(uiScale);
    }
    if (asset.startsWith('http://') || asset.startsWith('https://')) {
      return Image.network(
        asset,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imageFallback(uiScale),
      );
    }
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _imageFallback(uiScale),
    );
  }

  Widget _imageFallback(double uiScale) => Container(
        color: const Color(0xFFEDE7FA),
        alignment: Alignment.center,
        child: Icon(_getTypeIcon(meal.type), size: 20 * uiScale, color: const Color(0xFF6C4EF5)),
      );
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
    this.calendarAdded = false,
    this.isLoading = false,
    this.onExportPdf,
    this.onAddToCalendar,
    this.onRegenerate,
  });
  final double uiScale;
  final bool calendarAdded;
  final bool isLoading;
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
              icon: calendarAdded ? Icons.check_circle_rounded : Icons.calendar_today_rounded,
              iconColor: calendarAdded ? const Color(0xFF1E8A4C) : const Color(0xFF6C4EF5),
              textColor: calendarAdded ? const Color(0xFF1E8A4C) : const Color(0xFF6C4EF5),
              borderColor: calendarAdded ? const Color(0xFF1E8A4C) : const Color(0xFF6C4EF5),
              label: calendarAdded ? 'Added' : 'Calendar',
              onTap: onAddToCalendar,
            );
            final regenerateBtn = _FilledActionButton(
              uiScale: uiScale,
              icon: isLoading ? Icons.hourglass_top_rounded : Icons.refresh_rounded,
              label: isLoading ? 'Generating...' : 'Regenerate',
              onTap: isLoading ? null : onRegenerate,
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
                SizedBox(width: 8 * uiScale),
                Expanded(child: calendarBtn),
                SizedBox(width: 8 * uiScale),
                Expanded(flex: 1, child: regenerateBtn),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OutlinedActionButton extends StatelessWidget {
  const _OutlinedActionButton({
    required this.uiScale,
    required this.icon,
    required this.label,
    this.iconColor = const Color(0xFF6C4EF5),
    this.textColor = const Color(0xFF6C4EF5),
    this.borderColor = const Color(0xFF6C4EF5),
    this.onTap,
  });
  final double uiScale;
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color textColor;
  final Color borderColor;
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
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15 * uiScale, color: iconColor),
            SizedBox(width: 4 * uiScale),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11 * uiScale, fontWeight: FontWeight.w800, color: textColor),
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
