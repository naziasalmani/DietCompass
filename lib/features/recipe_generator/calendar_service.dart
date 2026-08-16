import 'package:device_calendar/device_calendar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class CalendarService {
  static Future<void> addMealPlan() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    final permission = await Permission.calendar.request();

    if (!permission.isGranted) {
      print("Calendar permission denied");
      return;
    }

    final calendarPlugin = DeviceCalendarPlugin();

    final calendarsResult = await calendarPlugin.retrieveCalendars();

    if (!calendarsResult.isSuccess ||
        calendarsResult.data == null ||
        calendarsResult.data!.isEmpty) {
      print("No calendars found");
      return;
    }

    final calendar = calendarsResult.data!.firstWhere(
  (c) =>
      c.accountName != null &&
      c.accountName!.contains("@gmail.com") &&
      !(c.name?.toLowerCase().contains("holiday") ?? false),
  orElse: () => calendarsResult.data!.first,
);

    final event = Event(
      calendar.id,
      title: "DietCompass Meal Plan",
      description: "Follow your AI generated meal plan.",
      start: tz.TZDateTime.now(tz.local),
end: tz.TZDateTime.now(tz.local).add(
  const Duration(hours: 1),
),
    );

    final result = await calendarPlugin.createOrUpdateEvent(event);

    print(result?.isSuccess);

    if (result?.isSuccess == true) {
      print("Calendar event created");
    } else {
      print("Failed to create event");
    }
  }
}