import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/features/notes/model/note.dart';
import 'package:noteswidgetapp/features/notes/my_notes/controller.dart';
import 'package:noteswidgetapp/features/notes/note_editor/view.dart';
import 'package:provider/provider.dart';

class MyNotesTab extends StatefulWidget {
  const MyNotesTab({super.key});

  @override
  State<MyNotesTab> createState() => _MyNotesTabState();
}

class _MyNotesTabState extends State<MyNotesTab>
    with AutomaticKeepAliveClientMixin {
  late final MyNotesController _controller;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = MyNotesController()..loadNotes();
  }

  @override
  void dispose() {
    _controller.dispose();
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
            body: _buildBody(context, controller),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _openNewNote(context, controller),
              backgroundColor: AppColors.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, MyNotesController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.notes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'No notes yet',
                style: getSemiBoldStyle(fontSize: 18, color: AppColors.textColor),
              ),
              const SizedBox(height: 8),
              Text(
                controller.isOffline
                    ? 'Offline — new notes will sync when you are back online.'
                    : 'Tap + to create your first note.',
                textAlign: TextAlign.center,
                style: getRegularStyle(color: AppColors.textColor),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (controller.isOffline)
          Container(
            width: double.infinity,
            color: Colors.orange.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              'Offline — showing saved notes. Changes will sync later.',
              style: getRegularStyle(fontSize: 12, color: AppColors.textColor),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.loadNotes,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: controller.notes.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final note = controller.notes[index];
                return ListTile(
                  title: Text(
                    note.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: getMediumStyle(color: AppColors.textColor),
                  ),
                  subtitle: Text(
                    note.body.isEmpty ? 'No content' : note.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: getRegularStyle(
                      fontSize: 13,
                      color: AppColors.textColor,
                    ),
                  ),
                  trailing: note.hasPendingSync
                      ? Icon(Icons.cloud_upload_outlined, size: 18, color: Colors.grey.shade600)
                      : null,
                  onTap: () => _openNote(context, controller, note.noteId),
                  onLongPress: () => _confirmDelete(context, controller, note),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openNewNote(BuildContext context, MyNotesController controller) async {
    final note = await controller.createNote();
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(noteId: note.noteId),
      ),
    );
    await controller.loadNotes();
  }

  Future<void> _openNote(BuildContext context, MyNotesController controller, String noteId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(noteId: noteId),
      ),
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
        title: const Text('Delete note?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.deleteNote(note);
    }
  }
}
