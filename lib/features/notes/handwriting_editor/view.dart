import 'package:flutter/material.dart';
import 'package:noteswidgetapp/features/notes/handwriting_editor/controller.dart';
import 'package:noteswidgetapp/features/notes/handwriting_editor/widgets/handwriting_editor_body.dart';
import 'package:provider/provider.dart';

class HandwritingEditorScreen extends StatelessWidget {
  final String noteId;

  const HandwritingEditorScreen({super.key, required this.noteId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HandwritingEditorController(noteId: noteId)..load(),
      child: const HandwritingEditorBody(),
    );
  }
}
