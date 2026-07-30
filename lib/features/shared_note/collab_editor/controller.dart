import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:noteswidgetapp/core/constants/app_constants.dart';
import 'package:noteswidgetapp/core/media/audio_recorder_service.dart';
import 'package:noteswidgetapp/core/media/image_compress_service.dart';
import 'package:noteswidgetapp/core/media/note_media_storage.dart';
import 'package:noteswidgetapp/core/notes/document_data.dart';
import 'package:noteswidgetapp/core/notes/note_type.dart';
import 'package:noteswidgetapp/core/supabase/app_supabase.dart';
import 'package:noteswidgetapp/core/sync/shared_note_sync_bus.dart';
import 'package:noteswidgetapp/core/widget/active_widget_note_service.dart';
import 'package:noteswidgetapp/core/widget/shared_note_widget_cache.dart';
import 'package:noteswidgetapp/core/widget/widget_sync_policy.dart';
import 'package:noteswidgetapp/features/notes/note_editor/controller.dart';
import 'package:noteswidgetapp/features/profile/repository/user_profile_repository.dart';
import 'package:noteswidgetapp/features/shared_note/model/shared_note.dart';
import 'package:noteswidgetapp/features/shared_note/repository/shared_note_repository.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

/// Shared text / document editor with per-block authorship.
class SharedCollabEditorController with ChangeNotifier {
  final SharedNoteRepository _repo = SharedNoteRepository();
  final UserProfileRepository _profiles = UserProfileRepository();
  final ImagePicker _picker = ImagePicker();
  final AudioRecorderService _recorder = AudioRecorderService();
  final Uuid _uuid = const Uuid();

  final String sharedNoteId;
  final String friendLabel;
  final String? friendUid;
  final bool textOnly;

  SharedCollabEditorController({
    required this.sharedNoteId,
    required this.friendLabel,
    this.friendUid,
    this.textOnly = false,
  }) {
    titleController.addListener(_onLocalEdit);
  }

  final titleController = TextEditingController();
  final titleFocusNode = FocusNode();
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, FocusNode> _textFocusNodes = {};

  SharedNote? note;
  List<DocumentBlock> blocks = [];
  bool isLoading = true;
  String? loadError;
  String myUid = '';
  String myName = 'You';
  bool isBusyMedia = false;
  bool isRecording = false;
  int recordingElapsedMs = 0;
  String? editingAudioId;

  EditorSaveStatus saveStatus = EditorSaveStatus.idle;
  bool _hasUnsavedChanges = false;
  bool _autoSaveEnabled = false;
  bool _suppressLocalListener = false;
  int _lastAppliedRemoteAt = 0;
  Timer? _debounceTimer;
  Timer? _recordTicker;
  StreamSubscription<SharedNote?>? _subscription;
  StreamSubscription<SharedNote>? _busSubscription;
  String _watchNoteId = '';

  static const _autoSaveDelay = Duration(milliseconds: 1500);

  NoteType get noteType =>
      textOnly ? NoteType.text : NoteType.document;

  String get statusLabel {
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

  TextEditingController textControllerFor(String blockId) {
    return _textControllers.putIfAbsent(blockId, () {
      final match = blocks.where((b) => b.id == blockId);
      final content = match.isEmpty ? '' : match.first.content;
      final c = TextEditingController(text: content);
      c.addListener(() => _onTextChanged(blockId, c.text));
      return c;
    });
  }

  FocusNode textFocusNodeFor(String blockId) {
    return _textFocusNodes.putIfAbsent(blockId, FocusNode.new);
  }

  Future<void> init() async {
    myUid = AppSupabase.currentUserId ?? '';
    final me = myUid.isEmpty ? null : await _profiles.fetchProfile(myUid);
    myName = me?.username?.trim().isNotEmpty == true
        ? me!.username!
        : (me?.displayName?.trim().isNotEmpty == true
            ? me!.displayName!
            : 'You');

    await _loadInitial();
    if (note == null || _watchNoteId.isEmpty) return;

    _busSubscription =
        SharedNoteSyncBus.streamFor(_watchNoteId).listen(_onRemote);
    _subscription = _repo.watch(_watchNoteId).listen(_onRemote);
  }

  Future<void> _loadInitial() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      note = await _repo.resolveAndFetch(
        preferredId: sharedNoteId,
        friendUid: friendUid,
      );
      if (note == null) {
        loadError = 'Shared note could not be loaded.';
        return;
      }
      _watchNoteId = note!.sharedNoteId;
      await ActiveWidgetNoteService.setActiveFriendNote(
        sharedNoteId: _watchNoteId,
        friendLabel: friendLabel,
      );
      _applyNote(note!, forceFields: true);
      saveStatus = EditorSaveStatus.saved;
    } catch (_) {
      loadError = 'Failed to load shared note.';
    } finally {
      isLoading = false;
      _autoSaveEnabled = true;
      notifyListeners();
    }
  }

  void _applyNote(SharedNote remote, {required bool forceFields}) {
    note = remote;
    if (!forceFields && _hasUnsavedChanges) return;

    final doc = remote.document;
    blocks = List.of(doc.blocks);
    if (blocks.isEmpty) {
      blocks = [
        DocumentBlock(
          id: _uuid.v4(),
          type: DocumentBlockType.text,
          authorId: myUid,
          authorName: myName,
        ),
      ];
    }
    _syncTextControllers();
    _suppressLocalListener = true;
    if (forceFields || titleController.text != remote.title) {
      titleController.text =
          remote.title == 'Shared note' ? '' : remote.title;
    }
    _suppressLocalListener = false;
    _lastAppliedRemoteAt = remote.updatedAt;
  }

  void _syncTextControllers() {
    final ids = blocks
        .where((b) => b.type == DocumentBlockType.text)
        .map((b) => b.id)
        .toSet();
    for (final id in ids) {
      final content = blocks.firstWhere((b) => b.id == id).content;
      final existing = _textControllers[id];
      if (existing == null) {
        textControllerFor(id);
      } else if (existing.text != content) {
        existing.value = TextEditingValue(
          text: content,
          selection: TextSelection.collapsed(offset: content.length),
        );
      }
    }
    for (final id in _textControllers.keys.where((id) => !ids.contains(id)).toList()) {
      _textControllers.remove(id)?.dispose();
      _textFocusNodes.remove(id)?.dispose();
    }
  }

  void _onRemote(SharedNote? remote) {
    if (remote == null) return;
    if (remote.updatedAt <= _lastAppliedRemoteAt) return;
    final own = remote.updatedBy == myUid;
    if (own && _hasUnsavedChanges) return;
    _applyNote(remote, forceFields: !own || !_hasUnsavedChanges);
    if (!own) {
      saveStatus = EditorSaveStatus.saved;
      _hasUnsavedChanges = false;
    }
    notifyListeners();
  }

  void _onLocalEdit() {
    if (_suppressLocalListener || !_autoSaveEnabled) return;
    _markDirty();
  }

  void _onTextChanged(String blockId, String text) {
    if (_suppressLocalListener || !_autoSaveEnabled) return;
    final i = blocks.indexWhere((b) => b.id == blockId);
    if (i < 0 || blocks[i].content == text) return;
    blocks[i] = blocks[i].copyWith(content: text);
    _markDirty();
  }

  void _markDirty() {
    _hasUnsavedChanges = true;
    saveStatus = EditorSaveStatus.unsaved;
    notifyListeners();
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_autoSaveDelay, () => save(silent: true));
  }

  DocumentBlock _authored({
    required DocumentBlockType type,
    String content = '',
    String localPath = '',
    String mimeType = '',
    int durationMs = 0,
  }) {
    return DocumentBlock(
      id: _uuid.v4(),
      type: type,
      content: content,
      localPath: localPath,
      mimeType: mimeType,
      durationMs: durationMs,
      authorId: myUid,
      authorName: myName,
    );
  }

  void addTextBlock() {
    final block = _authored(type: DocumentBlockType.text);
    blocks.add(block);
    textControllerFor(block.id);
    _markDirty();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      textFocusNodeFor(block.id).requestFocus();
    });
  }

  Future<void> addImage(ImageSource source) async {
    if (textOnly || note == null || isBusyMedia) return;
    isBusyMedia = true;
    notifyListeners();
    try {
      if (source == ImageSource.camera) {
        final cam = await Permission.camera.request();
        if (!cam.isGranted) {
          AppConstants.showToast('Camera permission needed');
          return;
        }
      }
      final picked = await _picker.pickImage(source: source, imageQuality: 100);
      if (picked == null) return;
      final compressed =
          await ImageCompressService.compressToJpeg(File(picked.path));
      final root = await getApplicationDocumentsDirectory();
      final folder = Directory(
        p.join(root.path, 'note_media', 'shared', note!.sharedNoteId),
      );
      if (!await folder.exists()) await folder.create(recursive: true);
      final local = await compressed.copy(
        p.join(folder.path, 'img_${_uuid.v4()}.jpg'),
      );
      blocks.add(
        _authored(
          type: DocumentBlockType.image,
          localPath: local.path,
          mimeType: 'image/jpeg',
        ),
      );
      addTextBlock();
    } catch (_) {
      AppConstants.showToast('Could not add image');
    } finally {
      isBusyMedia = false;
      notifyListeners();
    }
  }

  Future<void> toggleRecording() async {
    if (textOnly) return;
    if (isRecording) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }

  Future<void> startRecording() async {
    if (note == null || isRecording) return;
    try {
      await _recorder.start(
        ownerId: 'shared',
        noteId: note!.sharedNoteId,
      );
      isRecording = true;
      recordingElapsedMs = 0;
      _recordTicker?.cancel();
      _recordTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        recordingElapsedMs += 1000;
        notifyListeners();
      });
      notifyListeners();
    } catch (_) {
      AppConstants.showToast('Microphone permission needed');
    }
  }

  Future<void> stopRecording() async {
    if (!isRecording) return;
    _recordTicker?.cancel();
    try {
      final result = await _recorder.stop();
      isRecording = false;
      recordingElapsedMs = 0;
      if (result == null) {
        notifyListeners();
        return;
      }
      final count =
          blocks.where((b) => b.type == DocumentBlockType.audio).length + 1;
      blocks.add(
        _authored(
          type: DocumentBlockType.audio,
          content: 'Voice note $count',
          localPath: result.file.path,
          mimeType: 'audio/mp4',
          durationMs: result.durationMs,
        ),
      );
      addTextBlock();
    } catch (_) {
      isRecording = false;
      AppConstants.showToast('Could not save recording');
      notifyListeners();
    }
  }

  Future<void> cancelRecording() async {
    _recordTicker?.cancel();
    await _recorder.cancel();
    isRecording = false;
    recordingElapsedMs = 0;
    notifyListeners();
  }

  void beginRenameAudio(String blockId) {
    editingAudioId = blockId;
    notifyListeners();
  }

  void renameAudio(String blockId, String rawTitle) {
    final i = blocks.indexWhere((b) => b.id == blockId);
    editingAudioId = null;
    if (i < 0) {
      notifyListeners();
      return;
    }
    final cleaned = rawTitle.trim().isEmpty ? 'Voice note' : rawTitle.trim();
    if (blocks[i].content != cleaned) {
      blocks[i] = blocks[i].copyWith(content: cleaned);
      _markDirty();
    } else {
      notifyListeners();
    }
  }

  Future<void> removeBlock(String blockId) async {
    final i = blocks.indexWhere((b) => b.id == blockId);
    if (i < 0) return;
    final block = blocks[i];
    if (block.storagePath.isNotEmpty) {
      await NoteMediaStorage.deleteObject(block.storagePath);
    }
    if (block.localPath.isNotEmpty) {
      try {
        final f = File(block.localPath);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    blocks.removeAt(i);
    _textControllers.remove(blockId)?.dispose();
    _textFocusNodes.remove(blockId)?.dispose();
    if (blocks.isEmpty) {
      addTextBlock();
    } else {
      _markDirty();
    }
  }

  void reorderBlocks(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= blocks.length) return;
    if (newIndex < 0 || newIndex >= blocks.length) return;
    if (oldIndex == newIndex) return;
    final item = blocks.removeAt(oldIndex);
    blocks.insert(newIndex, item);
    _markDirty();
  }

  Future<String?> resolveMediaUrl(DocumentBlock block) async {
    if (block.localPath.isNotEmpty && File(block.localPath).existsSync()) {
      return block.localPath;
    }
    if (block.storagePath.isNotEmpty) {
      try {
        return await NoteMediaStorage.createSignedUrl(block.storagePath);
      } catch (_) {}
    }
    return null;
  }

  Future<List<DocumentBlock>> _uploadPending(List<DocumentBlock> input) async {
    if (note == null) return input;
    final out = <DocumentBlock>[];
    for (final block in input) {
      if (!block.needsUpload) {
        out.add(block);
        continue;
      }
      final file = File(block.localPath);
      if (!await file.exists()) {
        out.add(block);
        continue;
      }
      try {
        final path = await NoteMediaStorage.uploadSharedFile(
          sharedNoteId: note!.sharedNoteId,
          file: file,
          mimeType: block.mimeType.isNotEmpty
              ? block.mimeType
              : (block.type == DocumentBlockType.audio
                  ? 'audio/mp4'
                  : 'image/jpeg'),
        );
        out.add(block.copyWith(storagePath: path));
      } catch (_) {
        out.add(block);
      }
    }
    return out;
  }

  String _cloudDocumentData(List<DocumentBlock> list) {
    final cleaned = list.map((b) => b.copyWith(localPath: '')).toList();
    return DocumentData(blocks: cleaned).encode();
  }

  Future<bool> save({bool silent = false}) async {
    if (note == null) return false;
    _debounceTimer?.cancel();
    saveStatus = EditorSaveStatus.saving;
    notifyListeners();
    try {
      blocks = await _uploadPending(List.of(blocks));
      final doc = DocumentData(blocks: blocks);
      final title = titleController.text.trim().isEmpty
          ? 'Shared note'
          : titleController.text.trim();
      await _repo.save(
        sharedNoteId: note!.sharedNoteId,
        title: title,
        body: doc.previewText,
        noteType: noteType,
        documentData: _cloudDocumentData(blocks),
      );
      note = note!.copyWith(
        title: title,
        body: doc.previewText,
        documentData: _cloudDocumentData(blocks),
        noteType: noteType,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        updatedBy: myUid,
      );
      _lastAppliedRemoteAt = note!.updatedAt;
      _hasUnsavedChanges = false;
      saveStatus = EditorSaveStatus.saved;
      if (await WidgetSyncPolicy.shouldUpdateHomeWidget(note!.sharedNoteId)) {
        await SharedNoteWidgetCache.updateFromNote(
          note!,
          friendLabel: friendLabel,
        );
      }
      if (!silent) AppConstants.showToast('Synced');
      notifyListeners();
      return true;
    } catch (_) {
      saveStatus = EditorSaveStatus.error;
      if (!silent) AppConstants.showToast('Could not sync');
      notifyListeners();
      return false;
    }
  }

  Future<bool> tryClose() async {
    if (isRecording) await stopRecording();
    _debounceTimer?.cancel();
    final titleEmpty = titleController.text.trim().isEmpty;
    final empty = titleEmpty && !DocumentData(blocks: blocks).hasMeaningfulContent;
    if (empty) {
      // Keep shared note row; just clear content already empty.
      return true;
    }
    if (_hasUnsavedChanges) return save(silent: true);
    return true;
  }

  String formatDuration(int ms) {
    final totalSec = (ms / 1000).floor();
    final m = (totalSec ~/ 60).toString().padLeft(2, '0');
    final s = (totalSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String authorLabelFor(DocumentBlock block) {
    if (block.authorId == myUid) return myName;
    if (block.authorLabel.isNotEmpty) return block.authorLabel;
    if (block.authorId.isNotEmpty && block.authorId != myUid) {
      return friendLabel;
    }
    return '';
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _recordTicker?.cancel();
    _subscription?.cancel();
    _busSubscription?.cancel();
    titleController.removeListener(_onLocalEdit);
    titleController.dispose();
    titleFocusNode.dispose();
    for (final c in _textControllers.values) {
      c.dispose();
    }
    for (final f in _textFocusNodes.values) {
      f.dispose();
    }
    _recorder.dispose();
    super.dispose();
  }
}
