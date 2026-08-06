import 'dart:io';

import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/notes/document_data.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/features/notes/document_editor/controller.dart';
import 'package:noteswidgetapp/features/notes/document_editor/widgets/image_preview_overlay.dart';

class ImageBlock extends StatelessWidget {
  final DocumentBlock block;
  final DocumentEditorController controller;

  const ImageBlock({super.key, required this.block, required this.controller});

  Future<void> _openPreview(BuildContext context, String path) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, animation, __) {
          return FadeTransition(
            opacity: animation,
            child: ImagePreviewOverlay(
              path: path,
              heroTag: 'doc_img_${block.id}',
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: FutureBuilder<String?>(
        future: controller.resolveMediaUrl(block),
        builder: (context, snapshot) {
          final path = snapshot.data;
          if (path == null) {
            return Container(
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.glassFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: snapshot.connectionState == ConnectionState.waiting
                  ? CircularProgressIndicator(color: AppColors.selectedColor)
                  : Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.textColor2,
                    ),
            );
          }

          final image = path.startsWith('http')
              ? Image.network(
                  path,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  gaplessPlayback: true,
                )
              : Image.file(
                  File(path),
                  fit: BoxFit.contain,
                  width: double.infinity,
                  gaplessPlayback: true,
                );

          return Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () => _openPreview(context, path),
                child: Hero(
                  tag: 'doc_img_${block.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.glassBorder),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.selectedColor.withValues(
                              alpha: 0.08,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: image,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.drag_indicator_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => controller.removeBlock(block.id),
                    child: const Padding(
                      padding: EdgeInsets.all(7),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
