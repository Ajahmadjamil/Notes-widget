import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/shared/animations/app_animations.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/shared/widgets/note_grid_card.dart';
import 'package:noteswidgetapp/core/shared/widgets/segment_toggle.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/features/home/shared_notes_panel.dart';
import 'package:noteswidgetapp/features/notes/model/note.dart';
import 'package:noteswidgetapp/features/notes/my_notes/controller.dart';
import 'package:noteswidgetapp/core/navigation/note_editor_launcher.dart';
import 'package:noteswidgetapp/core/supabase/app_supabase.dart';
import 'package:noteswidgetapp/features/profile/model/user_profile.dart';
import 'package:noteswidgetapp/features/profile/repository/user_profile_repository.dart';
import 'package:provider/provider.dart';

class HomeTabView extends StatefulWidget {
  final MyNotesController notesController;
  final VoidCallback? onSegmentChanged;

  const HomeTabView({
    super.key,
    required this.notesController,
    this.onSegmentChanged,
  });

  @override
  State<HomeTabView> createState() => HomeTabViewState();
}

class HomeTabViewState extends State<HomeTabView>
    with AutomaticKeepAliveClientMixin {
  int _segment = 0;
  String _userName = '';

  @override
  bool get wantKeepAlive => true;

  bool get isMineSelected => _segment == 0;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final uid = AppSupabase.currentUserId;
    if (uid == null) return;

    final profile = await UserProfileRepository().fetchProfile(uid);
    final name = _resolveDisplayName(profile);
    if (mounted) setState(() => _userName = name);
  }

  String _resolveDisplayName(UserProfile? profile) {
    final display = profile?.displayName?.trim();
    if (display != null && display.isNotEmpty) {
      return _capitalize(display.split(' ').first);
    }

    final username = profile?.username?.trim();
    if (username != null && username.isNotEmpty) {
      return _capitalize(username);
    }

    final email = profile?.email ?? AppSupabase.currentUser?.email;
    if (email != null && email.contains('@')) {
      return _capitalize(email.split('@').first);
    }

    return 'there';
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: FadeSlideIn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: getBoldStyle(
                      fontSize: 28,
                      color: AppColors.textColor,
                    ),
                    children: [
                      const TextSpan(text: 'Welcome '),
                      TextSpan(
                        text: _userName.isEmpty ? '…' : _userName,
                        style: getBoldStyle(
                          fontSize: 28,
                          color: AppColors.selectedColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "What's in your mind",
                  style: getRegularStyle(
                    fontSize: 12,
                    color: AppColors.textColor2,
                  ).copyWith(letterSpacing: 1.6),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentToggle(
            selectedIndex: _segment,
            onChanged: (i) {
              setState(() => _segment = i);
              widget.onSegmentChanged?.call();
            },
            labels: const ['MINE', 'SHARED'],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _segment == 0
                ? _MinePanel(
                    controller: widget.notesController,
                    key: const ValueKey('mine'),
                  )
                : const SharedNotesPanel(key: ValueKey('shared')),
          ),
        ),
      ],
    );
  }
}

class _MinePanel extends StatelessWidget {
  final MyNotesController controller;

  const _MinePanel({super.key, required this.controller});

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
              if (ctrl.selectionMode)
                _SelectionBar(controller: ctrl),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.selectedColor,
                  onRefresh: ctrl.loadNotes,
                  child: ctrl.notes.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(24),
                          children: [_EmptyMine(isOffline: ctrl.isOffline)],
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
                                notes: ctrl.notes,
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

class _SelectionBar extends StatelessWidget {
  final MyNotesController controller;

  const _SelectionBar({required this.controller});

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
              onPressed: count == 0 ? null : () => controller.pinSelected(pinned: true),
              icon: Icon(Icons.push_pin_outlined, color: AppColors.selectedColor, size: 20),
            ),
            IconButton(
              tooltip: 'Unpin',
              onPressed: count == 0 ? null : () => controller.pinSelected(pinned: false),
              icon: Icon(Icons.push_pin_rounded, color: AppColors.textColor2, size: 20),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              icon: Icon(Icons.delete_outline_rounded, color: AppColors.textColorRed, size: 20),
            ),
            IconButton(
              tooltip: 'Cancel',
              onPressed: controller.exitSelection,
              icon: Icon(Icons.close_rounded, color: AppColors.textColor2, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMine extends StatelessWidget {
  final bool isOffline;
  const _EmptyMine({required this.isOffline});

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      child: AppContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              Icons.note_add_outlined,
              size: 40,
              color: AppColors.textColor2,
            ),
            const SizedBox(height: 12),
            Text(
              'No notes yet',
              style: getSemiBoldStyle(color: AppColors.textColor),
            ),
            const SizedBox(height: 6),
            Text(
              isOffline
                  ? 'Offline — new notes sync when online.'
                  : 'Tap + to create your first note.',
              textAlign: TextAlign.center,
              style: getRegularStyle(fontSize: 13, color: AppColors.textColor2),
            ),
          ],
        ),
      ),
    );
  }
}
