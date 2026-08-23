import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/model/food_product.dart';
import '../result_screen.dart';

/// DietCompass — Product Share Service
/// ---------------------------------------------------------------------------
/// Coordinates rendering of the high-resolution share card image and formatted
/// analysis summary, then presents the native Android/iOS share sheet.
class ProductShareService {
  ProductShareService._();
  static final ProductShareService instance = ProductShareService._();

  /// Generates a comprehensive, formatted text summary for sharing
  String generateShareText({
    required FoodProduct product,
    required int overallScore,
    required int compatibilityScore,
    required List<NutrientStat> nutrients,
    required List<CompatibilityItem> compatibility,
    required List<ProsConsItem> goodPoints,
    required List<ProsConsItem> watchPoints,
    String? aiRecommendation,
  }) {
    final buffer = StringBuffer();

    // 1. Header & Branding
    buffer.writeln('🧭 DietCompass • AI Food Analysis');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // 2. Product Info
    final brandPart = product.brand.trim().isNotEmpty ? ' (${product.brand.trim()})' : '';
    buffer.writeln('📦 Product: ${product.name.trim()}$brandPart');
    if (product.barcode.trim().isNotEmpty) {
      buffer.writeln('🏷️ Barcode: ${product.barcode.trim()}');
    }
    buffer.writeln();

    // 3. Scores
    String scoreStatus;
    if (overallScore >= 80) {
      scoreStatus = 'Excellent Choice';
    } else if (overallScore >= 65) {
      scoreStatus = 'Good Choice';
    } else if (overallScore >= 50) {
      scoreStatus = 'Moderate Choice';
    } else {
      scoreStatus = 'Consider Alternatives';
    }

    buffer.writeln('⭐ Overall Nutrition: $overallScore/100 ($scoreStatus)');
    buffer.writeln('🎯 Personal Compatibility: $compatibilityScore% Match');
    buffer.writeln();

    // 4. Nutrition Snapshot (only valid nutrients)
    final validNutrients = nutrients.where((n) => n.isAvailable && n.value != 'Unavailable').toList();
    if (validNutrients.isNotEmpty) {
      buffer.writeln('🥗 Nutrition Snapshot:');
      for (final n in validNutrients) {
        final unit = n.unit.isNotEmpty ? ' ${n.unit}' : '';
        buffer.writeln('  • ${n.label}: ${n.value}$unit');
      }
      buffer.writeln();
    }

    // 5. Compatibility Factors
    if (compatibility.isNotEmpty) {
      buffer.writeln('❤️ Personal Health Compatibility:');
      for (final c in compatibility.take(4)) {
        buffer.writeln('  • ${c.label}: ${c.rating}');
      }
      buffer.writeln();
    }

    // 6. What's Good
    final validGood = goodPoints.where((g) => g.title.isNotEmpty).take(3).toList();
    if (validGood.isNotEmpty) {
      buffer.writeln("✨ What's Good:");
      for (final g in validGood) {
        buffer.writeln('  • ${g.title}');
      }
      buffer.writeln();
    }

    // 7. Watch Out For
    final validWatch = watchPoints.where((w) => w.title.isNotEmpty).take(3).toList();
    if (validWatch.isNotEmpty) {
      buffer.writeln('⚠️ Watch Out For:');
      for (final w in validWatch) {
        buffer.writeln('  • ${w.title}');
      }
      buffer.writeln();
    }

    // 8. AI Recommendation
    if (aiRecommendation != null && aiRecommendation.trim().isNotEmpty) {
      buffer.writeln('💡 AI Recommendation:');
      buffer.writeln('  ${aiRecommendation.trim()}');
      buffer.writeln();
    }

    // 9. Footer
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📲 Scanned with DietCompass — AI-Powered Nutrition Assistant');

    return buffer.toString();
  }

  /// Captures the [RepaintBoundary] from [boundaryKey] and triggers native share
  Future<void> shareProductAnalysis({
    required BuildContext context,
    required FoodProduct product,
    required int overallScore,
    required int compatibilityScore,
    required List<NutrientStat> nutrients,
    required List<CompatibilityItem> compatibility,
    required List<ProsConsItem> goodPoints,
    required List<ProsConsItem> watchPoints,
    String? aiRecommendation,
    GlobalKey? boundaryKey,
  }) async {
    final textSummary = generateShareText(
      product: product,
      overallScore: overallScore,
      compatibilityScore: compatibilityScore,
      nutrients: nutrients,
      compatibility: compatibility,
      goodPoints: goodPoints,
      watchPoints: watchPoints,
      aiRecommendation: aiRecommendation,
    );

    File? imageFile;

    // Attempt to capture high-res share card image
    if (boundaryKey != null && boundaryKey.currentContext != null) {
      try {
        final renderObject = boundaryKey.currentContext?.findRenderObject();
        if (renderObject is RenderRepaintBoundary) {
          final ui.Image image = await renderObject.toImage(pixelRatio: 3.0);
          final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            final Uint8List pngBytes = byteData.buffer.asUint8List();
            final tempDir = await getTemporaryDirectory();
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final sanitizedName = product.name
                .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
                .toLowerCase();
            final filePath = '${tempDir.path}/dietcompass_${sanitizedName}_$timestamp.png';
            final file = File(filePath);
            await file.writeAsBytes(pngBytes, flush: true);
            imageFile = file;
          }
        }
      } catch (e) {
        debugPrint('Image capture for share encountered an error, falling back to text: $e');
      }
    }

    // Trigger native share sheet with image + formatted text (or text fallback)
    try {
      if (imageFile != null && await imageFile.exists()) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(imageFile.path, mimeType: 'image/png', name: 'dietcompass_analysis.png')],
            text: textSummary,
            subject: 'DietCompass AI Food Analysis: ${product.name}',
          ),
        );
      } else {
        await SharePlus.instance.share(
          ShareParams(
            text: textSummary,
            subject: 'DietCompass AI Food Analysis: ${product.name}',
          ),
        );
      }
    } catch (e) {
      debugPrint('SharePlus share error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open share sheet. Please try again.')),
        );
      }
    }
  }
}
