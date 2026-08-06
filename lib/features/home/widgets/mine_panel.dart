import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/shared/animations/app_animations.dart';
import 'package:noteswidgetapp/core/shared/widgets/note_grid_card.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/core/navigation/note_editor_launcher.dart';
import 'package:noteswidgetapp/features/home/widgets/empty_states.dart';
import 'package:noteswidgetapp/features/home/widgets/mine_notes_toolbar.dart';
import 'package:noteswidgetapp/features/home/widgets/selection_bar.dart';
import 'package:noteswidgetapp/features/notes/model/note.dart';
import 'package:noteswidgetapp/features/notes/my_notes/controller.dart';
import 'package:provider/provider.dart';

class MinePanel extends StatelessWidget {
  final MyNotesController controller;

  const MinePanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: Consumer<MyNotesController>(
        builder: (context, ctrl, _) {
          if (ctrl.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.selectedColor),
            );
          }

          final notes = ctrl.displayNotes;

          return Column(
            children: [
              if (ctrl.isOffline)
                AppContainer(
                  borderRadius: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_off_outlined,
                        size: 14,
                        color: AppColors.selectedColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Offline — changes sync when back online',
                          style: getRegularStyle(
                            fontSize: 11,
                            color: AppColors.textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (!ctrl.selectionMode) MineNotesToolbar(controller: ctrl),
              if (ctrl.selectionMode) SelectionBar(controller: ctrl),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.selectedColor,
                  onRefresh: ctrl.loadNotes,
                  child: ctrl.notes.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(24),
                          children: [EmptyMine(isOffline: ctrl.isOffline)],
                        )
                      : notes.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(24),
                          children: const [EmptySearch()],
                        )
                      : ListView(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            4,
                            16,
                            ctrl.selectionMode ? 16 : 100,
                          ),
                          children: [
                            FadeSlideIn(
                              child: NotesMasonryGrid(
                                notes: notes,
                                selectionMode: ctrl.selectionMode,
                                isSelected: ctrl.isSelected,
                                onTap: (note) {
                                  if (ctrl.selectionMode) {
                                    ctrl.toggleSelection(note.noteId);
                                  } else {
                                    _open(context, ctrl, note.noteId);
                                  }
                                },
                                onLongPress: (note) {
                                  if (ctrl.selectionMode) {
                                    ctrl.toggleSelection(note.noteId);
                                  } else {
                                    ctrl.enterSelection(note.noteId);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _open(
    BuildContext context,
    MyNotesController ctrl,
    String id,
  ) async {
    final Note? note = ctrl.notes.where((n) => n.noteId == id).firstOrNull;
    if (note == null) return;
    await NoteEditorLauncher.openPersonal(context, note);
    await ctrl.loadNotes();
  }
}
