import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/notes/document_data.dart';
import 'package:noteswidgetapp/core/shared/animations/app_animations.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/shared/widgets/editor_title_divider.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/features/notes/document_editor/controller.dart';
import 'package:noteswidgetapp/features/notes/document_editor/widgets/block_tile.dart';
import 'package:noteswidgetapp/features/notes/document_editor/widgets/doc_app_bar.dart';
import 'package:noteswidgetapp/features/notes/document_editor/widgets/glass_media_toolbar.dart';
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
              appBar: DocAppBar(controller: controller),
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
                                      final tile = BlockTile(
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
                      GlassMediaToolbar(controller: controller),
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
