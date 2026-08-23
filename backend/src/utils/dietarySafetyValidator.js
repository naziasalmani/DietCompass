/**
 * DietCompass — Backend Dietary Safety Validator
 * Enforces hard dietary constraints and allergy checks on recipes from Spoonacular, Edamam, or AI
 */

const MEAT_PATTERNS = [
  /\b(beef|steak|brisket|veal|ground beef|roast beef|ribeye|sirloin|tenderloin|corned beef)\b/i,
  /\b(pork|bacon|ham|prosciutto|pancetta|pork belly|pork chop|lard|pepperoni|salami|chorizo)\b/i,
  /\b(chicken|poultry|chicken breast|chicken thigh|chicken wing|turkey|duck|goose|quail)\b/i,
  /\b(lamb|mutton|goat meat|goat)\b/i,
  /\b(sausage|hot dog|frankfurter|bratwurst|meatball|meatloaf|gelatin|animal rennet|meat)\b/i,
  /\b(beef broth|chicken broth|bone broth|beef stock|chicken stock|pork stock|fish stock)\b/i,
  /\b(fish sauce|oyster sauce|worcestershire sauce)\b/i,
];

const SEAFOOD_PATTERNS = [
  /\b(fish|salmon|tuna|cod|tilapia|trout|mackerel|sardine|sardines|anchovy|anchovies|halibut|snapper|sea bass|swordfish)\b/i,
  /\b(seafood|shrimp|shrimps|prawn|prawns|crab|crabs|lobster|lobsters|crayfish|crawfish)\b/i,
  /\b(oyster|oysters|clam|clams|mussel|mussels|scallop|scallops|squid|octopus|calamari)\b/i,
  /\b(caviar|roe|surimi)\b/i,
];

const NON_VEGAN_PATTERNS = [
  /\b(egg|eggs|egg white|egg whites|egg yolk|egg yolks|mayonnaise|mayo|albumin)\b/i,
  /\b(cow milk|whole milk|skim milk|heavy cream|sour cream|whipped cream|butter|ghee|cheese|cheddar|mozzarella|parmesan|paneer|curd|yogurt|whey|casein|caseinate|lactose)\b/i,
  /\b(honey|beeswax|royal jelly)\b/i,
];

const SAFE_EXCEPTIONS = [
  'chickpea', 'chickpeas', 'eggplant', 'eggplants', 'cocoa butter', 'cacao butter',
  'shea butter', 'peanut butter', 'almond butter', 'cashew butter', 'apple butter',
  'cookie butter', 'coconut milk', 'almond milk', 'oat milk', 'soy milk',
  'cashew milk', 'rice milk', 'plant milk', 'coconut cream', 'vegan cheese',
  'vegan butter', 'vegan mayo', 'tofu', 'tempeh', 'seitan', 'jackfruit',
  'passionfruit', 'grapefruit', 'dragonfruit', 'butternut squash', 'meatless',
  'plant-based'
];

/**
 * Validates a normalized recipe object against user dietary preferences, allergies, and safety criteria
 */
const validateRecipeSafety = (recipe, userProfile, personalization) => {
  if (!recipe) {
    return { isCompatible: false, rejectionReason: 'Recipe is empty or null' };
  }

  // 1. Image Validation
  const image = recipe.image || recipe.imageAsset || recipe.sourceImageUrl || '';
  if (!image || typeof image !== 'string' || (!image.startsWith('http://') && !image.startsWith('https://') && !image.startsWith('assets/'))) {
    return { isCompatible: false, rejectionReason: 'Recipe is missing a valid image URL' };
  }

  // 2. Identity Validation
  const id = recipe.id || recipe.sourceRecipeId;
  if (!id || (typeof id === 'string' && id.trim().length === 0)) {
    return { isCompatible: false, rejectionReason: 'Recipe is missing stable identity ID' };
  }

  const dietType = (personalization?.dietType || userProfile?.dietType || 'Vegetarian').toLowerCase().trim();
  const allergies = (personalization?.allergies || userProfile?.allergies || []).map((a) => a.toLowerCase().trim());
  const dislikedFoods = (personalization?.dislikedFoods || []).map((d) => d.toLowerCase().trim());

  // Build corpus to check
  const title = (recipe.title || '').toLowerCase();
  const summary = (recipe.summary || recipe.description || '').toLowerCase();
  const ings = (recipe.ingredients || recipe.extendedIngredients || recipe.ingredientLines || [])
    .map((i) => (typeof i === 'string' ? i : `${i.amount || ''} ${i.name || i.original || i.text || ''}`))
    .join(' ')
    .toLowerCase();
  const instructions = (Array.isArray(recipe.instructions) ? recipe.instructions.join(' ') : (recipe.instructions || '')).toLowerCase();

  const rawText = `${title} ${summary} ${ings} ${instructions}`;

  // Sanitize safe exceptions
  let sanitizedText = rawText;
  for (const safe of SAFE_EXCEPTIONS) {
    sanitizedText = sanitizedText.split(safe).join(' ');
  }

  // 3. Strict Allergy Validation
  for (const allergy of allergies) {
    if (!allergy) continue;
    if (allergy.includes('peanut') && (rawText.includes('peanut') || rawText.includes('groundnut'))) {
      return { isCompatible: false, rejectionReason: `Contains Peanut (${allergy} allergy)` };
    }
    if ((allergy.includes('tree nut') || allergy.includes('nut')) && !allergy.includes('peanut') && !allergy.includes('coconut')) {
      if (/\b(almond|walnut|cashew|pecan|pistachio|hazelnut|macadamia|brazil nut|pine nut)\b/i.test(rawText)) {
        return { isCompatible: false, rejectionReason: `Contains Tree Nut (${allergy} allergy)` };
      }
    }
    if (allergy.includes('milk') || allergy.includes('dairy') || allergy.includes('lactose')) {
      let nonDairyCleaned = rawText;
      for (const plant of ['coconut milk', 'almond milk', 'oat milk', 'soy milk', 'cashew milk', 'rice milk', 'plant milk', 'peanut butter', 'almond butter', 'cashew butter', 'cocoa butter', 'cacao butter', 'shea butter', 'vegan butter', 'vegan cheese']) {
        nonDairyCleaned = nonDairyCleaned.split(plant).join(' ');
      }
      if (/\b(milk|dairy|cream|butter|ghee|cheese|paneer|curd|yogurt|whey|casein|caseinate|lactose)\b/i.test(nonDairyCleaned)) {
        return { isCompatible: false, rejectionReason: `Contains Dairy/Milk (${allergy} allergy)` };
      }
    }
    if (allergy.includes('egg')) {
      let nonEggCleaned = rawText.split('eggplant').join(' ').split('eggplants').join(' ');
      if (/\b(egg|eggs|egg white|egg whites|egg yolk|egg yolks|mayonnaise|mayo|albumin)\b/i.test(nonEggCleaned)) {
        return { isCompatible: false, rejectionReason: `Contains Egg (${allergy} allergy)` };
      }
    }
    if (allergy.includes('gluten') || allergy.includes('wheat')) {
      if (/\b(wheat|barley|rye|gluten|semolina|spelt|all-purpose flour|wheat flour)\b/i.test(rawText)) {
        return { isCompatible: false, rejectionReason: `Contains Gluten/Wheat (${allergy} allergy)` };
      }
    }
    if (allergy.includes('soy')) {
      if (/\b(soy|soya|soybean|soybeans|tofu|tempeh|edamame|soy sauce|soya sauce)\b/i.test(rawText)) {
        return { isCompatible: false, rejectionReason: `Contains Soy (${allergy} allergy)` };
      }
    }
    if (allergy.includes('seafood') || allergy.includes('shellfish') || allergy.includes('fish')) {
      for (const p of SEAFOOD_PATTERNS) {
        if (p.test(rawText)) {
          return { isCompatible: false, rejectionReason: `Contains Seafood/Fish (${allergy} allergy)` };
        }
      }
    }
    if (allergy.includes('sesame') && rawText.includes('sesame')) {
      return { isCompatible: false, rejectionReason: `Contains Sesame (${allergy} allergy)` };
    }
  }

  // 4. Strict Dietary Constraints
  const isVegetarian = dietType.includes('vegetarian') && !dietType.includes('non');
  const isVegan = dietType.includes('vegan');
  const isPescatarian = dietType.includes('pescatarian') || dietType.includes('pescetarian');

  if (isVegetarian || isVegan) {
    for (const p of MEAT_PATTERNS) {
      const match = p.exec(sanitizedText);
      if (match) {
        return { isCompatible: false, rejectionReason: `Contains ${match[0]}, which violates ${dietType} diet` };
      }
    }
    for (const p of SEAFOOD_PATTERNS) {
      const match = p.exec(sanitizedText);
      if (match) {
        return { isCompatible: false, rejectionReason: `Contains ${match[0]}, which violates ${dietType} diet` };
      }
    }
    if (isVegan) {
      for (const p of NON_VEGAN_PATTERNS) {
        const match = p.exec(sanitizedText);
        if (match) {
          return { isCompatible: false, rejectionReason: `Contains ${match[0]}, which violates vegan diet` };
        }
      }
    }
  } else if (isPescatarian) {
    for (const p of MEAT_PATTERNS) {
      const match = p.exec(sanitizedText);
      if (match) {
        return { isCompatible: false, rejectionReason: `Contains ${match[0]}, which violates pescatarian diet` };
      }
    }
  }

  // 5. Disliked Foods Validation
  for (const disliked of dislikedFoods) {
    if (disliked && rawText.includes(disliked)) {
      return { isCompatible: false, rejectionReason: `Contains disliked food: ${disliked}` };
    }
  }

  return { isCompatible: true };
};

module.exports = {
  validateRecipeSafety,
  MEAT_PATTERNS,
  SEAFOOD_PATTERNS,
  NON_VEGAN_PATTERNS,
  SAFE_EXCEPTIONS,
};
