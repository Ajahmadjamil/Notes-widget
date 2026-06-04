import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/shared/widgets/custom_button.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/features/friends/model/friend_request.dart';
import 'package:noteswidgetapp/features/friends/my_friends/controller.dart';
import 'package:noteswidgetapp/features/friends/friend_widget_prompt.dart';
import 'package:provider/provider.dart';

class MyFriendsTab extends StatefulWidget {
  const MyFriendsTab({super.key});

  @override
  State<MyFriendsTab> createState() => _MyFriendsTabState();
}

class _MyFriendsTabState extends State<MyFriendsTab>
    with AutomaticKeepAliveClientMixin {
  late final MyFriendsController _controller;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = MyFriendsController()..init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<MyFriendsController>(
        builder: (context, controller, _) {
          if (controller.isLoading && controller.friends.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: controller.loadAll,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SearchSection(controller: controller),
                const SizedBox(height: 20),
                _SectionHeader(
                  title: 'Friend requests',
                  count: controller.incomingRequests.length,
                ),
                const SizedBox(height: 8),
                if (controller.incomingRequests.isEmpty)
                  Text(
                    'No pending requests',
                    style: getRegularStyle(color: AppColors.textColor2),
                  )
                else
                  ...controller.incomingRequests.map(
                    (r) => _RequestTile(controller: controller, request: r),
                  ),
                const SizedBox(height: 20),
                _SectionHeader(
                  title: 'My friends',
                  count: controller.friends.length,
                ),
                const SizedBox(height: 8),
                if (controller.friends.isEmpty)
                  Text(
                    'No friends yet — search by username or email',
                    style: getRegularStyle(color: AppColors.textColor2),
                  )
                else
                  ...controller.friends.map(
                    (f) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.secondaryColor,
                        child: Text(
                          (f.profile?.username ?? f.friendUid)
                              .substring(0, 1)
                              .toUpperCase(),
                          style: getMediumStyle(color: AppColors.primaryColor),
                        ),
                      ),
                      title: Text(
                        f.displayLabel,
                        style: getMediumStyle(color: AppColors.textColor),
                      ),
                      subtitle: Text(
                        '${f.subtitle} · Tap to open or show on widget',
                        style: getRegularStyle(
                          fontSize: 13,
                          color: AppColors.textColor2,
                        ),
                      ),
                      trailing: Icon(
                        Icons.note_alt_outlined,
                        color: AppColors.primaryColor,
                        size: 20,
                      ),
                      onTap: f.sharedNoteId.isEmpty
                          ? null
                          : () => FriendWidgetPrompt.onFriendTap(context, f),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: getSemiBoldStyle(fontSize: 16, color: AppColors.textColor),
        ),
        const SizedBox(width: 8),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: getRegularStyle(fontSize: 12, color: Colors.white),
            ),
          ),
      ],
    );
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
        Text(
          'Find friends',
          style: getSemiBoldStyle(fontSize: 16, color: AppColors.textColor),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller.searchController,
                decoration: InputDecoration(
                  hintText: 'Username or email',
                  hintStyle: getRegularStyle(color: AppColors.textFieldPlaceHolderColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.textFieldBorderColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                style: getRegularStyle(color: AppColors.textColor),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => controller.searchUser(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: controller.isSearching ? null : () => controller.searchUser(),
              icon: controller.isSearching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.search, color: AppColors.primaryColor),
            ),
          ],
        ),
        if (controller.searchStatusMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            controller.searchStatusMessage!,
            style: getRegularStyle(fontSize: 13, color: AppColors.textColor2),
          ),
        ],
        if (controller.searchResult != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.textFieldBorderColor),
            ),
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
                        style: getRegularStyle(
                          fontSize: 13,
                          color: AppColors.textColor2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (sent || controller.searchStatusMessage == null)
                  CustomButton(
                    onTap: sent ? null : () => controller.sendRequestToSearchResult(),
                    label: sent ? 'Sent' : 'Add friend',
                    color: AppColors.primaryColor,
                    isEnabled: !sent,
                  ),
              ],
            ),
          ),
        ],
      ],
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

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: getMediumStyle(color: AppColors.textColor),
            ),
            if (request.fromUsername != null && request.fromUsername!.isNotEmpty)
              Text(
                '@${request.fromUsername}',
                style: getRegularStyle(fontSize: 13, color: AppColors.textColor2),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    onTap: () => controller.acceptRequest(request),
                    label: 'Accept',
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    onTap: () => controller.declineRequest(request),
                    label: 'Decline',
                    color: Colors.white,
                    style: getMediumStyle(color: AppColors.textColorRed),
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
