import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:noteswidgetapp/core/supabase/app_supabase.dart';
import 'package:noteswidgetapp/features/notes/data/notes_supabase_data_source.dart';
import 'package:noteswidgetapp/features/notes/data/notes_local_db.dart';
import 'package:noteswidgetapp/features/notes/model/note.dart';
import 'package:uuid/uuid.dart';

class NotesRepository {
  final NotesLocalDb _local = NotesLocalDb.instance;
  final NotesSupabaseDataSource _remote = NotesSupabaseDataSource();
  final Connectivity _connectivity = Connectivity();
  final Uuid _uuid = const Uuid();

  String? get _uid => AppSupabase.currentUserId;

  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Pull from Supabase, push pending queue, then return local list.
  Future<void> syncIfOnline() async {
    final uid = _uid;
    if (uid == null) return;
    if (!await isOnline) return;

    await _pullFromRemote(uid);
    await _pushPending(uid);
  }

  Future<void> _pullFromRemote(String uid) async {
    final remoteNotes = await _remote.fetchAllNotes(uid);
    final pending = await _local.getPendingNotes(uid);
    final pendingIds = pending.map((n) => n.noteId).toSet();

    for (final remote in remoteNotes.values) {
      if (pendingIds.contains(remote.noteId)) continue;
      final existing = await _local.getNote(remote.noteId);
      await _local.upsert(
        remote.copyWith(isPinned: existing?.isPinned ?? false),
      );
    }
  }

  Future<void> _pushPending(String uid) async {
    final pending = await _local.getPendingNotes(uid);

    for (final note in pending) {
      switch (note.pendingSync) {
        case 'create':
        case 'update':
          await _remote.saveNote(uid, note.copyWith(clearPendingSync: true));
          await _local.upsert(note.copyWith(clearPendingSync: true));
          break;
        case 'delete':
          await _remote.deleteNote(uid, note.noteId);
          await _local.deletePermanently(note.noteId);
          break;
      }
    }
  }

  Future<List<Note>> loadNotes() async {
    final uid = _uid;
    if (uid == null) return [];
    await syncIfOnline();
    return _local.getActiveNotes(uid);
  }

  Future<Note?> getNote(String noteId) => _local.getNote(noteId);

  Future<Note> createNote({String title = '', String body = ''}) async {
    final uid = _uid!;
    final now = DateTime.now().millisecondsSinceEpoch;
    final note = Note(
      noteId: _uuid.v4(),
      ownerId: uid,
      title: title.trim().isEmpty ? 'Untitled' : title.trim(),
      body: body,
      createdAt: now,
      updatedAt: now,
      pendingSync: 'create',
    );

    await _local.upsert(note);

    if (await isOnline) {
      await _remote.saveNote(uid, note);
      await _local.upsert(note.copyWith(clearPendingSync: true));
    }

    return note;
  }

  Future<Note> updateNote(Note note, {required String title, required String body}) async {
    final uid = _uid!;
    final now = DateTime.now().millisecondsSinceEpoch;
    final pending = note.pendingSync == 'create' ? 'create' : 'update';

    final updated = note.copyWith(
      title: title.trim().isEmpty ? 'Untitled' : title.trim(),
      body: body,
      updatedAt: now,
      pendingSync: pending,
    );

    await _local.upsert(updated);

    if (await isOnline) {
      await _remote.saveNote(uid, updated);
      await _local.upsert(updated.copyWith(clearPendingSync: true));
    }

    return updated;
  }

  Future<Note> setPinned(Note note, bool pinned) async {
    final uid = _uid!;
    final now = DateTime.now().millisecondsSinceEpoch;
    final pending = note.pendingSync == 'create' ? 'create' : 'update';

    final updated = note.copyWith(
      isPinned: pinned,
      updatedAt: now,
      pendingSync: pending,
    );

    await _local.upsert(updated);

    if (await isOnline) {
      await _remote.saveNote(uid, updated);
      await _local.upsert(updated.copyWith(clearPendingSync: true));
    }

    return updated;
  }

  Future<void> deleteNote(Note note) async {
    final uid = _uid!;

    if (note.pendingSync == 'create') {
      await _local.deletePermanently(note.noteId);
      return;
    }

    final marked = note.copyWith(
      isDeleted: true,
      pendingSync: 'delete',
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _local.upsert(marked);

    if (await isOnline) {
      await _remote.deleteNote(uid, note.noteId);
      await _local.deletePermanently(note.noteId);
    }
  }
}
