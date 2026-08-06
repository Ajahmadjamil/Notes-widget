import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/shared/animations/app_animations.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/shared/widgets/editor_title_divider.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/features/shared_note/editor/controller.dart';
import 'package:noteswidgetapp/features/shared_note/editor/widgets/shared_note_app_bar.dart';
import 'package:provider/provider.dart';

class SharedNoteEditorScreen extends StatefulWidget {
  final String sharedNoteId;
  final String friendLabel;
  final String? friendUid;

  const SharedNoteEditorScreen({
    super.key,
    required this.sharedNoteId,
    required this.friendLabel,
    this.friendUid,
  });

  @override
  State<SharedNoteEditorScreen> createState() => _SharedNoteEditorScreenState();
}

class _SharedNoteEditorScreenState extends State<SharedNoteEditorScreen> {
  late final SharedNoteEditorController _controller;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _controller = SharedNoteEditorController(
      sharedNoteId: widget.sharedNoteId,
      friendLabel: widget.friendLabel,
      friendUid: widget.friendUid,
    )..init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBack() async {
    if (_isClosing || !mounted) return;
    _isClosing = true;
    try {
      final canClose = await _controller.tryClose();
      if (!canClose || !mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } finally {
      _isClosing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<SharedNoteEditorController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return Scaffold(
              backgroundColor: AppColors.bgColor,
              appBar: AppBar(
                backgroundColor: AppColors.bgColor,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: AppColors.textColor),
                  onPressed: _handleBack,
                ),
                title: Text(
                  widget.friendLabel,
                  style: getMediumStyle(color: AppColors.textColor),
                ),
              ),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.selectedColor),
                    const SizedBox(height: 16),
                    Text(
                      'Loading shared note…',
                      style: getRegularStyle(color: AppColors.textColor2),
                    ),
                  ],
                ),
              ),
            );
          }

          if (controller.note == null) {
            return Scaffold(
              backgroundColor: AppColors.bgColor,
              appBar: AppBar(
                backgroundColor: AppColors.bgColor,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: AppColors.textColor),
                  onPressed: _handleBack,
                ),
                title: Text('Shared note', style: getMediumStyle(color: AppColors.textColor)),
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: AppContainer(
                    borderRadius: 24,
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.textColor2),
                        const SizedBox(height: 16),
                        Text(
                          controller.loadError ?? 'Shared note not found',
                          textAlign: TextAlign.center,
                          style: getRegularStyle(color: AppColors.textColor2),
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () => controller.retryLoad(),
                          child: Text(
                            'Try again',
                            style: getMediumStyle(color: AppColors.primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              await _handleBack();
            },
            child: Scaffold(
              backgroundColor: AppColors.bgColor,
              appBar: SharedNoteAppBar(
                controller: controller,
                onBack: _handleBack,
              ),
              body: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: AppContainer(
                        borderRadius: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Icon(Icons.people_outline_rounded, size: 16, color: AppColors.primaryColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Shared with ${widget.friendLabel} — edits sync live',
                                style: getRegularStyle(
                                  fontSize: 12,
                                  color: AppColors.textColor2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: FadeSlideIn(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          child: AppContainer(
                            borderRadius: 28,
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
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
                                        color: AppColors.textFieldPlaceHolderColor,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    textCapitalization: TextCapitalization.sentences,
                                    textInputAction: TextInputAction.next,
                                    onSubmitted: (_) => controller.bodyFocusNode.requestFocus(),
                                    maxLines: null,
                                  ),
                                  const EditorTitleDivider(),
                                  TextField(
                                    controller: controller.bodyController,
                                    focusNode: controller.bodyFocusNode,
                                    style: getRegularStyle(
                                      fontSize: 16,
                                      color: AppColors.textColor,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Write together…',
                                      hintStyle: getRegularStyle(
                                        fontSize: 16,
                                        color: AppColors.textFieldPlaceHolderColor,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    keyboardType: TextInputType.multiline,
                                    textCapitalization: TextCapitalization.sentences,
                                    maxLines: null,
                                    minLines: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
