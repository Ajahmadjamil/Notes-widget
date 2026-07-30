import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/notes/note_type.dart';
import 'package:noteswidgetapp/core/shared/widgets/note_type_picker_sheet.dart';
import 'package:noteswidgetapp/core/supabase/schema_capabilities.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/features/shared_note/collab_editor/view.dart';
import 'package:noteswidgetapp/features/shared_note/handwriting_editor/view.dart';
import 'package:noteswidgetapp/features/shared_note/model/shared_note.dart';
import 'package:noteswidgetapp/features/shared_note/repository/shared_note_repository.dart';

/// Resolves a shared note and routes to text, document, or handwriting editor.
class SharedNoteEntryScreen extends StatefulWidget {
  final String sharedNoteId;
  final String friendLabel;
  final String? friendUid;

  const SharedNoteEntryScreen({
    super.key,
    required this.sharedNoteId,
    required this.friendLabel,
    this.friendUid,
  });

  @override
  State<SharedNoteEntryScreen> createState() => _SharedNoteEntryScreenState();
}

class _SharedNoteEntryScreenState extends State<SharedNoteEntryScreen> {
  final _repo = SharedNoteRepository();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    SharedNote? note;
    for (var attempt = 0; attempt < 3; attempt++) {
      note = await _repo.resolveAndFetch(
        preferredId: widget.sharedNoteId,
        friendUid: widget.friendUid,
      );
      if (note != null) break;
      if (attempt < 2) {
        await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
      }
    }

    if (!mounted) return;

    if (note == null) {
      setState(() {
        _loading = false;
        _error = 'Shared note could not be loaded.';
      });
      return;
    }

    if (note.isUnset) {
      final type = await NoteTypePickerSheet.show(
        context,
        title: 'Shared note type',
        subtitle: 'Choose text, document, or handwriting',
      );
      if (!mounted) return;
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

    if (!mounted) return;
    _openEditor(note);
  }

  void _openEditor(SharedNote note) {
    final Widget screen;
    if (note.noteType == NoteType.drawing) {
      screen = SharedHandwritingEditorScreen(
        sharedNoteId: note.sharedNoteId,
        friendLabel: widget.friendLabel,
        friendUid: widget.friendUid,
      );
    } else {
      screen = SharedCollabEditorScreen(
        sharedNoteId: note.sharedNoteId,
        friendLabel: widget.friendLabel,
        friendUid: widget.friendUid,
        textOnly: note.noteType != NoteType.document,
      );
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: Center(
        child: _loading
            ? CircularProgressIndicator(color: AppColors.selectedColor)
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center),
                  )
                : const SizedBox.shrink(),
      ),
    );
  }
}
