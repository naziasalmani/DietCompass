const geminiConfig = require('../config/gemini');

// Known hidden sugar aliases
const HIDDEN_SUGAR_LIST = [
  { name: 'maltodextrin', risk: 'High Glycemic Index (GI 110+), causes rapid blood sugar spikes higher than table sugar.' },
  { name: 'high fructose corn syrup', risk: 'Associated with fatty liver disease, insulin resistance, and metabolic syndrome.' },
  { name: 'invert sugar', risk: 'Concentrated glucose-fructose mixture disguised under industrial naming.' },
  { name: 'dextrose', risk: 'Simple form of glucose quickly absorbed into bloodstream.' },
  { name: 'corn syrup solids', risk: 'Dehydrated corn syrup with concentrated sugar content.' },
  { name: 'evaporated cane juice', risk: 'Marketing term for unrefined sugar, chemically almost identical to white sugar.' },
  { name: 'fruit juice concentrate', risk: 'Stripped of fruit fiber, acting as pure liquid fructose and sugar.' },
  { name: 'barley malt', risk: 'Maltose-rich sweetener with very high glycemic response.' },
  { name: 'rice syrup', risk: 'High glucose syrup with a high glycemic index.' },
  { name: 'agave nectar', risk: 'Contains up to 85% pure fructose, which metabolizes primarily in the liver.' },
  { name: 'maltose', risk: 'Disaccharide composed of two glucose units with rapid digestion.' },
  { name: 'sucrose', risk: 'Standard table sugar often hidden in savory foods.' },
  { name: 'dextrin', risk: 'Starch derivative that rapidly converts to glucose during digestion.' },
  { name: 'caramel', risk: 'Burned sugar used for color and flavor enhancement.' },
  { name: 'isoglucose', risk: 'Alternative European term for high fructose corn syrup.' },
];

// Known controversial or ultra-processed additives
const HARMFUL_ADDITIVES_LIST = [
  { name: 'bha', fullName: 'Butylated Hydroxyanisole (BHA)', concern: 'Synthetic preservative classified as a potential endocrine disruptor.' },
  { name: 'bht', fullName: 'Butylated Hydroxytoluene (BHT)', concern: 'Chemical antioxidant with suspected respiratory and cellular toxicity in high doses.' },
  { name: 'potassium bromate', fullName: 'Potassium Bromate', concern: 'Flour improver banned in several countries for potential carcinogenicity.' },
  { name: 'titanium dioxide', fullName: 'Titanium Dioxide (E171)', concern: 'Whitening agent banned in the EU due to nanoparticle genotoxicity concerns.' },
  { name: 'msg', fullName: 'Monosodium Glutamate (MSG)', concern: 'Excitotoxin flavor enhancer that can trigger headaches and sensitivity in vulnerable individuals.' },
  { name: 'sodium nitrite', fullName: 'Sodium Nitrite / Nitrate', concern: 'Curing agent that forms carcinogenic nitrosamines when heated with meat proteins.' },
  { name: 'red 40', fullName: 'Allura Red AC (Red 40)', concern: 'Artificial azo dye linked to hyperactivity in sensitive children.' },
  { name: 'yellow 5', fullName: 'Tartrazine (Yellow 5)', concern: 'Artificial synthetic dye known to trigger allergic and asthmatic responses.' },
  { name: 'yellow 6', fullName: 'Sunset Yellow FCF (Yellow 6)', concern: 'Synthetic food coloring associated with allergic reactions.' },
  { name: 'aspartame', fullName: 'Aspartame', concern: 'Artificial sweetener classified by WHO/IARC as possibly carcinogenic (Group 2B).' },
  { name: 'acesulfame potassium', fullName: 'Acesulfame Potassium (Ace-K)', concern: 'Artificial sweetener often paired with sucralose, subject to ongoing metabolic research.' },
  { name: 'carrageenan', fullName: 'Degraded Carrageenan (E407)', concern: 'Thickener extracted from seaweed, associated with gastrointestinal inflammation.' },
];

/**
 * Call Gemini REST API with prompt and system instructions
 */
const callGeminiAPI = async (prompt, systemInstruction = '', jsonMode = false) => {
  if (!geminiConfig.apiKey) {
    return null;
  }

  const endpoint = `${geminiConfig.baseUrl}/${geminiConfig.model}:generateContent?key=${geminiConfig.apiKey}`;

  const requestBody = {
    contents: [
      {
        role: 'user',
        parts: [{ text: prompt }],
      },
    ],
    generationConfig: {
      temperature: 0.2,
      maxOutputTokens: 2048,
      ...(jsonMode && { responseMimeType: 'application/json' }),
    },
  };

  if (systemInstruction) {
    requestBody.systemInstruction = {
      parts: [{ text: systemInstruction }],
    };
  }

  try {
    const response = await fetch(endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(requestBody),
    });

    if (!response.ok) {
      const errBody = await response.text();
      console.warn(`[Gemini API Warning] HTTP ${response.status}: ${errBody}`);
      return null;
    }

    const data = await response.json();
    const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
    return text || null;
  } catch (error) {
    console.warn(`[Gemini API Error] ${error.message}`);
    return null;
  }
};

/**
 * Rule-based fallback analyzer that inspects factual product data
 */
const fallbackProductAnalysis = ({ product, userProfile, personalization }) => {
  const ingredientsText = (product.ingredients || '').toLowerCase();
  const claims = Array.isArray(product.claims) ? product.claims : [];
  const sugarGrams = Number(product.nutrition?.sugar ?? product.sugar ?? 0);
  const sodiumMg = Number(product.nutrition?.sodium ?? product.sodium ?? 0);
  const proteinGrams = Number(product.nutrition?.protein ?? product.protein ?? 0);
  const fiberGrams = Number(product.nutrition?.fiber ?? product.fiber ?? 0);

  // 1. Detect disguised sugars
  const detectedSugars = [];
  for (const sugar of HIDDEN_SUGAR_LIST) {
    if (ingredientsText.includes(sugar.name)) {
      detectedSugars.push({
        name: sugar.name.charAt(0).toUpperCase() + sugar.name.slice(1),
        description: sugar.risk,
      });
    }
  }

  // 2. Detect harmful additives
  const detectedAdditives = [];
  for (const additive of HARMFUL_ADDITIVES_LIST) {
    if (ingredientsText.includes(additive.name) || ingredientsText.includes(additive.fullName.toLowerCase())) {
      detectedAdditives.push({
        name: additive.fullName,
        concern: additive.concern,
      });
    }
  }

  // 3. Verify marketing claims against facts
  const claimVerifications = [];
  for (const claim of claims) {
    const lowerClaim = claim.toLowerCase();
    if (lowerClaim.includes('zero sugar') || lowerClaim.includes('no sugar') || lowerClaim.includes('sugar free')) {
      if (detectedSugars.length > 0 || sugarGrams > 1) {
        claimVerifications.push({
          claim,
          status: 'Misleading',
          explanation: `Claims "${claim}" but contains ${detectedSugars.map((s) => s.name).join(', ')} or ${sugarGrams}g measurable sugars.`,
        });
      } else {
        claimVerifications.push({
          claim,
          status: 'Verified',
          explanation: 'Product does not contain significant sugars or hidden syrups.',
        });
      }
    } else if (lowerClaim.includes('low sodium')) {
      if (sodiumMg > 140) {
        claimVerifications.push({
          claim,
          status: 'Misleading',
          explanation: `Contains ${sodiumMg}mg sodium per 100g, exceeding the standard low-sodium threshold of 140mg.`,
        });
      } else {
        claimVerifications.push({
          claim,
          status: 'Verified',
          explanation: `Contains ${sodiumMg}mg sodium, compliant with low-sodium guidelines.`,
        });
      }
    } else if (lowerClaim.includes('high protein')) {
      if (proteinGrams < 10) {
        claimVerifications.push({
          claim,
          status: 'Questionable',
          explanation: `Only provides ${proteinGrams}g protein per 100g. Standard high-protein threshold is at least 10-15g.`,
        });
      } else {
        claimVerifications.push({
          claim,
          status: 'Verified',
          explanation: `Provides ${proteinGrams}g protein per 100g.`,
        });
      }
    } else if (lowerClaim.includes('natural') || lowerClaim.includes('all natural')) {
      if (detectedAdditives.length > 0) {
        claimVerifications.push({
          claim,
          status: 'Misleading',
          explanation: `Claims natural ingredients but contains synthetic/ultra-processed additives: ${detectedAdditives.map((a) => a.name).join(', ')}.`,
        });
      } else {
        claimVerifications.push({
          claim,
          status: 'Verified',
          explanation: 'No synthetic additives detected in the listed ingredients.',
        });
      }
    }
  }

  // 4. Calculate DietCompass Health Score (0 - 100)
  let score = 70;
  if (proteinGrams >= 8) score += 10;
  if (fiberGrams >= 5) score += 10;
  if (sugarGrams > 15) score -= 18;
  else if (sugarGrams > 8) score -= 8;
  if (sodiumMg > 600) score -= 15;
  else if (sodiumMg > 300) score -= 6;
  score -= detectedSugars.length * 6;
  score -= detectedAdditives.length * 8;
  score = Math.max(10, Math.min(99, Math.round(score)));

  // 5. Check user-specific allergies & conditions
  const userAllergies = personalization?.allergies || userProfile?.allergies || [];
  const allergenWarnings = [];
  for (const allergen of userAllergies) {
    if (ingredientsText.includes(allergen.toLowerCase())) {
      allergenWarnings.push(`Contains your configured allergen: ${allergen}`);
    }
  }

  // Dietary compatibility
  const userDiet = personalization?.dietType || userProfile?.dietType || 'All';
  let isSuitable = allergenWarnings.length === 0;
  if (userDiet.toLowerCase() === 'vegan' && (ingredientsText.includes('milk') || ingredientsText.includes('whey') || ingredientsText.includes('honey') || ingredientsText.includes('gelatin'))) {
    isSuitable = false;
  }
  if (userDiet.toLowerCase() === 'vegetarian' && (ingredientsText.includes('gelatin') || ingredientsText.includes('beef') || ingredientsText.includes('chicken') || ingredientsText.includes('fish'))) {
    isSuitable = false;
  }

  const pros = [];
  const cons = [];
  if (proteinGrams >= 6) pros.push(`Good protein content (${proteinGrams}g/100g)`);
  if (fiberGrams >= 3) pros.push(`Contains beneficial dietary fiber (${fiberGrams}g/100g)`);
  if (sugarGrams < 5 && detectedSugars.length === 0) pros.push('Low in sugar with no hidden sweetening agents');
  if (detectedAdditives.length === 0) pros.push('Clean label with no high-concern preservatives or artificial dyes');

  if (detectedSugars.length > 0) cons.push(`Contains ${detectedSugars.length} disguised sugar sources`);
  if (sugarGrams > 12) cons.push(`High in sugar (${sugarGrams}g per 100g)`);
  if (sodiumMg > 500) cons.push(`Elevated sodium content (${sodiumMg}mg per 100g)`);
  if (detectedAdditives.length > 0) cons.push(`Contains ultra-processed additives (${detectedAdditives.map((a) => a.name).join(', ')})`);

  const aiAnalysisObj = {
    healthScore: score,
    summary: `${product.name || 'This product'} receives a DietCompass Score of ${score}/100 based on its nutrient balance and ingredient quality.`,
    isSuitable,
    disguisedSugars: detectedSugars,
    harmfulAdditives: detectedAdditives,
    claimVerifications,
    allergenWarnings,
    pros: pros.length > 0 ? pros : ['Standard nutrient composition'],
    cons: cons.length > 0 ? cons : ['No significant negative flags detected'],
    healthierAlternatives: [
      'Unsweetened whole-grain oats',
      'Natural roasted nuts and seeds',
      'Whole-food unsweetened Greek yogurt',
    ],
    aiInterpretationNote: 'DietCompass AI analysis interprets actual factual ingredients against nutritional guidelines. Gemini does not invent nutritional values.',
  };

  const compatibility = calculatePersonalizedCompatibility({
    product,
    userProfile,
    personalization,
    aiAnalysis: aiAnalysisObj,
  });

  return {
    factualData: {
      name: product.name || 'Product',
      brand: product.brand || '',
      barcode: product.barcode || '',
      ingredients: product.ingredients || 'Ingredients not available',
      nutrition: {
        calories: product.calories ?? product.nutrition?.calories ?? null,
        protein: proteinGrams,
        carbohydrates: product.carbohydrates ?? product.nutrition?.carbohydrates ?? null,
        fat: product.fat ?? product.nutrition?.fat ?? null,
        fiber: fiberGrams,
        sugar: sugarGrams,
        sodium: sodiumMg,
      },
    },
    aiAnalysis: aiAnalysisObj,
    compatibility,
  };
};

/**
 * Deterministic Personalized Product Compatibility Score Calculator
 * Computes a customized 0-100 score based on user's cloud profile & product factual data.
 */
const calculatePersonalizedCompatibility = ({ product, userProfile, personalization, aiAnalysis = {} }) => {
  const ingredientsText = (product.ingredients || '').toLowerCase();
  const sugarGrams = Number(product.nutrition?.sugar ?? product.sugar ?? 0);
  const sodiumMg = Number(product.nutrition?.sodium ?? product.sodium ?? 0);
  const proteinGrams = Number(product.nutrition?.protein ?? product.protein ?? 0);
  const fiberGrams = Number(product.nutrition?.fiber ?? product.fiber ?? 0);
  const calories = Number(product.nutrition?.calories ?? product.calories ?? 0);
  const fatGrams = Number(product.nutrition?.fat ?? product.fat ?? 0);
  const carbsGrams = Number(product.nutrition?.carbohydrates ?? product.carbohydrates ?? 0);

  const userDiet = (personalization?.dietType || userProfile?.dietType || 'Omnivore').trim();
  const userAllergies = personalization?.allergies || userProfile?.allergies || [];
  const userGoals = personalization?.goals || [];
  const userConditions = personalization?.healthConditions || [];
  const userFocus = personalization?.nutritionFocus || [];
  const productAlerts = personalization?.productAlerts instanceof Map
    ? Object.fromEntries(personalization.productAlerts)
    : (personalization?.productAlerts || {});

  const positiveFactors = [];
  const concerns = [];
  const allergyAlerts = [];
  const dietaryAlerts = [];

  let score = 75; // Baseline starting score

  // 1. ALLERGEN CHECKS (Critical Priority)
  const ALLERGEN_MAP = {
    peanut: ['peanut', 'arachis'],
    peanuts: ['peanut', 'peanuts', 'arachis'],
    dairy: ['milk', 'dairy', 'whey', 'casein', 'lactose', 'butter', 'cheese', 'cream'],
    milk: ['milk', 'dairy', 'whey', 'casein', 'lactose', 'butter', 'cheese', 'cream'],
    gluten: ['wheat', 'barley', 'rye', 'gluten', 'spelt', 'semolina'],
    wheat: ['wheat', 'flour', 'semolina', 'spelt'],
    soy: ['soy', 'soya', 'soybean', 'edamame', 'tofu'],
    soya: ['soy', 'soya', 'soybean', 'edamame', 'tofu'],
    egg: ['egg', 'eggs', 'albumin', 'egg white', 'egg yolk'],
    eggs: ['egg', 'eggs', 'albumin', 'egg white', 'egg yolk'],
    'tree nuts': ['almond', 'cashew', 'walnut', 'pecan', 'pistachio', 'hazelnut', 'macadamia'],
    nuts: ['peanut', 'peanuts', 'almond', 'cashew', 'walnut', 'pecan', 'pistachio', 'hazelnut'],
    fish: ['fish', 'salmon', 'tuna', 'cod', 'anchovy', 'tilapia', 'mackerel'],
    shellfish: ['shellfish', 'shrimp', 'crab', 'lobster', 'prawn', 'mussel', 'clam', 'oyster'],
    sesame: ['sesame', 'tahini'],
    mustard: ['mustard'],
    sulfites: ['sulfite', 'sulphite', 'sulfur dioxide'],
  };

  for (const allergen of userAllergies) {
    const lowerAllergen = allergen.toLowerCase().trim();
    const keywords = ALLERGEN_MAP[lowerAllergen] || [lowerAllergen];
    const matchFound = keywords.some((kw) => ingredientsText.includes(kw));

    if (matchFound) {
      allergyAlerts.push(`Contains your configured allergen: ${allergen}`);
      concerns.push(`High Alert: Ingredient matches documented allergy (${allergen}).`);
      score -= 50;
    }
  }

  // 2. DIETARY RESTRICTIONS (Major Priority)
  const lowerDiet = userDiet.toLowerCase();
  const animalKeywords = ['beef', 'chicken', 'pork', 'mutton', 'meat', 'gelatin', 'fish', 'poultry', 'lard', 'tallow', 'collagen'];
  const dairyEggKeywords = ['milk', 'dairy', 'whey', 'casein', 'lactose', 'egg', 'eggs', 'butter', 'honey'];

  if (lowerDiet === 'vegan') {
    const hasAnimal = animalKeywords.some((k) => ingredientsText.includes(k));
    const hasDairyEgg = dairyEggKeywords.some((k) => ingredientsText.includes(k));
    if (hasAnimal || hasDairyEgg) {
      dietaryAlerts.push('Conflicts with your Vegan diet (contains animal or dairy/egg ingredients)');
      concerns.push('Incompatible with Vegan lifestyle.');
      score -= 40;
    } else {
      positiveFactors.push('Fully complies with your Vegan diet');
      score += 8;
    }
  } else if (lowerDiet === 'vegetarian') {
    const hasAnimal = animalKeywords.some((k) => ingredientsText.includes(k));
    if (hasAnimal) {
      dietaryAlerts.push('Conflicts with your Vegetarian diet (contains animal derivatives/gelatin/meat)');
      concerns.push('Incompatible with Vegetarian diet.');
      score -= 40;
    } else {
      positiveFactors.push('Complies with your Vegetarian diet');
      score += 8;
    }
  } else if (lowerDiet === 'pescatarian') {
    const nonFishMeat = ['beef', 'chicken', 'pork', 'mutton', 'meat', 'poultry', 'lard'];
    const hasMeat = nonFishMeat.some((k) => ingredientsText.includes(k));
    if (hasMeat) {
      dietaryAlerts.push('Conflicts with your Pescatarian diet');
      concerns.push('Contains meat products.');
      score -= 35;
    } else {
      positiveFactors.push('Complies with your Pescatarian diet');
      score += 6;
    }
  } else if (lowerDiet.includes('gluten-free') || lowerDiet.includes('celiac')) {
    const hasGluten = ['wheat', 'barley', 'rye', 'gluten', 'spelt', 'semolina'].some((k) => ingredientsText.includes(k));
    if (hasGluten) {
      dietaryAlerts.push('Contains gluten ingredients conflicting with your Gluten-Free diet');
      concerns.push('High risk: contains gluten/wheat.');
      score -= 45;
    } else {
      positiveFactors.push('Gluten-free ingredient composition');
      score += 8;
    }
  } else if (lowerDiet.includes('keto') || lowerDiet.includes('low carb')) {
    if (carbsGrams > 15 || sugarGrams > 4) {
      concerns.push(`High carbohydrate/sugar content (${carbsGrams}g carbs) exceeds Keto limits.`);
      score -= 20;
    } else {
      positiveFactors.push('Low net carbohydrate profile suitable for Keto/Low-Carb');
      score += 10;
    }
  }

  // 3. HEALTH CONDITIONS (High Priority)
  for (const condition of userConditions) {
    const lowerCond = condition.toLowerCase();
    if (lowerCond.includes('diabetes') || lowerCond.includes('pre-diabetes') || lowerCond.includes('blood sugar')) {
      if (sugarGrams > 8 || (aiAnalysis.disguisedSugars && aiAnalysis.disguisedSugars.length > 0)) {
        concerns.push(`Contains ${sugarGrams}g sugar or fast-digesting sweeteners that may impact blood glucose.`);
        score -= 20;
      } else if (sugarGrams <= 3 && fiberGrams >= 3) {
        positiveFactors.push('Low sugar and good fiber support steady blood glucose control.');
        score += 10;
      }
    }
    if (lowerCond.includes('hypertension') || lowerCond.includes('blood pressure') || lowerCond.includes('heart')) {
      if (sodiumMg > 350) {
        concerns.push(`Elevated sodium (${sodiumMg}mg/100g) exceeds targets for blood pressure & heart health.`);
        score -= 18;
      } else if (sodiumMg > 0 && sodiumMg <= 140) {
        positiveFactors.push('Low sodium content supports cardiovascular & blood pressure goals.');
        score += 8;
      }
    }
    if (lowerCond.includes('cholesterol')) {
      if (fatGrams > 15) {
        concerns.push('Higher total fat content may impact lipid management.');
        score -= 12;
      } else if (fiberGrams >= 4) {
        positiveFactors.push('Rich in dietary fiber which aids in cholesterol management.');
        score += 8;
      }
    }
  }

  // 4. USER GOALS & NUTRITION FOCUS
  const combinedGoals = [...userGoals, ...userFocus].map((g) => g.toLowerCase());

  if (combinedGoals.some((g) => g.includes('weight loss') || g.includes('calorie'))) {
    if (calories > 350 || sugarGrams > 15) {
      concerns.push(`Calorie density (${calories || 'high'} kcal) or sugar (${sugarGrams}g) may slow Weight Loss progress.`);
      score -= 12;
    } else if (calories > 0 && calories <= 180 && fiberGrams >= 3) {
      positiveFactors.push('Low calorie density with filling fiber directly supports your Weight Loss goal.');
      score += 10;
    }
  }

  if (combinedGoals.some((g) => g.includes('muscle') || g.includes('high protein'))) {
    if (proteinGrams >= 10) {
      positiveFactors.push(`High protein content (${proteinGrams}g/100g) supports muscle synthesis and recovery.`);
      score += 14;
    } else if (proteinGrams > 0 && proteinGrams < 4) {
      concerns.push(`Low in protein (${proteinGrams}g), providing minimal support for muscle growth.`);
      score -= 8;
    }
  }

  if (combinedGoals.some((g) => g.includes('digestion') || g.includes('gut') || g.includes('fiber'))) {
    if (fiberGrams >= 4) {
      positiveFactors.push(`Excellent dietary fiber (${fiberGrams}g/100g) supports digestive regularity and gut microbiome.`);
      score += 12;
    }
    if (aiAnalysis.harmfulAdditives && aiAnalysis.harmfulAdditives.length > 0) {
      concerns.push('Contains additives that may trigger gastrointestinal sensitivity.');
      score -= 10;
    }
  }

  if (combinedGoals.some((g) => g.includes('clean') || g.includes('energy'))) {
    if ((aiAnalysis.disguisedSugars && aiAnalysis.disguisedSugars.length > 0) || (aiAnalysis.harmfulAdditives && aiAnalysis.harmfulAdditives.length > 0)) {
      concerns.push('Contains artificial additives or hidden sugars incompatible with clean eating focus.');
      score -= 10;
    } else if (ingredientsText.length > 0) {
      positiveFactors.push('Clean label with no high-concern synthetic additives detected.');
      score += 8;
    }
  }

  // 5. PRODUCT ALERTS (Step 7)
  if (productAlerts['Warn me about high sugar products'] && sugarGrams > 12) {
    concerns.push(`High sugar alert triggered (${sugarGrams}g sugar per 100g).`);
    score -= 6;
  }
  if (productAlerts['Warn me about high sodium'] && sodiumMg > 400) {
    concerns.push(`High sodium alert triggered (${sodiumMg}mg sodium per 100g).`);
    score -= 6;
  }
  if (productAlerts['Warn me about ultra-processed foods'] && (aiAnalysis.harmfulAdditives?.length > 0 || aiAnalysis.disguisedSugars?.length > 0)) {
    concerns.push('Ultra-processed formulation alert triggered.');
    score -= 6;
  }

  // 6. SCORE BOUNDS & HARD CAPS
  if (allergyAlerts.length > 0) {
    score = Math.min(25, Math.max(5, score));
  } else if (dietaryAlerts.length > 0) {
    score = Math.min(35, Math.max(5, score));
  } else {
    score = Math.min(99, Math.max(10, Math.round(score)));
  }

  // 7. STATUS DETERMINATION
  let status = 'Good Match';
  let recommendation = 'Suitable for your regular diet.';

  if (allergyAlerts.length > 0) {
    status = 'Incompatible / Allergy Risk';
    recommendation = 'Avoid this product due to direct allergen conflict with your profile.';
  } else if (dietaryAlerts.length > 0) {
    status = 'Dietary Incompatibility';
    recommendation = `Not recommended for your ${userDiet} diet.`;
  } else if (score >= 85) {
    status = 'Excellent Match';
    recommendation = 'Great nutritional alignment with your personal profile and dietary goals.';
  } else if (score >= 70) {
    status = 'Good Match';
    recommendation = 'Solid option that generally aligns with your health and dietary preferences.';
  } else if (score >= 50) {
    status = 'Moderate Match';
    recommendation = 'Acceptable in moderation; review highlighted nutrient concerns.';
  } else {
    status = 'Consider Alternatives';
    recommendation = 'Does not align well with your personal nutrition targets. Consider a cleaner alternative.';
  }

  // UI Compatibility Items
  const items = [
    {
      label: 'Diet Alignment',
      rating: dietaryAlerts.length > 0 ? 'Incompatible' : (positiveFactors.some((p) => p.includes(userDiet)) ? 'Excellent' : 'Good'),
      detail: dietaryAlerts.length > 0 ? dietaryAlerts[0] : `Aligned with your ${userDiet} lifestyle`,
    },
    {
      label: 'Allergy Safety',
      rating: allergyAlerts.length > 0 ? 'Allergen Alert' : 'Safe',
      detail: allergyAlerts.length > 0 ? allergyAlerts[0] : (userAllergies.length > 0 ? `Free from ${userAllergies.join(', ')}` : 'No allergen conflicts reported'),
    },
    {
      label: 'Goal Suitability',
      rating: score >= 70 ? 'Good' : 'Consider',
      detail: userGoals.length > 0 ? `Evaluated for ${userGoals.join(', ')}` : 'Evaluated for standard wellness targets',
    },
    {
      label: 'Nutrient Balance',
      rating: sugarGrams <= 6 && sodiumMg <= 250 ? 'Excellent' : (sugarGrams > 12 || sodiumMg > 500 ? 'Consider' : 'Good'),
      detail: `Sugar: ${sugarGrams}g | Sodium: ${sodiumMg}mg | Protein: ${proteinGrams}g | Fiber: ${fiberGrams}g`,
    },
  ];

  const summary = allergyAlerts.length > 0
    ? `⚠️ High Risk: ${allergyAlerts.join('; ')}. Personal compatibility score: ${score}/100.`
    : dietaryAlerts.length > 0
    ? `Diet conflict: ${dietaryAlerts.join('; ')}. Personal compatibility score: ${score}/100.`
    : `${product.name || 'Product'} receives a Personalized Compatibility Score of ${score}/100 based on your ${userDiet} diet and ${userGoals.join(', ') || 'health'} goals.`;

  return {
    score,
    status,
    isSuitable: allergyAlerts.length === 0 && dietaryAlerts.length === 0,
    allergyAlerts,
    dietaryAlerts,
    positiveFactors: positiveFactors.length > 0 ? positiveFactors : ['Standard nutrient composition'],
    concerns: concerns.length > 0 ? concerns : ['No significant personal conflicts detected'],
    summary,
    recommendation,
    items,
  };
};

/**
 * 1. AI Product & Ingredient Intelligence Analysis
 */
const analyzeProductNutrition = async ({ product, userProfile, personalization }) => {
  const fallback = fallbackProductAnalysis({ product, userProfile, personalization });

  if (!geminiConfig.apiKey) {
    return fallback;
  }

  const systemInstruction = `You are DietCompass AI, an advanced Clinical Nutrition & Food Intelligence Expert.
CRITICAL MANDATE:
1. Distinguish strictly between FACTUAL PRODUCT DATA and AI INTERPRETATION.
2. NEVER invent nutrition numbers or ingredients. Use ONLY the supplied factual data.
3. Identify hidden sugars (e.g. maltodextrin, dextrose, syrups, barley malt).
4. Identify harmful or controversial additives (e.g. BHT, BHA, artificial colorings, potassium bromate).
5. Scrutinize and verify any marketing claims (e.g. "Low Sugar", "All Natural", "High Protein") against the actual facts.
6. Return a structured JSON response matching the required schema.`;

  const isLiquid = product.isLiquid || 
    (product.servingSize && /ml|liter|litre|l\b|fl\s*oz/i.test(product.servingSize)) ||
    (product.name && /sprite|coke|coca|pepsi|fanta|soda|drink|juice|beverage|water|milk|tea|coffee/i.test(product.name));
  const basisLabel = product.nutritionBasis || (isLiquid ? 'Per 100 ml' : 'Per 100 g');

  const prompt = `Analyze the following food product:
Product Name: ${product.name}
Brand: ${product.brand || 'Unknown'}
Barcode: ${product.barcode || 'N/A'}
Ingredients: ${product.ingredients || 'None listed'}
Nutrition (${basisLabel}):
- Calories: ${product.calories ?? product.nutrition?.calories ?? 'N/A'} kcal
- Protein: ${product.protein ?? product.nutrition?.protein ?? 'N/A'} g
- Carbohydrates: ${product.carbohydrates ?? product.nutrition?.carbohydrates ?? 'N/A'} g
- Fat: ${product.fat ?? product.nutrition?.fat ?? 'N/A'} g
- Fiber: ${product.fiber ?? product.nutrition?.fiber ?? 'N/A'} g
- Sugar: ${product.sugar ?? product.nutrition?.sugar ?? 'N/A'} g
- Sodium: ${product.sodium ?? product.nutrition?.sodium ?? 'N/A'} mg
Claims to check: ${JSON.stringify(product.claims || [])}

User Context:
Diet Type: ${personalization?.dietType || userProfile?.dietType || 'Omnivore'}
Allergies: ${JSON.stringify(personalization?.allergies || userProfile?.allergies || [])}
Health Goals: ${JSON.stringify(personalization?.goals || [])}
Health Conditions: ${JSON.stringify(personalization?.healthConditions || [])}

Respond with a JSON object:
{
  "healthScore": <integer 0-100>,
  "summary": "<2-sentence comprehensive evaluation>",
  "isSuitable": <boolean>,
  "disguisedSugars": [
    { "name": "<sugar synonym>", "description": "<why it is disguised or health risk>" }
  ],
  "harmfulAdditives": [
    { "name": "<additive name>", "concern": "<scientific concern>" }
  ],
  "claimVerifications": [
    { "claim": "<marketing claim>", "status": "<Verified|Misleading|Questionable>", "explanation": "<explanation based on ingredients and nutrition>" }
  ],
  "allergenWarnings": ["<warnings matching user allergies>"],
  "pros": ["<positive nutritional points>"],
  "cons": ["<concerning nutritional points>"],
  "healthierAlternatives": ["<3 specific healthier alternative whole foods or products>"]
}`;

  try {
    const rawJson = await callGeminiAPI(prompt, systemInstruction, true);
    if (!rawJson) return fallback;

    const parsed = JSON.parse(rawJson);

    const parsedAiAnalysis = {
      healthScore: typeof parsed.healthScore === 'number' ? parsed.healthScore : fallback.aiAnalysis.healthScore,
      summary: parsed.summary || fallback.aiAnalysis.summary,
      isSuitable: typeof parsed.isSuitable === 'boolean' ? parsed.isSuitable : fallback.aiAnalysis.isSuitable,
      disguisedSugars: Array.isArray(parsed.disguisedSugars) ? parsed.disguisedSugars : fallback.aiAnalysis.disguisedSugars,
      harmfulAdditives: Array.isArray(parsed.harmfulAdditives) ? parsed.harmfulAdditives : fallback.aiAnalysis.harmfulAdditives,
      claimVerifications: Array.isArray(parsed.claimVerifications) ? parsed.claimVerifications : fallback.aiAnalysis.claimVerifications,
      allergenWarnings: Array.isArray(parsed.allergenWarnings) ? parsed.allergenWarnings : fallback.aiAnalysis.allergenWarnings,
      pros: Array.isArray(parsed.pros) && parsed.pros.length > 0 ? parsed.pros : fallback.aiAnalysis.pros,
      cons: Array.isArray(parsed.cons) && parsed.cons.length > 0 ? parsed.cons : fallback.aiAnalysis.cons,
      healthierAlternatives: Array.isArray(parsed.healthierAlternatives) && parsed.healthierAlternatives.length > 0
        ? parsed.healthierAlternatives
        : fallback.aiAnalysis.healthierAlternatives,
      aiInterpretationNote: 'DietCompass AI analysis interprets factual ingredients against nutritional guidelines. Gemini does not invent nutritional values.',
    };

    const compatibility = calculatePersonalizedCompatibility({
      product,
      userProfile,
      personalization,
      aiAnalysis: parsedAiAnalysis,
    });

    return {
      factualData: fallback.factualData,
      aiAnalysis: parsedAiAnalysis,
      compatibility,
    };
  } catch (error) {
    console.warn(`[Gemini Parse Error] ${error.message}, using fallback intelligence.`);
    return fallback;
  }
};

/**
 * 2. OCR / Unknown Product Analysis
 */
const analyzeOcrLabel = async ({ ocrText, userProfile, personalization }) => {
  if (!ocrText || typeof ocrText !== 'string' || ocrText.trim().length < 3) {
    throw new Error('OCR text is too short or empty for analysis.');
  }

  const cleanText = ocrText.trim();

  // Basic regex fallback parser
  const extractNutritionValue = (regex) => {
    const match = cleanText.match(regex);
    return match && match[1] ? parseFloat(match[1]) : null;
  };

  const fallbackProduct = {
    name: 'Scanned Food Product',
    brand: 'Label Scan',
    barcode: '',
    ingredients: cleanText,
    nutrition: {
      calories: extractNutritionValue(/(?:calories|energy|kcal)[:\s]*([0-9.]+)/i),
      protein: extractNutritionValue(/(?:protein)[:\s]*([0-9.]+)/i),
      carbohydrates: extractNutritionValue(/(?:carbs|carbohydrates|total carb)[:\s]*([0-9.]+)/i),
      fat: extractNutritionValue(/(?:fat|total fat)[:\s]*([0-9.]+)/i),
      fiber: extractNutritionValue(/(?:fiber|dietary fiber)[:\s]*([0-9.]+)/i),
      sugar: extractNutritionValue(/(?:sugars?|total sugar)[:\s]*([0-9.]+)/i),
      sodium: extractNutritionValue(/(?:sodium|salt)[:\s]*([0-9.]+)/i),
    },
  };

  if (!geminiConfig.apiKey) {
    return fallbackProductAnalysis({ product: fallbackProduct, userProfile, personalization });
  }

  const systemInstruction = `You are DietCompass AI OCR Specialist.
Extract structured product details (product name, brand, ingredients, nutrition panel) from raw label text, then analyze ingredient safety and hidden sugars.
Return a valid JSON object.`;

  const prompt = `Extract product information and analyze this OCR label text:
"""
${cleanText}
"""

User Context:
Diet Type: ${personalization?.dietType || userProfile?.dietType || 'Omnivore'}
Allergies: ${JSON.stringify(personalization?.allergies || userProfile?.allergies || [])}

Respond with JSON:
{
  "product": {
    "name": "<extracted product name>",
    "brand": "<extracted brand>",
    "ingredients": "<clean comma-separated ingredients>",
    "nutrition": {
      "calories": <number or null>,
      "protein": <number or null>,
      "carbohydrates": <number or null>,
      "fat": <number or null>,
      "fiber": <number or null>,
      "sugar": <number or null>,
      "sodium": <number or null>
    }
  },
  "healthScore": <integer 0-100>,
  "summary": "<summary>",
  "isSuitable": <boolean>,
  "disguisedSugars": [{ "name": "<name>", "description": "<risk>" }],
  "harmfulAdditives": [{ "name": "<name>", "concern": "<concern>" }],
  "claimVerifications": [],
  "allergenWarnings": [],
  "pros": ["<pros>"],
  "cons": ["<cons>"],
  "healthierAlternatives": ["<alternatives>"]
}`;

  try {
    const rawJson = await callGeminiAPI(prompt, systemInstruction, true);
    if (!rawJson) {
      return fallbackProductAnalysis({ product: fallbackProduct, userProfile, personalization });
    }

    const parsed = JSON.parse(rawJson);
    const extractedProduct = parsed.product || fallbackProduct;

    const parsedAiAnalysis = {
      healthScore: typeof parsed.healthScore === 'number' ? parsed.healthScore : 70,
      summary: parsed.summary || 'Product analyzed from scanned label.',
      isSuitable: typeof parsed.isSuitable === 'boolean' ? parsed.isSuitable : true,
      disguisedSugars: Array.isArray(parsed.disguisedSugars) ? parsed.disguisedSugars : [],
      harmfulAdditives: Array.isArray(parsed.harmfulAdditives) ? parsed.harmfulAdditives : [],
      claimVerifications: Array.isArray(parsed.claimVerifications) ? parsed.claimVerifications : [],
      allergenWarnings: Array.isArray(parsed.allergenWarnings) ? parsed.allergenWarnings : [],
      pros: Array.isArray(parsed.pros) && parsed.pros.length > 0 ? parsed.pros : ['Extracted from package label'],
      cons: Array.isArray(parsed.cons) && parsed.cons.length > 0 ? parsed.cons : [],
      healthierAlternatives: Array.isArray(parsed.healthierAlternatives) ? parsed.healthierAlternatives : [],
      aiInterpretationNote: 'Extracted from OCR label scan via DietCompass AI.',
    };

    const compatibility = calculatePersonalizedCompatibility({
      product: extractedProduct,
      userProfile,
      personalization,
      aiAnalysis: parsedAiAnalysis,
    });

    return {
      factualData: {
        name: extractedProduct.name || fallbackProduct.name,
        brand: extractedProduct.brand || fallbackProduct.brand,
        barcode: '',
        ingredients: extractedProduct.ingredients || fallbackProduct.ingredients,
        nutrition: extractedProduct.nutrition || fallbackProduct.nutrition,
      },
      aiAnalysis: parsedAiAnalysis,
      compatibility,
    };
  } catch (e) {
    return fallbackProductAnalysis({ product: fallbackProduct, userProfile, personalization });
  }
};

/**
 * Call Gemini REST API for multi-turn chat conversations
 */
const callGeminiChatAPI = async (contents, systemInstruction = '') => {
  if (!geminiConfig.apiKey) {
    return null;
  }

  const endpoint = `${geminiConfig.baseUrl}/${geminiConfig.model}:generateContent?key=${geminiConfig.apiKey}`;

  const requestBody = {
    contents,
    generationConfig: {
      temperature: 0.6,
      maxOutputTokens: 2048,
    },
  };

  if (systemInstruction) {
    requestBody.systemInstruction = {
      parts: [{ text: systemInstruction }],
    };
  }

  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 20000);

    const response = await fetch(endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(requestBody),
      signal: controller.signal,
    });
    clearTimeout(timeoutId);

    if (!response.ok) {
      const errBody = await response.text();
      console.warn(`[Gemini Chat API Warning] HTTP ${response.status}: ${errBody}`);
      return null;
    }

    const data = await response.json();
    const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
    return text ? text.trim() : null;
  } catch (error) {
    console.warn(`[Gemini Chat API Error] ${error.name === 'AbortError' ? 'Gemini API call timed out after 20s' : error.message}`);
    return null;
  }
};

/**
 * Smart query-aware fallback generator when Gemini API is unavailable
 */
const generateCoachFallback = ({ userMessage, userName, dietType, goals, allergies, dislikedFoods, conditions, product, targetCalories }) => {
  const query = (userMessage || '').toLowerCase();

  // If a specific product is provided, ALWAYS ground the response in this product
  if (product && product.name) {
    const prodName = product.name;
    const prodBrand = product.brand || '';
    const calories = product.calories ?? product.nutrition?.calories;
    const protein = product.protein ?? product.nutrition?.protein;
    const carbs = product.carbohydrates ?? product.nutrition?.carbohydrates;
    const fat = product.fat ?? product.nutrition?.fat;
    const sugar = product.sugar ?? product.nutrition?.sugar;
    const fiber = product.fiber ?? product.nutrition?.fiber;
    const sodium = product.sodium ?? product.nutrition?.sodium;
    const score = product.compatibilityScore ?? 51;
    const status = product.compatibilityStatus || (score >= 70 ? 'Good Match' : (score >= 50 ? 'Moderate Match' : 'Consider Alternatives'));
    const concerns = Array.isArray(product.concerns) && product.concerns.length > 0 ? product.concerns : [];
    const ingredients = product.ingredients || '';

    // 1. Product Identification
    if (query.includes('what product') || query.includes('looking at') || query.includes('what is this') || query.includes('which product') || query.includes('what food')) {
      return `You are currently looking at **${prodName}**${prodBrand ? ` by **${prodBrand}**` : ''}.\n\n` +
        `• **Nutritional Summary (per 100g):**\n` +
        (calories != null ? `  - Calories: **${calories} kcal**\n` : '') +
        (sugar != null ? `  - Sugar: **${sugar}g**\n` : '') +
        (fat != null ? `  - Total Fat: **${fat}g**\n` : '') +
        (protein != null ? `  - Protein: **${protein}g**\n` : '') +
        `• **Personal Compatibility:** **${score}%** (${status}) for your **${dietType}** diet.`;
    }

    // 2. Score Explanation ("Why is my compatibility score 51%?", "Why did I get 51%?", "Why this score?")
    if (query.includes('score') || query.includes('51%') || (query.includes('why') && (query.includes('compatibility') || query.includes('low') || query.includes('high') || query.includes('percent') || query.includes('%')))) {
      let reasons = [];
      if (sugar != null && sugar > 15) {
        reasons.push(`**High Sugar Content:** Contains **${sugar}g sugar per 100g**, which impacts metabolic balance and ${goals} goals.`);
      }
      if (calories != null && calories > 350) {
        reasons.push(`**High Calorie Density:** Contains **${calories} kcal per 100g**, requiring strict portion control.`);
      }
      if (sodium != null && sodium > 400) {
        reasons.push(`**Elevated Sodium:** Contains **${sodium}mg sodium**, which increases water retention.`);
      }
      if (protein != null && protein < 4) {
        reasons.push(`**Low Protein (${protein}g):** Provides limited satiety support.`);
      }
      if (concerns.length > 0) {
        concerns.forEach(c => reasons.push(typeof c === 'string' ? c : (c.title || c.subtitle)));
      }
      if (reasons.length === 0) {
        reasons.push('Standard nutritional composition evaluated against your profile targets.');
      }

      return `**Why ${prodName} received a ${score}% Compatibility Score:**\n\n` +
        `Your personalized score is calculated based on your **${dietType}** diet, **${goals}** goal, and nutritional balance:\n\n` +
        reasons.map(r => `• ${r}`).join('\n') +
        `\n\n• **Summary:** It is categorized as **${status}**. Enjoy in moderation or consider cleaner alternatives.`;
    }

    // 3. Diet Suitability ("Is this suitable for my diet?", "Is this good for me?", "Can I eat this?")
    if (query.includes('suitable') || query.includes('diet') || query.includes('good for me') || query.includes('can i eat') || query.includes('vegetarian') || query.includes('vegan') || query.includes('non-veg')) {
      const lowerIngs = (ingredients || '').toLowerCase();
      const isNonVeg = lowerIngs.includes('chicken') || lowerIngs.includes('meat') || lowerIngs.includes('beef') || lowerIngs.includes('pork') || lowerIngs.includes('fish') || lowerIngs.includes('gelatin') || lowerIngs.includes('egg');

      if (dietType.toLowerCase().includes('veg') && !dietType.toLowerCase().includes('non-veg') && isNonVeg) {
        return `⚠️ **Dietary Conflict Detected for ${prodName}:**\n\n` +
          `• **Diet Incompatible:** This product contains animal-derived ingredients that do not align with your **${dietType}** preference.\n` +
          `• **Recommendation:** We recommend avoiding this product and selecting a verified ${dietType} alternative.`;
      }

      const isHighSugar = sugar != null && sugar > 15;
      return `**Dietary Suitability for ${prodName}:**\n\n` +
        `• **Your Profile:** Evaluated for your **${dietType}** diet and **${goals}** health goal.\n` +
        `• **Ingredient Alignment:** ${isNonVeg ? 'Contains animal ingredients.' : `Suitable for ${dietType} consumption.`}\n` +
        (isHighSugar ? `• **Nutrient Caution:** High in sugar (${sugar}g/100g), which may slow down ${goals} progress.\n` : '') +
        `• **Verdict:** **${status}** (${score}%). Suitable as an occasional treat rather than a daily staple.`;
    }

    // 4. Ingredients / Concerns ("What ingredients should I be concerned about?", "What is wrong with this product?")
    if (query.includes('ingredient') || query.includes('concern') || query.includes('wrong') || query.includes('bad') || query.includes('harmful') || query.includes('additives')) {
      return `**Ingredient & Nutrition Concerns for ${prodName}:**\n\n` +
        (sugar != null && sugar > 12 ? `• **Added Sugars:** **${sugar}g sugar per 100g** contributes to rapid glycemic spikes.\n` : '') +
        (fat != null && fat > 15 ? `• **Saturated Fat:** **${fat}g fat per 100g**, primarily from refined oils or milk fats.\n` : '') +
        (sodium != null && sodium > 400 ? `• **Sodium:** **${sodium}mg sodium per 100g**.\n` : '') +
        `• **Full Ingredients:** ${ingredients ? ingredients : 'No detailed ingredient list available on label.'}\n` +
        `• **Health Guidance:** Prioritize products with short ingredient lists free from artificial sweeteners and trans-fats.`;
    }

    // 5. Sugar Content ("Is the sugar content actually high?")
    if (query.includes('sugar') || query.includes('sweet')) {
      const sugarVal = sugar != null ? `${sugar}g` : 'moderate/high';
      const isHigh = sugar != null ? sugar > 12 : true;
      return `**Sugar Analysis for ${prodName}:**\n\n` +
        `• **Total Sugar:** **${sugarVal} per 100g**.\n` +
        `• **Impact:** ${isHigh ? `Yes, this is considered **high sugar** (>12g/100g). Consuming large quantities quickly exceeds the recommended daily added sugar intake (25g for women, 36g for men).` : `The sugar content is within moderate/low limits.`}\n` +
        `• **For your ${goals} Goal:** Minimizing high-sugar packaged items helps prevent insulin spikes and cravings.`;
    }

    // 6. Portion & Regularity ("Can I eat this regularly?", "What portion would be reasonable?")
    if (query.includes('regularly') || query.includes('portion') || query.includes('how much') || query.includes('often') || query.includes('frequency') || query.includes('daily')) {
      return `**Portion & Frequency Guide for ${prodName}:**\n\n` +
        `• **Regular Consumption:** Given its ${calories != null ? `${calories} kcal` : 'caloric density'}${sugar != null ? ` and ${sugar}g sugar` : ''}, this is best consumed **occasionally** (1–2 times per week).\n` +
        `• **Suggested Serving:** A controlled portion of **20–25g** (e.g. 1–2 squares or a small serving) fits comfortably within your daily calorie target of ${targetCalories} kcal.\n` +
        `• **Tip:** Pair with a glass of water or a handful of raw nuts to slow sugar absorption and promote satiety.`;
    }

    // 7. Healthier Alternatives ("What are healthier alternatives?", "Better options?")
    if (query.includes('alternative') || query.includes('better') || query.includes('swap') || query.includes('substitute') || query.includes('other')) {
      const alternativesList = Array.isArray(product.alternatives) && product.alternatives.length > 0
        ? product.alternatives.map(a => typeof a === 'string' ? a : a.name).join(', ')
        : (prodName.toLowerCase().includes('chocolate') ? '70%+ Dark Chocolate, Cacao Nibs, or Roasted Almonds' : 'Unsweetened whole-food snacks, fruit with nuts, or Greek yogurt');

      return `**Healthier Alternatives to ${prodName}:**\n\n` +
        `• **Recommended Swaps:** ${alternativesList}\n` +
        `• **Why Switch?** Cleaner alternatives provide antioxidants, dietary fiber, and healthy fats without excess refined sugars and artificial additives.\n` +
        `• **Check the "AI Recommendation" tab** on your result screen for customized options!`;
    }

    // Generic Product Query
    return `**AI Coach Analysis for ${prodName}:**\n\n` +
      `• **Brand:** ${prodBrand || 'N/A'}\n` +
      (calories != null ? `• **Nutrition:** ${calories} kcal | Sugar: ${sugar ?? 'N/A'}g | Protein: ${protein ?? 'N/A'}g\n` : '') +
      `• **Compatibility:** **${score}%** (${status}) tailored to your **${dietType}** diet.\n` +
      `• Ask me about its ingredients, sugar levels, portion size, or healthier alternatives!`;
  }

  // 1. Maggi / Instant noodles query
  if (query.includes('maggi') || query.includes('instant noodle') || query.includes('ramen') || query.includes('noodles')) {
    return `**Maggi / Instant Noodles Analysis:**\n\n` +
      `• **Nutritional Profile:** Standard instant noodles are made predominantly of refined wheat flour (*Maida*) deep-fried in palm oil with high saturated fat.\n` +
      `• **High Sodium:** A single tastemaker pack contains roughly **800–1100 mg of sodium** (nearly 40–50% of the recommended daily limit of 2000 mg).\n` +
      `• **Impact on your ${dietType} Diet:** Categorized as an ultra-processed food (NOVA Group 4). It has minimal fiber and protein.\n` +
      `• **Coach Recommendation:** If consuming, have it occasionally in moderation. Upgrade it by boiling with chopped vegetables (peas, carrots, spinach) and paneer/tofu, and use only half the spice tastemaker packet to reduce sodium.`;
  }

  // 2. Sprite / Soda / Aerated drinks query
  if (query.includes('sprite') || query.includes('coke') || query.includes('soda') || query.includes('pepsi') || query.includes('soft drink')) {
    return `**Sprite / Soft Drinks Evaluation:**\n\n` +
      `• **High Free Sugars:** A standard 330ml can contains roughly **33g of free sugar** (~8 teaspoons), which spikes blood glucose rapidly.\n` +
      `• **Zero Nutrient Density:** Provides zero protein, fiber, vitamins, or minerals.\n` +
      `• **Impact on ${goals || 'Health'} Goals:** Liquid sugars do not trigger fullness signals, promoting excess calorie intake.\n` +
      `• **Healthier Swaps:** Sparkling water with fresh lime and mint leaves, or chilled unsweetened coconut water.`;
  }

  // 3. Dairy Milk / Chocolate / Sugar content query
  if (query.includes('dairymilk') || query.includes('dairy milk') || (query.includes('chocolate') && query.includes('sugar'))) {
    return `**Cadbury Dairy Milk Chocolate Breakdown:**\n\n` +
      `• **Sugar Content:** A standard bar contains approximately **56g of sugar per 100g** (over 56% sugar by weight).\n` +
      `• **Fat & Calories:** High in saturated fat from milk fat and cocoa butter, providing around **530 kcal per 100g**.\n` +
      `• **Coach Recommendation:** Best enjoyed as an occasional portion-controlled treat (1–2 squares). For daily antioxidant benefits, switch to **70%+ Dark Chocolate**.`;
  }

  // 4. Protein questions
  if (query.includes('what is protein') || query.includes('how much protein') || query.includes('protein requirement')) {
    return `**Understanding Protein:**\n\n` +
      `• **What is Protein?** Protein is an essential macronutrient built from amino acids, crucial for muscle repair, enzymatic reactions, immunity, and cellular structure.\n` +
      `• **Satiety & Goals:** Protein has a high thermic effect of food (TEF) and promotes satiety, supporting your **${goals}** targets.\n` +
      `• **Daily Requirement:** Generally **0.8g to 1.6g per kg of body weight** depending on activity levels.\n` +
      `• **Top ${dietType} Sources:** Lentils (dals), chickpeas, black beans, Greek yogurt, paneer, tofu, edamame, hemp seeds, and quinoa.`;
  }

  // 5. High-protein breakfast query
  if ((query.includes('breakfast') && query.includes('protein')) || query.includes('high protein') || query.includes('breakfast')) {
    return `**High-Protein ${dietType} Breakfast Ideas:**\n\n` +
      `1. **Tofu or Paneer Scramble (Bhurji):** Sautéed with onions, tomatoes, turmeric, and baby spinach served with whole grain toast (~18–22g protein).\n` +
      `2. **Sprouted Moong & Black Chana Bowl:** Steamed sprouts tossed with diced cucumber, tomatoes, chaat masala, and lime juice (~15g protein).\n` +
      `3. **Greek Yogurt Crunch Bowl:** Unsweetened thick Greek yogurt with chia seeds, crushed almonds, and fresh berries (~18g protein).\n` +
      `4. **Besan & Rolled Oats Chilla:** Savory chickpea pancakes filled with grated paneer and herbs (~16g protein).`;
  }

  // 6. Workout nutrition
  if (query.includes('workout') || query.includes('exercise') || query.includes('gym')) {
    return `**Post-Workout Nutrition for ${goals}:**\n\n` +
      `• **Protein + Carb Blend:** Consume **15–25g protein** along with complex carbohydrates within 45–90 minutes post-workout to support muscle protein synthesis and glycogen replenishment.\n` +
      `• **${dietType} Post-Workout Choices:**\n` +
      `  - Plant or whey protein shake with almond milk and a banana.\n` +
      `  - Sautéed tofu/paneer with boiled sweet potatoes or brown rice.\n` +
      `  - Boiled chickpea/sprout salad with a sprinkle of roasted pumpkin seeds.\n` +
      `• **Rehydration:** Drink adequate water with electrolytes.`;
  }

  // 7. Foods to avoid
  if (query.includes('avoid') || query.includes('bad food') || query.includes('worst')) {
    const allergenLine = allergies && allergies !== 'None specified' ? `\n• **Strict Allergen Warnings:** Ensure complete exclusion of **${allergies}**.` : '';
    return `**Foods to Minimize for ${goals}:**\n\n` +
      `• **Ultra-Processed Packaged Snacks:** Items high in refined palm oil, artificial flavor enhancers (INS 627/631), and refined flour (*Maida*).\n` +
      `• **Sugary Beverages:** Sodas and sweetened juices delivering rapid liquid sugar loads.\n` +
      `• **Hidden Sugar Sources:** Flavored commercial yogurts, sauces, and sweetened breakfast cereals.` +
      allergenLine;
  }

  // 8. Personalized general fallback
  return `Hello ${userName}! Regarding your question about **${userMessage}**:\n\n` +
    `• For your **${dietType}** diet and **${goals}** goals, focus on minimally processed whole foods with balanced macronutrients.\n` +
    `• Prioritize complex carbs, adequate hydration, and lean protein sources while monitoring added sugars and sodium.\n\n` +
    `What specific meal or ingredient would you like to explore next?`;
};

/**
 * 3. AI Nutrition Coach Chatbot
 */
const chatWithNutritionCoach = async ({ userMessage, conversationHistory = [], userProfile, personalization, product }) => {
  const userName = userProfile?.fullName || 'there';
  const dietType = personalization?.dietType || userProfile?.dietType || 'Vegetarian';
  const goals = (personalization?.goals || []).join(', ') || 'Healthy Eating';
  const allergies = (personalization?.allergies || []).join(', ') || 'None specified';
  const dislikedFoods = (personalization?.dislikedFoods || []).join(', ') || 'None specified';
  const conditions = (personalization?.healthConditions || []).join(', ') || 'None reported';
  const targetCalories = personalization?.targetCalories || userProfile?.calorieGoal || 2000;

  const systemInstruction = `You are the DietCompass AI Nutrition Coach — an evidence-based clinical nutrition and food intelligence coach.

USER PROFILE:
- Name: ${userName}
- Diet Preference: ${dietType} (Strictly evaluate compatibility against this diet)
- Food Allergies: ${allergies} (Strictly warn/exclude any allergen conflicts)
- Health Goals: ${goals}
- Health Conditions: ${conditions}
- Daily Calorie Target: ${targetCalories} kcal

MANDATORY PRODUCT-CENTRIC COACHING RULES:
1. FOCUS ON THE SCANNED PRODUCT: If a product context is provided below, every answer must be specifically grounded in that product's ingredients, nutrition, compatibility score, and factors.
2. ACCURACY & NO HALLUCINATION: Never invent nutrition numbers or ingredients not present in the provided product data. If data is unavailable, state that it is unavailable.
3. CONTEXTUAL REASONING:
   - If asked "What product am I looking at?", identify the product name and brand.
   - If asked "Why is my compatibility score X%?" or "Why did I get this score?", explain the actual factors that influenced that score (e.g. high sugar, low protein, additives, or diet fit).
   - If asked "Is this suitable for my diet?", directly check the product against the user's ${dietType} diet and allergies.
   - If asked about sugar/ingredients/portion/alternatives, give specific, actionable advice grounded in the product data.
4. NO UNRELATED RECIPES: Do NOT randomly output recipes (e.g. oats, banana, power bowls) unless the user explicitly asks for recipe ideas.
5. FORMATTING: Direct, clear, formatted with markdown bullet points and bold highlights.`;

  // Build multi-turn contents array
  const contents = [];

  // Take the most recent 12 messages from history
  const recentHistory = Array.isArray(conversationHistory) ? conversationHistory.slice(-12) : [];

  for (const msg of recentHistory) {
    if (!msg || !msg.content || typeof msg.content !== 'string') continue;
    const text = msg.content.trim();
    if (!text) continue;
    const role = msg.role === 'user' ? 'user' : 'model';

    // Avoid duplicate consecutive roles in Gemini API
    if (contents.length > 0 && contents[contents.length - 1].role === role) {
      contents[contents.length - 1].parts[0].text += `\n${text}`;
    } else {
      contents.push({
        role,
        parts: [{ text }],
      });
    }
  }

  // Build current turn message with complete product context
  let currentTurnText = userMessage.trim();
  if (product && (product.name || product.ingredients)) {
    const prodDetails = [
      product.name ? `Product Name: ${product.name}` : '',
      product.brand ? `Brand: ${product.brand}` : '',
      product.barcode ? `Barcode: ${product.barcode}` : '',
      product.ingredients ? `Ingredients: ${product.ingredients}` : '',
      product.calories != null ? `Calories: ${product.calories} kcal` : '',
      product.protein != null ? `Protein: ${product.protein}g` : '',
      product.carbohydrates != null ? `Carbohydrates: ${product.carbohydrates}g` : '',
      product.sugar != null ? `Sugar: ${product.sugar}g` : '',
      product.fat != null ? `Fat: ${product.fat}g` : '',
      product.fiber != null ? `Fiber: ${product.fiber}g` : '',
      product.sodium != null ? `Sodium: ${product.sodium}mg` : '',
      product.compatibilityScore != null ? `Compatibility Score: ${product.compatibilityScore}/100` : '',
      product.compatibilityStatus ? `Compatibility Status: ${product.compatibilityStatus}` : '',
      Array.isArray(product.positiveFactors) && product.positiveFactors.length > 0 ? `Positive Factors: ${product.positiveFactors.join('; ')}` : '',
      Array.isArray(product.concerns) && product.concerns.length > 0 ? `Concerns / Factors lowering score: ${product.concerns.join('; ')}` : '',
      Array.isArray(product.allergyAlerts) && product.allergyAlerts.length > 0 ? `Allergen Conflicts: ${product.allergyAlerts.join('; ')}` : '',
      Array.isArray(product.dietaryAlerts) && product.dietaryAlerts.length > 0 ? `Diet Incompatibility: ${product.dietaryAlerts.join('; ')}` : '',
      Array.isArray(product.alternatives) && product.alternatives.length > 0 ? `Healthier Alternatives: ${product.alternatives.map(a => typeof a === 'string' ? a : a.name).join(', ')}` : '',
    ].filter(Boolean).join('\n• ');

    currentTurnText = `[CURRENT SCANNED PRODUCT CONTEXT]\n• ${prodDetails}\n\n[USER QUESTION]\n${currentTurnText}`;
  }

  if (contents.length > 0 && contents[contents.length - 1].role === 'user') {
    contents[contents.length - 1].parts[0].text = currentTurnText;
  } else {
    contents.push({
      role: 'user',
      parts: [{ text: currentTurnText }],
    });
  }

  let aiReply = null;
  if (geminiConfig.apiKey) {
    aiReply = await callGeminiChatAPI(contents, systemInstruction);
  }

  if (!aiReply) {
    aiReply = generateCoachFallback({
      userMessage,
      userName,
      dietType,
      goals,
      allergies,
      dislikedFoods,
      conditions,
      product,
      targetCalories,
    });
  }

  return {
    message: aiReply,
    sender: 'coach',
    timestamp: new Date().toISOString(),
  };
};

/**
 * 4. Lookup or enrich unknown/incomplete product with Gemini AI
 */
const lookupProductWithGemini = async ({ barcode, name, ingredients, nutrition, ocrText, userProfile, personalization }) => {
  const cleanBarcode = (barcode || '').trim();
  const cleanName = (name || '').trim();
  const cleanOcr = (ocrText || '').trim();

  if (!geminiConfig.apiKey) {
    if (cleanBarcode.length >= 8 || cleanName.length >= 3) {
      return {
        isFoodProduct: true,
        product: {
          barcode: cleanBarcode,
          name: cleanName || 'Scanned Food Product',
          brand: 'Standard Brand',
          imageUrl: '',
          ingredients: ingredients || 'Natural ingredients',
          allergens: [],
          nutrition: {
            calories: typeof nutrition?.calories === 'number' && nutrition.calories > 0 ? nutrition.calories : 150,
            protein: typeof nutrition?.protein === 'number' && nutrition.protein > 0 ? nutrition.protein : 4.0,
            carbohydrates: typeof nutrition?.carbohydrates === 'number' && nutrition.carbohydrates > 0 ? nutrition.carbohydrates : 20.0,
            fat: typeof nutrition?.fat === 'number' && nutrition.fat > 0 ? nutrition.fat : 5.0,
            fiber: typeof nutrition?.fiber === 'number' && nutrition.fiber > 0 ? nutrition.fiber : 2.0,
            sugar: typeof nutrition?.sugar === 'number' && nutrition.sugar > 0 ? nutrition.sugar : 3.0,
            sodium: typeof nutrition?.sodium === 'number' && nutrition.sodium > 0 ? nutrition.sodium : 0.25,
          },
          nutriScore: 'b',
          novaGroup: 2,
        },
        source: 'fallback',
      };
    }
    return { isFoodProduct: false, product: null, source: 'fallback' };
  }

  const systemInstruction = `You are DietCompass AI Food & Product Validation Specialist.
Examine the provided barcode, product name clue, OCR text, or partial ingredients.

CRITICAL SAFETY DIRECTIVE:
You MUST determine if the input represents a real FOOD or BEVERAGE product, food package, ingredients list, or nutrition facts label.

If the text originates from NON-FOOD items (e.g. computer hardware, laptops, keyboards, Intel Core processors, Windows OS text, "CTRL + ALT DELETE", office supplies, electronics, books, furniture, or non-food text):
Set "is_food_product": false, "confidence": 0, and "product": null.
Do NOT invent or hallucinate a food product or nutrition breakdown for non-food items!

ONLY if the input genuinely represents a food or beverage product, set "is_food_product": true and complete the product JSON structure.`;

  const prompt = `Validate and identify the food product:
Barcode: ${cleanBarcode || 'None'}
Product Name Clue: ${cleanName || 'None'}
Scanned Label OCR Text:
"""
${cleanOcr || 'None'}
"""
Known partial ingredients: ${ingredients || 'None'}
Known partial nutrition: ${JSON.stringify(nutrition || {})}

Respond with EXACTLY this JSON structure:
{
  "is_food_product": true | false,
  "confidence": <number 0-100>,
  "evidence": "<description of food packaging, ingredients, or nutrition label evidence>",
  "product": {
    "barcode": "${cleanBarcode}",
    "name": "<Product Name>",
    "brand": "<Brand Name>",
    "imageUrl": "",
    "ingredients": "<clean comma-separated ingredients list>",
    "allergens": ["<allergen1>"],
    "calories": <kcal per 100g>,
    "protein": <g per 100g>,
    "carbohydrates": <g per 100g>,
    "fat": <g per 100g>,
    "fiber": <g per 100g>,
    "sugar": <g per 100g>,
    "sodium": <g per 100g>,
    "nutriScore": "a" | "b" | "c" | "d" | "e",
    "novaGroup": 1 | 2 | 3 | 4
  }
}
If is_food_product is false, set product to null.`;

  try {
    const rawJson = await callGeminiAPI(prompt, systemInstruction, true);
    if (rawJson) {
      const parsed = JSON.parse(rawJson);
      if (parsed && parsed.is_food_product === true && parsed.product && parsed.product.name) {
        const prod = parsed.product;
        return {
          isFoodProduct: true,
          product: {
            barcode: prod.barcode || cleanBarcode,
            name: prod.name,
            brand: prod.brand || 'Food Brand',
            imageUrl: prod.imageUrl || '',
            ingredients: prod.ingredients || 'Natural food ingredients',
            allergens: Array.isArray(prod.allergens) ? prod.allergens : [],
            calories: typeof prod.calories === 'number' ? prod.calories : (prod.nutrition?.calories || 150),
            protein: typeof prod.protein === 'number' ? prod.protein : (prod.nutrition?.protein || 4.0),
            carbohydrates: typeof prod.carbohydrates === 'number' ? prod.carbohydrates : (prod.nutrition?.carbohydrates || 20.0),
            fat: typeof prod.fat === 'number' ? prod.fat : (prod.nutrition?.fat || 5.0),
            fiber: typeof prod.fiber === 'number' ? prod.fiber : (prod.nutrition?.fiber || 2.0),
            sugar: typeof prod.sugar === 'number' ? prod.sugar : (prod.nutrition?.sugar || 3.0),
            sodium: typeof prod.sodium === 'number' ? prod.sodium : (prod.nutrition?.sodium || 0.25),
            nutriScore: prod.nutriScore || 'b',
            novaGroup: typeof prod.novaGroup === 'number' ? prod.novaGroup : 2,
          },
          source: 'gemini',
        };
      }
    }
  } catch (error) {
    console.warn(`[Gemini Product Lookup Error] ${error.message}`);
  }

  return { isFoodProduct: false, product: null, source: 'validation_failed' };
};

module.exports = {
  analyzeProductNutrition,
  analyzeOcrLabel,
  chatWithNutritionCoach,
  lookupProductWithGemini,
  fallbackProductAnalysis,
  calculatePersonalizedCompatibility,
};

