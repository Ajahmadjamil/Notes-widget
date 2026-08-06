import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/shared/widgets/custom_button.dart';
import 'package:noteswidgetapp/core/shared/widgets/input_field.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/app_dimensions.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/features/friends/my_friends/controller.dart';

class FriendsSearchSection extends StatelessWidget {
  final MyFriendsController controller;

  const FriendsSearchSection({super.key, required this.controller});

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
                onTap: controller.isSearching
                    ? null
                    : () => controller.searchUser(),
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
                    : Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.selectedColor,
                        size: 20,
                      ),
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
                    onTap: sent
                        ? null
                        : () => controller.sendRequestToSearchResult(),
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
