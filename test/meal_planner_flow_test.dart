import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/core/model/meal_plan_model.dart';
import 'package:diet_compass/features/recipe_generator/ai_meal_planner_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AI Meal Planner Model & Deserialization Tests', () {
    test('Correctly deserializes 7-day meal plan JSON response', () {
      final sampleJson = {
        'durationDays': 7,
        'goal': 'Weight Loss',
        'diet': 'Vegetarian',
        'targetCalories': 1800,
        'summary': 'Your 7-day plan is tailored for Weight Loss with a vegetarian diet.',
        'geminiPowered': true,
        'days': List.generate(7, (i) => {
          'day': i + 1,
          'dayLabel': 'Day ${i + 1}',
          'dayNumber': 'Day ${i + 1}',
          'date': '2026-08-${28 + i}',
          'dailyCalories': 1800,
          'dailyProtein': 75,
          'dailyFiber': 30,
          'waterGlasses': 8,
          'meals': [
            {
              'type': 'Breakfast',
              'recipeId': 'r_b_${i + 1}',
              'title': 'Banana Oats Power Bowl',
              'calories': 350,
              'proteinGrams': 12,
              'carbsGrams': 45,
              'fatGrams': 8,
              'fiberGrams': 6,
              'image': 'https://images.unsplash.com/photo-1584776296944-ab6fb57b0bdd',
              'ingredients': ['Oats', 'Banana', 'Milk'],
              'isVegetarian': true,
            },
            {
              'type': 'Lunch',
              'recipeId': 'r_l_${i + 1}',
              'title': 'Quinoa Veggie Bowl',
              'calories': 550,
              'proteinGrams': 22,
              'carbsGrams': 60,
              'fatGrams': 14,
              'fiberGrams': 10,
              'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
              'ingredients': ['Quinoa', 'Broccoli', 'Chickpeas'],
              'isVegetarian': true,
            },
            {
              'type': 'Dinner',
              'recipeId': 'r_d_${i + 1}',
              'title': 'Pasta Primavera',
              'calories': 500,
              'proteinGrams': 20,
              'carbsGrams': 65,
              'fatGrams': 12,
              'fiberGrams': 8,
              'image': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624',
              'ingredients': ['Pasta', 'Bell Peppers', 'Tomatoes'],
              'isVegetarian': true,
            },
          ],
        }),
        'totals': {
          'averageCalories': 1800,
          'averageProtein': 75,
          'averageFiber': 30,
        },
      };

      final plan = MealPlanResponse.fromJson(sampleJson);

      expect(plan.durationDays, 7);
      expect(plan.goal, 'Weight Loss');
      expect(plan.diet, 'Vegetarian');
      expect(plan.geminiPowered, true);
      expect(plan.days.length, 7);
      expect(plan.days.first.meals.length, 3);
      expect(plan.days.first.meals.first.title, 'Banana Oats Power Bowl');
      expect(plan.totals.averageCalories, 1800);
    });

    test('MealPlanMeal.toRecipe converts to Recipe for RecipeDetailScreen', () {
      const meal = MealPlanMeal(
        type: 'Breakfast',
        recipeId: 'hardcoded_banana_oats',
        title: 'Banana Oats Power Bowl',
        description: 'Nutritious breakfast bowl',
        calories: 350,
        proteinGrams: 14,
        carbsGrams: 48,
        fatGrams: 7,
        fiberGrams: 6,
        image: 'https://images.unsplash.com/photo-1584776296944-ab6fb57b0bdd',
        ingredients: ['Rolled Oats', 'Banana', 'Milk'],
        instructions: ['Boil milk', 'Add oats', 'Top with sliced banana'],
        isVegetarian: true,
      );

      final recipe = meal.toRecipe();

      expect(recipe.title, 'Banana Oats Power Bowl');
      expect(recipe.calories, '350 kcal');
      expect(recipe.protein, '14g');
      expect(recipe.ingredients.length, 3);
      expect(recipe.instructions.length, 3);
      expect(recipe.tags.contains('Vegetarian'), true);
      expect(recipe.nutritionFacts.isNotEmpty, true);
    });
  });

  group('AI Meal Planner Screen UI Widget Tests', () {
    testWidgets('Renders 7-day meal plan with dynamic summary and meals', (tester) async {
      final samplePlan = MealPlanResponse(
        durationDays: 7,
        goal: 'Muscle Gain',
        diet: 'Vegetarian',
        targetCalories: 2200,
        summary: 'Your 7-day meal plan is tailored for Muscle Gain with high protein and balanced macros.',
        geminiPowered: true,
        days: List.generate(7, (i) => MealPlanDay(
          day: i + 1,
          dayLabel: 'Day ${i + 1}',
          dayNumber: 'Day ${i + 1}',
          date: '2026-08-${28 + i}',
          dailyCalories: 2200,
          dailyProtein: 95,
          dailyFiber: 35,
          waterGlasses: 9,
          meals: const [
            MealPlanMeal(
              type: 'Breakfast',
              recipeId: 'm1',
              title: 'High-Protein Green Egg Scramble',
              calories: 420,
              proteinGrams: 28,
              carbsGrams: 18,
              fatGrams: 22,
              fiberGrams: 5,
              image: 'https://images.unsplash.com/photo-1525351484163-7529414344d8',
              ingredients: ['Eggs', 'Spinach', 'Feta'],
              isVegetarian: true,
            ),
            MealPlanMeal(
              type: 'Lunch',
              recipeId: 'm2',
              title: 'Paneer Protein Rice Bowl',
              calories: 680,
              proteinGrams: 32,
              carbsGrams: 75,
              fatGrams: 18,
              fiberGrams: 8,
              image: 'https://images.unsplash.com/photo-1512058564366-18510be2db19',
              ingredients: ['Paneer', 'Brown Rice', 'Peas'],
              isVegetarian: true,
            ),
          ],
        )),
        totals: const MealPlanTotals(averageCalories: 2200, averageProtein: 95, averageFiber: 35),
      );

      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: AiMealPlannerScreen(initialPlan: samplePlan),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1600));

      // Check header and plan title
      expect(find.text('AI Meal Planner'), findsOneWidget);
      expect(find.text('3. Your 7-Day Plan'), findsOneWidget);

      // Check dynamic AI summary
      expect(find.text('AI Meal Plan Summary'), findsOneWidget);
      expect(find.text(samplePlan.summary), findsOneWidget);

      // Check meals rendered
      expect(find.text('High-Protein Green Egg Scramble'), findsOneWidget);
      expect(find.text('Paneer Protein Rice Bowl'), findsOneWidget);

      // Check bottom action buttons
      expect(find.text('Export PDF'), findsOneWidget);
      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('Regenerate'), findsOneWidget);
    });
  });
}
