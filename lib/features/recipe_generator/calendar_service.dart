import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../core/model/meal_plan_model.dart';
import '../../core/services/meal_plan_service.dart';

class CalendarSyncResult {
  final bool isSuccess;
  final String message;
  final int eventsCount;
  final bool isDuplicate;

  const CalendarSyncResult({
    required this.isSuccess,
    required this.message,
    this.eventsCount = 0,
    this.isDuplicate = false,
  });
}

class CalendarService {
  static final Set<String> _syncedPlanSignatures = {};

  static Future<CalendarSyncResult> addMealPlan([MealPlanResponse? plan]) async {
    final effectivePlan = plan ?? MealPlanService.instance.currentPlan;

    if (effectivePlan == null || effectivePlan.days.isEmpty) {
      return const CalendarSyncResult(
        isSuccess: false,
        message: 'No active meal plan found to add to calendar.',
      );
    }

    // Prevent duplicate sync for the same plan
    final planSignature = '${effectivePlan.durationDays}_${effectivePlan.goal}_${effectivePlan.days.map((d) => d.meals.map((m) => m.title).join()).join()}';
    if (_syncedPlanSignatures.contains(planSignature)) {
      return const CalendarSyncResult(
        isSuccess: true,
        message: 'This meal plan has already been added to your Google Calendar.',
        isDuplicate: true,
      );
    }

    try {
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      } catch (_) {
        tz.setLocalLocation(tz.local);
      }

      final permission = await Permission.calendar.request();
      if (!permission.isGranted) {
        return const CalendarSyncResult(
          isSuccess: false,
          message: 'Calendar permission denied. Please enable calendar access in settings.',
        );
      }

      final calendarPlugin = DeviceCalendarPlugin();
      final calendarsResult = await calendarPlugin.retrieveCalendars();

      if (!calendarsResult.isSuccess ||
          calendarsResult.data == null ||
          calendarsResult.data!.isEmpty) {
        return const CalendarSyncResult(
          isSuccess: false,
          message: 'No calendar accounts found on this device.',
        );
      }

      final calendar = calendarsResult.data!.firstWhere(
        (c) =>
            c.accountName != null &&
            c.accountName!.contains('@gmail.com') &&
            !(c.name?.toLowerCase().contains('holiday') ?? false),
        orElse: () => calendarsResult.data!.first,
      );

      int createdCount = 0;
      final baseDate = tz.TZDateTime.now(tz.local);

      for (int i = 0; i < effectivePlan.days.length; i++) {
        final day = effectivePlan.days[i];
        final dayDate = baseDate.add(Duration(days: i));

        final mealsSummary = day.meals
            .map((m) => '• [${m.type}] ${m.title} (${m.calories} kcal, ${m.proteinGrams}g Protein)')
            .join('\n');

        final event = Event(
          calendar.id,
          title: 'DietCompass: ${day.dayNumber} Meal Plan',
          description: 'Personalized ${effectivePlan.goal} (${effectivePlan.diet}) Plan:\n\n$mealsSummary\n\nDaily Total: ${day.dailyCalories} kcal | ${day.dailyProtein}g Protein | ${day.dailyFiber}g Fiber',
          start: tz.TZDateTime(tz.local, dayDate.year, dayDate.month, dayDate.day, 8, 0),
          end: tz.TZDateTime(tz.local, dayDate.year, dayDate.month, dayDate.day, 21, 0),
        );

        final result = await calendarPlugin.createOrUpdateEvent(event);
        if (result?.isSuccess == true) {
          createdCount++;
        }
      }

      if (createdCount > 0) {
        _syncedPlanSignatures.add(planSignature);
        return CalendarSyncResult(
          isSuccess: true,
          message: 'Your ${effectivePlan.durationDays}-day meal plan has been added to your Google Calendar.',
          eventsCount: createdCount,
        );
      } else {
        return const CalendarSyncResult(
          isSuccess: false,
          message: 'Failed to create calendar events. Please try again.',
        );
      }
    } catch (e) {
      debugPrint('[CalendarService] Error adding to calendar: $e');
      return CalendarSyncResult(
        isSuccess: false,
        message: 'Error syncing with calendar: $e',
      );
    }
  }
}