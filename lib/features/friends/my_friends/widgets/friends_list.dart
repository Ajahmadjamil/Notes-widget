import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/shared/animations/app_animations.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/features/friends/friend_action/controller.dart';
import 'package:noteswidgetapp/features/friends/my_friends/controller.dart';

class FriendsList extends StatelessWidget {
  final MyFriendsController controller;

  const FriendsList({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.friends.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          FadeSlideIn(
            child: AppContainer(
              borderRadius: 22,
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 40,
                    color: AppColors.textColor2,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No friends yet',
                    style: getSemiBoldStyle(color: AppColors.textColor),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Search above to find and add friends.',
                    textAlign: TextAlign.center,
                    style: getRegularStyle(
                      fontSize: 13,
                      color: AppColors.textColor2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: controller.friends.length,
      itemBuilder: (context, index) {
        final friend = controller.friends[index];
        final initial =
            (friend.profile?.username ?? friend.friendUid)
                .substring(0, 1)
                .toUpperCase();

        return StaggeredFadeSlideIn(
          index: index,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppContainer(
              borderRadius: 18,
              onTap: friend.sharedNoteId.isEmpty
                  ? null
                  : () => FriendActionController.onFriendTap(context, friend),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.containerColor,
                    child: Text(
                      initial,
                      style: getBoldStyle(
                        fontSize: 16,
                        color: AppColors.selectedColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          friend.displayLabel,
                          style: getSemiBoldStyle(
                            fontSize: 14,
                            color: AppColors.textColor,
                          ),
                        ),
                        Text(
                          friend.sharedNoteId.isEmpty
                              ? 'No shared note yet'
                              : friend.subtitle,
                          style: getRegularStyle(
                            fontSize: 12,
                            color: AppColors.textColor2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (friend.sharedNoteId.isNotEmpty)
                    Icon(
                      Icons.note_alt_outlined,
                      color: AppColors.selectedColor,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
