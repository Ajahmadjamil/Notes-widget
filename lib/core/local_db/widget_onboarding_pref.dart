import 'package:shared_preferences/shared_preferences.dart';

class WidgetOnboardingPref {
  WidgetOnboardingPref._();

  static const _keyHasSeen = 'has_seen_widget_onboarding';

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasSeen) ?? false;
  }

  static Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasSeen, true);
  }
}
