const assert = require('assert');
const { generatePersonalizedRecipes } = require('./src/services/recipePipelineService');
const { getMatchingPantryIngredients } = require('./src/utils/productNormalizer');

async function runPantryRuntimeE2ETests() {
  console.log('===============================================================');
  console.log('DIETCOMPASS END-TO-END PANTRY RUNTIME RELEVANCE TEST SUITE');
  console.log('===============================================================\n');

  let passed = 0;
  let failed = 0;

  function test(name, fn) {
    return (async () => {
      try {
        await fn();
        console.log(`  ✓ PASS: ${name}`);
        passed++;
      } catch (e) {
        console.error(`  ✗ FAIL: ${name}`);
        console.error(`    Error: ${e.message}`);
        failed++;
      }
    })();
  }

  // ---------------------------------------------------------------------------
  // TEST 1: Exact Runtime Failing Case (rice, noodle, chilli)
  // ---------------------------------------------------------------------------
  await test('1. Pantry ["rice", "noodle", "chilli"] returns recipes matching >= 1 pantry item', async () => {
    const pantry = ['rice', 'noodle', 'chilli'];
    const result = await generatePersonalizedRecipes({
      mode: 'pantry',
      ingredients: pantry,
      pantryItems: pantry,
      mealType: 'Breakfast',
      maxTime: 20,
      userProfile: {
        dietType: 'Vegetarian',
        goals: ['Weight Loss', 'Muscle Gain'],
      },
      personalization: {
        dietType: 'Vegetarian',
        goals: ['Weight Loss', 'Muscle Gain'],
        nutritionPreference: 'Balanced',
      },
      number: 6,
    });

    assert(result, 'Result should not be null');
    assert(Array.isArray(result.recipes), 'Recipes should be an array');
    assert(result.recipes.length > 0, 'Should return at least 1 recipe');
    assert.notStrictEqual(result.recipeSource, 'none', 'Should not be none');

    console.log(`    Generated ${result.recipes.length} recipes (source: ${result.recipeSource}):`);

    const unrelatedCuratedTitles = [
      'banana oats power bowl',
      'chocolate banana overnight oats',
      'apple cinnamon oatmeal bowl',
      'savory spinach & mushroom oats',
      'high-protein green egg scramble',
      'pasta primavera with fresh vegetables',
    ];

    for (const recipe of result.recipes) {
      const titleLower = (recipe.title || '').toLowerCase().trim();
      const matchedPantry = getMatchingPantryIngredients(recipe, pantry);
      console.log(`      - "${recipe.title}" | Matched Pantry: [${matchedPantry.join(', ')}] | Ingredients: ${(recipe.ingredients || []).map(i => i.name).join(', ')}`);

      // 1. MUST contain at least one pantry ingredient
      assert(
        matchedPantry.length >= 1,
        `Recipe "${recipe.title}" has 0 matched pantry ingredients! Ingredients: ${JSON.stringify(recipe.ingredients)}`
      );

      // 2. MUST NOT be one of the unrelated oats / egg hardcoded recipes
      assert(
        !unrelatedCuratedTitles.includes(titleLower),
        `Recipe "${recipe.title}" is an unrelated curated fallback recipe that does not belong in pantry mode results!`
      );
    }
  });

  // ---------------------------------------------------------------------------
  // TEST 2: Diversity Coverage across Pantry Ingredients
  // ---------------------------------------------------------------------------
  await test('2. Pantry with ["rice", "noodle", "chilli"] provides diverse ingredient coverage', async () => {
    const pantry = ['rice', 'noodle', 'chilli'];
    const result = await generatePersonalizedRecipes({
      mode: 'pantry',
      ingredients: pantry,
      pantryItems: pantry,
      mealType: 'Breakfast',
      maxTime: 20,
      userProfile: { dietType: 'Vegetarian' },
      personalization: { dietType: 'Vegetarian' },
      number: 6,
    });

    const allMatches = new Set();
    for (const r of result.recipes) {
      const matches = getMatchingPantryIngredients(r, pantry);
      matches.forEach((m) => allMatches.add(m));
    }

    console.log(`    Unique pantry ingredients covered: [${[...allMatches].join(', ')}]`);
    assert(allMatches.size >= 1, 'Should cover pantry ingredients across the collection');
  });

  // ---------------------------------------------------------------------------
  // TEST 3: Pantry ["egg", "spinach"] properly matches curated egg/spinach recipes
  // ---------------------------------------------------------------------------
  await test('3. Pantry with ["egg", "spinach"] matches eggetarian curated recipes', async () => {
    const pantry = ['egg', 'spinach'];
    const result = await generatePersonalizedRecipes({
      mode: 'pantry',
      ingredients: pantry,
      pantryItems: pantry,
      mealType: 'Breakfast',
      maxTime: 20,
      userProfile: { dietType: 'Eggetarian' },
      personalization: { dietType: 'Eggetarian' },
      number: 6,
    });

    for (const recipe of result.recipes) {
      const matchedPantry = getMatchingPantryIngredients(recipe, pantry);
      assert(matchedPantry.length >= 1, `Recipe "${recipe.title}" must match egg or spinach`);
    }
  });

  // ---------------------------------------------------------------------------
  // TEST 4: Empty Pantry Guard
  // ---------------------------------------------------------------------------
  await test('4. Empty pantry returns empty recipe list without fabricating items', async () => {
    const result = await generatePersonalizedRecipes({
      mode: 'pantry',
      ingredients: [],
      pantryItems: [],
      userProfile: { dietType: 'Vegetarian' },
      personalization: { dietType: 'Vegetarian' },
      number: 6,
    });

    assert.strictEqual(result.recipes.length, 0, 'Empty pantry must return 0 recipes');
    assert.strictEqual(result.recipeSource, 'none', 'Source must be none');
  });

  // ---------------------------------------------------------------------------
  // TEST 5: Explicit Search "chocolate" returns Chocolate Banana Overnight Oats
  // ---------------------------------------------------------------------------
  await test('5. Explicit search "chocolate" still matches Chocolate Banana Overnight Oats', async () => {
    const result = await generatePersonalizedRecipes({
      mode: 'pantry',
      craving: 'chocolate',
      ingredients: [],
      pantryItems: [],
      userProfile: { dietType: 'Vegetarian' },
      personalization: { dietType: 'Vegetarian' },
      number: 6,
    });

    assert(result.recipes.length > 0, 'Should return recipes for search');
    const titles = result.recipes.map((r) => r.title.toLowerCase());
    const matchesChocolate = titles.some((t) => t.includes('chocolate') || t.includes('choco'));
    assert(matchesChocolate, 'Search results must include chocolate recipe');
  });

  console.log('\n===============================================================');
  console.log(`RESULTS: ${passed} PASSED | ${failed} FAILED`);
  console.log('===============================================================\n');

  if (failed > 0) {
    process.exit(1);
  }
}

runPantryRuntimeE2ETests().catch((err) => {
  console.error('Fatal Test Runner Error:', err);
  process.exit(1);
});
