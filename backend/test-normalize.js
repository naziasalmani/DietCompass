const { normalizeProductForRecipe } = require('./src/utils/productNormalizer');

const testCases = [
  { input: { name: 'Dairy Milk Silk Chocolate', brand: 'Cadbury' }, expected: 'chocolate' },
  { input: { name: 'Cadbury Dairy Milk', brand: 'Cadbury' }, expected: 'chocolate' },
  { input: { name: 'Maggi 2-Minute Masala Noodles', brand: 'Nestle' }, expected: 'noodles' },
  { input: { name: 'Maggi Masala Noodles', brand: 'Nestle' }, expected: 'noodles' },
  { input: { name: "Lay's Classic Salted Potato Chips", brand: "Lay's" }, expected: 'potato chips' },
  { input: { name: 'Amul Butter', brand: 'Amul' }, expected: 'butter' },
  { input: { name: 'Amul Processed Cheese', brand: 'Amul' }, expected: 'cheese' },
  { input: { name: 'Oreo Original', brand: 'Cadbury' }, expected: 'cookies' },
  { input: { name: 'Nutella Hazelnut Spread', brand: 'Ferrero' }, expected: 'hazelnut spread' },
  { input: { name: 'Organic Rolled Oats', brand: 'Quaker' }, expected: 'oats' },
];

console.log('======================================================');
console.log('🧪 Testing normalizeProductForRecipe directly');
console.log('======================================================\n');

let pass = 0;
for (const { input, expected } of testCases) {
  const norm = normalizeProductForRecipe(input);
  if (norm.normalizedIngredient === expected && norm.recipeSearchQuery === expected) {
    console.log(`✅ PASS: "${input.name}" -> normalizedIngredient: "${norm.normalizedIngredient}" | searchQuery: "${norm.recipeSearchQuery}"`);
    pass++;
  } else {
    console.error(`❌ FAIL: "${input.name}" -> got "${norm.normalizedIngredient}", expected "${expected}"`);
  }
}

console.log(`\nResult: ${pass}/${testCases.length} Passed`);
