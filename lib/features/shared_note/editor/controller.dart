import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/constants/app_constants.dart';
import 'package:noteswidgetapp/core/widget/active_widget_note_service.dart';
import 'package:noteswidgetapp/core/widget/shared_note_widget_cache.dart';
import 'package:noteswidgetapp/core/widget/widget_sync_policy.dart';
import 'package:noteswidgetapp/features/notes/note_editor/controller.dart';
import 'package:noteswidgetapp/features/shared_note/model/shared_note.dart';
import 'package:noteswidgetapp/features/shared_note/repository/shared_note_repository.dart';

class SharedNoteEditorController with ChangeNotifier {
  final SharedNoteRepository _repo = SharedNoteRepository();
  final String sharedNoteId;
  final String friendLabel;
  final String? friendUid;

  SharedNoteEditorController({
    required this.sharedNoteId,
    required this.friendLabel,
    this.friendUid,
  }) {
    titleController.addListener(_onLocalEdit);
    bodyController.addListener(_onLocalEdit);
  }

  final titleController = TextEditingController();
  final bodyController = TextEditingController();
  final titleFocusNode = FocusNode();
  final bodyFocusNode = FocusNode();

  SharedNote? note;
  bool isLoading = true;
  bool _initialLoadComplete = false;
  bool _fieldsInitialized = false;
  String? loadError;
  String _watchNoteId = '';

  EditorSaveStatus saveStatus = EditorSaveStatus.idle;
  bool _hasUnsavedChanges = false;
  bool _autoSaveEnabled = false;
  bool _suppressLocalListener = false;
  int _lastAppliedRemoteAt = 0;
  int _lastSavedAt = 0;
  String? _remoteEditHint;
  Timer? _debounceTimer;
  StreamSubscription<SharedNote?>? _subscription;

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

  Future<void> init() async {
    await _loadInitial();
    _initialLoadComplete = true;

    if (note == null || _watchNoteId.isEmpty) return;

    _subscription = _repo.watch(_watchNoteId).listen(
      _onRemoteNote,
      onError: (_) {
        AppConstants.showToast('Lost connection to shared note');
      },
    );
  }

  Future<void> retryLoad() async {
    loadError = null;
    isLoading = true;
    note = null;
    _fieldsInitialized = false;
    _initialLoadComplete = false;
    _watchNoteId = '';
    _clearFields();
    notifyListeners();

    await _subscription?.cancel();
    _subscription = null;
    await init();
  }

  void _clearFields() {
    _suppressLocalListener = true;
    titleController.text = '';
    bodyController.text = '';
    _suppressLocalListener = false;
  }

  Future<void> _loadInitial() async {
    isLoading = true;
    loadError = null;
    _clearFields();
    notifyListeners();

    SharedNote? remote;
    for (var attempt = 0; attempt < 3; attempt++) {
      remote = await _repo.resolveAndFetch(
        preferredId: sharedNoteId,
        friendUid: friendUid,
      );
      if (remote != null) break;
      if (attempt < 2) {
        await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
      }
    }

    if (remote != null) {
      _watchNoteId = remote.sharedNoteId;
      await _applyInitialNote(remote);
      return;
    }

    isLoading = false;
    loadError = 'Shared note could not be loaded. Check your connection and try again.';
    if (kDebugMode) {
      print('Shared note load failed — id=$sharedNoteId friendUid=$friendUid');
    }
    notifyListeners();
  }

  Future<void> _applyInitialNote(SharedNote remote) async {
    note = remote;
    isLoading = false;
    loadError = null;
    _lastAppliedRemoteAt = remote.updatedAt;
    _applyToFields(remote);
    _fieldsInitialized = true;
    _autoSaveEnabled = true;
    saveStatus = EditorSaveStatus.saved;

    await ActiveWidgetNoteService.setActiveFriendNote(
      sharedNoteId: remote.sharedNoteId,
      friendLabel: friendLabel,
    );

    await SharedNoteWidgetCache.update(
      sharedNoteId: remote.sharedNoteId,
      title: remote.title,
      body: remote.body,
      updatedAt: remote.updatedAt,
      friendLabel: friendLabel,
    );

    notifyListeners();
  }

  Future<void> _onRemoteNote(SharedNote? remote) async {
    if (remote == null) {
      if (!_initialLoadComplete || note != null) return;
      isLoading = false;
      loadError ??= 'Shared note not found';
      notifyListeners();
      return;
    }

    if (remote.sharedNoteId != _watchNoteId) return;

    note = remote;
    isLoading = false;
    loadError = null;

    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwnWrite = remote.updatedBy == myUid;

    if (!_fieldsInitialized) {
      await _applyInitialNote(remote);
      return;
    }

    if (remote.updatedAt <= _lastAppliedRemoteAt) {
      notifyListeners();
      return;
    }

    _lastAppliedRemoteAt = remote.updatedAt;

    if (await WidgetSyncPolicy.shouldUpdateHomeWidget(remote.sharedNoteId)) {
      await SharedNoteWidgetCache.update(
        sharedNoteId: remote.sharedNoteId,
        title: remote.title,
        body: remote.body,
        updatedAt: remote.updatedAt,
        friendLabel: friendLabel,
      );
    }

    if (isOwnWrite && _hasUnsavedChanges) {
      notifyListeners();
      return;
    }

    if (_hasUnsavedChanges && !isOwnWrite) {
      _remoteEditHint = 'Friend updated — save or keep typing';
      notifyListeners();
      return;
    }

    _applyToFields(remote);
    _hasUnsavedChanges = false;
    saveStatus = EditorSaveStatus.saved;
    _remoteEditHint = isOwnWrite ? null : 'Updated by friend';
    notifyListeners();

    if (_remoteEditHint != null) {
      Future.delayed(const Duration(seconds: 3), () {
        if (_remoteEditHint == 'Updated by friend') {
          _remoteEditHint = null;
          notifyListeners();
        }
      });
    }
  }

  void _applyToFields(SharedNote remote) {
    _suppressLocalListener = true;
    final showEmptyTitle =
        remote.title == 'Shared note' && remote.body.isEmpty;
    titleController.text = showEmptyTitle ? '' : remote.title;
    bodyController.text = remote.body;
    _suppressLocalListener = false;
  }

  void _onLocalEdit() {
    if (_suppressLocalListener || !_autoSaveEnabled) return;

    _hasUnsavedChanges = true;
    _remoteEditHint = null;
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
      final id = _watchNoteId.isNotEmpty ? _watchNoteId : sharedNoteId;
      await _repo.save(
        sharedNoteId: id,
        title: titleController.text,
        body: bodyController.text,
      );
      _lastSavedAt = DateTime.now().millisecondsSinceEpoch;
      _lastAppliedRemoteAt = _lastSavedAt;
      _hasUnsavedChanges = false;
      _remoteEditHint = null;
      saveStatus = EditorSaveStatus.saved;

      await SharedNoteWidgetCache.update(
        sharedNoteId: id,
        title: titleController.text,
        body: bodyController.text,
        updatedAt: _lastSavedAt,
        friendLabel: friendLabel,
      );

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

  Future<bool> tryClose() async {
    if (_hasUnsavedChanges) return save(silent: true);
    return true;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _subscription?.cancel();
    titleController.removeListener(_onLocalEdit);
    bodyController.removeListener(_onLocalEdit);
    titleController.dispose();
    bodyController.dispose();
    titleFocusNode.dispose();
    bodyFocusNode.dispose();
    super.dispose();
  }
}
