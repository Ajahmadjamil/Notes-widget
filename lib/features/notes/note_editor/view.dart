import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/shared/animations/app_animations.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/shared/widgets/editor_title_divider.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/features/notes/note_editor/controller.dart';
import 'package:noteswidgetapp/features/notes/note_editor/widgets/editor_app_bar.dart';
import 'package:provider/provider.dart';

/// Keep-style plain text editor with auto-save (rich text in a future module).
class NoteEditorScreen extends StatelessWidget {
  final String noteId;

  const NoteEditorScreen({super.key, required this.noteId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NoteEditorController(noteId: noteId)..load(),
      child: Consumer<NoteEditorController>(
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
                title: Text('Note', style: getMediumStyle(color: AppColors.textColor)),
              ),
              body: Center(
                child: Text('Note not found', style: getRegularStyle(color: AppColors.textColor2)),
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
              appBar: NoteEditorAppBar(controller: controller),
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
                                tooltip: controller.note!.isPinned ? 'Unpin' : 'Pin',
                                onPressed: () => controller.togglePin(),
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
                          Expanded(
                            child: TextField(
                              controller: controller.bodyController,
                              focusNode: controller.bodyFocusNode,
                              style: getRegularStyle(
                                fontSize: 16,
                                color: AppColors.textColor,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Take a note…',
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
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
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

  Future<void> _confirmDelete(BuildContext context, NoteEditorController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete note?', style: getSemiBoldStyle(color: AppColors.textColor)),
        content: Text(
          'This note will be permanently deleted.',
          style: getRegularStyle(color: AppColors.textColor2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: AppColors.textColorRed)),
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
