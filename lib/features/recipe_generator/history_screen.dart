import 'dart:ui';

import 'package:flutter/material.dart';

/// DietCompass — History Screen
/// -----------------------------------------------------------------------
/// Matches the visual language of the rest of the app: lavender background
/// (0xFFF3F0FB), purple → green brand accents, frosted glassmorphism
/// cards, staggered/animated card reveals, an animated segmented tab
/// switch (All Recipes / Viewed / Saved), and a bouncy bookmark toggle.
///
/// Recipe photos are optional — pass an `imageAsset` per HistoryRecipeItem
/// and it renders via Image.asset with a graceful colour-tinted icon
/// fallback if the asset isn't found yet.
class HistoryRecipeItem {
  const HistoryRecipeItem({
    required this.title,
    required this.tags,
    required this.timeMinutes,
    required this.kcal,
    required this.proteinG,
    required this.generatedAtLabel,
    required this.dateGroup,
    this.imageAsset,
    this.isVegetarian = true,
    this.isBookmarked = false,
    this.isViewed = true,
  });

  final String title;
  final String tags;
  final int timeMinutes;
  final int kcal;
  final int proteinG;
  final String generatedAtLabel;
  final String dateGroup;
  final String? imageAsset;
  final bool isVegetarian;
  final bool isBookmarked;
  final bool isViewed;
}

enum HistoryTab { all, viewed, saved }

class HistoryScreen extends StatefulWidget {
  HistoryScreen({
    super.key,
    List<HistoryRecipeItem>? recipes,
    this.onBack,
    this.onEditTap,
    this.onRecipeTap,
    this.onRecipeMenuTap,
    this.onBookmarkToggle,
    this.onClearAllTap,
  }) : recipes = recipes ?? _defaultRecipes;

  final List<HistoryRecipeItem> recipes;
  final VoidCallback? onBack;
  final VoidCallback? onEditTap;
  final ValueChanged<HistoryRecipeItem>? onRecipeTap;
  final ValueChanged<HistoryRecipeItem>? onRecipeMenuTap;
  final void Function(HistoryRecipeItem recipe, bool bookmarked)? onBookmarkToggle;
  final VoidCallback? onClearAllTap;

  static const _defaultRecipes = [
    HistoryRecipeItem(
      title: 'Banana Oats Power Bowl',
      tags: 'Healthy • Quick • Delicious',
      timeMinutes: 15,
      kcal: 320,
      proteinG: 12,
      generatedAtLabel: 'Generated at 12:22 PM',
      dateGroup: 'Today',
      imageAsset: 'assets/images/recipe_banana_oats.png',
      isBookmarked: true,
    ),
    HistoryRecipeItem(
      title: 'Apple Cinnamon Oatmeal',
      tags: 'Warm • Comforting • Wholesome',
      timeMinutes: 12,
      kcal: 310,
      proteinG: 9,
      generatedAtLabel: 'Generated at 12:15 PM',
      dateGroup: 'Today',
      imageAsset: 'assets/images/recipe_apple_cinnamon_oatmeal.png',
    ),
    HistoryRecipeItem(
      title: 'Quinoa Veggie Salad',
      tags: 'Healthy • Light • Refreshing',
      timeMinutes: 20,
      kcal: 280,
      proteinG: 10,
      generatedAtLabel: 'Generated at 11:48 AM',
      dateGroup: 'Today',
      imageAsset: 'assets/images/recipe_quinoa_veggie_salad.png',
    ),
    HistoryRecipeItem(
      title: 'Chickpea Curry with Rice',
      tags: 'Hearty • Spicy • Comforting',
      timeMinutes: 25,
      kcal: 450,
      proteinG: 15,
      generatedAtLabel: 'Generated at 7:30 PM',
      dateGroup: 'Yesterday',
      imageAsset: 'assets/images/recipe_chickpea_curry.png',
    ),
    HistoryRecipeItem(
      title: 'Berry Banana Smoothie',
      tags: 'Quick • Healthy • Energizing',
      timeMinutes: 5,
      kcal: 210,
      proteinG: 6,
      generatedAtLabel: 'Generated at 6:45 PM',
      dateGroup: 'Yesterday',
      imageAsset: 'assets/images/recipe_berry_banana_smoothie.png',
    ),
    HistoryRecipeItem(
      title: 'Avocado Egg Toast',
      tags: 'High Protein • Quick • Filling',
      timeMinutes: 10,
      kcal: 350,
      proteinG: 14,
      generatedAtLabel: 'Generated at 9:10 AM',
      dateGroup: '2 Days Ago',
      imageAsset: 'assets/images/recipe_avocado_egg_toast.png',
    ),
  ];

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  HistoryTab _selectedTab = HistoryTab.all;
  late Map<String, bool> _bookmarked;

  @override
  void initState() {
    super.initState();
    _bookmarked = {for (final r in widget.recipes) r.title: r.isBookmarked};
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

  List<HistoryRecipeItem> get _filtered {
    switch (_selectedTab) {
      case HistoryTab.all:
        return widget.recipes;
      case HistoryTab.viewed:
        return widget.recipes.where((r) => r.isViewed).toList();
      case HistoryTab.saved:
        return widget.recipes.where((r) => _bookmarked[r.title] ?? r.isBookmarked).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 390).clamp(0.85, 1.25);

    final grouped = <String, List<HistoryRecipeItem>>{};
    for (final r in _filtered) {
      grouped.putIfAbsent(r.dateGroup, () => []).add(r);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FB),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _GlassBackdrop(uiScale: scale),
          SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(18 * scale, 8 * scale, 18 * scale, 24 * scale),
              physics: const BouncingScrollPhysics(),
              children: [
                FadeTransition(
                  opacity: _fade(0.0, 0.3),
                  child: SlideTransition(
                    position: _slide(0.0, 0.34),
                    child: _TopHeader(uiScale: scale, onBack: widget.onBack, onEditTap: widget.onEditTap),
                  ),
                ),
                SizedBox(height: 16 * scale),

                FadeTransition(
                  opacity: _fade(0.08, 0.38),
                  child: SlideTransition(
                    position: _slide(0.08, 0.42),
                    child: _TabsRow(
                      uiScale: scale,
                      selected: _selectedTab,
                      onSelected: (t) => setState(() => _selectedTab = t),
                    ),
                  ),
                ),
                SizedBox(height: 18 * scale),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(anim),
                      child: child,
                    ),
                  ),
                  child: grouped.isEmpty
                      ? _EmptyState(uiScale: scale, key: ValueKey(_selectedTab))
                      : Column(
                          key: ValueKey(_selectedTab),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: grouped.entries.expand((entry) {
                            final items = entry.value;
                            return [
                              Padding(
                                padding: EdgeInsets.only(bottom: 10 * scale, top: 4 * scale),
                                child: Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 13 * scale,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1B1B2E),
                                  ),
                                ),
                              ),
                              ...List.generate(items.length, (i) {
                                final recipe = items[i];
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 14 * scale),
                                  child: _RecipeCard(
                                    uiScale: scale,
                                    index: i,
                                    recipe: recipe,
                                    bookmarked: _bookmarked[recipe.title] ?? recipe.isBookmarked,
                                    onTap: () => widget.onRecipeTap?.call(recipe),
                                    onMenuTap: () => widget.onRecipeMenuTap?.call(recipe),
                                    onBookmarkToggle: (v) {
                                      setState(() => _bookmarked[recipe.title] = v);
                                      widget.onBookmarkToggle?.call(recipe, v);
                                    },
                                  ),
                                );
                              }),
                            ];
                          }).toList(),
                        ),
                ),
                SizedBox(height: 6 * scale),

                FadeTransition(
                  opacity: _fade(0.5, 0.85),
                  child: SlideTransition(
                    position: _slide(0.5, 0.88),
                    child: _FooterNote(uiScale: scale, onClearAllTap: widget.onClearAllTap),
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
            Positioned(top: -80 + t * 14, right: -60, child: _blob(210 * uiScale, const Color(0xFF6C4EF5))),
            Positioned(bottom: -60 + t * 12, left: -60, child: _blob(180 * uiScale, const Color(0xFF1E8A4C))),
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
            color: (color ?? Colors.white).withOpacity(color == null ? 0.68 : 0.9),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor ?? Colors.white.withOpacity(0.8), width: 1.1),
            boxShadow: [
              BoxShadow(color: const Color(0xFF6C4EF5).withOpacity(0.07), blurRadius: 18, offset: const Offset(0, 8)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

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
// Top header — back, history icon + title, subtitle, Edit pill
// ---------------------------------------------------------------------------
class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.uiScale, this.onBack, this.onEditTap});
  final double uiScale;
  final VoidCallback? onBack;
  final VoidCallback? onEditTap;

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
                  Icon(Icons.history_rounded, size: 18 * uiScale, color: const Color(0xFF6C4EF5)),
                  SizedBox(width: 6 * uiScale),
                  Text(
                    'History',
                    style: TextStyle(fontSize: 18 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E)),
                  ),
                ],
              ),
              SizedBox(height: 2 * uiScale),
              Text(
                'Your recently generated recipes',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5 * uiScale, color: const Color(0xFF6B6B7B)),
              ),
            ],
          ),
        ),
        _Pressable(
          onTap: onEditTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14 * uiScale, vertical: 11 * uiScale),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_rounded, size: 14 * uiScale, color: const Color(0xFF6C4EF5)),
                SizedBox(width: 5 * uiScale),
                Text(
                  'Edit',
                  style: TextStyle(fontSize: 12 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF6C4EF5)),
                ),
              ],
            ),
          ),
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
        color: Colors.white.withOpacity(0.85),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Icon(icon, size: 19 * uiScale, color: const Color(0xFF1B1B2E)),
    );
  }
}

// ---------------------------------------------------------------------------
// Segmented tabs — All Recipes / Viewed / Saved
// ---------------------------------------------------------------------------
class _TabsRow extends StatelessWidget {
  const _TabsRow({required this.uiScale, required this.selected, required this.onSelected});
  final double uiScale;
  final HistoryTab selected;
  final ValueChanged<HistoryTab> onSelected;

  static const _tabs = [
    (tab: HistoryTab.all, icon: Icons.filter_none_rounded, label: 'All Recipes'),
    (tab: HistoryTab.viewed, icon: Icons.visibility_outlined, label: 'Viewed'),
    (tab: HistoryTab.saved, icon: Icons.bookmark_outline_rounded, label: 'Saved'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4 * uiScale),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3DDF5)),
      ),
      child: Row(
        children: _tabs.map((t) {
          final isSelected = t.tab == selected;
          return Expanded(
            child: _Pressable(
              onTap: () => onSelected(t.tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(vertical: 11 * uiScale),
                decoration: BoxDecoration(
                  gradient: isSelected ? const LinearGradient(colors: [Color(0xFF6C4EF5), Color(0xFF8467F8)]) : null,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [BoxShadow(color: const Color(0xFF6C4EF5).withOpacity(0.32), blurRadius: 12, offset: const Offset(0, 5))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(t.icon, size: 14 * uiScale, color: isSelected ? Colors.white : const Color(0xFF6C4EF5)),
                    SizedBox(width: 5 * uiScale),
                    Flexible(
                      child: Text(
                        t.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5 * uiScale,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : const Color(0xFF1B1B2E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recipe card — staggered reveal on first build
// ---------------------------------------------------------------------------
class _RecipeCard extends StatefulWidget {
  const _RecipeCard({
    required this.uiScale,
    required this.index,
    required this.recipe,
    required this.bookmarked,
    this.onTap,
    this.onMenuTap,
    this.onBookmarkToggle,
  });

  final double uiScale;
  final int index;
  final HistoryRecipeItem recipe;
  final bool bookmarked;
  final VoidCallback? onTap;
  final VoidCallback? onMenuTap;
  final ValueChanged<bool>? onBookmarkToggle;

  @override
  State<_RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<_RecipeCard> with TickerProviderStateMixin {
  late final AnimationController _revealCtrl;

  @override
  void initState() {
    super.initState();
    _revealCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
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

  @override
  Widget build(BuildContext context) {
    final uiScale = widget.uiScale;
    final recipe = widget.recipe;
    final bookmarked = widget.bookmarked;

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
                                  Icon(Icons.eco_rounded, size: 12 * uiScale, color: const Color(0xFF1E8A4C)),
                                ],
                              ],
                            ),
                          ),
                          _Pressable(
                            onTap: widget.onMenuTap,
                            child: Icon(Icons.more_vert_rounded, size: 17 * uiScale, color: const Color(0xFFB0ACC2)),
                          ),
                        ],
                      ),
                      SizedBox(height: 2 * uiScale),
                      Text(
                        recipe.tags,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10.5 * uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF6C4EF5)),
                      ),
                      SizedBox(height: 8 * uiScale),
                      Wrap(
                        spacing: 6 * uiScale,
                        runSpacing: 6 * uiScale,
                        children: [
                          _MetaPill(uiScale: uiScale, icon: Icons.access_time_rounded, iconColor: const Color(0xFF6C4EF5), label: '${recipe.timeMinutes} min'),
                          _MetaPill(uiScale: uiScale, icon: Icons.local_fire_department_rounded, iconColor: const Color(0xFFE0862E), label: '${recipe.kcal} kcal'),
                          _MetaPill(uiScale: uiScale, icon: Icons.eco_rounded, iconColor: const Color(0xFF1E8A4C), label: '${recipe.proteinG}g Protein'),
                        ],
                      ),
                      SizedBox(height: 8 * uiScale),
                      Text(
                        recipe.generatedAtLabel,
                        style: TextStyle(fontSize: 10.5 * uiScale, color: const Color(0xFF6B6B7B)),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 6 * uiScale),
                GestureDetector(
                  onTap: () => widget.onBookmarkToggle?.call(!bookmarked),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1, end: bookmarked ? 1.15 : 1.0),
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.elasticOut,
                    builder: (context, val, child) => Transform.scale(scale: val, child: child),
                    child: Container(
                      width: 32 * uiScale,
                      height: 32 * uiScale,
                      decoration: BoxDecoration(
                        color: bookmarked ? const Color(0xFF6C4EF5) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: bookmarked ? null : Border.all(color: const Color(0xFF6C4EF5)),
                      ),
                      child: Icon(
                        Icons.bookmark_rounded,
                        size: 16 * uiScale,
                        color: bookmarked ? Colors.white : const Color(0xFF6C4EF5),
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
  const _MetaPill({required this.uiScale, required this.icon, required this.iconColor, required this.label});
  final double uiScale;
  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * uiScale, vertical: 5 * uiScale),
      decoration: BoxDecoration(color: const Color(0xFFF3F0FB), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11 * uiScale, color: iconColor),
          SizedBox(width: 4 * uiScale),
          Text(
            label,
            style: TextStyle(fontSize: 9.5 * uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF1B1B2E)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state (shown when a tab has no matching recipes)
// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key, required this.uiScale});
  final double uiScale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 40 * uiScale),
      child: Column(
        children: [
          Container(
            width: 64 * uiScale,
            height: 64 * uiScale,
            decoration: const BoxDecoration(color: Color(0xFFEDE7FA), shape: BoxShape.circle),
            child: Icon(Icons.history_rounded, size: 30 * uiScale, color: const Color(0xFF6C4EF5)),
          ),
          SizedBox(height: 14 * uiScale),
          Text(
            'Nothing here yet',
            style: TextStyle(fontSize: 13.5 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E)),
          ),
          SizedBox(height: 4 * uiScale),
          Text(
            'Recipes will show up here once available.',
            style: TextStyle(fontSize: 11 * uiScale, color: const Color(0xFF6B6B7B)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Footer note — retention info + Clear All
// ---------------------------------------------------------------------------
class _FooterNote extends StatelessWidget {
  const _FooterNote({required this.uiScale, this.onClearAllTap});
  final double uiScale;
  final VoidCallback? onClearAllTap;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      uiScale: uiScale,
      radius: 18,
      padding: EdgeInsets.all(14 * uiScale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.history_rounded, size: 16 * uiScale, color: const Color(0xFF6C4EF5)),
          SizedBox(width: 10 * uiScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recipes are saved for 30 days',
                  style: TextStyle(fontSize: 12 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E)),
                ),
                SizedBox(height: 2 * uiScale),
                Text(
                  'You can view, save or regenerate them anytime.',
                  style: TextStyle(fontSize: 10.5 * uiScale, color: const Color(0xFF6B6B7B)),
                ),
              ],
            ),
          ),
          SizedBox(width: 8 * uiScale),
          _Pressable(
            onTap: onClearAllTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_outline_rounded, size: 15 * uiScale, color: const Color(0xFFE0475B)),
                SizedBox(width: 4 * uiScale),
                Text(
                  'Clear All',
                  style: TextStyle(fontSize: 11.5 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFFE0475B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
