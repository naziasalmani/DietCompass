import 'package:flutter/material.dart';
import '../../core/model/ai_analysis_model.dart';
import '../../core/model/food_product.dart';
import '../../core/services/ingredient_intelligence_service.dart';
import '../../core/services/product_analysis_engine.dart';
import '../../core/theme/app_colors.dart';

/// DietCompass — Dedicated Ingredients Detail Screen
/// Displays full ingredient list in original order and highlights ingredient intelligence findings.
class IngredientsDetailScreen extends StatelessWidget {
  const IngredientsDetailScreen({
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

    final intel = IngredientIntelligenceService.instance.analyze(product);

    final rawIngredients = product.ingredients.trim();
    final hasIngredients = rawIngredients.isNotEmpty;
    final ingredientsList = hasIngredients
        ? rawIngredients.split(RegExp(r',\s*|\.\s*|\n')).where((s) => s.trim().isNotEmpty).toList()
        : <String>[];

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
          'Ingredients',
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
              _buildProductHeader(context, colors, scale, ingredientsList.length),
              SizedBox(height: 16 * scale),

              // Full Ingredient Statement Card
              _buildIngredientStatementCard(colors, scale, rawIngredients),
              SizedBox(height: 20 * scale),

              // Ingredient Intelligence Findings (Sugar, Additives, Allergens, Whole Foods)
              if (intel.sugarRelatedIngredients.isNotEmpty ||
                  intel.artificialSweeteners.isNotEmpty ||
                  intel.additives.isNotEmpty ||
                  product.allergens.isNotEmpty ||
                  intel.wholeFoodIngredients.isNotEmpty) ...[
                Text(
                  'Ingredient Intelligence',
                  style: TextStyle(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: 10 * scale),
                _buildIntelligenceBreakdown(colors, scale, intel),
                SizedBox(height: 20 * scale),
              ],

              // Original Ordered Ingredients Chips
              if (ingredientsList.isNotEmpty) ...[
                Text(
                  'All Ingredients (${ingredientsList.length})',
                  style: TextStyle(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: 4 * scale),
                Text(
                  'Listed in order of predominance as specified on product packaging',
                  style: TextStyle(
                    fontSize: 12 * scale,
                    color: colors.textMuted,
                  ),
                ),
                SizedBox(height: 12 * scale),
                _buildIngredientChips(colors, scale, ingredientsList, intel),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductHeader(
    BuildContext context,
    DietCompassThemeColors colors,
    double scale,
    int count,
  ) {
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
                        Icons.restaurant_rounded,
                        color: colors.iconPurple,
                        size: 26 * scale,
                      ),
                    )
                  : Icon(
                      Icons.restaurant_rounded,
                      color: colors.iconPurple,
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
          if (count > 0) ...[
            SizedBox(width: 8 * scale),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 6 * scale),
              decoration: BoxDecoration(
                color: colors.iconPurpleBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count items',
                style: TextStyle(
                  fontSize: 11.5 * scale,
                  fontWeight: FontWeight.w700,
                  color: colors.iconPurple,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIngredientStatementCard(
    DietCompassThemeColors colors,
    double scale,
    String rawText,
  ) {
    final displayText = rawText.isNotEmpty
        ? rawText
        : 'No detailed ingredients statement listed for this product label.';

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
              Icon(Icons.receipt_long_rounded, size: 18 * scale, color: colors.iconPurple),
              SizedBox(width: 8 * scale),
              Text(
                'Full Statement',
                style: TextStyle(
                  fontSize: 14.5 * scale,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 10 * scale),
          Text(
            displayText,
            style: TextStyle(
              fontSize: 13.5 * scale,
              height: 1.55,
              color: rawText.isNotEmpty ? colors.textPrimary : colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntelligenceBreakdown(
    DietCompassThemeColors colors,
    double scale,
    IngredientIntelligenceResult intel,
  ) {
    return Column(
      children: [
        if (intel.sugarRelatedIngredients.isNotEmpty)
          _buildIntelCard(
            colors: colors,
            scale: scale,
            icon: Icons.water_drop_rounded,
            iconColor: colors.iconOrange,
            bgColor: colors.iconOrangeBg,
            title: 'Sugar-Related Ingredients',
            items: intel.sugarRelatedIngredients.map((e) => '${e.name}: ${e.explanation}').toList(),
          ),
        if (intel.artificialSweeteners.isNotEmpty)
          _buildIntelCard(
            colors: colors,
            scale: scale,
            icon: Icons.science_rounded,
            iconColor: colors.iconBlue,
            bgColor: colors.iconBlueBg,
            title: 'Low-Calorie Sweeteners / Substitutes',
            items: intel.artificialSweeteners.map((e) => '${e.name}: ${e.explanation}').toList(),
          ),
        if (intel.additives.isNotEmpty)
          _buildIntelCard(
            colors: colors,
            scale: scale,
            icon: Icons.inventory_2_rounded,
            iconColor: colors.iconPurple,
            bgColor: colors.iconPurpleBg,
            title: 'Additives & E-Numbers',
            items: intel.additives.map((e) => '${e.name}: ${e.explanation}').toList(),
          ),
        if (product.allergens.isNotEmpty)
          _buildIntelCard(
            colors: colors,
            scale: scale,
            icon: Icons.warning_amber_rounded,
            iconColor: colors.iconRed,
            bgColor: colors.iconRedBg,
            title: 'Declared Allergens',
            items: product.allergens,
          ),
        if (intel.wholeFoodIngredients.isNotEmpty)
          _buildIntelCard(
            colors: colors,
            scale: scale,
            icon: Icons.eco_rounded,
            iconColor: colors.iconGreen,
            bgColor: colors.iconGreenBg,
            title: 'Wholesome Whole Foods',
            items: intel.wholeFoodIngredients.map((e) => '${e.name}: ${e.explanation}').toList(),
          ),
      ],
    );
  }

  Widget _buildIntelCard({
    required DietCompassThemeColors colors,
    required double scale,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required List<String> items,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 10 * scale),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.cardBorder),
      ),
      padding: EdgeInsets.all(14 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6 * scale),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16 * scale, color: iconColor),
              ),
              SizedBox(width: 10 * scale),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5 * scale,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8 * scale),
          ...items.map(
            (item) => Padding(
              padding: EdgeInsets.only(top: 4 * scale, left: 4 * scale),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: iconColor, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 12.5 * scale,
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientChips(
    DietCompassThemeColors colors,
    double scale,
    List<String> items,
    IngredientIntelligenceResult intel,
  ) {
    final sugarNames = intel.sugarRelatedIngredients.map((e) => e.name.toLowerCase()).toSet();
    final sweetenerNames = intel.artificialSweeteners.map((e) => e.name.toLowerCase()).toSet();
    final additiveNames = intel.additives.map((e) => e.name.toLowerCase()).toSet();
    final allergenNames = product.allergens.map((e) => e.toLowerCase()).toSet();

    return Wrap(
      spacing: 8 * scale,
      runSpacing: 8 * scale,
      children: List.generate(items.length, (idx) {
        final raw = items[idx].trim();
        final lower = raw.toLowerCase();

        final isSugar = sugarNames.any((s) => lower.contains(s));
        final isSweetener = sweetenerNames.any((s) => lower.contains(s));
        final isAdditive = additiveNames.any((a) => lower.contains(a));
        final isAllergen = allergenNames.any((a) => lower.contains(a));

        Color chipBg = colors.surfaceSecondary;
        Color chipBorder = colors.cardBorder;
        Color textColor = colors.textPrimary;

        if (isAllergen) {
          chipBg = colors.iconRedBg;
          chipBorder = colors.iconRed.withValues(alpha: 0.3);
          textColor = colors.iconRed;
        } else if (isSugar) {
          chipBg = colors.iconOrangeBg;
          chipBorder = colors.iconOrange.withValues(alpha: 0.3);
          textColor = colors.iconOrange;
        } else if (isSweetener) {
          chipBg = colors.iconBlueBg;
          chipBorder = colors.iconBlue.withValues(alpha: 0.3);
          textColor = colors.iconBlue;
        } else if (isAdditive) {
          chipBg = colors.iconPurpleBg;
          chipBorder = colors.iconPurple.withValues(alpha: 0.3);
          textColor = colors.iconPurple;
        }

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 6 * scale),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: chipBorder),
          ),
          child: Text(
            '${idx + 1}. $raw',
            style: TextStyle(
              fontSize: 12.5 * scale,
              fontWeight: (isSugar || isSweetener || isAdditive || isAllergen)
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: textColor,
            ),
          ),
        );
      }),
    );
  }
}
