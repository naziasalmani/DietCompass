import 'package:flutter/material.dart';
import '../../../core/model/food_product.dart';
import '../result_screen.dart';

/// DietCompass — Dynamic Product Analysis Share Card
/// ---------------------------------------------------------------------------
/// Generates a high-resolution, branded visual card containing the complete
/// AI food analysis summary for sharing across social platforms.
class ProductShareCard extends StatelessWidget {
  const ProductShareCard({
    super.key,
    required this.product,
    required this.overallScore,
    required this.compatibilityScore,
    required this.nutrients,
    required this.compatibility,
    required this.goodPoints,
    required this.watchPoints,
    this.aiRecommendation,
    this.productImage,
    this.cardWidth = 420.0,
  });

  final FoodProduct product;
  final int overallScore;
  final int compatibilityScore;
  final List<NutrientStat> nutrients;
  final List<CompatibilityItem> compatibility;
  final List<ProsConsItem> goodPoints;
  final List<ProsConsItem> watchPoints;
  final String? aiRecommendation;
  final ImageProvider? productImage;
  final double cardWidth;

  String _getScoreLabel(int score) {
    if (score >= 80) return 'Excellent Choice';
    if (score >= 65) return 'Good Choice';
    if (score >= 50) return 'Moderate Choice';
    return 'Consider Alternatives';
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF1E8A4C);
    if (score >= 65) return const Color(0xFF6C4EF5);
    if (score >= 50) return const Color(0xFFE0862E);
    return const Color(0xFFE0525C);
  }

  String _getCompatibilityLabel(int percent) {
    if (percent >= 80) return 'High Compatibility';
    if (percent >= 60) return 'Good Compatibility';
    if (percent >= 40) return 'Moderate Match';
    return 'Low Compatibility';
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _getScoreColor(overallScore);
    final scoreLabel = _getScoreLabel(overallScore);
    final compatLabel = _getCompatibilityLabel(compatibilityScore);

    // Filter only nutrients that actually have valid data (never display missing as 0)
    final validNutrients = nutrients.where((n) => n.isAvailable && n.value != 'Unavailable').toList();

    return Container(
      width: cardWidth,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3FC),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C4EF5).withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Top Branding Header ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6C4EF5), Color(0xFF432CA5)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.explore_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DietCompass',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        'AI Food Intelligence & Health Analysis',
                        style: TextStyle(
                          color: Color(0xFFD6CEF8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E8A4C),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'AI Verified',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 2. Product Information Card ───────────────────────────────
                _buildProductHeader(context),

                const SizedBox(height: 14),

                // ── 3. Dual Scores Section (Nutrition & Compatibility) ────────
                _buildScoresRow(scoreColor, scoreLabel, compatLabel),

                const SizedBox(height: 14),

                // ── 4. Nutrition Snapshot ─────────────────────────────────────
                if (validNutrients.isNotEmpty) ...[
                  _buildNutritionSection(validNutrients),
                  const SizedBox(height: 14),
                ],

                // ── 5. Personalized Compatibility Breakdown ───────────────────
                if (compatibility.isNotEmpty) ...[
                  _buildCompatibilitySection(),
                  const SizedBox(height: 14),
                ],

                // ── 6. What's Good & Watch Out For ────────────────────────────
                _buildProsAndConsSection(),

                // ── 7. AI Recommendation ──────────────────────────────────────
                if (aiRecommendation != null && aiRecommendation!.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildAiRecommendationSection(),
                ],
              ],
            ),
          ),

          // ── 8. Bottom Footer ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              border: const Border(
                top: BorderSide(color: Color(0xFFE8E4F2)),
              ),
            ),
            child: const Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, size: 14, color: Color(0xFF6C4EF5)),
                    SizedBox(width: 6),
                    Text(
                      'Scanned with DietCompass',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5B5B6B),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 12, color: Color(0xFF1E8A4C)),
                    SizedBox(width: 4),
                    Text(
                      'Personalized for you',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E8A4C),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Product Header ──────────────────────────────────────────────────────────
  Widget _buildProductHeader(BuildContext context) {
    final ImageProvider? resolvedImage = productImage ??
        (product.imageUrl.trim().isNotEmpty ? NetworkImage(product.imageUrl.trim()) : null);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEBE6F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 64,
              height: 64,
              color: const Color(0xFFF7F5FC),
              padding: const EdgeInsets.all(4),
              child: resolvedImage != null
                  ? Image(
                      image: resolvedImage,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.fastfood_rounded,
                        color: Color(0xFF9A96A8),
                        size: 28,
                      ),
                    )
                  : const Icon(
                      Icons.fastfood_rounded,
                      color: Color(0xFF9A96A8),
                      size: 28,
                    ),
            ),
          ),
          const SizedBox(width: 14),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name.trim().isNotEmpty ? product.name : 'Scanned Food Product',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B1B2E),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                if (product.brand.trim().isNotEmpty) ...[
                  Text(
                    product.brand.trim(),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6C4EF5),
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                if (product.barcode.trim().isNotEmpty)
                  Text(
                    'Barcode: ${product.barcode.trim()}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF8A889A),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Scores Row ──────────────────────────────────────────────────────────────
  Widget _buildScoresRow(Color scoreColor, String scoreLabel, String compatLabel) {
    return Row(
      children: [
        // Overall Nutrition Score
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: scoreColor.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: scoreColor.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$overallScore',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: scoreColor,
                      ),
                    ),
                    const Text(
                      '/100',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8A889A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Overall Nutrition',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B6B7B),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    scoreLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: scoreColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Personal Compatibility
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF6C4EF5).withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C4EF5).withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$compatibilityScore',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF6C4EF5),
                      ),
                    ),
                    const Text(
                      '%',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6C4EF5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Personal Match',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B6B7B),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C4EF5).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    compatLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6C4EF5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Nutrition Snapshot ──────────────────────────────────────────────────────
  Widget _buildNutritionSection(List<NutrientStat> validNutrients) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEBE6F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, size: 15, color: Color(0xFF6C4EF5)),
              SizedBox(width: 6),
              Text(
                'Nutrition Snapshot',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B1B2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: validNutrients.map((n) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F5FC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8E3F2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(n.icon, size: 13, color: n.color),
                    const SizedBox(width: 5),
                    Text(
                      '${n.label}: ',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B6B7B),
                      ),
                    ),
                    Text(
                      '${n.value}${n.unit.isNotEmpty ? " ${n.unit}" : ""}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B1B2E),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Compatibility Section ───────────────────────────────────────────────────
  Widget _buildCompatibilitySection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEBE6F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.favorite_rounded, size: 15, color: Color(0xFF1E8A4C)),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Personal Health Compatibility',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B1B2E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...compatibility.take(4).map((item) {
            final isGood = item.rating.toLowerCase().contains('good') ||
                item.rating.toLowerCase().contains('excellent') ||
                item.rating.toLowerCase().contains('safe');
            final badgeColor = isGood ? const Color(0xFF1E8A4C) : const Color(0xFFE0862E);

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(item.icon, size: 14, color: badgeColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1B1B2E),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.rating,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Pros & Cons Section ─────────────────────────────────────────────────────
  Widget _buildProsAndConsSection() {
    final validGood = goodPoints.take(2).toList();
    final validWatch = watchPoints.take(2).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // What's Good
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDCFCE7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF16A34A)),
                    SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        "What's Good",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (validGood.isNotEmpty)
                  ...validGood.map((g) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w800)),
                            Expanded(
                              child: Text(
                                g.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF166534),
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                else
                  const Text(
                    'No major positive flags recorded',
                    style: TextStyle(fontSize: 10.5, color: Color(0xFF15803D)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Watch Out For
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFEF3C7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFD97706)),
                    SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Watch Out For',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (validWatch.isNotEmpty)
                  ...validWatch.map((w) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.w800)),
                            Expanded(
                              child: Text(
                                w.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF92400E),
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                else
                  const Text(
                    'No critical flags detected',
                    style: TextStyle(fontSize: 10.5, color: Color(0xFFB45309)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── AI Recommendation ───────────────────────────────────────────────────────
  Widget _buildAiRecommendationSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6C4EF5).withValues(alpha: 0.08),
            const Color(0xFF1E8A4C).withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF6C4EF5).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, size: 14, color: Color(0xFF6C4EF5)),
              SizedBox(width: 6),
              Text(
                'AI Recommendation',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6C4EF5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            aiRecommendation!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2D2B3D),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
