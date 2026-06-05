import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/shared/animations/app_animations.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/core/widget/active_widget_note_service.dart';
import 'package:noteswidgetapp/features/friends/friend_widget_prompt.dart';
import 'package:noteswidgetapp/features/friends/model/friend.dart';
import 'package:noteswidgetapp/features/friends/my_friends/controller.dart';
import 'package:provider/provider.dart';

/// Shared notes list shown under the SHARED segment on Home.
class SharedNotesPanel extends StatefulWidget {
  const SharedNotesPanel({super.key});

  @override
  State<SharedNotesPanel> createState() => _SharedNotesPanelState();
}

class _SharedNotesPanelState extends State<SharedNotesPanel> {
  String? _activeNoteId;

  @override
  void initState() {
    super.initState();
    _loadActive();
  }

  Future<void> _loadActive() async {
    final id = await ActiveWidgetNoteService.getActiveNoteId();
    if (mounted) setState(() => _activeNoteId = id);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyFriendsController>(
      builder: (context, controller, _) {
        if (controller.isLoading && controller.friends.isEmpty) {
          return Center(child: CircularProgressIndicator(color: AppColors.selectedColor));
        }

        final withNotes = controller.friends.where((f) => f.sharedNoteId.isNotEmpty).toList();
        if (withNotes.isEmpty) {
          return _EmptyShared();
        }

        final onWidget = withNotes.where((f) => f.sharedNoteId == _activeNoteId).toList();
        final others = withNotes.where((f) => f.sharedNoteId != _activeNoteId).toList();

        return RefreshIndicator(
          color: AppColors.selectedColor,
          onRefresh: () async {
            await controller.loadAll();
            await _loadActive();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            children: [
              if (onWidget.isNotEmpty) ...[
                _Label('On widget'),
                ...onWidget.asMap().entries.map(
                  (e) => _SharedCard(
                    friend: e.value,
                    isOnWidget: true,
                    index: e.key,
                    onTap: () => _open(context, e.value),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (others.isNotEmpty) ...[
                _Label(onWidget.isNotEmpty ? 'All shared' : 'Shared notes'),
                ...others.asMap().entries.map(
                  (e) => _SharedCard(
                    friend: e.value,
                    isOnWidget: false,
                    index: e.key + onWidget.length,
                    onTap: () => _open(context, e.value),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _open(BuildContext context, Friend friend) async {
    await FriendWidgetPrompt.onFriendTap(context, friend);
    await _loadActive();
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

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

class _EmptyShared extends StatelessWidget {
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
                Icon(Icons.people_outline_rounded, size: 40, color: AppColors.textColor2),
                const SizedBox(height: 12),
                Text('No shared notes', style: getSemiBoldStyle(color: AppColors.textColor)),
                const SizedBox(height: 6),
                Text(
                  'Add friends in the Shared tab to collaborate on notes.',
                  textAlign: TextAlign.center,
                  style: getRegularStyle(fontSize: 13, color: AppColors.textColor2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SharedCard extends StatelessWidget {
  final Friend friend;
  final bool isOnWidget;
  final int index;
  final VoidCallback onTap;

  const _SharedCard({
    required this.friend,
    required this.isOnWidget,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial = (friend.profile?.username ?? friend.friendUid).substring(0, 1).toUpperCase();

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
                  backgroundColor: AppColors.containerColor.withValues(alpha: 0.7),
                  child: Text(
                    initial,
                    style: getBoldStyle(fontSize: 14, color: AppColors.selectedColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(friend.displayLabel, style: getSemiBoldStyle(fontSize: 14, color: AppColors.textColor)),
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
                isOnWidget ? Icons.widgets_outlined : Icons.chevron_right_rounded,
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
