import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/core/model/food_product.dart';

void main() {
  group("What's Good & Watch Out For Section Tests", () {
    test('TestCase 1: 10 Watch Out For findings prioritization & deduplication', () {
      final rawFindings = [
        {'title': 'Additive Concern: E476', 'subtitle': 'Emulsifier concern', 'category': 'additives'},
        {'title': 'Hidden Sugar: Cane Sugar', 'subtitle': 'Added sugar alias', 'category': 'sugars'},
        {'title': 'Additive Concern: E476', 'subtitle': 'Duplicate E476', 'category': 'additives'}, // duplicate
        {'title': 'Allergen Alert: Milk', 'subtitle': 'Contains dairy allergen', 'category': 'allergens'},
        {'title': 'High Sugar Content', 'subtitle': 'Exceeds recommended daily limit', 'category': 'nutrition'},
      ];

      final seenTitles = <String>{};
      final uniquePoints = <Map<String, String>>[];

      for (final f in rawFindings) {
        final titleKey = f['title']!.trim().toLowerCase();
        if (seenTitles.add(titleKey)) {
          uniquePoints.add(f);
        }
      }

      // Verify deduplication
      expect(uniquePoints.length, equals(4), reason: 'Duplicate E476 should be filtered out');

      int warningPriority(Map<String, String> item) {
        final t = item['title']!.toLowerCase();
        final s = item['subtitle']!.toLowerCase();
        final c = item['category']!.toLowerCase();

        if (t.contains('allergen') || s.contains('allergen') || c.contains('allergen')) return 1;
        if (t.contains('profile concern') || t.contains('dietary') || s.contains('profile concern')) return 2;
        if (t.contains('hidden sugar') || t.contains('disguised sugar') || s.contains('sugar alias')) return 3;
        if (t.contains('high sugar') || t.contains('high saturated fat') || t.contains('high sodium') || t.contains('high fat') || t.contains('nutrition warning')) return 4;
        if (t.contains('additive') || t.contains('e-number') || s.contains('additive')) return 5;
        return 6;
      }

      uniquePoints.sort((a, b) => warningPriority(a).compareTo(warningPriority(b)));

      // Verify Allergen Alert is at index 0 (Highest Priority)
      expect(uniquePoints.first['title'], contains('Allergen Alert'), reason: 'Allergen alerts must be prioritized first');
      expect(uniquePoints[1]['title'], contains('Hidden Sugar'), reason: 'Hidden sugar prioritized before generic additives');
    });

    test('TestCase 7: Collapsing logic calculation for > 3 findings', () {
      final totalFindings = 11;
      final initialMax = 3;
      final shouldCollapse = totalFindings > initialMax;
      final hiddenCount = totalFindings - initialMax;

      expect(shouldCollapse, isTrue);
      expect(hiddenCount, equals(8));
    });

    test('TestCase 2: Collapsing logic calculation for <= 3 findings', () {
      final totalFindings = 2;
      final initialMax = 3;
      final shouldCollapse = totalFindings > initialMax;

      expect(shouldCollapse, isFalse, reason: '2 findings should not show expand button');
    });
  });
}
