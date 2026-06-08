import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/theme/app_theme_palette.dart';

/// Builds Material 3 [ThemeData] from a semantic palette.
ThemeData buildAppTheme(AppThemePalette palette) {
  final colorScheme = ColorScheme(
    brightness: palette.brightness,
    primary: palette.primary,
    onPrimary: palette.onPrimary,
    secondary: palette.secondary,
    onSecondary: palette.onBackground,
    surface: palette.background,
    onSurface: palette.onBackground,
    error: AppThemePalettes.errorRed,
    onError: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: palette.brightness,
    scaffoldBackgroundColor: palette.background,
    colorScheme: colorScheme,
    appBarTheme: AppBarTheme(
      backgroundColor: palette.background,
      foregroundColor: palette.onBackground,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: palette.primary,
      foregroundColor: palette.onPrimary,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: palette.primary,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: palette.surface,
      textStyle: TextStyle(color: palette.onBackground),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.background,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dividerColor: palette.borderSubtle,
  );
}
