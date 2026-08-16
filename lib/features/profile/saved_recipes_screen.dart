import 'dart:ui';

import 'package:flutter/material.dart';

/// DietCompass — Saved Recipes Screen
/// -----------------------------------------------------------------------
/// Matches the visual language of the rest of the app: lavender background
/// (0xFFF3F0FB), purple → green brand accents, frosted glassmorphism
/// cards/pills, staggered entrance choreography, and a per-card reveal
/// animation as recipes scroll into view. Bookmark buttons pop on tap.
///
/// Recipe photos are optional — pass an `imageAsset` per RecipeItem and it
/// will render via Image.asset with a graceful colour-tinted icon fallback
/// if the asset isn't found yet, so the screen works before you wire in
/// real photography.
class RecipeItem {
  const RecipeItem({
    required this.title,
    required this.tags,
    required this.timeMinutes,
    required this.kcal,
    required this.proteinG,
    required this.savedLabel,
    this.imageAsset,
    this.isVegetarian = true,
    this.isBookmarked = true,
  });

  final String title;
  final String tags;
  final int timeMinutes;
  final int kcal;
  final int proteinG;
  final String savedLabel;
  final String? imageAsset;
  final bool isVegetarian;
  final bool isBookmarked;
}

class CategoryTab {
  const CategoryTab({required this.icon, required this.label, required this.count});
  final IconData icon;
  final String label;
  final int count;
}

class SavedRecipesScreen extends StatefulWidget {
  SavedRecipesScreen({
    super.key,
    List<RecipeItem>? recipes,
    this.onBack,
    this.onSearchTap,
    this.onRecipeTap,
    this.onRecipeMenuTap,
    this.onBookmarkToggle,
    this.onFilterTap,
  }) : recipes = recipes ?? _defaultRecipes;

  final List<RecipeItem> recipes;
  final VoidCallback? onBack;
  final VoidCallback? onSearchTap;
  final ValueChanged<RecipeItem>? onRecipeTap;
  final ValueChanged<RecipeItem>? onRecipeMenuTap;
  final void Function(RecipeItem recipe, bool bookmarked)? onBookmarkToggle;
  final VoidCallback? onFilterTap;

  static const _defaultRecipes = [
    RecipeItem(
      title: 'Banana Oats Power Bowl',
      tags: 'Healthy • Quick • Delicious',
      timeMinutes: 15,
      kcal: 320,
      proteinG: 12,
      savedLabel: 'Saved today',
      imageAsset: 'assets/images/recipe_banana_oats_power_bowl.jpeg',
    ),
    RecipeItem(
      title: 'Apple Cinnamon Oatmeal',
      tags: 'Warm • Comforting • Wholesome',
      timeMinutes: 12,
      kcal: 310,
      proteinG: 9,
      savedLabel: 'Saved 1 day ago',
      imageAsset: 'assets/images/recipe_apple_cinnamon_oatmeal.jpeg',
    ),
    RecipeItem(
      title: 'Quinoa Veggie Salad',
      tags: 'Healthy • Light • Refreshing',
      timeMinutes: 20,
      kcal: 280,
      proteinG: 10,
      savedLabel: 'Saved 2 days ago',
      imageAsset: 'assets/images/quinoa_veggie_salad.jpeg',
    ),
    RecipeItem(
      title: 'Chickpea Curry with Rice',
      tags: 'Hearty • Spicy • Comforting',
      timeMinutes: 25,
      kcal: 450,
      proteinG: 15,
      savedLabel: 'Saved 4 days ago',
      imageAsset: 'assets/images/chickpea_curry.jpeg',
    ),
    RecipeItem(
      title: 'Berry Banana Smoothie',
      tags: 'Quick • Healthy • Energizing',
      timeMinutes: 5,
      kcal: 210,
      proteinG: 6,
      savedLabel: 'Saved 5 days ago',
      imageAsset: 'assets/images/berry_banana_smoothie.jpeg',
    ),
    RecipeItem(
      title: 'Avocado Egg Toast',
      tags: 'High Protein • Quick • Filling',
      timeMinutes: 10,
      kcal: 350,
      proteinG: 14,
      savedLabel: 'Saved 1 week ago',
      imageAsset: 'assets/images/avocado_egg_toast.jpeg',
    ),
  ];

  @override
  State<SavedRecipesScreen> createState() => _SavedRecipesScreenState();
}

class _SavedRecipesScreenState extends State<SavedRecipesScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  int _selectedCategory = 0;
  String _sortLabel = 'Recently Added';

  static const _categories = [
    CategoryTab(icon: Icons.bookmark_rounded, label: 'All Recipes', count: 24),
    CategoryTab(icon: Icons.wb_sunny_rounded, label: 'Breakfast', count: 8),
    CategoryTab(icon: Icons.ramen_dining_rounded, label: 'Lunch', count: 6),
    CategoryTab(icon: Icons.nightlight_round, label: 'Dinner', count: 7),
    CategoryTab(icon: Icons.cookie_rounded, label: 'Snacks', count: 3),
  ];

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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

  void _handleSortSelected(String value) => setState(() => _sortLabel = value);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 390).clamp(0.85, 1.25);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FB),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _GlassBackdrop(uiScale: scale),
          SafeArea(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(18 * scale, 8 * scale, 18 * scale, 24 * scale),
              physics: const BouncingScrollPhysics(),
              itemCount: widget.recipes.length + 4,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return FadeTransition(
                    opacity: _fade(0.0, 0.3),
                    child: SlideTransition(
                      position: _slide(0.0, 0.34),
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 16 * scale),
                        child: _TopHeader(
                          uiScale: scale,
                          onBack: widget.onBack,
                          onSearchTap: widget.onSearchTap,
                        ),
                      ),
                    ),
                  );
                }
                if (index == 1) {
                  return FadeTransition(
                    opacity: _fade(0.08, 0.38),
                    child: SlideTransition(
                      position: _slide(0.08, 0.42),
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 14 * scale),
                        child: _CategoryTabsRow(
                          uiScale: scale,
                          categories: _categories,
                          selectedIndex: _selectedCategory,
                          onSelected: (i) => setState(() => _selectedCategory = i),
                        ),
                      ),
                    ),
                  );
                }
                if (index == 2) {
                  return FadeTransition(
                    opacity: _fade(0.14, 0.42),
                    child: SlideTransition(
                      position: _slide(0.14, 0.46),
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 4 * scale),
                        child: _SortFilterRow(
                          uiScale: scale,
                          sortLabel: _sortLabel,
                          onSortSelected: _handleSortSelected,
                          onFilterTap: widget.onFilterTap,
                        ),
                      ),
                    ),
                  );
                }
                if (index == 3) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 10 * scale),
                    child: Divider(height: 1, color: const Color(0xFFE1DAF2)),
                  );
                }

                final recipeIndex = index - 4;
                final recipe = widget.recipes[recipeIndex];
                return Padding(
                  padding: EdgeInsets.only(bottom: 14 * scale),
                  child: _RecipeCard(
                    uiScale: scale,
                    index: recipeIndex,
                    recipe: recipe,
                    onTap: () => widget.onRecipeTap?.call(recipe),
                    onMenuTap: () => widget.onRecipeMenuTap?.call(recipe),
                    onBookmarkToggle: (v) => widget.onBookmarkToggle?.call(recipe, v),
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

// ---------------------------------------------------------------------------
// Ambient glass backdrop — soft blurred colour blobs
// ---------------------------------------------------------------------------
class _GlassBackdrop extends StatefulWidget {
  const _GlassBackdrop({required this.uiScale});
  final double uiScale;

  @override
  State<_GlassBackdrop> createState() => _GlassBackdropState();
}

class _GlassBackdropState extends State<_GlassBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
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
            Positioned(
              top: -80 + t * 14,
              right: -60,
              child: _blob(210 * uiScale, const Color(0xFF6C4EF5)),
            ),
            Positioned(
              bottom: -60 + t * 12,
              left: -60,
              child: _blob(180 * uiScale, const Color(0xFF1E8A4C)),
            ),
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.16),
            ),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Reusable frosted glass container
// ---------------------------------------------------------------------------
class _Glass extends StatelessWidget {
  const _Glass({
    required this.uiScale,
    required this.child,
    this.padding,
    this.radius = 20,
    this.color,
    this.borderColor,
  });
  final double uiScale;
  final Widget child;
  final EdgeInsets? padding;
  final double radius;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (color ?? Colors.white).withValues(alpha: color == null ? 0.68 : 0.9),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor ?? Colors.white.withValues(alpha: 0.8), width: 1.1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C4EF5).withValues(alpha: 0.07),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Generic press-scale wrapper
// ---------------------------------------------------------------------------
class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, this.onTap, this.minScale = 0.95});
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
// Top header — back, title with bookmark icon + subtitle, search
// ---------------------------------------------------------------------------
class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.uiScale, this.onBack, this.onSearchTap});
  final double uiScale;
  final VoidCallback? onBack;
  final VoidCallback? onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Pressable(
          onTap: onBack ?? () => Navigator.maybePop(context),
          child: _RoundGlassIcon(uiScale: uiScale, icon: Icons.arrow_back_rounded),
        ),
        Expanded(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_rounded, size: 17 * uiScale, color: const Color(0xFF6C4EF5)),
                  SizedBox(width: 6 * uiScale),
                  Text(
                    'Saved Recipes',
                    style: TextStyle(
                      fontSize: 18 * uiScale,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1B1B2E),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2 * uiScale),
              Text(
                'Your favorite recipes, all in one place',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5 * uiScale, color: const Color(0xFF6B6B7B)),
              ),
            ],
          ),
        ),
        _Pressable(
          onTap: onSearchTap,
          child: _RoundGlassIcon(uiScale: uiScale, icon: Icons.search_rounded),
        ),
      ],
    );
  }
}

class _RoundGlassIcon extends StatelessWidget {
  const _RoundGlassIcon({required this.uiScale, required this.icon});
  final double uiScale;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42 * uiScale,
      height: 42 * uiScale,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Icon(icon, size: 19 * uiScale, color: const Color(0xFF1B1B2E)),
    );
  }
}

// ---------------------------------------------------------------------------
// Category tabs — horizontal scroll, animated selection
// ---------------------------------------------------------------------------
class _CategoryTabsRow extends StatelessWidget {
  const _CategoryTabsRow({
    required this.uiScale,
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });
  final double uiScale;
  final List<CategoryTab> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 74 * uiScale,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) => SizedBox(width: 10 * uiScale),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final selected = i == selectedIndex;
          return _Pressable(
            onTap: () => onSelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(horizontal: 16 * uiScale, vertical: 10 * uiScale),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(colors: [Color(0xFF6C4EF5), Color(0xFF8467F8)])
                    : null,
                color: selected ? null : Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(18),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF6C4EF5).withValues(alpha: 0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(cat.icon,
                          size: 14 * uiScale, color: selected ? Colors.white : const Color(0xFF6C4EF5)),
                      SizedBox(width: 6 * uiScale),
                      Text(
                        cat.label,
                        style: TextStyle(
                          fontSize: 12 * uiScale,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : const Color(0xFF1B1B2E),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4 * uiScale),
                  Text(
                    '${cat.count}',
                    style: TextStyle(
                      fontSize: 11.5 * uiScale,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF6B6B7B),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sort by / Filter row
// ---------------------------------------------------------------------------
class _SortFilterRow extends StatelessWidget {
  const _SortFilterRow({
    required this.uiScale,
    required this.sortLabel,
    required this.onSortSelected,
    this.onFilterTap,
  });
  final double uiScale;
  final String sortLabel;
  final ValueChanged<String> onSortSelected;
  final VoidCallback? onFilterTap;

  static const _sortOptions = [
    'Recently Added',
    'A–Z',
    'Quickest First',
    'Lowest Calories',
    'Highest Protein',
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: PopupMenuButton<String>(
            onSelected: onSortSelected,
            offset: Offset(0, 44 * uiScale),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            itemBuilder: (context) => _sortOptions
                .map((o) => PopupMenuItem(value: o, child: Text(o, style: TextStyle(fontSize: 12.5 * uiScale))))
                .toList(),
            child: Row(
              children: [
                Text(
                  'Sort by: ',
                  style: TextStyle(fontSize: 12 * uiScale, color: const Color(0xFF6B6B7B)),
                ),
                Flexible(
                  child: Text(
                    sortLabel,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12 * uiScale,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF6C4EF5),
                    ),
                  ),
                ),
                Icon(Icons.expand_more_rounded, size: 16 * uiScale, color: const Color(0xFF6C4EF5)),
              ],
            ),
          ),
        ),
        _Pressable(
          onTap: onFilterTap,
          child: _Glass(
            uiScale: uiScale,
            radius: 16,
            padding: EdgeInsets.symmetric(horizontal: 14 * uiScale, vertical: 9 * uiScale),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune_rounded, size: 15 * uiScale, color: const Color(0xFF1B1B2E)),
                SizedBox(width: 6 * uiScale),
                Text(
                  'Filter',
                  style: TextStyle(
                    fontSize: 12 * uiScale,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B1B2E),
                  ),
                ),
                Icon(Icons.expand_more_rounded, size: 15 * uiScale, color: const Color(0xFF1B1B2E)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Recipe card — reveals with a staggered fade/slide as it enters the list
// ---------------------------------------------------------------------------
class _RecipeCard extends StatefulWidget {
  const _RecipeCard({
    required this.uiScale,
    required this.index,
    required this.recipe,
    this.onTap,
    this.onMenuTap,
    this.onBookmarkToggle,
  });

  final double uiScale;
  final int index;
  final RecipeItem recipe;
  final VoidCallback? onTap;
  final VoidCallback? onMenuTap;
  final ValueChanged<bool>? onBookmarkToggle;

  @override
  State<_RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<_RecipeCard> with TickerProviderStateMixin {
  late final AnimationController _revealCtrl;
  late bool _bookmarked;

  @override
  void initState() {
    super.initState();
    _bookmarked = widget.recipe.isBookmarked;
    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    final delay = Duration(milliseconds: 60 * (widget.index % 6));
    Future.delayed(delay, () {
      if (mounted) _revealCtrl.forward();
    });
  }

  @override
  void dispose() {
    _revealCtrl.dispose();
    super.dispose();
  }

  void _toggleBookmark() {
    setState(() => _bookmarked = !_bookmarked);
    widget.onBookmarkToggle?.call(_bookmarked);
  }

  @override
  Widget build(BuildContext context) {
    final uiScale = widget.uiScale;
    final recipe = widget.recipe;

    return FadeTransition(
      opacity: CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOutCubic)),
        child: _Pressable(
          onTap: widget.onTap,
          minScale: 0.98,
          child: _Glass(
            uiScale: uiScale,
            radius: 20,
            padding: EdgeInsets.all(10 * uiScale),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 80 * uiScale,
                    height: 80 * uiScale,
                    child: recipe.imageAsset != null
                        ? Image.asset(
                            recipe.imageAsset!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imageFallback(uiScale),
                          )
                        : _imageFallback(uiScale),
                  ),
                ),
                SizedBox(width: 12 * uiScale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    recipe.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13.5 * uiScale,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1B1B2E),
                                    ),
                                  ),
                                ),
                                if (recipe.isVegetarian) ...[
                                  SizedBox(width: 4 * uiScale),
                                  Icon(Icons.eco_rounded,
                                      size: 12 * uiScale, color: const Color(0xFF1E8A4C)),
                                ],
                              ],
                            ),
                          ),
                          _Pressable(
                            onTap: widget.onMenuTap,
                            child: Icon(Icons.more_vert_rounded,
                                size: 17 * uiScale, color: const Color(0xFFB0ACC2)),
                          ),
                        ],
                      ),
                      SizedBox(height: 2 * uiScale),
                      Text(
                        recipe.tags,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5 * uiScale,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF6C4EF5),
                        ),
                      ),
                      SizedBox(height: 8 * uiScale),
                      Wrap(
                        spacing: 6 * uiScale,
                        runSpacing: 6 * uiScale,
                        children: [
                          _MetaPill(
                            uiScale: uiScale,
                            icon: Icons.access_time_rounded,
                            iconColor: const Color(0xFF6C4EF5),
                            label: '${recipe.timeMinutes} min',
                          ),
                          _MetaPill(
                            uiScale: uiScale,
                            icon: Icons.local_fire_department_rounded,
                            iconColor: const Color(0xFFE0862E),
                            label: '${recipe.kcal} kcal',
                          ),
                          _MetaPill(
                            uiScale: uiScale,
                            icon: Icons.eco_rounded,
                            iconColor: const Color(0xFF1E8A4C),
                            label: '${recipe.proteinG}g Protein',
                          ),
                        ],
                      ),
                      SizedBox(height: 8 * uiScale),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 11 * uiScale, color: const Color(0xFFB0ACC2)),
                          SizedBox(width: 5 * uiScale),
                          Text(
                            recipe.savedLabel,
                            style: TextStyle(fontSize: 10.5 * uiScale, color: const Color(0xFF6B6B7B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 6 * uiScale),
                GestureDetector(
                  onTap: _toggleBookmark,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1, end: _bookmarked ? 1.15 : 1.0),
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.elasticOut,
                    builder: (context, val, child) => Transform.scale(scale: val, child: child),
                    child: Container(
                      width: 32 * uiScale,
                      height: 32 * uiScale,
                      decoration: BoxDecoration(
                        color: _bookmarked ? const Color(0xFF6C4EF5) : const Color(0xFFEDE7FA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.bookmark_rounded,
                        size: 16 * uiScale,
                        color: _bookmarked ? Colors.white : const Color(0xFF6C4EF5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imageFallback(double uiScale) => Container(
        color: const Color(0xFFEDE7FA),
        alignment: Alignment.center,
        child: Icon(Icons.restaurant_rounded, size: 28 * uiScale, color: const Color(0xFF6C4EF5)),
      );
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.uiScale,
    required this.icon,
    required this.iconColor,
    required this.label,
  });
  final double uiScale;
  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * uiScale, vertical: 5 * uiScale),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0FB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11 * uiScale, color: iconColor),
          SizedBox(width: 4 * uiScale),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5 * uiScale,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1B1B2E),
            ),
          ),
        ],
      ),
    );
  }
}
