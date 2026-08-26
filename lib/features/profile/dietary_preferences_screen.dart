import 'package:flutter/material.dart';
import 'package:diet_compass/features/personalization/lib/onboarding/onboarding_data.dart';
import '../../core/services/personalization_service.dart';

class DietaryPreferencesScreen extends StatefulWidget {
  const DietaryPreferencesScreen({
    super.key,
    this.initialData,
  });

  final OnboardingData? initialData;

  @override
  State<DietaryPreferencesScreen> createState() =>
      _DietaryPreferencesScreenState();
}

class _DietaryPreferencesScreenState extends State<DietaryPreferencesScreen> {
  late final OnboardingData _data;
  bool _showOtherDislikeField = false;

  static const _dietTypes = [
    ('Vegetarian', Icons.eco),
    ('Vegan', Icons.spa),
    ('Eggetarian', Icons.egg_outlined),
    ('Non-Vegetarian', Icons.set_meal_outlined),
  ];
  static const _allergies = [
    'Milk', 'Eggs', 'Peanuts', 'Tree Nuts', 'Soy', 'Wheat', 'Gluten',
    'Fish', 'Shellfish', 'Sesame', 'Mustard', 'Celery', 'Lupin', 'Sulphites',
  ];
  static const _dislikedFoods = [
    'Spicy Food', 'Mushrooms', 'Seafood', 'Bitter Vegetables',
  ];

  @override
  void initState() {
    super.initState();
    _data = widget.initialData ?? OnboardingData();
    _showOtherDislikeField = _data.dislikedFoods.any(
      (food) => !_dislikedFoods.contains(food),
    );
  }

  Future<void> _save() async {
    try {
      await PersonalizationService.instance.savePersonalization(_data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dietary preferences updated')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update preferences: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final noneAllergies = _data.allergies.contains('None of the above');
    return Scaffold(
      backgroundColor: const Color(0xFFF6F3FC),
      appBar: AppBar(
        title: const Text('Dietary Preferences'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          _section(
            title: 'Diet Type',
            subtitle: 'Choose the option that best describes you.',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _dietTypes.map((diet) {
                final selected = _data.dietType == diet.$1;
                return ChoiceChip(
                  avatar: Icon(diet.$2, size: 18),
                  label: Text(diet.$1),
                  selected: selected,
                  onSelected: (_) => setState(() => _data.dietType = diet.$1),
                );
              }).toList(),
            ),
          ),
          _section(
            title: 'Allergies',
            subtitle: 'Select all that apply to you.',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._allergies.map((allergy) => _choiceChip(
                      allergy,
                      _data.allergies.contains(allergy),
                      () => setState(() {
                        _data.allergies.remove('None of the above');
                        if (!_data.allergies.remove(allergy)) {
                          _data.allergies.add(allergy);
                        }
                      }),
                    )),
                _choiceChip(
                  'None of the above',
                  noneAllergies,
                  () => setState(() {
                    if (noneAllergies) {
                      _data.allergies.remove('None of the above');
                    } else {
                      _data.allergies
                        ..clear()
                        ..add('None of the above');
                    }
                  }),
                ),
              ],
            ),
          ),
          _section(
            title: 'Foods You Dislike',
            subtitle: 'This helps us avoid suggesting foods you do not enjoy.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _dislikedFoods.map((food) => _choiceChip(
                        food,
                        _data.dislikedFoods.contains(food),
                        () => setState(() {
                          if (!_data.dislikedFoods.remove(food)) {
                            _data.dislikedFoods.add(food);
                          }
                        }),
                      )).toList(),
                ),
                const SizedBox(height: 8),
                _choiceChip(
                  'Other',
                  _showOtherDislikeField,
                  () => setState(() => _showOtherDislikeField =
                      !_showOtherDislikeField),
                ),
                if (_showOtherDislikeField) ...[
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Food you dislike',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _data.dislikedFoods.removeWhere(
                        (food) => !_dislikedFoods.contains(food),
                      );
                      if (value.trim().isNotEmpty) {
                        _data.dislikedFoods.add(value.trim());
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Preferences'),
          ),
        ],
      ),
    );
  }

  Widget _choiceChip(String label, bool selected, VoidCallback onSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }

  Widget _section({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
