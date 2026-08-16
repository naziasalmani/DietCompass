import 'package:flutter/material.dart';
import 'recipe_generator_screen.dart';
/// DietCompass — Recipe Detail Screen
/// -----------------------------------------------------------------------
/// You mentioned you'll add the recipe photos separately — this screen
/// points at asset paths like 'assets/images/recipe_banana_oats_1.png'
/// that don't need to exist yet. Until you drop real photos into
/// assets/images/ (and declare them in pubspec.yaml), each falls back to
/// a soft gradient placeholder with a bowl icon instead of crashing.
///
/// Everything else (title, tags, stats, nutrition facts, ingredients,
/// numbered instructions) is driven by the [Recipe] model below, so this
/// screen works for any recipe your Recipe Generator returns.
class IngredientItem {
  const IngredientItem({required this.amount, required this.name});
  final String amount;
  final String name;
}

class NutritionFact {
  const NutritionFact({required this.icon, required this.color, required this.label, required this.value});
  final IconData icon;
  final Color color;
  final String label;
  final String value;
}

class Recipe {
  const Recipe({
    required this.images,
    required this.title,
    required this.tags,
    required this.description,
    required this.prepTime,
    required this.calories,
    required this.protein,
    required this.difficulty,
    required this.nutritionFacts,
    required this.ingredients,
    required this.serves,
    required this.instructions,
  });

  final List<String> images;
  final String title;
  final List<String> tags;
  final String description;
  final String prepTime;
  final String calories;
  final String protein;
  final String difficulty;
  final List<NutritionFact> nutritionFacts;
  final List<IngredientItem> ingredients;
  final int serves;
  final List<String> instructions;
}

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({
    super.key,
    this.recipe = const Recipe(
      images: [
        'assets/images/recipe_banana_oats_power_bowl.jpeg',
        'assets/images/recipe_banana_oats_2.png',
        'assets/images/recipe_banana_oats_3.png',
      ],
      title: 'Banana Oats Power Bowl',
      tags: ['Healthy', 'Quick', 'Delicious'],
      description: 'A nutritious bowl packed with fiber, protein and '
          'natural energy to kickstart your day!',
      prepTime: '15 min',
      calories: '320 kcal',
      protein: '12g',
      difficulty: 'Easy',
      nutritionFacts: [
        NutritionFact(icon: Icons.local_fire_department, color: Color(0xFFE0862E), label: 'Calories', value: '320\nkcal'),
        NutritionFact(icon: Icons.circle, color: Color(0xFF6C4EF5), label: 'Carbs', value: '50g'),
        NutritionFact(icon: Icons.eco, color: Color(0xFF1E8A4C), label: 'Protein', value: '12g'),
        NutritionFact(icon: Icons.opacity, color: Color(0xFFE0B32E), label: 'Fat', value: '10g'),
        NutritionFact(icon: Icons.grass, color: Color(0xFF1E8A4C), label: 'Fiber', value: '8g'),
        NutritionFact(icon: Icons.icecream, color: Color(0xFFE0525C), label: 'Sugar', value: '12g'),
        NutritionFact(icon: Icons.shield_outlined, color: Color(0xFF3B82F6), label: 'Sodium', value: '120mg'),
      ],
      ingredients: [
        IngredientItem(amount: '1/2 cup', name: 'Oats'),
        IngredientItem(amount: '1', name: 'Banana (sliced)'),
        IngredientItem(amount: '1/2 cup', name: 'Milk (or any milk)'),
        IngredientItem(amount: '1 tbsp', name: 'Chia Seeds'),
        IngredientItem(amount: '1 tbsp', name: 'Almonds (chopped)'),
        IngredientItem(amount: '1 tsp', name: 'Honey (optional)'),
        IngredientItem(amount: 'A pinch', name: 'of Cinnamon'),
        IngredientItem(amount: 'A pinch', name: 'of Salt'),
      ],
      serves: 1,
      instructions: [
        'In a saucepan, bring milk to a gentle boil.',
        'Add oats and cook for 5–7 minutes on low heat, stirring occasionally.',
        'Remove from heat and let it cool slightly.',
        'Top with banana slices, chia seeds, almonds and a pinch of cinnamon.',
        'Drizzle honey if desired and enjoy your healthy power bowl!',
      ],
    ),
    this.onBack,
    this.onFavoriteTap,
    this.onShareTap,
    this.onViewAllNutrition,
    this.onSaveForLater,
    this.onAddToMealPlan,
  });

  final Recipe recipe;
  final VoidCallback? onBack;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onViewAllNutrition;
  final VoidCallback? onSaveForLater;
  final VoidCallback? onAddToMealPlan;

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  final _pageController = PageController();
  int _page = 0;
  bool _favorited = false;
  bool _savedForLater = false;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _pageController.dispose();
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
    final r = widget.recipe;

    return Scaffold(
      backgroundColor: const Color(0xFFF1EDFB),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                children: [
                  FadeTransition(
                    opacity: _fade(0.0, 0.4),
                    child: _HeroCarousel(
                      uiScale: scale,
                      images: r.images,
                      calories: r.calories,
                      page: _page,
                      controller: _pageController,
                      favorited: _favorited,
                      onPageChanged: (i) => setState(() => _page = i),
                      onBack: () {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const RecipeGeneratorScreen(),
    ),
  );
},
                      onFavoriteTap: () {
                        setState(() => _favorited = !_favorited);
                        widget.onFavoriteTap?.call();
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(18 * scale, 14 * scale, 18 * scale, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeTransition(
                          opacity: _fade(0.08, 0.42),
                          child: SlideTransition(
                            position: _slide(0.08, 0.44),
                            child: _TitleRow(uiScale: scale, title: r.title, tags: r.tags, onShareTap: widget.onShareTap),
                          ),
                        ),
                        SizedBox(height: 8 * scale),
                        FadeTransition(
                          opacity: _fade(0.12, 0.46),
                          child: Text(r.description, style: TextStyle(fontSize: 12.5 * scale, height: 1.4, color: const Color(0xFF3B3B4F))),
                        ),
                        SizedBox(height: 16 * scale),
                        FadeTransition(
                          opacity: _fade(0.16, 0.5),
                          child: SlideTransition(
                            position: _slide(0.16, 0.52),
                            child: _QuickStatsRow(uiScale: scale, prepTime: r.prepTime, calories: r.calories, protein: r.protein, difficulty: r.difficulty),
                          ),
                        ),
                        SizedBox(height: 20 * scale),
                        if (r.nutritionFacts.isNotEmpty) ...[
                          FadeTransition(
                            opacity: _fade(0.22, 0.54),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Nutrition Facts', style: TextStyle(fontSize: 15.5 * scale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
                                      Text('Per Serving', style: TextStyle(fontSize: 10.5 * scale, color: const Color(0xFF6B6B7B))),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: widget.onViewAllNutrition,
                                  child: Row(
                                    children: [
                                      Text('View All', style: TextStyle(fontSize: 12 * scale, fontWeight: FontWeight.w700, color: const Color(0xFF6C4EF5))),
                                      Icon(Icons.chevron_right, size: 15 * scale, color: const Color(0xFF6C4EF5)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10 * scale),
                          FadeTransition(
                            opacity: _fade(0.26, 0.58),
                            child: SlideTransition(
                              position: _slide(0.26, 0.6),
                              child: _NutritionFactsCard(uiScale: scale, facts: r.nutritionFacts),
                            ),
                          ),
                          SizedBox(height: 20 * scale),
                        ],
                        FadeTransition(
                          opacity: _fade(0.32, 0.62),
                          child: Row(
                            children: [
                              Expanded(child: Text('Ingredients', style: TextStyle(fontSize: 15.5 * scale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E)))),
                              Text('Serves ${r.serves}', style: TextStyle(fontSize: 12 * scale, fontWeight: FontWeight.w700, color: const Color(0xFF6C4EF5))),
                            ],
                          ),
                        ),
                        SizedBox(height: 10 * scale),
                        FadeTransition(
                          opacity: _fade(0.34, 0.66),
                          child: SlideTransition(
                            position: _slide(0.34, 0.68),
                            child: _IngredientsCard(uiScale: scale, ingredients: r.ingredients),
                          ),
                        ),
                        SizedBox(height: 20 * scale),
                        FadeTransition(
                          opacity: _fade(0.4, 0.7),
                          child: Text('Instructions', style: TextStyle(fontSize: 15.5 * scale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
                        ),
                        SizedBox(height: 10 * scale),
                        FadeTransition(
                          opacity: _fade(0.42, 0.75),
                          child: SlideTransition(
                            position: _slide(0.42, 0.78),
                            child: _InstructionsCard(uiScale: scale, steps: r.instructions),
                          ),
                        ),
                        SizedBox(height: 20 * scale),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            FadeTransition(
              opacity: _fade(0.55, 0.9),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(18 * scale, 10 * scale, 18 * scale, 10 * scale),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SaveForLaterButton(
                          uiScale: scale,
                          saved: _savedForLater,
                          onTap: () {
                            setState(() => _savedForLater = !_savedForLater);
                            widget.onSaveForLater?.call();
                          },
                        ),
                      ),
                      SizedBox(width: 12 * scale),
                      Expanded(
                        child: _AddToMealPlanButton(uiScale: scale, onTap: widget.onAddToMealPlan),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero carousel
// ---------------------------------------------------------------------------
class _HeroCarousel extends StatelessWidget {
  const _HeroCarousel({
    required this.uiScale,
    required this.images,
    required this.calories,
    required this.page,
    required this.controller,
    required this.favorited,
    required this.onPageChanged,
    this.onBack,
    this.onFavoriteTap,
  });

  final double uiScale;
  final List<String> images;
  final String calories;
  final int page;
  final PageController controller;
  final bool favorited;
  final ValueChanged<int> onPageChanged;
  final VoidCallback? onBack;
  final VoidCallback? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 260 * uiScale,
          width: double.infinity,
          child: PageView.builder(
            controller: controller,
            onPageChanged: onPageChanged,
            itemCount: images.isEmpty ? 1 : images.length,
            itemBuilder: (context, i) {
              final asset = images.isEmpty ? null : images[i];
              return asset == null
                  ? const _ImagePlaceholder()
                  : Image.asset(
                      asset,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const _ImagePlaceholder(),
                    );
            },
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16 * uiScale,
          child: _CircleButton(uiScale: uiScale, icon: Icons.arrow_back, onTap: onBack),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          right: 16 * uiScale,
          child: _CircleButton(
            uiScale: uiScale,
            icon: favorited ? Icons.favorite : Icons.favorite_border,
            iconColor: favorited ? const Color(0xFFE0525C) : const Color(0xFF6C4EF5),
            onTap: onFavoriteTap,
          ),
        ),
        Positioned(
          right: 16 * uiScale,
          bottom: 22 * uiScale,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12 * uiScale, vertical: 8 * uiScale),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_fire_department, size: 14 * uiScale, color: const Color(0xFFE0862E)),
                SizedBox(width: 5 * uiScale),
                Text(calories, style: TextStyle(fontSize: 12 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
              ],
            ),
          ),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 8 * uiScale,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (i) {
                final active = i == page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.symmetric(horizontal: 3 * uiScale),
                  width: active ? 16 * uiScale : 6 * uiScale,
                  height: 6 * uiScale,
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFF6C4EF5) : Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFEDE7FA), Color(0xFFE4F5E9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: const Center(
        child: Icon(Icons.ramen_dining_outlined, size: 56, color: Color(0xFFB0ACC2)),
      ),
    );
  }
}

class _CircleButton extends StatefulWidget {
  const _CircleButton({required this.uiScale, required this.icon, this.iconColor = const Color(0xFF1B1B2E), this.onTap});
  final double uiScale;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  State<_CircleButton> createState() => _CircleButtonState();
}

class _CircleButtonState extends State<_CircleButton> {
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
          width: 42 * widget.uiScale,
          height: 42 * widget.uiScale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Icon(widget.icon, size: 18 * widget.uiScale, color: widget.iconColor),
        ),
      ),
    );
  }
}

class AppleCinnamonOatmealScreen extends StatelessWidget {
  const AppleCinnamonOatmealScreen({super.key});

  static const recipe = Recipe(
    images: [
      'assets/images/recipe_apple_cinnamon_1.png',
      'assets/images/recipe_apple_cinnamon_2.png',
      'assets/images/recipe_apple_cinnamon_3.png',
    ],
    title: 'Apple Cinnamon Oatmeal',
    tags: ['Warm', 'Comforting', 'Wholesome'],
    description: 'Warm, comforting oats with apple, cinnamon and nuts. '
        'A perfect way to start your day.',
    prepTime: '12 min',
    calories: '310 kcal',
    protein: '9g',
    difficulty: 'Easy',
    nutritionFacts: [], // none in this reference -> section hides itself
    ingredients: [
      IngredientItem(amount: '1/2 cup', name: 'Oats'),
      IngredientItem(amount: '1 cup', name: 'Milk (or any milk)'),
      IngredientItem(amount: '1/2', name: 'Apple (chopped)'),
      IngredientItem(amount: '1 tsp', name: 'Honey (optional)'),
      IngredientItem(amount: '1/4 tsp', name: 'Cinnamon Powder'),
      IngredientItem(amount: '1 tbsp', name: 'Chopped Nuts'),
      IngredientItem(amount: '1/4 tsp', name: 'Vanilla Extract'),
      IngredientItem(amount: 'A pinch', name: 'of Salt'),
    ],
    serves: 1,
    instructions: [
      'In a saucepan, bring milk to a gentle boil.',
      'Add oats and cook for 5-7 minutes on low heat, stirring occasionally.',
      'Add chopped apple, cinnamon, and salt. Cook for another 2 minutes.',
      'Remove from heat and stir in honey and vanilla extract.',
      'Top with chopped nuts and serve warm!',
    ],
  );

  @override
  Widget build(BuildContext context) {
    return const RecipeDetailScreen(recipe: recipe);
  }
}


// ---------------------------------------------------------------------------
// Title row
// ---------------------------------------------------------------------------
class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.uiScale, required this.title, required this.tags, this.onShareTap});
  final double uiScale;
  final String title;
  final List<String> tags;
  final VoidCallback? onShareTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title, style: TextStyle(fontSize: 20 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
                  ),
                  Icon(Icons.eco, size: 17 * uiScale, color: const Color(0xFF1E8A4C)),
                ],
              ),
              SizedBox(height: 3 * uiScale),
              Text(
                tags.join(' • '),
                style: TextStyle(fontSize: 12 * uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF6C4EF5)),
              ),
            ],
          ),
        ),
        SizedBox(width: 10 * uiScale),
        _CircleButton(uiScale: uiScale, icon: Icons.share_outlined, onTap: onShareTap),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Quick stats
// ---------------------------------------------------------------------------
class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({required this.uiScale, required this.prepTime, required this.calories, required this.protein, required this.difficulty});
  final double uiScale;
  final String prepTime;
  final String calories;
  final String protein;
  final String difficulty;

  @override
  Widget build(BuildContext context) {
    final stats = [
      (icon: Icons.access_time_rounded, color: const Color(0xFF6C4EF5), value: prepTime, label: 'Prep Time'),
      (icon: Icons.local_fire_department, color: const Color(0xFFE0862E), value: calories, label: 'Calories'),
      (icon: Icons.eco, color: const Color(0xFF1E8A4C), value: protein, label: 'Protein'),
      (icon: Icons.bar_chart_rounded, color: const Color(0xFF6C4EF5), value: difficulty, label: 'Difficulty'),
    ];

    return Row(
      children: List.generate(stats.length, (i) {
        final s = stats[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == stats.length - 1 ? 0 : 8 * uiScale),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12 * uiScale, horizontal: 6 * uiScale),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Icon(s.icon, size: 16 * uiScale, color: s.color),
                  SizedBox(height: 6 * uiScale),
                  Text(s.value, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
                  Text(s.label, style: TextStyle(fontSize: 9 * uiScale, color: const Color(0xFF6B6B7B))),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Nutrition facts
// ---------------------------------------------------------------------------
class _NutritionFactsCard extends StatelessWidget {
  const _NutritionFactsCard({required this.uiScale, required this.facts});
  final double uiScale;
  final List<NutritionFact> facts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14 * uiScale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 14 * uiScale),
        child: Row(
          children: facts.map((f) {
            return Padding(
              padding: EdgeInsets.only(right: 18 * uiScale),
              child: Column(
                children: [
                  Icon(f.icon, size: 16 * uiScale, color: f.color),
                  SizedBox(height: 6 * uiScale),
                  Text(f.label, style: TextStyle(fontSize: 10 * uiScale, color: const Color(0xFF6B6B7B))),
                  SizedBox(height: 2 * uiScale),
                  Text(f.value, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ingredients
// ---------------------------------------------------------------------------
class _IngredientsCard extends StatelessWidget {
  const _IngredientsCard({required this.uiScale, required this.ingredients});
  final double uiScale;
  final List<IngredientItem> ingredients;

  @override
  Widget build(BuildContext context) {
    final half = (ingredients.length / 2).ceil();
    final left = ingredients.sublist(0, half);
    final right = ingredients.sublist(half);

    return Container(
      padding: EdgeInsets.all(16 * uiScale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _IngredientColumn(uiScale: uiScale, items: left)),
          SizedBox(width: 10 * uiScale),
          Expanded(child: _IngredientColumn(uiScale: uiScale, items: right)),
        ],
      ),
    );
  }
}

class _IngredientColumn extends StatelessWidget {
  const _IngredientColumn({required this.uiScale, required this.items});
  final double uiScale;
  final List<IngredientItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: EdgeInsets.only(bottom: 10 * uiScale),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 5 * uiScale),
                child: Container(width: 4 * uiScale, height: 4 * uiScale, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF6C4EF5))),
              ),
              SizedBox(width: 8 * uiScale),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 11.5 * uiScale, color: const Color(0xFF3B3B4F), height: 1.3),
                    children: [
                      TextSpan(text: '${item.amount} ', style: TextStyle(fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
                      TextSpan(text: item.name),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Instructions
// ---------------------------------------------------------------------------
class _InstructionsCard extends StatelessWidget {
  const _InstructionsCard({required this.uiScale, required this.steps});
  final double uiScale;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16 * uiScale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            child: Icon(Icons.soup_kitchen_outlined, size: 44 * uiScale, color: const Color(0xFF6C4EF5).withValues(alpha: 0.18)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(steps.length, (i) {
              return Padding(
                padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 12 * uiScale),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22 * uiScale,
                      height: 22 * uiScale,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF6C4EF5)),
                      child: Center(
                        child: Text('${i + 1}', style: TextStyle(fontSize: 11 * uiScale, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    ),
                    SizedBox(width: 10 * uiScale),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 2 * uiScale),
                        child: Text(steps[i], style: TextStyle(fontSize: 12 * uiScale, height: 1.4, color: const Color(0xFF3B3B4F))),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom buttons
// ---------------------------------------------------------------------------
class _SaveForLaterButton extends StatefulWidget {
  const _SaveForLaterButton({required this.uiScale, required this.saved, this.onTap});
  final double uiScale;
  final bool saved;
  final VoidCallback? onTap;

  @override
  State<_SaveForLaterButton> createState() => _SaveForLaterButtonState();
}

class _SaveForLaterButtonState extends State<_SaveForLaterButton> {
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
          padding: EdgeInsets.symmetric(vertical: 14 * widget.uiScale),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF6C4EF5), width: 1.6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.saved ? Icons.alarm_on_rounded : Icons.alarm_outlined, size: 16 * widget.uiScale, color: const Color(0xFF6C4EF5)),
              SizedBox(width: 6 * widget.uiScale),
              Flexible(
                child: Text(
                  widget.saved ? 'Saved' : 'Save for Later',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5 * widget.uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF6C4EF5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddToMealPlanButton extends StatefulWidget {
  const _AddToMealPlanButton({required this.uiScale, this.onTap});
  final double uiScale;
  final VoidCallback? onTap;

  @override
  State<_AddToMealPlanButton> createState() => _AddToMealPlanButtonState();
}

class _AddToMealPlanButtonState extends State<_AddToMealPlanButton> {
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
          padding: EdgeInsets.symmetric(vertical: 14 * widget.uiScale),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(colors: [Color(0xFF6C4EF5), Color(0xFF7C5CFC)]),
            boxShadow: [BoxShadow(color: const Color(0xFF6C4EF5).withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 8))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.ramen_dining_outlined, size: 16 * widget.uiScale, color: Colors.white),
              SizedBox(width: 6 * widget.uiScale),
              Flexible(
                child: Text(
                  'Add to Meal Plan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5 * widget.uiScale, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
