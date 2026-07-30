import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/constants/app_constants.dart';
import 'package:noteswidgetapp/core/navigation/note_editor_launcher.dart';
import 'package:noteswidgetapp/core/notes/note_type.dart';
import 'package:noteswidgetapp/core/shared/animations/app_animations.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/shared/widgets/custom_button.dart';
import 'package:noteswidgetapp/core/shared/widgets/glass_confirm_dialog.dart';
import 'package:noteswidgetapp/core/shared/widgets/note_type_picker_sheet.dart';
import 'package:noteswidgetapp/core/supabase/schema_capabilities.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/core/widget/active_widget_note_service.dart';
import 'package:noteswidgetapp/core/widget/shared_note_widget_cache.dart';
import 'package:noteswidgetapp/core/widget/widget_setup_helper.dart';
import 'package:noteswidgetapp/features/friends/model/friend.dart';
import 'package:noteswidgetapp/features/shared_note/repository/shared_note_repository.dart';

enum FriendTapChoice { showOnWidget, openNoteOnly, changeNoteType }

class FriendWidgetPrompt {
  FriendWidgetPrompt._();

  static final _repo = SharedNoteRepository();

  static Future<void> onFriendTap(BuildContext context, Friend friend) async {
    if (friend.sharedNoteId.isEmpty) {
      AppConstants.showToast('No shared note with this friend yet');
      return;
    }

    final choice = await showModalBottomSheet<FriendTapChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.secondaryColor.withValues(alpha: 0.35),
      builder: (ctx) => _FriendActionSheet(friend: friend),
    );

    if (!context.mounted || choice == null) return;

    if (choice == FriendTapChoice.changeNoteType) {
      await _changeNoteType(context, friend);
      return;
    }

    if (choice == FriendTapChoice.showOnWidget ||
        choice == FriendTapChoice.openNoteOnly) {
      final ready = await _ensureInitialNoteType(context, friend);
      if (!ready || !context.mounted) return;
    }

    if (choice == FriendTapChoice.showOnWidget) {
      await ActiveWidgetNoteService.setActiveFriendNote(
        sharedNoteId: friend.sharedNoteId,
        friendLabel: friend.displayLabel,
      );
      await WidgetSetupHelper.requestPinExplicitly();
      if (!context.mounted) return;
      AppConstants.showToast(
        'Add the widget if prompted — ${friend.displayLabel} is ready',
      );
    }

    if (!context.mounted) return;
    if (choice == FriendTapChoice.showOnWidget ||
        choice == FriendTapChoice.openNoteOnly) {
      await NoteEditorLauncher.openShared(
        context: context,
        sharedNoteId: friend.sharedNoteId,
        friendUid: friend.friendUid,
        friendLabel: friend.displayLabel,
      );
    }
  }

  static Future<bool> _ensureInitialNoteType(
    BuildContext context,
    Friend friend,
  ) async {
    final note = await _repo.resolveAndFetch(
      preferredId: friend.sharedNoteId,
      friendUid: friend.friendUid,
    );
    if (note == null) {
      AppConstants.showToast('Could not load shared note');
      return false;
    }
    if (!note.isUnset) return true;

    if (!context.mounted) return false;
    final type = await NoteTypePickerSheet.show(
      context,
      title: 'Shared note type',
      subtitle: 'Choose text, document, or handwriting',
    );
    if (type == null) return false;

    if (type == NoteType.drawing && !SchemaCapabilities.drawingNotesSupported) {
      AppConstants.showToast(
        'Run RUN_IN_SUPABASE_SQL_EDITOR.sql in Supabase to enable handwriting',
      );
      return true;
    }
    if (type == NoteType.document &&
        !SchemaCapabilities.documentNotesSupported) {
      AppConstants.showToast(
        'Run RUN_DOCUMENT_NOTES_SQL.sql in Supabase to enable documents',
      );
      return true;
    }

    await _repo.setNoteType(
      sharedNoteId: note.sharedNoteId,
      noteType: type,
    );
    return true;
  }

  static Future<void> _changeNoteType(
    BuildContext context,
    Friend friend,
  ) async {
    final note = await _repo.fetchOnce(friend.sharedNoteId);
    if (note == null) {
      AppConstants.showToast('Could not load shared note');
      return;
    }

    if (!context.mounted) return;
    final newType = await NoteTypePickerSheet.show(
      context,
      title: 'Change note type',
      subtitle: 'Pick a different type — current content will be cleared',
      excludeTypes: {note.noteType},
    );
    if (newType == null || !context.mounted) return;

    if (newType == NoteType.drawing &&
        !SchemaCapabilities.drawingNotesSupported) {
      AppConstants.showToast(
        'Run RUN_IN_SUPABASE_SQL_EDITOR.sql in Supabase to enable handwriting',
      );
      return;
    }
    if (newType == NoteType.document &&
        !SchemaCapabilities.documentNotesSupported) {
      AppConstants.showToast(
        'Run RUN_DOCUMENT_NOTES_SQL.sql in Supabase to enable documents',
      );
      return;
    }

    final hasContent = note.body.trim().isNotEmpty ||
        note.drawingData.trim().isNotEmpty ||
        note.documentData.trim().isNotEmpty;

    final ok = await GlassConfirmDialog.show(
      context,
      title: 'Switch note type?',
      message: hasContent
          ? 'Current content will be cleared when switching.'
          : 'This shared note will open as the new type.',
      confirmLabel: 'Switch',
      cancelLabel: 'Cancel',
      icon: Icons.swap_horiz_rounded,
    );
    if (!ok || !context.mounted) return;

    try {
      final updated = await _repo.changeNoteType(
        sharedNoteId: note.sharedNoteId,
        newType: newType,
      );
      if (updated == null) {
        AppConstants.showToast('Could not change note type');
        return;
      }

      if (await ActiveWidgetNoteService.shouldSyncToWidget(note.sharedNoteId)) {
        await SharedNoteWidgetCache.updateFromNote(
          updated,
          friendLabel: friend.displayLabel,
        );
      }

      final label = switch (newType) {
        NoteType.drawing => 'handwriting',
        NoteType.document => 'document',
        NoteType.text => 'text',
      };
      AppConstants.showToast('Switched to $label');

      if (!context.mounted) return;
      await NoteEditorLauncher.openShared(
        context: context,
        sharedNoteId: friend.sharedNoteId,
        friendUid: friend.friendUid,
        friendLabel: friend.displayLabel,
      );
    } catch (_) {
      AppConstants.showToast('Could not change note type');
    }
  }
}

class _FriendActionSheet extends StatelessWidget {
  final Friend friend;

  const _FriendActionSheet({required this.friend});

  @override
  Widget build(BuildContext context) {
    final initial = (friend.profile?.username ?? friend.friendUid)
        .substring(0, 1)
        .toUpperCase();

    return FadeSlideIn(
      slideOffset: 40,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.paddingOf(context).bottom + 16,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AppContainer(
              borderRadius: 32,
              enableGlass: false,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.selectedColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.selectedColor,
                          AppColors.selectedColor.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: getBoldStyle(
                        fontSize: 24,
                        color: AppColors.textColor1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    friend.displayLabel,
                    style: getBoldStyle(
                      fontSize: 20,
                      color: AppColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    friend.subtitle,
                    style: getRegularStyle(
                      fontSize: 13,
                      color: AppColors.textColor2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _ActionCard(
                    icon: Icons.edit_note_rounded,
                    title: 'Edit shared note',
                    subtitle: 'Open and collaborate in real time',
                    onTap: () =>
                        Navigator.pop(context, FriendTapChoice.openNoteOnly),
                  ),
                  const SizedBox(height: 10),
                  _ActionCard(
                    icon: Icons.widgets_rounded,
                    title: 'Add to home widget',
                    subtitle: 'Pin their note to your home screen',
                    isPrimary: true,
                    onTap: () =>
                        Navigator.pop(context, FriendTapChoice.showOnWidget),
                  ),
                  const SizedBox(height: 10),
                  _ActionCard(
                    icon: Icons.swap_horiz_rounded,
                    title: 'Change note type',
                    subtitle: 'Choose text, document, or handwriting',
                    onTap: () =>
                        Navigator.pop(context, FriendTapChoice.changeNoteType),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    onTap: () => Navigator.pop(context),
                    label: 'Cancel',
                    color: AppColors.btnColorLight,
                    style: getMediumStyle(color: AppColors.textColor2),
                    height: 44,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: AppContainer(
        borderRadius: 20,
        isSelected: isPrimary,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: isPrimary ? AppColors.textColor1 : AppColors.selectedColor,
              size: 24,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: getSemiBoldStyle(
                      fontSize: 14,
                      color: isPrimary
                          ? AppColors.textColor1
                          : AppColors.textColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: getRegularStyle(
                      fontSize: 12,
                      color: isPrimary
                          ? AppColors.textColor1.withValues(alpha: 0.75)
                          : AppColors.textColor2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
