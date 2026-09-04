import 'package:flutter/material.dart';
import 'package:diet_compass/core/theme/app_colors.dart';
import '../../core/services/recipe_history_service.dart';
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
    this.id,
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

  final dynamic id;
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
    required this.recipe,
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
    final isSaved = RecipeHistoryService.instance.isRecipeSaved(widget.recipe.id, widget.recipe.title);
    _favorited = isSaved;
    _savedForLater = isSaved;
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

    final colors = context.dcColors;
    return Scaffold(
      backgroundColor: colors.bg,
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
                        if (widget.onBack != null) {
                          widget.onBack!();
                        } else if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RecipeGeneratorScreen(),
                            ),
                          );
                        }
                      },

                      onFavoriteTap: () {
                        final nextState = !_favorited;
                        setState(() {
                          _favorited = nextState;
                          _savedForLater = nextState;
                        });
                        final card = RecipeCardData(
                          id: widget.recipe.id,
                          title: widget.recipe.title,
                          tagline: widget.recipe.tags.join(' • '),
                          description: widget.recipe.description,
                          timeMinutes: int.tryParse(widget.recipe.prepTime.replaceAll(RegExp(r'[^0-9]'), '')) ?? 15,
                          kcal: int.tryParse(widget.recipe.calories.replaceAll(RegExp(r'[^0-9]'), '')) ?? 300,
                          proteinGrams: int.tryParse(widget.recipe.protein.replaceAll(RegExp(r'[^0-9]'), '')) ?? 10,
                          imageAsset: widget.recipe.images.isNotEmpty ? widget.recipe.images.first : '',
                          whatsInside: const [],
                          fullRecipe: widget.recipe,
                        );
                        RecipeHistoryService.instance.saveOrBookmarkRecipeCard(card, bookmarked: nextState);
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
                          child: Text(r.description, style: TextStyle(fontSize: 12.5 * scale, height: 1.4, color: colors.textSecondary)),
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
                                      Text('Nutrition Facts', style: TextStyle(fontSize: 15.5 * scale, fontWeight: FontWeight.w800, color: colors.textPrimary)),
                                      Text('Per Serving', style: TextStyle(fontSize: 10.5 * scale, color: colors.textSecondary)),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: widget.onViewAllNutrition,
                                  child: Row(
                                    children: [
                                      Text('View All', style: TextStyle(fontSize: 12 * scale, fontWeight: FontWeight.w700, color: colors.iconPurple)),
                                      Icon(Icons.chevron_right, size: 15 * scale, color: colors.iconPurple),
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
                              Expanded(child: Text('Ingredients', style: TextStyle(fontSize: 15.5 * scale, fontWeight: FontWeight.w800, color: colors.textPrimary))),
                              Text('Serves ${r.serves}', style: TextStyle(fontSize: 12 * scale, fontWeight: FontWeight.w700, color: colors.iconPurple)),
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
                          child: Text('Instructions', style: TextStyle(fontSize: 15.5 * scale, fontWeight: FontWeight.w800, color: colors.textPrimary)),
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
                            final nextState = !_savedForLater;
                            setState(() {
                              _savedForLater = nextState;
                              _favorited = nextState;
                            });
                            final card = RecipeCardData(
                              id: widget.recipe.id,
                              title: widget.recipe.title,
                              tagline: widget.recipe.tags.join(' • '),
                              description: widget.recipe.description,
                              timeMinutes: int.tryParse(widget.recipe.prepTime.replaceAll(RegExp(r'[^0-9]'), '')) ?? 15,
                              kcal: int.tryParse(widget.recipe.calories.replaceAll(RegExp(r'[^0-9]'), '')) ?? 300,
                              proteinGrams: int.tryParse(widget.recipe.protein.replaceAll(RegExp(r'[^0-9]'), '')) ?? 10,
                              imageAsset: widget.recipe.images.isNotEmpty ? widget.recipe.images.first : '',
                              whatsInside: const [],
                              fullRecipe: widget.recipe,
                            );
                            RecipeHistoryService.instance.saveOrBookmarkRecipeCard(card, bookmarked: nextState);
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
              if (asset == null || asset.isEmpty) {
                return const _ImagePlaceholder();
              }
              if (asset.startsWith('http')) {
                return Image.network(
                  asset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const _ImagePlaceholder(),
                );
              }
              return Image.asset(
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
            decoration: BoxDecoration(
              color: context.dcColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.dcColors.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_fire_department, size: 14 * uiScale, color: context.dcColors.iconOrange),
                SizedBox(width: 5 * uiScale),
                Text(calories, style: TextStyle(fontSize: 12 * uiScale, fontWeight: FontWeight.w800, color: context.dcColors.textPrimary)),
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
            color: context.dcColors.surface,
            border: Border.all(color: context.dcColors.cardBorder),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: context.dcColors.isDark ? 0.25 : 0.1), blurRadius: 10, offset: const Offset(0, 4))],
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
                    child: Text(title, style: TextStyle(fontSize: 20 * uiScale, fontWeight: FontWeight.w800, color: context.dcColors.textPrimary)),
                  ),
                  Icon(Icons.eco, size: 17 * uiScale, color: context.dcColors.iconGreen),
                ],
              ),
              SizedBox(height: 3 * uiScale),
              Text(
                tags.join(' • '),
                style: TextStyle(fontSize: 12 * uiScale, fontWeight: FontWeight.w700, color: context.dcColors.iconPurple),
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
                color: context.dcColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.dcColors.cardBorder),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: context.dcColors.isDark ? 0.2 : 0.04), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Icon(s.icon, size: 16 * uiScale, color: s.color),
                  SizedBox(height: 6 * uiScale),
                  Text(s.value, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5 * uiScale, fontWeight: FontWeight.w800, color: context.dcColors.textPrimary)),
                  Text(s.label, style: TextStyle(fontSize: 9 * uiScale, color: context.dcColors.textSecondary)),
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
        color: context.dcColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.dcColors.cardBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: context.dcColors.isDark ? 0.2 : 0.04), blurRadius: 12, offset: const Offset(0, 6))],
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
                  Text(f.label, style: TextStyle(fontSize: 10 * uiScale, color: context.dcColors.textSecondary)),
                  SizedBox(height: 2 * uiScale),
                  Text(f.value, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5 * uiScale, fontWeight: FontWeight.w800, color: context.dcColors.textPrimary)),
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
        color: context.dcColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.dcColors.cardBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: context.dcColors.isDark ? 0.2 : 0.04), blurRadius: 12, offset: const Offset(0, 6))],
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
                child: Container(width: 4 * uiScale, height: 4 * uiScale, decoration: BoxDecoration(shape: BoxShape.circle, color: context.dcColors.iconPurple)),
              ),
              SizedBox(width: 8 * uiScale),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 11.5 * uiScale, color: context.dcColors.textSecondary, height: 1.3),
                    children: [
                      TextSpan(text: '${item.amount} ', style: TextStyle(fontWeight: FontWeight.w800, color: context.dcColors.textPrimary)),
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
        color: context.dcColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.dcColors.cardBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: context.dcColors.isDark ? 0.2 : 0.04), blurRadius: 12, offset: const Offset(0, 6))],
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
            border: Border.all(color: context.dcColors.iconPurple, width: 1.6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.saved ? Icons.alarm_on_rounded : Icons.alarm_outlined, size: 16 * widget.uiScale, color: context.dcColors.iconPurple),
              SizedBox(width: 6 * widget.uiScale),
              Flexible(
                child: Text(
                  widget.saved ? 'Saved' : 'Save for Later',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5 * widget.uiScale, fontWeight: FontWeight.w800, color: context.dcColors.iconPurple),
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
            gradient: LinearGradient(colors: [context.dcColors.iconPurple, const Color(0xFF7C5CFC)]),
            boxShadow: [BoxShadow(color: context.dcColors.iconPurple.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 8))],
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
