import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/local_db/widget_onboarding_pref.dart';
import 'package:noteswidgetapp/core/local_db/widget_pin_pref.dart';
import 'package:noteswidgetapp/core/widget/widget_setup_helper.dart';
import 'package:noteswidgetapp/features/home/view.dart';

class WidgetOnboardingController with ChangeNotifier {
  bool isLoading = false;

  Future<void> addWidget(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    try {
      await WidgetSetupHelper.addWidgetToHomeScreen(context);
      await WidgetPinPref.markPinPromptHandled();
      await _finish(context);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> skip(BuildContext context) async {
    await _finish(context);
  }

  Future<void> _finish(BuildContext context) async {
    await WidgetOnboardingPref.markOnboardingSeen();
    await WidgetPinPref.markPinPromptHandled();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }
}
