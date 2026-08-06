/// Backward-compatible entry point for friend tap actions.
library;

import 'package:flutter/material.dart';
import 'package:noteswidgetapp/features/friends/friend_action/controller.dart';
import 'package:noteswidgetapp/features/friends/model/friend.dart';

export 'package:noteswidgetapp/features/friends/friend_action/controller.dart'
    show FriendActionController, FriendTapChoice;

class FriendWidgetPrompt {
  FriendWidgetPrompt._();

  static Future<void> onFriendTap(BuildContext context, Friend friend) {
    return FriendActionController.onFriendTap(context, friend);
  }
}
