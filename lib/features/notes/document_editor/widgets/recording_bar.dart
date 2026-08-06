import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/shared/animations/app_animations.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/features/notes/document_editor/controller.dart';

class RecordingBar extends StatelessWidget {
  final DocumentEditorController controller;

  const RecordingBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.textColorRed,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.textColorRed.withValues(alpha: 0.45),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Recording  ${controller.formatDuration(controller.recordingElapsedMs)}',
            style: getMediumStyle(fontSize: 14, color: AppColors.textColor),
          ),
        ),
        TextButton(
          onPressed: controller.cancelRecording,
          child: Text(
            'Cancel',
            style: getRegularStyle(color: AppColors.textColor2),
          ),
        ),
        PressableScale(
          onTap: controller.stopRecording,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.selectedColor.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stop_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  'Stop',
                  style: getMediumStyle(fontSize: 13, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
