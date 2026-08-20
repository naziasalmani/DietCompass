const path = require('path');
const fs = require('fs');
const { calculatePersonalizedCompatibility } = require('./geminiService');

// Load authentic food catalog
let foodCatalog = [];
try {
  const catalogPath = path.join(__dirname, '../data/foodCatalog.json');
  if (fs.existsSync(catalogPath)) {
    foodCatalog = JSON.parse(fs.readFileSync(catalogPath, 'utf8'));
  }
} catch (e) {
  console.warn('[RecommendationService] Could not load foodCatalog.json:', e.message);
  foodCatalog = [];
}

/**
 * Detect product category based on name, brand, ingredients, or category tag
 */
const detectCategory = (product) => {
  if (product.category && typeof product.category === 'string' && product.category.trim().length > 0) {
    return product.category.toLowerCase().trim();
  }

  const text = `${product.name || ''} ${product.brand || ''} ${product.ingredients || ''}`.toLowerCase();

  if (text.match(/cereal|oat|muesli|granola|flake|cheerio|loops|bran/)) return 'cereal';
  if (text.match(/drink|juice|soda|cola|beverage|tea|coffee|water|frooti|thums up|sprite|pepsi|coke|fanta|maaza|slice/)) return 'beverage';
  if (text.match(/protein bar|snack bar|energy bar|\bbar\b|larabar|rxbar|kind bar|snickers/)) return 'snack_bar';
  if (text.match(/milk|yogurt|curd|cheese|dahi|almond milk|oat milk|oatmilk|greek yogurt/)) return 'dairy_milk';
  if (text.match(/bread|toast|bun|pita|bagel|ezekiel|multigrain/)) return 'bread';
  if (text.match(/noodle|pasta|spaghetti|macaroni|rotini|penne|ramen|maggi|chowmein/)) return 'noodle_pasta';
  if (text.match(/biscuit|cookie|cracker|chips|crisps|parle|kurkure|namkeen|wafer/)) return 'snack_biscuit';
  if (text.match(/ketchup|sauce|spread|mayo|dip|mustard|chutney/)) return 'sauce_spread';

  return 'general';
};

/**
 * Compute factual nutrient comparison between scanned and candidate product
 */
const computeNutritionComparison = (scanned, candidate, userGoals = []) => {
  const getNum = (v) => (typeof v === 'number' && !isNaN(v) ? v : 0);

  const scanSugar = getNum(scanned.nutrition?.sugar ?? scanned.sugar);
  const candSugar = getNum(candidate.nutrition?.sugar ?? candidate.sugar);
  const sugarDiff = Math.round((candSugar - scanSugar) * 10) / 10;

  const scanProtein = getNum(scanned.nutrition?.protein ?? scanned.protein);
  const candProtein = getNum(candidate.nutrition?.protein ?? candidate.protein);
  const proteinDiff = Math.round((candProtein - scanProtein) * 10) / 10;

  const scanFiber = getNum(scanned.nutrition?.fiber ?? scanned.fiber);
  const candFiber = getNum(candidate.nutrition?.fiber ?? candidate.fiber);
  const fiberDiff = Math.round((candFiber - scanFiber) * 10) / 10;

  const scanCal = getNum(scanned.nutrition?.calories ?? scanned.calories);
  const candCal = getNum(candidate.nutrition?.calories ?? candidate.calories);
  const calorieDiff = Math.round(candCal - scanCal);

  const scanSodium = getNum(scanned.nutrition?.sodium ?? scanned.sodium);
  const candSodium = getNum(candidate.nutrition?.sodium ?? candidate.sodium);
  const sodiumDiff = Math.round(candSodium - scanSodium);

  const highlights = [];
  if (sugarDiff <= -3) highlights.push(`${Math.abs(sugarDiff)}g less sugar`);
  if (proteinDiff >= 2) highlights.push(`${proteinDiff}g more protein`);
  if (fiberDiff >= 2) highlights.push(`${fiberDiff}g more fiber`);
  if (calorieDiff <= -30) highlights.push(`${Math.abs(calorieDiff)} fewer kcal`);
  if (sodiumDiff <= -100) highlights.push(`${Math.abs(sodiumDiff)}mg less sodium`);

  // Determine top differentiator
  let differentiator = 'Healthier Profile';
  if (sugarDiff <= -4) differentiator = `Lower Sugar (-${Math.abs(sugarDiff).toFixed(0)}g)`;
  else if (proteinDiff >= 4) differentiator = `Higher Protein (+${proteinDiff.toFixed(0)}g)`;
  else if (fiberDiff >= 3) differentiator = `Higher Fiber (+${fiberDiff.toFixed(0)}g)`;
  else if (calorieDiff <= -50) differentiator = `Lower Calories (-${Math.abs(calorieDiff)} kcal)`;
  else if (sodiumDiff <= -150) differentiator = `Lower Sodium (-${Math.abs(sodiumDiff)}mg)`;

  // Generate personalized match reason
  const goalsLower = userGoals.map((g) => g.toLowerCase());
  let matchReason = `Better nutritional alignment and higher DietCompass compatibility score.`;

  if (goalsLower.some((g) => g.includes('sugar') || g.includes('diabet')) && sugarDiff < 0) {
    matchReason = `Contains ${Math.abs(sugarDiff)}g less sugar, better supporting blood glucose control and your low-sugar goal.`;
  } else if (goalsLower.some((g) => g.includes('muscle') || g.includes('protein')) && proteinDiff > 0) {
    matchReason = `Provides ${proteinDiff}g more protein per serving to support muscle synthesis and recovery.`;
  } else if (goalsLower.some((g) => g.includes('blood pressure') || g.includes('hypertension') || g.includes('heart')) && sodiumDiff < 0) {
    matchReason = `Contains ${Math.abs(sodiumDiff)}mg less sodium, aligning with cardiovascular health targets.`;
  } else if (goalsLower.some((g) => g.includes('weight')) && (calorieDiff < 0 || sugarDiff < 0)) {
    matchReason = `Lower calorie density and ${Math.abs(sugarDiff)}g less sugar to support your Weight Loss target.`;
  } else if (highlights.length > 0) {
    matchReason = `${highlights.join(', ')} compared to the scanned product.`;
  }

  return {
    sugarDiff,
    proteinDiff,
    fiberDiff,
    calorieDiff,
    sodiumDiff,
    highlights: highlights.length > 0 ? highlights : ['Balanced nutrient profile'],
    differentiator,
    matchReason,
  };
};

/**
 * Get personalized similar product recommendations
 */
const getPersonalizedRecommendations = async ({
  scannedProduct,
  candidates = [],
  userProfile,
  personalization,
  maxResults = 3,
}) => {
  if (!scannedProduct || (!scannedProduct.name && !scannedProduct.barcode && !scannedProduct.ingredients)) {
    throw new Error('Valid scanned product is required to generate recommendations.');
  }

  const userDiet = personalization?.dietType || userProfile?.dietType || 'Omnivore';
  const userAllergies = personalization?.allergies || userProfile?.allergies || [];
  const userGoals = personalization?.goals || [];

  // 1. Calculate scanned product compatibility score
  const scannedCompatibility = calculatePersonalizedCompatibility({
    product: scannedProduct,
    userProfile,
    personalization,
  });

  // 2. Identify category
  const scannedCategory = detectCategory(scannedProduct);

  // 3. Pool candidates: Combine external candidate products with authentic food catalog
  const rawPool = [...candidates, ...foodCatalog];

  // 4. Deduplicate and filter out the scanned product itself
  const scannedBarcode = (scannedProduct.barcode || '').trim();
  const scannedName = (scannedProduct.name || '').toLowerCase().trim();

  const seenKeys = new Set();
  const filteredCandidates = [];

  for (const item of rawPool) {
    const itemBarcode = (item.barcode || '').trim();
    const itemName = (item.name || '').toLowerCase().trim();

    // Skip scanned product
    if (scannedBarcode && itemBarcode && scannedBarcode === itemBarcode) continue;
    if (scannedName && itemName && scannedName === itemName) continue;

    // Deduplicate within candidate list
    const key = itemBarcode || itemName;
    if (seenKeys.has(key)) continue;
    seenKeys.add(key);

    filteredCandidates.push(item);
  }

  // 5. Match by category where available
  let categoryCandidates = filteredCandidates.filter(
    (item) => detectCategory(item) === scannedCategory
  );

  if (categoryCandidates.length === 0) {
    categoryCandidates = filteredCandidates;
  }

  // 6. Safety & Allergen Filter + Compatibility Engine evaluation
  const scoredCandidates = [];

  for (const candidate of categoryCandidates) {
    // Run existing Phase 6B deterministic compatibility engine
    const comp = calculatePersonalizedCompatibility({
      product: candidate,
      userProfile,
      personalization,
    });

    // Safety rule: If allergen conflict or dietary restriction conflict exists, EXCLUDE
    if (comp.allergyAlerts.length > 0) continue;
    if (comp.dietaryAlerts.length > 0) continue;
    if (!comp.isSuitable) continue;
    if (comp.score < 50) continue; // Must be at least moderate/good match

    const comparison = computeNutritionComparison(scannedProduct, candidate, userGoals);

    scoredCandidates.push({
      product: {
        barcode: candidate.barcode || '',
        name: candidate.name || 'Alternative Product',
        brand: candidate.brand || '',
        category: detectCategory(candidate),
        imageUrl: candidate.imageUrl || '',
        ingredients: candidate.ingredients || '',
        allergens: candidate.allergens || [],
        nutrition: {
          calories: candidate.calories ?? candidate.nutrition?.calories ?? null,
          protein: candidate.protein ?? candidate.nutrition?.protein ?? null,
          carbohydrates: candidate.carbohydrates ?? candidate.nutrition?.carbohydrates ?? null,
          fat: candidate.fat ?? candidate.nutrition?.fat ?? null,
          fiber: candidate.fiber ?? candidate.nutrition?.fiber ?? null,
          sugar: candidate.sugar ?? candidate.nutrition?.sugar ?? null,
          sodium: candidate.sodium ?? candidate.nutrition?.sodium ?? null,
        },
      },
      compatibility: comp,
      matchReason: comparison.matchReason,
      differentiator: comparison.differentiator,
      nutritionComparison: comparison,
    });
  }

  // 7. Sort by compatibility score descending
  scoredCandidates.sort((a, b) => b.compatibility.score - a.compatibility.score);

  // 8. Select top results
  const topRecommendations = scoredCandidates.slice(0, maxResults);

  const summary = topRecommendations.length > 0
    ? `Found ${topRecommendations.length} healthier alternatives aligned with your ${userDiet} diet and personal goals.`
    : "Couldn't find a suitable alternative right now.";

  return {
    scannedProduct: {
      name: scannedProduct.name || 'Scanned Food',
      barcode: scannedProduct.barcode || '',
      category: scannedCategory,
      compatibilityScore: scannedCompatibility.score,
      status: scannedCompatibility.status,
    },
    recommendations: topRecommendations,
    summary,
  };
};

module.exports = {
  detectCategory,
  computeNutritionComparison,
  getPersonalizedRecommendations,
};
