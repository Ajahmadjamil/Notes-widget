import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/shared/animations/app_animations.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/shared/widgets/custom_button.dart';
import 'package:noteswidgetapp/core/shared/widgets/input_field.dart';
import 'package:noteswidgetapp/core/shared/widgets/segment_toggle.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/app_dimensions.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/features/friends/model/friend_request.dart';
import 'package:noteswidgetapp/features/friends/my_friends/controller.dart';
import 'package:noteswidgetapp/features/friends/friend_widget_prompt.dart';
import 'package:provider/provider.dart';

class MyFriendsTab extends StatefulWidget {
  final MyFriendsController? controller;

  const MyFriendsTab({super.key, this.controller});

  @override
  State<MyFriendsTab> createState() => _MyFriendsTabState();
}

class _MyFriendsTabState extends State<MyFriendsTab>
    with AutomaticKeepAliveClientMixin {
  MyFriendsController? _ownController;
  int _segment = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _ownController = MyFriendsController()..init();
    }
  }

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final content = Consumer<MyFriendsController>(
      builder: (context, controller, _) {
        if (controller.isLoading && controller.friends.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.selectedColor),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: _SearchSection(controller: controller),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentToggle(
                selectedIndex: _segment,
                onChanged: (i) => setState(() => _segment = i),
                labels: const ['MY FRIENDS', 'REQUESTS'],
                badgeCounts: [0, controller.incomingRequests.length],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.selectedColor,
                onRefresh: controller.loadAll,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: _segment == 0
                      ? _FriendsList(
                          key: const ValueKey('friends'),
                          controller: controller,
                        )
                      : _RequestsList(
                          key: const ValueKey('requests'),
                          controller: controller,
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (widget.controller != null) return content;
    return ChangeNotifierProvider.value(value: _ownController!, child: content);
  }
}

class _SearchSection extends StatelessWidget {
  final MyFriendsController controller;

  const _SearchSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    final sent = controller.searchStatusMessage == 'Friend request sent';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: InputField(
                hint: 'Username or email',
                controller: controller.searchController,
                prefixIcon: Icons.search_rounded,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => controller.searchUser(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: AppDimensions.inputFieldHeight,
              width: AppDimensions.inputFieldHeight,
              child: AppContainer(
                borderRadius: 16,
                onTap: controller.isSearching ? null : () => controller.searchUser(),
                padding: EdgeInsets.zero,
                alignment: Alignment.center,
                child: controller.isSearching
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.selectedColor,
                        ),
                      )
                    : Icon(Icons.arrow_forward_rounded, color: AppColors.selectedColor, size: 20),
              ),
            ),
          ],
        ),
        if (controller.searchStatusMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            controller.searchStatusMessage!,
            style: getRegularStyle(fontSize: 12, color: AppColors.textColor2),
          ),
        ],
        if (controller.searchResult != null) ...[
          const SizedBox(height: 10),
          AppContainer(
            borderRadius: 18,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@${controller.searchResult!.username ?? 'unknown'}',
                        style: getSemiBoldStyle(color: AppColors.textColor),
                      ),
                      Text(
                        controller.searchResult!.displayName ??
                            controller.searchResult!.email ??
                            '',
                        style: getRegularStyle(fontSize: 13, color: AppColors.textColor2),
                      ),
                    ],
                  ),
                ),
                if (sent || controller.searchStatusMessage == null)
                  CustomButton(
                    onTap: sent ? null : () => controller.sendRequestToSearchResult(),
                    label: sent ? 'Sent' : 'Add',
                    color: AppColors.primaryColor,
                    isEnabled: !sent,
                    height: 40,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _FriendsList extends StatelessWidget {
  final MyFriendsController controller;

  const _FriendsList({super.key, required this.controller});

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
                  Icon(Icons.people_outline_rounded, size: 40, color: AppColors.textColor2),
                  const SizedBox(height: 12),
                  Text('No friends yet', style: getSemiBoldStyle(color: AppColors.textColor)),
                  const SizedBox(height: 6),
                  Text(
                    'Search above to find and add friends.',
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

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: controller.friends.length,
      itemBuilder: (context, index) {
        final friend = controller.friends[index];
        final initial = (friend.profile?.username ?? friend.friendUid).substring(0, 1).toUpperCase();

        return StaggeredFadeSlideIn(
          index: index,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppContainer(
              borderRadius: 18,
              onTap: friend.sharedNoteId.isEmpty
                  ? null
                  : () => FriendWidgetPrompt.onFriendTap(context, friend),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.containerColor,
                    child: Text(
                      initial,
                      style: getBoldStyle(fontSize: 16, color: AppColors.selectedColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(friend.displayLabel, style: getSemiBoldStyle(fontSize: 14, color: AppColors.textColor)),
                        Text(
                          friend.sharedNoteId.isEmpty
                              ? 'No shared note yet'
                              : friend.subtitle,
                          style: getRegularStyle(fontSize: 12, color: AppColors.textColor2),
                        ),
                      ],
                    ),
                  ),
                  if (friend.sharedNoteId.isNotEmpty)
                    Icon(Icons.note_alt_outlined, color: AppColors.selectedColor, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RequestsList extends StatelessWidget {
  final MyFriendsController controller;

  const _RequestsList({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.incomingRequests.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          FadeSlideIn(
            child: AppContainer(
              borderRadius: 22,
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Icon(Icons.mail_outline_rounded, size: 40, color: AppColors.textColor2),
                  const SizedBox(height: 12),
                  Text('No requests', style: getSemiBoldStyle(color: AppColors.textColor)),
                  const SizedBox(height: 6),
                  Text(
                    'Friend requests will appear here.',
                    style: getRegularStyle(fontSize: 13, color: AppColors.textColor2),
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
      itemCount: controller.incomingRequests.length,
      itemBuilder: (context, index) {
        return StaggeredFadeSlideIn(
          index: index,
          child: _RequestTile(
            controller: controller,
            request: controller.incomingRequests[index],
          ),
        );
      },
    );
  }
}

class _RequestTile extends StatelessWidget {
  final MyFriendsController controller;
  final FriendRequest request;

  const _RequestTile({
    required this.controller,
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    final name = request.fromDisplayName?.isNotEmpty == true
        ? request.fromDisplayName!
        : request.fromUsername ?? request.fromUid;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppContainer(
        borderRadius: 18,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: getSemiBoldStyle(fontSize: 14, color: AppColors.textColor)),
            if (request.fromUsername != null && request.fromUsername!.isNotEmpty)
              Text(
                '@${request.fromUsername}',
                style: getRegularStyle(fontSize: 12, color: AppColors.textColor2),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    onTap: () => controller.acceptRequest(request),
                    label: 'Accept',
                    color: AppColors.primaryColor,
                    height: 40,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    onTap: () => controller.declineRequest(request),
                    label: 'Decline',
                    color: AppColors.btnColorLight,
                    style: getMediumStyle(color: AppColors.textColor),
                    height: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
