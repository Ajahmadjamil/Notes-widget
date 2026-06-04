import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:noteswidgetapp/core/supabase/app_supabase.dart';
import 'package:noteswidgetapp/core/sync/shared_note_sync_bus.dart';
import 'package:noteswidgetapp/core/widget/shared_note_widget_cache.dart';
import 'package:noteswidgetapp/features/shared_note/model/shared_note.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SharedNoteAccessDeniedException implements Exception {
  const SharedNoteAccessDeniedException();
}

class SharedNoteRepository {
  SupabaseClient get _client => AppSupabase.client;
  String? get _myUid => AppSupabase.currentUserId;

  static const _noteSelect =
      'id, friendship_id, title, body, created_at, updated_at, updated_by, '
      'friendships(id, user_id, friend_id)';

  Future<SharedNote?> resolveAndFetch({
    required String preferredId,
    String? friendUid,
  }) async {
    final ids = await _candidateNoteIds(
      preferredId: preferredId,
      friendUid: friendUid,
    );

    for (final id in ids) {
      try {
        final note = await fetchOnce(id);
        if (note != null) return note;
      } on SharedNoteAccessDeniedException {
        if (kDebugMode) print('Shared note access denied for $id');
      }
    }

    if (friendUid != null && _myUid != null) {
      return _ensureSharedNoteForFriend(_myUid!, friendUid);
    }

    return null;
  }

  Future<List<String>> _candidateNoteIds({
    required String preferredId,
    String? friendUid,
  }) async {
    final uid = _myUid;
    final ids = <String>[];

    if (uid != null && friendUid != null) {
      final noteId = await _noteIdForFriendPair(uid, friendUid);
      if (noteId != null && noteId.isNotEmpty) ids.add(noteId);
    }

    if (preferredId.isNotEmpty) ids.add(preferredId);
    return ids.toSet().toList();
  }

  Future<String?> _noteIdForFriendPair(String myUid, String friendUid) async {
    final friendship = await _friendshipRow(myUid, friendUid);
    if (friendship == null) return null;

    final note = await _client
        .from('shared_notes')
        .select('id')
        .eq('friendship_id', friendship['id'] as String)
        .maybeSingle();

    return note?['id'] as String?;
  }

  Future<Map<String, dynamic>?> _friendshipRow(
    String myUid,
    String friendUid,
  ) async {
    final row = await _client
        .from('friendships')
        .select('id')
        .eq('status', 'accepted')
        .or('and(user_id.eq.$myUid,friend_id.eq.$friendUid),and(user_id.eq.$friendUid,friend_id.eq.$myUid)')
        .maybeSingle();
    if (row == null) return null;
    return Map<String, dynamic>.from(row);
  }

  Future<SharedNote?> _ensureSharedNoteForFriend(
    String myUid,
    String friendUid,
  ) async {
    final friendship = await _friendshipRow(myUid, friendUid);
    if (friendship == null) return null;

    final friendshipId = friendship['id'] as String;
    final existing = await _client
        .from('shared_notes')
        .select(_noteSelect)
        .eq('friendship_id', friendshipId)
        .maybeSingle();

    if (existing != null) {
      return fetchOnce(existing['id'] as String);
    }

    final inserted = await _client
        .from('shared_notes')
        .insert({
          'friendship_id': friendshipId,
          'title': 'Shared note',
          'body': '',
          'updated_by': myUid,
        })
        .select(_noteSelect)
        .single();

    if (kDebugMode) {
      print('Created missing shared note for friendship $friendshipId');
    }

    final note = SharedNote.fromRow(Map<String, dynamic>.from(inserted));
    _assertAccess(note);
    return note;
  }

  Future<SharedNote?> fetchOnce(String sharedNoteId) async {
    final row = await _client
        .from('shared_notes')
        .select(_noteSelect)
        .eq('id', sharedNoteId)
        .maybeSingle();

    if (row == null) return null;

    final note = SharedNote.fromRow(Map<String, dynamic>.from(row));
    _assertAccess(note);
    return note;
  }

  Stream<SharedNote?> watch(String sharedNoteId) {
    final controller = StreamController<SharedNote?>();
    RealtimeChannel? channel;

    Future<void> emitLatest() async {
      try {
        final note = await fetchOnce(sharedNoteId);
        if (note != null && !controller.isClosed) {
          SharedNoteSyncBus.emit(note);
          controller.add(note);
        }
      } catch (_) {
        if (!controller.isClosed) controller.add(null);
      }
    }

    channel = _client.channel('shared_note_watch:$sharedNoteId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'shared_notes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: sharedNoteId,
          ),
          callback: (_) => emitLatest(),
        )
        .subscribe();

    emitLatest();

    final ch = channel;
    controller.onCancel = () async {
      if (ch != null) {
        await _client.removeChannel(ch);
      }
    };

    return controller.stream;
  }

  Future<void> save({
    required String sharedNoteId,
    required String title,
    required String body,
  }) async {
    final uid = _myUid;
    if (uid == null) throw StateError('Not signed in');

    final existing = await fetchOnce(sharedNoteId);
    if (existing == null) {
      throw StateError('Shared note not found');
    }

    final trimmedTitle = title.trim().isEmpty ? 'Shared note' : title.trim();

    await _client.from('shared_notes').update({
      'title': trimmedTitle,
      'body': body,
      'updated_by': uid,
    }).eq('id', sharedNoteId);

    final saved = await fetchOnce(sharedNoteId);
    if (saved != null) {
      SharedNoteSyncBus.emit(saved);
    }

    final updatedAt = DateTime.now().millisecondsSinceEpoch;

    await SharedNoteWidgetCache.update(
      sharedNoteId: sharedNoteId,
      title: trimmedTitle,
      body: body,
      updatedAt: updatedAt,
    );
  }

  void _assertAccess(SharedNote note) {
    final uid = _myUid;
    if (uid == null || !note.involvesUser(uid)) {
      throw const SharedNoteAccessDeniedException();
    }
  }
}
