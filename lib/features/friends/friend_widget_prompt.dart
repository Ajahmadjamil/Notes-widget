import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/constants/app_constants.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/core/widget/active_widget_note_service.dart';
import 'package:noteswidgetapp/core/widget/widget_setup_helper.dart';
import 'package:noteswidgetapp/features/friends/model/friend.dart';
import 'package:noteswidgetapp/features/shared_note/editor/view.dart';

enum FriendTapChoice { showOnWidget, openNoteOnly }

class FriendWidgetPrompt {
  FriendWidgetPrompt._();

  static Future<void> onFriendTap(BuildContext context, Friend friend) async {
    if (friend.sharedNoteId.isEmpty) {
      AppConstants.showToast('No shared note with this friend yet');
      return;
    }

    final choice = await showDialog<FriendTapChoice>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          friend.displayLabel,
          style: getSemiBoldStyle(color: AppColors.textColor),
        ),
        content: Text(
          'Show this friend\'s shared note on your home screen widget? '
          'It will update in real time when either of you edits.',
          style: getRegularStyle(color: AppColors.textColor2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, FriendTapChoice.openNoteOnly),
            child: Text(
              'Open note only',
              style: getMediumStyle(color: AppColors.textColor2),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: getMediumStyle(color: AppColors.textColor2)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, FriendTapChoice.showOnWidget),
            child: Text(
              'Show on widget',
              style: getMediumStyle(color: AppColors.primaryColor),
            ),
          ),
        ],
      ),
    );

    if (!context.mounted || choice == null) return;

    if (choice == FriendTapChoice.showOnWidget) {
      await ActiveWidgetNoteService.setActiveFriendNote(
        sharedNoteId: friend.sharedNoteId,
        friendLabel: friend.displayLabel,
      );
      await WidgetSetupHelper.requestPinIfNeeded();
      if (!context.mounted) return;
      AppConstants.showToast('${friend.displayLabel} is on your home screen widget');
    }

    if (!context.mounted) return;
    if (choice == FriendTapChoice.showOnWidget || choice == FriendTapChoice.openNoteOnly) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SharedNoteEditorScreen(
            key: ValueKey('note_${friend.friendUid}_${friend.sharedNoteId}'),
            sharedNoteId: friend.sharedNoteId,
            friendUid: friend.friendUid,
            friendLabel: friend.displayLabel,
          ),
        ),
      );
    }
  }
}
