import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/shared/animations/app_animations.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/features/friends/model/friend.dart';

class SharedNoteCard extends StatelessWidget {
  final Friend friend;
  final bool isOnWidget;
  final int index;
  final VoidCallback onTap;

  const SharedNoteCard({
    super.key,
    required this.friend,
    required this.isOnWidget,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial =
        (friend.profile?.username ?? friend.friendUid).substring(0, 1).toUpperCase();

    return StaggeredFadeSlideIn(
      index: index,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AppContainer(
          borderRadius: 20,
          isHighlighted: isOnWidget,
          onTap: onTap,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isOnWidget
                      ? Border.all(
                          color: AppColors.selectedColor.withValues(alpha: 0.3),
                          width: 1.5,
                        )
                      : null,
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      AppColors.containerColor.withValues(alpha: 0.7),
                  child: Text(
                    initial,
                    style: getBoldStyle(
                      fontSize: 14,
                      color: AppColors.selectedColor,
                    ),
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
                      isOnWidget ? 'Pinned to home widget' : friend.subtitle,
                      style: getRegularStyle(
                        fontSize: 12,
                        color: isOnWidget
                            ? AppColors.selectedColor.withValues(alpha: 0.55)
                            : AppColors.textColor2,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isOnWidget
                    ? Icons.widgets_outlined
                    : Icons.chevron_right_rounded,
                size: 18,
                color: isOnWidget
                    ? AppColors.selectedColor.withValues(alpha: 0.5)
                    : AppColors.textColor2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
