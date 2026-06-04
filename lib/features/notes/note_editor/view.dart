import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/features/notes/note_editor/controller.dart';
import 'package:provider/provider.dart';

/// Keep-style plain text editor with auto-save (rich text in a future module).
class NoteEditorScreen extends StatelessWidget {
  final String noteId;

  const NoteEditorScreen({super.key, required this.noteId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NoteEditorController(noteId: noteId)..load(),
      child: Consumer<NoteEditorController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return Scaffold(
              backgroundColor: Colors.white,
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (controller.note == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Note')),
              body: const Center(child: Text('Note not found')),
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
              backgroundColor: Colors.white,
              appBar: _EditorAppBar(controller: controller),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
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
                            color: AppColors.textFieldPlaceHolderColor,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => controller.bodyFocusNode.requestFocus(),
                        maxLines: null,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: controller.bodyController,
                        focusNode: controller.bodyFocusNode,
                        style: getRegularStyle(
                          fontSize: 16,
                          color: AppColors.textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Take a note…',
                          hintStyle: getRegularStyle(
                            fontSize: 16,
                            color: AppColors.textFieldPlaceHolderColor,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: null,
                        minLines: 12,
                      ),
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

class _EditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final NoteEditorController controller;

  const _EditorAppBar({required this.controller});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppColors.textColor),
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
        IconButton(
          icon: Icon(Icons.delete_outline, color: AppColors.textColorRed),
          onPressed: () => _confirmDelete(context),
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

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This note will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: AppColors.textColorRed)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final ok = await controller.deleteNote();
    if (ok && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
