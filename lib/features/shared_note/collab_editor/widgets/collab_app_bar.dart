import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/features/notes/note_editor/controller.dart';
import 'package:noteswidgetapp/features/shared_note/collab_editor/controller.dart';

class CollabAppBar extends StatelessWidget implements PreferredSizeWidget {
  final SharedCollabEditorController controller;

  const CollabAppBar({super.key, required this.controller});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.bgColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: AppColors.textColor),
        onPressed: () async {
          final canClose = await controller.tryClose();
          if (canClose && context.mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
      title: Text(
        controller.statusLabel,
        style: getRegularStyle(
          fontSize: 13,
          color: _statusColor(controller.saveStatus),
        ),
      ),
      centerTitle: true,
      actions: [
        if (controller.saveStatus == EditorSaveStatus.unsaved)
          TextButton(
            onPressed: controller.saveStatus == EditorSaveStatus.saving
                ? null
                : () => controller.save(),
            child: Text(
              'Save',
              style: getMediumStyle(color: AppColors.primaryColor),
            ),
          ),
      ],
    );
  }

  Color _statusColor(EditorSaveStatus status) {
    switch (status) {
      case EditorSaveStatus.error:
        return AppColors.textColorRed;
      case EditorSaveStatus.unsaved:
        return AppColors.primaryColor;
      case EditorSaveStatus.saving:
        return AppColors.textColor2;
      default:
        return AppColors.textColor2;
    }
  }
}
