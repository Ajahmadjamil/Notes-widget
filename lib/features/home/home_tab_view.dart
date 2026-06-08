import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/shared/animations/app_animations.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/shared/widgets/note_grid_card.dart';
import 'package:noteswidgetapp/core/shared/widgets/segment_toggle.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/app_dimensions.dart';
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
              if (!ctrl.selectionMode) _MineNotesToolbar(controller: ctrl),
              if (ctrl.selectionMode) _SelectionBar(controller: ctrl),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.selectedColor,
                  onRefresh: ctrl.loadNotes,
                  child: ctrl.notes.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(24),
                          children: [_EmptyMine(isOffline: ctrl.isOffline)],
                        )
                      : notes.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(24),
                          children: const [_EmptySearch()],
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

class _MineNotesToolbar extends StatefulWidget {
  final MyNotesController controller;

  const _MineNotesToolbar({required this.controller});

  @override
  State<_MineNotesToolbar> createState() => _MineNotesToolbarState();
}

class _MineNotesToolbarState extends State<_MineNotesToolbar> {
  bool _searchExpanded = false;
  late final FocusNode _searchFocus;

  MyNotesController get _ctrl => widget.controller;

  @override
  void initState() {
    super.initState();
    _searchFocus = FocusNode()
      ..addListener(() {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _searchExpanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _closeSearch() {
    _searchFocus.unfocus();
    _ctrl.clearSearch();
    setState(() => _searchExpanded = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SizedBox(
        height: AppDimensions.inputFieldHeight,
        child: Row(
          children: [
            Expanded(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                alignment: Alignment.centerLeft,
                clipBehavior: Clip.hardEdge,
                child: _searchExpanded
                    ? AppContainer(
                        height: 40,
                        borderRadius: 12,
                        isFocused: _searchFocus.hasFocus,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              size: 24,
                              color: AppColors.iconColorGrey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                focusNode: _searchFocus,
                                controller: _ctrl.searchController,
                                onChanged: _ctrl.setSearchQuery,
                                textInputAction: TextInputAction.search,
                                style: getRegularStyle(
                                  color: AppColors.textFieldTextColor,
                                  fontSize: 14,
                                ),
                                cursorColor: AppColors.selectedColor,
                                decoration: InputDecoration.collapsed(
                                  hintText: 'Search title or body…',
                                  hintStyle: getRegularStyle(
                                    color: AppColors.textFieldHintColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            if (_ctrl.hasActiveSearch)
                              GestureDetector(
                                onTap: _ctrl.clearSearch,
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: AppColors.textColor2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _searchExpanded
                  ? _ToolbarIconButton(
                      key: const ValueKey('close'),
                      icon: Icons.close_rounded,
                      tooltip: 'Close search',
                      onTap: _closeSearch,
                    )
                  : Row(
                      key: const ValueKey('actions'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ToolbarIconButton(
                          icon: Icons.search_rounded,
                          tooltip: 'Search notes',
                          onTap: _openSearch,
                        ),
                        const SizedBox(width: 4),
                        _SortButton(controller: _ctrl),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ToolbarIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: AppContainer(
        borderRadius: 14,
        padding: const EdgeInsets.all(10),
        onTap: onTap,
        child: Icon(icon, size: 20, color: AppColors.selectedColor),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final MyNotesController controller;

  const _SortButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<NoteSortOption>(
      offset: const Offset(0, 44),
      tooltip: 'Sort notes',
      color: AppColors.containerColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: controller.setSortOption,
      itemBuilder: (context) => NoteSortOption.values
          .map(
            (option) => PopupMenuItem<NoteSortOption>(
              value: option,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option.label,
                      style: getRegularStyle(
                        fontSize: 14,
                        color: AppColors.textColor,
                      ),
                    ),
                  ),
                  if (controller.sortOption == option)
                    Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: AppColors.selectedColor,
                    ),
                ],
              ),
            ),
          )
          .toList(),
      child: AppContainer(
        borderRadius: 14,
        padding: const EdgeInsets.all(10),
        child: Icon(
          Icons.sort_rounded,
          size: 20,
          color: AppColors.selectedColor,
        ),
      ),
    );
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

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      child: AppContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 40,
              color: AppColors.textColor2,
            ),
            const SizedBox(height: 12),
            Text(
              'No matching notes',
              style: getSemiBoldStyle(color: AppColors.textColor),
            ),
            const SizedBox(height: 6),
            Text(
              'Try a different search term.',
              textAlign: TextAlign.center,
              style: getRegularStyle(fontSize: 13, color: AppColors.textColor2),
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
