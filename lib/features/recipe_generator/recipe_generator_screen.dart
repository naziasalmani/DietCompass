import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:diet_compass/core/theme/app_colors.dart';
import '../../core/model/food_product.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/dietary_safety_validator.dart';
import '../../core/services/api_service.dart';
import '../../core/services/pantry_storage_service.dart';
import '../../core/services/personalization_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/recipe_service.dart';
import '../../core/services/recipe_history_service.dart';
import 'recipe_detail_screen.dart';
import '../home/home_screen.dart';
import '../pantry/pantry_screen.dart';
import 'history_screen.dart';
import 'pdf_service.dart';
import 'calendar_service.dart';
import 'ai_meal_planner_screen.dart';

class RecipeGeneratorScreen extends StatefulWidget {
  const RecipeGeneratorScreen({
    super.key,
    this.sourceProduct,
    this.initialProduct,
    this.userName = 'Nazia',
    this.pantryItems = const [],
    this.customizeOptions = const [
      CustomizeChipData(icon: Icons.flag_rounded, label: 'Goal', value: 'Weight Loss', color: Color(0xFF1E8A4C)),
      CustomizeChipData(icon: Icons.restaurant_menu_rounded, label: 'Meal Type', value: 'Breakfast', color: Color(0xFF6C4EF5)),
      CustomizeChipData(icon: Icons.eco_rounded, label: 'Diet Preference', value: 'Vegetarian', color: Color(0xFF1E8A4C)),
      CustomizeChipData(icon: Icons.access_time_rounded, label: 'Cooking Time', value: 'Under 20 min', color: Color(0xFFE0862E)),
    ],
    this.recipes,
    this.moreIdeas = const [
      MoreIdeaData(title: 'Protein Pancakes', imageAsset: 'assets/images/recipe_protein_pancakes.jpeg', timeMinutes: 20, kcal: 375),
      MoreIdeaData(title: 'Berry Chia Pudding', imageAsset: 'assets/images/recipe_berry_chia_pudding.jpeg', timeMinutes: 10, kcal: 280),
      MoreIdeaData(title: 'Veggie Omelette', imageAsset: 'assets/images/recipe_veggie_omelette.jpeg', timeMinutes: 15, kcal: 310),
      MoreIdeaData(title: 'Peanut Butter Smoothie', imageAsset: 'assets/images/recipe_peanut_butter_smoothie.jpeg', timeMinutes: 5, kcal: 250),
    ],
    this.onBack,
    this.onHistoryTap,
    this.onViewPantryTap,
    this.onAddPantryItem,
    this.onGenerateRecipe,
    this.onCustomizeTap,
    this.onViewAllRecipes,
    this.onViewRecipe,
    this.onSaveRecipe,
    this.onCreateMealPlan,
    this.onNavTap,
    this.initialNavIndex = 3,
  });

  final FoodProduct? sourceProduct;
  final FoodProduct? initialProduct;
  final String userName;
  final List<PantryChipData> pantryItems;
  final List<CustomizeChipData> customizeOptions;
  final List<RecipeCardData>? recipes;
  final List<MoreIdeaData> moreIdeas;

  final VoidCallback? onBack;
  final VoidCallback? onHistoryTap;
  final VoidCallback? onViewPantryTap;
  final VoidCallback? onAddPantryItem;
  final ValueChanged<String>? onGenerateRecipe;
  final ValueChanged<int>? onCustomizeTap;
  final VoidCallback? onViewAllRecipes;
  final ValueChanged<int>? onViewRecipe;
  final ValueChanged<int>? onSaveRecipe;
  final VoidCallback? onCreateMealPlan;
  final ValueChanged<int>? onNavTap;
  final int initialNavIndex;

  @override
  State<RecipeGeneratorScreen> createState() => _RecipeGeneratorScreenState();
}

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------
class PantryChipData {
  const PantryChipData({required this.label, required this.asset, required this.icon});
  final String label;
  final String asset;
  final IconData icon;
}

class CustomizeChipData {
  const CustomizeChipData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;
}

class WhatsInTag {
  const WhatsInTag({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
}

class RecipeCardData {
  const RecipeCardData({
    required this.title,
    required this.tagline,
    required this.description,
    required this.timeMinutes,
    required this.kcal,
    required this.proteinGrams,
    required this.imageAsset,
    required this.whatsInside,
    this.id,
    this.recipeSource = 'api',
    this.recommended = false,
    this.usedIngredientCount = 0,
    this.missedIngredientCount = 0,
    this.pantryMatchSummary = '',
    this.fullRecipe,
  });
  final dynamic id;
  final String title;
  final String tagline;
  final String description;
  final int timeMinutes;
  final int kcal;
  final int proteinGrams;
  final String imageAsset;
  final String recipeSource;
  final List<WhatsInTag> whatsInside;
  final bool recommended;
  final int usedIngredientCount;
  final int missedIngredientCount;
  final String pantryMatchSummary;
  final Recipe? fullRecipe;
}



class MoreIdeaData {
  const MoreIdeaData({
    required this.title,
    required this.imageAsset,
    required this.timeMinutes,
    required this.kcal,
  });
  final String title;
  final String imageAsset;
  final int timeMinutes;
  final int kcal;
}

// ---------------------------------------------------------------------------
// Palette (shared with home_screen.dart)
// ---------------------------------------------------------------------------
const _kPurple = Color(0xFF6C4EF5);
const _kGreen = Color(0xFF1E8A4C);
const _kOrange = Color(0xFFE0862E);
const _kRed = Color(0xFFE0525C);
const _kInk = Color(0xFF1B1B2E);
const _kMutedInk = Color(0xFF6B6B7B);
const _kFaintPurple = Color(0xFFF1ECFB);

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
class _RecipeGeneratorScreenState extends State<RecipeGeneratorScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _ambientCtrl;
  late final PageController _recipePageCtrl;
  late final TextEditingController _cravingCtrl;
  late List<PantryChipData> _pantryItems;
  late List<RecipeCardData> _recipes;
  late Set<int> _savedRecipes;
  late Set<int> _bookmarkedIdeas;
  late int _navIndex;
  double _recipePage = 0;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isTimeout = false;

  FoodProduct? get _effectiveProduct => widget.sourceProduct ?? widget.initialProduct;

  @override
  void initState() {
    super.initState();
    _navIndex = widget.initialNavIndex;
    _pantryItems = [...widget.pantryItems];
    _recipes = widget.recipes != null ? [...widget.recipes!] : [];
    _savedRecipes = {};
    _bookmarkedIdeas = {};
    _cravingCtrl = TextEditingController();

    _initProductState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _recipePageCtrl = PageController(viewportFraction: 0.97)
      ..addListener(() {
        setState(() {
          _recipePage = _recipePageCtrl.page ?? 0;
        });
      });

    if (widget.recipes == null) {
      if (widget.pantryItems.isEmpty && _effectiveProduct == null) {
        _loadUserPantry().then((_) {
          _fetchRecipes();
        });
      } else {
        _fetchRecipes();
      }
    }
  }

  Future<void> _loadUserPantry() async {
    final products = await PantryStorageService.instance.getProducts();
    if (!mounted) return;
    if (products.isNotEmpty) {
      setState(() {
        _pantryItems = products.map((p) {
          return PantryChipData(
            label: p.name.trim(),
            asset: '',
            icon: Icons.kitchen_rounded,
          );
        }).toList();
      });
    }
  }

  void _initProductState() {
    if (widget.pantryItems.isNotEmpty) {
      _pantryItems = [...widget.pantryItems];
    }
    final p = _effectiveProduct;
    if (p != null) {
      _cravingCtrl.text = '';
    }
  }

  @override
  void didUpdateWidget(covariant RecipeGeneratorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sourceProduct != widget.sourceProduct ||
        oldWidget.initialProduct != widget.initialProduct) {
      _initProductState();
      _fetchRecipes();
    }
  }

  Future<void> _fetchRecipes({String craving = ''}) async {
    if (!mounted) return;
    if (_recipePageCtrl.hasClients) {
      _recipePageCtrl.jumpToPage(0);
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isTimeout = false;
      _recipes = [];
      _recipePage = 0;
    });

    try {
      final isProductMode = _effectiveProduct != null;
      final customize = _effectiveCustomizeOptions;
      final mealType = customize.length > 1 ? customize[1].value : 'Breakfast';
      final timeStr = customize.length > 3 ? customize[3].value : 'Under 20 min';
      int? maxTime;
      final match = RegExp(r'(\d+)').firstMatch(timeStr);
      if (match != null) {
        maxTime = int.tryParse(match.group(1)!);
      }

      List<RecipeCardData> list;

      if (isProductMode) {
        list = await RecipeService.instance.generateRecipes(
          mode: 'product',
          sourceProduct: _effectiveProduct,
          craving: craving.isNotEmpty ? craving : _cravingCtrl.text,
          mealType: mealType,
          maxTime: maxTime,
        );
      } else {
        final ingredients = _pantryItems.map((p) => p.label).toList();
        if (ingredients.isEmpty && craving.isEmpty && _cravingCtrl.text.trim().isEmpty) {
          setState(() {
            _recipes = [];
            _isLoading = false;
            _errorMessage = null;
            _isTimeout = false;
          });
          return;
        }
        list = await RecipeService.instance.generateRecipes(
          mode: 'pantry',
          ingredients: ingredients,
          craving: craving.isNotEmpty ? craving : _cravingCtrl.text,
          mealType: mealType,
          maxTime: maxTime,
        );
      }

      if (mounted) {
        setState(() {
          _recipes = list;
          _isLoading = false;
          _errorMessage = null;
          _isTimeout = false;
        });

        if (list.isNotEmpty) {
          RecipeHistoryService.instance.saveRecipes(
            recipes: list,
            generationMode: isProductMode ? 'product' : 'pantry',
            sourceProduct: _effectiveProduct?.name,
            normalizedIngredient: isProductMode && _effectiveProduct != null
                ? RecipeService.normalizeProductCategory(_effectiveProduct!)
                : null,
            pantryIngredients: !isProductMode ? _pantryItems.map((p) => p.label).toList() : const [],
          );
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _recipes = [];
          if (e.statusCode == 408 || e.message.toLowerCase().contains('time')) {
            _isTimeout = true;
            _errorMessage = 'Recipe request timed out. Please tap below to retry.';
          } else {
            _isTimeout = false;
            _errorMessage = e.message.isNotEmpty ? e.message : 'Unable to load recipes right now.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        final isTimeout = e.toString().toLowerCase().contains('timeout') || e.toString().contains('408');
        setState(() {
          _isLoading = false;
          _recipes = [];
          _isTimeout = isTimeout;
          _errorMessage = isTimeout
              ? 'Recipe request timed out. Please tap below to retry.'
              : 'Network issue occurred. Please check your connection and retry.';
        });
      }
    }
  }


  @override
  void dispose() {
    _entranceCtrl.dispose();
    _ambientCtrl.dispose();
    _recipePageCtrl.dispose();
    _cravingCtrl.dispose();
    super.dispose();
  }

  String get _effectiveUserName {
    if (widget.userName != 'Nazia' && widget.userName.isNotEmpty) return widget.userName;
    final prof = ProfileService.instance.currentProfile;
    if (prof != null && prof.fullName.trim().isNotEmpty) {
      return prof.fullName.split(' ').first;
    }
    final user = AuthService.instance.currentUser;
    if (user != null && user.fullName.trim().isNotEmpty) {
      return user.fullName.split(' ').first;
    }
    return 'There';
  }

  List<CustomizeChipData> get _effectiveCustomizeOptions {
    final pers = PersonalizationService.instance.currentPersonalization;
    final prof = ProfileService.instance.currentProfile;

    final goal = (pers?.goals.isNotEmpty == true) ? pers!.goals.first : 'Maintain Weight';
    final diet = (pers?.dietType?.isNotEmpty == true)
        ? pers!.dietType!
        : (prof?.dietType.isNotEmpty == true ? prof!.dietType : 'Balanced');

    return [
      CustomizeChipData(icon: Icons.flag_rounded, label: 'Goal', value: goal, color: const Color(0xFF1E8A4C)),
      const CustomizeChipData(icon: Icons.restaurant_menu_rounded, label: 'Meal Type', value: 'Breakfast', color: Color(0xFF6C4EF5)),
      CustomizeChipData(icon: Icons.eco_rounded, label: 'Diet Preference', value: diet, color: const Color(0xFF1E8A4C)),
      const CustomizeChipData(icon: Icons.access_time_rounded, label: 'Cooking Time', value: 'Under 20 min', color: Color(0xFFE0862E)),
    ];
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

  void _removePantryItem(int index) {
    setState(() => _pantryItems.removeAt(index));
    _fetchRecipes();
  }

  void _openPantry() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PantryScreen()),
    );
  }

  void _toggleSaveRecipe(int index) async {
    if (index >= 0 && index < _recipes.length) {
      final recipe = _recipes[index];
      final isCurrentlySaved = RecipeHistoryService.instance.isRecipeSaved(recipe.id, recipe.title) || _savedRecipes.contains(index);
      final nextSavedState = !isCurrentlySaved;

      setState(() {
        if (nextSavedState) {
          _savedRecipes.add(index);
        } else {
          _savedRecipes.remove(index);
        }
      });

      final success = await RecipeHistoryService.instance.saveOrBookmarkRecipeCard(
        recipe,
        generationMode: _effectiveProduct != null ? 'product' : 'pantry',
        sourceProduct: _effectiveProduct?.name,
        normalizedIngredient: _effectiveProduct != null
            ? RecipeService.normalizeProductCategory(_effectiveProduct!)
            : null,
        pantryIngredients: _effectiveProduct == null
            ? _pantryItems.map((p) => p.label).toList()
            : const [],
        bookmarked: nextSavedState,
      );

      if (!success) {
        if (mounted) {
          setState(() {
            if (isCurrentlySaved) {
              _savedRecipes.add(index);
            } else {
              _savedRecipes.remove(index);
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save ${recipe.title}. Please check your connection.'),
              backgroundColor: const Color(0xFFE0525C),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else {
        if (mounted && nextSavedState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.bookmark_added_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Saved ${recipe.title} to your recipes ✓',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: _kPurple,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
      widget.onSaveRecipe?.call(index);
    }
  }

  void _toggleBookmarkIdea(int index) {
    setState(() {
      if (_bookmarkedIdeas.contains(index)) {
        _bookmarkedIdeas.remove(index);
      } else {
        _bookmarkedIdeas.add(index);
      }
    });
  }

  List<MoreIdeaData> get _safeMoreIdeas {
    return widget.moreIdeas.where((idea) {
      final res = DietarySafetyValidator.instance.validateRecipeCard(
        RecipeCardData(
          title: idea.title,
          tagline: '${idea.timeMinutes} min • ${idea.kcal} kcal',
          description: 'Idea for ${idea.title}',
          timeMinutes: idea.timeMinutes,
          kcal: idea.kcal,
          proteinGrams: 10,
          imageAsset: idea.imageAsset,
          whatsInside: const [],
        ),
      );
      return res.isCompatible;
    }).toList();
  }

  void _openRecipeDetail(RecipeCardData card) {
    // 1-to-1 strict binding: Card must open the exact same recipe object
    final recipeToOpen = card.fullRecipe ??
        Recipe(
          id: card.id ?? card.title.toLowerCase().replaceAll(' ', '_'),
          images: [card.imageAsset],
          title: card.title,
          tags: card.tagline.split('•').map((s) => s.trim()).toList(),
          description: card.description,
          prepTime: '${card.timeMinutes} min',
          calories: '${card.kcal} kcal',
          protein: '${card.proteinGrams}g',
          difficulty: 'Easy',
          nutritionFacts: [
            NutritionFact(icon: Icons.local_fire_department, color: const Color(0xFFE0862E), label: 'Calories', value: '${card.kcal}\nkcal'),
            NutritionFact(icon: Icons.eco, color: const Color(0xFF1E8A4C), label: 'Protein', value: '${card.proteinGrams}g'),
          ],
          ingredients: card.whatsInside.isNotEmpty
              ? card.whatsInside.map((w) => IngredientItem(amount: '1 portion', name: w.title)).toList()
              : _pantryItems.map((p) => IngredientItem(amount: '1 portion', name: p.label)).toList(),
          serves: 1,
          instructions: const [
            'Prepare all fresh pantry ingredients.',
            'Combine and cook according to recipe instructions.',
            'Serve warm and enjoy your healthy meal!',
          ],
        );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recipe: recipeToOpen),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 390).clamp(0.85, 1.25);
    final currentRecipeIndex = _recipePage.round().clamp(0, (_recipes.isNotEmpty ? _recipes.length - 1 : 0));
    final productContext = _effectiveProduct;


    final colors = context.dcColors;
    return Scaffold(
      backgroundColor: colors.bg,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _BackgroundGradient(),
          _DriftingSparkles(controller: _ambientCtrl),
          SafeArea(
            bottom: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(18 * scale, 8 * scale, 18 * scale, 110 * scale),
              physics: const BouncingScrollPhysics(),
              children: [
                FadeTransition(
                  opacity: _fade(0.0, 0.3),
                  child: SlideTransition(
                    position: _slide(0.0, 0.35),
                    child: _ScreenHeader(
                      uiScale: scale,
                      onBack: () {
                        if (widget.onBack != null) {
                          widget.onBack!();
                        } else if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HomeScreen(),
                            ),
                          );
                        }
                      },
                      onHistoryTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => HistoryScreen(),
    ),
  );
},
                    ),
                  ),
                ),
                SizedBox(height: 18 * scale),

                if (productContext != null) ...[
                  FadeTransition(
                    opacity: _fade(0.02, 0.36),
                    child: SlideTransition(
                      position: _slide(0.02, 0.40),
                      child: _ProductSourceBanner(
                        uiScale: scale,
                        product: productContext,
                      ),
                    ),
                  ),
                  SizedBox(height: 14 * scale),
                ],

                FadeTransition(
                  opacity: _fade(0.05, 0.38),
                  child: SlideTransition(
                    position: _slide(0.05, 0.42),
                    child: _AiIntroCard(
                      uiScale: scale,
                      userName: _effectiveUserName,
                      ambientCtrl: _ambientCtrl,
                    ),
                  ),
                ),
                SizedBox(height: 22 * scale),

                FadeTransition(
                  opacity: _fade(0.1, 0.44),
                  child: SlideTransition(
                    position: _slide(0.1, 0.48),
                    child: _PantrySection(
                      uiScale: scale,
                      items: _pantryItems,
                      onRemove: _removePantryItem,
                      onAddMore: widget.onAddPantryItem ?? _openPantry,
                      onViewPantry: widget.onViewPantryTap ?? _openPantry,
                    ),
                  ),
                ),
                SizedBox(height: 16 * scale),

                if (_effectiveProduct != null) ...[
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 4 * scale),
                    padding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 10 * scale),
                    decoration: BoxDecoration(
                      color: _kPurple.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _kPurple.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: _kPurple, size: 20),
                        SizedBox(width: 8 * scale),
                        Expanded(
                          child: Text(
                            'Product Focus: ${_effectiveProduct!.name}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _kInk,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12 * scale),
                ],

                FadeTransition(
                  opacity: _fade(0.15, 0.5),
                  child: SlideTransition(
                    position: _slide(0.15, 0.54),
                    child: _CravingInputRow(
                      uiScale: scale,
                      controller: _cravingCtrl,
                      onGenerate: () {
                        widget.onGenerateRecipe?.call(_cravingCtrl.text);
                        _fetchRecipes(craving: _cravingCtrl.text);
                      },
                    ),
                  ),
                ),

                SizedBox(height: 22 * scale),

                FadeTransition(
                  opacity: _fade(0.2, 0.55),
                  child: SlideTransition(
                    position: _slide(0.2, 0.58),
                    child: _CustomizeSection(
                      uiScale: scale,
                      options: _effectiveCustomizeOptions,
                      onTap: (optIndex) {
                        widget.onCustomizeTap?.call(optIndex);
                        _fetchRecipes();
                      },
                    ),
                  ),
                ),
                SizedBox(height: 22 * scale),

                FadeTransition(
                  opacity: _fade(0.25, 0.6),
                  child: SlideTransition(
                    position: _slide(0.25, 0.64),
                    child: _SectionTitleRow(
                      uiScale: scale,
                      title: 'AI Generated Recipes for You',
                      actionLabel: 'View All',
                      onAction: widget.onViewAllRecipes,
                    ),
                  ),
                ),
                SizedBox(height: 12 * scale),

                FadeTransition(
                  opacity: _fade(0.28, 0.65),
                  child: _isLoading
                      ? Container(
                          height: 220 * scale,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(color: _kPurple),
                              SizedBox(height: 12 * scale),
                              Text(
                                _effectiveProduct != null
                                    ? 'Chef AI is finding recipes for ${_effectiveProduct!.name}...'
                                    : 'Chef AI is finding recipes with your pantry...',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.5 * scale,
                                  fontWeight: FontWeight.w600,
                                  color: _kInk,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _errorMessage != null
                          ? Container(
                              height: 200 * scale,
                              padding: EdgeInsets.all(16 * scale),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isTimeout ? Icons.timer_off_outlined : Icons.cloud_off_outlined,
                                    size: 38 * scale,
                                    color: const Color(0xFFE0862E),
                                  ),
                                  SizedBox(height: 8 * scale),
                                  Text(
                                    _errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12 * scale,
                                      color: _kInk,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 12 * scale),
                                  FilledButton.icon(
                                    onPressed: () => _fetchRecipes(craving: _cravingCtrl.text),
                                    icon: const Icon(Icons.refresh_rounded, size: 16),
                                    label: const Text('Retry'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _kPurple,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _recipes.isEmpty
                              ? Container(
                                  height: 200 * scale,
                                  padding: EdgeInsets.all(16 * scale),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.restaurant_menu_rounded, size: 42 * scale, color: _kMutedInk),
                                      SizedBox(height: 8 * scale),
                                      Text(
                                        _effectiveProduct != null
                                            ? 'No suitable recipes found for this product with your selected preferences.'
                                            : _pantryItems.isEmpty
                                                ? 'Your pantry is empty. Add ingredients to discover personalized recipes.'
                                                : 'No suitable recipes found with your current pantry and preferences.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12 * scale,
                                          color: _kMutedInk,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (_effectiveProduct == null && _pantryItems.isEmpty) ...[
                                        SizedBox(height: 10 * scale),
                                        FilledButton.icon(
                                          onPressed: _openPantry,
                                          icon: const Icon(Icons.add, size: 16),
                                          label: const Text('Open Pantry'),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: _kPurple,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                )
                          : SizedBox(
                              height: 220 * scale,
                              child: ListenableBuilder(
                                listenable: RecipeHistoryService.instance,
                                builder: (context, _) {
                                  return PageView.builder(
                                    controller: _recipePageCtrl,
                                    itemCount: _recipes.length,
                                    itemBuilder: (context, index) {
                                      final recipe = _recipes[index];
                                      final delta = (_recipePage - index).abs().clamp(0.0, 1.0);
                                      final cardScale = 1.0 - (delta * 0.06);
                                      final isSaved = RecipeHistoryService.instance.isRecipeSaved(recipe.id, recipe.title) || _savedRecipes.contains(index);

                                      return Transform.scale(
                                        scale: cardScale,
                                        child: Padding(
                                          key: ValueKey(recipe.id ?? recipe.title),
                                          padding: EdgeInsets.symmetric(horizontal: 2 * scale),
                                          child: _RecipeCard(
                                            uiScale: scale,
                                            recipe: recipe,
                                            saved: isSaved,
                                            onView: () => _openRecipeDetail(recipe),
                                            onSave: () => _toggleSaveRecipe(index),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                ),
                SizedBox(height: 10 * scale),

                FadeTransition(
                  opacity: _fade(0.3, 0.66),
                  child: _PageDots(
                    uiScale: scale,
                    count: _recipes.isNotEmpty ? _recipes.length : 1,
                    page: _recipePage,
                  ),
                ),
                SizedBox(height: 22 * scale),

                if (_recipes.isNotEmpty)
                  FadeTransition(
                    opacity: _fade(0.32, 0.68),
                    child: SlideTransition(
                      position: _slide(0.32, 0.7),
                      child: _WhatsInRecipeSection(
                        uiScale: scale,
                        recipe: _recipes[currentRecipeIndex],
                      ),
                    ),
                  ),

                SizedBox(height: 24 * scale),

                FadeTransition(
                  opacity: _fade(0.38, 0.72),
                  child: SlideTransition(
                    position: _slide(0.38, 0.76),
                    child: _MoreIdeasSection(
                      uiScale: scale,
                      ideas: _safeMoreIdeas,
                      bookmarked: _bookmarkedIdeas,
                      onToggleBookmark: _toggleBookmarkIdea,
                    ),
                  ),
                ),
                SizedBox(height: 22 * scale),

                FadeTransition(
                  opacity: _fade(0.45, 0.8),
                  child: SlideTransition(
                    position: _slide(0.45, 0.85),
                    child: _MealPlanBanner(
  uiScale: scale,
  ambientCtrl: _ambientCtrl,
  onCreateMealPlan: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AiMealPlannerScreen(
  onExportPdf: () async {
    await PdfService.exportMealPlan();
  },

  onAddToCalendar: () async {
    await CalendarService.addMealPlan();
  },
),
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
    );
  }
}

// ---------------------------------------------------------------------------
// Background
// ---------------------------------------------------------------------------
class _BackgroundGradient extends StatelessWidget {
  const _BackgroundGradient();

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.bg,
            colors.isDark ? const Color(0xFF141320) : const Color(0xFFF2FFF7),
          ],
        ),
      ),
    );
  }
}

class _DriftingSparkles extends StatelessWidget {
  const _DriftingSparkles({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final t = controller.value;
          final dy = math.sin(t * math.pi) * 6;
          return Stack(
            children: [
              Positioned(
                top: 70 + dy,
                right: 22,
                child: Transform.rotate(
                  angle: t * 0.6,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: _kPurple.withValues(alpha: 0.35),
                  ),
                ),
              ),
              Positioned(
                bottom: 220 - dy,
                left: 14,
                child: Transform.rotate(
                  angle: -t * 0.5,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 12,
                    color: _kGreen.withValues(alpha: 0.3),
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
// Reusable: glass container
// ---------------------------------------------------------------------------
class _GlassContainer extends StatelessWidget {
  const _GlassContainer({
    required this.child,
    this.borderRadius = 22,
    this.blur = 16,
    this.opacity = 0.6,
    this.padding,
    this.gradientColors,
    this.borderColor,
    this.boxShadowColor,
  });

  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final List<Color>? gradientColors;
  final Color? borderColor;
  final Color? boxShadowColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: gradientColors != null
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors!,
                  )
                : null,
            color: gradientColors == null
                ? (colors.isDark ? colors.surface.withValues(alpha: 0.85) : Colors.white.withValues(alpha: opacity))
                : null,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? (colors.isDark ? colors.cardBorder : Colors.white.withValues(alpha: 0.65)),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (boxShadowColor ?? colors.iconPurple).withValues(alpha: colors.isDark ? 0.2 : 0.1),
                blurRadius: 26,
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

class _SafeAssetImage extends StatelessWidget {
  const _SafeAssetImage({
    required this.asset,
    required this.icon,
    this.fit = BoxFit.cover,
    this.iconColor = _kPurple,
    this.bgColor = _kFaintPurple,
  });

  final String asset;
  final IconData icon;
  final BoxFit fit;
  final Color iconColor;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    if (asset.startsWith('http')) {
      return Image.network(
        asset,
        fit: fit,
        errorBuilder: (context, error, stack) => Container(
          color: bgColor,
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor.withValues(alpha: 0.6)),
        ),
      );
    }
    return Image.asset(
      asset,
      fit: fit,
      errorBuilder: (context, error, stack) => Container(
        color: bgColor,
        alignment: Alignment.center,
        child: Icon(icon, color: iconColor.withValues(alpha: 0.6)),
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------
class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({required this.uiScale, this.onBack, this.onHistoryTap});
  final double uiScale;
  final VoidCallback? onBack;
  final VoidCallback? onHistoryTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _CircleIconButton(uiScale: uiScale, icon: Icons.arrow_back_rounded, onTap: onBack),
        Expanded(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome_rounded, color: colors.iconPurple, size: 17 * uiScale),
                  SizedBox(width: 6 * uiScale),
                  Flexible(
                    child: Text(
                      'Recipe Generator',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17.5 * uiScale,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2 * uiScale),
              Text(
                'AI creates healthy recipes just for you',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10.5 * uiScale, color: colors.textSecondary),
              ),
            ],
          ),
        ),
        _HistoryButton(uiScale: uiScale, onTap: onHistoryTap),
      ],
    );
  }
}

class _CircleIconButton extends StatefulWidget {
  const _CircleIconButton({required this.uiScale, required this.icon, this.onTap});
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
            color: context.dcColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: context.dcColors.cardBorder),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: context.dcColors.isDark ? 0.2 : 0.06), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Icon(widget.icon, size: 19 * widget.uiScale, color: context.dcColors.textPrimary),
        ),
      ),
    );
  }
}

class _HistoryButton extends StatefulWidget {
  const _HistoryButton({required this.uiScale, this.onTap});
  final double uiScale;
  final VoidCallback? onTap;

  @override
  State<_HistoryButton> createState() => _HistoryButtonState();
}

class _HistoryButtonState extends State<_HistoryButton> {
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
          padding: EdgeInsets.symmetric(horizontal: 12 * widget.uiScale, vertical: 9 * widget.uiScale),
          decoration: BoxDecoration(
            color: context.dcColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.dcColors.cardBorder),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: context.dcColors.isDark ? 0.2 : 0.06), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded, size: 14 * widget.uiScale, color: context.dcColors.iconPurple),
              SizedBox(width: 4 * widget.uiScale),
              Text(
                'History',
                style: TextStyle(fontSize: 11.5 * widget.uiScale, fontWeight: FontWeight.w700, color: context.dcColors.iconPurple),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AI intro card
// ---------------------------------------------------------------------------
class _AiIntroCard extends StatelessWidget {
  const _AiIntroCard({required this.uiScale, required this.userName, required this.ambientCtrl});
  final double uiScale;
  final String userName;
  final AnimationController ambientCtrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return _GlassContainer(
      borderRadius: 24,
      gradientColors: colors.isDark
          ? const [Color(0xFF221F35), Color(0xFF1B192A)]
          : const [Color(0xFFEDE7FC), Color(0xFFF7F3FF)],
      padding: EdgeInsets.all(16 * uiScale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: ambientCtrl,
            builder: (context, child) {
              final bob = math.sin(ambientCtrl.value * math.pi) * 3.5;
              return Transform.translate(offset: Offset(0, -bob), child: child);
            },
            child: _RobotAvatar(uiScale: uiScale),
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
                        'Hi $userName!',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15.5 * uiScale, fontWeight: FontWeight.w800, color: colors.textPrimary),
                      ),
                    ),
                    SizedBox(width: 4 * uiScale),
                    Text('👋', style: TextStyle(fontSize: 14 * uiScale)),
                  ],
                ),
                SizedBox(height: 3 * uiScale),
                RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 11.5 * uiScale, height: 1.35, color: colors.textSecondary),
                    children: [
                      const TextSpan(text: "Tell me what you have or what you're craving, I'll create the "),
                      TextSpan(
                        text: 'perfect recipe!',
                        style: TextStyle(color: colors.iconPurple, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8 * uiScale),
          _SpinningWandBadge(uiScale: uiScale, ambientCtrl: ambientCtrl),
        ],
      ),
    );
  }
}

class _RobotAvatar extends StatelessWidget {
  const _RobotAvatar({required this.uiScale});
  final double uiScale;

  @override
  Widget build(BuildContext context) {
    final layoutSize = 58 * uiScale;
    final visualSize = 100 * uiScale;
    return SizedBox(
      width: layoutSize,
      height: layoutSize,
      child: OverflowBox(
        maxWidth: visualSize,
        maxHeight: visualSize,
        alignment: Alignment.center,
        child: _SafeAssetImage(
          asset: 'assets/images/rg_robot.png',
          icon: Icons.smart_toy_rounded,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _SpinningWandBadge extends StatelessWidget {
  const _SpinningWandBadge({required this.uiScale, required this.ambientCtrl});
  final double uiScale;
  final AnimationController ambientCtrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Container(
      width: 44 * uiScale,
      height: 44 * uiScale,
      decoration: BoxDecoration(
        color: colors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          BoxShadow(color: colors.iconPurple.withValues(alpha: 0.18), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: AnimatedBuilder(
        animation: ambientCtrl,
        builder: (context, child) {
          final angle = math.sin(ambientCtrl.value * math.pi) * 0.35;
          return Transform.rotate(angle: angle, child: child);
        },
        child: Icon(Icons.auto_fix_high_rounded, color: colors.iconPurple, size: 19 * uiScale),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pantry section
// ---------------------------------------------------------------------------
class _PantrySection extends StatelessWidget {
  const _PantrySection({
    required this.uiScale,
    required this.items,
    required this.onRemove,
    this.onAddMore,
    this.onViewPantry,
  });

  final double uiScale;
  final List<PantryChipData> items;
  final ValueChanged<int> onRemove;
  final VoidCallback? onAddMore;
  final VoidCallback? onViewPantry;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3.5 * uiScale,
              height: 30 * uiScale,
              margin: EdgeInsets.only(top: 2 * uiScale, right: 8 * uiScale),
              decoration: BoxDecoration(
                color: colors.iconPurple,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What do you have?',
                    style: TextStyle(fontSize: 14.5 * uiScale, fontWeight: FontWeight.w800, color: colors.textPrimary),
                  ),
                  Text(
                    'Add ingredients from your pantry',
                    style: TextStyle(fontSize: 10.5 * uiScale, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onViewPantry,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_basket_rounded, size: 13 * uiScale, color: colors.iconPurple),
                  SizedBox(width: 4 * uiScale),
                  Text(
                    'View Pantry',
                    style: TextStyle(fontSize: 11.5 * uiScale, fontWeight: FontWeight.w700, color: colors.iconPurple),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 15 * uiScale, color: colors.iconPurple),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 12 * uiScale),
        SizedBox(
          height: 102 * uiScale,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length + 1,
            separatorBuilder: (_, __) => SizedBox(width: 10 * uiScale),
            itemBuilder: (context, index) {
              if (index == items.length) {
                return _AddMorePantryTile(uiScale: uiScale, onTap: onAddMore);
              }
              final item = items[index];
              return _PantryTile(
                uiScale: uiScale,
                data: item,
                onRemove: () => onRemove(index),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PantryTile extends StatelessWidget {
  const _PantryTile({required this.uiScale, required this.data, required this.onRemove});
  final double uiScale;
  final PantryChipData data;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final tileSize = 66 * uiScale;
    return SizedBox(
      width: tileSize,
      child: Column(
        children: [
          SizedBox(
            width: tileSize,
            height: tileSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _SafeAssetImage(asset: data.asset, icon: data.icon),
                ),
                Positioned(
                  top: -6,
                  right: -6,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      width: 20 * uiScale,
                      height: 20 * uiScale,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Icon(Icons.close_rounded, size: 12 * uiScale, color: _kMutedInk),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 5 * uiScale),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10.5 * uiScale, fontWeight: FontWeight.w600, color: context.dcColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _AddMorePantryTile extends StatefulWidget {
  const _AddMorePantryTile({required this.uiScale, this.onTap});
  final double uiScale;
  final VoidCallback? onTap;

  @override
  State<_AddMorePantryTile> createState() => _AddMorePantryTileState();
}

class _AddMorePantryTileState extends State<_AddMorePantryTile> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final tileSize = 66 * widget.uiScale;
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.92),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: SizedBox(
          width: tileSize,
          child: Column(
            children: [
              SizedBox(
                width: tileSize,
                height: tileSize,
                child: CustomPaint(
                  painter: _DashedRectPainter(color: _kPurple.withValues(alpha: 0.45), radius: 16),
                  child: Center(
                    child: Icon(Icons.add_rounded, color: _kPurple, size: 22 * widget.uiScale),
                  ),
                ),
              ),
              SizedBox(height: 5 * widget.uiScale),
              Text(
                'Add More',
                style: TextStyle(fontSize: 10.5 * widget.uiScale, fontWeight: FontWeight.w600, color: _kPurple),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({required this.color, this.radius = 16, this.dashWidth = 5, this.gapWidth = 4});
  final Color color;
  final double radius;
  final double dashWidth;
  final double gapWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next.clamp(0, metric.length)), paint);
        distance = next + gapWidth;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

// ---------------------------------------------------------------------------
// Craving input row
// ---------------------------------------------------------------------------
class _CravingInputRow extends StatefulWidget {
  const _CravingInputRow({required this.uiScale, required this.controller, this.onGenerate});
  final double uiScale;
  final TextEditingController controller;
  final VoidCallback? onGenerate;

  @override
  State<_CravingInputRow> createState() => _CravingInputRowState();
}

class _CravingInputRowState extends State<_CravingInputRow> with SingleTickerProviderStateMixin {
  bool _generating = false;

  Future<void> _handleGenerate() async {
    if (_generating) return;
    setState(() => _generating = true);
    widget.onGenerate?.call();
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _generating = false);
  }

  @override
Widget build(BuildContext context) {
  final uiScale = widget.uiScale;

  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
  children: [
        Expanded(
          flex: 5,
          child: _GlassContainer(
            borderRadius: 18,
            opacity: 0.75,
            padding: EdgeInsets.symmetric(horizontal: 14 * uiScale),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    style: TextStyle(fontSize: 12.5 * uiScale, color: context.dcColors.textPrimary),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'e.g., high protein breakfast',
                      hintStyle: TextStyle(fontSize: 12 * uiScale, color: context.dcColors.textMuted),
                    ),
                  ),
                ),
                Container(
                  width: 26 * uiScale,
                  height: 26 * uiScale,
                  decoration: BoxDecoration(
                    color: _kPurple,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(Icons.auto_awesome_rounded, size: 13 * uiScale, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 10 * uiScale),
        Expanded(
          flex: 7,
          child: GestureDetector(
            onTap: _handleGenerate,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10 * uiScale),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(colors: [Color(0xFF7C5CFC), _kPurple]),
                boxShadow: [
                  BoxShadow(color: _kPurple.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 8)),
                ],
              ),
              alignment: Alignment.center,
              child: _generating
                  ? SizedBox(
                      width: 16 * uiScale,
                      height: 16 * uiScale,
                      child: const CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                'Generate Recipe',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11.5 * uiScale, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ),
                            SizedBox(width: 4 * uiScale),
                            Icon(Icons.arrow_forward_rounded, size: 13 * uiScale, color: Colors.white),
                          ],
                        ),
                        Text(
                          'AI will work its magic',
                          style: TextStyle(fontSize: 8.5 * uiScale, color: Colors.white.withValues(alpha: 0.85)),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Customize section
// ---------------------------------------------------------------------------
class _CustomizeSection extends StatelessWidget {
  const _CustomizeSection({required this.uiScale, required this.options, this.onTap});
  final double uiScale;
  final List<CustomizeChipData> options;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customize your recipe',
          style: TextStyle(fontSize: 14.5 * uiScale, fontWeight: FontWeight.w800, color: colors.textPrimary),
        ),
        SizedBox(height: 10 * uiScale),
        SizedBox(
          height: 48 * uiScale,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              for (int i = 0; i < options.length; i++) ...[
                _CustomizeChip(uiScale: uiScale, data: options[i], onTap: () => onTap?.call(i)),
                SizedBox(width: 8 * uiScale),
              ],
              _FilterIconButton(uiScale: uiScale, onTap: () => onTap?.call(options.length)),
            ],
          ),
        ),
      ],
    );
  }
}

class _CustomizeChip extends StatefulWidget {
  const _CustomizeChip({required this.uiScale, required this.data, this.onTap});
  final double uiScale;
  final CustomizeChipData data;
  final VoidCallback? onTap;

  @override
  State<_CustomizeChip> createState() => _CustomizeChipState();
}

class _CustomizeChipState extends State<_CustomizeChip> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final uiScale = widget.uiScale;
    final data = widget.data;
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12 * uiScale, vertical: 8 * uiScale),
          decoration: BoxDecoration(
            color: data.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: data.color.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(data.icon, size: 13 * uiScale, color: data.color),
              SizedBox(width: 6 * uiScale),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(data.label, style: TextStyle(fontSize: 8.5 * uiScale, color: context.dcColors.textSecondary)),
                  Text(
                    data.value,
                    style: TextStyle(fontSize: 10.5 * uiScale, fontWeight: FontWeight.w700, color: context.dcColors.textPrimary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterIconButton extends StatelessWidget {
  const _FilterIconButton({required this.uiScale, this.onTap});
  final double uiScale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38 * uiScale,
        height: 38 * uiScale,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.cardBorder),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.05), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Icon(Icons.tune_rounded, size: 16 * uiScale, color: colors.textPrimary),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section title row (reusable "Title ... View All >")
// ---------------------------------------------------------------------------
class _SectionTitleRow extends StatelessWidget {
  const _SectionTitleRow({
    required this.uiScale,
    required this.title,
    this.actionLabel,
    this.onAction,
  });
  final double uiScale;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 14.5 * uiScale, fontWeight: FontWeight.w800, color: colors.textPrimary),
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel!,
                  style: TextStyle(fontSize: 11.5 * uiScale, fontWeight: FontWeight.w700, color: colors.iconPurple),
                ),
                Icon(Icons.chevron_right_rounded, size: 15 * uiScale, color: colors.iconPurple),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Recipe carousel card — image on one side, info on the other
// ---------------------------------------------------------------------------
class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.uiScale,
    required this.recipe,
    required this.saved,
    this.onView,
    this.onSave,
  });

  final double uiScale;
  final RecipeCardData recipe;
  final bool saved;
  final VoidCallback? onView;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    debugPrint('[RECIPE CARD]');
    debugPrint('title = ${recipe.title}');
    debugPrint('image = ${recipe.imageAsset}');
    debugPrint('source = ${recipe.recipeSource}');

    return _GlassContainer(
      borderRadius: 24,
      opacity: 0.7,
      padding: EdgeInsets.all(10 * uiScale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image side
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _SafeAssetImage(
                      asset: recipe.imageAsset,
                      icon: Icons.ramen_dining_rounded,
                    ),
                  ),
                ),
                if (recipe.recommended)
                  Positioned(
                    top: 8 * uiScale,
                    left: 8 * uiScale,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8 * uiScale, vertical: 5 * uiScale),
                      decoration: BoxDecoration(
                        color: _kPurple,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, size: 11 * uiScale, color: Colors.white),
                          SizedBox(width: 3 * uiScale),
                          Text(
                            'Recommended',
                            style: TextStyle(fontSize: 8.5 * uiScale, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 10 * uiScale),
          // Info side
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        recipe.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13.5 * uiScale, fontWeight: FontWeight.w800, color: context.dcColors.textPrimary, height: 1.15),
                      ),
                    ),
                    SizedBox(width: 4 * uiScale),
                    Icon(Icons.eco_rounded, size: 13 * uiScale, color: context.dcColors.iconGreen),
                  ],
                ),
                SizedBox(height: 4 * uiScale),
                Text(
                  recipe.tagline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9.5 * uiScale, fontWeight: FontWeight.w600, color: context.dcColors.iconPurple),
                ),
                SizedBox(height: 6 * uiScale),
                Text(
                  recipe.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9.5 * uiScale, height: 1.3, color: context.dcColors.textSecondary),
                ),
                SizedBox(height: 8 * uiScale),
                Wrap(
                  spacing: 6 * uiScale,
                  runSpacing: 6 * uiScale,
                  children: [
                    _StatChip(uiScale: uiScale, icon: Icons.access_time_rounded, label: '${recipe.timeMinutes} min', color: _kPurple),
                    _StatChip(uiScale: uiScale, icon: Icons.local_fire_department_rounded, label: '${recipe.kcal} kcal', color: _kOrange),
                    _StatChip(uiScale: uiScale, icon: Icons.fitness_center_rounded, label: '${recipe.proteinGrams}g Protein', color: _kGreen),
                  ],
                ),
                SizedBox(height: 10 * uiScale),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onView,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 8 * uiScale),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _kPurple.withValues(alpha: 0.35)),
                          ),
                          alignment: Alignment.center,
                          child: FittedBox(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.open_in_new_rounded, size: 11 * uiScale, color: _kPurple),
                                SizedBox(width: 4 * uiScale),
                                Text(
                                  'View Recipe',
                                  style: TextStyle(fontSize: 9.5 * uiScale, fontWeight: FontWeight.w700, color: _kPurple),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8 * uiScale),
                    Expanded(
                      child: GestureDetector(
                        onTap: onSave,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: EdgeInsets.symmetric(vertical: 8 * uiScale),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: saved
                                  ? [_kGreen, const Color(0xFF166B3B)]
                                  : [const Color(0xFF7C5CFC), _kPurple],
                            ),
                          ),
                          alignment: Alignment.center,
                          child: FittedBox(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                  size: 11 * uiScale,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4 * uiScale),
                                Text(
                                  saved ? 'Saved' : 'Save Recipe',
                                  style: TextStyle(fontSize: 9.5 * uiScale, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.uiScale, required this.icon, required this.label, required this.color});
  final double uiScale;
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7 * uiScale, vertical: 4 * uiScale),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10 * uiScale, color: color),
          SizedBox(width: 3 * uiScale),
          Text(label, style: TextStyle(fontSize: 8.5 * uiScale, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.uiScale, required this.count, required this.page});
  final double uiScale;
  final int count;
  final double page;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final delta = (page - i).abs().clamp(0.0, 1.0);
        final active = 1 - delta;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: EdgeInsets.symmetric(horizontal: 3 * uiScale),
          width: (6 + active * 12) * uiScale,
          height: 6 * uiScale,
          decoration: BoxDecoration(
            color: Color.lerp(const Color(0xFFDCD5F5), _kPurple, active),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// What's in this recipe?
// ---------------------------------------------------------------------------
class _WhatsInRecipeSection extends StatelessWidget {
  const _WhatsInRecipeSection({required this.uiScale, required this.recipe});
  final double uiScale;
  final RecipeCardData recipe;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What's in this recipe?",
          style: TextStyle(fontSize: 14.5 * uiScale, fontWeight: FontWeight.w800, color: colors.textPrimary),
        ),
        SizedBox(height: 10 * uiScale),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Wrap(
            key: ValueKey(recipe.title),
            spacing: 8 * uiScale,
            runSpacing: 8 * uiScale,
            children: [
              for (final tag in recipe.whatsInside)
                _WhatsInChip(uiScale: uiScale, tag: tag),
            ],
          ),
        ),
      ],
    );
  }
}

class _WhatsInChip extends StatelessWidget {
  const _WhatsInChip({required this.uiScale, required this.tag});
  final double uiScale;
  final WhatsInTag tag;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 36 * uiScale - 8 * uiScale) / 2;
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 10 * uiScale, vertical: 10 * uiScale),
      decoration: BoxDecoration(
        color: tag.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tag.color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(tag.icon, size: 15 * uiScale, color: tag.color),
          SizedBox(width: 7 * uiScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tag.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5 * uiScale, fontWeight: FontWeight.w700, color: context.dcColors.textPrimary),
                ),
                Text(
                  tag.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 8.5 * uiScale, color: context.dcColors.textSecondary),
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
// More ideas for you
// ---------------------------------------------------------------------------
class _MoreIdeasSection extends StatelessWidget {
  const _MoreIdeasSection({
    required this.uiScale,
    required this.ideas,
    required this.bookmarked,
    required this.onToggleBookmark,
  });

  final double uiScale;
  final List<MoreIdeaData> ideas;
  final Set<int> bookmarked;
  final ValueChanged<int> onToggleBookmark;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'More ideas for you',
          style: TextStyle(fontSize: 14.5 * uiScale, fontWeight: FontWeight.w800, color: colors.textPrimary),
        ),
        SizedBox(height: 12 * uiScale),
        SizedBox(
          height: 148 * uiScale,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: ideas.length,
            separatorBuilder: (_, __) => SizedBox(width: 12 * uiScale),
            itemBuilder: (context, index) {
              final idea = ideas[index];
              return _MoreIdeaCard(
                uiScale: uiScale,
                idea: idea,
                bookmarked: bookmarked.contains(index),
                onToggleBookmark: () => onToggleBookmark(index),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MoreIdeaCard extends StatelessWidget {
  const _MoreIdeaCard({
    required this.uiScale,
    required this.idea,
    required this.bookmarked,
    required this.onToggleBookmark,
  });

  final double uiScale;
  final MoreIdeaData idea;
  final bool bookmarked;
  final VoidCallback onToggleBookmark;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Container(
      width: 118 * uiScale,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.05), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: _SafeAssetImage(asset: idea.imageAsset, icon: Icons.restaurant_rounded),
                  ),
                ),
                Positioned(
                  top: 6 * uiScale,
                  right: 6 * uiScale,
                  child: GestureDetector(
                    onTap: onToggleBookmark,
                    child: Container(
                      width: 22 * uiScale,
                      height: 22 * uiScale,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(
                        bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        size: 12 * uiScale,
                        color: _kPurple,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(8 * uiScale, 6 * uiScale, 8 * uiScale, 8 * uiScale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  idea.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5 * uiScale, fontWeight: FontWeight.w700, color: colors.textPrimary),
                ),
                SizedBox(height: 3 * uiScale),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time_rounded, size: 9 * uiScale, color: colors.iconPurple),
                      SizedBox(width: 2 * uiScale),
                      Text('${idea.timeMinutes} min', style: TextStyle(fontSize: 8.5 * uiScale, color: colors.textSecondary)),
                      SizedBox(width: 6 * uiScale),
                      Icon(Icons.local_fire_department_rounded, size: 9 * uiScale, color: colors.iconOrange),
                      SizedBox(width: 2 * uiScale),
                      Text('${idea.kcal} kcal', style: TextStyle(fontSize: 8.5 * uiScale, color: colors.textSecondary)),
                    ],
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
// Meal plan banner
// ---------------------------------------------------------------------------
class _MealPlanBanner extends StatelessWidget {
  const _MealPlanBanner({required this.uiScale, required this.ambientCtrl, this.onCreateMealPlan});
  final double uiScale;
  final AnimationController ambientCtrl;
  final VoidCallback? onCreateMealPlan;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Container(
      padding: EdgeInsets.all(14 * uiScale),
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
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
            child: _RobotAvatar(uiScale: uiScale),
          ),
          SizedBox(width: 10 * uiScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Want personalized weekly meal plans?',
                  style: TextStyle(fontSize: 12.5 * uiScale, fontWeight: FontWeight.w800, color: colors.iconPurple),
                ),
                SizedBox(height: 2 * uiScale),
                Text(
                  'Let AI create a complete plan based on your goals, preferences and pantry.',
                  style: TextStyle(fontSize: 10 * uiScale, height: 1.3, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          SizedBox(width: 8 * uiScale),
          _CreateMealPlanButton(uiScale: uiScale, onTap: onCreateMealPlan),
        ],
      ),
    );
  }
}

class _CreateMealPlanButton extends StatefulWidget {
  const _CreateMealPlanButton({required this.uiScale, this.onTap});
  final double uiScale;
  final VoidCallback? onTap;

  @override
  State<_CreateMealPlanButton> createState() => _CreateMealPlanButtonState();
}

class _CreateMealPlanButtonState extends State<_CreateMealPlanButton> {
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
          padding: EdgeInsets.symmetric(horizontal: 12 * widget.uiScale, vertical: 10 * widget.uiScale),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(colors: [_kPurple, _kGreen]),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_month_rounded, color: Colors.white, size: 13 * widget.uiScale),
              SizedBox(width: 4 * widget.uiScale),
              Text(
                'Create Meal Plan',
                style: TextStyle(color: Colors.white, fontSize: 10.5 * widget.uiScale, fontWeight: FontWeight.w700),
              ),
              SizedBox(width: 4 * widget.uiScale),
              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12 * widget.uiScale),
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
    (icon: Icons.crop_free_rounded, label: 'Scan'),
    (icon: Icons.shopping_basket_rounded, label: 'Pantry'),
    (icon: Icons.restaurant_menu_rounded, label: 'Recipes'),
    (icon: Icons.person_outline_rounded, label: 'AI Coach'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.fromLTRB(14 * uiScale, 0, 14 * uiScale, 10 * uiScale),
        padding: EdgeInsets.symmetric(vertical: 8 * uiScale),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.cardBorder),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: colors.isDark ? 0.25 : 0.08), blurRadius: 20, offset: const Offset(0, 8)),
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
                  color: selected ? (colors.isDark ? const Color(0xFF2B264A) : const Color(0xFFF1ECFB)) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 20 * uiScale,
                      color: selected ? colors.iconPurple : colors.textMuted,
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      child: selected
                          ? Padding(
                              padding: EdgeInsets.only(top: 3 * uiScale),
                              child: Text(
                                item.label,
                                style: TextStyle(fontSize: 9.5 * uiScale, fontWeight: FontWeight.w700, color: colors.iconPurple),
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

class _ProductSourceBanner extends StatelessWidget {
  const _ProductSourceBanner({
    required this.uiScale,
    required this.product,
  });

  final double uiScale;
  final FoodProduct product;

  @override
  Widget build(BuildContext context) {
    return _GlassContainer(
      borderRadius: 20,
      opacity: 0.82,
      padding: EdgeInsets.symmetric(horizontal: 14 * uiScale, vertical: 12 * uiScale),
      child: Row(
        children: [
          Container(
            width: 40 * uiScale,
            height: 40 * uiScale,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B6EF6), _kPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _kPurple.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(Icons.auto_awesome_rounded, size: 20 * uiScale, color: Colors.white),
          ),
          SizedBox(width: 12 * uiScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6 * uiScale, vertical: 2 * uiScale),
                      decoration: BoxDecoration(
                        color: _kGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'USING PRODUCT',
                        style: TextStyle(
                          fontSize: 8.5 * uiScale,
                          fontWeight: FontWeight.w800,
                          color: _kGreen,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (product.brand.isNotEmpty) ...[
                      SizedBox(width: 6 * uiScale),
                      Flexible(
                        child: Text(
                          product.brand,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5 * uiScale,
                            fontWeight: FontWeight.w600,
                            color: _kMutedInk,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 3 * uiScale),
                Text(
                  'Recipe with ${product.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13 * uiScale,
                    fontWeight: FontWeight.w800,
                    color: context.dcColors.textPrimary,
                  ),
                ),
                Text(
                  'AI is creating healthy recipes using this product',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10 * uiScale,
                    color: context.dcColors.textSecondary,
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

