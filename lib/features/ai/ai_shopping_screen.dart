import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../scan/scan_screen.dart';
import '../pantry/pantry_screen.dart';
import '../dashboard/DashboardScreen.dart';
import '../ai_coach/voice_assistant_modal.dart';


/// DietCompass — AI Shopping Assistant Screen
/// -----------------------------------------------------------------------
/// Reuses your existing assets:
///   • assets/images/robot_pointing.png     — DietCompass robot (header)
///   • assets/images/product_quaker.png     — recommended product photo
///   • assets/images/card_high_protein.png, card_low_sugar.png,
///     card_immunity.png, card_gluten_free.png — Quick Suggestions tiles
///   • assets/images/card_dairy.png, card_breakfast.png, card_snacks.png,
///     card_beverages.png, card_cooking.png — Popular Categories tiles
///   • assets/images/icon_smart_cart_circle.png — cropped icon for the
///     Smart Cart Advice banner
///
/// The quick-suggestion and category tiles are used exactly as provided
/// (each is already a complete card with its own icon/photo and label
/// baked in) — wrapped in real, tappable, animated widgets.
///
/// Add to pubspec.yaml (skip any already present):
/// ```yaml
/// flutter:
///   assets:
///     - assets/images/robot_pointing.png
///     - assets/images/product_quaker.png
///     - assets/images/card_high_protein.png
///     - assets/images/card_low_sugar.png
///     - assets/images/card_immunity.png
///     - assets/images/card_gluten_free.png
///     - assets/images/card_dairy.jpeg
///     - assets/images/card_breakfast.png
///     - assets/images/card_snacks.png
///     - assets/images/card_beverages.png
///     - assets/images/card_cooking.png
///     - assets/images/icon_smart_cart_circle.png
/// ```
class QuickTile {
  const QuickTile({required this.asset, required this.id});
  final String asset;
  final String id;
}

class RecommendedProduct {
  const RecommendedProduct({
    required this.image,
    required this.name,
    required this.matchPercent,
    required this.highlights,
    required this.description,
    required this.tags,
    required this.price,
    required this.weight,
  });

  final ImageProvider image;
  final String name;
  final int matchPercent;
  final List<String> highlights;
  final String description;
  final List<String> tags;
  final String price;
  final String weight;
}

class AiShoppingScreen extends StatefulWidget {
  const AiShoppingScreen({
    super.key,
    this.userName = 'Nazia',
    this.cartCount = 3,
    this.quickSuggestions = const [
      QuickTile(asset: 'assets/images/card_high_protein.png', id: 'high_protein'),
      QuickTile(asset: 'assets/images/card_low_sugar.jpeg', id: 'low_sugar'),
      QuickTile(asset: 'assets/images/card_immunity.jpeg', id: 'immunity'),
      QuickTile(asset: 'assets/images/card_gluten_free.jpeg', id: 'gluten_free'),
    ],
    this.categories = const [
      QuickTile(asset: 'assets/images/card_dairy.jpeg', id: 'dairy'),
      QuickTile(asset: 'assets/images/card_breakfast.jpeg', id: 'breakfast'),
      QuickTile(asset: 'assets/images/card_snacks.jpeg', id: 'snacks'),
      QuickTile(asset: 'assets/images/card_beverages.jpeg', id: 'beverages'),
      QuickTile(asset: 'assets/images/card_cooking.jpeg', id: 'cooking'),
    ],
    this.recommended = const RecommendedProduct(
      image: AssetImage('assets/images/product_quaker.png'),
      name: 'Quaker Whole Oats',
      matchPercent: 95,
      highlights: ['High in Fiber', 'Low Sugar'],
      description: 'Great for your heart health and weight management '
          'goals. Rich in fiber and keeps you full longer.',
      tags: ['High Fiber', 'Low Sugar', 'Heart Friendly'],
      price: '₹250',
      weight: '1 kg',
    ),
    this.cartHighSugarCount = 2,
    this.onBack,
    this.onCartTap,
    this.onSearchSubmitted,
    this.onMicTap,
    this.onScanTap,
    this.onQuickSuggestionTap,
    this.onViewAllSuggestions,
    this.onFavoriteRecommended,
    this.onAddToCart,
    this.onReviewCartTap,
    this.onCategoryTap,
    this.onViewAllCategories,
    this.onNavTap,
    this.initialNavIndex = 2,
  });

  final String userName;
  final int cartCount;
  final List<QuickTile> quickSuggestions;
  final List<QuickTile> categories;
  final RecommendedProduct recommended;
  final int cartHighSugarCount;

  final VoidCallback? onBack;
  final VoidCallback? onCartTap;
  final ValueChanged<String>? onSearchSubmitted;
  final VoidCallback? onMicTap;
  final VoidCallback? onScanTap;
  final ValueChanged<String>? onQuickSuggestionTap;
  final VoidCallback? onViewAllSuggestions;
  final VoidCallback? onFavoriteRecommended;
  final VoidCallback? onAddToCart;
  final VoidCallback? onReviewCartTap;
  final ValueChanged<String>? onCategoryTap;
  final VoidCallback? onViewAllCategories;
  final ValueChanged<int>? onNavTap;
  final int initialNavIndex;

  @override
  State<AiShoppingScreen> createState() => _AiShoppingScreenState();
}

class _AiShoppingScreenState extends State<AiShoppingScreen> with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _ambientCtrl;
  late int _navIndex;
  bool _favorited = false;

  @override
  void initState() {
    super.initState();
    _navIndex = widget.initialNavIndex;
    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();
    _ambientCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _ambientCtrl.dispose();
    super.dispose();
  }

  Animation<double> _fade(double s, double e) =>
      CurvedAnimation(parent: _entranceCtrl, curve: Interval(s, e, curve: Curves.easeOut));

  Animation<Offset> _slide(double s, double e) => Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
      .animate(CurvedAnimation(parent: _entranceCtrl, curve: Interval(s, e, curve: Curves.easeOutCubic)));

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 390).clamp(0.85, 1.25);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FB),
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

  // Optional overlay for better readability
  Positioned.fill(
    child: Container(
      color: Colors.white.withValues(alpha: 0.08),
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
                  child: _TopBar(uiScale: scale, cartCount: widget.cartCount, onBack: widget.onBack, onCartTap: widget.onCartTap),
                ),
                SizedBox(height: 16 * scale),

                FadeTransition(
                  opacity: _fade(0.04, 0.4),
                  child: SlideTransition(
                    position: _slide(0.04, 0.42),
                    child: _GreetingHeader(uiScale: scale, userName: widget.userName, ambientCtrl: _ambientCtrl),
                  ),
                ),
                SizedBox(height: 16 * scale),

                FadeTransition(
                  opacity: _fade(0.1, 0.44),
                  child: SlideTransition(
                    position: _slide(0.1, 0.46),
                    child: _SearchBar(
                      uiScale: scale,
                      onSubmitted: widget.onSearchSubmitted,
                      onMicTap: widget.onMicTap ??
                          () => showVoiceAssistantModal(context, userName: widget.userName),
                      onScanTap: widget.onScanTap,
                    ),
                  ),
                ),

                SizedBox(height: 20 * scale),

                FadeTransition(
                  opacity: _fade(0.16, 0.5),
                  child: SlideTransition(
                    position: _slide(0.16, 0.52),
                    child: _TileSection(
                      uiScale: scale,
                      title: 'Quick Suggestions',
                      tiles: widget.quickSuggestions,
                      onTileTap: widget.onQuickSuggestionTap,
                      onViewAll: widget.onViewAllSuggestions,
                    ),
                  ),
                ),
                SizedBox(height: 20 * scale),

                FadeTransition(
                  opacity: _fade(0.22, 0.56),
                  child: SlideTransition(
                    position: _slide(0.22, 0.58),
                    child: Text('Recommended for You',
                        style: TextStyle(fontSize: 15.5 * scale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
                  ),
                ),
                SizedBox(height: 10 * scale),

                FadeTransition(
                  opacity: _fade(0.24, 0.6),
                  child: SlideTransition(
                    position: _slide(0.24, 0.62),
                    child: _RecommendedCard(
                      uiScale: scale,
                      product: widget.recommended,
                      favorited: _favorited,
                      onFavoriteTap: () {
                        setState(() => _favorited = !_favorited);
                        widget.onFavoriteRecommended?.call();
                      },
                      onAddToCart: widget.onAddToCart,
                    ),
                  ),
                ),
                SizedBox(height: 16 * scale),

                FadeTransition(
                  opacity: _fade(0.32, 0.66),
                  child: SlideTransition(
                    position: _slide(0.32, 0.68),
                    child: _SmartCartAdviceBanner(
                      uiScale: scale,
                      highSugarCount: widget.cartHighSugarCount,
                      onReviewCartTap: widget.onReviewCartTap,
                    ),
                  ),
                ),
                SizedBox(height: 20 * scale),

                FadeTransition(
                  opacity: _fade(0.4, 0.74),
                  child: SlideTransition(
                    position: _slide(0.4, 0.76),
                    child: _TileSection(
                      uiScale: scale,
                      title: 'Popular Categories',
                      tiles: widget.categories,
                      onTileTap: widget.onCategoryTap,
                      onViewAll: widget.onViewAllCategories,
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
      // Already on AI screen
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
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const DashboardScreen(),
    ),
  );
  break;
        }
    },
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF1EDFB), Color(0xFFEFFAF3)],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------
class _TopBar extends StatelessWidget {
  const _TopBar({required this.uiScale, required this.cartCount, this.onBack, this.onCartTap});
  final double uiScale;
  final int cartCount;
  final VoidCallback? onBack;
  final VoidCallback? onCartTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundButton(uiScale: uiScale, icon: Icons.arrow_back, onTap: onBack),
        Expanded(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('AI Shopping Assistant', style: TextStyle(fontSize: 15.5 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
                  SizedBox(width: 5 * uiScale),
                  Icon(Icons.auto_awesome, size: 14 * uiScale, color: const Color(0xFF9B7BFA)),
                ],
              ),
              Text('Your smart guide to healthier choices',
                  style: TextStyle(fontSize: 10.5 * uiScale, color: const Color(0xFF6B6B7B))),
            ],
          ),
        ),
        _CartButton(uiScale: uiScale, count: cartCount, onTap: onCartTap),
      ],
    );
  }
}

class _RoundButton extends StatefulWidget {
  const _RoundButton({required this.uiScale, required this.icon, this.onTap});
  final double uiScale;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  State<_RoundButton> createState() => _RoundButtonState();
}

class _RoundButtonState extends State<_RoundButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.9),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: () {
  if (widget.onTap != null) {
    widget.onTap!();
  } else {
    Navigator.pop(context);
  }
},
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 40 * widget.uiScale,
          height: 40 * widget.uiScale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Icon(widget.icon, size: 18 * widget.uiScale, color: const Color(0xFF1B1B2E)),
        ),
      ),
    );
  }
}

class _CartButton extends StatefulWidget {
  const _CartButton({required this.uiScale, required this.count, this.onTap});
  final double uiScale;
  final int count;
  final VoidCallback? onTap;

  @override
  State<_CartButton> createState() => _CartButtonState();
}

class _CartButtonState extends State<_CartButton> {
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
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Color(0xFF6C4EF5), Color(0xFF1E8A4C)]),
              ),
              child: Icon(Icons.shopping_cart_outlined, size: 18 * widget.uiScale, color: Colors.white),
            ),
            if (widget.count > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 5 * widget.uiScale, vertical: 1 * widget.uiScale),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E8A4C),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.4),
                  ),
                  child: Text('${widget.count}',
                      style: TextStyle(fontSize: 9 * widget.uiScale, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Greeting header + robot
// ---------------------------------------------------------------------------
class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.uiScale, required this.userName, required this.ambientCtrl});
  final double uiScale;
  final String userName;
  final AnimationController ambientCtrl;

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
                  Text('Hi ', style: TextStyle(fontSize: 21 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
                  Text('$userName! ', style: TextStyle(fontSize: 21 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF6C4EF5))),
                  Text('👋', style: TextStyle(fontSize: 18 * uiScale)),
                ],
              ),
              SizedBox(height: 4 * uiScale),
              Text('What are you looking for today?',
                  style: TextStyle(fontSize: 14 * uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF1B1B2E))),
              SizedBox(height: 6 * uiScale),
              Text(
                "I'll help you find the healthiest options from your "
                'pantry & match your goals.',
                style: TextStyle(fontSize: 11.5 * uiScale, height: 1.4, color: const Color(0xFF6B6B7B)),
              ),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: ambientCtrl,
          builder: (context, child) {
            final bob = math.sin(ambientCtrl.value * math.pi) * 6;
            return Transform.translate(offset: Offset(0, -bob), child: child);
          },
          child: Image.asset('assets/images/robot_pointing.png', width: 92 * uiScale),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Search bar
// ---------------------------------------------------------------------------
class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.uiScale, this.onSubmitted, this.onMicTap, this.onScanTap});
  final double uiScale;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onMicTap;
  final VoidCallback? onScanTap;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _focused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 52 * widget.uiScale,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _focused ? const Color(0xFF6C4EF5) : Colors.white, width: 1.6),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          SizedBox(width: 14 * widget.uiScale),
          Icon(Icons.search, size: 19 * widget.uiScale, color: const Color(0xFF9A96A8)),
          Expanded(
            child: TextField(
              focusNode: _focusNode,
              onSubmitted: widget.onSubmitted,
              style: TextStyle(fontSize: 13 * widget.uiScale),
              decoration: InputDecoration(
                hintText: 'Search for a product (e.g., oats, almond milk...)',
                hintStyle: TextStyle(color: const Color(0xFFB0ACC2), fontSize: 12 * widget.uiScale),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10 * widget.uiScale, vertical: 14 * widget.uiScale),
              ),
            ),
          ),
          GestureDetector(
            onTap: widget.onMicTap,
            child: Icon(Icons.mic_none_rounded, size: 19 * widget.uiScale, color: const Color(0xFF6C4EF5)),
          ),
          SizedBox(width: 10 * widget.uiScale),
          GestureDetector(
            onTap: widget.onScanTap,
            child: Container(
              width: 52 * widget.uiScale,
              height: 52 * widget.uiScale,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(topRight: Radius.circular(15), bottomRight: Radius.circular(15)),
                gradient: const LinearGradient(colors: [Color(0xFF6C4EF5), Color(0xFF1E8A4C)]),
              ),
              child: Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20 * widget.uiScale),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable tile section (Quick Suggestions / Popular Categories)
// ---------------------------------------------------------------------------
class _TileSection extends StatelessWidget {
  const _TileSection({
    required this.uiScale,
    required this.title,
    required this.tiles,
    this.onTileTap,
    this.onViewAll,
  });

  final double uiScale;
  final String title;
  final List<QuickTile> tiles;
  final ValueChanged<String>? onTileTap;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: TextStyle(fontSize: 15.5 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
            const Spacer(),
            GestureDetector(
              onTap: onViewAll,
              child: Text('View all', style: TextStyle(fontSize: 12 * uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF6C4EF5))),
            ),
          ],
        ),
        SizedBox(height: 10 * uiScale),
        SizedBox(
          height: 108 * uiScale,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: tiles.length,
            separatorBuilder: (_, __) => SizedBox(width: 10 * uiScale),
            itemBuilder: (context, i) {
              final tile = tiles[i];
              return _Tile(uiScale: uiScale, asset: tile.asset, onTap: () => onTileTap?.call(tile.id));
            },
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatefulWidget {
  const _Tile({required this.uiScale, required this.asset, this.onTap});
  final double uiScale;
  final String asset;
  final VoidCallback? onTap;

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 96 * widget.uiScale,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 6))],
            ),
            child: Image.asset(widget.asset, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recommended product card
// ---------------------------------------------------------------------------
class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({
    required this.uiScale,
    required this.product,
    required this.favorited,
    required this.onFavoriteTap,
    this.onAddToCart,
  });

  final double uiScale;
  final RecommendedProduct product;
  final bool favorited;
  final VoidCallback onFavoriteTap;
  final VoidCallback? onAddToCart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14 * uiScale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 88 * uiScale,
                      height: 108 * uiScale,
                      color: const Color(0xFFF6F3FC),
                      padding: EdgeInsets.all(6 * uiScale),
                      child: Image(image: product.image, fit: BoxFit.contain),
                    ),
                  ),
                  Positioned(
                    top: 6 * uiScale,
                    left: 6 * uiScale,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6 * uiScale, vertical: 3 * uiScale),
                      decoration: BoxDecoration(color: const Color(0xFFE4F5E9), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, size: 10 * uiScale, color: const Color(0xFF1E8A4C)),
                          SizedBox(width: 2 * uiScale),
                          Text('Best Match', style: TextStyle(fontSize: 7.5 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1E8A4C))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 12 * uiScale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(product.name, style: TextStyle(fontSize: 14.5 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
                        ),
                        GestureDetector(
                          onTap: onFavoriteTap,
                          child: Icon(
                            favorited ? Icons.favorite : Icons.favorite_border,
                            size: 17 * uiScale,
                            color: favorited ? const Color(0xFFE0525C) : const Color(0xFF9A96A8),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4 * uiScale),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('${product.matchPercent}% Match', style: TextStyle(fontSize: 10.5 * uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF1E8A4C))),
                        for (final h in product.highlights) ...[
                          Text('  •  ', style: TextStyle(fontSize: 10.5 * uiScale, color: const Color(0xFF9A96A8))),
                          Text(h, style: TextStyle(fontSize: 10.5 * uiScale, color: const Color(0xFF6B6B7B))),
                        ],
                      ],
                    ),
                    SizedBox(height: 6 * uiScale),
                    Text(product.description, style: TextStyle(fontSize: 10.5 * uiScale, height: 1.35, color: const Color(0xFF3B3B4F))),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10 * uiScale),
          Wrap(
            spacing: 6 * uiScale,
            runSpacing: 6 * uiScale,
            children: product.tags.map((t) => _Tag(uiScale: uiScale, label: t)).toList(),
          ),
          SizedBox(height: 12 * uiScale),
          Row(
            children: [
              Text(product.price, style: TextStyle(fontSize: 16 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
              SizedBox(width: 6 * uiScale),
              Text(product.weight, style: TextStyle(fontSize: 11 * uiScale, color: const Color(0xFF9A96A8))),
              const Spacer(),
              _AddToCartButton(uiScale: uiScale, onTap: onAddToCart),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.uiScale, required this.label});
  final double uiScale;
  final String label;

  Color get _bg {
    switch (label) {
      case 'High Fiber':
        return const Color(0xFFE4F5E9);
      case 'Low Sugar':
        return const Color(0xFFE3EEFC);
      default:
        return const Color(0xFFFCEBE0);
    }
  }

  Color get _fg {
    switch (label) {
      case 'High Fiber':
        return const Color(0xFF1E8A4C);
      case 'Low Sugar':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFFE0525C);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9 * uiScale, vertical: 5 * uiScale),
      decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(fontSize: 10 * uiScale, fontWeight: FontWeight.w700, color: _fg)),
    );
  }
}

class _AddToCartButton extends StatefulWidget {
  const _AddToCartButton({required this.uiScale, this.onTap});
  final double uiScale;
  final VoidCallback? onTap;

  @override
  State<_AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<_AddToCartButton> {
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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(colors: [Color(0xFF6C4EF5), Color(0xFF1E8A4C)]),
            boxShadow: [BoxShadow(color: const Color(0xFF6C4EF5).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 6))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 14 * widget.uiScale),
              SizedBox(width: 5 * widget.uiScale),
              Text('Add to Cart', style: TextStyle(color: Colors.white, fontSize: 11.5 * widget.uiScale, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Smart Cart Advice banner
// ---------------------------------------------------------------------------
class _SmartCartAdviceBanner extends StatelessWidget {
  const _SmartCartAdviceBanner({required this.uiScale, required this.highSugarCount, this.onReviewCartTap});
  final double uiScale;
  final int highSugarCount;
  final VoidCallback? onReviewCartTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14 * uiScale),
      decoration: BoxDecoration(color: const Color(0xFFE9F7EE), borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Image.asset('assets/images/icon_smart_cart_circle.png', width: 44 * uiScale, height: 44 * uiScale, fit: BoxFit.cover),
          ),
          SizedBox(width: 12 * uiScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Smart Cart Advice', style: TextStyle(fontSize: 12.5 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
                    SizedBox(width: 6 * uiScale),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6 * uiScale, vertical: 2 * uiScale),
                      decoration: BoxDecoration(color: const Color(0xFF1E8A4C), borderRadius: BorderRadius.circular(8)),
                      child: Text('New', style: TextStyle(fontSize: 8 * uiScale, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ],
                ),
                SizedBox(height: 3 * uiScale),
                Text(
                  'Your cart has $highSugarCount high-sugar items. Want '
                  'healthier alternatives?',
                  style: TextStyle(fontSize: 10.5 * uiScale, height: 1.3, color: const Color(0xFF3B3B4F)),
                ),
              ],
            ),
          ),
          SizedBox(width: 8 * uiScale),
          _ReviewCartButton(uiScale: uiScale, onTap: onReviewCartTap),
        ],
      ),
    );
  }
}

class _ReviewCartButton extends StatefulWidget {
  const _ReviewCartButton({required this.uiScale, this.onTap});
  final double uiScale;
  final VoidCallback? onTap;

  @override
  State<_ReviewCartButton> createState() => _ReviewCartButtonState();
}

class _ReviewCartButtonState extends State<_ReviewCartButton> {
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
          padding: EdgeInsets.symmetric(horizontal: 12 * widget.uiScale, vertical: 9 * widget.uiScale),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E8A4C).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Review Cart', style: TextStyle(fontSize: 10.5 * widget.uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF1E8A4C))),
              SizedBox(width: 3 * widget.uiScale),
              Icon(Icons.arrow_forward, size: 12 * widget.uiScale, color: const Color(0xFF1E8A4C)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom nav bar (same pattern as other screens; AI tab active)
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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
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
