import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:diet_compass/core/theme/app_colors.dart';
import '../../core/model/recipe_history_item.dart';
import '../../core/services/recipe_history_service.dart';
import 'recipe_detail_screen.dart';

/// DietCompass — History Screen
/// -----------------------------------------------------------------------
/// Matches the visual language of the rest of the app: lavender background
/// (0xFFF3F0FB), purple → green brand accents, frosted glassmorphism
/// cards, staggered/animated card reveals, an animated segmented tab
/// switch (All Recipes / Viewed / Saved), and a bouncy bookmark toggle.
///
/// Fully dynamic: Powered by RecipeHistoryService with user-specific persistence.
enum HistoryTab { all, viewed, saved }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    this.recipes,
    this.onBack,
    this.onEditTap,
    this.onRecipeTap,
    this.onRecipeMenuTap,
    this.onBookmarkToggle,
    this.onClearAllTap,
  });

  final List<RecipeHistoryItem>? recipes;
  final VoidCallback? onBack;
  final VoidCallback? onEditTap;
  final ValueChanged<RecipeHistoryItem>? onRecipeTap;
  final ValueChanged<RecipeHistoryItem>? onRecipeMenuTap;
  final void Function(RecipeHistoryItem recipe, bool bookmarked)? onBookmarkToggle;
  final VoidCallback? onClearAllTap;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  HistoryTab _selectedTab = HistoryTab.all;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.recipes == null) {
      setState(() => _isLoading = true);
      await RecipeHistoryService.instance.getRecipeHistory();
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

  List<RecipeHistoryItem> _getFilteredList(List<RecipeHistoryItem> source) {
    switch (_selectedTab) {
      case HistoryTab.all:
        return source;
      case HistoryTab.viewed:
        return source.where((r) => r.isViewed).toList();
      case HistoryTab.saved:
        return source.where((r) => r.isBookmarked).toList();
    }
  }

  void _handleRecipeTap(RecipeHistoryItem recipe) {
    if (widget.onRecipeTap != null) {
      widget.onRecipeTap!(recipe);
    } else {
      RecipeHistoryService.instance.logRecipeOpen(recipe);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(recipe: recipe.toRecipe()),
        ),
      );
    }
  }

  void _handleBookmarkToggle(RecipeHistoryItem recipe, bool nextVal) {
    RecipeHistoryService.instance.toggleBookmark(recipe, nextVal);
    widget.onBookmarkToggle?.call(recipe, nextVal);
  }

  Future<void> _handleClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear Recipe History?'),
        content: const Text(
          'Are you sure you want to clear your recipe history? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE0525C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await RecipeHistoryService.instance.clearHistory();
      widget.onClearAllTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 390).clamp(0.85, 1.25);

    final colors = context.dcColors;
    return Scaffold(
      backgroundColor: colors.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _GlassBackdrop(uiScale: scale),
          SafeArea(
            child: ListenableBuilder(
              listenable: RecipeHistoryService.instance,
              builder: (context, _) {
                final source = widget.recipes ?? RecipeHistoryService.instance.currentHistory;
                final filtered = _getFilteredList(source);

                final grouped = <String, List<RecipeHistoryItem>>{};
                for (final r in filtered) {
                  grouped.putIfAbsent(r.dateGroup, () => []).add(r);
                }

                return ListView(
                  padding: EdgeInsets.fromLTRB(18 * scale, 8 * scale, 18 * scale, 24 * scale),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    FadeTransition(
                      opacity: _fade(0.0, 0.3),
                      child: SlideTransition(
                        position: _slide(0.0, 0.34),
                        child: _TopHeader(
                          uiScale: scale,
                          onBack: widget.onBack,
                          onEditTap: widget.onEditTap,
                        ),
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

                    if (_isLoading && source.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40 * scale),
                          child: const CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Color(0xFF6C4EF5),
                          ),
                        ),
                      )
                    else
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
                                .animate(anim),
                            child: child,
                          ),
                        ),
                        child: grouped.isEmpty
                            ? _EmptyState(
                                uiScale: scale,
                                tab: _selectedTab,
                                onGenerateTap: () {
                                  if (widget.onBack != null) {
                                    widget.onBack!();
                                  } else {
                                    Navigator.maybePop(context);
                                  }
                                },
                                key: ValueKey(_selectedTab),
                              )
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
                                          color: colors.textPrimary,
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
                                          bookmarked: recipe.isBookmarked,
                                          onTap: () => _handleRecipeTap(recipe),
                                          onMenuTap: () => widget.onRecipeMenuTap?.call(recipe),
                                          onBookmarkToggle: (v) => _handleBookmarkToggle(recipe, v),
                                        ),
                                      );
                                    }),
                                  ];
                                }).toList(),
                              ),
                      ),
                    SizedBox(height: 6 * scale),

                    if (source.isNotEmpty)
                      FadeTransition(
                        opacity: _fade(0.5, 0.85),
                        child: SlideTransition(
                          position: _slide(0.5, 0.88),
                          child: _FooterNote(
                            uiScale: scale,
                            onClearAllTap: _handleClearAll,
                          ),
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
            Container(color: context.dcColors.bg),
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
            color: (color ?? (context.dcColors.isDark ? context.dcColors.surface : Colors.white))
                .withValues(alpha: color == null ? (context.dcColors.isDark ? 0.85 : 0.68) : 0.9),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor ?? context.dcColors.cardBorder,
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: context.dcColors.iconPurple.withValues(alpha: context.dcColors.isDark ? 0.2 : 0.07),
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
                  Icon(Icons.history_rounded, size: 18 * uiScale, color: context.dcColors.iconPurple),
                  SizedBox(width: 6 * uiScale),
                  Text(
                    'History',
                    style: TextStyle(fontSize: 18 * uiScale, fontWeight: FontWeight.w800, color: context.dcColors.textPrimary),
                  ),
                ],
              ),
              SizedBox(height: 2 * uiScale),
              Text(
                'Your recently generated recipes',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5 * uiScale, color: context.dcColors.textSecondary),
              ),
            ],
          ),
        ),
        SizedBox(width: 42 * uiScale),
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
        color: context.dcColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: context.dcColors.cardBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: context.dcColors.isDark ? 0.2 : 0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Icon(icon, size: 19 * uiScale, color: context.dcColors.textPrimary),
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
        color: context.dcColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.dcColors.cardBorder),
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
                  gradient: isSelected ? LinearGradient(colors: [context.dcColors.iconPurple, const Color(0xFF8467F8)]) : null,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [BoxShadow(color: context.dcColors.iconPurple.withValues(alpha: 0.32), blurRadius: 12, offset: const Offset(0, 5))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(t.icon, size: 14 * uiScale, color: isSelected ? Colors.white : context.dcColors.iconPurple),
                    SizedBox(width: 5 * uiScale),
                    Flexible(
                      child: Text(
                        t.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5 * uiScale,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : context.dcColors.textPrimary,
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
  final RecipeHistoryItem recipe;
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
                    child: _buildImage(uiScale, recipe.imageUrl),
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
                                      color: context.dcColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (recipe.isVegetarian) ...[
                                  SizedBox(width: 4 * uiScale),
                                  Icon(Icons.eco_rounded, size: 12 * uiScale, color: context.dcColors.iconGreen),
                                ],
                              ],
                            ),
                          ),
                          _Pressable(
                            onTap: widget.onMenuTap,
                            child: Icon(Icons.more_vert_rounded, size: 17 * uiScale, color: context.dcColors.textMuted),
                          ),
                        ],
                      ),
                      SizedBox(height: 2 * uiScale),
                      Text(
                        recipe.contextSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11 * uiScale,
                          fontWeight: FontWeight.w700,
                          color: context.dcColors.iconPurple,
                        ),
                      ),
                      SizedBox(height: 8 * uiScale),
                      Wrap(
                        spacing: 6 * uiScale,
                        runSpacing: 6 * uiScale,
                        children: [
                          _MetaPill(uiScale: uiScale, icon: Icons.access_time_rounded, iconColor: context.dcColors.iconPurple, label: '${recipe.timeMinutes} min'),
                          if (recipe.calories != null)
                            _MetaPill(uiScale: uiScale, icon: Icons.local_fire_department_rounded, iconColor: context.dcColors.iconOrange, label: '${recipe.calories!.toInt()} kcal'),
                          if (recipe.protein != null)
                            _MetaPill(uiScale: uiScale, icon: Icons.eco_rounded, iconColor: context.dcColors.iconGreen, label: '${recipe.protein!.toInt()}g Protein'),
                        ],
                      ),
                      SizedBox(height: 8 * uiScale),
                      Text(
                        recipe.generatedAtLabel,
                        style: TextStyle(fontSize: 10.5 * uiScale, color: context.dcColors.textSecondary),
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
                        color: bookmarked ? context.dcColors.iconPurple : context.dcColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: bookmarked ? null : Border.all(color: context.dcColors.iconPurple),
                      ),
                      child: Icon(
                        Icons.bookmark_rounded,
                        size: 16 * uiScale,
                        color: bookmarked ? Colors.white : context.dcColors.iconPurple,
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

  Widget _buildImage(double uiScale, String imgUrl) {
    if (imgUrl.startsWith('http://') || imgUrl.startsWith('https://')) {
      return Image.network(
        imgUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: const Color(0xFFEDE7FA),
            alignment: Alignment.center,
            child: SizedBox(
              width: 18 * uiScale,
              height: 18 * uiScale,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF6C4EF5),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _imageFallback(uiScale),
      );
    } else if (imgUrl.startsWith('assets/')) {
      return Image.asset(
        imgUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imageFallback(uiScale),
      );
    }
    return _imageFallback(uiScale);
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
      decoration: BoxDecoration(
        color: context.dcColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.dcColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11 * uiScale, color: iconColor),
          SizedBox(width: 4 * uiScale),
          Text(
            label,
            style: TextStyle(fontSize: 9.5 * uiScale, fontWeight: FontWeight.w700, color: context.dcColors.textPrimary),
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
  const _EmptyState({
    super.key,
    required this.uiScale,
    this.tab = HistoryTab.all,
    this.onGenerateTap,
  });

  final double uiScale;
  final HistoryTab tab;
  final VoidCallback? onGenerateTap;

  @override
  Widget build(BuildContext context) {
    String title = 'No recipes generated yet';
    String subtitle = 'Generate recipes using your pantry or scanned products to build your history.';

    if (tab == HistoryTab.saved) {
      title = 'No saved recipes yet';
      subtitle = 'Bookmark recipes in history or generation results to view them here.';
    } else if (tab == HistoryTab.viewed) {
      title = 'No viewed recipes yet';
      subtitle = 'Recipes you view in detail will appear here.';
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 40 * uiScale),
      child: Column(
        children: [
          Container(
            width: 64 * uiScale,
            height: 64 * uiScale,
            decoration: BoxDecoration(
              color: context.dcColors.iconPurple.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              tab == HistoryTab.saved ? Icons.bookmark_border_rounded : Icons.history_rounded,
              size: 30 * uiScale,
              color: context.dcColors.iconPurple,
            ),
          ),
          SizedBox(height: 14 * uiScale),
          Text(
            title,
            style: TextStyle(fontSize: 14 * uiScale, fontWeight: FontWeight.w800, color: context.dcColors.textPrimary),
          ),
          SizedBox(height: 6 * uiScale),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24 * uiScale),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5 * uiScale, color: context.dcColors.textSecondary, height: 1.4),
            ),
          ),
          if (tab == HistoryTab.all && onGenerateTap != null) ...[
            SizedBox(height: 18 * uiScale),
            ElevatedButton.icon(
              onPressed: onGenerateTap,
              icon: const Icon(Icons.auto_awesome_rounded, size: 16),
              label: const Text('Generate Your First Recipe'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C4EF5),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 18 * uiScale, vertical: 10 * uiScale),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ],
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
          Icon(Icons.history_rounded, size: 16 * uiScale, color: context.dcColors.iconPurple),
          SizedBox(width: 10 * uiScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recipes are saved to your account',
                  style: TextStyle(fontSize: 12 * uiScale, fontWeight: FontWeight.w800, color: context.dcColors.textPrimary),
                ),
                SizedBox(height: 2 * uiScale),
                Text(
                  'You can view, save or regenerate them anytime.',
                  style: TextStyle(fontSize: 10.5 * uiScale, color: context.dcColors.textSecondary),
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
                Icon(Icons.delete_outline_rounded, size: 14 * uiScale, color: context.dcColors.iconRed),
                SizedBox(width: 4 * uiScale),
                Text(
                  'Clear All',
                  style: TextStyle(fontSize: 11 * uiScale, fontWeight: FontWeight.w800, color: context.dcColors.iconRed),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
