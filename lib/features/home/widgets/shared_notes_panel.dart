import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/shared/animations/app_animations.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/features/friends/model/friend.dart';
import 'package:noteswidgetapp/features/friends/friend_action/controller.dart';
import 'package:noteswidgetapp/features/friends/my_friends/controller.dart';
import 'package:noteswidgetapp/features/home/controller.dart';
import 'package:noteswidgetapp/features/home/widgets/shared_note_card.dart';
import 'package:provider/provider.dart';

/// Shared notes list shown under the SHARED segment on Home.
class SharedNotesPanel extends StatelessWidget {
  const SharedNotesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final homeTab = context.watch<HomeTabController>();

    return Consumer<MyFriendsController>(
      builder: (context, controller, _) {
        if (controller.isLoading && controller.friends.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.selectedColor),
          );
        }

        final withNotes =
            controller.friends.where((f) => f.sharedNoteId.isNotEmpty).toList();
        if (withNotes.isEmpty) {
          return const EmptyShared();
        }

        final activeId = homeTab.activeWidgetNoteId;
        final onWidget =
            withNotes.where((f) => f.sharedNoteId == activeId).toList();
        final others =
            withNotes.where((f) => f.sharedNoteId != activeId).toList();

        return RefreshIndicator(
          color: AppColors.selectedColor,
          onRefresh: () async {
            await controller.loadAll();
            await homeTab.loadActiveWidgetNote();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            children: [
              if (onWidget.isNotEmpty) ...[
                const SectionLabel('On widget'),
                ...onWidget.asMap().entries.map(
                  (e) => SharedNoteCard(
                    friend: e.value,
                    isOnWidget: true,
                    index: e.key,
                    onTap: () => _open(context, homeTab, e.value),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (others.isNotEmpty) ...[
                SectionLabel(onWidget.isNotEmpty ? 'All shared' : 'Shared notes'),
                ...others.asMap().entries.map(
                  (e) => SharedNoteCard(
                    friend: e.value,
                    isOnWidget: false,
                    index: e.key + onWidget.length,
                    onTap: () => _open(context, homeTab, e.value),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _open(
    BuildContext context,
    HomeTabController homeTab,
    Friend friend,
  ) async {
    await FriendActionController.onFriendTap(context, friend);
    await homeTab.loadActiveWidgetNote();
  }
}

class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text.toUpperCase(),
        style: getMediumStyle(fontSize: 10, color: AppColors.textColor2)
            .copyWith(letterSpacing: 1.4),
      ),
    );
  }
}

class EmptyShared extends StatelessWidget {
  const EmptyShared({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        FadeSlideIn(
          child: AppContainer(
            borderRadius: 24,
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
                  'No shared notes',
                  style: getSemiBoldStyle(color: AppColors.textColor),
                ),
                const SizedBox(height: 6),
                Text(
                  'Add friends in the Shared tab to collaborate on notes.',
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
}
