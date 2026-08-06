import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/notes/document_data.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/features/shared_note/collab_editor/controller.dart';
import 'package:noteswidgetapp/features/shared_note/collab_editor/widgets/audio_block.dart';
import 'package:noteswidgetapp/features/shared_note/collab_editor/widgets/image_block.dart';
import 'package:noteswidgetapp/features/shared_note/collab_editor/widgets/text_block.dart';

class CollabBlockTile extends StatelessWidget {
  final DocumentBlock block;
  final int index;
  final SharedCollabEditorController controller;

  const CollabBlockTile({
    super.key,
    required this.block,
    required this.index,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final author = controller.authorLabelFor(block);
    final content = switch (block.type) {
      DocumentBlockType.text => CollabTextBlock(
          block: block,
          index: index,
          controller: controller,
        ),
      DocumentBlockType.image => CollabImageBlock(
          block: block,
          controller: controller,
        ),
      DocumentBlockType.audio => CollabAudioBlock(
          block: block,
          controller: controller,
        ),
    };

    if (author.isEmpty) return content;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: index == 0 ? 4 : 8,
            bottom: 2,
          ),
          child: Text(
            author,
            style: getMediumStyle(
              fontSize: 12,
              color: AppColors.selectedColor,
            ),
          ),
        ),
        content,
      ],
    );
  }
}
