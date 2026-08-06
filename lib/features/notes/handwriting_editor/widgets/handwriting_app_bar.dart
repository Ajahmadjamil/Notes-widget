import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/features/notes/handwriting_editor/controller.dart';

class HandwritingAppBar extends StatelessWidget implements PreferredSizeWidget {
  final HandwritingEditorController controller;
  const HandwritingAppBar({super.key, required this.controller});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.bgColor,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: AppColors.textColor),
        onPressed: () async {
          final ok = await controller.tryClose();
          if (ok && context.mounted) Navigator.of(context).pop();
        },
      ),
      title: Text(
        controller.statusLabel,
        style: getRegularStyle(fontSize: 13, color: AppColors.textColor2),
      ),
      centerTitle: true,
    );
  }
}
