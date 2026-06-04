import 'package:flutter/material.dart';

class ThemeService extends ChangeNotifier {
  ThemeService();
  static final ThemeService instance = ThemeService._internal();
  ThemeService._internal();
  ThemeMode themeMode = ThemeMode.light;
  ThemeMode get currentTheme => themeMode;

  bool get isDarkMode {
    if (themeMode == ThemeMode.system) {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return themeMode == ThemeMode.dark;
  }

  void toggleTheme() {
    switch (themeMode) {
      case ThemeMode.light:
        themeMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        themeMode = ThemeMode.system;
        break;
      case ThemeMode.system:
        themeMode = ThemeMode.light;
        break;
    }
    notifyListeners();
  }

  void setTheme(ThemeMode mode) {
    themeMode = mode;
    notifyListeners();
  }
}
