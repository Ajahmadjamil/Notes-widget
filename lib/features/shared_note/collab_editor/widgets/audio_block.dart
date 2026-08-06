import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/notes/document_data.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/features/shared_note/collab_editor/controller.dart';

class CollabAudioBlock extends StatefulWidget {
  final DocumentBlock block;
  final SharedCollabEditorController controller;

  const CollabAudioBlock({super.key, required this.block, required this.controller});

  @override
  State<CollabAudioBlock> createState() => _CollabAudioBlockState();
}

class _CollabAudioBlockState extends State<CollabAudioBlock> {
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
  void didUpdateWidget(covariant CollabAudioBlock oldWidget) {
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
