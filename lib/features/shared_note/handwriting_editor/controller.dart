import 'dart:async';

import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/constants/app_constants.dart';
import 'package:noteswidgetapp/core/notes/drawing_data.dart';
import 'package:noteswidgetapp/core/notes/note_type.dart';
import 'package:noteswidgetapp/core/supabase/app_supabase.dart';
import 'package:noteswidgetapp/core/sync/shared_note_sync_bus.dart';
import 'package:noteswidgetapp/core/widget/shared_note_widget_cache.dart';
import 'package:noteswidgetapp/core/widget/widget_sync_policy.dart';
import 'package:noteswidgetapp/features/notes/note_editor/controller.dart';
import 'package:noteswidgetapp/features/shared_note/model/shared_note.dart';
import 'package:noteswidgetapp/features/shared_note/repository/shared_note_repository.dart';

class SharedHandwritingEditorController with ChangeNotifier {
  final SharedNoteRepository _repo = SharedNoteRepository();
  final String sharedNoteId;
  final String friendLabel;
  final String? friendUid;

  SharedHandwritingEditorController({
    required this.sharedNoteId,
    required this.friendLabel,
    this.friendUid,
  }) {
    titleController.addListener(_onLocalEdit);
  }

  final titleController = TextEditingController();
  final titleFocusNode = FocusNode();

  SharedNote? note;
  bool isLoading = true;
  bool _initialLoadComplete = false;
  bool _fieldsInitialized = false;
  bool _disposed = false;
  String? loadError;
  String _watchNoteId = '';

  DrawingData drawingData = const DrawingData();
  EditorSaveStatus saveStatus = EditorSaveStatus.idle;
  bool _hasUnsavedChanges = false;
  bool _autoSaveEnabled = false;
  bool _suppressLocalListener = false;
  int _lastAppliedRemoteAt = 0;
  int _lastSavedAt = 0;
  String? _remoteEditHint;
  Timer? _debounceTimer;
  StreamSubscription<SharedNote?>? _subscription;
  StreamSubscription<SharedNote>? _busSubscription;

  static const _autoSaveDelay = Duration(milliseconds: 1500);

  String get statusLabel {
    if (_remoteEditHint != null) return _remoteEditHint!;
    if (isLoading) return 'Loading…';
    switch (saveStatus) {
      case EditorSaveStatus.saving:
        return 'Saving…';
      case EditorSaveStatus.saved:
        return 'Synced';
      case EditorSaveStatus.unsaved:
        return 'Unsaved changes';
      case EditorSaveStatus.error:
        return 'Save failed';
      case EditorSaveStatus.idle:
        return 'Live sync';
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> init() async {
    await _loadInitial();
    if (_disposed) return;

    _initialLoadComplete = true;
    if (note == null || _watchNoteId.isEmpty) return;

    _busSubscription?.cancel();
    _busSubscription =
        SharedNoteSyncBus.streamFor(_watchNoteId).listen(_onRemoteNote);

    _subscription = _repo.watch(_watchNoteId).listen(
      _onRemoteNote,
      onError: (_) {
        if (!_disposed) AppConstants.showToast('Lost connection to shared note');
      },
    );
  }

  Future<void> retryLoad() async {
    if (_disposed) return;
    loadError = null;
    isLoading = true;
    note = null;
    _fieldsInitialized = false;
    _initialLoadComplete = false;
    _watchNoteId = '';
    _clearFields();
    _notify();

    await _subscription?.cancel();
    _subscription = null;
    await _busSubscription?.cancel();
    _busSubscription = null;
    await init();
  }

  void _clearFields() {
    _suppressLocalListener = true;
    titleController.text = '';
    drawingData = const DrawingData();
    _suppressLocalListener = false;
  }

  Future<void> _loadInitial() async {
    if (_disposed) return;
    isLoading = true;
    loadError = null;
    _clearFields();
    _notify();

    SharedNote? remote;
    for (var attempt = 0; attempt < 3; attempt++) {
      if (_disposed) return;
      remote = await _repo.resolveAndFetch(
        preferredId: sharedNoteId,
        friendUid: friendUid,
      );
      if (remote != null) break;
      if (attempt < 2) {
        await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
      }
    }

    if (_disposed) return;

    if (remote != null) {
      _watchNoteId = remote.sharedNoteId;
      await _applyInitialNote(remote);
      return;
    }

    isLoading = false;
    loadError = 'Shared note could not be loaded. Check your connection and try again.';
    _notify();
  }

  Future<void> _syncWidgetIfNeeded(SharedNote remote) async {
    if (_disposed) return;
    if (!await WidgetSyncPolicy.shouldUpdateHomeWidget(remote.sharedNoteId)) return;
    await SharedNoteWidgetCache.updateFromNote(remote, friendLabel: friendLabel);
  }

  Future<void> _applyInitialNote(SharedNote remote) async {
    if (_disposed) return;

    note = remote;
    isLoading = false;
    loadError = null;
    _lastAppliedRemoteAt = remote.updatedAt;
    _applyToFields(remote);
    _fieldsInitialized = true;
    _autoSaveEnabled = true;
    saveStatus = EditorSaveStatus.saved;

    await _syncWidgetIfNeeded(remote);
    if (_disposed) return;
    _notify();
  }

  Future<void> _onRemoteNote(SharedNote? remote) async {
    if (_disposed) return;

    if (remote == null) {
      if (!_initialLoadComplete || note != null) return;
      isLoading = false;
      loadError ??= 'Shared note not found';
      _notify();
      return;
    }

    if (remote.sharedNoteId != _watchNoteId) return;

    note = remote;
    isLoading = false;
    loadError = null;

    final myUid = AppSupabase.currentUserId;
    final isOwnWrite = remote.updatedBy == myUid;

    if (!_fieldsInitialized) {
      await _applyInitialNote(remote);
      return;
    }

    if (remote.updatedAt <= _lastAppliedRemoteAt) {
      _notify();
      return;
    }

    _lastAppliedRemoteAt = remote.updatedAt;
    await _syncWidgetIfNeeded(remote);
    if (_disposed) return;

    if (isOwnWrite && _hasUnsavedChanges) {
      _notify();
      return;
    }

    if (_hasUnsavedChanges && !isOwnWrite) {
      _remoteEditHint = 'Friend updated — save or keep drawing';
      _notify();
      return;
    }

    _applyToFields(remote);
    _hasUnsavedChanges = false;
    saveStatus = EditorSaveStatus.saved;
    _remoteEditHint = isOwnWrite ? null : 'Updated by friend';
    _notify();

    if (_remoteEditHint != null) {
      Future.delayed(const Duration(seconds: 3), () {
        if (_disposed) return;
        if (_remoteEditHint == 'Updated by friend') {
          _remoteEditHint = null;
          _notify();
        }
      });
    }
  }

  void _applyToFields(SharedNote remote) {
    _suppressLocalListener = true;
    final showEmptyTitle =
        remote.title == 'Shared note' && remote.drawingData.isEmpty;
    titleController.text = showEmptyTitle ? '' : remote.title;
    drawingData = DrawingData.decode(remote.drawingData);
    _suppressLocalListener = false;
  }

  void _onLocalEdit() {
    if (_disposed || _suppressLocalListener || !_autoSaveEnabled) return;
    _hasUnsavedChanges = true;
    _remoteEditHint = null;
    saveStatus = EditorSaveStatus.unsaved;
    _notify();
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_autoSaveDelay, () {
      if (!_disposed) save(silent: true);
    });
  }

  void onDrawingChanged(DrawingData data) {
    if (_disposed || _suppressLocalListener || !_autoSaveEnabled) return;
    drawingData = data;
    _onLocalEdit();
  }

  Future<void> _pushWidgetPreview() async {
    if (_disposed || note == null) return;
    if (!await WidgetSyncPolicy.shouldUpdateHomeWidget(note!.sharedNoteId)) return;

    final title = titleController.text.trim().isEmpty
        ? 'Shared note'
        : titleController.text.trim();

    await SharedNoteWidgetCache.update(
      sharedNoteId: note!.sharedNoteId,
      title: title,
      body: '',
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      friendLabel: friendLabel,
      noteType: NoteType.drawing,
      drawingData: drawingData.encode(),
    );
  }

  Future<bool> save({bool silent = false}) async {
    if (_disposed || note == null) return false;

    _debounceTimer?.cancel();
    saveStatus = EditorSaveStatus.saving;
    _notify();

    try {
      final id = _watchNoteId.isNotEmpty ? _watchNoteId : sharedNoteId;
      final title = titleController.text.trim().isEmpty
          ? 'Shared note'
          : titleController.text.trim();

      await _repo.save(
        sharedNoteId: id,
        title: title,
        body: '',
        noteType: NoteType.drawing,
        drawingData: drawingData.encode(),
      );
      if (_disposed) return false;

      _lastSavedAt = DateTime.now().millisecondsSinceEpoch;
      _lastAppliedRemoteAt = _lastSavedAt;
      _hasUnsavedChanges = false;
      _remoteEditHint = null;
      saveStatus = EditorSaveStatus.saved;

      await _pushWidgetPreview();
      if (_disposed) return true;

      if (!silent) AppConstants.showToast('Saved');
      _notify();
      return true;
    } catch (e) {
      if (_disposed) return false;
      saveStatus = EditorSaveStatus.error;
      if (!silent) AppConstants.showToast('Could not save');
      _notify();
      return false;
    }
  }

  Future<bool> tryClose() async {
    if (_hasUnsavedChanges) return save(silent: true);
    return true;
  }

  @override
  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    _subscription?.cancel();
    _busSubscription?.cancel();
    titleController.removeListener(_onLocalEdit);
    titleController.dispose();
    titleFocusNode.dispose();
    super.dispose();
  }
}
