import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/notes/note_type.dart';
import 'package:noteswidgetapp/features/notes/document_editor/view.dart';
import 'package:noteswidgetapp/features/notes/handwriting_editor/view.dart';
import 'package:noteswidgetapp/features/notes/model/note.dart';
import 'package:noteswidgetapp/features/notes/note_editor/view.dart';
import 'package:noteswidgetapp/features/shared_note/entry/shared_note_entry_screen.dart';

class NoteEditorLauncher {
  NoteEditorLauncher._();

  static Future<void> openPersonal(BuildContext context, Note note) {
    if (note.noteType == NoteType.drawing) {
      return Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => HandwritingEditorScreen(noteId: note.noteId),
        ),
      );
    }
    if (note.noteType == NoteType.document) {
      return Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DocumentEditorScreen(noteId: note.noteId),
        ),
      );
    }
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NoteEditorScreen(noteId: note.noteId)),
    );
  }

  static Future<void> openShared({
    required BuildContext context,
    required String sharedNoteId,
    required String friendLabel,
    String? friendUid,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SharedNoteEntryScreen(
          key: ValueKey('entry_${friendUid ?? ''}_$sharedNoteId'),
          sharedNoteId: sharedNoteId,
          friendLabel: friendLabel,
          friendUid: friendUid,
        ),
      ),
    );
  }
}
