import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../model/ai_analysis_model.dart';
import '../model/food_product.dart';
import '../model/personalization_profile.dart';
import '../model/user_profile.dart';
import 'ingredient_intelligence_service.dart';
import 'personalization_service.dart';
import 'profile_service.dart';
import 'recommendation_service.dart';

/// Item representing a pros/cons finding in product analysis UI
class ProsConsFinding {
  const ProsConsFinding({
    required this.title,
    required this.subtitle,
    this.category = 'general',
  });

  final String title;
  final String subtitle;
  final String category;

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'category': category,
      };

  factory ProsConsFinding.fromJson(Map<String, dynamic> json) {
    return ProsConsFinding(
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      category: json['category']?.toString() ?? 'general',
    );
  }
}

/// Single Source of Truth Canonical Product Analysis Result
class CanonicalProductAnalysis {
  CanonicalProductAnalysis({
    required this.analysisKey,
    required this.userId,
    required this.barcode,
    required this.product,
    required this.profileVersion,
    required this.engineVersion,
    required this.overallScore,
    required this.compatibility,
    required this.whatsGood,
    required this.watchOutFor,
    required this.ingredientIntelligence,
    this.alternatives = const [],
    this.aiExplanation,
    required this.analyzedAt,
  });

  final String analysisKey;
  final String userId;
  final String barcode;
  final FoodProduct product;
  final String profileVersion;
  final String engineVersion;
  final int overallScore;
  final ProductCompatibility compatibility;
  final List<ProsConsFinding> whatsGood;
  final List<ProsConsFinding> watchOutFor;
  final IngredientIntelligenceResult ingredientIntelligence;
  final List<PersonalizedRecommendation> alternatives;
  final String? aiExplanation;
  final DateTime analyzedAt;

  int? get compatibilityScore => compatibility.score;

  Map<String, dynamic> toJson() => {
        'analysisKey': analysisKey,
        'userId': userId,
        'barcode': barcode,
        'product': product.toJson(),
        'profileVersion': profileVersion,
        'engineVersion': engineVersion,
        'overallScore': overallScore,
        'compatibility': compatibility.toJson(),
        'whatsGood': whatsGood.map((w) => w.toJson()).toList(),
        'watchOutFor': watchOutFor.map((w) => w.toJson()).toList(),
        'ingredientIntelligence': ingredientIntelligence.toJson(),
        'alternatives': alternatives.map((a) => a.toJson()).toList(),
        'aiExplanation': aiExplanation,
        'analyzedAt': analyzedAt.toIso8601String(),
      };

  factory CanonicalProductAnalysis.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(dynamic list, T Function(Map<String, dynamic>) mapper) {
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map((item) => mapper(item))
            .toList();
      }
      return [];
    }

    DateTime parsedDate;
    try {
      parsedDate = json['analyzedAt'] != null
          ? DateTime.parse(json['analyzedAt'].toString())
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    final prodMap = json['product'] as Map<String, dynamic>? ?? {};
    final compatMap = json['compatibility'] as Map<String, dynamic>? ?? {};
    final intelMap = json['ingredientIntelligence'] as Map<String, dynamic>? ?? {};

    return CanonicalProductAnalysis(
      analysisKey: (json['analysisKey'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      barcode: (json['barcode'] ?? '').toString(),
      product: FoodProduct.fromJson(prodMap),
      profileVersion: (json['profileVersion'] ?? '1').toString(),
      engineVersion: (json['engineVersion'] ?? 'v1.0').toString(),
      overallScore: (json['overallScore'] as num?)?.toInt() ?? 50,
      compatibility: ProductCompatibility.fromJson(compatMap),
      whatsGood: parseList(json['whatsGood'], ProsConsFinding.fromJson),
      watchOutFor: parseList(json['watchOutFor'], ProsConsFinding.fromJson),
      ingredientIntelligence: IngredientIntelligenceResult.fromJson(intelMap),
      alternatives: parseList(json['alternatives'], PersonalizedRecommendation.fromJson),
      aiExplanation: json['aiExplanation']?.toString(),
      analyzedAt: parsedDate,
    );
  }
}

/// DietCompass — Deterministic Product Analysis Engine
class ProductAnalysisEngine {
  ProductAnalysisEngine._();
  static final ProductAnalysisEngine instance = ProductAnalysisEngine._();

  static const String engineVersion = 'v1.0';
  final Map<String, CanonicalProductAnalysis> _analysisCache = {};

  /// Generates a stable, deterministic analysis key for a given user & product
  String buildAnalysisKey({
    required String userId,
    required FoodProduct product,
    required String profileVersion,
  }) {
    final identity = product.barcode.trim().isNotEmpty
        ? product.barcode.trim()
        : '${product.name.trim().toLowerCase()}_${product.brand.trim().toLowerCase()}';
    return '${userId}_${identity}_${profileVersion}_$engineVersion';
  }

  /// Evaluates and builds the 100% deterministic CanonicalProductAnalysis
  CanonicalProductAnalysis analyzeProduct(
    FoodProduct product, {
    PersonalizationProfile? personalization,
    UserProfile? profile,
    String? goalFilter,
    bool forceReanalyze = false,
  }) {
    final activePersonalization = personalization ?? PersonalizationService.instance.currentPersonalization;
    final activeProfile = profile ?? ProfileService.instance.currentProfile;

    final userId = activeProfile?.id ?? 'authenticated_user';
    final profileVer = '${ProfileService.instance.profileVersion}_${PersonalizationService.instance.profileVersion}';
    final key = buildAnalysisKey(userId: userId, product: product, profileVersion: profileVer);

    if (!forceReanalyze && _analysisCache.containsKey(key)) {
      debugPrint('[ANALYSIS ENGINE] Cache hit for key: $key');
      return _analysisCache[key]!;
    }

    // 1. Authoritative Deterministic Scores
    final overallScore = RecommendationService.instance.calculateNutritionScore(product);
    final compatibility = RecommendationService.instance.evaluateCompatibility(
      product,
      personalization: activePersonalization,
      profile: activeProfile,
      goalFilter: goalFilter,
    );

    // 2. Deterministic Ingredient Intelligence
    final intel = IngredientIntelligenceService.instance.analyze(product);

    // 3. Build Deterministic "What's Good" Findings
    final whatsGood = _buildWhatsGood(product, compatibility, intel);

    // 4. Build Deterministic "Watch Out For" Findings (Allergens, Disguised Sugars, Additives/E-numbers, Health & Goal Risks, Claims)
    final watchOutFor = _buildWatchOutFor(product, compatibility, intel);

    final analysis = CanonicalProductAnalysis(
      analysisKey: key,
      userId: userId,
      barcode: product.barcode.trim(),
      product: product,
      profileVersion: profileVer,
      engineVersion: engineVersion,
      overallScore: overallScore,
      compatibility: compatibility,
      whatsGood: whatsGood,
      watchOutFor: watchOutFor,
      ingredientIntelligence: intel,
      alternatives: const [],
      analyzedAt: DateTime.now(),
    );

    _analysisCache[key] = analysis;

    debugPrint('\n==============================================');
    debugPrint('[ANALYSIS ENGINE EXECUTED]');
    debugPrint('key = $key');
    debugPrint('productName = ${product.name}');
    debugPrint('overallScore = $overallScore');
    debugPrint('compatibilityScore = ${compatibility.score}');
    debugPrint('whatsGoodCount = ${whatsGood.length}');
    debugPrint('watchOutForCount = ${watchOutFor.length}');
    debugPrint('==============================================\n');

    return analysis;
  }

  /// Caches an analysis explicitly (e.g. loaded from scan history)
  void cacheAnalysis(CanonicalProductAnalysis analysis) {
    if (analysis.analysisKey.isNotEmpty) {
      _analysisCache[analysis.analysisKey] = analysis;
    }
  }

  /// Gets cached analysis if available
  CanonicalProductAnalysis? getCachedAnalysis(String key) {
    return _analysisCache[key];
  }

  /// Clears in-memory analysis cache
  void clearCache() {
    _analysisCache.clear();
  }

  List<ProsConsFinding> _buildWhatsGood(
    FoodProduct product,
    ProductCompatibility compatibility,
    IngredientIntelligenceResult intel,
  ) {
    final list = <ProsConsFinding>[];
    final seenTitles = <String>{};

    void addFinding(String title, String subtitle, {String category = 'nutrition'}) {
      if (title.trim().isEmpty) return;
      if (seenTitles.add(title.toLowerCase().trim())) {
        list.add(ProsConsFinding(title: title, subtitle: subtitle, category: category));
      }
    }

    // A. Positive Factors from Compatibility Engine
    for (final factor in compatibility.positiveFactors) {
      if (factor != 'Nutrition analyzed') {
        addFinding(factor, 'Verified Dietary Compatibility', category: 'compatibility');
      }
    }

    // B. Whole Foods from Ingredient Intelligence
    for (final item in intel.wholeFoodIngredients) {
      addFinding(
        'Wholesome Ingredient: ${item.name}',
        item.explanation,
        category: 'ingredient',
      );
    }

    // C. Objective Nutrition Threshold Benefits
    if (product.protein != null && product.protein! >= 5.0) {
      addFinding(
        'Good Protein Source (${product.protein!.toStringAsFixed(1)}g per 100g)',
        'Supports muscle maintenance and satiety',
        category: 'nutrition',
      );
    }
    if (product.fiber != null && product.fiber! >= 3.0) {
      addFinding(
        'Beneficial Fiber Content (${product.fiber!.toStringAsFixed(1)}g per 100g)',
        'Supports digestive health and steady energy',
        category: 'nutrition',
      );
    }
    if (product.sugar != null && product.sugar! <= 3.0) {
      addFinding(
        'Low Sugar Formulation (${product.sugar!.toStringAsFixed(1)}g per 100g)',
        'Helps avoid blood sugar spikes',
        category: 'nutrition',
      );
    }
    if (product.sodium != null) {
      final rawSodium = product.sodium!;
      final sodiumMg = rawSodium <= 10.0 ? rawSodium * 1000.0 : rawSodium;
      if (sodiumMg <= 140) {
        addFinding(
          'Low Sodium (${sodiumMg.toStringAsFixed(0)}mg per 100g)',
          'Aligns with heart-healthy sodium guidelines',
          category: 'nutrition',
        );
      }
    }

    if (list.isEmpty) {
      addFinding(
        'Standard Nutritional Composition',
        'No major positive or negative outliers detected',
        category: 'general',
      );
    }

    return list;
  }

  List<ProsConsFinding> _buildWatchOutFor(
    FoodProduct product,
    ProductCompatibility compatibility,
    IngredientIntelligenceResult intel,
  ) {
    final list = <ProsConsFinding>[];
    final seenTitles = <String>{};

    void addFinding(String title, String subtitle, {String category = 'alert'}) {
      if (title.trim().isEmpty) return;
      if (seenTitles.add(title.toLowerCase().trim())) {
        list.add(ProsConsFinding(title: title, subtitle: subtitle, category: category));
      }
    }

    // 1. ALLERGEN ALERTS (Highest Priority)
    for (final alert in compatibility.allergyAlerts) {
      final detail = alert.replaceAll('Contains your configured allergen: ', '').trim();
      addFinding(detail.isNotEmpty ? '⚠️ Allergen Alert: $detail' : '⚠️ Allergen Alert', alert, category: 'allergen');
    }

    // 2. DIETARY CONFLICTS
    for (final alert in compatibility.dietaryAlerts) {
      addFinding('⚠️ Dietary Conflict: $alert', alert, category: 'dietary');
    }

    // 3. DISGUISED SUGARS (Ingredient Intelligence)
    for (final sugar in intel.sugarRelatedIngredients) {
      addFinding('Hidden Sugar: ${sugar.name}', sugar.explanation, category: 'sugar');
    }

    // 4. HARMFUL ADDITIVES & E-NUMBERS (Ingredient Intelligence)
    for (final additive in intel.additives) {
      addFinding('Additive Concern: ${additive.name}', additive.explanation, category: 'additive');
    }

    // 5. ARTIFICIAL SWEETENERS
    for (final sweetener in intel.artificialSweeteners) {
      addFinding('Sugar Substitute: ${sweetener.name}', sweetener.explanation, category: 'sweetener');
    }

    // 6. HEALTH CONDITION & PROFILE CONCERNS
    for (final concern in compatibility.concerns) {
      addFinding('Profile Concern', concern, category: 'profile_concern');
    }

    // 7. CLAIM VERIFICATIONS
    for (final claimCheck in intel.claimChecks) {
      if (claimCheck.status != 'Verified') {
        addFinding(
          'Claim Check (${claimCheck.claim}): ${claimCheck.status}',
          claimCheck.explanation,
          category: 'claim',
        );
      }
    }

    // 8. NUTRITION THRESHOLD WARNINGS (If no specific ingredient concerns yet exist)
    if (product.sugar != null && product.sugar! > 12.0) {
      addFinding(
        'High Sugar Content (${product.sugar!.toStringAsFixed(1)}g per 100g)',
        'May contribute to excess daily sugar intake',
        category: 'nutrition_warning',
      );
    }
    if (product.sodium != null) {
      final rawSodium = product.sodium!;
      final sodiumMg = rawSodium <= 10.0 ? rawSodium * 1000.0 : rawSodium;
      if (sodiumMg > 600) {
        addFinding(
          'High Sodium Content (${sodiumMg.toStringAsFixed(0)}mg per 100g)',
          'Exceeds recommended per-serving sodium guidelines',
          category: 'nutrition_warning',
        );
      }
    }
    if (product.saturatedFat != null && product.saturatedFat! > 5.0) {
      addFinding(
        'High Saturated Fat (${product.saturatedFat!.toStringAsFixed(1)}g per 100g)',
        'Consider enjoying in moderation',
        category: 'nutrition_warning',
      );
    }

    return list;
  }
}
