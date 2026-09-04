import 'package:flutter/material.dart';
import 'package:diet_compass/core/theme/app_colors.dart';
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
    final colors = context.dcColors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: Text(
          'Activity Level',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Card(
            color: colors.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colors.cardBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How active are you on a regular day?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._activityLevels.map((level) {
                    final selected = _selectedActivityLevel == level.$1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: selected
                              ? (colors.isDark ? const Color(0xFF1B2E24) : const Color(0xFFE4F5E9))
                              : colors.surfaceSecondary,
                          child: Icon(
                            level.$3,
                            color: selected
                                ? colors.iconGreen
                                : colors.iconPurple,
                          ),
                        ),
                        title: Text(
                          level.$1,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          level.$2,
                          style: TextStyle(color: colors.textSecondary),
                        ),
                        trailing: selected
                            ? Icon(
                                Icons.check_circle,
                                color: colors.iconGreen,
                              )
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: selected
                                ? colors.iconGreen
                                : colors.cardBorder,
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
