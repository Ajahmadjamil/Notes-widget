import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:noteswidgetapp/core/firebase/database_paths.dart';
import 'package:noteswidgetapp/core/firebase/firebase_database_service.dart';
import 'package:noteswidgetapp/features/profile/model/user_profile.dart';

class UsernameTakenException implements Exception {
  const UsernameTakenException();
}

class InvalidUsernameException implements Exception {
  final String message;
  const InvalidUsernameException(this.message);
}

class UserProfileRepository {
  DatabaseReference get _root => FirebaseDatabaseService.rootRef();

  static String normalizeUsername(String username) =>
      username.trim().toLowerCase();

  static bool isValidUsername(String raw) {
    final normalized = normalizeUsername(raw);
    if (normalized.length < 3 || normalized.length > 20) return false;
    return RegExp(r'^[a-z0-9_]+$').hasMatch(normalized);
  }

  Future<UserProfile?> fetchProfile(String uid) async {
    final snapshot = await _root.child(DatabasePaths.user(uid)).get();
    if (!snapshot.exists || snapshot.value == null) return null;
    final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
    return UserProfile.fromSnapshot(uid, data);
  }

  Future<bool> needsUsernameSetup(String uid) async {
    final profile = await fetchProfile(uid);
    return profile == null || !profile.hasUsername;
  }

  /// Creates a minimal profile for new sign-ins (username set later).
  Future<void> ensureProfileExists(User authUser) async {
    final uid = authUser.uid;
    final userRef = _root.child(DatabasePaths.user(uid));
    final snapshot = await userRef.get();
    if (snapshot.exists) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final data = <String, dynamic>{
      'email': authUser.email?.trim().toLowerCase(),
      'displayName': authUser.displayName,
      'createdAt': now,
      'updatedAt': now,
    };
    if (authUser.photoURL != null) {
      data['photoUrl'] = authUser.photoURL;
    }
    await userRef.set(data);
  }

  /// Writes /usernames and /emails indexes from an existing profile (repair).
  Future<void> repairSearchIndexes(String uid) async {
    final profile = await fetchProfile(uid);
    if (profile == null || !profile.hasUsername) return;

    final normalized = normalizeUsername(profile.username!);
    await _root.child(DatabasePaths.usernameIndex(normalized)).set(uid);

    final email = profile.email != null && profile.email!.isNotEmpty
        ? DatabasePaths.normalizeEmail(profile.email!)
        : null;
    if (email != null) {
      try {
        await _root.child(DatabasePaths.emailIndex(email)).set(uid);
      } catch (e) {
        if (kDebugMode) {
          print('repairSearchIndexes email index skipped: $e');
        }
      }
    }
  }

  /// Claims a unique username and completes the user profile indexes.
  Future<void> claimUsername({
    required User authUser,
    required String username,
  }) async {
    final trimmed = username.trim();
    if (!isValidUsername(trimmed)) {
      throw const InvalidUsernameException(
        'Username must be 3–20 characters: letters, numbers, underscore only.',
      );
    }

    final uid = authUser.uid;
    final normalized = normalizeUsername(trimmed);

    final existingProfile = await fetchProfile(uid);
    if (existingProfile != null &&
        existingProfile.hasUsername &&
        normalizeUsername(existingProfile.username!) == normalized) {
      await repairSearchIndexes(uid);
      return;
    }

    final usernameRef = _root.child(DatabasePaths.usernameIndex(normalized));

    final transaction = await usernameRef.runTransaction((current) {
      if (current != null && current.toString() != uid) {
        return Transaction.abort();
      }
      return Transaction.success(uid);
    });

    if (!transaction.committed) {
      throw const UsernameTakenException();
    }

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final email = authUser.email != null && authUser.email!.isNotEmpty
          ? DatabasePaths.normalizeEmail(authUser.email!)
          : null;

      final updates = <String, dynamic>{
        'username': trimmed,
        'displayName': authUser.displayName ?? trimmed,
        'updatedAt': now,
      };
      if (email != null) updates['email'] = email;
      if (authUser.photoURL != null) {
        updates['photoUrl'] = authUser.photoURL;
      }

      final userRef = _root.child(DatabasePaths.user(uid));
      final userSnap = await userRef.get();
      if (!userSnap.exists) {
        updates['createdAt'] = now;
        await userRef.set(updates);
      } else {
        await userRef.update(updates);
      }

      // Email index is optional — do not fail username save if rules block /emails.
      if (email != null && email.isNotEmpty) {
        try {
          await _root.child(DatabasePaths.emailIndex(email)).set(uid);
        } catch (e) {
          if (kDebugMode) {
            print('claimUsername: email index not written ($e). Search by email may use fallback.');
          }
        }
      }
    } catch (e) {
      try {
        final indexSnap = await usernameRef.get();
        if (indexSnap.exists && indexSnap.value?.toString() == uid) {
          await usernameRef.remove();
        }
      } catch (_) {}
      rethrow;
    }
  }
}
