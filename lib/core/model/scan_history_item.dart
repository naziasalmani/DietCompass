import 'food_product.dart';
import '../services/nutrition_normalization_service.dart';

/// Represents a single product scan recorded for the authenticated user.
class ScanHistoryItem {
  final String id;
  final String userId;
  final String barcode;
  final String productName;
  final String brand;
  final String imageUrl;
  final int score;
  final String ingredients;
  final List<String> allergens;
  final Map<String, dynamic> nutrients;
  final DateTime scannedAt;

  ScanHistoryItem({
    required this.id,
    required this.userId,
    this.barcode = '',
    required this.productName,
    this.brand = '',
    this.imageUrl = '',
    this.score = 85,
    this.ingredients = '',
    this.allergens = const [],
    this.nutrients = const {},
    required this.scannedAt,
  });

  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = json['scannedAt'] != null
          ? DateTime.parse(json['scannedAt'].toString())
          : (json['createdAt'] != null
              ? DateTime.parse(json['createdAt'].toString())
              : DateTime.now());
    } catch (_) {
      parsedDate = DateTime.now();
    }

    final allergensList = <String>[];
    if (json['allergens'] is List) {
      for (final a in json['allergens']) {
        if (a != null) allergensList.add(a.toString());
      }
    }

    final rawNutrients = json['nutrients'];
    final nutrientsMap = <String, dynamic>{};
    if (rawNutrients is Map) {
      rawNutrients.forEach((k, v) {
        nutrientsMap[k.toString()] = v;
      });
    }

    return ScanHistoryItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      barcode: (json['barcode'] ?? '').toString(),
      productName: (json['productName'] ?? json['name'] ?? 'Scanned Product').toString(),
      brand: (json['brand'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      score: (json['score'] is num) ? (json['score'] as num).toInt() : 85,
      ingredients: (json['ingredients'] ?? '').toString(),
      allergens: allergensList,
      nutrients: nutrientsMap,
      scannedAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'barcode': barcode,
        'productName': productName,
        'brand': brand,
        'imageUrl': imageUrl,
        'score': score,
        'ingredients': ingredients,
        'allergens': allergens,
        'nutrients': nutrients,
        'scannedAt': scannedAt.toIso8601String(),
      };

  /// Converts this scan history record back into a full [FoodProduct]
  /// so tapping it opens the real [ResultScreen].
  FoodProduct toFoodProduct() {
    double? doubleOrNull(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    final norm = NutritionNormalizationService.instance.normalize(
      calories: doubleOrNull(nutrients['calories']),
      protein: doubleOrNull(nutrients['protein']),
      carbohydrates: doubleOrNull(nutrients['carbohydrates']),
      fat: doubleOrNull(nutrients['fat']),
      saturatedFat: doubleOrNull(nutrients['saturatedFat']),
      fiber: doubleOrNull(nutrients['fiber']),
      sugar: doubleOrNull(nutrients['sugar']),
      sodium: doubleOrNull(nutrients['sodium']),
      salt: doubleOrNull(nutrients['salt']),
      productName: productName,
      brand: brand,
      ingredients: ingredients,
    );

    return FoodProduct(
      barcode: barcode,
      name: productName,
      brand: brand,
      imageUrl: imageUrl,
      ingredients: ingredients,
      allergens: allergens,
      calories: norm.calories,
      protein: norm.protein,
      carbohydrates: norm.carbohydrates,
      fat: norm.fat,
      saturatedFat: norm.saturatedFat,
      fiber: norm.fiber,
      sugar: norm.sugar,
      sodium: norm.sodium,
      salt: norm.salt,
      nutritionBasis: norm.nutritionBasis,
    );
  }

  /// User-friendly relative time string (e.g. "Just now", "10m ago", "Today, 9:30 AM", "Yesterday")
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(scannedAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24 && now.day == scannedAt.day) {
      final hour = scannedAt.hour % 12 == 0 ? 12 : scannedAt.hour % 12;
      final minute = scannedAt.minute.toString().padLeft(2, '0');
      final period = scannedAt.hour >= 12 ? 'PM' : 'AM';
      return 'Today, $hour:$minute $period';
    } else if (difference.inDays == 1 || (difference.inHours < 48 && now.day - scannedAt.day == 1)) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${scannedAt.day}/${scannedAt.month}/${scannedAt.year}';
    }
  }
}
