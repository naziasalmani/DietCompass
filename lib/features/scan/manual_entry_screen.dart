import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:diet_compass/core/model/food_product.dart';
import 'package:diet_compass/core/services/scan_history_service.dart';
import 'package:diet_compass/features/scan/ai_analysis_screen.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({
    super.key,
    this.onBack,
    this.onScanLabelTap,
    this.onUploadImageTap,
    this.onNeedHelpTap,
    this.onAnalyze,
  });

  final VoidCallback? onBack;
  final VoidCallback? onScanLabelTap;
  final VoidCallback? onUploadImageTap;
  final VoidCallback? onNeedHelpTap;
  final ValueChanged<Map<String, dynamic>>? onAnalyze;

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _ambientCtrl;

  // Product info
  final _productNameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _servingSizeCtrl = TextEditingController();
  String _servingUnit = 'g';

  // Nutrition facts
  bool _perServing = true;
  bool _showMoreNutrients = false;
  final Map<String, TextEditingController> _nutrientCtrls = {
    for (final n in _NutrientField.basics) n.label: TextEditingController(),
  };
  final Map<String, TextEditingController> _extraNutrientCtrls = {
    for (final n in _NutrientField.extras) n.label: TextEditingController(),
  };

  // Ingredients
  final _ingredientsCtrl = TextEditingController();

  // Allergens
  final Set<String> _selectedAllergens = {};
  bool _showOtherInput = false;
  final _otherAllergenCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _ingredientsCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _ambientCtrl.dispose();
    _productNameCtrl.dispose();
    _brandCtrl.dispose();
    _servingSizeCtrl.dispose();
    _ingredientsCtrl.dispose();
    _otherAllergenCtrl.dispose();
    for (final c in _nutrientCtrls.values) c.dispose();
    for (final c in _extraNutrientCtrls.values) c.dispose();
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

 void _handleAnalyze() {
  final data = <String, dynamic>{
    'productName': _productNameCtrl.text,
    'brand': _brandCtrl.text,
    'servingSize': _servingSizeCtrl.text,
    'servingUnit': _servingUnit,
    'perServing': _perServing,
    'nutrients': {
      for (final e in _nutrientCtrls.entries)
        e.key: e.value.text,
    },
    'extraNutrients': {
      for (final e in _extraNutrientCtrls.entries)
        e.key: e.value.text,
    },
    'ingredients': _ingredientsCtrl.text,
    'allergens': _selectedAllergens.toList(),
  };

    widget.onAnalyze?.call(data);

    final product = FoodProduct(
      barcode: '',
      name: _productNameCtrl.text.isEmpty
          ? 'Unknown Product'
          : _productNameCtrl.text.trim(),
      brand: _brandCtrl.text.isEmpty ? 'Manual Entry' : _brandCtrl.text.trim(),
      imageUrl: '',
      ingredients: _ingredientsCtrl.text.trim(),
      allergens: _selectedAllergens.toList(),
      calories: double.tryParse(_nutrientCtrls['Calories']?.text ?? ''),
      protein: double.tryParse(_nutrientCtrls['Protein']?.text ?? ''),
      carbohydrates: double.tryParse(_nutrientCtrls['Carbs']?.text ?? ''),
      fat: double.tryParse(_nutrientCtrls['Fat']?.text ?? ''),
      fiber: double.tryParse(_nutrientCtrls['Fiber']?.text ?? ''),
      sugar: double.tryParse(_nutrientCtrls['Sugar']?.text ?? ''),
      sodium: double.tryParse(_nutrientCtrls['Sodium']?.text ?? ''),
    );

    ScanHistoryService.instance.saveScan(product);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiAnalysisScreen(
          product: product,
          productName: product.name,
          productSubtitle: product.brand,
          servingInfo:
              '${_servingSizeCtrl.text} $_servingUnit',
        ),
      ),
    );
  }

  @override


  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 390).clamp(0.85, 1.25);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FB),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Ambient blurred glass blobs for the glassmorphism backdrop
          _GlassBackdrop(uiScale: scale, ambientCtrl: _ambientCtrl),

          SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                18 * scale,
                8 * scale,
                18 * scale,
                28 * scale,
              ),
              physics: const BouncingScrollPhysics(),
              children: [
                FadeTransition(
                  opacity: _fade(0.0, 0.3),
                  child: SlideTransition(
                    position: _slide(0.0, 0.35),
                    child: _TopHeader(
                      uiScale: scale,
                      onBack: widget.onBack,
                      onNeedHelpTap: widget.onNeedHelpTap,
                    ),
                  ),
                ),
                SizedBox(height: 16 * scale),

                FadeTransition(
                  opacity: _fade(0.05, 0.35),
                  child: SlideTransition(
                    position: _slide(0.05, 0.4),
                    child: _EntryTabsBar(
                      uiScale: scale,
                      onScanLabelTap: widget.onScanLabelTap,
                      onUploadImageTap: widget.onUploadImageTap,
                    ),
                  ),
                ),
                SizedBox(height: 18 * scale),

                FadeTransition(
                  opacity: _fade(0.12, 0.42),
                  child: SlideTransition(
                    position: _slide(0.12, 0.46),
                    child: _GlassCard(
  uiScale: scale,
  child: _ProductInfoSection(
    uiScale: scale,
    productNameCtrl: _productNameCtrl,
    brandCtrl: _brandCtrl,
    servingSizeCtrl: _servingSizeCtrl,
    selectedUnit: _servingUnit,
    onUnitChanged: (v) => setState(() => _servingUnit = v),
  ),
),
                  ),
                ),
                SizedBox(height: 16 * scale),

                FadeTransition(
                  opacity: _fade(0.18, 0.5),
                  child: SlideTransition(
                    position: _slide(0.18, 0.54),
                    child: _GlassCard(
                      uiScale: scale,
                      child: _NutritionFactsSection(
                        uiScale: scale,
                        perServing: _perServing,
                        onToggle: (v) => setState(() => _perServing = v),
                        controllers: _nutrientCtrls,
                        showMore: _showMoreNutrients,
                        onToggleMore: () => setState(
                          () => _showMoreNutrients = !_showMoreNutrients,
                        ),
                        extraControllers: _extraNutrientCtrls,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16 * scale),

                FadeTransition(
                  opacity: _fade(0.24, 0.56),
                  child: SlideTransition(
                    position: _slide(0.24, 0.6),
                    child: _GlassCard(
                      uiScale: scale,
                      child: _IngredientsSection(
                        uiScale: scale,
                        controller: _ingredientsCtrl,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16 * scale),

                FadeTransition(
                  opacity: _fade(0.3, 0.62),
                  child: SlideTransition(
                    position: _slide(0.3, 0.66),
                    child: _GlassCard(
                      uiScale: scale,
                      child: _AllergensSection(
                        uiScale: scale,
                        selected: _selectedAllergens,
                        showOtherInput: _showOtherInput,
                        otherCtrl: _otherAllergenCtrl,
                        onToggleOtherInput: () => setState(
                          () => _showOtherInput = !_showOtherInput,
                        ),
                        onToggle: (name) => setState(() {
                          if (_selectedAllergens.contains(name)) {
                            _selectedAllergens.remove(name);
                          } else {
                            _selectedAllergens.add(name);
                          }
                        }),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 18 * scale),

                FadeTransition(
                  opacity: _fade(0.38, 0.7),
                  child: SlideTransition(
                    position: _slide(0.38, 0.74),
                    child: _AiHelperCard(
                      uiScale: scale,
                      ambientCtrl: _ambientCtrl,
                    ),
                  ),
                ),
                SizedBox(height: 18 * scale),

                FadeTransition(
                  opacity: _fade(0.46, 0.8),
                  child: SlideTransition(
                    position: _slide(0.46, 0.84),
                    child: _AnalyzeButton(
                      uiScale: scale,
                      onTap: _handleAnalyze,
                    ),
                  ),
                ),
                SizedBox(height: 10 * scale),

                FadeTransition(
                  opacity: _fade(0.5, 0.85),
                  child: _PrivacyNote(uiScale: scale),
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
// Ambient glass backdrop — soft blurred colour blobs behind the frosted cards
// ---------------------------------------------------------------------------
class _GlassBackdrop extends StatelessWidget {
  const _GlassBackdrop({required this.uiScale, required this.ambientCtrl});
  final double uiScale;
  final AnimationController ambientCtrl;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ambientCtrl,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(ambientCtrl.value);
        return Stack(
          fit: StackFit.expand,
          children: [
            Container(color: const Color(0xFFF3F0FB)),
            Positioned(
              top: -80 + t * 16,
              left: -60,
              child: _blob(220 * uiScale, const Color(0xFF6C4EF5)),
            ),
            Positioned(
              top: 220 - t * 20,
              right: -70,
              child: _blob(190 * uiScale, const Color(0xFF1E8A4C)),
            ),
            Positioned(
              bottom: -60 + t * 12,
              left: -40,
              child: _blob(180 * uiScale, const Color(0xFF3B82F6)),
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
              color: color.withValues(alpha: 0.22),
            ),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Reusable frosted glassmorphism card
// ---------------------------------------------------------------------------
class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.uiScale, required this.child, this.padding});
  final double uiScale;
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding ?? EdgeInsets.all(16 * uiScale),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.75), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C4EF5).withValues(alpha: 0.08),
                blurRadius: 24,
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

// ---------------------------------------------------------------------------
// Step number badge (1 / 2 / 3 / 4)
// ---------------------------------------------------------------------------
class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.uiScale, required this.number});
  final double uiScale;
  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24 * uiScale,
      height: 24 * uiScale,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF6C4EF5), Color(0xFF8E6EF7)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12.5 * uiScale,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.uiScale,
    required this.number,
    required this.title,
    this.trailing,
  });
  final double uiScale;
  final int number;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepBadge(uiScale: uiScale, number: number),
        SizedBox(width: 8 * uiScale),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15 * uiScale,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1B1B2E),
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Top header — back button, title, subtitle, Need Help pill
// ---------------------------------------------------------------------------
class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.uiScale, this.onBack, this.onNeedHelpTap});
  final double uiScale;
  final VoidCallback? onBack;
  final VoidCallback? onNeedHelpTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CircleIconButton(
          uiScale: uiScale,
          icon: Icons.arrow_back_rounded,
          onTap: onBack,
        ),
        SizedBox(width: 10 * uiScale),
        Expanded(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Manual Nutrition Entry ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17.5 * uiScale,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1B1B2E),
                    ),
                  ),
                  Icon(
                    Icons.auto_awesome,
                    size: 14 * uiScale,
                    color: const Color(0xFF6C4EF5),
                  ),
                ],
              ),
              SizedBox(height: 2 * uiScale),
              Text(
                'Enter nutrition facts from any food package',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5 * uiScale,
                  color: const Color(0xFF6B6B7B),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 6 * uiScale),
        _NeedHelpPill(uiScale: uiScale, onTap: onNeedHelpTap),
      ],
    );
  }
}

class _CircleIconButton extends StatefulWidget {
  const _CircleIconButton({
    required this.uiScale,
    required this.icon,
    this.onTap,
  });
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
      onTap: widget.onTap ?? () => Navigator.maybePop(context),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 40 * widget.uiScale,
          height: 40 * widget.uiScale,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.75),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            size: 18 * widget.uiScale,
            color: const Color(0xFF6C4EF5),
          ),
        ),
      ),
    );
  }
}

class _NeedHelpPill extends StatefulWidget {
  const _NeedHelpPill({required this.uiScale, this.onTap});
  final double uiScale;
  final VoidCallback? onTap;

  @override
  State<_NeedHelpPill> createState() => _NeedHelpPillState();
}

class _NeedHelpPillState extends State<_NeedHelpPill> {
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
          padding: EdgeInsets.symmetric(
            horizontal: 9 * widget.uiScale,
            vertical: 7 * widget.uiScale,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD9CDF5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.help_outline_rounded,
                size: 12 * widget.uiScale,
                color: const Color(0xFF6C4EF5),
              ),
              SizedBox(width: 4 * widget.uiScale),
              Text(
                'Need Help?',
                style: TextStyle(
                  fontSize: 10.5 * widget.uiScale,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6C4EF5),
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
// Tabs bar — Scan Label / Upload Image / Manual Entry
// ---------------------------------------------------------------------------
class _EntryTabsBar extends StatelessWidget {
  const _EntryTabsBar({
    required this.uiScale,
    this.onScanLabelTap,
    this.onUploadImageTap,
  });
  final double uiScale;
  final VoidCallback? onScanLabelTap;
  final VoidCallback? onUploadImageTap;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      uiScale: uiScale,
      padding: EdgeInsets.symmetric(
        horizontal: 6 * uiScale,
        vertical: 6 * uiScale,
      ),
      child: Row(
        children: [
          _EntryTab(
            uiScale: uiScale,
            icon: Icons.qr_code_scanner_rounded,
            label: 'Scan Label',
            selected: false,
            onTap: onScanLabelTap,
          ),
          _EntryTab(
            uiScale: uiScale,
            icon: Icons.image_outlined,
            label: 'Upload Image',
            selected: false,
            onTap: onUploadImageTap,
          ),
          _EntryTab(
            uiScale: uiScale,
            icon: Icons.edit_note_rounded,
            label: 'Manual Entry',
            selected: true,
            onTap: null,
          ),
        ],
      ),
    );
  }
}

class _EntryTab extends StatelessWidget {
  const _EntryTab({
    required this.uiScale,
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
  });
  final double uiScale;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(vertical: 10 * uiScale),
          decoration: BoxDecoration(
            color: selected ? Colors.white.withValues(alpha: 0.85) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: selected
                ? Border(
                    bottom: const BorderSide(color: Color(0xFF6C4EF5), width: 2),
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16 * uiScale,
                color: selected
                    ? const Color(0xFF6C4EF5)
                    : const Color(0xFFB0ACC2),
              ),
              SizedBox(height: 3 * uiScale),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5 * uiScale,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected
                      ? const Color(0xFF6C4EF5)
                      : const Color(0xFFB0ACC2),
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
// Reusable frosted text field
// ---------------------------------------------------------------------------
class _GlassTextField extends StatelessWidget {
  const _GlassTextField({
    required this.uiScale,
    required this.controller,
    required this.hint,
    this.icon,
    this.trailing,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
  });

  final double uiScale;
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final Widget? trailing;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3DDF5)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 12.5 * uiScale, color: const Color(0xFF1B1B2E)),
        decoration: InputDecoration(
          counterText: '',
          hintText: hint,
          hintStyle: TextStyle(fontSize: 12 * uiScale, color: const Color(0xFFB0ACC2)),
          prefixIcon: icon == null
              ? null
              : Padding(
                  padding: EdgeInsets.only(left: 12 * uiScale, right: 6 * uiScale),
                  child: Icon(icon, size: 16 * uiScale, color: const Color(0xFF6C4EF5)),
                ),
          prefixIconConstraints: BoxConstraints(minWidth: 32 * uiScale),
          suffixIcon: trailing,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: icon == null ? 14 * uiScale : 4 * uiScale,
            vertical: 13 * uiScale,
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.uiScale, required this.text, this.required = false});
  final double uiScale;
  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6 * uiScale),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 12 * uiScale,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1B1B2E),
          ),
          children: [
            TextSpan(text: text),
            if (required)
              const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFE0862E))),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 1 — Product Information
// ---------------------------------------------------------------------------
class _ProductInfoSection extends StatelessWidget {
  const _ProductInfoSection({
    required this.uiScale,
    required this.productNameCtrl,
    required this.brandCtrl,
    required this.servingSizeCtrl,
    required this.selectedUnit,
    required this.onUnitChanged,
  });

  final double uiScale;
  final TextEditingController productNameCtrl;
  final TextEditingController brandCtrl;
  final TextEditingController servingSizeCtrl;
  final String selectedUnit;
  final ValueChanged<String> onUnitChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(uiScale: uiScale, number: 1, title: 'Product Information'),
        SizedBox(height: 14 * uiScale),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 340;
            final nameField = Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    _FieldLabel(
      uiScale: uiScale,
      text: 'Product Name',
      required: true,
    ),
    _GlassTextField(
      uiScale: uiScale,
      controller: productNameCtrl,
      hint: 'Enter product name',
      icon: Icons.deblur_rounded,
    ),
  ],
);

final brandField = Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    _FieldLabel(
      uiScale: uiScale,
      text: 'Brand (Optional)',
    ),
    _GlassTextField(
      uiScale: uiScale,
      controller: brandCtrl,
      hint: 'Enter brand name',
      icon: Icons.storefront_rounded,
    ),
  ],
);
            if (narrow) {
              return Column(
  children: [
    nameField,
    SizedBox(height: 12 * uiScale),
    brandField,
  ],
);
            }
            return Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Expanded(child: nameField),
    SizedBox(width: 12 * uiScale),
    Expanded(child: brandField),
  ],
);
          },
        ),
        SizedBox(height: 12 * uiScale),
        _FieldLabel(uiScale: uiScale, text: 'Serving Size', required: true),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _GlassTextField(
                uiScale: uiScale,
                controller: servingSizeCtrl,
                hint: 'e.g., 40 g / 1 cup / 100 ml',
                icon: Icons.restaurant_rounded,
              ),
            ),
            SizedBox(width: 10 * uiScale),
            _UnitToggleGroup(
              uiScale: uiScale,
              selected: selectedUnit,
              onChanged: onUnitChanged,
            ),
          ],
        ),
      ],
    );
  }
}

class _UnitToggleGroup extends StatelessWidget {
  const _UnitToggleGroup({
    required this.uiScale,
    required this.selected,
    required this.onChanged,
  });
  final double uiScale;
  final String selected;
  final ValueChanged<String> onChanged;

  static const _units = ['g', 'ml', 'cup'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3 * uiScale),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3DDF5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _units.map((u) {
          final isSelected = u == selected;
          return GestureDetector(
            onTap: () => onChanged(u),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              margin: EdgeInsets.symmetric(horizontal: 2 * uiScale),
              padding: EdgeInsets.symmetric(
                horizontal: 10 * uiScale,
                vertical: 9 * uiScale,
              ),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6C4EF5) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                u,
                style: TextStyle(
                  fontSize: 11.5 * uiScale,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF6B6B7B),
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
// Section 2 — Nutrition Facts
// ---------------------------------------------------------------------------
class _NutrientField {
  const _NutrientField(this.label, this.unit, this.asset, this.color);
  final String label;
  final String unit;
  final String asset;
  final Color color;

  static const basics = [
    _NutrientField('Calories', 'kcal', 'assets/images/calories.jpeg', Color(0xFFE0862E)),
    _NutrientField('Protein', 'g', 'assets/images/protein.jpeg', Color(0xFF1E8A4C)),
    _NutrientField('Carbohydrates', 'g', 'assets/images/carbohydrate.jpeg', Color(0xFF6C4EF5)),
    _NutrientField('Total Fat', 'g', 'assets/images/fat.jpeg', Color(0xFFE0B32E)),
    _NutrientField('Fibre', 'g', 'assets/images/fibre.jpeg', Color(0xFF1E8A4C)),
    _NutrientField('Sugar', 'g', 'assets/images/sugar.jpeg', Color(0xFFE84D6B)),
    _NutrientField('Sodium', 'mg', 'assets/images/sodium.jpeg', Color(0xFF3B82F6)),
  ];

  static const extras = [
    _NutrientField('Saturated Fat', 'g', 'assets/images/saturated_fat.jpeg', Color(0xFFE0B32E)),
    _NutrientField('Cholesterol', 'mg', 'assets/images/cholesterol.jpeg', Color(0xFFE0862E)),
    _NutrientField('Calcium', 'mg', 'assets/images/calcium.jpeg', Color(0xFFB0ACC2)),
    _NutrientField('Iron', 'mg', 'assets/images/iron.jpeg', Color(0xFF6B6B7B)),
  ];
}

class _NutritionFactsSection extends StatelessWidget {
  const _NutritionFactsSection({
    required this.uiScale,
    required this.perServing,
    required this.onToggle,
    required this.controllers,
    required this.showMore,
    required this.onToggleMore,
    required this.extraControllers,
  });

  final double uiScale;
  final bool perServing;
  final ValueChanged<bool> onToggle;
  final Map<String, TextEditingController> controllers;
  final bool showMore;
  final VoidCallback onToggleMore;
  final Map<String, TextEditingController> extraControllers;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  _StepBadge(uiScale: uiScale, number: 2),
                  SizedBox(width: 8 * uiScale),
                  Flexible(
                    child: Text(
                      'Nutrition Facts',
                      style: TextStyle(
                        fontSize: 15 * uiScale,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1B1B2E),
                      ),
                    ),
                  ),
                  SizedBox(width: 4 * uiScale),
                  Icon(Icons.info_outline_rounded,
                      size: 14 * uiScale, color: const Color(0xFFB0ACC2)),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 10 * uiScale),
        _PerServingToggle(uiScale: uiScale, perServing: perServing, onToggle: onToggle),
        SizedBox(height: 14 * uiScale),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth < 340 ? 2 : 4;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _NutrientField.basics.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 10 * uiScale,
                crossAxisSpacing: 10 * uiScale,
                childAspectRatio: 1.45,
              ),
              itemBuilder: (context, i) {
                final n = _NutrientField.basics[i];
                return _NutrientCell(
                  uiScale: uiScale,
                  field: n,
                  controller: controllers[n.label]!,
                );
              },
            );
          },
        ),
        SizedBox(height: 12 * uiScale),
        GestureDetector(
          onTap: onToggleMore,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12 * uiScale,
              vertical: 12 * uiScale,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF1ECFB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 26 * uiScale,
                  height: 26 * uiScale,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6C4EF5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add, size: 15 * uiScale, color: Colors.white),
                ),
                SizedBox(width: 10 * uiScale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add More Nutrients',
                        style: TextStyle(
                          fontSize: 12.5 * uiScale,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF6C4EF5),
                        ),
                      ),
                      Text(
                        'Saturated Fat, Cholesterol, Calcium, Iron & more',
                        style: TextStyle(
                          fontSize: 10.5 * uiScale,
                          color: const Color(0xFF6B6B7B),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: showMore ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.chevron_right_rounded,
                      size: 20 * uiScale, color: const Color(0xFF6C4EF5)),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: showMore
              ? Padding(
                  padding: EdgeInsets.only(top: 12 * uiScale),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = constraints.maxWidth < 340 ? 2 : 4;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _NutrientField.extras.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          mainAxisSpacing: 10 * uiScale,
                          crossAxisSpacing: 10 * uiScale,
                          childAspectRatio: 0.92,
                        ),
                        itemBuilder: (context, i) {
                          final n = _NutrientField.extras[i];
                          return _NutrientCell(
                            uiScale: uiScale,
                            field: n,
                            controller: extraControllers[n.label]!,
                            fallbackIcon: Icons.science_outlined,
                          );
                        },
                      );
                    },
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _PerServingToggle extends StatelessWidget {
  const _PerServingToggle({
    required this.uiScale,
    required this.perServing,
    required this.onToggle,
  });
  final double uiScale;
  final bool perServing;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3 * uiScale),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3DDF5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(vertical: 9 * uiScale),
                decoration: BoxDecoration(
                  color: !perServing ? const Color(0xFF6C4EF5) : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Per 100g',
                  style: TextStyle(
                    fontSize: 11.5 * uiScale,
                    fontWeight: FontWeight.w700,
                    color: !perServing ? Colors.white : const Color(0xFF6B6B7B),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(vertical: 9 * uiScale),
                decoration: BoxDecoration(
                  color: perServing ? const Color(0xFF6C4EF5) : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add,
                        size: 12 * uiScale,
                        color: perServing ? Colors.white : const Color(0xFF6B6B7B)),
                    SizedBox(width: 3 * uiScale),
                    Text(
                      'Per Serving',
                      style: TextStyle(
                        fontSize: 11.5 * uiScale,
                        fontWeight: FontWeight.w700,
                        color: perServing ? Colors.white : const Color(0xFF6B6B7B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NutrientCell extends StatelessWidget {
  const _NutrientCell({
    required this.uiScale,
    required this.field,
    required this.controller,
    this.fallbackIcon,
  });
  final double uiScale;
  final _NutrientField field;
  final TextEditingController controller;
  final IconData? fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(6 * uiScale),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEAF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              field.asset.isNotEmpty
    ? Image.asset(
        field.asset,
        width: 70 * uiScale,
        height: 70 * uiScale,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          fallbackIcon ?? Icons.circle,
          size: 30 * uiScale,
          color: field.color,
        ),
      )
                  : Icon(fallbackIcon ?? Icons.circle, size: 14 * uiScale, color: field.color),
            ],
          ),
          SizedBox(height: 2 * uiScale),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontSize: 13 * uiScale,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B1B2E),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '0',
                    hintStyle: TextStyle(color: const Color(0xFFB0ACC2)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              Text(
                field.unit,
                style: TextStyle(
                  fontSize: 9.5 * uiScale,
                  color: const Color(0xFFB0ACC2),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 3 — Ingredients
// ---------------------------------------------------------------------------
class _IngredientsSection extends StatelessWidget {
  const _IngredientsSection({required this.uiScale, required this.controller});
  final double uiScale;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(uiScale: uiScale, number: 3, title: 'Ingredients'),
        SizedBox(height: 12 * uiScale),
        _GlassTextField(
          uiScale: uiScale,
          controller: controller,
          hint: 'Enter ingredients listed on the package...',
          maxLines: 4,
          maxLength: 500,
        ),
        SizedBox(height: 4 * uiScale),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${controller.text.length}/500',
            style: TextStyle(fontSize: 10 * uiScale, color: const Color(0xFFB0ACC2)),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Section 4 — Allergens
// ---------------------------------------------------------------------------
class _AllergenItem {
  const _AllergenItem(this.name, this.asset, this.color, {this.fallbackIcon});
  final String name;
  final String asset;
  final Color color;
  final IconData? fallbackIcon;

  static const items = [
    _AllergenItem('Milk', 'assets/images/milk.jpeg', Color(0xFF3B82F6)),
    _AllergenItem('Egg', 'assets/images/egg.jpeg', Color(0xFFE0862E)),
    _AllergenItem('Peanut', 'assets/images/peanut.jpeg', Color(0xFFB2662E)),
    _AllergenItem('Tree Nuts', 'assets/images/tree_nut.jpeg', Color(0xFF8A5A2E)),
    _AllergenItem('Soy', 'assets/images/soy.jpeg', Color(0xFF1E8A4C)),
    _AllergenItem('Wheat', 'assets/images/wheat.jpeg', Color(0xFFE0B32E)),
    _AllergenItem('Fish', 'assets/images/fish.jpeg', Color(0xFF3B82F6)),
    _AllergenItem('Shellfish', 'assets/images/shellfish.jpeg', Color(0xFFE84D6B), fallbackIcon: Icons.set_meal_rounded),
    _AllergenItem('Sesame', 'assets/images/sesame.jpeg', Color(0xFFE0862E)),
    _AllergenItem('Other', 'assets/images/other.jpeg', Color(0xFF6C4EF5)),
  ];
}

class _AllergensSection extends StatelessWidget {
  const _AllergensSection({
    required this.uiScale,
    required this.selected,
    required this.onToggle,
    required this.showOtherInput,
    required this.otherCtrl,
    required this.onToggleOtherInput,
  });

  final double uiScale;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final bool showOtherInput;
  final TextEditingController otherCtrl;
  final VoidCallback onToggleOtherInput;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StepBadge(uiScale: uiScale, number: 4),
            SizedBox(width: 8 * uiScale),
            Text(
              'Allergens',
              style: TextStyle(
                fontSize: 15 * uiScale,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1B1B2E),
              ),
            ),
            SizedBox(width: 6 * uiScale),
            Expanded(
              child: Text(
                'Select all that apply',
                style: TextStyle(fontSize: 10.5 * uiScale, color: const Color(0xFF6B6B7B)),
              ),
            ),
            GestureDetector(
              onTap: onToggleOtherInput,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 9 * uiScale,
                  vertical: 6 * uiScale,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE7FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 12 * uiScale, color: const Color(0xFF6C4EF5)),
                    SizedBox(width: 3 * uiScale),
                    Text(
                      'Add Other',
                      style: TextStyle(
                        fontSize: 10.5 * uiScale,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6C4EF5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: showOtherInput
              ? Padding(
                  padding: EdgeInsets.only(top: 10 * uiScale, bottom: 4 * uiScale),
                  child: _GlassTextField(
                    uiScale: uiScale,
                    controller: otherCtrl,
                    hint: 'Type a custom allergen...',
                    icon: Icons.edit_rounded,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        SizedBox(height: 12 * uiScale),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth < 340 ? 2 : 4;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _AllergenItem.items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 10 * uiScale,
                crossAxisSpacing: 10 * uiScale,
                childAspectRatio: 1.55,
              ),
              itemBuilder: (context, i) {
                final a = _AllergenItem.items[i];
                final isSelected = selected.contains(a.name);
                return _AllergenChip(
                  uiScale: uiScale,
                  item: a,
                  selected: isSelected,
                  onTap: () => onToggle(a.name),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _AllergenChip extends StatelessWidget {
  const _AllergenChip({
    required this.uiScale,
    required this.item,
    required this.selected,
    required this.onTap,
  });
  final double uiScale;
  final _AllergenItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: 9 * uiScale, vertical: 8 * uiScale),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF1ECFB) : Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? const Color(0xFF6C4EF5) : const Color(0xFFEDEAF7),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            item.asset.isNotEmpty
                ? Image.asset(
                    item.asset,
                    width: 70 * uiScale,
                    height: 70 * uiScale,
                    errorBuilder: (_, __, ___) => Icon(
                      item.fallbackIcon ?? Icons.circle,
                      size: 14 * uiScale,
                      color: item.color,
                    ),
                  )
                : Icon(item.fallbackIcon ?? Icons.circle, size: 14 * uiScale, color: item.color),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 15 * uiScale,
              height: 15 * uiScale,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF6C4EF5) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: selected ? const Color(0xFF6C4EF5) : const Color(0xFFD9CDF5),
                  width: 1.4,
                ),
              ),
              child: selected
                  ? Icon(Icons.check, size: 11 * uiScale, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AI helper card (real robot image, floating)
// ---------------------------------------------------------------------------
class _AiHelperCard extends StatelessWidget {
  const _AiHelperCard({required this.uiScale, required this.ambientCtrl});
  final double uiScale;
  final AnimationController ambientCtrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
  clipBehavior: Clip.none,
  children: [
    Padding(
      padding: EdgeInsets.only(top: 35 * uiScale),
      child: _GlassCard(
        uiScale: uiScale,
        child: Padding(
          padding: EdgeInsets.only(
            left: 95 * uiScale, // space for robot
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Let AI do the heavy lifting!',
                      style: TextStyle(
                        fontSize: 15 * uiScale,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1B1B2E),
                      ),
                    ),
                  ),
                  SizedBox(width: 4 * uiScale),
                  Icon(
                    Icons.auto_awesome,
                    size: 14 * uiScale,
                    color: const Color(0xFF6C4EF5),
                  ),
                ],
              ),
              SizedBox(height: 6 * uiScale),
              Text(
                'Our AI will analyze the nutrition data and provide health insights, product rating and healthier options.',
                style: TextStyle(
                  fontSize: 11.5 * uiScale,
                  height: 1.4,
                  color: const Color(0xFF6B6B7B),
                ),
              ),
            ],
          ),
        ),
      ),
    ),

    Positioned(
      left: -8 * uiScale,
      top: 20 * uiScale,
      child: AnimatedBuilder(
        animation: ambientCtrl,
        builder: (context, child) {
          final bob = math.sin(ambientCtrl.value * math.pi) * 5;

          return Transform.translate(
            offset: Offset(0, -bob),
            child: child,
          );
        },
        child: Image.asset(
          'assets/images/robot_pointing.png',
          width: 130 * uiScale,
          height: 150 * uiScale,
          fit: BoxFit.contain,
        ),
      ),
    ),
  ],
);
  }
}

// ---------------------------------------------------------------------------
// Bottom gradient CTA — "Analyze with AI"
// ---------------------------------------------------------------------------
class _AnalyzeButton extends StatefulWidget {
  const _AnalyzeButton({required this.uiScale, this.onTap});
  final double uiScale;
  final VoidCallback? onTap;

  @override
  State<_AnalyzeButton> createState() => _AnalyzeButtonState();
}

class _AnalyzeButtonState extends State<_AnalyzeButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16 * widget.uiScale),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF6C4EF5), Color(0xFF1E8A4C)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C4EF5).withValues(alpha: 0.32),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 16 * widget.uiScale),
              SizedBox(width: 8 * widget.uiScale),
              Text(
                'Analyze with AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15 * widget.uiScale,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: 8 * widget.uiScale),
              Container(
                width: 26 * widget.uiScale,
                height: 26 * widget.uiScale,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward, color: Colors.white, size: 14 * widget.uiScale),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({required this.uiScale});
  final double uiScale;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline_rounded, size: 12 * uiScale, color: const Color(0xFFB0ACC2)),
        SizedBox(width: 5 * uiScale),
        Text(
          'Your data is private and secure with us.',
          style: TextStyle(fontSize: 10.5 * uiScale, color: const Color(0xFFB0ACC2)),
        ),
      ],
    );
  }
}
