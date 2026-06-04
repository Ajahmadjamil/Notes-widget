import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignInRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    if (kDebugMode) {
      print('Google sign-in: start');
    }

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw FirebaseAuthException(
        code: 'google-sign-in-not-supported',
        message: 'Google Sign-In is not supported on this platform.',
      );
    }

    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      if (kDebugMode) {
        print('Google sign-in: signOut before auth (ignored): $e');
      }
    }

    try {
      final account = await GoogleSignIn.instance.authenticate();
      if (kDebugMode) {
        print('Google sign-in: account ok — ${account.email}');
      }

      final googleAuth = account.authentication;
      final idToken = googleAuth.idToken;

      if (kDebugMode) {
        print(
          'Google sign-in: idToken ${idToken != null ? "received" : "MISSING — check SHA-1 + web client ID"}',
        );
      }

      if (idToken == null) {
        throw FirebaseAuthException(
          code: 'missing-google-id-token',
          message:
              'Google ID token was empty. Add your app SHA-1 in Firebase Console, enable Google sign-in, and rebuild.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await _auth.signInWithCredential(credential);

      if (kDebugMode) {
        print(
          'Google sign-in: Firebase success — uid=${userCredential.user?.uid}',
        );
      }

      return userCredential;
    } on GoogleSignInException catch (e) {
      if (kDebugMode) {
        print('Google sign-in: GoogleSignInException ${e.code} — $e');
      }
      rethrow;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Google sign-in: FirebaseAuthException ${e.code} — ${e.message}');
      }
      rethrow;
    } catch (e, stack) {
      if (kDebugMode) {
        print('Google sign-in: error $e\n$stack');
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      if (kDebugMode) {
        print('Google sign out: $e');
      }
    }
    await _auth.signOut();
  }

  static String messageFromAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'weak-password':
        return 'Password is too weak (use at least 6 characters).';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'google-sign-in-not-supported':
        return e.message ?? 'Google Sign-In is not supported.';
      case 'missing-google-id-token':
        return e.message ?? 'Google sign-in configuration is incomplete.';
      default:
        return e.message ?? 'Authentication failed (${e.code}).';
    }
  }
}
