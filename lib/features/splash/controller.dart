import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/navigation/auth_navigation.dart';
import 'package:noteswidgetapp/features/authentication/signin/view.dart';

class SplashController extends ChangeNotifier {
  Future<void> init(BuildContext context) async {
    await Future.delayed(const Duration(seconds: 2));
    if (!context.mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    await AuthNavigation.goAfterAuth(context);
  }
}
