import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/shared/animations/app_animations.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/shared/widgets/editor_title_divider.dart';
import 'package:noteswidgetapp/core/shared/widgets/handwriting_canvas.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/features/notes/handwriting_editor/controller.dart';
import 'package:noteswidgetapp/features/notes/handwriting_editor/widgets/handwriting_app_bar.dart';
import 'package:provider/provider.dart';

class HandwritingEditorBody extends StatefulWidget {
  const HandwritingEditorBody({super.key});

  @override
  State<HandwritingEditorBody> createState() => _HandwritingEditorBodyState();
}

class _HandwritingEditorBodyState extends State<HandwritingEditorBody> {
  final _canvasKey = GlobalKey<HandwritingCanvasState>();

  Future<void> _confirmDelete(
    BuildContext context,
    HandwritingEditorController controller,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgColor,
        title: Text('Delete note?', style: getSemiBoldStyle(color: AppColors.textColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final deleted = await controller.deleteNote();
    if (deleted && context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HandwritingEditorController>(
      builder: (context, controller, _) {
        if (controller.isLoading) {
          return Scaffold(
            backgroundColor: AppColors.bgColor,
            body: Center(child: CircularProgressIndicator(color: AppColors.selectedColor)),
          );
        }

        if (controller.note == null) {
          return Scaffold(
            backgroundColor: AppColors.bgColor,
            appBar: AppBar(backgroundColor: AppColors.bgColor),
            body: Center(
              child: Text('Note not found', style: getRegularStyle(color: AppColors.textColor2)),
            ),
          );
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final ok = await controller.tryClose();
            if (ok && context.mounted) Navigator.of(context).pop();
          },
          child: Scaffold(
            backgroundColor: AppColors.bgColor,
            appBar: HandwritingAppBar(controller: controller),
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
                              icon: Icon(Icons.undo_rounded, color: AppColors.textColor2, size: 22),
                            ),
                            IconButton(
                              tooltip: controller.note!.isPinned ? 'Unpin' : 'Pin',
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
                              onPressed: () => _confirmDelete(context, controller),
                              icon: Icon(Icons.delete_outline_rounded, color: AppColors.textColorRed, size: 22),
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
                          onChanged: (_) => controller.onTitleChanged(),
                        ),
                        const EditorTitleDivider(),
                        Expanded(
                          child: AppContainer(
                            borderRadius: 16,
                            enableGlass: false,
                            padding: EdgeInsets.zero,
                            child: HandwritingCanvas(
                              key: _canvasKey,
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
    );
  }
}
