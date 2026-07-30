import 'dart:io';

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:noteswidgetapp/core/constants/app_constants.dart';
import 'package:noteswidgetapp/core/local_db/widget_pin_pref.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/core/widget/home_widget_service.dart';

class WidgetSetupHelper {
  WidgetSetupHelper._();

  static Future<bool> _isWidgetActuallyInstalled() async {
    if (!Platform.isAndroid) return false;
    try {
      final installed = await HomeWidget.getInstalledWidgets();
      return installed.any(
        (w) => (w.androidClassName ?? '')
            .contains(HomeWidgetService.androidProviderName),
      );
    } catch (_) {
      return false;
    }
  }

  /// Soft prompt: only ask if we don't already know a widget is installed.
  static Future<void> requestPinIfNeeded() async {
    await HomeWidgetService.syncOnAppLaunch();
    if (!Platform.isAndroid) return;
    if (await _isWidgetActuallyInstalled()) {
      await WidgetPinPref.markPinPromptHandled();
      await HomeWidgetService.syncFromCache();
      return;
    }
    await _requestPin();
  }

  /// Explicit user action from Shared → always try the system pin sheet
  /// unless the widget is already installed.
  static Future<void> requestPinExplicitly() async {
    await HomeWidgetService.syncOnAppLaunch();
    if (!Platform.isAndroid) return;

    if (await _isWidgetActuallyInstalled()) {
      await WidgetPinPref.markPinPromptHandled();
      await HomeWidgetService.syncFromCache();
      return;
    }

    await _requestPin();
  }

  static Future<void> _requestPin() async {
    final supported = await HomeWidgetService.isPinSupported();
    if (supported) {
      await HomeWidgetService.requestPinWidget();
    }
  }

  /// User explicitly asked to add the widget from the app bar.
  static Future<void> addWidgetToHomeScreen(BuildContext context) async {
    if (!Platform.isAndroid) {
      if (context.mounted) await showManualAddDialog(context);
      return;
    }

    if (await _isWidgetActuallyInstalled()) {
      await HomeWidgetService.syncFromCache();
      if (context.mounted) {
        AppConstants.showToast(
          'Widget already on home screen — content refreshed',
        );
      }
      return;
    }

    await _requestPin();
    if (context.mounted) {
      AppConstants.showToast(
        'Tap Add on the system dialog to place the widget',
      );
    }
  }

  static Future<void> showManualAddDialog(BuildContext context) {
    final steps = Platform.isIOS
        ? [
            'Long-press your home screen',
            'Tap the + button',
            'Search for "Notes Widget"',
            'Add the widget',
          ]
        : [
            'Long-press home screen → Widgets',
            'Find "Notes Widget"',
            'Drag it to your home screen',
          ];

    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Add home screen widget',
          style: getSemiBoldStyle(color: AppColors.textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Android will show an "Add to home screen" prompt when supported.',
              style: getRegularStyle(color: AppColors.textColor),
            ),
            const SizedBox(height: 12),
            ...steps.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${e.key + 1}. ${e.value}',
                      style: getRegularStyle(
                        fontSize: 14,
                        color: AppColors.textColor,
                      ),
                    ),
                  ),
                ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Got it',
              style: getMediumStyle(color: AppColors.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
