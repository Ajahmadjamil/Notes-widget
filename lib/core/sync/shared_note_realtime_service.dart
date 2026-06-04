import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:noteswidgetapp/core/supabase/app_supabase.dart';
import 'package:noteswidgetapp/core/sync/shared_note_inbound_sync.dart';
import 'package:noteswidgetapp/core/widget/active_widget_note_service.dart';
import 'package:noteswidgetapp/features/friends/repository/friends_repository.dart';
import 'package:noteswidgetapp/features/shared_note/repository/shared_note_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Realtime (Postgres changes) for shared notes while the app is alive.
class SharedNoteRealtimeService {
  SharedNoteRealtimeService._();
  static final SharedNoteRealtimeService instance = SharedNoteRealtimeService._();

  RealtimeChannel? _channel;
  final FriendsRepository _friendsRepo = FriendsRepository();
  final SharedNoteRepository _notesRepo = SharedNoteRepository();
  final Map<String, String> _noteIdToFriendLabel = {};
  final Set<String> _trackedNoteIds = {};

  bool _running = false;

  Future<void> start() async {
    if (_running) return;
    _running = true;
    await _subscribe();
    await SharedNoteInboundSync.syncActiveWidgetNote();
  }

  Future<void> stop() async {
    _running = false;
    if (_channel != null) {
      await AppSupabase.client.removeChannel(_channel!);
      _channel = null;
    }
    _noteIdToFriendLabel.clear();
    _trackedNoteIds.clear();
  }

  Future<void> refresh() async {
    if (!_running) return;
    await _reloadTrackedNotes();
    await _subscribe();
    await SharedNoteInboundSync.syncActiveWidgetNote();
  }

  Future<void> _reloadTrackedNotes() async {
    _noteIdToFriendLabel.clear();
    _trackedNoteIds.clear();

    final uid = AppSupabase.currentUserId;
    if (uid == null) return;

    final friends = await _friendsRepo.fetchFriends();
    for (final f in friends) {
      if (f.sharedNoteId.isEmpty) continue;
      _trackedNoteIds.add(f.sharedNoteId);
      _noteIdToFriendLabel[f.sharedNoteId] = f.displayLabel;
    }

    final activeId = await ActiveWidgetNoteService.getActiveNoteId();
    if (activeId != null && activeId.isNotEmpty) {
      _trackedNoteIds.add(activeId);
    }

    if (kDebugMode) {
      print('Realtime: tracking ${_trackedNoteIds.length} shared note(s)');
    }
  }

  Future<void> _subscribe() async {
    final uid = AppSupabase.currentUserId;
    if (uid == null) return;

    await _reloadTrackedNotes();

    if (_channel != null) {
      await AppSupabase.client.removeChannel(_channel!);
      _channel = null;
    }

    _channel = AppSupabase.client.channel('shared_notes_live');

    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'shared_notes',
          callback: (payload) => _onNoteChanged(payload),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'shared_notes',
          callback: (payload) => _onNoteChanged(payload),
        )
        .subscribe((status, [error]) {
          if (kDebugMode) {
            print('Realtime channel status: $status ${error ?? ''}');
          }
        });
  }

  Future<void> _onNoteChanged(PostgresChangePayload payload) async {
    if (!_running) return;

    final record = payload.newRecord;
    final noteId = record['id'] as String?;
    if (noteId == null || noteId.isEmpty) return;

    if (_trackedNoteIds.isNotEmpty && !_trackedNoteIds.contains(noteId)) {
      return;
    }
    if (_trackedNoteIds.isEmpty) {
      return;
    }

    try {
      final note = await _notesRepo.fetchOnce(noteId);
      if (note == null) return;

      if (kDebugMode) {
        print('Realtime postgres change: $noteId by ${note.updatedBy}');
      }

      await SharedNoteInboundSync.apply(
        note,
        friendLabel: _noteIdToFriendLabel[noteId] ?? '',
      );
    } catch (e) {
      if (kDebugMode) print('Realtime _onNoteChanged error: $e');
    }
  }
}
