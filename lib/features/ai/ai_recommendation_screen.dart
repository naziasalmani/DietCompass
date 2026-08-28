import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../core/model/ai_analysis_model.dart';
import '../../core/model/food_product.dart';
import '../../core/model/personalization_profile.dart';
import '../../core/model/user_profile.dart';
import '../../core/services/personalization_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/recommendation_service.dart';
import '../home/home_screen.dart';
import '../scan/scan_screen.dart';
import '../pantry/pantry_screen.dart';
import '../dashboard/DashboardScreen.dart';
import '../scan/result_screen.dart';
import '../ai_coach/voice_assistant_modal.dart';

/// Quick suggestion tile model
class QuickTile {
  const QuickTile({required this.asset, required this.id, this.title = ''});
  final String asset;
  final String id;
  final String title;
}

/// DietCompass — AI Recommendation & Smart Shopping Screen
class AiShoppingScreen extends StatefulWidget {
  const AiShoppingScreen({
    super.key,
    this.referenceProduct,
    this.userName,
    this.pantryCount = 0,
    this.quickSuggestions = const [
      QuickTile(asset: 'assets/images/card_high_protein.png', id: 'high_protein', title: 'High Protein'),
      QuickTile(asset: 'assets/images/card_low_sugar.jpeg', id: 'low_sugar', title: 'Low Sugar'),
      QuickTile(asset: 'assets/images/card_immunity.jpeg', id: 'immunity', title: 'Immunity'),
      QuickTile(asset: 'assets/images/card_gluten_free.jpeg', id: 'gluten_free', title: 'Gluten Free'),
    ],
    this.categories = const [
      QuickTile(asset: 'assets/images/card_dairy.jpeg', id: 'dairy', title: 'Dairy'),
      QuickTile(asset: 'assets/images/card_breakfast.jpeg', id: 'breakfast', title: 'Breakfast'),
      QuickTile(asset: 'assets/images/card_snacks.jpeg', id: 'snacks', title: 'Snacks'),
      QuickTile(asset: 'assets/images/card_beverages.jpeg', id: 'beverages', title: 'Beverages'),
      QuickTile(asset: 'assets/images/card_cooking.jpeg', id: 'cooking', title: 'Cooking'),
    ],
    this.onBack,
    this.onPantryTap,
    this.onSearchSubmitted,
    this.onMicTap,
    this.onScanTap,
    this.onQuickSuggestionTap,
    this.onViewAllSuggestions,
    this.onFavoriteRecommended,
    this.onAddToPantry,
    this.onReviewPantryTap,
    this.onCategoryTap,
    this.onViewAllCategories,
    this.onNavTap,
    this.initialNavIndex = 2,
  });

  final FoodProduct? referenceProduct;
  final String? userName;
  final int pantryCount;
  final List<QuickTile> quickSuggestions;
  final List<QuickTile> categories;

  final VoidCallback? onBack;
  final VoidCallback? onPantryTap;
  final ValueChanged<String>? onSearchSubmitted;
  final VoidCallback? onMicTap;
  final VoidCallback? onScanTap;
  final ValueChanged<String>? onQuickSuggestionTap;
  final VoidCallback? onViewAllSuggestions;
  final VoidCallback? onFavoriteRecommended;
  final VoidCallback? onAddToPantry;
  final VoidCallback? onReviewPantryTap;
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

  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Dynamic recommendation & search state
  List<FoodProduct> _products = [];
  int _currentProductIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;

  // Search & Filter state
  bool _isSearchMode = false;
  String _activeSearchQuery = '';
  String? _activeFilterId;
  String? _activeFilterTitle;

  // User profiles & smart pantry advice
  UserProfile? _userProfile;
  PersonalizationProfile? _personalization;
  SmartPantryAdviceResult? _smartPantryAdvice;

  bool _favorited = false;
  late int _pantryCount;

  @override
  void initState() {
    super.initState();
    _navIndex = widget.initialNavIndex;
    _pantryCount = widget.pantryCount;

    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();
    _ambientCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat(reverse: true);

    _initializeData();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _ambientCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Animation<double> _fade(double s, double e) =>
      CurvedAnimation(parent: _entranceCtrl, curve: Interval(s, e, curve: Curves.easeOut));

  Animation<Offset> _slide(double s, double e) => Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
      .animate(CurvedAnimation(parent: _entranceCtrl, curve: Interval(s, e, curve: Curves.easeOutCubic)));

  // =========================================================================
  // DATA LOADING & DYNAMIC ENGINE
  // =========================================================================

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Fetch user profile & personalization in parallel
      try {
        _userProfile = await ProfileService.instance.getProfile();
      } catch (_) {
        _userProfile = ProfileService.instance.currentProfile;
      }

      try {
        _personalization = await PersonalizationService.instance.getPersonalization();
      } catch (_) {
        _personalization = PersonalizationService.instance.currentPersonalization;
      }

      // 2. Fetch real dynamic recommendations based on user profile and goals
      await _loadRecommendations();

      // 3. Compute Smart Pantry advice from pantry items
      _calculatePantryAdvice();
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Couldn't load products. Check your internet connection and try again.";
        });
      }
    }
  }

  Future<void> _loadRecommendations({String? filterId}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.referenceProduct != null && filterId == null) {
        final recs = await RecommendationService.instance.getCategoryAwareAlternatives(
          widget.referenceProduct!,
          personalization: _personalization,
          profile: _userProfile,
          limit: 8,
        );

        if (!mounted) return;
        setState(() {
          _products = recs.map((r) => r.product).toList();
          _currentProductIndex = 0;
          _isLoading = false;
        });
        return;
      }

      final recs = await RecommendationService.instance.getRecommendedProducts(
        personalization: _personalization,
        profile: _userProfile,
        categoryOrGoal: filterId,
      );

      if (!mounted) return;
      setState(() {
        _products = recs;
        _currentProductIndex = 0;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Couldn't load recommendations. Check connection and retry.";
      });
    }
  }

  Future<void> _executeSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      _clearSearch();
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isSearchMode = true;
      _activeSearchQuery = clean;
      _activeFilterId = null;
      _activeFilterTitle = null;
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await RecommendationService.instance.searchProducts(
        clean,
        personalization: _personalization,
        profile: _userProfile,
      );

      if (!mounted) return;
      setState(() {
        _products = results;
        _currentProductIndex = 0;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "No products found for '$clean'. Try another search.";
      });
    }
  }

  void _clearSearch() {
    _searchCtrl.clear();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isSearchMode = false;
      _activeSearchQuery = '';
      _activeFilterId = null;
      _activeFilterTitle = null;
    });
    _loadRecommendations();
  }

  void _handleTileTap(String tileId, String title) {
    if (_activeFilterId == tileId) {
      // Toggle off filter
      setState(() {
        _activeFilterId = null;
        _activeFilterTitle = null;
        _isSearchMode = false;
      });
      _loadRecommendations();
    } else {
      // Apply filter
      setState(() {
        _activeFilterId = tileId;
        _activeFilterTitle = title;
        _isSearchMode = false;
        _searchCtrl.clear();
      });
      _loadRecommendations(filterId: tileId);
    }
  }

  void _calculatePantryAdvice() {
    _smartPantryAdvice = RecommendationService.instance.calculateSmartPantryAdvice([]);
  }

  void _handleAddToPantry(FoodProduct product) {
    setState(() {
      _pantryCount++;
    });
    widget.onAddToPantry?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Added "${product.name}" to your pantry',
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E8A4C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openProductDetails(FoodProduct product) {
    final compat = RecommendationService.instance.evaluateCompatibility(
      product,
      personalization: _personalization,
      profile: _userProfile,
      goalFilter: _activeFilterId,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          product: product,
          initialCompatibility: compat,
        ),
      ),
    );
  }

  String get _resolvedUserName {
    if (widget.userName != null && widget.userName!.isNotEmpty) {
      return widget.userName!;
    }
    if (_userProfile?.displayName.isNotEmpty == true) {
      return _userProfile!.displayName;
    }
    if (_personalization?.fullName.isNotEmpty == true) {
      return _personalization!.fullName;
    }
    return 'Explorer';
  }

  String get _sectionTitle {
    if (_isSearchMode && _activeSearchQuery.isNotEmpty) {
      return 'Search Results for "$_activeSearchQuery"';
    }
    if (_activeFilterTitle != null && _activeFilterTitle!.isNotEmpty) {
      return 'Recommended for $_activeFilterTitle';
    }
    if (widget.referenceProduct != null) {
      return 'Better Alternatives for ${widget.referenceProduct!.name}';
    }
    return 'Recommended for You';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 390).clamp(0.85, 1.25);

    final currentProduct = (_products.isNotEmpty && _currentProductIndex < _products.length)
        ? _products[_currentProductIndex]
        : null;

    final evaluation = currentProduct != null
        ? RecommendationService.instance.evaluateCompatibility(
            currentProduct,
            personalization: _personalization,
            profile: _userProfile,
            goalFilter: _activeFilterId,
          )
        : null;

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
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: () async {
                if (_isSearchMode) {
                  await _executeSearch(_activeSearchQuery);
                } else {
                  await _loadRecommendations(filterId: _activeFilterId);
                }
              },
              color: const Color(0xFF6C4EF5),
              child: ListView(
                padding: EdgeInsets.fromLTRB(16 * scale, 8 * scale, 16 * scale, 110 * scale),
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                children: [
                  FadeTransition(
                    opacity: _fade(0.0, 0.25),
                    child: _TopBar(
                      uiScale: scale,
                      pantryCount: _pantryCount,
                      onBack: widget.onBack,
                      onPantryTap: widget.onPantryTap ??
                          () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => PantryScreen()),
                              ),
                    ),
                  ),
                  SizedBox(height: 16 * scale),

                  FadeTransition(
                    opacity: _fade(0.04, 0.4),
                    child: SlideTransition(
                      position: _slide(0.04, 0.42),
                      child: _GreetingHeader(
                        uiScale: scale,
                        userName: _resolvedUserName,
                        ambientCtrl: _ambientCtrl,
                      ),
                    ),
                  ),
                  SizedBox(height: 16 * scale),

                  if (widget.referenceProduct != null) ...[
                    FadeTransition(
                      opacity: _fade(0.08, 0.42),
                      child: SlideTransition(
                        position: _slide(0.08, 0.44),
                        child: _ReferenceProductContextBanner(
                          uiScale: scale,
                          product: widget.referenceProduct!,
                        ),
                      ),
                    ),
                    SizedBox(height: 14 * scale),
                  ],

                  FadeTransition(
                    opacity: _fade(0.1, 0.44),
                    child: SlideTransition(
                      position: _slide(0.1, 0.46),
                      child: _SearchBar(
                        uiScale: scale,
                        controller: _searchCtrl,
                        focusNode: _searchFocusNode,
                        isSearchMode: _isSearchMode,
                        onSubmitted: (query) {
                          widget.onSearchSubmitted?.call(query);
                          _executeSearch(query);
                        },
                        onClear: _clearSearch,
                        onMicTap: widget.onMicTap ??
                            () => showVoiceAssistantModal(context, userName: _resolvedUserName),
                        onScanTap: widget.onScanTap ??
                            () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ScanScreen()),
                                ),
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
                        activeTileId: _activeFilterId,
                        onTileTap: (id) {
                          final tile = widget.quickSuggestions.firstWhere(
                            (t) => t.id == id,
                            orElse: () => QuickTile(asset: '', id: id, title: id),
                          );
                          widget.onQuickSuggestionTap?.call(id);
                          _handleTileTap(id, tile.title);
                        },
                        onViewAll: widget.onViewAllSuggestions,
                      ),
                    ),
                  ),
                  SizedBox(height: 20 * scale),

                  FadeTransition(
                    opacity: _fade(0.22, 0.56),
                    child: SlideTransition(
                      position: _slide(0.22, 0.58),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _sectionTitle,
                              style: TextStyle(
                                fontSize: 15.5 * scale,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1B1B2E),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_isSearchMode || _activeFilterId != null)
                            GestureDetector(
                              onTap: _clearSearch,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 3 * scale),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6C4EF5).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Clear',
                                  style: TextStyle(
                                    fontSize: 11 * scale,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF6C4EF5),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10 * scale),

                  FadeTransition(
                    opacity: _fade(0.24, 0.6),
                    child: SlideTransition(
                      position: _slide(0.24, 0.62),
                      child: _DynamicRecommendedCard(
                        uiScale: scale,
                        product: currentProduct,
                        evaluation: evaluation,
                        dietType: _personalization?.dietType ?? _userProfile?.dietType ?? 'Vegetarian',
                        isLoading: _isLoading,
                        errorMessage: _errorMessage,
                        favorited: _favorited,
                        totalCount: _products.length,
                        currentIndex: _currentProductIndex,
                        onFavoriteTap: () {
                          setState(() => _favorited = !_favorited);
                          widget.onFavoriteRecommended?.call();
                        },
                        onAddToPantry: () {
                          if (currentProduct != null) {
                            _handleAddToPantry(currentProduct);
                          }
                        },
                        onCardTap: () {
                          if (currentProduct != null) {
                            _openProductDetails(currentProduct);
                          }
                        },
                        onNextProduct: _products.length > 1
                            ? () {
                                setState(() {
                                  _currentProductIndex = (_currentProductIndex + 1) % _products.length;
                                });
                              }
                            : null,
                        onPrevProduct: _products.length > 1
                            ? () {
                                setState(() {
                                  _currentProductIndex =
                                      (_currentProductIndex - 1 + _products.length) % _products.length;
                                });
                              }
                            : null,
                        onRetry: () => _loadRecommendations(filterId: _activeFilterId),
                      ),
                    ),
                  ),

                  if (_products.length > 1) ...[
                    SizedBox(height: 14 * scale),
                    FadeTransition(
                      opacity: _fade(0.28, 0.64),
                      child: SlideTransition(
                        position: _slide(0.28, 0.66),
                        child: _ProductsListCarousel(
                          uiScale: scale,
                          products: _products,
                          selectedIndex: _currentProductIndex,
                          onSelect: (idx) => setState(() => _currentProductIndex = idx),
                          onOpen: (prod) => _openProductDetails(prod),
                          personalization: _personalization,
                          profile: _userProfile,
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: 16 * scale),

                  FadeTransition(
                    opacity: _fade(0.32, 0.66),
                    child: SlideTransition(
                      position: _slide(0.32, 0.68),
                      child: _SmartPantryAdviceBanner(
                        uiScale: scale,
                        highSugarCount: _smartPantryAdvice?.highSugarCount ?? 0,
                        customMessage: _smartPantryAdvice?.adviceMessage,
                        onReviewPantryTap: widget.onReviewPantryTap ??
                            () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => PantryScreen()),
                                ),
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
                        activeTileId: _activeFilterId,
                        onTileTap: (id) {
                          final tile = widget.categories.firstWhere(
                            (t) => t.id == id,
                            orElse: () => QuickTile(asset: '', id: id, title: id),
                          );
                          widget.onCategoryTap?.call(id);
                          _handleTileTap(id, tile.title);
                        },
                        onViewAll: widget.onViewAllCategories,
                      ),
                    ),
                  ),
                ],
              ),
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
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ScanScreen()),
              );
              break;
            case 2:
              // Already on AI Recommendation screen
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => PantryScreen()),
              );
              break;
            case 4:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              );
              break;
          }
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------
class _TopBar extends StatelessWidget {
  const _TopBar({required this.uiScale, required this.pantryCount, this.onBack, this.onPantryTap});
  final double uiScale;
  final int pantryCount;
  final VoidCallback? onBack;
  final VoidCallback? onPantryTap;

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
                  Text(
                    'AI Product Recommendations',
                    style: TextStyle(
                      fontSize: 15.5 * uiScale,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1B1B2E),
                    ),
                  ),
                  SizedBox(width: 5 * uiScale),
                  Icon(Icons.auto_awesome, size: 14 * uiScale, color: const Color(0xFF9B7BFA)),
                ],
              ),
              Text(
                'Your smart guide to healthier choices',
                style: TextStyle(fontSize: 10.5 * uiScale, color: const Color(0xFF6B6B7B)),
              ),
            ],
          ),
        ),
        _PantryButton(uiScale: uiScale, count: pantryCount, onTap: onPantryTap),
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(widget.icon, size: 18 * widget.uiScale, color: const Color(0xFF1B1B2E)),
        ),
      ),
    );
  }
}

class _PantryButton extends StatefulWidget {
  const _PantryButton({required this.uiScale, required this.count, this.onTap});
  final double uiScale;
  final int count;
  final VoidCallback? onTap;

  @override
  State<_PantryButton> createState() => _PantryButtonState();
}

class _PantryButtonState extends State<_PantryButton> {
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
              child: Icon(Icons.kitchen_outlined, size: 18 * widget.uiScale, color: Colors.white),
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
                  child: Text(
                    '${widget.count}',
                    style: TextStyle(
                      fontSize: 9 * widget.uiScale,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
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
                  Text(
                    'Hi ',
                    style: TextStyle(
                      fontSize: 21 * uiScale,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1B1B2E),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      '$userName! ',
                      style: TextStyle(
                        fontSize: 21 * uiScale,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF6C4EF5),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('👋', style: TextStyle(fontSize: 18 * uiScale)),
                ],
              ),
              SizedBox(height: 4 * uiScale),
              Text(
                'What are you looking for today?',
                style: TextStyle(
                  fontSize: 14 * uiScale,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1B1B2E),
                ),
              ),
              SizedBox(height: 6 * uiScale),
              Text(
                "I'll help you find the healthiest options from real food databases & match your goals.",
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
  const _SearchBar({
    required this.uiScale,
    required this.controller,
    required this.focusNode,
    this.isSearchMode = false,
    this.onSubmitted,
    this.onClear,
    this.onMicTap,
    this.onScanTap,
  });

  final double uiScale;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSearchMode;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final VoidCallback? onMicTap;
  final VoidCallback? onScanTap;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      if (mounted) setState(() => _focused = widget.focusNode.hasFocus);
    });
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(width: 14 * widget.uiScale),
          GestureDetector(
            onTap: () {
              widget.onSubmitted?.call(widget.controller.text);
              widget.focusNode.unfocus();
            },
            child: Icon(Icons.search, size: 19 * widget.uiScale, color: const Color(0xFF9A96A8)),
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              onSubmitted: widget.onSubmitted,
              style: TextStyle(fontSize: 13 * widget.uiScale),
              decoration: InputDecoration(
                hintText: 'Search real products (e.g., oats, almond milk...)',
                hintStyle: TextStyle(color: const Color(0xFFB0ACC2), fontSize: 12 * widget.uiScale),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10 * widget.uiScale,
                  vertical: 14 * widget.uiScale,
                ),
              ),
            ),
          ),
          if (widget.controller.text.isNotEmpty || widget.isSearchMode)
            GestureDetector(
              onTap: widget.onClear,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6 * widget.uiScale),
                child: Icon(Icons.close_rounded, size: 18 * widget.uiScale, color: const Color(0xFF9A96A8)),
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
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(topRight: Radius.circular(15), bottomRight: Radius.circular(15)),
                gradient: LinearGradient(colors: [Color(0xFF6C4EF5), Color(0xFF1E8A4C)]),
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
    this.activeTileId,
    this.onTileTap,
    this.onViewAll,
  });

  final double uiScale;
  final String title;
  final List<QuickTile> tiles;
  final String? activeTileId;
  final ValueChanged<String>? onTileTap;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15.5 * uiScale,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1B1B2E),
              ),
            ),
            const Spacer(),
            if (activeTileId != null && tiles.any((t) => t.id == activeTileId))
              Padding(
                padding: EdgeInsets.only(right: 6 * uiScale),
                child: Text(
                  'Active Filter',
                  style: TextStyle(
                    fontSize: 11 * uiScale,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E8A4C),
                  ),
                ),
              ),
            GestureDetector(
              onTap: onViewAll,
              child: Text(
                'View all',
                style: TextStyle(
                  fontSize: 12 * uiScale,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6C4EF5),
                ),
              ),
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
              final isSelected = tile.id == activeTileId;
              return _Tile(
                uiScale: uiScale,
                asset: tile.asset,
                isSelected: isSelected,
                onTap: () => onTileTap?.call(tile.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatefulWidget {
  const _Tile({required this.uiScale, required this.asset, this.isSelected = false, this.onTap});
  final double uiScale;
  final String asset;
  final bool isSelected;
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
              border: Border.all(
                color: widget.isSelected ? const Color(0xFF6C4EF5) : Colors.transparent,
                width: 2.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.isSelected
                      ? const Color(0xFF6C4EF5).withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Image.asset(widget.asset, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dynamic Recommended Product Card (Populated strictly with real API data)
// ---------------------------------------------------------------------------
class _DynamicRecommendedCard extends StatelessWidget {
  const _DynamicRecommendedCard({
    required this.uiScale,
    required this.product,
    required this.evaluation,
    required this.dietType,
    required this.isLoading,
    this.errorMessage,
    required this.favorited,
    required this.onFavoriteTap,
    this.onAddToPantry,
    this.onCardTap,
    this.onNextProduct,
    this.onPrevProduct,
    this.onRetry,
    this.totalCount = 1,
    this.currentIndex = 0,
  });

  final double uiScale;
  final FoodProduct? product;
  final ProductCompatibility? evaluation;
  final String dietType;
  final bool isLoading;
  final String? errorMessage;
  final bool favorited;
  final VoidCallback onFavoriteTap;
  final VoidCallback? onAddToPantry;
  final VoidCallback? onCardTap;
  final VoidCallback? onNextProduct;
  final VoidCallback? onPrevProduct;
  final VoidCallback? onRetry;
  final int totalCount;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 220 * uiScale,
        padding: EdgeInsets.all(20 * uiScale),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 32 * uiScale,
                height: 32 * uiScale,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.8,
                  valueColor: AlwaysStoppedAnimation(Color(0xFF6C4EF5)),
                ),
              ),
              SizedBox(height: 12 * uiScale),
              Text(
                'Fetching personalized recommendations...',
                style: TextStyle(
                  fontSize: 12 * uiScale,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B6B7B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null && product == null) {
      return Container(
        padding: EdgeInsets.all(20 * uiScale),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.wifi_off_rounded, size: 36 * uiScale, color: const Color(0xFFB02030)),
            SizedBox(height: 10 * uiScale),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12 * uiScale, color: const Color(0xFF3B3B4F)),
            ),
            SizedBox(height: 12 * uiScale),
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C4EF5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
          ],
        ),
      );
    }

    if (product == null) {
      return Container(
        padding: EdgeInsets.all(24 * uiScale),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 40 * uiScale, color: const Color(0xFF9A96A8)),
            SizedBox(height: 10 * uiScale),
            Text(
              'No matching products found',
              style: TextStyle(
                fontSize: 14.5 * uiScale,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1B1B2E),
              ),
            ),
            SizedBox(height: 6 * uiScale),
            Text(
              'Try another goal or search for a different product.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5 * uiScale, color: const Color(0xFF6B6B7B)),
            ),
            if (onRetry != null) ...[
              SizedBox(height: 14 * uiScale),
              TextButton(
                onPressed: onRetry,
                child: const Text('Reset Recommendations', style: TextStyle(color: Color(0xFF6C4EF5), fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      );
    }

    final prod = product!;
    final eval = evaluation ??
      RecommendationService.instance.evaluateCompatibility(prod);

    final displayScore = eval.score;
    final highlights = RecommendationService.instance.generateHighlights(prod);
    final tags = RecommendationService.instance.generateTags(
      prod,
      eval,
      dietType,
    );
    final description = eval.recommendation.isNotEmpty ? eval.recommendation : eval.summary;
    final nutritionSummary = _formatNutritionSummary(prod);

    return GestureDetector(
      onTap: onCardTap,
      child: Container(
        padding: EdgeInsets.all(14 * uiScale),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
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
                        child: prod.imageUrl.trim().isNotEmpty
                            ? Image.network(
                                prod.imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => _fallbackImage(uiScale),
                              )
                            : _fallbackImage(uiScale),
                      ),
                    ),
                    Positioned(
                      top: 6 * uiScale,
                      left: 6 * uiScale,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6 * uiScale,
                          vertical: 3 * uiScale,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE4F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, size: 10 * uiScale, color: const Color(0xFF1E8A4C)),
                            SizedBox(width: 2 * uiScale),
                            Text(
                              'Best Match',
                              style: TextStyle(
                                fontSize: 7.5 * uiScale,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E8A4C),
                              ),
                            ),
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
                            child: Text(
                              prod.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.5 * uiScale,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1B1B2E),
                              ),
                            ),
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
                      if (prod.brand.isNotEmpty && prod.brand.toLowerCase() != 'unknown brand') ...[
                        SizedBox(height: 2 * uiScale),
                        Text(
                          prod.brand,
                          style: TextStyle(
                            fontSize: 10.5 * uiScale,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6C4EF5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      SizedBox(height: 4 * uiScale),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '$displayScore% Match',
                            style: TextStyle(
                              fontSize: 10.5 * uiScale,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E8A4C),
                            ),
                          ),
                          for (final h in highlights) ...[
                            Text('  •  ', style: TextStyle(fontSize: 10.5 * uiScale, color: const Color(0xFF9A96A8))),
                            Text(h, style: TextStyle(fontSize: 10.5 * uiScale, color: const Color(0xFF6B6B7B))),
                          ],
                        ],
                      ),
                      SizedBox(height: 6 * uiScale),
                      Text(
                        description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5 * uiScale,
                          height: 1.35,
                          color: const Color(0xFF3B3B4F),
                        ),
                      ),
                      if (nutritionSummary.isNotEmpty) ...[
                        SizedBox(height: 5 * uiScale),
                        Text(
                          nutritionSummary,
                          style: TextStyle(
                            fontSize: 9.5 * uiScale,
                            height: 1.3,
                            color: const Color(0xFF6B6B7B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10 * uiScale),
            Wrap(
              spacing: 6 * uiScale,
              runSpacing: 6 * uiScale,
              children: tags.map((t) => _Tag(uiScale: uiScale, label: t)).toList(),
            ),
            SizedBox(height: 12 * uiScale),
            Row(
              children: [
                if (totalCount > 1) ...[
                  GestureDetector(
                    onTap: onPrevProduct,
                    child: Container(
                      padding: EdgeInsets.all(5 * uiScale),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF3F0FB),
                      ),
                      child: Icon(Icons.chevron_left_rounded, size: 18 * uiScale, color: const Color(0xFF6C4EF5)),
                    ),
                  ),
                  SizedBox(width: 4 * uiScale),
                  Text(
                    '${currentIndex + 1} of $totalCount',
                    style: TextStyle(
                      fontSize: 10.5 * uiScale,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6B6B7B),
                    ),
                  ),
                  SizedBox(width: 4 * uiScale),
                  GestureDetector(
                    onTap: onNextProduct,
                    child: Container(
                      padding: EdgeInsets.all(5 * uiScale),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF3F0FB),
                      ),
                      child: Icon(Icons.chevron_right_rounded, size: 18 * uiScale, color: const Color(0xFF6C4EF5)),
                    ),
                  ),
                ] else ...[
                  Icon(Icons.touch_app_outlined, size: 13 * uiScale, color: const Color(0xFF9A96A8)),
                  SizedBox(width: 4 * uiScale),
                  Text(
                    'Tap to view AI analysis',
                    style: TextStyle(
                      fontSize: 10.5 * uiScale,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF9A96A8),
                    ),
                  ),
                ],
                const Spacer(),
                _AddToPantryButton(uiScale: uiScale, onTap: onAddToPantry),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackImage(double uiScale) {
    return Container(
      alignment: Alignment.center,
      color: const Color(0xFFEDE8F7),
      child: Icon(
        Icons.restaurant_rounded,
        size: 32 * uiScale,
        color: const Color(0xFF9B7BFA),
      ),
    );
  }

  String _formatNutritionSummary(FoodProduct p) {
    final parts = <String>[];
    if (p.calories != null && p.calories! > 0) parts.add('${p.calories!.toStringAsFixed(0)} kcal');
    if (p.protein != null && p.protein! > 0) parts.add('P: ${p.protein!.toStringAsFixed(1)}g');
    if (p.sugar != null) parts.add('Sugar: ${p.sugar!.toStringAsFixed(1)}g');
    if (p.fiber != null && p.fiber! > 0) parts.add('Fiber: ${p.fiber!.toStringAsFixed(1)}g');
    if (parts.isEmpty) return '';
    return '${p.normalizedBasisLabel}: ${parts.join('  |  ')}';
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.uiScale, required this.label});
  final double uiScale;
  final String label;

  Color get _bg {
    switch (label) {
      case 'High Fiber':
      case 'High Protein':
      case 'Vegetarian':
      case 'Vegan Safe':
      case 'Natural':
        return const Color(0xFFE4F5E9);
      case 'Low Sugar':
      case 'Low Sodium':
      case 'Top Match':
        return const Color(0xFFE3EEFC);
      default:
        return const Color(0xFFFCEBE0);
    }
  }

  Color get _fg {
    switch (label) {
      case 'High Fiber':
      case 'High Protein':
      case 'Vegetarian':
      case 'Vegan Safe':
      case 'Natural':
        return const Color(0xFF1E8A4C);
      case 'Low Sugar':
      case 'Low Sodium':
      case 'Top Match':
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
      child: Text(
        label,
        style: TextStyle(fontSize: 10 * uiScale, fontWeight: FontWeight.w700, color: _fg),
      ),
    );
  }
}

class _AddToPantryButton extends StatefulWidget {
  const _AddToPantryButton({required this.uiScale, this.onTap});
  final double uiScale;
  final VoidCallback? onTap;

  @override
  State<_AddToPantryButton> createState() => _AddToPantryButtonState();
}

class _AddToPantryButtonState extends State<_AddToPantryButton> {
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
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C4EF5).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.kitchen_outlined, color: Colors.white, size: 14 * widget.uiScale),
              SizedBox(width: 5 * widget.uiScale),
              Text(
                'Add to Pantry',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.5 * widget.uiScale,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Smart Pantry Advice banner (Calculated dynamically)
// ---------------------------------------------------------------------------
class _SmartPantryAdviceBanner extends StatelessWidget {
  const _SmartPantryAdviceBanner({
    required this.uiScale,
    required this.highSugarCount,
    this.customMessage,
    this.onReviewPantryTap,
  });

  final double uiScale;
  final int highSugarCount;
  final String? customMessage;
  final VoidCallback? onReviewPantryTap;

  @override
  Widget build(BuildContext context) {
    final message = customMessage ??
        (highSugarCount > 0
            ? 'Your pantry has $highSugarCount high-sugar item${highSugarCount > 1 ? 's' : ''}. Want healthier alternatives?'
            : 'Your pantry items look well-balanced! Explore smart alternatives.');

    return Container(
      padding: EdgeInsets.all(14 * uiScale),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F7EE),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44 * uiScale,
            height: 44 * uiScale,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.kitchen_outlined,
              size: 24 * uiScale,
              color: const Color(0xFF1E8A4C),
            ),
          ),
          SizedBox(width: 12 * uiScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Smart Pantry Advice',
                      style: TextStyle(
                        fontSize: 12.5 * uiScale,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1B1B2E),
                      ),
                    ),
                    SizedBox(width: 6 * uiScale),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6 * uiScale, vertical: 2 * uiScale),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E8A4C),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Live',
                        style: TextStyle(
                          fontSize: 8 * uiScale,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 3 * uiScale),
                Text(
                  message,
                  style: TextStyle(fontSize: 10.5 * uiScale, height: 1.3, color: const Color(0xFF3B3B4F)),
                ),
              ],
            ),
          ),
          SizedBox(width: 8 * uiScale),
          _ReviewPantryButton(uiScale: uiScale, onTap: onReviewPantryTap),
        ],
      ),
    );
  }
}

class _ReviewPantryButton extends StatefulWidget {
  const _ReviewPantryButton({required this.uiScale, this.onTap});
  final double uiScale;
  final VoidCallback? onTap;

  @override
  State<_ReviewPantryButton> createState() => _ReviewPantryButtonState();
}

class _ReviewPantryButtonState extends State<_ReviewPantryButton> {
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
              Text(
                'View Pantry',
                style: TextStyle(
                  fontSize: 10.5 * widget.uiScale,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E8A4C),
                ),
              ),
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
// Bottom nav bar
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
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
                  horizontal: selected ? 10 * uiScale : 6 * uiScale,
                  vertical: 6 * uiScale,
                ),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFEDE7FA) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 18 * uiScale,
                      color: selected ? const Color(0xFF6C4EF5) : const Color(0xFFB0ACC2),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      child: selected
                          ? Padding(
                              padding: EdgeInsets.only(top: 2 * uiScale),
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 8.5 * uiScale,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF6C4EF5),
                                ),
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

class _ReferenceProductContextBanner extends StatelessWidget {
  const _ReferenceProductContextBanner({
    required this.uiScale,
    required this.product,
  });

  final double uiScale;
  final FoodProduct product;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14 * uiScale, vertical: 12 * uiScale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF6C4EF5).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C4EF5).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38 * uiScale,
            height: 38 * uiScale,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C4EF5), Color(0xFF9B7BFA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.auto_awesome_rounded, size: 20 * uiScale, color: Colors.white),
          ),
          SizedBox(width: 12 * uiScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6 * uiScale, vertical: 2 * uiScale),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E8A4C).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'AI RECOMMENDATIONS FOR',
                    style: TextStyle(
                      fontSize: 8.5 * uiScale,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E8A4C),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(height: 3 * uiScale),
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5 * uiScale,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1B1B2E),
                  ),
                ),
                Text(
                  'Showing top healthier options in the same category',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5 * uiScale,
                    color: const Color(0xFF6B6B7B),
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

class _ProductsListCarousel extends StatelessWidget {
  const _ProductsListCarousel({
    required this.uiScale,
    required this.products,
    required this.selectedIndex,
    required this.onSelect,
    required this.onOpen,
    this.personalization,
    this.profile,
  });

  final double uiScale;
  final List<FoodProduct> products;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final ValueChanged<FoodProduct> onOpen;
  final PersonalizationProfile? personalization;
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'All ${products.length} Alternatives',
              style: TextStyle(
                fontSize: 13.5 * uiScale,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1B1B2E),
              ),
            ),
            Text(
              'Tap to preview',
              style: TextStyle(
                fontSize: 10.5 * uiScale,
                color: const Color(0xFF6B6B7B),
              ),
            ),
          ],
        ),
        SizedBox(height: 8 * uiScale),
        SizedBox(
          height: 124 * uiScale,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (_, __) => SizedBox(width: 10 * uiScale),
            itemBuilder: (context, index) {
              final prod = products[index];
              final isSelected = index == selectedIndex;
              final comp = RecommendationService.instance.evaluateCompatibility(
                prod,
                personalization: personalization,
                profile: profile,
              );

              return GestureDetector(
                onTap: () => onSelect(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 112 * uiScale,
                  padding: EdgeInsets.all(8 * uiScale),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF6C4EF5) : Colors.black.withValues(alpha: 0.06),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? const Color(0xFF6C4EF5).withValues(alpha: 0.18)
                            : Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: prod.imageUrl.isNotEmpty
                                ? Image.network(
                                    prod.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _productPlaceholder(uiScale),
                                  )
                                : _productPlaceholder(uiScale),
                          ),
                        ),
                      ),
                      SizedBox(height: 6 * uiScale),
                      Text(
                        prod.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5 * uiScale,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1B1B2E),
                        ),
                      ),
                      SizedBox(height: 2 * uiScale),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              prod.brand.isNotEmpty ? prod.brand : 'Brand',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 8.5 * uiScale,
                                color: const Color(0xFF6B6B7B),
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 4 * uiScale, vertical: 1 * uiScale),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E8A4C).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${comp.score}%',
                              style: TextStyle(
                                fontSize: 8.5 * uiScale,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E8A4C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _productPlaceholder(double uiScale) {
    return Container(
      color: const Color(0xFFF1ECFB),
      child: Center(
        child: Icon(
          Icons.fastfood_rounded,
          color: const Color(0xFF6C4EF5).withValues(alpha: 0.5),
          size: 24 * uiScale,
        ),
      ),
    );
  }
}

