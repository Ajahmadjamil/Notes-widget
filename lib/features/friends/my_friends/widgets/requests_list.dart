import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/shared/animations/app_animations.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/shared/widgets/custom_button.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/features/friends/model/friend_request.dart';
import 'package:noteswidgetapp/features/friends/my_friends/controller.dart';

class RequestsList extends StatelessWidget {
  final MyFriendsController controller;

  const RequestsList({super.key, required this.controller});

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
                  Icon(
                    Icons.mail_outline_rounded,
                    size: 40,
                    color: AppColors.textColor2,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No requests',
                    style: getSemiBoldStyle(color: AppColors.textColor),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Friend requests will appear here.',
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
      itemCount: controller.incomingRequests.length,
      itemBuilder: (context, index) {
        return StaggeredFadeSlideIn(
          index: index,
          child: RequestTile(
            controller: controller,
            request: controller.incomingRequests[index],
          ),
        );
      },
    );
  }
}

class RequestTile extends StatelessWidget {
  final MyFriendsController controller;
  final FriendRequest request;

  const RequestTile({
    super.key,
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
            Text(
              name,
              style: getSemiBoldStyle(fontSize: 14, color: AppColors.textColor),
            ),
            if (request.fromUsername != null &&
                request.fromUsername!.isNotEmpty)
              Text(
                '@${request.fromUsername}',
                style: getRegularStyle(
                  fontSize: 12,
                  color: AppColors.textColor2,
                ),
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
