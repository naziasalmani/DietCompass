import 'package:flutter/material.dart';

/// Comprehensive grocery and pantry taxonomy categories.
enum PantryCategory {
  fruitsVegetables,
  dairyEggs,
  meatSeafood,
  grainsCereals,
  pulsesLegumes,
  snacks,
  beverages,
  bakery,
  condimentsSauces,
  spicesSeasonings,
  cookingEssentials,
  frozenFoods,
  readyToEatInstant,
  sweetsDesserts,
  other,
}

extension PantryCategoryExtension on PantryCategory {
  String get label {
    switch (this) {
      case PantryCategory.fruitsVegetables:
        return 'Fruits & Vegetables';
      case PantryCategory.dairyEggs:
        return 'Dairy & Eggs';
      case PantryCategory.meatSeafood:
        return 'Meat & Seafood';
      case PantryCategory.grainsCereals:
        return 'Grains & Cereals';
      case PantryCategory.pulsesLegumes:
        return 'Pulses & Legumes';
      case PantryCategory.snacks:
        return 'Snacks';
      case PantryCategory.beverages:
        return 'Beverages';
      case PantryCategory.bakery:
        return 'Bakery';
      case PantryCategory.condimentsSauces:
        return 'Condiments & Sauces';
      case PantryCategory.spicesSeasonings:
        return 'Spices & Seasonings';
      case PantryCategory.cookingEssentials:
        return 'Cooking Essentials';
      case PantryCategory.frozenFoods:
        return 'Frozen Foods';
      case PantryCategory.readyToEatInstant:
        return 'Ready-to-Eat / Instant Foods';
      case PantryCategory.sweetsDesserts:
        return 'Sweets & Desserts';
      case PantryCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case PantryCategory.fruitsVegetables:
        return Icons.eco_rounded;
      case PantryCategory.dairyEggs:
        return Icons.egg_alt_rounded;
      case PantryCategory.meatSeafood:
        return Icons.set_meal_rounded;
      case PantryCategory.grainsCereals:
        return Icons.grain_rounded;
      case PantryCategory.pulsesLegumes:
        return Icons.circle_rounded;
      case PantryCategory.snacks:
        return Icons.cookie_rounded;
      case PantryCategory.beverages:
        return Icons.local_cafe_rounded;
      case PantryCategory.bakery:
        return Icons.bakery_dining_rounded;
      case PantryCategory.condimentsSauces:
        return Icons.soup_kitchen_rounded;
      case PantryCategory.spicesSeasonings:
        return Icons.flare_rounded;
      case PantryCategory.cookingEssentials:
        return Icons.kitchen_rounded;
      case PantryCategory.frozenFoods:
        return Icons.ac_unit_rounded;
      case PantryCategory.readyToEatInstant:
        return Icons.ramen_dining_rounded;
      case PantryCategory.sweetsDesserts:
        return Icons.icecream_rounded;
      case PantryCategory.other:
        return Icons.category_rounded;
    }
  }

  Color get color {
    switch (this) {
      case PantryCategory.fruitsVegetables:
        return const Color(0xFF16A34A);
      case PantryCategory.dairyEggs:
        return const Color(0xFF3B82F6);
      case PantryCategory.meatSeafood:
        return const Color(0xFFDC2626);
      case PantryCategory.grainsCereals:
        return const Color(0xFF6C4EF5);
      case PantryCategory.pulsesLegumes:
        return const Color(0xFFD97706);
      case PantryCategory.snacks:
        return const Color(0xFFE0862E);
      case PantryCategory.beverages:
        return const Color(0xFF059669);
      case PantryCategory.bakery:
        return const Color(0xFF9333EA);
      case PantryCategory.condimentsSauces:
        return const Color(0xFFE0525C);
      case PantryCategory.spicesSeasonings:
        return const Color(0xFFB45309);
      case PantryCategory.cookingEssentials:
        return const Color(0xFF4B5563);
      case PantryCategory.frozenFoods:
        return const Color(0xFF0284C7);
      case PantryCategory.readyToEatInstant:
        return const Color(0xFFEA580C);
      case PantryCategory.sweetsDesserts:
        return const Color(0xFFDB2777);
      case PantryCategory.other:
        return const Color(0xFF6B7280);
    }
  }

  static PantryCategory fromString(String? value) {
    if (value == null || value.trim().isEmpty) return PantryCategory.other;
    final normalized = value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    // Check enum names
    for (final c in PantryCategory.values) {
      final nameClean = c.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final labelClean = c.label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (normalized == nameClean || normalized == labelClean) {
        return c;
      }
    }

    // Check legacy aliases
    if (normalized == 'dairy') return PantryCategory.dairyEggs;
    if (normalized == 'grains') return PantryCategory.grainsCereals;
    if (normalized == 'condiments') return PantryCategory.condimentsSauces;
    if (normalized == 'instant' || normalized == 'readytoeat') return PantryCategory.readyToEatInstant;
    if (normalized == 'sweets') return PantryCategory.sweetsDesserts;
    if (normalized == 'spices') return PantryCategory.spicesSeasonings;

    return PantryCategory.other;
  }
}
