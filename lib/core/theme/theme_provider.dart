import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:noteswidgetapp/core/theme/app_theme_palette.dart';
import 'package:noteswidgetapp/core/widget/widget_theme_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _storageKey = 'app_theme_id';

/// Tracks the active palette, persists selection, and restarts the app on change.
class AppThemeProvider extends ChangeNotifier {
  AppThemeProvider._();
  static final AppThemeProvider instance = AppThemeProvider._();

  AppThemeId _themeId = AppThemeId.softCream;
  late AppThemePalette _palette;
  bool _initialized = false;

  AppThemeId get themeId => _themeId;
  AppThemePalette get palette => _palette;
  String get currentThemeName => _palette.name;
  bool get isInitialized => _initialized;

  bool get isDarkMode => _palette.brightness == Brightness.dark;

  /// Call once in [main] before [runApp].
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _themeId = AppThemeIdLabel.fromStorage(prefs.getString(_storageKey));
    _palette = AppThemePalettes.forId(_themeId);
    _initialized = true;
    await WidgetThemeSync.applyFromPalette(_palette);
    notifyListeners();
  }

  /// Saves theme, then rebuilds the entire widget tree via Phoenix.
  Future<void> selectThemeAndRestart(
    BuildContext context,
    AppThemeId id,
  ) async {
    if (id == _themeId) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, id.name);

    _themeId = id;
    _palette = AppThemePalettes.forId(id);
    await WidgetThemeSync.applyFromPalette(_palette);
    notifyListeners();

    if (context.mounted) {
      Phoenix.rebirth(context);
    }
  }
}
