import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:noteswidgetapp/core/supabase/app_supabase.dart';
import 'package:noteswidgetapp/core/supabase/schema_capabilities.dart';
import 'package:noteswidgetapp/core/sync/shared_note_sync_bus.dart';
import 'package:noteswidgetapp/core/widget/shared_note_widget_cache.dart';
import 'package:noteswidgetapp/core/notes/note_type.dart';
import 'package:noteswidgetapp/features/shared_note/model/shared_note.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SharedNoteAccessDeniedException implements Exception {
  const SharedNoteAccessDeniedException();
}

class SharedNoteRepository {
  SupabaseClient get _client => AppSupabase.client;
  String? get _myUid => AppSupabase.currentUserId;

  static const _noteSelectBase =
      'id, friendship_id, title, body, created_at, updated_at, updated_by, '
      'friendships(id, user_id, friend_id)';

  static const _drawingColumns = 'note_type, drawing_data';

  Future<String> _noteSelect() async {
    await SchemaCapabilities.ensureProbed(_client);
    if (SchemaCapabilities.drawingNotesSupported) {
      return 'id, friendship_id, title, body, $_drawingColumns, created_at, updated_at, updated_by, '
          'friendships(id, user_id, friend_id)';
    }
    return _noteSelectBase;
  }

  Map<String, dynamic> _newNotePayload({
    required String friendshipId,
    required String myUid,
  }) {
    final payload = <String, dynamic>{
      'friendship_id': friendshipId,
      'title': 'Shared note',
      'body': '',
      'updated_by': myUid,
    };
    if (SchemaCapabilities.drawingNotesSupported) {
      payload['note_type'] = NoteType.text.value;
      payload['drawing_data'] = '';
    }
    return payload;
  }

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
    await SchemaCapabilities.ensureProbed(_client);
    final select = await _noteSelect();

    final existing = await _client
        .from('shared_notes')
        .select(select)
        .eq('friendship_id', friendshipId)
        .maybeSingle();

    if (existing != null) {
      return fetchOnce(existing['id'] as String);
    }

    final inserted = await _client
        .from('shared_notes')
        .insert(_newNotePayload(friendshipId: friendshipId, myUid: myUid))
        .select(select)
        .single();

    if (kDebugMode) {
      print('Created missing shared note for friendship $friendshipId');
    }

    final note = SharedNote.fromRow(Map<String, dynamic>.from(inserted));
    _assertAccess(note);
    return note;
  }

  Future<SharedNote?> fetchOnce(String sharedNoteId) async {
    final select = await _noteSelect();
    final row = await _client
        .from('shared_notes')
        .select(select)
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

  Future<SharedNote?> changeNoteType({
    required String sharedNoteId,
    required NoteType newType,
  }) async {
    final uid = _myUid;
    if (uid == null) throw StateError('Not signed in');

    await SchemaCapabilities.ensureProbed(_client);
    if (!SchemaCapabilities.drawingNotesSupported) {
      throw StateError('Handwriting requires a Supabase database migration');
    }

    final existing = await fetchOnce(sharedNoteId);
    if (existing == null) throw StateError('Shared note not found');
    if (existing.noteType == newType) return existing;

    final payload = <String, dynamic>{
      'note_type': newType.value,
      'updated_by': uid,
    };
    if (newType == NoteType.text) {
      payload['drawing_data'] = '';
    } else {
      payload['body'] = '';
    }

    await _client.from('shared_notes').update(payload).eq('id', sharedNoteId);

    final saved = await fetchOnce(sharedNoteId);
    if (saved != null) SharedNoteSyncBus.emit(saved);
    return saved;
  }

  Future<void> setNoteType({
    required String sharedNoteId,
    required NoteType noteType,
  }) async {
    final uid = _myUid;
    if (uid == null) throw StateError('Not signed in');

    await SchemaCapabilities.ensureProbed(_client);
    if (!SchemaCapabilities.drawingNotesSupported) {
      throw StateError('Handwriting requires a Supabase database migration');
    }

    final existing = await fetchOnce(sharedNoteId);
    if (existing == null) throw StateError('Shared note not found');

    await _client.from('shared_notes').update({
      'note_type': noteType.value,
      'updated_by': uid,
    }).eq('id', sharedNoteId);

    final saved = await fetchOnce(sharedNoteId);
    if (saved != null) SharedNoteSyncBus.emit(saved);
  }

  Future<void> save({
    required String sharedNoteId,
    required String title,
    required String body,
    NoteType? noteType,
    String? drawingData,
  }) async {
    final uid = _myUid;
    if (uid == null) throw StateError('Not signed in');

    final existing = await fetchOnce(sharedNoteId);
    if (existing == null) {
      throw StateError('Shared note not found');
    }

    final trimmedTitle = title.trim().isEmpty ? 'Shared note' : title.trim();

    final payload = <String, dynamic>{
      'title': trimmedTitle,
      'body': body,
      'updated_by': uid,
    };
    await SchemaCapabilities.ensureProbed(_client);
    if (SchemaCapabilities.drawingNotesSupported) {
      if (noteType != null) payload['note_type'] = noteType.value;
      if (drawingData != null) payload['drawing_data'] = drawingData;
    } else if (noteType == NoteType.drawing || (drawingData != null && drawingData.isNotEmpty)) {
      throw StateError('Handwriting requires a Supabase database migration');
    }

    await _client.from('shared_notes').update(payload).eq('id', sharedNoteId);

    final saved = await fetchOnce(sharedNoteId);
    if (saved != null) {
      SharedNoteSyncBus.emit(saved);
    }

    final updatedAt = DateTime.now().millisecondsSinceEpoch;

    if (saved != null) {
      await SharedNoteWidgetCache.updateFromNote(saved);
    } else {
      await SharedNoteWidgetCache.update(
        sharedNoteId: sharedNoteId,
        title: trimmedTitle,
        body: body,
        updatedAt: updatedAt,
        noteType: noteType ?? NoteType.text,
        drawingData: drawingData ?? '',
      );
    }
  }

  void _assertAccess(SharedNote note) {
    final uid = _myUid;
    if (uid == null || !note.involvesUser(uid)) {
      throw const SharedNoteAccessDeniedException();
    }
  }
}
