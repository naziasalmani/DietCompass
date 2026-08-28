import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/model/recipe_history_item.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/recipe_history_service.dart';
import '../recipe_generator/recipe_detail_screen.dart';
import '../recipe_generator/recipe_generator_screen.dart';

/// DietCompass — Saved Recipes Screen
/// -----------------------------------------------------------------------
/// Displays actual saved recipes for the authenticated user, synchronized with
/// backend RecipeHistory and RecipeHistoryService.
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
    this.historyItem,
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
  final RecipeHistoryItem? historyItem;

  factory RecipeItem.fromHistoryItem(RecipeHistoryItem h) {
    String label = 'Saved recently';
    final now = DateTime.now();
    final diff = now.difference(h.generatedAt);
    if (diff.inDays == 0 && now.day == h.generatedAt.day) {
      label = 'Saved today';
    } else if (diff.inDays <= 1) {
      label = 'Saved yesterday';
    } else if (diff.inDays < 7) {
      label = 'Saved ${diff.inDays} days ago';
    } else {
      label = 'Saved earlier';
    }

    return RecipeItem(
      title: h.title,
      tags: h.tagsLabel,
      timeMinutes: h.timeMinutes,
      kcal: h.calories?.toInt() ?? 300,
      proteinG: h.protein?.toInt() ?? 10,
      savedLabel: label,
      imageAsset: h.imageUrl.isNotEmpty ? h.imageUrl : null,
      isVegetarian: h.isVegetarian,
      isBookmarked: h.isBookmarked,
      historyItem: h,
    );
  }
}

class CategoryTab {
  const CategoryTab({required this.icon, required this.label, required this.count});
  final IconData icon;
  final String label;
  final int count;
}

class SavedRecipesScreen extends StatefulWidget {
  const SavedRecipesScreen({
    super.key,
    this.recipes,
    this.onBack,
    this.onSearchTap,
    this.onRecipeTap,
    this.onRecipeMenuTap,
    this.onBookmarkToggle,
    this.onFilterTap,
  });

  final List<RecipeItem>? recipes;
  final VoidCallback? onBack;
  final VoidCallback? onSearchTap;
  final ValueChanged<RecipeItem>? onRecipeTap;
  final ValueChanged<RecipeItem>? onRecipeMenuTap;
  final void Function(RecipeItem recipe, bool bookmarked)? onBookmarkToggle;
  final VoidCallback? onFilterTap;

  @override
  State<SavedRecipesScreen> createState() => _SavedRecipesScreenState();
}

class _SavedRecipesScreenState extends State<SavedRecipesScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  int _selectedCategory = 0;
  String _sortLabel = 'Recently Added';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _loadSavedRecipes();
  }

  Future<void> _loadSavedRecipes() async {
    if (widget.recipes == null) {
      setState(() => _isLoading = true);
      await RecipeHistoryService.instance.getRecipeHistory(tab: 'saved');
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

  void _handleSortSelected(String value) => setState(() => _sortLabel = value);

  List<RecipeItem> _buildRecipeList(List<RecipeHistoryItem> savedHistory) {
    if (widget.recipes != null) {
      return widget.recipes!;
    }
    return savedHistory.map((h) => RecipeItem.fromHistoryItem(h)).toList();
  }

  List<RecipeItem> _filterAndSort(List<RecipeItem> items) {
    var result = List<RecipeItem>.from(items);

    // 1. Category Filter
    if (_selectedCategory == 1) {
      result = result.where((r) {
        final t = r.tags.toLowerCase();
        final title = r.title.toLowerCase();
        return t.contains('breakfast') || title.contains('oat') || title.contains('egg') || title.contains('pancake');
      }).toList();
    } else if (_selectedCategory == 2) {
      result = result.where((r) {
        final t = r.tags.toLowerCase();
        final title = r.title.toLowerCase();
        return t.contains('lunch') || title.contains('salad') || title.contains('rice') || title.contains('pasta') || title.contains('curry');
      }).toList();
    } else if (_selectedCategory == 3) {
      result = result.where((r) {
        final t = r.tags.toLowerCase();
        final title = r.title.toLowerCase();
        return t.contains('dinner') || title.contains('stew') || title.contains('soup') || title.contains('roast');
      }).toList();
    } else if (_selectedCategory == 4) {
      result = result.where((r) {
        final t = r.tags.toLowerCase();
        final title = r.title.toLowerCase();
        return t.contains('snack') || title.contains('smoothie') || title.contains('bites') || title.contains('bar');
      }).toList();
    }

    // 2. Sorting
    switch (_sortLabel) {
      case 'A–Z':
        result.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Quickest First':
        result.sort((a, b) => a.timeMinutes.compareTo(b.timeMinutes));
        break;
      case 'Lowest Calories':
        result.sort((a, b) => a.kcal.compareTo(b.kcal));
        break;
      case 'Highest Protein':
        result.sort((a, b) => b.proteinG.compareTo(a.proteinG));
        break;
      case 'Recently Added':
      default:
        // Preserves natural order from newest to oldest
        break;
    }

    return result;
  }

  void _onRecipeClicked(RecipeItem recipe) {
    if (widget.onRecipeTap != null) {
      widget.onRecipeTap!(recipe);
    } else if (recipe.historyItem != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(recipe: recipe.historyItem!.toRecipe()),
        ),
      );
    }
  }

  void _onBookmarkClicked(RecipeItem recipe, bool isBookmarked) {
    if (recipe.historyItem != null) {
      RecipeHistoryService.instance.toggleBookmark(recipe.historyItem!, isBookmarked);
    }
    widget.onBookmarkToggle?.call(recipe, isBookmarked);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 390).clamp(0.85, 1.25);
    final userId = AuthService.instance.currentUser?.id ?? 'guest_user';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FB),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _GlassBackdrop(uiScale: scale),
          SafeArea(
            child: ListenableBuilder(
              listenable: RecipeHistoryService.instance,
              builder: (context, _) {
                final savedHistory = RecipeHistoryService.instance.savedRecipes;
                final allRecipes = _buildRecipeList(savedHistory);

                debugPrint('\n==============================================');
                debugPrint('[SAVED RECIPES PROFILE TRACE]');
                debugPrint('userId = $userId');
                debugPrint('savedRecipeCount = ${allRecipes.length}');
                debugPrint('recipeTitles = [${allRecipes.map((r) => r.title).join(', ')}]');
                debugPrint('==============================================\n');

                final categories = [
                  CategoryTab(icon: Icons.bookmark_rounded, label: 'All Recipes', count: allRecipes.length),
                  CategoryTab(
                    icon: Icons.wb_sunny_rounded,
                    label: 'Breakfast',
                    count: allRecipes.where((r) => r.tags.toLowerCase().contains('breakfast') || r.title.toLowerCase().contains('oat') || r.title.toLowerCase().contains('egg')).length,
                  ),
                  CategoryTab(
                    icon: Icons.ramen_dining_rounded,
                    label: 'Lunch',
                    count: allRecipes.where((r) => r.tags.toLowerCase().contains('lunch') || r.title.toLowerCase().contains('salad') || r.title.toLowerCase().contains('rice') || r.title.toLowerCase().contains('pasta')).length,
                  ),
                  CategoryTab(
                    icon: Icons.nightlight_round,
                    label: 'Dinner',
                    count: allRecipes.where((r) => r.tags.toLowerCase().contains('dinner') || r.title.toLowerCase().contains('curry') || r.title.toLowerCase().contains('stew')).length,
                  ),
                  CategoryTab(
                    icon: Icons.cookie_rounded,
                    label: 'Snacks',
                    count: allRecipes.where((r) => r.tags.toLowerCase().contains('snack') || r.title.toLowerCase().contains('smoothie') || r.title.toLowerCase().contains('pudding')).length,
                  ),
                ];

                final filteredRecipes = _filterAndSort(allRecipes);

                return ListView(
                  padding: EdgeInsets.fromLTRB(18 * scale, 8 * scale, 18 * scale, 24 * scale),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    FadeTransition(
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
                    ),

                    if (allRecipes.isNotEmpty) ...[
                      FadeTransition(
                        opacity: _fade(0.08, 0.38),
                        child: SlideTransition(
                          position: _slide(0.08, 0.42),
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 14 * scale),
                            child: _CategoryTabsRow(
                              uiScale: scale,
                              categories: categories,
                              selectedIndex: _selectedCategory,
                              onSelected: (i) => setState(() => _selectedCategory = i),
                            ),
                          ),
                        ),
                      ),
                      FadeTransition(
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
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 10 * scale),
                        child: const Divider(height: 1, color: Color(0xFFE1DAF2)),
                      ),
                    ],

                    if (_isLoading && allRecipes.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 60 * scale),
                          child: const CircularProgressIndicator(color: Color(0xFF6C4EF5)),
                        ),
                      )
                    else if (allRecipes.isEmpty)
                      FadeTransition(
                        opacity: _fade(0.1, 0.4),
                        child: SlideTransition(
                          position: _slide(0.1, 0.45),
                          child: _EmptySavedRecipesState(
                            uiScale: scale,
                            onExplore: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              } else {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const RecipeGeneratorScreen()),
                                );
                              }
                            },
                          ),
                        ),
                      )
                    else if (filteredRecipes.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 40 * scale),
                          child: Text(
                            'No recipes match this category.',
                            style: TextStyle(
                              fontSize: 13 * scale,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B6B7B),
                            ),
                          ),
                        ),
                      )
                    else
                      for (int i = 0; i < filteredRecipes.length; i++)
                        Padding(
                          padding: EdgeInsets.only(bottom: 14 * scale),
                          child: _RecipeCard(
                            uiScale: scale,
                            index: i,
                            recipe: filteredRecipes[i],
                            onTap: () => _onRecipeClicked(filteredRecipes[i]),
                            onMenuTap: () => widget.onRecipeMenuTap?.call(filteredRecipes[i]),
                            onBookmarkToggle: (v) => _onBookmarkClicked(filteredRecipes[i], v),
                          ),
                        ),
                  ],
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
    final s = widget.uiScale;
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF7F3FF), Color(0xFFF3F0FB), Color(0xFFF0FCF5)],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final t = _ctrl.value;
              return Stack(
                children: [
                  Positioned(
                    top: -40 * s + (t * 14),
                    left: -30 * s,
                    child: _Blob(
                      size: 230 * s,
                      color: const Color(0xFF6C4EF5).withValues(alpha: 0.14),
                    ),
                  ),
                  Positioned(
                    bottom: 120 * s - (t * 16),
                    right: -40 * s,
                    child: _Blob(
                      size: 260 * s,
                      color: const Color(0xFF1E8A4C).withValues(alpha: 0.12),
                    ),
                  ),
                ],
              );
            },
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: const SizedBox.expand(),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable glass card
// ---------------------------------------------------------------------------
class _Glass extends StatelessWidget {
  const _Glass({
    required this.uiScale,
    required this.child,
    this.radius = 22,
    this.padding,
  });

  final double uiScale;
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius * uiScale),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(radius * uiScale),
            border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C4EF5).withValues(alpha: 0.06),
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
// Pressable bounce wrapper
// ---------------------------------------------------------------------------
class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, this.onTap, this.minScale = 0.94});
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
// Category tabs
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
// Recipe card
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
  void didUpdateWidget(_RecipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recipe.isBookmarked != widget.recipe.isBookmarked) {
      _bookmarked = widget.recipe.isBookmarked;
    }
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
                    child: _buildImage(recipe.imageAsset, uiScale),
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

  Widget _buildImage(String? asset, double uiScale) {
    if (asset == null || asset.isEmpty) {
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

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------
class _EmptySavedRecipesState extends StatelessWidget {
  const _EmptySavedRecipesState({required this.uiScale, required this.onExplore});
  final double uiScale;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 40 * uiScale),
      child: _Glass(
        uiScale: uiScale,
        radius: 24,
        padding: EdgeInsets.all(28 * uiScale),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64 * uiScale,
              height: 64 * uiScale,
              decoration: BoxDecoration(
                color: const Color(0xFF6C4EF5).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_border_rounded,
                size: 32 * uiScale,
                color: const Color(0xFF6C4EF5),
              ),
            ),
            SizedBox(height: 16 * uiScale),
            Text(
              'No saved recipes yet',
              style: TextStyle(
                fontSize: 16 * uiScale,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1B1B2E),
              ),
            ),
            SizedBox(height: 8 * uiScale),
            Text(
              'Explore recipes and tap Save Recipe to build your personal cookbook.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12 * uiScale,
                color: const Color(0xFF6B6B7B),
                height: 1.4,
              ),
            ),
            SizedBox(height: 20 * uiScale),
            FilledButton.icon(
              onPressed: onExplore,
              icon: const Icon(Icons.auto_awesome_rounded, size: 16),
              label: const Text('Explore Recipes'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6C4EF5),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20 * uiScale, vertical: 12 * uiScale),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
