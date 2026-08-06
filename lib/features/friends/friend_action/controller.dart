import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/constants/app_constants.dart';
import 'package:noteswidgetapp/core/navigation/note_editor_launcher.dart';
import 'package:noteswidgetapp/core/notes/note_type.dart';
import 'package:noteswidgetapp/core/shared/widgets/glass_confirm_dialog.dart';
import 'package:noteswidgetapp/core/shared/widgets/note_type_picker_sheet.dart';
import 'package:noteswidgetapp/core/supabase/schema_capabilities.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/widget/active_widget_note_service.dart';
import 'package:noteswidgetapp/core/widget/shared_note_widget_cache.dart';
import 'package:noteswidgetapp/core/widget/widget_setup_helper.dart';
import 'package:noteswidgetapp/features/friends/friend_action/widgets/friend_action_sheet.dart';
import 'package:noteswidgetapp/features/friends/model/friend.dart';
import 'package:noteswidgetapp/features/shared_note/repository/shared_note_repository.dart';

enum FriendTapChoice { showOnWidget, openNoteOnly, changeNoteType }

/// Handles friend-tap actions: open note, pin to widget, change type.
class FriendActionController {
  FriendActionController._();

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
      builder: (ctx) => FriendActionSheet(friend: friend),
    );

    if (!context.mounted || choice == null) return;

    if (choice == FriendTapChoice.changeNoteType) {
      await changeNoteType(context, friend);
      return;
    }

    if (choice == FriendTapChoice.showOnWidget ||
        choice == FriendTapChoice.openNoteOnly) {
      final ready = await ensureInitialNoteType(context, friend);
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

  static Future<bool> ensureInitialNoteType(
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

  static Future<void> changeNoteType(
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
