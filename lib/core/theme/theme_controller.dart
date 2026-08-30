import 'package:flutter/material.dart';
import '../services/storage_service.dart';

/// DietCompass — Central Theme Controller
/// Manages reactive theme switching between Light, Dark, and System Default,
/// persisting user selection locally via StorageService.
class ThemeController extends ChangeNotifier {
  ThemeController._internal();
  static final ThemeController instance = ThemeController._internal();

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  String get themeModeName {
    switch (_themeMode) {
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.light:
        return 'Light';
    }
  }

  /// Initialize theme mode from secure local storage
  Future<void> initialize() async {
    try {
      final savedMode = await StorageService.instance.getThemeMode();
      if (savedMode != null) {
        _themeMode = savedMode;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ThemeController] Error initializing theme: $e');
    }
  }

  Future<void> init() => initialize();

  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  /// Set and persist the app-wide ThemeMode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await StorageService.instance.saveThemeMode(mode);
  }
}
