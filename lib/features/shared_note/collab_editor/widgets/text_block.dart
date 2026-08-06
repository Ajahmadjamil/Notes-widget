import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/notes/document_data.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/features/shared_note/collab_editor/controller.dart';

class CollabTextBlock extends StatelessWidget {
  final DocumentBlock block;
  final int index;
  final SharedCollabEditorController controller;

  const CollabTextBlock({
    super.key,
    required this.block,
    required this.index,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
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
  }
}
