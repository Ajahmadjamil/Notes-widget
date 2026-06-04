import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/local_db/widget_onboarding_pref.dart';
import 'package:noteswidgetapp/features/authentication/signin/view.dart';
import 'package:noteswidgetapp/features/home/view.dart';
import 'package:noteswidgetapp/features/profile/repository/user_profile_repository.dart';
import 'package:noteswidgetapp/features/profile/username_setup/view.dart';
import 'package:noteswidgetapp/core/sync/push_sync_service.dart';
import 'package:noteswidgetapp/features/widget_onboarding/view.dart';

class AuthNavigation {
  AuthNavigation._();

  static Future<void> goAfterAuth(BuildContext context) async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      _replaceWith(context, const LoginScreen());
      return;
    }

    final repo = UserProfileRepository();
    try {
      await repo.ensureProfileExists(authUser);
      await repo.repairSearchIndexes(authUser.uid);
      await PushSyncService.initialize();
    } catch (e) {
      if (kDebugMode) {
        print('goAfterAuth profile setup: $e');
      }
    }

    final needsUsername = await repo.needsUsernameSetup(authUser.uid);

    if (!context.mounted) return;

    if (needsUsername) {
      _replaceWith(context, const UsernameSetupScreen());
      return;
    }

    final seenWidgetOnboarding = await WidgetOnboardingPref.hasSeenOnboarding();
    if (!context.mounted) return;

    _replaceWith(
      context,
      seenWidgetOnboarding ? const HomeScreen() : const WidgetOnboardingScreen(),
    );
  }

  static void _replaceWith(BuildContext context, Widget screen) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screen),
      (_) => false,
    );
  }
}
