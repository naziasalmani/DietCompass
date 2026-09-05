import 'package:flutter/material.dart';
import '../../core/model/food_product.dart';
import '../../core/services/product_analysis_engine.dart';
import '../../core/theme/app_colors.dart';

/// DietCompass — Dedicated Full Nutrition Detail Screen
/// Displays complete nutrition facts, serving context, and product metadata.
class FullNutritionDetailScreen extends StatelessWidget {
  const FullNutritionDetailScreen({
    super.key,
    required this.product,
    this.canonicalAnalysis,
  });

  final FoodProduct product;
  final CanonicalProductAnalysis? canonicalAnalysis;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    final scale = (MediaQuery.of(context).size.shortestSide / 390).clamp(0.85, 1.25).toDouble();

    final basisLabel = product.nutritionBasis ?? product.normalizedBasisLabel;

    final nutrientsList = [
      _NutrientRowData(
        label: 'Calories / Energy',
        value: product.calories != null ? '${product.calories!.round()} kcal' : null,
        icon: Icons.local_fire_department_rounded,
        color: colors.iconOrange,
        bgColor: colors.iconOrangeBg,
      ),
      _NutrientRowData(
        label: 'Protein',
        value: product.protein != null ? '${product.protein!.toStringAsFixed(1)} g' : null,
        icon: Icons.fitness_center_rounded,
        color: colors.iconPurple,
        bgColor: colors.iconPurpleBg,
      ),
      _NutrientRowData(
        label: 'Total Carbohydrates',
        value: product.carbohydrates != null ? '${product.carbohydrates!.toStringAsFixed(1)} g' : null,
        icon: Icons.grain_rounded,
        color: colors.iconBlue,
        bgColor: colors.iconBlueBg,
      ),
      _NutrientRowData(
        label: 'Total Sugars',
        value: product.sugar != null ? '${product.sugar!.toStringAsFixed(1)} g' : null,
        icon: Icons.water_drop_rounded,
        color: colors.iconOrange,
        bgColor: colors.iconOrangeBg,
      ),
      _NutrientRowData(
        label: 'Dietary Fiber',
        value: product.fiber != null ? '${product.fiber!.toStringAsFixed(1)} g' : null,
        icon: Icons.grass_rounded,
        color: colors.iconGreen,
        bgColor: colors.iconGreenBg,
      ),
      _NutrientRowData(
        label: 'Total Fat',
        value: product.fat != null ? '${product.fat!.toStringAsFixed(1)} g' : null,
        icon: Icons.pie_chart_outline_rounded,
        color: colors.iconPurple,
        bgColor: colors.iconPurpleBg,
      ),
      _NutrientRowData(
        label: 'Saturated Fat',
        value: product.saturatedFat != null ? '${product.saturatedFat!.toStringAsFixed(1)} g' : null,
        icon: Icons.opacity_rounded,
        color: colors.iconOrange,
        bgColor: colors.iconOrangeBg,
      ),
      _NutrientRowData(
        label: 'Sodium',
        value: product.sodium != null
            ? (product.sodium! <= 10.0
                ? '${(product.sodium! * 1000).round()} mg'
                : '${product.sodium!.round()} mg')
            : null,
        icon: Icons.grain_outlined,
        color: colors.iconBlue,
        bgColor: colors.iconBlueBg,
      ),
      _NutrientRowData(
        label: 'Salt',
        value: product.salt != null ? '${product.salt!.toStringAsFixed(2)} g' : null,
        icon: Icons.waves_rounded,
        color: colors.textSecondary,
        bgColor: colors.surfaceSecondary,
      ),
    ];

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary, size: 22 * scale),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back to Result',
        ),
        title: Text(
          'Full Nutrition',
          style: TextStyle(
            fontSize: 18 * scale,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: colors.cardBorder, height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20 * scale, vertical: 16 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Header Summary Card
              _buildProductHeader(colors, scale),
              SizedBox(height: 16 * scale),

              // Serving Basis & Quantity Card
              _buildServingBasisCard(colors, scale, basisLabel),
              SizedBox(height: 20 * scale),

              // Nutri-Score & NOVA Badges if available
              if ((product.nutriScore != null && product.nutriScore!.isNotEmpty) ||
                  product.novaGroup != null) ...[
                _buildQualityScoresRow(colors, scale),
                SizedBox(height: 20 * scale),
              ],

              // Complete Nutrition Facts Table Card
              Text(
                'Nutrition Facts ($basisLabel)',
                style: TextStyle(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: 10 * scale),
              _buildNutritionTable(colors, scale, nutrientsList),
              SizedBox(height: 20 * scale),

              // Product Claims if non-empty
              if (product.claims.isNotEmpty) ...[
                Text(
                  'Verified Packaging Claims',
                  style: TextStyle(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: 10 * scale),
                _buildClaimsChips(colors, scale),
                SizedBox(height: 20 * scale),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductHeader(DietCompassThemeColors colors, double scale) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(16 * scale),
      child: Row(
        children: [
          Container(
            width: 54 * scale,
            height: 54 * scale,
            decoration: BoxDecoration(
              color: colors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.cardBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: product.imageUrl.isNotEmpty
                  ? Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.bar_chart_rounded,
                        color: colors.iconBlue,
                        size: 26 * scale,
                      ),
                    )
                  : Icon(
                      Icons.bar_chart_rounded,
                      color: colors.iconBlue,
                      size: 26 * scale,
                    ),
            ),
          ),
          SizedBox(width: 14 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name.trim().isNotEmpty ? product.name.trim() : 'Scanned Food Product',
                  style: TextStyle(
                    fontSize: 15.5 * scale,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (product.brand.trim().isNotEmpty) ...[
                  SizedBox(height: 2 * scale),
                  Text(
                    product.brand.trim(),
                    style: TextStyle(
                      fontSize: 13 * scale,
                      color: colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServingBasisCard(
    DietCompassThemeColors colors,
    double scale,
    String basisLabel,
  ) {
    final hasServingSize = product.servingSize != null && product.servingSize!.trim().isNotEmpty;
    final hasPackageSize = product.packageSize != null && product.packageSize!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.cardBorder),
      ),
      padding: EdgeInsets.all(16 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6 * scale),
                decoration: BoxDecoration(
                  color: colors.iconBlueBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.scale_rounded, size: 16 * scale, color: colors.iconBlue),
              ),
              SizedBox(width: 10 * scale),
              Expanded(
                child: Text(
                  'Serving & Measurement Basis',
                  style: TextStyle(
                    fontSize: 14.5 * scale,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * scale),
          Wrap(
            spacing: 10 * scale,
            runSpacing: 10 * scale,
            children: [
              _buildBasisTile(
                colors: colors,
                scale: scale,
                label: 'Nutrition Basis',
                value: basisLabel,
                highlight: true,
              ),
              if (hasServingSize)
                _buildBasisTile(
                  colors: colors,
                  scale: scale,
                  label: 'Serving Size',
                  value: product.servingSize!.trim(),
                  highlight: false,
                ),
              if (hasPackageSize)
                _buildBasisTile(
                  colors: colors,
                  scale: scale,
                  label: 'Package Weight',
                  value: product.packageSize!.trim(),
                  highlight: false,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasisTile({
    required DietCompassThemeColors colors,
    required double scale,
    required String label,
    required String value,
    required bool highlight,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 8 * scale),
      decoration: BoxDecoration(
        color: highlight ? colors.iconBlueBg : colors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? colors.iconBlue.withValues(alpha: 0.3) : colors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11 * scale,
              color: colors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2 * scale),
          Text(
            value,
            style: TextStyle(
              fontSize: 13 * scale,
              fontWeight: FontWeight.w700,
              color: highlight ? colors.iconBlue : colors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQualityScoresRow(DietCompassThemeColors colors, double scale) {
    return Row(
      children: [
        if (product.nutriScore != null && product.nutriScore!.isNotEmpty)
          Expanded(
            child: Container(
              padding: EdgeInsets.all(12 * scale),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.workspace_premium_rounded, size: 20 * scale, color: colors.iconPurple),
                  SizedBox(width: 8 * scale),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nutri-Score',
                        style: TextStyle(fontSize: 11 * scale, color: colors.textMuted),
                      ),
                      Text(
                        product.nutriScore!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 15 * scale,
                          fontWeight: FontWeight.w800,
                          color: colors.iconPurple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        if (product.nutriScore != null && product.nutriScore!.isNotEmpty && product.novaGroup != null)
          SizedBox(width: 12 * scale),
        if (product.novaGroup != null)
          Expanded(
            child: Container(
              padding: EdgeInsets.all(12 * scale),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.precision_manufacturing_rounded, size: 20 * scale, color: colors.iconOrange),
                  SizedBox(width: 8 * scale),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NOVA Group',
                        style: TextStyle(fontSize: 11 * scale, color: colors.textMuted),
                      ),
                      Text(
                        'Group ${product.novaGroup}',
                        style: TextStyle(
                          fontSize: 15 * scale,
                          fontWeight: FontWeight.w800,
                          color: colors.iconOrange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNutritionTable(
    DietCompassThemeColors colors,
    double scale,
    List<_NutrientRowData> nutrients,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        children: List.generate(nutrients.length, (idx) {
          final item = nutrients[idx];
          final isLast = idx == nutrients.length - 1;
          final isAvailable = item.value != null;

          return Container(
            decoration: BoxDecoration(
              border: isLast ? null : Border(bottom: BorderSide(color: colors.cardBorder)),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 12 * scale),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6 * scale),
                  decoration: BoxDecoration(
                    color: item.bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.icon, size: 16 * scale, color: item.color),
                ),
                SizedBox(width: 12 * scale),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 13.5 * scale,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  isAvailable ? item.value! : 'Not available',
                  style: TextStyle(
                    fontSize: 13.5 * scale,
                    fontWeight: isAvailable ? FontWeight.w700 : FontWeight.w500,
                    color: isAvailable ? colors.textPrimary : colors.textMuted,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildClaimsChips(DietCompassThemeColors colors, double scale) {
    return Wrap(
      spacing: 8 * scale,
      runSpacing: 8 * scale,
      children: product.claims.map((claim) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 6 * scale),
          decoration: BoxDecoration(
            color: colors.iconGreenBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.iconGreen.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_rounded, size: 14 * scale, color: colors.iconGreen),
              SizedBox(width: 6 * scale),
              Text(
                claim,
                style: TextStyle(
                  fontSize: 12.5 * scale,
                  fontWeight: FontWeight.w600,
                  color: colors.iconGreen,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _NutrientRowData {
  const _NutrientRowData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  final String label;
  final String? value;
  final IconData icon;
  final Color color;
  final Color bgColor;
}
