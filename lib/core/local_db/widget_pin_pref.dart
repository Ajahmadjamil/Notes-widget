import 'dart:io';

import 'package:home_widget/home_widget.dart';
import 'package:noteswidgetapp/core/widget/home_widget_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetPinPref {
  WidgetPinPref._();

  static const _keyDismissedPinPrompt = 'widget_pin_prompt_completed';

  static Future<bool> hasWidgetOnHomeScreen() async {
    if (Platform.isAndroid) {
      try {
        final installed = await HomeWidget.getInstalledWidgets();
        if (installed.any(
          (w) =>
              (w.androidClassName ?? '')
                  .contains(HomeWidgetService.androidProviderName),
        )) {
          await _markPinned();
          return true;
        }
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDismissedPinPrompt) ?? false;
  }

  static Future<void> _markPinned() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDismissedPinPrompt, true);
  }

  /// Call after user adds widget or skips onboarding (won't auto-prompt again).
  static Future<void> markPinPromptHandled() async {
    await _markPinned();
  }
}
