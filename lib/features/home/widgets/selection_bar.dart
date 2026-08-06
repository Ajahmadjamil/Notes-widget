import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/features/notes/my_notes/controller.dart';

class SelectionBar extends StatelessWidget {
  final MyNotesController controller;

  const SelectionBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final count = controller.selectedNoteIds.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: AppContainer(
        borderRadius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Text(
              '$count selected',
              style: getSemiBoldStyle(fontSize: 13, color: AppColors.textColor),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Pin',
              onPressed: count == 0
                  ? null
                  : () => controller.pinSelected(pinned: true),
              icon: Icon(
                Icons.push_pin_outlined,
                color: AppColors.selectedColor,
                size: 20,
              ),
            ),
            IconButton(
              tooltip: 'Unpin',
              onPressed: count == 0
                  ? null
                  : () => controller.pinSelected(pinned: false),
              icon: Icon(
                Icons.push_pin_rounded,
                color: AppColors.textColor2,
                size: 20,
              ),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed: count == 0
                  ? null
                  : () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppColors.bgColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: Text(
                            'Delete $count note(s)?',
                            style: getSemiBoldStyle(color: AppColors.textColor),
                          ),
                          content: Text(
                            'This cannot be undone.',
                            style: getRegularStyle(color: AppColors.textColor2),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) await controller.deleteSelected();
                    },
              icon: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.textColorRed,
                size: 20,
              ),
            ),
            IconButton(
              tooltip: 'Cancel',
              onPressed: controller.exitSelection,
              icon: Icon(
                Icons.close_rounded,
                color: AppColors.textColor2,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
