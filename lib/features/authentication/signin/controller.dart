import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:noteswidgetapp/core/constants/app_constants.dart';
import 'package:noteswidgetapp/core/navigation/auth_navigation.dart';
import 'package:noteswidgetapp/features/authentication/signin/repository.dart';

class LoginController with ChangeNotifier {
  final SignInRepository _repo = SignInRepository();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final emailFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();

  bool isLoading = false;
  bool isSignUpMode = false;

  void toggleSignUpMode() {
    isSignUpMode = !isSignUpMode;
    notifyListeners();
  }

  Future<void> submitEmailPassword(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      AppConstants.showToast('Please enter email and password');
      if (email.isEmpty) {
        emailFocusNode.requestFocus();
      } else {
        passwordFocusNode.requestFocus();
      }
      return;
    }

    if (isSignUpMode && password.length < 6) {
      AppConstants.showToast('Password must be at least 6 characters');
      passwordFocusNode.requestFocus();
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      if (isSignUpMode) {
        await _repo.signUpWithEmail(email: email, password: password);
      } else {
        await _repo.signInWithEmail(email: email, password: password);
      }
      if (!context.mounted) return;
      await AuthNavigation.goAfterAuth(context);
    } on FirebaseAuthException catch (e) {
      AppConstants.showToast(SignInRepository.messageFromAuthException(e));
    } catch (e) {
      if (kDebugMode) print('Email auth error: $e');
      AppConstants.showToast('Authentication failed');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    try {
      await _repo.signInWithGoogle();
      if (!context.mounted) return;
      AppConstants.showToast('Google sign-in successful');
      await AuthNavigation.goAfterAuth(context);
    } on GoogleSignInException catch (e) {
      if (e.code != GoogleSignInExceptionCode.canceled) {
        final msg = e.description ?? e.code.toString();
        if (kDebugMode) print('GoogleSignInException: $msg');
        AppConstants.showToast('Google sign-in failed: $msg');
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) print('FirebaseAuthException: ${e.code} ${e.message}');
      AppConstants.showToast(SignInRepository.messageFromAuthException(e));
    } catch (e) {
      if (kDebugMode) print('Google sign-in unexpected: $e');
      AppConstants.showToast('Google sign-in failed: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }
}
