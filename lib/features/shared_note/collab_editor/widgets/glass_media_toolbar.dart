import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/features/shared_note/collab_editor/controller.dart';
import 'package:noteswidgetapp/features/shared_note/collab_editor/widgets/glass_tool_btn.dart';
import 'package:noteswidgetapp/features/shared_note/collab_editor/widgets/recording_bar.dart';

class CollabGlassMediaToolbar extends StatelessWidget {
  final SharedCollabEditorController controller;

  const CollabGlassMediaToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 8, 14, bottom > 0 ? bottom : 12),
      child: AppContainer(
        borderRadius: 28,
        blur: 20,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: controller.isRecording
            ? CollabRecordingBar(controller: controller)
            : controller.textOnly
                ? Row(
                    children: [
                      CollabGlassToolBtn(
                        icon: Icons.text_fields_rounded,
                        label: 'Text',
                        onTap: controller.addTextBlock,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      CollabGlassToolBtn(
                        icon: Icons.text_fields_rounded,
                        label: 'Text',
                        onTap: controller.addTextBlock,
                      ),
                      CollabGlassToolBtn(
                        icon: Icons.photo_camera_rounded,
                        label: 'Camera',
                        onTap: controller.isBusyMedia
                            ? null
                            : () => controller.addImage(ImageSource.camera),
                      ),
                      CollabGlassToolBtn(
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        onTap: controller.isBusyMedia
                            ? null
                            : () => controller.addImage(ImageSource.gallery),
                      ),
                      CollabGlassToolBtn(
                        icon: Icons.mic_rounded,
                        label: 'Audio',
                        accent: true,
                        onTap: controller.toggleRecording,
                      ),
                    ],
                  ),
      ),
    );
  }
}
