import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/constants/app_constants.dart';
import 'package:noteswidgetapp/features/notes/model/note.dart';
import 'package:noteswidgetapp/features/notes/repository/notes_repository.dart';

class MyNotesController with ChangeNotifier {
  final NotesRepository _repo = NotesRepository();

  List<Note> notes = [];
  bool isLoading = false;
  bool isOffline = false;
  bool selectionMode = false;
  final Set<String> selectedNoteIds = {};
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> loadNotes() async {
    if (_disposed) return;
    isLoading = true;
    _notify();

    try {
      isOffline = !(await _repo.isOnline);
      if (_disposed) return;
      notes = await _repo.loadNotes();
    } catch (e) {
      if (!_disposed) AppConstants.showToast('Could not load notes');
    } finally {
      if (_disposed) return;
      isLoading = false;
      _notify();
    }
  }

  Future<Note> createNote() async {
    return _repo.createNote();
  }

  Future<void> deleteNote(Note note) async {
    try {
      await _repo.deleteNote(note);
      notes = notes.where((n) => n.noteId != note.noteId).toList();
      _notify();
    } catch (e) {
      AppConstants.showToast('Could not delete note');
    }
  }

  void enterSelection(String noteId) {
    selectionMode = true;
    selectedNoteIds.add(noteId);
    _notify();
  }

  void toggleSelection(String noteId) {
    if (!selectionMode) return;
    if (selectedNoteIds.contains(noteId)) {
      selectedNoteIds.remove(noteId);
      if (selectedNoteIds.isEmpty) selectionMode = false;
    } else {
      selectedNoteIds.add(noteId);
    }
    _notify();
  }

  void exitSelection() {
    selectionMode = false;
    selectedNoteIds.clear();
    _notify();
  }

  bool isSelected(String noteId) => selectedNoteIds.contains(noteId);

  Future<void> deleteSelected() async {
    if (selectedNoteIds.isEmpty) return;
    final toDelete = notes.where((n) => selectedNoteIds.contains(n.noteId)).toList();
    try {
      for (final note in toDelete) {
        await _repo.deleteNote(note);
      }
      exitSelection();
      await loadNotes();
      AppConstants.showToast('Deleted ${toDelete.length} note(s)');
    } catch (e) {
      AppConstants.showToast('Could not delete notes');
    }
  }

  Future<void> pinSelected({required bool pinned}) async {
    if (selectedNoteIds.isEmpty) return;
    final toPin = notes.where((n) => selectedNoteIds.contains(n.noteId)).toList();
    try {
      for (final note in toPin) {
        await _repo.setPinned(note, pinned);
      }
      exitSelection();
      await loadNotes();
      AppConstants.showToast(pinned ? 'Pinned ${toPin.length} note(s)' : 'Unpinned ${toPin.length} note(s)');
    } catch (e) {
      AppConstants.showToast('Could not update pins');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
