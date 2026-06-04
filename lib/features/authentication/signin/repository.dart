import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:noteswidgetapp/core/supabase/app_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignInRepository {
  SupabaseClient get _client => AppSupabase.client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> authStateChanges() => _client.auth.onAuthStateChange;

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> signInWithGoogle() async {
    if (kDebugMode) {
      print('Google sign-in: start');
    }

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw AuthException(
        'Google Sign-In is not supported on this platform.',
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
          'Google sign-in: idToken ${idToken != null ? "received" : "MISSING"}',
        );
      }

      if (idToken == null) {
        throw AuthException(
          'Google ID token was empty. Enable Google in Supabase Auth and check SHA-1 / web client ID.',
        );
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      if (kDebugMode) {
        print('Google sign-in: Supabase success — uid=${response.user?.id}');
      }

      return response;
    } on GoogleSignInException catch (e) {
      if (kDebugMode) {
        print('Google sign-in: GoogleSignInException ${e.code} — $e');
      }
      rethrow;
    } on AuthException catch (e) {
      if (kDebugMode) {
        print('Google sign-in: AuthException — ${e.message}');
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
    await _client.auth.signOut();
  }

  static String messageFromAuthException(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'Invalid email or password.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please confirm your email before signing in.';
    }
    if (msg.contains('user already registered')) {
      return 'An account already exists for this email.';
    }
    if (msg.contains('password')) {
      return e.message;
    }
    return e.message;
  }
}
