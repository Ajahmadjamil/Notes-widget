import 'dart:io';

import 'package:home_widget/home_widget.dart';
import 'package:noteswidgetapp/core/theme/app_theme_palette.dart';
import 'package:noteswidgetapp/core/theme/theme_provider.dart';
import 'package:noteswidgetapp/core/widget/home_widget_service.dart';

/// Keeps the Android home widget colors in sync with the active app theme.
abstract final class WidgetThemeSync {
  static const String bgColorKey = 'widget_bg_color';
  static const String surfaceColorKey = 'widget_surface_color';
  static const String textPrimaryColorKey = 'widget_text_primary_color';
  static const String textSecondaryColorKey = 'widget_text_secondary_color';

  static Future<void> saveColors([AppThemePalette? palette]) async {
    final p = palette ?? AppThemeProvider.instance.palette;

    await HomeWidget.saveWidgetData<String>(
      bgColorKey,
      '${p.background.toARGB32()}',
    );
    await HomeWidget.saveWidgetData<String>(
      surfaceColorKey,
      '${p.surface.toARGB32()}',
    );
    await HomeWidget.saveWidgetData<String>(
      textPrimaryColorKey,
      '${p.onBackground.toARGB32()}',
    );
    await HomeWidget.saveWidgetData<String>(
      textSecondaryColorKey,
      '${p.onSurfaceVariant.toARGB32()}',
    );
  }

  static Future<void> refreshWidget() async {
    if (!Platform.isAndroid) return;
    await HomeWidget.updateWidget(
      name: HomeWidgetService.androidProviderName,
      qualifiedAndroidName: HomeWidgetService.qualifiedAndroidName,
    );
  }

  static Future<void> applyFromPalette([AppThemePalette? palette]) async {
    await saveColors(palette);
    await refreshWidget();
  }
}
