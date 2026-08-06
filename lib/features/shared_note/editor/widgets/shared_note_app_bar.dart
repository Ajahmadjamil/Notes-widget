import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/features/notes/note_editor/controller.dart';
import 'package:noteswidgetapp/features/shared_note/editor/controller.dart';

class SharedNoteAppBar extends StatelessWidget implements PreferredSizeWidget {
  final SharedNoteEditorController controller;
  final VoidCallback onBack;

  const SharedNoteAppBar({
    super.key,
    required this.controller,
    required this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.bgColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: AppColors.textColor),
        onPressed: onBack,
      ),
      title: Column(
        children: [
          Text(
            controller.friendLabel,
            style: getMediumStyle(fontSize: 14, color: AppColors.textColor),
          ),
          Text(
            controller.statusLabel,
            style: getRegularStyle(
              fontSize: 12,
              color: AppColors.textColor2,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        if (controller.saveStatus == EditorSaveStatus.unsaved)
          TextButton(
            onPressed: () => controller.save(),
            child: Text(
              'Save',
              style: getMediumStyle(color: AppColors.primaryColor),
            ),
          ),
      ],
    );
  }
}
