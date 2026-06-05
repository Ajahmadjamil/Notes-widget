import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/shared/animations/app_animations.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/features/notes/model/note.dart';
import 'package:noteswidgetapp/features/notes/my_notes/controller.dart';
import 'package:noteswidgetapp/features/notes/note_editor/view.dart';
import 'package:provider/provider.dart';

/// Standalone notes tab — used only if navigated to directly.
class MyNotesTab extends StatefulWidget {
  final MyNotesController? controller;

  const MyNotesTab({super.key, this.controller});

  @override
  State<MyNotesTab> createState() => _MyNotesTabState();
}

class _MyNotesTabState extends State<MyNotesTab>
    with AutomaticKeepAliveClientMixin {
  MyNotesController? _ownController;

  MyNotesController get _controller => widget.controller ?? _ownController!;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _ownController = MyNotesController()..loadNotes();
    }
  }

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<MyNotesController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: AppColors.bgColor,
            body: _buildBody(context, controller),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _openNewNote(context, controller),
              backgroundColor: AppColors.primaryColor,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, MyNotesController controller) {
    if (controller.isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.selectedColor));
    }

    if (controller.notes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AppContainer(
            borderRadius: 28,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.note_add_outlined, size: 48, color: AppColors.textColor2),
                const SizedBox(height: 16),
                Text('No notes yet', style: getSemiBoldStyle(fontSize: 18, color: AppColors.textColor)),
                const SizedBox(height: 8),
                Text(
                  'Tap + to create your first note.',
                  textAlign: TextAlign.center,
                  style: getRegularStyle(color: AppColors.textColor2),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.selectedColor,
      onRefresh: controller.loadNotes,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        itemCount: controller.notes.length,
        itemBuilder: (context, index) {
          final note = controller.notes[index];
          return StaggeredFadeSlideIn(
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _NoteCard(
                note: note,
                onTap: () => _openNote(context, controller, note.noteId),
                onLongPress: () => _confirmDelete(context, controller, note),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openNewNote(BuildContext context, MyNotesController controller) async {
    final note = await controller.createNote();
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NoteEditorScreen(noteId: note.noteId)),
    );
    await controller.loadNotes();
  }

  Future<void> _openNote(BuildContext context, MyNotesController controller, String noteId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NoteEditorScreen(noteId: noteId)),
    );
    await controller.loadNotes();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    MyNotesController controller,
    Note note,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete note?', style: getSemiBoldStyle(color: AppColors.textColor)),
        content: Text('This cannot be undone.', style: getRegularStyle(color: AppColors.textColor2)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) await controller.deleteNote(note);
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _NoteCard({required this.note, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      borderRadius: 20,
      onTap: onTap,
      onLongPress: onLongPress,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            note.title.isEmpty ? 'Untitled' : note.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: getSemiBoldStyle(fontSize: 15, color: AppColors.textColor),
          ),
          if (note.body.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              note.body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: getRegularStyle(fontSize: 13, color: AppColors.textColor2),
            ),
          ],
        ],
      ),
    );
  }
}
