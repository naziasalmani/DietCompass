import '../model/ai_analysis_model.dart';
import '../model/food_product.dart';
import 'api_service.dart';

/// DietCompass — AI Nutrition Intelligence Service
/// Communicates with backend `/api/ai/analyze-product`, `/api/ai/analyze-ocr`, and `/api/ai/coach`.
class AiService {
  AiService._();
  static final AiService instance = AiService._();

  /// Analyzes a food product's ingredients, hidden sugars, additives, and claims with Gemini AI
  Future<ProductAiAnalysisResult> analyzeProduct(
    FoodProduct product, {
    List<String> claims = const [],
  }) async {
    final payload = {
      'name': product.name,
      'brand': product.brand,
      'barcode': product.barcode,
      'ingredients': product.ingredients,
      'claims': claims,
      'nutrition': {
        'calories': product.calories,
        'protein': product.protein,
        'carbohydrates': product.carbohydrates,
        'fat': product.fat,
        'fiber': product.fiber,
        'sugar': product.sugar,
        'sodium': product.sodium,
      },
    };

    final response = await ApiService.instance.post(
      '/ai/analyze-product',
      body: payload,
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>? ?? response.data!;
      return ProductAiAnalysisResult.fromJson(data);
    }

    throw ApiException(
      response.message ?? 'Failed to analyze product with DietCompass AI.',
      statusCode: response.statusCode,
      code: response.errorCode,
    );
  }

  /// Analyzes raw OCR text from an unknown product label
  Future<ProductAiAnalysisResult> analyzeOcr(String ocrText) async {
    final response = await ApiService.instance.post(
      '/ai/analyze-ocr',
      body: {'ocrText': ocrText},
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>? ?? response.data!;
      return ProductAiAnalysisResult.fromJson(data);
    }

    throw ApiException(
      response.message ?? 'Failed to analyze scanned label with DietCompass AI.',
      statusCode: response.statusCode,
      code: response.errorCode,
    );
  }

  /// Looks up or enriches product information, nutrition, and ingredients using Gemini AI
  /// when traditional food databases do not have information.
  Future<FoodProduct?> lookupProductWithGemini({
    String? barcode,
    String? name,
    String? ocrText,
    FoodProduct? partialProduct,
  }) async {
    try {
      final payload = {
        'barcode': barcode ?? partialProduct?.barcode ?? '',
        'name': name ?? partialProduct?.name ?? '',
        'ocrText': ocrText ?? '',
        'ingredients': partialProduct?.ingredients ?? '',
        'nutrition': {
          'calories': partialProduct?.calories,
          'protein': partialProduct?.protein,
          'carbohydrates': partialProduct?.carbohydrates,
          'fat': partialProduct?.fat,
          'fiber': partialProduct?.fiber,
          'sugar': partialProduct?.sugar,
          'sodium': partialProduct?.sodium,
        },
      };

      final response = await ApiService.instance.post(
        '/ai/lookup-product',
        body: payload,
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final data = response.data!['data'] as Map<String, dynamic>? ?? response.data!;
        final productJson = data['product'] as Map<String, dynamic>? ?? data;
        return FoodProduct.fromJson(productJson);
      }
    } catch (e) {
      print('[AiService] Gemini product lookup error: $e');
    }
    return null;
  }

  /// Communicates with the AI Nutrition Coach
  Future<String> chatWithCoach(
    String message, {
    List<AiCoachChatMessage> history = const [],
    FoodProduct? product,
  }) async {
    final historyPayload = history.map((m) => {
      'role': m.isUser ? 'user' : 'model',
      'content': m.text,
    }).toList();

    final body = <String, dynamic>{
      'message': message,
      'history': historyPayload,
    };

    if (product != null) {
      body['product'] = {
        'name': product.name,
        'brand': product.brand,
        'barcode': product.barcode,
        'ingredients': product.ingredients,
        'calories': product.calories,
        'protein': product.protein,
        'carbohydrates': product.carbohydrates,
        'fat': product.fat,
        'fiber': product.fiber,
        'sugar': product.sugar,
        'sodium': product.sodium,
      };
    }

    final response = await ApiService.instance.post(
      '/ai/coach',
      body: body,
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>? ?? response.data!;
      return data['message']?.toString() ?? 'I am here to help you with your nutrition goals.';
    }

    throw ApiException(
      response.message ?? 'AI Nutrition Coach is temporarily unavailable.',
      statusCode: response.statusCode,
      code: response.errorCode,
    );
  }

  /// Calculates personalized product compatibility score
  Future<ProductCompatibility> getCompatibility(
    FoodProduct product, {
    List<String> claims = const [],
  }) async {
    final payload = {
      'name': product.name,
      'brand': product.brand,
      'barcode': product.barcode,
      'ingredients': product.ingredients,
      'claims': claims,
      'nutrition': {
        'calories': product.calories,
        'protein': product.protein,
        'carbohydrates': product.carbohydrates,
        'fat': product.fat,
        'fiber': product.fiber,
        'sugar': product.sugar,
        'sodium': product.sodium,
      },
    };

    final response = await ApiService.instance.post(
      '/ai/compatibility',
      body: payload,
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>? ?? response.data!;
      return ProductCompatibility.fromJson(data);
    }

    throw ApiException(
      response.message ?? 'Failed to calculate product compatibility score.',
      statusCode: response.statusCode,
      code: response.errorCode,
    );
  }

  /// Fetches personalized similar product recommendations
  Future<List<PersonalizedRecommendation>> getRecommendations(

    FoodProduct product, {
    List<FoodProduct> candidates = const [],
    int maxResults = 3,
  }) async {
    final payload = {
      'name': product.name,
      'brand': product.brand,
      'barcode': product.barcode,
      'ingredients': product.ingredients,
      'nutrition': {
        'calories': product.calories,
        'protein': product.protein,
        'carbohydrates': product.carbohydrates,
        'fat': product.fat,
        'fiber': product.fiber,
        'sugar': product.sugar,
        'sodium': product.sodium,
      },
      'candidates': candidates.map((c) => {
        'barcode': c.barcode,
        'name': c.name,
        'brand': c.brand,
        'imageUrl': c.imageUrl,
        'ingredients': c.ingredients,
        'nutrition': {
          'calories': c.calories,
          'protein': c.protein,
          'carbohydrates': c.carbohydrates,
          'fat': c.fat,
          'fiber': c.fiber,
          'sugar': c.sugar,
          'sodium': c.sodium,
        },
      }).toList(),
      'maxResults': maxResults,
    };

    final response = await ApiService.instance.post(
      '/ai/recommendations',
      body: payload,
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>? ?? response.data!;
      final recsRaw = data['recommendations'] as List?;
      if (recsRaw != null) {
        return recsRaw
            .whereType<Map<String, dynamic>>()
            .map((e) => PersonalizedRecommendation.fromJson(e))
            .toList();
      }
      return [];
    }

    throw ApiException(
      response.message ?? 'Failed to load similar product recommendations.',
      statusCode: response.statusCode,
      code: response.errorCode,
    );
  }
}


