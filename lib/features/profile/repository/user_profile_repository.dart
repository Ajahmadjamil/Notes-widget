import 'package:flutter/foundation.dart';
import 'package:noteswidgetapp/core/supabase/app_supabase.dart';
import 'package:noteswidgetapp/features/profile/model/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsernameTakenException implements Exception {
  const UsernameTakenException();
}

class InvalidUsernameException implements Exception {
  final String message;
  const InvalidUsernameException(this.message);
}

class UserProfileRepository {
  SupabaseClient get _client => AppSupabase.client;

  static String normalizeUsername(String username) =>
      username.trim().toLowerCase();

  static bool isValidUsername(String raw) {
    final normalized = normalizeUsername(raw);
    if (normalized.length < 3 || normalized.length > 20) return false;
    return RegExp(r'^[a-z0-9_]+$').hasMatch(normalized);
  }

  Future<UserProfile?> fetchProfile(String uid) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', uid)
        .maybeSingle();
    if (data == null) return null;
    return UserProfile.fromRow(uid, Map<String, dynamic>.from(data));
  }

  Future<bool> needsUsernameSetup(String uid) async {
    final profile = await fetchProfile(uid);
    return profile == null || !profile.hasUsername;
  }

  /// Ensures profile row exists (trigger usually creates it on sign-up).
  Future<void> ensureProfileExists(User authUser) async {
    final existing = await fetchProfile(authUser.id);
    if (existing != null) return;

    final email = authUser.email?.trim().toLowerCase();
    await _client.from('profiles').upsert({
      'id': authUser.id,
      if (email != null) 'email': email,
      'display_name': authUser.userMetadata?['full_name'] ??
          authUser.userMetadata?['name'] ??
          authUser.email,
      'photo_url': authUser.userMetadata?['avatar_url'],
    });
  }

  /// No-op: Postgres unique indexes replace RTDB search indexes.
  Future<void> repairSearchIndexes(String uid) async {}

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

    final uid = authUser.id;
    final normalized = normalizeUsername(trimmed);

    final existingProfile = await fetchProfile(uid);
    if (existingProfile != null &&
        existingProfile.hasUsername &&
        normalizeUsername(existingProfile.username!) == normalized) {
      return;
    }

    final email = authUser.email != null && authUser.email!.isNotEmpty
        ? authUser.email!.trim().toLowerCase()
        : null;

    try {
      await _client.from('profiles').upsert({
        'id': uid,
        'username': normalized,
        'display_name': authUser.userMetadata?['full_name'] ??
            authUser.userMetadata?['name'] ??
            trimmed,
        if (email != null) 'email': email,
        if (authUser.userMetadata?['avatar_url'] != null)
          'photo_url': authUser.userMetadata!['avatar_url'],
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505' && (e.message.contains('username') == true)) {
        throw const UsernameTakenException();
      }
      if (kDebugMode) {
        print('claimUsername PostgrestException: ${e.code} ${e.message}');
      }
      rethrow;
    }
  }
}
