import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:noteswidgetapp/core/firebase/database_paths.dart';
import 'package:noteswidgetapp/core/firebase/firebase_database_service.dart';
import 'package:noteswidgetapp/core/widget/shared_note_widget_cache.dart';
import 'package:noteswidgetapp/core/widget/widget_sync_policy.dart';
import 'package:noteswidgetapp/features/friends/repository/friends_repository.dart';
import 'package:noteswidgetapp/features/shared_note/model/shared_note.dart';

/// Listens to friend shared notes while the app process is alive (foreground/background).
class SharedNoteRealtimeService {
  SharedNoteRealtimeService._();
  static final SharedNoteRealtimeService instance = SharedNoteRealtimeService._();

  final Map<String, StreamSubscription<DatabaseEvent>> _subs = {};
  final FriendsRepository _friendsRepo = FriendsRepository();

  bool _running = false;

  Future<void> start() async {
    if (_running) return;
    _running = true;
    await _reloadListeners();
  }

  Future<void> stop() async {
    _running = false;
    for (final sub in _subs.values) {
      await sub.cancel();
    }
    _subs.clear();
  }

  Future<void> refresh() async {
    if (!_running) return;
    await _reloadListeners();
  }

  Future<void> _reloadListeners() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final friends = await _friendsRepo.fetchFriends();
    final activeIds = friends
        .where((f) => f.sharedNoteId.isNotEmpty)
        .map((f) => f.sharedNoteId)
        .toSet();

    for (final id in _subs.keys.toList()) {
      if (!activeIds.contains(id)) {
        await _subs[id]?.cancel();
        _subs.remove(id);
      }
    }

    for (final friend in friends) {
      if (friend.sharedNoteId.isEmpty) continue;
      if (_subs.containsKey(friend.sharedNoteId)) continue;

      final ref = FirebaseDatabaseService.rootRef()
          .child(DatabasePaths.sharedNote(friend.sharedNoteId));

      _subs[friend.sharedNoteId] = ref.onValue.listen((event) async {
        if (!event.snapshot.exists || event.snapshot.value == null) return;

        final note = SharedNote.fromSnapshot(
          friend.sharedNoteId,
          Map<dynamic, dynamic>.from(event.snapshot.value as Map),
        );

        if (!note.involvesUser(uid)) return;

        if (!await WidgetSyncPolicy.shouldUpdateHomeWidget(note.sharedNoteId)) {
          return;
        }

        if (kDebugMode) {
          print('Realtime widget sync: ${note.sharedNoteId} by ${note.updatedBy}');
        }

        await SharedNoteWidgetCache.update(
          sharedNoteId: note.sharedNoteId,
          title: note.title,
          body: note.body,
          updatedAt: note.updatedAt,
          friendLabel: friend.displayLabel,
        );
      });
    }
  }
}
