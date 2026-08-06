import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/notes/note_type.dart';
import 'package:noteswidgetapp/core/shared/widgets/note_type_picker_sheet.dart';
import 'package:noteswidgetapp/core/supabase/schema_capabilities.dart';
import 'package:noteswidgetapp/features/shared_note/collab_editor/view.dart';
import 'package:noteswidgetapp/features/shared_note/handwriting_editor/view.dart';
import 'package:noteswidgetapp/features/shared_note/model/shared_note.dart';
import 'package:noteswidgetapp/features/shared_note/repository/shared_note_repository.dart';

/// Resolves a shared note and decides which editor to open.
class SharedNoteEntryController with ChangeNotifier {
  SharedNoteEntryController({
    required this.sharedNoteId,
    required this.friendLabel,
    this.friendUid,
  });

  final String sharedNoteId;
  final String friendLabel;
  final String? friendUid;

  final _repo = SharedNoteRepository();

  bool isLoading = true;
  String? error;
  bool _disposed = false;

  Future<void> resolve(BuildContext context) async {
    isLoading = true;
    error = null;
    _notify();

    SharedNote? note;
    for (var attempt = 0; attempt < 3; attempt++) {
      note = await _repo.resolveAndFetch(
        preferredId: sharedNoteId,
        friendUid: friendUid,
      );
      if (note != null) break;
      if (attempt < 2) {
        await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
      }
    }

    if (_disposed) return;

    if (note == null) {
      isLoading = false;
      error = 'Shared note could not be loaded.';
      _notify();
      return;
    }

    if (note.isUnset) {
      if (!context.mounted) return;
      final type = await NoteTypePickerSheet.show(
        context,
        title: 'Shared note type',
        subtitle: 'Choose text, document, or handwriting',
      );
      if (!context.mounted) return;
      if (type == null) {
        Navigator.of(context).pop();
        return;
      }

      if (type == NoteType.drawing &&
          !SchemaCapabilities.drawingNotesSupported) {
        // Fall through as text if migration missing.
      } else if (type == NoteType.document &&
          !SchemaCapabilities.documentNotesSupported) {
        // Fall through as text if migration missing.
      } else {
        await _repo.setNoteType(
          sharedNoteId: note.sharedNoteId,
          noteType: type,
        );
        note = await _repo.fetchOnce(note.sharedNoteId) ??
            note.copyWith(noteType: type);
      }
    }

    if (!context.mounted || _disposed) return;
    openEditor(context, note);
  }

  void openEditor(BuildContext context, SharedNote note) {
    final Widget screen;
    if (note.noteType == NoteType.drawing) {
      screen = SharedHandwritingEditorScreen(
        sharedNoteId: note.sharedNoteId,
        friendLabel: friendLabel,
        friendUid: friendUid,
      );
    } else {
      screen = SharedCollabEditorScreen(
        sharedNoteId: note.sharedNoteId,
        friendLabel: friendLabel,
        friendUid: friendUid,
        textOnly: note.noteType != NoteType.document,
      );
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
