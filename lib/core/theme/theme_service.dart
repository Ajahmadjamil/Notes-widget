import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/theme/app_theme_palette.dart';
import 'package:noteswidgetapp/core/theme/theme_provider.dart';

/// Backwards-compatible accessor used by [AppColors] across the app.
class ThemeService extends ChangeNotifier {
  ThemeService._();
  static final ThemeService instance = ThemeService._();

  AppThemeProvider get _provider => AppThemeProvider.instance;

  ThemeMode get themeMode =>
      _provider.isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeMode get currentTheme => themeMode;

  bool get isDarkMode => _provider.isDarkMode;

  AppThemeId get themeId => _provider.themeId;

  AppThemePalette get palette => _provider.palette;
}
