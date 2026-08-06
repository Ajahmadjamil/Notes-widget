import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/notes/document_data.dart';
import 'package:noteswidgetapp/core/shared/animations/app_animations.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/shared/widgets/editor_title_divider.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/features/shared_note/collab_editor/controller.dart';
import 'package:noteswidgetapp/features/shared_note/collab_editor/widgets/block_tile.dart';
import 'package:noteswidgetapp/features/shared_note/collab_editor/widgets/collab_app_bar.dart';
import 'package:noteswidgetapp/features/shared_note/collab_editor/widgets/glass_media_toolbar.dart';
import 'package:provider/provider.dart';

class SharedCollabEditorScreen extends StatelessWidget {
  final String sharedNoteId;
  final String friendLabel;
  final String? friendUid;
  final bool textOnly;

  const SharedCollabEditorScreen({
    super.key,
    required this.sharedNoteId,
    required this.friendLabel,
    this.friendUid,
    this.textOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SharedCollabEditorController(
        sharedNoteId: sharedNoteId,
        friendLabel: friendLabel,
        friendUid: friendUid,
        textOnly: textOnly,
      )..init(),
      child: Consumer<SharedCollabEditorController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return Scaffold(
              backgroundColor: AppColors.bgColor,
              body: Center(
                child: CircularProgressIndicator(
                  color: AppColors.selectedColor,
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
                title: Text(
                  friendLabel,
                  style: getMediumStyle(color: AppColors.textColor),
                ),
              ),
              body: Center(
                child: Text(
                  controller.loadError ?? 'Shared note not found',
                  style: getRegularStyle(color: AppColors.textColor2),
                  textAlign: TextAlign.center,
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
              appBar: CollabAppBar(controller: controller),
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
                                      final tile = CollabBlockTile(
                                        block: block,
                                        index: index,
                                        controller: controller,
                                      );
                                      final isMedia =
                                          block.type ==
                                              DocumentBlockType.image ||
                                          block.type == DocumentBlockType.audio;
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
                      CollabGlassMediaToolbar(controller: controller),
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
}
