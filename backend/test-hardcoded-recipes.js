/**
 * DietCompass — Test Suite for Hardcoded / Fallback Recipe Integration
 * Verifies:
 * 1. Search Query Relevance: "chocolate", "banana", "oats", "egg", "pasta" matching
 * 2. Irrelevant Recipe Exclusion (e.g. Pasta Primavera excluded when searching chocolate)
 * 3. Case 1: Pantry Mode with matching recipes does NOT inject unrelated hardcoded recipes
 * 4. Case 1: Zero-result Fallback returns safe hardcoded recipes
 * 5. Case 2: Explicit Search candidate participation
 * 6. ID lookup via getRecipeDetails
 */

const {
  HARDCODED_RECIPES,
  findMatchingHardcodedRecipes,
  findPantryMatchingHardcodedRecipes,
  getFallbackHardcodedRecipes,
  getHardcodedRecipeById,
  doesRecipeMatchQuery,
} = require('./src/data/hardcodedRecipes');

const recipePipelineService = require('./src/services/recipePipelineService');

let passed = 0;
let failed = 0;

const assert = (condition, message) => {
  if (condition) {
    console.log(`  ✅ PASS: ${message}`);
    passed++;
  } else {
    console.error(`  ❌ FAIL: ${message}`);
    failed++;
  }
};

const runTests = async () => {
  console.log('\n======================================================');
  console.log('🧪 TEST SUITE: HARDCODED RECIPE PIPELINE & SEARCH RELEVANCE');
  console.log('======================================================\n');

  // --- SECTION 1: Catalog Integrity ---
  console.log('--- SECTION 1: Catalog Integrity ---');
  assert(HARDCODED_RECIPES.length === 6, `Catalog contains exactly 6 curated recipes (found: ${HARDCODED_RECIPES.length})`);
  
  const titles = HARDCODED_RECIPES.map((r) => r.title);
  assert(titles.includes('Banana Oats Power Bowl'), 'Contains Banana Oats Power Bowl');
  assert(titles.includes('Chocolate Banana Overnight Oats'), 'Contains Chocolate Banana Overnight Oats');
  assert(titles.includes('Apple Cinnamon Oatmeal Bowl'), 'Contains Apple Cinnamon Oatmeal Bowl');
  assert(titles.includes('Savory Spinach & Mushroom Oats'), 'Contains Savory Spinach & Mushroom Oats');
  assert(titles.includes('High-Protein Green Egg Scramble'), 'Contains High-Protein Green Egg Scramble');
  assert(titles.includes('Pasta Primavera with Fresh Vegetables'), 'Contains Pasta Primavera with Fresh Vegetables');

  for (const r of HARDCODED_RECIPES) {
    assert(r.id && r.id.startsWith('hardcoded_'), `${r.title} has valid hardcoded ID: ${r.id}`);
    assert(Array.isArray(r.ingredients) && r.ingredients.length >= 4, `${r.title} has detailed ingredients list`);
    assert(Array.isArray(r.instructions) && r.instructions.length >= 3, `${r.title} has step-by-step instructions`);
    assert(Array.isArray(r.whatsInside) && r.whatsInside.length >= 3, `${r.title} has whatsInside tags`);
    assert(typeof r.kcal === 'number' && typeof r.proteinGrams === 'number', `${r.title} has macro data`);
  }

  // --- SECTION 2: Explicit Search / Craving Query Matching ---
  console.log('\n--- SECTION 2: Explicit Search / Craving Query Matching ---');
  
  // Search: "chocolate"
  const chocolateMatches = findMatchingHardcodedRecipes('chocolate');
  assert(chocolateMatches.length === 1, `Search "chocolate" returns exactly 1 recipe (got: ${chocolateMatches.length})`);
  assert(chocolateMatches[0]?.title === 'Chocolate Banana Overnight Oats', `Search "chocolate" matched "Chocolate Banana Overnight Oats"`);
  assert(!chocolateMatches.some((r) => r.title.includes('Pasta Primavera')), `Search "chocolate" strictly excludes "Pasta Primavera"`);

  // Search: "banana"
  const bananaMatches = findMatchingHardcodedRecipes('banana');
  const bananaTitles = bananaMatches.map((r) => r.title);
  assert(bananaTitles.includes('Banana Oats Power Bowl'), 'Search "banana" includes "Banana Oats Power Bowl"');
  assert(bananaTitles.includes('Chocolate Banana Overnight Oats'), 'Search "banana" includes "Chocolate Banana Overnight Oats"');
  assert(!bananaTitles.includes('Pasta Primavera with Fresh Vegetables'), 'Search "banana" excludes "Pasta Primavera"');

  // Search: "oats"
  const oatsMatches = findMatchingHardcodedRecipes('oats');
  assert(oatsMatches.length === 4, `Search "oats" returns 4 oat recipes (got: ${oatsMatches.length})`);
  const oatsTitles = oatsMatches.map((r) => r.title);
  assert(oatsTitles.includes('Banana Oats Power Bowl'), 'Search "oats" includes "Banana Oats Power Bowl"');
  assert(oatsTitles.includes('Chocolate Banana Overnight Oats'), 'Search "oats" includes "Chocolate Banana Overnight Oats"');
  assert(oatsTitles.includes('Apple Cinnamon Oatmeal Bowl'), 'Search "oats" includes "Apple Cinnamon Oatmeal Bowl"');
  assert(oatsTitles.includes('Savory Spinach & Mushroom Oats'), 'Search "oats" includes "Savory Spinach & Mushroom Oats"');

  // Search: "egg"
  const eggMatches = findMatchingHardcodedRecipes('egg');
  assert(eggMatches.length === 1, `Search "egg" returns 1 recipe (got: ${eggMatches.length})`);
  assert(eggMatches[0]?.title === 'High-Protein Green Egg Scramble', 'Search "egg" matched "High-Protein Green Egg Scramble"');

  // Search: "pasta"
  const pastaMatches = findMatchingHardcodedRecipes('pasta');
  assert(pastaMatches.length === 1, `Search "pasta" returns 1 recipe (got: ${pastaMatches.length})`);
  assert(pastaMatches[0]?.title === 'Pasta Primavera with Fresh Vegetables', 'Search "pasta" matched "Pasta Primavera with Fresh Vegetables"');

  // Search: "spinach"
  const spinachMatches = findMatchingHardcodedRecipes('spinach');
  const spinachTitles = spinachMatches.map((r) => r.title);
  assert(spinachTitles.includes('Savory Spinach & Mushroom Oats'), 'Search "spinach" includes "Savory Spinach & Mushroom Oats"');
  assert(spinachTitles.includes('High-Protein Green Egg Scramble'), 'Search "spinach" includes "High-Protein Green Egg Scramble"');

  // --- SECTION 3: Dietary Safety Filtering ---
  console.log('\n--- SECTION 3: Dietary Safety Filtering ---');
  const vegProfile = { dietType: 'Vegetarian' };
  const vegEggMatches = findMatchingHardcodedRecipes('egg', { userProfile: vegProfile });
  assert(vegEggMatches.length === 0, 'Vegetarian profile rejects High-Protein Green Egg Scramble');

  const eggWithEggetarian = findMatchingHardcodedRecipes('egg', { userProfile: { dietType: 'Eggetarian' } });
  assert(eggWithEggetarian.length === 1, 'Eggetarian profile allows High-Protein Green Egg Scramble');

  // --- SECTION 4: Pantry Mode Matching & Fallback ---
  console.log('\n--- SECTION 4: Pantry Mode Matching & Fallback ---');
  const pantryIngredientsOats = ['Oats', 'Banana', 'Milk'];
  const pantryMatchesOats = findPantryMatchingHardcodedRecipes(pantryIngredientsOats);
  assert(pantryMatchesOats.length >= 3, `Pantry with [Oats, Banana, Milk] finds matching hardcoded recipes (${pantryMatchesOats.length})`);

  const pantryIngredientsUnrelated = ['rice', 'chicken', 'tuna'];
  const pantryMatchesUnrelated = findPantryMatchingHardcodedRecipes(pantryIngredientsUnrelated);
  assert(pantryMatchesUnrelated.length === 0, `Pantry with [rice, chicken, tuna] finds 0 matching curated oat/pasta recipes`);

  // Generic fallback retrieval
  const fallbacks = getFallbackHardcodedRecipes({ userProfile: vegProfile, limit: 4 });
  assert(fallbacks.length > 0 && fallbacks.length <= 4, `Fallback retrieval returns safe recipes (got: ${fallbacks.length})`);
  assert(fallbacks.every((r) => r.recipeSource === 'fallback'), 'All fallback recipes have recipeSource = "fallback"');
  assert(!fallbacks.some((r) => r.title === 'High-Protein Green Egg Scramble'), 'Fallback for Vegetarian excludes non-veg egg scramble');

  // --- SECTION 5: ID Lookup ---
  console.log('\n--- SECTION 5: ID Lookup via getRecipeDetails ---');
  const recipeDetail = await recipePipelineService.getRecipeDetails('hardcoded_chocolate_banana_oats');
  assert(recipeDetail !== null, 'getRecipeDetails resolves hardcoded_chocolate_banana_oats');
  assert(recipeDetail?.title === 'Chocolate Banana Overnight Oats', `Resolved correct title: ${recipeDetail?.title}`);
  assert(recipeDetail?.ingredients?.length > 0, `Resolved ingredients for recipe`);

  const recipeDetailTitle = await recipePipelineService.getRecipeDetails('Banana Oats Power Bowl');
  assert(recipeDetailTitle !== null, 'getRecipeDetails resolves by recipe title');
  assert(recipeDetailTitle?.id === 'hardcoded_banana_oats', `Resolved correct ID: ${recipeDetailTitle?.id}`);

  // --- SUMMARY ---
  console.log('\n======================================================');
  console.log(`Test Results: ${passed} PASSED | ${failed} FAILED`);
  console.log('======================================================\n');

  if (failed > 0) {
    process.exit(1);
  }
};

runTests().catch((err) => {
  console.error('Test run error:', err);
  process.exit(1);
});
