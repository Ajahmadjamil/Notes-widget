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
import 'package:noteswidgetapp/features/notes/model/note.dart';
import 'package:noteswidgetapp/features/notes/note_editor/controller.dart';
import 'package:noteswidgetapp/features/notes/repository/notes_repository.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class _InsertAnchor {
  final String blockId;
  final int offset;

  const _InsertAnchor({required this.blockId, required this.offset});
}

class DocumentEditorController with ChangeNotifier {
  final NotesRepository _repo = NotesRepository();
  final ImagePicker _picker = ImagePicker();
  final AudioRecorderService _recorder = AudioRecorderService();
  final Uuid _uuid = const Uuid();
  final String noteId;

  DocumentEditorController({required this.noteId}) {
    titleController.addListener(_onContentChanged);
  }

  final titleController = TextEditingController();
  final titleFocusNode = FocusNode();
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, FocusNode> _textFocusNodes = {};

  Note? note;
  List<DocumentBlock> blocks = [];
  bool isLoading = true;
  bool isBusyMedia = false;
  bool isRecording = false;
  EditorSaveStatus saveStatus = EditorSaveStatus.idle;
  int? lastSavedAt;
  bool _hasUnsavedChanges = false;
  bool _autoSaveEnabled = false;
  Timer? _debounceTimer;
  Timer? _recordTicker;
  int recordingElapsedMs = 0;
  _InsertAnchor? _pendingInsert;
  String? editingAudioId;

  static const _autoSaveDelay = Duration(milliseconds: 1500);

  bool get hasUnsavedChanges => _hasUnsavedChanges;

  TextEditingController textControllerFor(String blockId) {
    return _textControllers.putIfAbsent(blockId, () {
      final match = blocks.where((b) => b.id == blockId);
      final content = match.isEmpty ? '' : match.first.content;
      final c = TextEditingController(text: content);
      c.addListener(() => _onTextBlockChanged(blockId, c.text));
      return c;
    });
  }

  FocusNode textFocusNodeFor(String blockId) {
    return _textFocusNodes.putIfAbsent(blockId, FocusNode.new);
  }

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
        titleController.text =
            (note!.title == 'Untitled' || note!.title == 'Document')
                ? ''
                : note!.title;
        blocks = List.of(note!.document.blocks);
        if (blocks.isEmpty) {
          blocks = [
            DocumentBlock(id: _uuid.v4(), type: DocumentBlockType.text),
          ];
        }
        _syncTextControllers();
        lastSavedAt = note!.updatedAt;
        saveStatus = EditorSaveStatus.saved;
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (titleController.text.isEmpty) {
            titleFocusNode.requestFocus();
          }
        });
      }
    } finally {
      isLoading = false;
      _autoSaveEnabled = true;
      notifyListeners();
    }
  }

  void _syncTextControllers() {
    final ids = blocks
        .where((b) => b.type == DocumentBlockType.text)
        .map((b) => b.id)
        .toSet();
    for (final id in ids) {
      final existing = _textControllers[id];
      final content = blocks.firstWhere((b) => b.id == id).content;
      if (existing == null) {
        textControllerFor(id);
      } else if (existing.text != content) {
        existing.value = TextEditingValue(
          text: content,
          selection: TextSelection.collapsed(
            offset: content.length.clamp(0, content.length),
          ),
        );
      }
    }
    final stale =
        _textControllers.keys.where((id) => !ids.contains(id)).toList();
    for (final id in stale) {
      _textControllers.remove(id)?.dispose();
      _textFocusNodes.remove(id)?.dispose();
    }
  }

  void _onTextBlockChanged(String blockId, String text) {
    final index = blocks.indexWhere((b) => b.id == blockId);
    if (index < 0) return;
    if (blocks[index].content == text) return;
    blocks[index] = blocks[index].copyWith(content: text);
    _markDirty();
  }

  void _onContentChanged() {
    if (!_autoSaveEnabled || note == null) return;
    _markDirty();
  }

  void _markDirty() {
    _hasUnsavedChanges = true;
    saveStatus = EditorSaveStatus.unsaved;
    notifyListeners();
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_autoSaveDelay, () => autoSave());
  }

  /// Snapshot cursor before camera/gallery/mic steals focus.
  void captureInsertAnchor() {
    for (final entry in _textFocusNodes.entries) {
      if (!entry.value.hasFocus) continue;
      final controller = _textControllers[entry.key];
      if (controller == null) continue;
      var offset = controller.selection.baseOffset;
      if (offset < 0) offset = controller.text.length;
      offset = offset.clamp(0, controller.text.length);
      _pendingInsert = _InsertAnchor(blockId: entry.key, offset: offset);
      return;
    }
    _pendingInsert = null;
  }

  void _insertMediaAtAnchor(DocumentBlock media) {
    final anchor = _pendingInsert;
    _pendingInsert = null;

    if (anchor == null) {
      blocks.add(media);
      addTextBlock();
      return;
    }

    final idx = blocks.indexWhere((b) => b.id == anchor.blockId);
    if (idx < 0 || blocks[idx].type != DocumentBlockType.text) {
      blocks.add(media);
      addTextBlock();
      return;
    }

    final textCtrl = textControllerFor(anchor.blockId);
    final full = textCtrl.text;
    final offset = anchor.offset.clamp(0, full.length);
    final before = full.substring(0, offset);
    final after = full.substring(offset);

    blocks[idx] = blocks[idx].copyWith(content: before);
    textCtrl.value = TextEditingValue(
      text: before,
      selection: TextSelection.collapsed(offset: before.length),
    );

    blocks.insert(idx + 1, media);

    final afterBlock = DocumentBlock(
      id: _uuid.v4(),
      type: DocumentBlockType.text,
      content: after,
    );
    blocks.insert(idx + 2, afterBlock);
    final afterCtrl = textControllerFor(afterBlock.id);
    afterCtrl.value = TextEditingValue(
      text: after,
      selection: const TextSelection.collapsed(offset: 0),
    );

    _markDirty();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      textFocusNodeFor(afterBlock.id).requestFocus();
    });
  }

  void reorderBlocks(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= blocks.length) return;
    if (newIndex < 0 || newIndex >= blocks.length) return;
    if (oldIndex == newIndex) return;

    final item = blocks.removeAt(oldIndex);
    blocks.insert(newIndex, item);
    _markDirty();
  }

  void addTextBlock({int? afterIndex}) {
    final block = DocumentBlock(id: _uuid.v4(), type: DocumentBlockType.text);
    final insertAt = afterIndex == null
        ? blocks.length
        : (afterIndex + 1).clamp(0, blocks.length);
    blocks.insert(insertAt, block);
    textControllerFor(block.id);
    _markDirty();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      textFocusNodeFor(block.id).requestFocus();
    });
  }

  Future<void> addImage(ImageSource source) async {
    if (note == null || isBusyMedia) return;
    captureInsertAnchor();
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

      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 100,
      );
      if (picked == null) return;

      final raw = File(picked.path);
      final compressed = await ImageCompressService.compressToJpeg(raw);
      final local = await ImageCompressService.persistLocalCopy(
        compressed: compressed,
        ownerId: note!.ownerId,
        noteId: note!.noteId,
      );

      _insertMediaAtAnchor(
        DocumentBlock(
          id: _uuid.v4(),
          type: DocumentBlockType.image,
          localPath: local.path,
          mimeType: 'image/jpeg',
        ),
      );
    } catch (e) {
      AppConstants.showToast('Could not add image');
    } finally {
      isBusyMedia = false;
      notifyListeners();
    }
  }

  Future<void> toggleRecording() async {
    if (note == null) return;
    if (isRecording) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }

  Future<void> startRecording() async {
    if (note == null || isRecording) return;
    captureInsertAnchor();
    try {
      await _recorder.start(ownerId: note!.ownerId, noteId: note!.noteId);
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
      _insertMediaAtAnchor(
        DocumentBlock(
          id: _uuid.v4(),
          type: DocumentBlockType.audio,
          content: 'Voice note $count',
          localPath: result.file.path,
          mimeType: 'audio/mp4',
          durationMs: result.durationMs,
        ),
      );
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
    _pendingInsert = null;
    notifyListeners();
  }

  void beginRenameAudio(String blockId) {
    editingAudioId = blockId;
    notifyListeners();
  }

  void renameAudio(String blockId, String rawTitle) {
    final index = blocks.indexWhere((b) => b.id == blockId);
    if (index < 0 || blocks[index].type != DocumentBlockType.audio) {
      editingAudioId = null;
      notifyListeners();
      return;
    }
    final cleaned = rawTitle.trim().isEmpty ? 'Voice note' : rawTitle.trim();
    editingAudioId = null;
    if (blocks[index].content != cleaned) {
      blocks[index] = blocks[index].copyWith(content: cleaned);
      _markDirty();
    } else {
      notifyListeners();
    }
  }

  Future<void> removeBlock(String blockId) async {
    final index = blocks.indexWhere((b) => b.id == blockId);
    if (index < 0) return;
    final block = blocks[index];

    if (block.type == DocumentBlockType.image ||
        block.type == DocumentBlockType.audio) {
      if (block.localPath.isNotEmpty) {
        final f = File(block.localPath);
        if (await f.exists()) {
          try {
            await f.delete();
          } catch (_) {}
        }
      }
      if (block.storagePath.isNotEmpty) {
        await NoteMediaStorage.deleteObject(block.storagePath);
      }
    }

    blocks.removeAt(index);
    _textControllers.remove(blockId)?.dispose();
    _textFocusNodes.remove(blockId)?.dispose();

    if (blocks.isEmpty) {
      addTextBlock();
    } else {
      _markDirty();
    }
  }

  Future<String?> resolveMediaUrl(DocumentBlock block) async {
    if (block.localPath.isNotEmpty && File(block.localPath).existsSync()) {
      return block.localPath;
    }
    if (block.storagePath.isNotEmpty) {
      try {
        return await NoteMediaStorage.createSignedUrl(block.storagePath);
      } catch (_) {
        return null;
      }
    }
    return null;
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
      final doc = DocumentData(blocks: List.of(blocks));
      final updated = await _repo.updateDocument(
        note!,
        documentData: doc.encode(),
        title: titleController.text.trim().isEmpty
            ? 'Document'
            : titleController.text,
        bodyPreview: doc.previewText,
      );
      note = updated;
      blocks = List.of(updated.document.blocks);
      _syncTextControllers();
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
        AppConstants.showToast('Could not save document');
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
    } catch (_) {
      AppConstants.showToast('Could not update pin');
    }
  }

  Future<bool> deleteNote() async {
    if (note == null) return false;
    _debounceTimer?.cancel();
    if (isRecording) await cancelRecording();
    try {
      await _repo.deleteNote(note!);
      return true;
    } catch (_) {
      AppConstants.showToast('Could not delete note');
      return false;
    }
  }

  bool get _isDocumentEmpty {
    final titleEmpty = titleController.text.trim().isEmpty;
    final hasMedia = blocks.any(
      (b) =>
          b.type == DocumentBlockType.image ||
          b.type == DocumentBlockType.audio,
    );
    final hasText = blocks.any(
      (b) =>
          b.type == DocumentBlockType.text && b.content.trim().isNotEmpty,
    );
    return titleEmpty && !hasMedia && !hasText;
  }

  Future<bool> tryClose() async {
    if (isRecording) await stopRecording();
    _debounceTimer?.cancel();
    if (_isDocumentEmpty) {
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
    if (saved.year == now.year &&
        saved.month == now.month &&
        saved.day == now.day) {
      return 'Saved today $time';
    }
    return 'Saved ${saved.month}/${saved.day}/${saved.year} $time';
  }

  String formatDuration(int ms) {
    final totalSec = (ms / 1000).floor();
    final m = (totalSec ~/ 60).toString().padLeft(2, '0');
    final s = (totalSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _recordTicker?.cancel();
    titleController.removeListener(_onContentChanged);
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
