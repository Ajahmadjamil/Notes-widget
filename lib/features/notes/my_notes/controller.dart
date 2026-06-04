import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/constants/app_constants.dart';
import 'package:noteswidgetapp/features/notes/model/note.dart';
import 'package:noteswidgetapp/features/notes/repository/notes_repository.dart';

class MyNotesController with ChangeNotifier {
  final NotesRepository _repo = NotesRepository();

  List<Note> notes = [];
  bool isLoading = false;
  bool isOffline = false;
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

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
