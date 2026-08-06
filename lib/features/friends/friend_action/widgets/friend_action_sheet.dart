import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/shared/animations/app_animations.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/shared/widgets/custom_button.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/features/friends/friend_action/controller.dart';
import 'package:noteswidgetapp/features/friends/model/friend.dart';

class FriendActionSheet extends StatelessWidget {
  final Friend friend;

  const FriendActionSheet({super.key, required this.friend});

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
                  FriendActionCard(
                    icon: Icons.edit_note_rounded,
                    title: 'Edit shared note',
                    subtitle: 'Open and collaborate in real time',
                    onTap: () =>
                        Navigator.pop(context, FriendTapChoice.openNoteOnly),
                  ),
                  const SizedBox(height: 10),
                  FriendActionCard(
                    icon: Icons.widgets_rounded,
                    title: 'Add to home widget',
                    subtitle: 'Pin their note to your home screen',
                    isPrimary: true,
                    onTap: () =>
                        Navigator.pop(context, FriendTapChoice.showOnWidget),
                  ),
                  const SizedBox(height: 10),
                  FriendActionCard(
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

class FriendActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isPrimary;

  const FriendActionCard({
    super.key,
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
