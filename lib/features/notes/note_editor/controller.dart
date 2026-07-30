import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/constants/app_constants.dart';
import 'package:noteswidgetapp/features/notes/model/note.dart';
import 'package:noteswidgetapp/features/notes/repository/notes_repository.dart';

enum EditorSaveStatus { idle, unsaved, saving, saved, error }

class NoteEditorController with ChangeNotifier {
  final NotesRepository _repo = NotesRepository();
  final String noteId;

  NoteEditorController({required this.noteId}) {
    titleController.addListener(_onContentChanged);
    bodyController.addListener(_onContentChanged);
  }

  final titleController = TextEditingController();
  final bodyController = TextEditingController();
  final titleFocusNode = FocusNode();
  final bodyFocusNode = FocusNode();

  Note? note;
  bool isLoading = true;
  EditorSaveStatus saveStatus = EditorSaveStatus.idle;
  int? lastSavedAt;
  bool _hasUnsavedChanges = false;
  bool _autoSaveEnabled = false;
  Timer? _debounceTimer;

  static const _autoSaveDelay = Duration(milliseconds: 1500);

  bool get hasUnsavedChanges => _hasUnsavedChanges;

  String get statusLabel {
    switch (saveStatus) {
      case EditorSaveStatus.saving:
        return 'Saving…';
      case EditorSaveStatus.saved:
        return _formatSavedLabel(lastSavedAt);
      case EditorSaveStatus.unsaved:
        return 'Unsaved changes';
      case EditorSaveStatus.error:
        return 'Save failed';
      case EditorSaveStatus.idle:
        return note != null ? _formatSavedLabel(note!.updatedAt) : '';
    }
  }

  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    try {
      note = await _repo.getNote(noteId);
      if (note != null) {
        titleController.text = note!.title == 'Untitled' ? '' : note!.title;
        bodyController.text = note!.body;
        lastSavedAt = note!.updatedAt;
        saveStatus = EditorSaveStatus.saved;
        if (titleController.text.isEmpty && bodyController.text.isEmpty) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            titleFocusNode.requestFocus();
          });
        }
      }
    } finally {
      isLoading = false;
      _autoSaveEnabled = true;
      notifyListeners();
    }
  }

  void _onContentChanged() {
    if (!_autoSaveEnabled || note == null) return;

    _hasUnsavedChanges = true;
    saveStatus = EditorSaveStatus.unsaved;
    notifyListeners();

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_autoSaveDelay, () => autoSave());
  }

  Future<void> autoSave() async {
    if (!_hasUnsavedChanges || note == null) return;
    await save(silent: true);
  }

  Future<bool> save({bool silent = false}) async {
    if (note == null) return false;

    _debounceTimer?.cancel();
    saveStatus = EditorSaveStatus.saving;
    notifyListeners();

    try {
      final updated = await _repo.updateNote(
        note!,
        title: titleController.text,
        body: bodyController.text,
      );
      note = updated;
      lastSavedAt = updated.updatedAt;
      _hasUnsavedChanges = false;
      saveStatus = EditorSaveStatus.saved;
      if (!silent) {
        AppConstants.showToast('Saved');
      }
      notifyListeners();
      return true;
    } catch (e) {
      saveStatus = EditorSaveStatus.error;
      if (!silent) {
        AppConstants.showToast('Could not save note');
      }
      notifyListeners();
      return false;
    }
  }

  Future<void> togglePin() async {
    if (note == null) return;

    try {
      final pinned = !note!.isPinned;
      note = await _repo.setPinned(note!, pinned);
      AppConstants.showToast(pinned ? 'Note pinned' : 'Note unpinned');
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

  /// Saves if needed, then returns whether the screen can close.
  /// Empty notes are discarded instead of kept.
  Future<bool> tryClose() async {
    _debounceTimer?.cancel();
    final title = titleController.text.trim();
    final body = bodyController.text.trim();
    if (title.isEmpty && body.isEmpty) {
      return deleteNote();
    }
    if (_hasUnsavedChanges) {
      return save(silent: true);
    }
    return true;
  }

  static String _formatSavedLabel(int? millis) {
    if (millis == null) return 'Saved';
    final saved = DateTime.fromMillisecondsSinceEpoch(millis);
    final now = DateTime.now();
    final time =
        '${saved.hour.toString().padLeft(2, '0')}:${saved.minute.toString().padLeft(2, '0')}';

    if (saved.year == now.year && saved.month == now.month && saved.day == now.day) {
      return 'Saved today $time';
    }
    return 'Saved ${saved.month}/${saved.day}/${saved.year} $time';
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    titleController.removeListener(_onContentChanged);
    bodyController.removeListener(_onContentChanged);
    titleController.dispose();
    bodyController.dispose();
    titleFocusNode.dispose();
    bodyFocusNode.dispose();
    super.dispose();
  }
}
