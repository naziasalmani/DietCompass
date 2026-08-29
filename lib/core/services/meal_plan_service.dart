import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../model/meal_plan_model.dart';
import 'auth_service.dart';
import 'pantry_storage_service.dart';
import 'storage_service.dart';

/// DietCompass — AI Meal Plan Service
///
/// Communicates with backend `/api/meal-plans/generate` to produce genuine,
/// personalized multi-day meal plans (1, 3, 7, or 30 days) adhering to user
/// goals, dietary safety, and pantry ingredients.
class MealPlanService extends ChangeNotifier {
  MealPlanService._();
  static final MealPlanService instance = MealPlanService._();

  final http.Client _httpClient = http.Client();
  MealPlanResponse? _currentPlan;

  MealPlanResponse? get currentPlan => _currentPlan;

  /// Generate personalized meal plan from backend
  Future<MealPlanResponse?> generateMealPlan({
    int durationDays = 7,
    String goal = 'Weight Loss',
    int calories = 1800,
    String mealType = 'Breakfast, Lunch, Dinner, Snacks',
    String diet = 'Vegetarian',
    String allergy = 'None',
    String budget = 'Moderate',
    bool usePantry = true,
  }) async {
    debugPrint('[MEAL PLAN BUILD CHECK] Dynamic meal planner version = 2');

    final userId = AuthService.instance.currentUser?.id ?? 'guest_user';

    List<String> pantryIngredients = [];
    if (usePantry) {
      try {
        final products = await PantryStorageService.instance.getProducts();
        pantryIngredients = products.map((p) => p.name).toList();
      } catch (e) {
        debugPrint('[MealPlanService] Error reading pantry: $e');
      }
    }

    final mealTypeList = mealType
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final allergyList = allergy != 'None' && allergy.isNotEmpty ? [allergy] : <String>[];

    debugPrint('\n==============================================');
    debugPrint('[MEAL PLAN REQUEST]');
    debugPrint('userId = $userId');
    debugPrint('durationDays = $durationDays');
    debugPrint('goal = $goal');
    debugPrint('calories = $calories');
    debugPrint('mealTypes = $mealTypeList');
    debugPrint('diet = $diet');
    debugPrint('allergies = $allergyList');
    debugPrint('usePantry = $usePantry');
    debugPrint('pantryIngredients = $pantryIngredients');
    debugPrint('==============================================\n');

    final fullUrl = '${AppConfig.apiBaseUrl}/meal-plans/generate';
    debugPrint('[MEAL PLAN HTTP]');
    debugPrint('url = $fullUrl');

    final payload = {
      'durationDays': durationDays,
      'goal': goal,
      'calories': calories,
      'mealTypes': mealTypeList,
      'diet': diet,
      'allergies': allergyList,
      'budget': budget,
      'usePantry': usePantry,
      'pantryIngredients': pantryIngredients,
    };

    final jsonPayload = jsonEncode(payload);

    debugPrint('[MEAL PLAN HTTP START]');
    debugPrint('[MEAL PLAN HTTP URL] $fullUrl');
    debugPrint('[MEAL PLAN HTTP BODY] $jsonPayload');

    try {
      final token = await StorageService.instance.getAccessToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      debugPrint('[PROFILE AUTH DEBUG]');
      debugPrint('tokenExists = ${token != null && token.isNotEmpty}');
      debugPrint('authorizationHeaderPresent = ${headers.containsKey('Authorization')}');
      debugPrint('endpoint = /meal-plans/generate');
      debugPrint('method = POST');

      final response = await _httpClient
          .post(
            Uri.parse(fullUrl),
            headers: headers,
            body: jsonPayload,
          )
          .timeout(const Duration(seconds: 60));

      debugPrint('[MEAL PLAN HTTP RESPONSE] status = ${response.statusCode}');
      debugPrint('[MEAL PLAN HTTP RESPONSE] body = ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final rawData = decoded['data'] ?? decoded;
          if (rawData is Map<String, dynamic>) {
            final plan = MealPlanResponse.fromJson(rawData);
            _currentPlan = plan;
            notifyListeners();

            debugPrint('\n==============================================');
            debugPrint('[MEAL PLAN RECEIVED]');
            debugPrint('durationDays = ${plan.durationDays}');
            debugPrint('daysCount = ${plan.days.length}');
            debugPrint('geminiPowered = ${plan.geminiPowered}');
            debugPrint('summary = ${plan.summary}');
            debugPrint('==============================================\n');

            return plan;
          }
        }
      } else {
        debugPrint('[MealPlanService] Server returned non-200 status: ${response.statusCode}');
      }
    } on SocketException catch (e, stack) {
      debugPrint('[MEAL PLAN HTTP ERROR]');
      debugPrint('type = SocketException');
      debugPrint('message = $e');
      debugPrint('stack = $stack');
    } on TimeoutException catch (e, stack) {
      debugPrint('[MEAL PLAN HTTP ERROR]');
      debugPrint('type = TimeoutException');
      debugPrint('message = Request timed out after 60s: $e');
      debugPrint('stack = $stack');
    } catch (e, stack) {
      debugPrint('[MEAL PLAN HTTP ERROR]');
      debugPrint('type = ${e.runtimeType}');
      debugPrint('message = $e');
      debugPrint('stack = $stack');
    }

    return _currentPlan;
  }

  /// Sets or updates the currently active plan in memory
  void setCurrentPlan(MealPlanResponse plan) {
    _currentPlan = plan;
    notifyListeners();
  }

  /// Clears active meal plan on logout
  void clear() {
    _currentPlan = null;
    notifyListeners();
  }
}
