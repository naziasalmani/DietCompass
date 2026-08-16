import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../ai/ai_shopping_screen.dart';
import '../scan/scan_screen.dart';
import '../dashboard/DashboardScreen.dart';

/// DietCompass — My Pantry Screen
/// -----------------------------------------------------------------------/// Reuses your existing product photos where available
/// (assets/images/product_amul.png, assets/images/product_quaker.png).
/// For pantry items you haven't photographed yet, pass an [imageAsset]
/// path of your choosing (e.g. 'assets/images/pantry_honey.png') — if the
/// file isn't in your assets yet, the item gracefully falls back to a
/// soft category icon instead of crashing, so you can drop real photos
/// into the folder whenever you have them.
///
/// Add to pubspec.yaml (skip any already present):
/// ```yaml
/// flutter:
///   assets:
///     - assets/images/product_amul.png
///     - assets/images/product_quaker.png
///     # add your own pantry item photos here as you capture them
/// ```
enum ItemStatus { fresh, expiringSoon, expired, lowStock }

enum PantryCategory { dairy, grains, snacks, beverages, condiments }

extension on PantryCategory {
  String get label {
    switch (this) {
      case PantryCategory.dairy:
        return 'Dairy';
      case PantryCategory.grains:
        return 'Grains';
      case PantryCategory.snacks:
        return 'Snacks';
      case PantryCategory.beverages:
        return 'Beverages';
      case PantryCategory.condiments:
        return 'Condiments';
    }
  }

  IconData get icon {
    switch (this) {
      case PantryCategory.dairy:
        return Icons.icecream_outlined;
      case PantryCategory.grains:
        return Icons.grain;
      case PantryCategory.snacks:
        return Icons.cookie_outlined;
      case PantryCategory.beverages:
        return Icons.local_cafe_outlined;
      case PantryCategory.condiments:
        return Icons.liquor_outlined;
    }
  }

  Color get color {
    switch (this) {
      case PantryCategory.dairy:
        return const Color(0xFF3B82F6);
      case PantryCategory.grains:
        return const Color(0xFF6C4EF5);
      case PantryCategory.snacks:
        return const Color(0xFFE0862E);
      case PantryCategory.beverages:
        return const Color(0xFF1E8A4C);
      case PantryCategory.condiments:
        return const Color(0xFFE0525C);
    }
  }
}

class PantryItem {
  const PantryItem({
    required this.imageAsset,
    required this.name,
    required this.category,
    required this.addedOn,
    required this.quantity,
    required this.status,
    required this.statusDetail,
  });

  final String imageAsset;
  final String name;
  final PantryCategory category;
  final DateTime addedOn;
  final String quantity;
  final ItemStatus status;

  /// e.g. "Exp. in 5 days", "Expired 2 days ago", "Only 1 left"
  final String statusDetail;
}

class PantryScreen extends StatefulWidget {
  PantryScreen({
    super.key,
    List<PantryItem>? items,
    this.onSearchTap,
    this.onFilterTap,
    this.onAddItemTap,
    this.onItemTap,
    this.onViewAllExpiring,
    this.onExploreRecipesTap,
    this.onNavTap,
    this.initialNavIndex = 3,
  }) : items = items ??
            [
              PantryItem(
                imageAsset: 'assets/images/product_amul.jpeg',
                name: 'Amul Toned Milk',
                category: PantryCategory.dairy,
                addedOn: DateTime(2024, 5, 20),
                quantity: '1 L',
                status: ItemStatus.fresh,
                statusDetail: 'Exp. in 5 days',
              ),
              PantryItem(
                imageAsset: 'assets/images/product_quaker.jpeg',
                name: 'Quaker Oats',
                category: PantryCategory.grains,
                addedOn: DateTime(2024, 5, 18),
                quantity: '1 kg',
                status: ItemStatus.expiringSoon,
                statusDetail: 'Exp. in 2 days',
              ),
              PantryItem(
                imageAsset: 'assets/images/pantry_peanut_butter.jpeg',
                name: 'Peanut Butter',
                category: PantryCategory.snacks,
                addedOn: DateTime(2024, 5, 15),
                quantity: '500 g',
                status: ItemStatus.fresh,
                statusDetail: 'Exp. in 25 days',
              ),
              PantryItem(
                imageAsset: 'assets/images/pantry_honey.jpeg',
                name: 'Honey',
                category: PantryCategory.snacks,
                addedOn: DateTime(2024, 5, 10),
                quantity: '250 g',
                status: ItemStatus.expired,
                statusDetail: 'Expired 2 days ago',
              ),
              PantryItem(
                imageAsset: 'assets/images/pantry_green_tea.jpeg',
                name: 'Green Tea',
                category: PantryCategory.beverages,
                addedOn: DateTime(2024, 5, 8),
                quantity: '25 Bags',
                status: ItemStatus.fresh,
                statusDetail: 'Exp. in 60 days',
              ),
              PantryItem(
                imageAsset: 'assets/images/pantry_almonds.jpeg',
                name: 'Almonds',
                category: PantryCategory.snacks,
                addedOn: DateTime(2024, 5, 5),
                quantity: '200 g',
                status: ItemStatus.lowStock,
                statusDetail: 'Only 1 left',
              ),
            ];

  final List<PantryItem> items;
  final VoidCallback? onSearchTap;
  final VoidCallback? onFilterTap;
  final VoidCallback? onAddItemTap;
  final ValueChanged<PantryItem>? onItemTap;
  final VoidCallback? onViewAllExpiring;
  final VoidCallback? onExploreRecipesTap;
  final ValueChanged<int>? onNavTap;
  final int initialNavIndex;

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

enum _TabFilter { all, expiringSoon, expired, lowStock }

class _PantryScreenState extends State<PantryScreen> with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  _TabFilter _tab = _TabFilter.all;
  PantryCategory? _category;
  bool _sortNewest = true;
  late int _navIndex;

  @override
  void initState() {
    super.initState();
    _navIndex = widget.initialNavIndex;
    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  Animation<double> _fade(double s, double e) =>
      CurvedAnimation(parent: _entranceCtrl, curve: Interval(s, e, curve: Curves.easeOut));

  List<PantryItem> get _filtered {
    var list = widget.items.where((item) {
      final tabOk = switch (_tab) {
        _TabFilter.all => true,
        _TabFilter.expiringSoon => item.status == ItemStatus.expiringSoon,
        _TabFilter.expired => item.status == ItemStatus.expired,
        _TabFilter.lowStock => item.status == ItemStatus.lowStock,
      };
      final catOk = _category == null || item.category == _category;
      return tabOk && catOk;
    }).toList();
    list.sort((a, b) => _sortNewest ? b.addedOn.compareTo(a.addedOn) : a.addedOn.compareTo(b.addedOn));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 390).clamp(0.85, 1.25);

    final total = widget.items.length;
    final expiringSoon = widget.items.where((i) => i.status == ItemStatus.expiringSoon).length;
    final expired = widget.items.where((i) => i.status == ItemStatus.expired).length;
    final lowStock = widget.items.where((i) => i.status == ItemStatus.lowStock).length;

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

  SafeArea(
            bottom: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16 * scale, 8 * scale, 16 * scale, 110 * scale),
              physics: const BouncingScrollPhysics(),
              children: [
                FadeTransition(
                  opacity: _fade(0.0, 0.3),
                  child: _Header(uiScale: scale, onSearchTap: widget.onSearchTap, onFilterTap: widget.onFilterTap, onAddItemTap: widget.onAddItemTap),
                ),
                SizedBox(height: 16 * scale),

                FadeTransition(
                  opacity: _fade(0.06, 0.4),
                  child: _StatsRow(
                    uiScale: scale,
                    total: total,
                    expiringSoon: expiringSoon,
                    expired: expired,
                    lowStock: lowStock,
                    activeTab: _tab,
                    onTabSelected: (t) => setState(() => _tab = t),
                  ),
                ),
                SizedBox(height: 14 * scale),

                if (expiringSoon > 0)
                  FadeTransition(
                    opacity: _fade(0.1, 0.44),
                    child: _ExpiringBanner(uiScale: scale, count: expiringSoon, onViewAll: widget.onViewAllExpiring),
                  ),
                SizedBox(height: 14 * scale),

                FadeTransition(
                  opacity: _fade(0.14, 0.48),
                  child: _FilterTabs(
                    uiScale: scale,
                    total: total,
                    expiringSoon: expiringSoon,
                    expired: expired,
                    lowStock: lowStock,
                    active: _tab,
                    onSelected: (t) => setState(() => _tab = t),
                  ),
                ),
                SizedBox(height: 12 * scale),

                FadeTransition(
                  opacity: _fade(0.18, 0.52),
                  child: _CategoryChips(
                    uiScale: scale,
                    selected: _category,
                    onSelected: (c) => setState(() => _category = c),
                  ),
                ),
                SizedBox(height: 18 * scale),

                FadeTransition(
                  opacity: _fade(0.22, 0.56),
                  child: Row(
                    children: [
                      Text('All Items', style: TextStyle(fontSize: 15.5 * scale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _sortNewest = !_sortNewest),
                        child: Row(
                          children: [
                            Text('Sort by: ', style: TextStyle(fontSize: 11.5 * scale, color: const Color(0xFF6B6B7B))),
                            Text(_sortNewest ? 'Newest' : 'Oldest', style: TextStyle(fontSize: 11.5 * scale, fontWeight: FontWeight.w700, color: const Color(0xFF6C4EF5))),
                            Icon(Icons.keyboard_arrow_down, size: 16 * scale, color: const Color(0xFF6C4EF5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10 * scale),

                ..._buildItemRows(scale),

                SizedBox(height: 16 * scale),
                FadeTransition(
                  opacity: _fade(0.5, 0.85),
                  child: _SmartTipBanner(uiScale: scale, onExploreRecipesTap: widget.onExploreRecipesTap),
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
          builder: (_) => const ScanScreen(),
        ),
      );
      break;

    case 2:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AiShoppingScreen(),
        ),
      );
      break;

    case 3:
      break;

    case 4:
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => DashboardScreen(),
    ),
  );
  break;

  }

  widget.onNavTap?.call(i);
},
      ),
    );
  }

  List<Widget> _buildItemRows(double scale) {
    final items = _filtered;
    if (items.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 30 * scale),
          child: Column(
            children: [
              Icon(Icons.inventory_2_outlined, size: 36 * scale, color: const Color(0xFFCFC9E5)),
              SizedBox(height: 8 * scale),
              Text('No items match this filter', style: TextStyle(fontSize: 12.5 * scale, color: const Color(0xFF9A96A8))),
            ],
          ),
        ),
      ];
    }
    return List.generate(items.length, (i) {
      final start = (0.24 + i * 0.05).clamp(0.0, 0.9);
      return FadeTransition(
        opacity: _fade(start, (start + 0.3).clamp(0.0, 1.0)),
        child: Padding(
          padding: EdgeInsets.only(bottom: 10 * scale),
          child: _PantryItemRow(uiScale: scale, item: items[i], onTap: () => widget.onItemTap?.call(items[i])),
        ),
      );
    });
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
// Header
// ---------------------------------------------------------------------------
class _Header extends StatelessWidget {
  const _Header({required this.uiScale, this.onSearchTap, this.onFilterTap, this.onAddItemTap});
  final double uiScale;
  final VoidCallback? onSearchTap;
  final VoidCallback? onFilterTap;
  final VoidCallback? onAddItemTap;

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
                  Text('My Pantry', style: TextStyle(fontSize: 23 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
                  SizedBox(width: 6 * uiScale),
                  Icon(Icons.eco, size: 18 * uiScale, color: const Color(0xFF1E8A4C)),
                ],
              ),
              SizedBox(height: 3 * uiScale),
              Text('Manage your items and never run out of healthy choices.',
                  style: TextStyle(fontSize: 11 * uiScale, color: const Color(0xFF6B6B7B))),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Stats row
// ---------------------------------------------------------------------------
class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.uiScale,
    required this.total,
    required this.expiringSoon,
    required this.expired,
    required this.lowStock,
    required this.activeTab,
    required this.onTabSelected,
  });

  final double uiScale;
  final int total;
  final int expiringSoon;
  final int expired;
  final int lowStock;
  final _TabFilter activeTab;
  final ValueChanged<_TabFilter> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12 * uiScale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              uiScale: uiScale,
              icon: Icons.inventory_2_outlined,
              value: '$total',
              label: 'Total Items',
              bg: const Color(0xFFE4F5E9),
              fg: const Color(0xFF1E8A4C),
              onTap: () => onTabSelected(_TabFilter.all),
            ),
          ),
          SizedBox(width: 8 * uiScale),
          Expanded(
            child: _StatTile(
              uiScale: uiScale,
              icon: Icons.hourglass_bottom_rounded,
              value: '$expiringSoon',
              label: 'Expiring Soon',
              bg: const Color(0xFFFCF2E0),
              fg: const Color(0xFFE0862E),
              onTap: () => onTabSelected(_TabFilter.expiringSoon),
            ),
          ),
          SizedBox(width: 8 * uiScale),
          Expanded(
            child: _StatTile(
              uiScale: uiScale,
              icon: Icons.warning_amber_rounded,
              value: '$expired',
              label: 'Expired Items',
              bg: const Color(0xFFFCEBEB),
              fg: const Color(0xFFE0525C),
              onTap: () => onTabSelected(_TabFilter.expired),
            ),
          ),
          SizedBox(width: 8 * uiScale),
          Expanded(
            child: _StatTile(
              uiScale: uiScale,
              icon: Icons.shopping_cart_outlined,
              value: '$lowStock',
              label: 'Low Stock',
              bg: const Color(0xFFEDE7FA),
              fg: const Color(0xFF6C4EF5),
              onTap: () => onTabSelected(_TabFilter.lowStock),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatefulWidget {
  const _StatTile({
    required this.uiScale,
    required this.icon,
    required this.value,
    required this.label,
    required this.bg,
    required this.fg,
    this.onTap,
  });

  final double uiScale;
  final IconData icon;
  final String value;
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback? onTap;

  @override
  State<_StatTile> createState() => _StatTileState();
}

class _StatTileState extends State<_StatTile> {
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
          padding: EdgeInsets.symmetric(vertical: 12 * widget.uiScale, horizontal: 6 * widget.uiScale),
          decoration: BoxDecoration(color: widget.bg, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(widget.icon, size: 16 * widget.uiScale, color: widget.fg),
              SizedBox(height: 8 * widget.uiScale),
              Text(widget.value, style: TextStyle(fontSize: 19 * widget.uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
              Text(widget.label, style: TextStyle(fontSize: 9 * widget.uiScale, color: const Color(0xFF3B3B4F))),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Expiring soon banner
// ---------------------------------------------------------------------------
class _ExpiringBanner extends StatelessWidget {
  const _ExpiringBanner({required this.uiScale, required this.count, this.onViewAll});
  final double uiScale;
  final int count;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14 * uiScale),
      decoration: BoxDecoration(color: const Color(0xFFFCF2E0), borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Container(
            width: 40 * uiScale,
            height: 40 * uiScale,
            decoration: const BoxDecoration(color: Color(0xFFE0862E), shape: BoxShape.circle),
            child: Icon(Icons.hourglass_bottom_rounded, color: Colors.white, size: 18 * uiScale),
          ),
          SizedBox(width: 12 * uiScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Items Expiring Soon', style: TextStyle(fontSize: 12.5 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
                Text('You have $count items that will expire in the next 7 days.',
                    style: TextStyle(fontSize: 10.5 * uiScale, color: const Color(0xFF3B3B4F))),
              ],
            ),
          ),
          GestureDetector(
            onTap: onViewAll,
            child: Row(
              children: [
                Text('View All', style: TextStyle(fontSize: 11.5 * uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF6C4EF5))),
                Icon(Icons.chevron_right, size: 15 * uiScale, color: const Color(0xFF6C4EF5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter tabs
// ---------------------------------------------------------------------------
class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.uiScale,
    required this.total,
    required this.expiringSoon,
    required this.expired,
    required this.lowStock,
    required this.active,
    required this.onSelected,
  });

  final double uiScale;
  final int total;
  final int expiringSoon;
  final int expired;
  final int lowStock;
  final _TabFilter active;
  final ValueChanged<_TabFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (filter: _TabFilter.all, label: 'All Items ($total)'),
      (filter: _TabFilter.expiringSoon, label: 'Expiring Soon ($expiringSoon)'),
      (filter: _TabFilter.expired, label: 'Expired ($expired)'),
      (filter: _TabFilter.lowStock, label: 'Low Stock ($lowStock)'),
    ];

    return Container(
      padding: EdgeInsets.all(4 * uiScale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((t) {
            final selected = t.filter == active;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 3 * uiScale),
              child: GestureDetector(
                onTap: () => onSelected(t.filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 14 * uiScale, vertical: 10 * uiScale),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF6C4EF5) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    t.label,
                    style: TextStyle(
                      fontSize: 11.5 * uiScale,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : const Color(0xFF6B6B7B),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category chips
// ---------------------------------------------------------------------------
class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.uiScale, required this.selected, required this.onSelected});
  final double uiScale;
  final PantryCategory? selected;
  final ValueChanged<PantryCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40 * uiScale,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _CategoryChip(uiScale: uiScale, icon: Icons.grid_view_rounded, label: 'All', color: const Color(0xFF6C4EF5), selected: selected == null, onTap: () => onSelected(null)),
          SizedBox(width: 8 * uiScale),
          for (final c in PantryCategory.values) ...[
            _CategoryChip(uiScale: uiScale, icon: c.icon, label: c.label, color: c.color, selected: selected == c, onTap: () => onSelected(c)),
            SizedBox(width: 8 * uiScale),
          ],
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.uiScale,
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final double uiScale;
  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12 * uiScale, vertical: 8 * uiScale),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? const Color(0xFF6C4EF5) : const Color(0xFFE4E0F2), width: selected ? 1.6 : 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14 * uiScale, color: color),
            SizedBox(width: 5 * uiScale),
            Text(label, style: TextStyle(fontSize: 11 * uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF1B1B2E))),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pantry item row
// ---------------------------------------------------------------------------
class _PantryItemRow extends StatefulWidget {
  const _PantryItemRow({required this.uiScale, required this.item, this.onTap});
  final double uiScale;
  final PantryItem item;
  final VoidCallback? onTap;

  @override
  State<_PantryItemRow> createState() => _PantryItemRowState();
}

class _PantryItemRowState extends State<_PantryItemRow> {
  double _scale = 1.0;

  (Color, Color, String) get _statusStyle {
    switch (widget.item.status) {
      case ItemStatus.fresh:
        return (const Color(0xFFE4F5E9), const Color(0xFF1E8A4C), 'Fresh');
      case ItemStatus.expiringSoon:
        return (const Color(0xFFFCF2E0), const Color(0xFFE0862E), 'Expiring Soon');
      case ItemStatus.expired:
        return (const Color(0xFFFCEBEB), const Color(0xFFE0525C), 'Expired');
      case ItemStatus.lowStock:
        return (const Color(0xFFEDE7FA), const Color(0xFF6C4EF5), 'Low Stock');
    }
  }

  String get _formattedDate {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final d = widget.item.addedOn;
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = _statusStyle;
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: EdgeInsets.all(10 * widget.uiScale),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 52 * widget.uiScale,
                  height: 52 * widget.uiScale,
                  color: const Color(0xFFF6F3FC),
                  padding: EdgeInsets.all(4 * widget.uiScale),
                  child: Image.asset(
                    widget.item.imageAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      widget.item.category.icon,
                      color: widget.item.category.color,
                      size: 22 * widget.uiScale,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12 * widget.uiScale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.item.name, style: TextStyle(fontSize: 13.5 * widget.uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
                    SizedBox(height: 3 * widget.uiScale),
                    Row(
                      children: [
                        Container(width: 5 * widget.uiScale, height: 5 * widget.uiScale, decoration: BoxDecoration(shape: BoxShape.circle, color: widget.item.category.color)),
                        SizedBox(width: 4 * widget.uiScale),
                        Text(widget.item.category.label, style: TextStyle(fontSize: 10.5 * widget.uiScale, color: const Color(0xFF6B6B7B))),
                      ],
                    ),
                    SizedBox(height: 3 * widget.uiScale),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 10 * widget.uiScale, color: const Color(0xFF9A96A8)),
                        SizedBox(width: 4 * widget.uiScale),
                        Text('Added on $_formattedDate', style: TextStyle(fontSize: 9.5 * widget.uiScale, color: const Color(0xFF9A96A8))),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8 * widget.uiScale, vertical: 3 * widget.uiScale),
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
                    child: Text(label, style: TextStyle(fontSize: 9.5 * widget.uiScale, fontWeight: FontWeight.w700, color: fg)),
                  ),
                  SizedBox(height: 6 * widget.uiScale),
                  Text(widget.item.quantity, style: TextStyle(fontSize: 11 * widget.uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF1B1B2E))),
                  Text(widget.item.statusDetail, style: TextStyle(fontSize: 9.5 * widget.uiScale, color: fg)),
                ],
              ),
              SizedBox(width: 4 * widget.uiScale),
              Icon(Icons.chevron_right, size: 18 * widget.uiScale, color: const Color(0xFFB0ACC2)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Smart tip banner
// ---------------------------------------------------------------------------
class _SmartTipBanner extends StatelessWidget {
  const _SmartTipBanner({required this.uiScale, this.onExploreRecipesTap});
  final double uiScale;
  final VoidCallback? onExploreRecipesTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14 * uiScale),
      decoration: BoxDecoration(color: const Color(0xFFEDE7FA), borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, size: 20 * uiScale, color: const Color(0xFF6C4EF5)),
          SizedBox(width: 10 * uiScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Smart Tip', style: TextStyle(fontSize: 12.5 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF6C4EF5))),
                Text('Items expiring soon are highlighted. Use them in recipes to avoid waste!',
                    style: TextStyle(fontSize: 10.5 * uiScale, height: 1.3, color: const Color(0xFF3B3B4F))),
              ],
            ),
          ),
          SizedBox(width: 8 * uiScale),
          _ExploreRecipesButton(uiScale: uiScale, onTap: onExploreRecipesTap),
        ],
      ),
    );
  }
}

class _ExploreRecipesButton extends StatefulWidget {
  const _ExploreRecipesButton({required this.uiScale, this.onTap});
  final double uiScale;
  final VoidCallback? onTap;

  @override
  State<_ExploreRecipesButton> createState() => _ExploreRecipesButtonState();
}

class _ExploreRecipesButtonState extends State<_ExploreRecipesButton> {
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
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Explore Recipes', style: TextStyle(fontSize: 10.5 * widget.uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF6C4EF5))),
              SizedBox(width: 4 * widget.uiScale),
              Icon(Icons.arrow_forward, size: 12 * widget.uiScale, color: const Color(0xFF6C4EF5)),
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
    (icon: Icons.smart_toy_rounded, label: 'Assistant'),
    (icon: Icons.kitchen_rounded, label: 'Pantry'),
    (icon: Icons.pie_chart_rounded, label: 'Dashboard'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.fromLTRB(14 * uiScale, 0, 14 * uiScale, 10 * uiScale),
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
                padding: EdgeInsets.symmetric(horizontal: selected ? 12 * uiScale : 8 * uiScale, vertical: 6 * uiScale),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFEDE7FA) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, size: 20 * uiScale, color: selected ? const Color(0xFF6C4EF5) : const Color(0xFFB0ACC2)),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      child: selected
                          ? Padding(
                              padding: EdgeInsets.only(top: 3 * uiScale),
                              child: Text(item.label, style: TextStyle(fontSize: 9.5 * uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF6C4EF5))),
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
