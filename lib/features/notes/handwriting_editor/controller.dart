import 'dart:async';

import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/constants/app_constants.dart';
import 'package:noteswidgetapp/core/notes/drawing_data.dart';
import 'package:noteswidgetapp/features/notes/model/note.dart';
import 'package:noteswidgetapp/features/notes/note_editor/controller.dart';
import 'package:noteswidgetapp/features/notes/repository/notes_repository.dart';

class HandwritingEditorController with ChangeNotifier {
  final NotesRepository _repo = NotesRepository();
  final String noteId;

  HandwritingEditorController({required this.noteId});

  final titleController = TextEditingController();
  final titleFocusNode = FocusNode();

  Note? note;
  bool isLoading = true;
  DrawingData drawingData = const DrawingData();
  EditorSaveStatus saveStatus = EditorSaveStatus.idle;
  bool _hasUnsavedChanges = false;
  bool _autoSaveEnabled = false;
  Timer? _debounceTimer;

  static const _autoSaveDelay = Duration(milliseconds: 1500);

  String get statusLabel {
    switch (saveStatus) {
      case EditorSaveStatus.saving:
        return 'Saving…';
      case EditorSaveStatus.saved:
        return 'Saved';
      case EditorSaveStatus.unsaved:
        return 'Unsaved changes';
      case EditorSaveStatus.error:
        return 'Save failed';
      default:
        return '';
    }
  }

  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    try {
      note = await _repo.getNote(noteId);
      if (note != null) {
        titleController.text =
            note!.title == 'Handwritten note' && drawingData.isEmpty ? '' : note!.title;
        drawingData = DrawingData.decode(note!.drawingData);
      }
    } finally {
      isLoading = false;
      _autoSaveEnabled = true;
      notifyListeners();
    }
  }

  void onDrawingChanged(DrawingData data) {
    if (!_autoSaveEnabled || note == null) return;
    drawingData = data;
    _markDirty();
  }

  void onTitleChanged() {
    if (!_autoSaveEnabled || note == null) return;
    _markDirty();
  }

  void _markDirty() {
    _hasUnsavedChanges = true;
    saveStatus = EditorSaveStatus.unsaved;
    notifyListeners();
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_autoSaveDelay, () => save(silent: true));
  }

  Future<bool> save({bool silent = false}) async {
    if (note == null) return false;

    _debounceTimer?.cancel();
    saveStatus = EditorSaveStatus.saving;
    notifyListeners();

    try {
      final title = titleController.text.trim().isEmpty ? 'Handwritten note' : titleController.text.trim();
      note = await _repo.updateDrawing(
        note!,
        drawingData: drawingData.encode(),
        title: title,
      );
      _hasUnsavedChanges = false;
      saveStatus = EditorSaveStatus.saved;
      if (!silent) AppConstants.showToast('Saved');
      notifyListeners();
      return true;
    } catch (e) {
      saveStatus = EditorSaveStatus.error;
      if (!silent) AppConstants.showToast('Could not save');
      notifyListeners();
      return false;
    }
  }

  Future<void> togglePin() async {
    if (note == null) return;
    try {
      note = await _repo.setPinned(note!, !note!.isPinned);
      AppConstants.showToast(note!.isPinned ? 'Note pinned' : 'Note unpinned');
      notifyListeners();
    } catch (e) {
      AppConstants.showToast('Could not update pin');
    }
  }

  Future<bool> deleteNote() async {
    if (note == null) return false;
    _debounceTimer?.cancel();
    try {
      await _repo.deleteNote(note!);
      return true;
    } catch (e) {
      AppConstants.showToast('Could not delete note');
      return false;
    }
  }

  Future<bool> tryClose() async {
    if (_hasUnsavedChanges) return save(silent: true);
    return true;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    titleController.dispose();
    titleFocusNode.dispose();
    super.dispose();
  }
}
