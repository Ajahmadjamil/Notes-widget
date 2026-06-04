import 'package:firebase_database/firebase_database.dart';
import 'package:noteswidgetapp/core/firebase/database_paths.dart';
import 'package:noteswidgetapp/core/firebase/firebase_database_service.dart';
import 'package:noteswidgetapp/features/notes/model/note.dart';

class NotesFirebaseDataSource {
  DatabaseReference get _root => FirebaseDatabaseService.rootRef();

  Future<Map<String, Note>> fetchAllNotes(String uid) async {
    final snapshot = await _root.child(DatabasePaths.notes(uid)).get();
    if (!snapshot.exists || snapshot.value == null) {
      return {};
    }

    final raw = Map<dynamic, dynamic>.from(snapshot.value as Map);
    final result = <String, Note>{};

    for (final entry in raw.entries) {
      final noteId = entry.key as String;
      final data = Map<dynamic, dynamic>.from(entry.value as Map);
      result[noteId] = Note.fromFirebase(noteId, data);
    }
    return result;
  }

  Future<void> saveNote(String uid, Note note) async {
    await _root.child(DatabasePaths.note(uid, note.noteId)).set(note.toFirebaseMap());
  }

  Future<void> deleteNote(String uid, String noteId) async {
    await _root.child(DatabasePaths.note(uid, noteId)).remove();
  }
}
