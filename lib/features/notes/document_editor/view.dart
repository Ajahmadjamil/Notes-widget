import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:noteswidgetapp/core/notes/document_data.dart';
import 'package:noteswidgetapp/core/shared/animations/app_animations.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/shared/widgets/editor_title_divider.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/features/notes/document_editor/controller.dart';
import 'package:noteswidgetapp/features/notes/note_editor/controller.dart';
import 'package:provider/provider.dart';

class DocumentEditorScreen extends StatelessWidget {
  final String noteId;

  const DocumentEditorScreen({super.key, required this.noteId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DocumentEditorController(noteId: noteId)..load(),
      child: Consumer<DocumentEditorController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return Scaffold(
              backgroundColor: AppColors.bgColor,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.selectedColor),
              ),
            );
          }

          if (controller.note == null) {
            return Scaffold(
              backgroundColor: AppColors.bgColor,
              appBar: AppBar(
                backgroundColor: AppColors.bgColor,
                title: Text(
                  'Document',
                  style: getMediumStyle(color: AppColors.textColor),
                ),
              ),
              body: Center(
                child: Text(
                  'Document not found',
                  style: getRegularStyle(color: AppColors.textColor2),
                ),
              ),
            );
          }

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              final canClose = await controller.tryClose();
              if (canClose && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Scaffold(
              backgroundColor: AppColors.bgColor,
              appBar: _DocAppBar(controller: controller),
              body: SafeArea(
                child: FadeSlideIn(
                  child: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                          child: AppContainer(
                            borderRadius: 24,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      tooltip: controller.note!.isPinned
                                          ? 'Unpin'
                                          : 'Pin',
                                      onPressed: controller.togglePin,
                                      icon: Icon(
                                        controller.note!.isPinned
                                            ? Icons.push_pin_rounded
                                            : Icons.push_pin_outlined,
                                        color: controller.note!.isPinned
                                            ? AppColors.selectedColor
                                            : AppColors.textColor2,
                                        size: 22,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete',
                                      onPressed: () =>
                                          _confirmDelete(context, controller),
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        color: AppColors.textColorRed,
                                        size: 22,
                                      ),
                                    ),
                                  ],
                                ),
                                TextField(
                                  controller: controller.titleController,
                                  focusNode: controller.titleFocusNode,
                                  style: getSemiBoldStyle(
                                    fontSize: 22,
                                    color: AppColors.textColor,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Title',
                                    hintStyle: getSemiBoldStyle(
                                      fontSize: 22,
                                      color:
                                          AppColors.textFieldPlaceHolderColor,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  maxLines: null,
                                ),
                                const EditorTitleDivider(),
                                Expanded(
                                  child: ReorderableListView.builder(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    buildDefaultDragHandles: false,
                                    proxyDecorator: (child, index, animation) {
                                      return AnimatedBuilder(
                                        animation: animation,
                                        builder: (context, _) {
                                          return Material(
                                            color: Colors.transparent,
                                            elevation: 6 * animation.value,
                                            shadowColor: AppColors.selectedColor
                                                .withValues(alpha: 0.25),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            child: child,
                                          );
                                        },
                                      );
                                    },
                                    itemCount: controller.blocks.length,
                                    onReorderItem: controller.reorderBlocks,
                                    itemBuilder: (context, index) {
                                      final block = controller.blocks[index];
                                      final tile = _BlockTile(
                                        block: block,
                                        index: index,
                                        controller: controller,
                                      );
                                      final isMedia =
                                          block.type == DocumentBlockType.image ||
                                              block.type ==
                                                  DocumentBlockType.audio;
                                      return KeyedSubtree(
                                        key: ValueKey(block.id),
                                        child: isMedia
                                            ? ReorderableDelayedDragStartListener(
                                                index: index,
                                                child: tile,
                                              )
                                            : tile,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _GlassMediaToolbar(controller: controller),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    DocumentEditorController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete document?',
          style: getSemiBoldStyle(color: AppColors.textColor),
        ),
        content: Text(
          'This document and its media will be permanently deleted.',
          style: getRegularStyle(color: AppColors.textColor2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: TextStyle(color: AppColors.textColorRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    final ok = await controller.deleteNote();
    if (ok && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _DocAppBar extends StatelessWidget implements PreferredSizeWidget {
  final DocumentEditorController controller;

  const _DocAppBar({required this.controller});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.bgColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: AppColors.textColor),
        onPressed: () async {
          final canClose = await controller.tryClose();
          if (canClose && context.mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
      title: Text(
        controller.statusLabel,
        style: getRegularStyle(
          fontSize: 13,
          color: _statusColor(controller.saveStatus),
        ),
      ),
      centerTitle: true,
      actions: [
        if (controller.saveStatus == EditorSaveStatus.unsaved)
          TextButton(
            onPressed: controller.saveStatus == EditorSaveStatus.saving
                ? null
                : () => controller.save(),
            child: Text(
              'Save',
              style: getMediumStyle(color: AppColors.primaryColor),
            ),
          ),
      ],
    );
  }

  Color _statusColor(EditorSaveStatus status) {
    switch (status) {
      case EditorSaveStatus.error:
        return AppColors.textColorRed;
      case EditorSaveStatus.unsaved:
        return AppColors.primaryColor;
      case EditorSaveStatus.saving:
        return AppColors.textColor2;
      default:
        return AppColors.textColor2;
    }
  }
}

/// Floating glass media bar — matches app glassmorphic theme.
class _GlassMediaToolbar extends StatelessWidget {
  final DocumentEditorController controller;

  const _GlassMediaToolbar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 8, 14, bottom > 0 ? bottom : 12),
      child: AppContainer(
        borderRadius: 28,
        blur: 20,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: controller.isRecording
            ? _RecordingBar(controller: controller)
            : Row(
                children: [
                  _GlassToolBtn(
                    icon: Icons.text_fields_rounded,
                    label: 'Text',
                    onTap: controller.addTextBlock,
                  ),
                  _GlassToolBtn(
                    icon: Icons.photo_camera_rounded,
                    label: 'Camera',
                    onTap: controller.isBusyMedia
                        ? null
                        : () => controller.addImage(ImageSource.camera),
                  ),
                  _GlassToolBtn(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: controller.isBusyMedia
                        ? null
                        : () => controller.addImage(ImageSource.gallery),
                  ),
                  _GlassToolBtn(
                    icon: Icons.mic_rounded,
                    label: 'Audio',
                    accent: true,
                    onTap: controller.toggleRecording,
                  ),
                ],
              ),
      ),
    );
  }
}

class _RecordingBar extends StatelessWidget {
  final DocumentEditorController controller;

  const _RecordingBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.textColorRed,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.textColorRed.withValues(alpha: 0.45),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Recording  ${controller.formatDuration(controller.recordingElapsedMs)}',
            style: getMediumStyle(fontSize: 14, color: AppColors.textColor),
          ),
        ),
        TextButton(
          onPressed: controller.cancelRecording,
          child: Text(
            'Cancel',
            style: getRegularStyle(color: AppColors.textColor2),
          ),
        ),
        PressableScale(
          onTap: controller.stopRecording,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.selectedColor.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stop_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  'Stop',
                  style: getMediumStyle(fontSize: 13, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool accent;

  const _GlassToolBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final iconColor = !enabled
        ? AppColors.textColor2.withValues(alpha: 0.35)
        : accent
            ? AppColors.selectedColor
            : AppColors.textColor;

    return Expanded(
      child: PressableScale(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent
                    ? AppColors.selectedColor.withValues(alpha: 0.14)
                    : AppColors.glassFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: accent
                      ? AppColors.selectedColor.withValues(alpha: 0.35)
                      : AppColors.glassBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.selectedColor.withValues(
                      alpha: accent ? 0.12 : 0.04,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: getRegularStyle(
                fontSize: 11,
                color: enabled
                    ? AppColors.textColor2
                    : AppColors.textColor2.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockTile extends StatelessWidget {
  final DocumentBlock block;
  final int index;
  final DocumentEditorController controller;

  const _BlockTile({
    required this.block,
    required this.index,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    switch (block.type) {
      case DocumentBlockType.text:
        // Word-like: plain flowing text, no delete chrome on text.
        final isFirstText = !controller.blocks
            .take(index)
            .any((b) => b.type == DocumentBlockType.text);
        return Padding(
          padding: EdgeInsets.only(
            top: index == 0 ? 0 : 4,
            bottom: 4,
          ),
          child: TextField(
            controller: controller.textControllerFor(block.id),
            focusNode: controller.textFocusNodeFor(block.id),
            style: getRegularStyle(
              fontSize: 16,
              color: AppColors.textColor,
            ).copyWith(height: 1.45),
            decoration: InputDecoration(
              hintText: isFirstText ? 'Start writing…' : null,
              hintStyle: getRegularStyle(
                fontSize: 16,
                color: AppColors.textFieldPlaceHolderColor,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            maxLines: null,
          ),
        );
      case DocumentBlockType.image:
        return _ImageBlock(block: block, controller: controller);
      case DocumentBlockType.audio:
        return _AudioBlock(block: block, controller: controller);
    }
  }
}

class _ImageBlock extends StatelessWidget {
  final DocumentBlock block;
  final DocumentEditorController controller;

  const _ImageBlock({required this.block, required this.controller});

  Future<void> _openPreview(BuildContext context, String path) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, animation, __) {
          return FadeTransition(
            opacity: animation,
            child: _ImagePreviewOverlay(
              path: path,
              heroTag: 'doc_img_${block.id}',
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: FutureBuilder<String?>(
        future: controller.resolveMediaUrl(block),
        builder: (context, snapshot) {
          final path = snapshot.data;
          if (path == null) {
            return Container(
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.glassFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: snapshot.connectionState == ConnectionState.waiting
                  ? CircularProgressIndicator(color: AppColors.selectedColor)
                  : Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.textColor2,
                    ),
            );
          }

          final image = path.startsWith('http')
              ? Image.network(
                  path,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  gaplessPlayback: true,
                )
              : Image.file(
                  File(path),
                  fit: BoxFit.contain,
                  width: double.infinity,
                  gaplessPlayback: true,
                );

          return Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () => _openPreview(context, path),
                child: Hero(
                  tag: 'doc_img_${block.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.glassBorder),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.selectedColor.withValues(
                              alpha: 0.08,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: image,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.drag_indicator_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => controller.removeBlock(block.id),
                    child: const Padding(
                      padding: EdgeInsets.all(7),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// WhatsApp-style fullscreen image preview (pinch + tap to dismiss).
class _ImagePreviewOverlay extends StatelessWidget {
  final String path;
  final String heroTag;

  const _ImagePreviewOverlay({
    required this.path,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final image = path.startsWith('http')
        ? Image.network(path, fit: BoxFit.contain)
        : Image.file(File(path), fit: BoxFit.contain);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
          Center(
            child: Hero(
              tag: heroTag,
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: image,
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Material(
                  color: Colors.black45,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioBlock extends StatefulWidget {
  final DocumentBlock block;
  final DocumentEditorController controller;

  const _AudioBlock({required this.block, required this.controller});

  @override
  State<_AudioBlock> createState() => _AudioBlockState();
}

class _AudioBlockState extends State<_AudioBlock> {
  final AudioPlayer _player = AudioPlayer();
  late final TextEditingController _titleController;
  late final FocusNode _titleFocus;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _source;

  bool get _isEditing =>
      widget.controller.editingAudioId == widget.block.id;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.block.audioTitle);
    _titleFocus = FocusNode();
    _titleFocus.addListener(_onTitleFocusChanged);
    _duration = Duration(milliseconds: widget.block.durationMs);
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playing = false;
          _position = Duration.zero;
        });
      }
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _prepare();
  }

  @override
  void didUpdateWidget(covariant _AudioBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing &&
        oldWidget.block.content != widget.block.content &&
        _titleController.text != widget.block.audioTitle) {
      _titleController.text = widget.block.audioTitle;
    }
    if (_isEditing && !_titleFocus.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isEditing) _titleFocus.requestFocus();
      });
    }
  }

  void _onTitleFocusChanged() {
    if (!_titleFocus.hasFocus && _isEditing) {
      widget.controller.renameAudio(widget.block.id, _titleController.text);
    }
  }

  Future<void> _prepare() async {
    final url = await widget.controller.resolveMediaUrl(widget.block);
    if (!mounted) return;
    setState(() => _source = url);
  }

  Future<void> _toggle() async {
    if (_source == null) return;
    if (_playing) {
      await _player.pause();
      setState(() => _playing = false);
      return;
    }
    if (_source!.startsWith('http')) {
      await _player.play(UrlSource(_source!));
    } else {
      await _player.play(DeviceFileSource(_source!));
    }
    setState(() => _playing = true);
  }

  void _startRename() {
    _titleController.text = widget.block.audioTitle;
    widget.controller.beginRenameAudio(widget.block.id);
  }

  @override
  void dispose() {
    _titleFocus.removeListener(_onTitleFocusChanged);
    _titleFocus.dispose();
    _titleController.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.controller.formatDuration(
      _duration.inMilliseconds > 0
          ? _duration.inMilliseconds
          : widget.block.durationMs,
    );
    final pos = widget.controller.formatDuration(_position.inMilliseconds);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AppContainer(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.drag_indicator_rounded,
              size: 18,
              color: AppColors.textColor2.withValues(alpha: 0.7),
            ),
            IconButton(
              onPressed: _source == null ? null : _toggle,
              icon: Icon(
                _playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                color: AppColors.selectedColor,
                size: 36,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isEditing)
                    TextField(
                      controller: _titleController,
                      focusNode: _titleFocus,
                      style: getMediumStyle(
                        fontSize: 14,
                        color: AppColors.textColor,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.selectedColor.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                        hintText: 'Recording name',
                        hintStyle: getRegularStyle(
                          fontSize: 14,
                          color: AppColors.textFieldPlaceHolderColor,
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (value) {
                        widget.controller.renameAudio(widget.block.id, value);
                      },
                    )
                  else
                    GestureDetector(
                      onTap: _startRename,
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        widget.block.audioTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: getMediumStyle(
                          fontSize: 14,
                          color: AppColors.textColor,
                        ),
                      ),
                    ),
                  Text(
                    _playing ? '$pos / $label' : label,
                    style: getRegularStyle(
                      fontSize: 12,
                      color: AppColors.textColor2,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Delete recording',
              onPressed: () =>
                  widget.controller.removeBlock(widget.block.id),
              icon: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.textColor2,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
