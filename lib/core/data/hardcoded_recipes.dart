import 'package:flutter/material.dart';
import '../services/recipe_service.dart';
import '../../features/recipe_generator/recipe_generator_screen.dart';
import '../../features/recipe_generator/recipe_detail_screen.dart';

/// DietCompass — Curated Hardcoded Recipe Catalog
/// Preserves 6 curated high-quality recipes:
/// 1. Banana Oats Power Bowl
/// 2. Chocolate Banana Overnight Oats
/// 3. Apple Cinnamon Oatmeal Bowl
/// 4. Savory Spinach & Mushroom Oats
/// 5. High-Protein Green Egg Scramble
/// 6. Pasta Primavera with Fresh Vegetables
class HardcodedRecipeCatalog {
  HardcodedRecipeCatalog._();

  static final List<RecipeCardData> recipes = [
    _bananaOatsPowerBowl,
    _chocolateBananaOvernightOats,
    _appleCinnamonOatmealBowl,
    _savorySpinachMushroomOats,
    _highProteinGreenEggScramble,
    _pastaPrimavera,
  ];

  static RecipeCardData get bananaOatsPowerBowl => _bananaOatsPowerBowl;
  static RecipeCardData get chocolateBananaOvernightOats => _chocolateBananaOvernightOats;
  static RecipeCardData get appleCinnamonOatmealBowl => _appleCinnamonOatmealBowl;
  static RecipeCardData get savorySpinachMushroomOats => _savorySpinachMushroomOats;
  static RecipeCardData get highProteinGreenEggScramble => _highProteinGreenEggScramble;
  static RecipeCardData get pastaPrimavera => _pastaPrimavera;

  static RecipeCardData? findByIdOrTitle(String idOrTitle) {
    final target = idOrTitle.toLowerCase().trim();
    for (final r in recipes) {
      if (r.id?.toString().toLowerCase() == target ||
          r.title.toLowerCase() == target ||
          r.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') == target.replaceAll(RegExp(r'[^a-z0-9]'), '')) {
        return r;
      }
    }
    return null;
  }

  static List<RecipeCardData> findMatchingSearch(String query) {
    if (query.trim().isEmpty) return [];
    final clean = query.toLowerCase().trim();
    final tokens = clean.split(RegExp(r'[\s,+/_-]+')).where((t) => t.length >= 3).toList();

    return recipes.where((r) {
      final title = r.title.toLowerCase();
      final desc = r.description.toLowerCase();
      final ings = r.fullRecipe?.ingredients.map((i) => i.name.toLowerCase()).join(' ') ?? '';
      final corpus = '$title $desc $ings';

      if (corpus.contains(clean)) return true;
      for (final t in tokens) {
        if (RegExp('\\b$t(s|es)?\\b').hasMatch(corpus)) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  // 1. Banana Oats Power Bowl
  static final RecipeCardData _bananaOatsPowerBowl = RecipeCardData(
    id: 'hardcoded_banana_oats',
    title: 'Banana Oats Power Bowl',
    tagline: 'Healthy • Quick 15 min • Energy Rich',
    description: 'A nutritious bowl packed with fiber, protein and natural energy to kickstart your day!',
    timeMinutes: 15,
    kcal: 320,
    proteinGrams: 12,
    imageAsset: 'assets/images/recipe_banana_oats_power_bowl.jpeg',
    recipeSource: 'curated',
    recommended: true,
    whatsInside: const [
      WhatsInTag(icon: Icons.eco_rounded, title: 'High in Fiber', subtitle: 'Good for digestion', color: Color(0xFF1E8A4C)),
      WhatsInTag(icon: Icons.bolt_rounded, title: 'Natural Energy', subtitle: 'Sustained vitality', color: Color(0xFFE0862E)),
      WhatsInTag(icon: Icons.favorite_rounded, title: 'Heart Healthy', subtitle: 'Whole grain oats', color: Color(0xFFE0525C)),
      WhatsInTag(icon: Icons.shopping_bag_rounded, title: 'Weight Friendly', subtitle: 'Nutrient dense', color: Color(0xFF6C4EF5)),
    ],
    fullRecipe: const Recipe(
      id: 'hardcoded_banana_oats',
      images: ['assets/images/recipe_banana_oats_power_bowl.jpeg'],
      title: 'Banana Oats Power Bowl',
      tags: ['Healthy', 'Quick', 'Delicious', 'Vegetarian', 'High Fiber'],
      description: 'A nutritious bowl packed with fiber, protein and natural energy to kickstart your day!',
      prepTime: '15 min',
      calories: '320 kcal',
      protein: '12g',
      difficulty: 'Easy',
      nutritionFacts: [
        NutritionFact(icon: Icons.local_fire_department, color: Color(0xFFE0862E), label: 'Calories', value: '320\nkcal'),
        NutritionFact(icon: Icons.circle, color: Color(0xFF6C4EF5), label: 'Carbs', value: '52g'),
        NutritionFact(icon: Icons.eco, color: Color(0xFF1E8A4C), label: 'Protein', value: '12g'),
        NutritionFact(icon: Icons.opacity, color: Color(0xFFE0B32E), label: 'Fat', value: '6g'),
        NutritionFact(icon: Icons.grass, color: Color(0xFF1E8A4C), label: 'Fiber', value: '7g'),
        NutritionFact(icon: Icons.icecream, color: Color(0xFFE0525C), label: 'Sugar', value: '14g'),
        NutritionFact(icon: Icons.shield_outlined, color: Color(0xFF3B82F6), label: 'Sodium', value: '45mg'),
      ],
      ingredients: [
        IngredientItem(amount: '1/2 cup', name: 'Rolled Oats'),
        IngredientItem(amount: '1 sliced', name: 'Ripe Banana'),
        IngredientItem(amount: '1 cup', name: 'Milk'),
        IngredientItem(amount: '1 tsp', name: 'Honey'),
        IngredientItem(amount: '1 tbsp', name: 'Chia Seeds'),
        IngredientItem(amount: '1 tbsp', name: 'Chopped Almonds'),
      ],
      instructions: [
        'In a saucepan, bring milk to a gentle simmer over medium heat.',
        'Add rolled oats and cook for 5 minutes, stirring continuously until creamy.',
        'Pour oatmeal into a serving bowl and arrange fresh banana slices on top.',
        'Drizzle with honey and garnish with chia seeds and chopped almonds.',
        'Serve warm for sustained morning energy!',
      ],
      serves: 1,
    ),
  );

  // 2. Chocolate Banana Overnight Oats
  static final RecipeCardData _chocolateBananaOvernightOats = RecipeCardData(
    id: 'hardcoded_chocolate_banana_oats',
    title: 'Chocolate Banana Overnight Oats',
    tagline: 'Make-ahead • Creamy • Antioxidant Rich',
    description: 'Creamy oats infused with rich cocoa, sweet banana and crunchy nuts. Perfect for a healthy make-ahead breakfast.',
    timeMinutes: 10,
    kcal: 320,
    proteinGrams: 11,
    imageAsset: 'assets/images/recipe_chocolate_banana_oats.jpeg',
    recipeSource: 'curated',
    recommended: false,
    whatsInside: const [
      WhatsInTag(icon: Icons.eco_rounded, title: 'High Fiber', subtitle: 'Keeps you full', color: Color(0xFF1E8A4C)),
      WhatsInTag(icon: Icons.nightlight_round, title: 'Make-Ahead', subtitle: 'Ready overnight', color: Color(0xFF6C4EF5)),
      WhatsInTag(icon: Icons.favorite_rounded, title: 'Antioxidants', subtitle: 'From pure cocoa', color: Color(0xFFE0525C)),
      WhatsInTag(icon: Icons.shopping_bag_rounded, title: 'Portion Smart', subtitle: 'Balanced calories', color: Color(0xFFE0862E)),
    ],
    fullRecipe: const Recipe(
      id: 'hardcoded_chocolate_banana_oats',
      images: ['assets/images/recipe_chocolate_banana_oats.jpeg'],
      title: 'Chocolate Banana Overnight Oats',
      tags: ['Make-ahead', 'Creamy', 'Kid-friendly', 'Vegetarian', 'Chocolate', 'Dessert'],
      description: 'Creamy oats infused with rich cocoa, sweet banana and crunchy nuts. Perfect for a healthy make-ahead breakfast.',
      prepTime: '10 min',
      calories: '320 kcal',
      protein: '11g',
      difficulty: 'Easy',
      nutritionFacts: [
        NutritionFact(icon: Icons.local_fire_department, color: Color(0xFFE0862E), label: 'Calories', value: '320\nkcal'),
        NutritionFact(icon: Icons.circle, color: Color(0xFF6C4EF5), label: 'Carbs', value: '50g'),
        NutritionFact(icon: Icons.eco, color: Color(0xFF1E8A4C), label: 'Protein', value: '11g'),
        NutritionFact(icon: Icons.opacity, color: Color(0xFFE0B32E), label: 'Fat', value: '7g'),
        NutritionFact(icon: Icons.grass, color: Color(0xFF1E8A4C), label: 'Fiber', value: '8g'),
        NutritionFact(icon: Icons.icecream, color: Color(0xFFE0525C), label: 'Sugar', value: '12g'),
        NutritionFact(icon: Icons.shield_outlined, color: Color(0xFF3B82F6), label: 'Sodium', value: '50mg'),
      ],
      ingredients: [
        IngredientItem(amount: '1/2 cup', name: 'Rolled Oats'),
        IngredientItem(amount: '1 tbsp', name: 'Cocoa Powder'),
        IngredientItem(amount: '1 medium', name: 'Mashed Banana'),
        IngredientItem(amount: '3/4 cup', name: 'Milk'),
        IngredientItem(amount: '1 tsp', name: 'Chia Seeds'),
        IngredientItem(amount: '1 tsp', name: 'Dark Chocolate Chips'),
        IngredientItem(amount: '1 tbsp', name: 'Walnuts'),
      ],
      instructions: [
        'In a mason jar or glass bowl, combine rolled oats, cocoa powder, and chia seeds.',
        'Add milk and mashed banana, stirring vigorously until cocoa is fully incorporated.',
        'Cover with a lid and refrigerate overnight (or for at least 4 hours).',
        'Before serving, top with dark chocolate chips and chopped walnuts.',
        'Enjoy chilled for a creamy, decadent breakfast dessert!',
      ],
      serves: 1,
    ),
  );

  // 3. Apple Cinnamon Oatmeal Bowl
  static final RecipeCardData _appleCinnamonOatmealBowl = RecipeCardData(
    id: 'hardcoded_apple_cinnamon_oatmeal',
    title: 'Apple Cinnamon Oatmeal Bowl',
    tagline: 'Warm • Comforting • Heart Healthy',
    description: 'Warm, comforting whole grain oats simmered with crisp apples, aromatic cinnamon and toasted walnuts.',
    timeMinutes: 12,
    kcal: 310,
    proteinGrams: 9,
    imageAsset: 'assets/images/recipe_apple_cinnamon_oatmeal.jpeg',
    recipeSource: 'curated',
    recommended: false,
    whatsInside: const [
      WhatsInTag(icon: Icons.favorite_rounded, title: 'Good for Heart', subtitle: 'Whole grain oats', color: Color(0xFFE0525C)),
      WhatsInTag(icon: Icons.eco_rounded, title: 'Fiber Rich', subtitle: 'Apple + oats', color: Color(0xFF1E8A4C)),
      WhatsInTag(icon: Icons.bolt_rounded, title: 'Steady Energy', subtitle: 'Low glycemic index', color: Color(0xFFE0862E)),
      WhatsInTag(icon: Icons.shopping_bag_rounded, title: 'No Added Sugar', subtitle: 'Naturally sweetened', color: Color(0xFF6C4EF5)),
    ],
    fullRecipe: const Recipe(
      id: 'hardcoded_apple_cinnamon_oatmeal',
      images: ['assets/images/recipe_apple_cinnamon_oatmeal.jpeg'],
      title: 'Apple Cinnamon Oatmeal Bowl',
      tags: ['Warm', 'Comforting', 'Wholesome', 'Vegetarian', 'Apple', 'Cinnamon'],
      description: 'Warm, comforting whole grain oats simmered with crisp apples, aromatic cinnamon and toasted walnuts.',
      prepTime: '12 min',
      calories: '310 kcal',
      protein: '9g',
      difficulty: 'Easy',
      nutritionFacts: [
        NutritionFact(icon: Icons.local_fire_department, color: Color(0xFFE0862E), label: 'Calories', value: '310\nkcal'),
        NutritionFact(icon: Icons.circle, color: Color(0xFF6C4EF5), label: 'Carbs', value: '48g'),
        NutritionFact(icon: Icons.eco, color: Color(0xFF1E8A4C), label: 'Protein', value: '9g'),
        NutritionFact(icon: Icons.opacity, color: Color(0xFFE0B32E), label: 'Fat', value: '6g'),
        NutritionFact(icon: Icons.grass, color: Color(0xFF1E8A4C), label: 'Fiber', value: '6g'),
        NutritionFact(icon: Icons.icecream, color: Color(0xFFE0525C), label: 'Sugar', value: '15g'),
        NutritionFact(icon: Icons.shield_outlined, color: Color(0xFF3B82F6), label: 'Sodium', value: '40mg'),
      ],
      ingredients: [
        IngredientItem(amount: '1/2 cup', name: 'Rolled Oats'),
        IngredientItem(amount: '1/2 diced', name: 'Fresh Apple'),
        IngredientItem(amount: '1 cup', name: 'Milk'),
        IngredientItem(amount: '1/2 tsp', name: 'Cinnamon Powder'),
        IngredientItem(amount: '1 tsp', name: 'Honey'),
        IngredientItem(amount: '1 tbsp', name: 'Chopped Walnuts'),
      ],
      instructions: [
        'In a small pot, simmer milk and diced apples for 3 minutes until apples soften slightly.',
        'Stir in rolled oats and ground cinnamon.',
        'Cook over low heat for 5-6 minutes, stirring occasionally until thick.',
        'Transfer to a bowl, drizzle with honey, and top with toasted walnuts.',
        'Serve warm on cozy mornings!',
      ],
      serves: 1,
    ),
  );

  // 4. Savory Spinach & Mushroom Oats
  static final RecipeCardData _savorySpinachMushroomOats = RecipeCardData(
    id: 'hardcoded_savory_spinach_mushroom_oats',
    title: 'Savory Spinach & Mushroom Oats',
    tagline: 'Savory • High Fiber • Quick 15 min',
    description: 'A wholesome savory oats bowl sautéed with fresh baby spinach, earthy mushrooms, garlic, and cracked black pepper.',
    timeMinutes: 15,
    kcal: 280,
    proteinGrams: 14,
    imageAsset: 'assets/images/recipe_savory_veggie_oats.jpeg',
    recipeSource: 'curated',
    recommended: false,
    whatsInside: const [
      WhatsInTag(icon: Icons.fitness_center_rounded, title: 'High Protein', subtitle: 'Plant protein 14g', color: Color(0xFFE0862E)),
      WhatsInTag(icon: Icons.eco_rounded, title: 'Veggie Packed', subtitle: 'Spinach & mushroom', color: Color(0xFF1E8A4C)),
      WhatsInTag(icon: Icons.favorite_rounded, title: 'Low Fat', subtitle: 'Heart friendly', color: Color(0xFFE0525C)),
      WhatsInTag(icon: Icons.shopping_bag_rounded, title: 'Weight Friendly', subtitle: 'Low calorie', color: Color(0xFF6C4EF5)),
    ],
    fullRecipe: const Recipe(
      id: 'hardcoded_savory_spinach_mushroom_oats',
      images: ['assets/images/recipe_savory_veggie_oats.jpeg'],
      title: 'Savory Spinach & Mushroom Oats',
      tags: ['Savory', 'High Fiber', 'Warm', 'Vegetarian', 'Vegan', 'Spinach', 'Mushroom'],
      description: 'A wholesome savory oats bowl sautéed with fresh baby spinach, earthy mushrooms, garlic, and cracked black pepper.',
      prepTime: '15 min',
      calories: '280 kcal',
      protein: '14g',
      difficulty: 'Easy',
      nutritionFacts: [
        NutritionFact(icon: Icons.local_fire_department, color: Color(0xFFE0862E), label: 'Calories', value: '280\nkcal'),
        NutritionFact(icon: Icons.circle, color: Color(0xFF6C4EF5), label: 'Carbs', value: '38g'),
        NutritionFact(icon: Icons.eco, color: Color(0xFF1E8A4C), label: 'Protein', value: '14g'),
        NutritionFact(icon: Icons.opacity, color: Color(0xFFE0B32E), label: 'Fat', value: '7g'),
        NutritionFact(icon: Icons.grass, color: Color(0xFF1E8A4C), label: 'Fiber', value: '8g'),
        NutritionFact(icon: Icons.icecream, color: Color(0xFFE0525C), label: 'Sugar', value: '3g'),
        NutritionFact(icon: Icons.shield_outlined, color: Color(0xFF3B82F6), label: 'Sodium', value: '120mg'),
      ],
      ingredients: [
        IngredientItem(amount: '1/2 cup', name: 'Rolled Oats'),
        IngredientItem(amount: '1 cup', name: 'Fresh Baby Spinach'),
        IngredientItem(amount: '1/2 cup', name: 'Sliced Mushrooms'),
        IngredientItem(amount: '1 tsp', name: 'Olive Oil'),
        IngredientItem(amount: '1 clove', name: 'Minced Garlic'),
        IngredientItem(amount: '1 cup', name: 'Vegetable Broth or Water'),
        IngredientItem(amount: 'To taste', name: 'Salt & Black Pepper'),
      ],
      instructions: [
        'Heat olive oil in a skillet over medium heat and sauté minced garlic for 30 seconds.',
        'Add sliced mushrooms and cook until browned (3-4 minutes).',
        'Add baby spinach and toss until wilted.',
        'In a separate pot, cook oats in vegetable broth or water for 5 minutes with salt and pepper.',
        'Spoon savory oats into a bowl and top with the warm sautéed spinach and mushrooms.',
      ],
      serves: 1,
    ),
  );

  // 5. High-Protein Green Egg Scramble
  static final RecipeCardData _highProteinGreenEggScramble = RecipeCardData(
    id: 'hardcoded_high_protein_green_egg_scramble',
    title: 'High-Protein Green Egg Scramble',
    tagline: 'High-Protein • Quick 10 min • Keto Friendly',
    description: 'Fluffy whole eggs scrambled with fresh baby spinach, diced bell peppers, and olive oil for a lean, high-protein powerhouse breakfast.',
    timeMinutes: 10,
    kcal: 260,
    proteinGrams: 20,
    imageAsset: 'assets/images/recipe_veggie_omelette.jpeg',
    recipeSource: 'curated',
    recommended: false,
    whatsInside: const [
      WhatsInTag(icon: Icons.fitness_center_rounded, title: 'High Protein', subtitle: '20g muscle fuel', color: Color(0xFF1E8A4C)),
      WhatsInTag(icon: Icons.bolt_rounded, title: 'Low Carb', subtitle: 'Keto friendly 4g carbs', color: Color(0xFFE0862E)),
      WhatsInTag(icon: Icons.eco_rounded, title: 'Green Superfood', subtitle: 'Rich in iron & folate', color: Color(0xFF1E8A4C)),
      WhatsInTag(icon: Icons.favorite_rounded, title: 'Quick Fuel', subtitle: 'Ready in 10 mins', color: Color(0xFFE0525C)),
    ],
    fullRecipe: const Recipe(
      id: 'hardcoded_high_protein_green_egg_scramble',
      images: ['assets/images/recipe_veggie_omelette.jpeg'],
      title: 'High-Protein Green Egg Scramble',
      tags: ['High-Protein', 'Quick 10 min', 'Keto-friendly', 'Eggetarian', 'Eggs', 'Spinach'],
      description: 'Fluffy whole eggs scrambled with fresh baby spinach, diced bell peppers, and olive oil for a lean, high-protein powerhouse breakfast.',
      prepTime: '10 min',
      calories: '260 kcal',
      protein: '20g',
      difficulty: 'Easy',
      nutritionFacts: [
        NutritionFact(icon: Icons.local_fire_department, color: Color(0xFFE0862E), label: 'Calories', value: '260\nkcal'),
        NutritionFact(icon: Icons.circle, color: Color(0xFF6C4EF5), label: 'Carbs', value: '4g'),
        NutritionFact(icon: Icons.eco, color: Color(0xFF1E8A4C), label: 'Protein', value: '20g'),
        NutritionFact(icon: Icons.opacity, color: Color(0xFFE0B32E), label: 'Fat', value: '16g'),
        NutritionFact(icon: Icons.grass, color: Color(0xFF1E8A4C), label: 'Fiber', value: '2g'),
        NutritionFact(icon: Icons.icecream, color: Color(0xFFE0525C), label: 'Sugar', value: '1g'),
        NutritionFact(icon: Icons.shield_outlined, color: Color(0xFF3B82F6), label: 'Sodium', value: '180mg'),
      ],
      ingredients: [
        IngredientItem(amount: '2 large', name: 'Whole Eggs'),
        IngredientItem(amount: '2 large', name: 'Egg Whites'),
        IngredientItem(amount: '1 cup packed', name: 'Baby Spinach'),
        IngredientItem(amount: '1/4 cup', name: 'Diced Bell Pepper'),
        IngredientItem(amount: '1 tsp', name: 'Olive Oil'),
        IngredientItem(amount: 'To taste', name: 'Salt & Black Pepper'),
      ],
      instructions: [
        'Whisk eggs and egg whites in a bowl with a pinch of salt and black pepper.',
        'Heat olive oil in a non-stick skillet over medium-low heat.',
        'Add diced bell pepper and spinach; cook for 1-2 minutes until spinach wilts.',
        'Pour in whisked eggs and gently scramble with a spatula until soft and fluffy (2-3 minutes).',
        'Transfer to a plate and serve immediately with fresh herbs or sliced avocado.',
      ],
      serves: 1,
    ),
  );

  // 6. Pasta Primavera with Fresh Vegetables
  static final RecipeCardData _pastaPrimavera = RecipeCardData(
    id: 'hardcoded_pasta_primavera',
    title: 'Pasta Primavera with Fresh Vegetables',
    tagline: 'Italian • Fresh Veggies • High Fiber',
    description: 'Tender pasta tossed with colorful sautéed bell peppers, zucchini, sweet cherry tomatoes, extra virgin olive oil, and grated parmesan cheese.',
    timeMinutes: 18,
    kcal: 380,
    proteinGrams: 13,
    imageAsset: 'assets/images/recipe_protein_pancakes.jpeg',
    recipeSource: 'curated',
    recommended: false,
    whatsInside: const [
      WhatsInTag(icon: Icons.eco_rounded, title: 'Fiber Rich', subtitle: 'Fresh seasonal veggies', color: Color(0xFF1E8A4C)),
      WhatsInTag(icon: Icons.favorite_rounded, title: 'Heart Healthy', subtitle: 'Extra virgin olive oil', color: Color(0xFFE0525C)),
      WhatsInTag(icon: Icons.bolt_rounded, title: 'Energizing', subtitle: 'Complex carbohydrates', color: Color(0xFFE0862E)),
      WhatsInTag(icon: Icons.shopping_bag_rounded, title: 'Classic Taste', subtitle: 'Authentic Italian flair', color: Color(0xFF6C4EF5)),
    ],
    fullRecipe: const Recipe(
      id: 'hardcoded_pasta_primavera',
      images: ['assets/images/recipe_protein_pancakes.jpeg'],
      title: 'Pasta Primavera with Fresh Vegetables',
      tags: ['Italian', 'Colorful', 'Vegetarian', 'Fiber Rich', 'Pasta', 'Dinner'],
      description: 'Tender pasta tossed with colorful sautéed bell peppers, zucchini, sweet cherry tomatoes, extra virgin olive oil, and grated parmesan cheese.',
      prepTime: '18 min',
      calories: '380 kcal',
      protein: '13g',
      difficulty: 'Easy',
      nutritionFacts: [
        NutritionFact(icon: Icons.local_fire_department, color: Color(0xFFE0862E), label: 'Calories', value: '380\nkcal'),
        NutritionFact(icon: Icons.circle, color: Color(0xFF6C4EF5), label: 'Carbs', value: '58g'),
        NutritionFact(icon: Icons.eco, color: Color(0xFF1E8A4C), label: 'Protein', value: '13g'),
        NutritionFact(icon: Icons.opacity, color: Color(0xFFE0B32E), label: 'Fat', value: '10g'),
        NutritionFact(icon: Icons.grass, color: Color(0xFF1E8A4C), label: 'Fiber', value: '6g'),
        NutritionFact(icon: Icons.icecream, color: Color(0xFFE0525C), label: 'Sugar', value: '5g'),
        NutritionFact(icon: Icons.shield_outlined, color: Color(0xFF3B82F6), label: 'Sodium', value: '140mg'),
      ],
      ingredients: [
        IngredientItem(amount: '1 cup dry', name: 'Pasta (Penne or Fusilli)'),
        IngredientItem(amount: '1/2 sliced', name: 'Zucchini'),
        IngredientItem(amount: '1/2 cup sliced', name: 'Bell Peppers'),
        IngredientItem(amount: '1/2 cup halved', name: 'Cherry Tomatoes'),
        IngredientItem(amount: '1 tbsp', name: 'Olive Oil'),
        IngredientItem(amount: '2 cloves', name: 'Minced Garlic'),
        IngredientItem(amount: '1 tbsp', name: 'Grated Parmesan Cheese'),
        IngredientItem(amount: 'To taste', name: 'Italian Herbs & Pepper'),
      ],
      instructions: [
        'Boil pasta in salted water according to package instructions until al dente; drain and save 2 tbsp cooking water.',
        'Heat olive oil in a large skillet over medium heat and sauté garlic for 30 seconds.',
        'Add sliced bell peppers, zucchini, and cherry tomatoes; sauté for 4-5 minutes until tender-crisp.',
        'Toss drained pasta and reserved pasta water with the vegetables in the pan.',
        'Season with Italian herbs, sprinkle with parmesan cheese, and serve immediately.',
      ],
      serves: 1,
    ),
  );
}
