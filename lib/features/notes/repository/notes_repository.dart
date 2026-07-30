import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:noteswidgetapp/core/media/note_media_storage.dart';
import 'package:noteswidgetapp/core/notes/document_data.dart';
import 'package:noteswidgetapp/core/supabase/app_supabase.dart';
import 'package:noteswidgetapp/features/notes/data/notes_supabase_data_source.dart';
import 'package:noteswidgetapp/features/notes/data/notes_local_db.dart';
import 'package:noteswidgetapp/core/notes/note_type.dart';
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
      // Keep local media paths when remote has the same storage paths.
      final merged = _mergeDocumentLocalPaths(existing, remote);
      await _local.upsert(
        merged.copyWith(
          isPinned: existing?.isPinned ?? false,
        ),
      );
    }
  }

  Note _mergeDocumentLocalPaths(Note? local, Note remote) {
    if (local == null || !remote.isDocument) return remote;
    final localDoc = local.document;
    final remoteDoc = remote.document;
    if (localDoc.blocks.isEmpty || remoteDoc.blocks.isEmpty) return remote;

    final byId = {for (final b in localDoc.blocks) b.id: b};
    final mergedBlocks = remoteDoc.blocks.map((rb) {
      final lb = byId[rb.id];
      if (lb == null) return rb;
      if (lb.localPath.isNotEmpty &&
          rb.storagePath == lb.storagePath &&
          File(lb.localPath).existsSync()) {
        return rb.copyWith(localPath: lb.localPath);
      }
      return rb;
    }).toList();

    return remote.copyWith(
      documentData: DocumentData(blocks: mergedBlocks).encode(),
    );
  }

  Future<void> _pushPending(String uid) async {
    final pending = await _local.getPendingNotes(uid);

    for (final note in pending) {
      switch (note.pendingSync) {
        case 'create':
        case 'update':
          final prepared = await _uploadPendingMedia(note);
          await _remote.saveNote(uid, prepared.copyWith(clearPendingSync: true));
          await _local.upsert(prepared.copyWith(clearPendingSync: true));
          break;
        case 'delete':
          await _deleteNoteMedia(note);
          await _remote.deleteNote(uid, note.noteId);
          await _local.deletePermanently(note.noteId);
          break;
      }
    }
  }

  Future<Note> _uploadPendingMedia(Note note) async {
    if (!note.isDocument) return note;
    final doc = note.document;
    var changed = false;
    final blocks = <DocumentBlock>[];

    for (final block in doc.blocks) {
      if (!block.needsUpload) {
        blocks.add(block);
        continue;
      }
      final file = File(block.localPath);
      if (!await file.exists()) {
        blocks.add(block);
        continue;
      }
      try {
        final path = await NoteMediaStorage.uploadFile(
          ownerId: note.ownerId,
          noteId: note.noteId,
          file: file,
          mimeType: block.mimeType.isNotEmpty
              ? block.mimeType
              : (block.type == DocumentBlockType.audio
                  ? 'audio/mp4'
                  : 'image/jpeg'),
        );
        blocks.add(block.copyWith(storagePath: path));
        changed = true;
      } catch (_) {
        blocks.add(block);
      }
    }

    if (!changed) return note;
    return note.copyWith(documentData: DocumentData(blocks: blocks).encode());
  }

  Future<void> _deleteNoteMedia(Note note) async {
    if (!note.isDocument) return;
    final paths = note.document.blocks
        .map((b) => b.storagePath)
        .where((p) => p.isNotEmpty);
    await NoteMediaStorage.deleteMany(paths);
  }

  Future<List<Note>> loadNotes() async {
    final uid = _uid;
    if (uid == null) return [];
    await syncIfOnline();
    return _local.getActiveNotes(uid);
  }

  Future<Note?> getNote(String noteId) => _local.getNote(noteId);

  Future<Note> createNote({
    String title = '',
    String body = '',
    NoteType noteType = NoteType.text,
  }) async {
    final uid = _uid!;
    final now = DateTime.now().millisecondsSinceEpoch;
    final defaultTitle = switch (noteType) {
      NoteType.drawing => 'Handwritten note',
      NoteType.document => 'Document',
      NoteType.text => 'Untitled',
    };
    final note = Note(
      noteId: _uuid.v4(),
      ownerId: uid,
      title: title.trim().isEmpty ? defaultTitle : title.trim(),
      body: body,
      createdAt: now,
      updatedAt: now,
      pendingSync: 'create',
      noteType: noteType,
      documentData: noteType == NoteType.document
          ? DocumentData(blocks: [
              DocumentBlock(
                id: _uuid.v4(),
                type: DocumentBlockType.text,
              ),
            ]).encode()
          : '',
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

  Future<Note> updateDrawing(Note note, {required String drawingData, String? title}) async {
    final uid = _uid!;
    final now = DateTime.now().millisecondsSinceEpoch;
    final pending = note.pendingSync == 'create' ? 'create' : 'update';

    final updated = note.copyWith(
      title: title?.trim().isNotEmpty == true ? title!.trim() : note.title,
      drawingData: drawingData,
      noteType: NoteType.drawing,
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

  Future<Note> updateDocument(
    Note note, {
    required String documentData,
    String? title,
    String? bodyPreview,
  }) async {
    final uid = _uid!;
    final now = DateTime.now().millisecondsSinceEpoch;
    final pending = note.pendingSync == 'create' ? 'create' : 'update';

    var updated = note.copyWith(
      title: title?.trim().isNotEmpty == true
          ? title!.trim()
          : (note.title.trim().isEmpty ? 'Document' : note.title),
      body: bodyPreview ?? note.body,
      documentData: documentData,
      noteType: NoteType.document,
      updatedAt: now,
      pendingSync: pending,
    );

    await _local.upsert(updated);

    if (await isOnline) {
      updated = await _uploadPendingMedia(updated);
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
      await _deleteNoteMedia(note);
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
      await _deleteNoteMedia(note);
      await _remote.deleteNote(uid, note.noteId);
      await _local.deletePermanently(note.noteId);
    }
  }
}
