import 'package:flutter/material.dart';
import '../../core/services/personalization_service.dart';

class ActivityLevelScreen extends StatefulWidget {
  const ActivityLevelScreen({
    super.key,
    this.initialActivityLevel,
  });

  final String? initialActivityLevel;

  @override
  State<ActivityLevelScreen> createState() => _ActivityLevelScreenState();
}

class _ActivityLevelScreenState extends State<ActivityLevelScreen> {
  late String? _selectedActivityLevel = widget.initialActivityLevel;

  static const _activityLevels = [
    (
      'Sedentary',
      'Little or no exercise',
      Icons.weekend_outlined,
    ),
    (
      'Lightly Active',
      'Light exercise 1-3 days/week',
      Icons.directions_walk,
    ),
    (
      'Moderately Active',
      'Moderate exercise 3-5 days/week',
      Icons.accessibility_new,
    ),
    (
      'Very Active',
      'Hard exercise 6-7 days/week',
      Icons.directions_run,
    ),
  ];

  Future<void> _select(String value) async {
    setState(() => _selectedActivityLevel = value);
    try {
      await PersonalizationService.instance.updatePersonalization({
        'activityLevel': value,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity level updated')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update activity level: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F3FC),
      appBar: AppBar(
        title: const Text('Activity Level'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How active are you on a regular day?',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ..._activityLevels.map((level) {
                    final selected = _selectedActivityLevel == level.$1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: selected
                              ? const Color(0xFFE4F5E9)
                              : const Color(0xFFF0EDF7),
                          child: Icon(
                            level.$3,
                            color: selected
                                ? const Color(0xFF1E8A4C)
                                : const Color(0xFF6C4EF5),
                          ),
                        ),
                        title: Text(level.$1),
                        subtitle: Text(level.$2),
                        trailing: selected
                            ? const Icon(
                                Icons.check_circle,
                                color: Color(0xFF1E8A4C),
                              )
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: selected
                                ? const Color(0xFF1E8A4C)
                                : const Color(0xFFE2DDED),
                          ),
                        ),
                        onTap: () => _select(level.$1),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
