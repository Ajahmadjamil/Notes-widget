import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/shared/animations/app_animations.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/shared/widgets/editor_title_divider.dart';
import 'package:noteswidgetapp/core/shared/widgets/shared_handwriting_canvas.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/core/widget/widget_drawing_dimensions.dart';
import 'package:noteswidgetapp/features/shared_note/handwriting_editor/controller.dart';
import 'package:provider/provider.dart';

class SharedHandwritingEditorScreen extends StatefulWidget {
  final String sharedNoteId;
  final String friendLabel;
  final String? friendUid;

  const SharedHandwritingEditorScreen({
    super.key,
    required this.sharedNoteId,
    required this.friendLabel,
    this.friendUid,
  });

  @override
  State<SharedHandwritingEditorScreen> createState() =>
      _SharedHandwritingEditorScreenState();
}

class _SharedHandwritingEditorScreenState
    extends State<SharedHandwritingEditorScreen> {
  late final SharedHandwritingEditorController _controller;
  final _canvasKey = GlobalKey<SharedHandwritingCanvasState>();
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _controller = SharedHandwritingEditorController(
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
      final ok = await _controller.tryClose();
      if (ok && mounted) Navigator.of(context).pop();
    } finally {
      _isClosing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<SharedHandwritingEditorController>(
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
              appBar: AppBar(backgroundColor: AppColors.bgColor),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      controller.loadError ?? 'Shared note not found',
                      textAlign: TextAlign.center,
                      style: getRegularStyle(color: AppColors.textColor2),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: controller.retryLoad,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final padWidth = MediaQuery.sizeOf(context).width - 56;
          final padHeight = WidgetDrawingDimensions.heightForWidth(padWidth);

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) async {
              if (didPop) return;
              await _handleBack();
            },
            child: Scaffold(
              backgroundColor: AppColors.bgColor,
              appBar: AppBar(
                backgroundColor: AppColors.bgColor,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: AppColors.textColor),
                  onPressed: _handleBack,
                ),
                title: Column(
                  children: [
                    Text(
                      widget.friendLabel,
                      style: getSemiBoldStyle(fontSize: 14, color: AppColors.textColor),
                    ),
                    Text(
                      controller.statusLabel,
                      style: getRegularStyle(fontSize: 11, color: AppColors.textColor2),
                    ),
                  ],
                ),
                centerTitle: true,
              ),
              body: SafeArea(
                child: FadeSlideIn(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    child: AppContainer(
                      borderRadius: 24,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                tooltip: 'Undo',
                                onPressed: () => _canvasKey.currentState?.undo(),
                                icon: Icon(
                                  Icons.undo_rounded,
                                  color: AppColors.textColor2,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                          TextField(
                            controller: controller.titleController,
                            focusNode: controller.titleFocusNode,
                            style: getSemiBoldStyle(fontSize: 22, color: AppColors.textColor),
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
                          ),
                          const EditorTitleDivider(),
                          Text(
                            'Pinch with two fingers to zoom',
                            style: getRegularStyle(fontSize: 11, color: AppColors.textColor2),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: AppContainer(
                              borderRadius: 16,
                              enableGlass: false,
                              padding: EdgeInsets.zero,
                              child: SharedHandwritingCanvas(
                                key: _canvasKey,
                                canvasWidth: padWidth,
                                canvasHeight: padHeight,
                                initialData: controller.drawingData,
                                onChanged: controller.onDrawingChanged,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
