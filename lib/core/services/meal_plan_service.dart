import 'package:flutter/foundation.dart';
import '../model/meal_plan_model.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'pantry_storage_service.dart';

/// DietCompass — AI Meal Plan Service
///
/// Communicates with backend `/api/meal-plans/generate` to produce genuine,
/// personalized multi-day meal plans (1, 3, 7, or 30 days) adhering to user
/// goals, dietary safety, and pantry ingredients.
class MealPlanService extends ChangeNotifier {
  MealPlanService._();
  static final MealPlanService instance = MealPlanService._();

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

    try {
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

      final response = await ApiService.instance.post(
        '/meal-plans/generate',
        body: payload,
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final rawData = response.data!['data'] ?? response.data!;
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
    } catch (e) {
      debugPrint('[MealPlanService] Generate error: $e');
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
