import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/shared/widgets/segment_toggle.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/features/friends/my_friends/controller.dart';
import 'package:noteswidgetapp/features/friends/my_friends/widgets/friends_list.dart';
import 'package:noteswidgetapp/features/friends/my_friends/widgets/friends_search_section.dart';
import 'package:noteswidgetapp/features/friends/my_friends/widgets/requests_list.dart';
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
              child: FriendsSearchSection(controller: controller),
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
                      ? FriendsList(
                          key: const ValueKey('friends'),
                          controller: controller,
                        )
                      : RequestsList(
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
