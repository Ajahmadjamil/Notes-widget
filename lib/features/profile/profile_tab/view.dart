import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/constants/app_constants.dart';
import 'package:noteswidgetapp/core/shared/animations/app_animations.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/shared/widgets/custom_button.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/core/theme/theme_picker_sheet.dart';
import 'package:noteswidgetapp/core/theme/theme_provider.dart';
import 'package:noteswidgetapp/core/widget/widget_setup_helper.dart';
import 'package:noteswidgetapp/features/profile/profile_tab/controller.dart';
import 'package:noteswidgetapp/features/profile/profile_tab/widgets/profile_action_tile.dart';
import 'package:provider/provider.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileTabController()..load(),
      child: const _ProfileTabBody(),
    );
  }
}

class _ProfileTabBody extends StatelessWidget {
  const _ProfileTabBody();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProfileTabController>();

    if (controller.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.selectedColor),
      );
    }

    final name = controller.displayName;
    final username = controller.username;
    final email = controller.email;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        FadeSlideIn(
          child: AppContainer(
            borderRadius: 28,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.containerColor,
                  child: Text(
                    name.substring(0, 1).toUpperCase(),
                    style: getBoldStyle(
                      fontSize: 28,
                      color: AppColors.selectedColor,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  name,
                  style: getBoldStyle(fontSize: 20, color: AppColors.textColor),
                ),
                if (username != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '@$username',
                    style: getRegularStyle(color: AppColors.textColor2),
                  ),
                ],
                if (email != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: getRegularStyle(
                      fontSize: 12,
                      color: AppColors.textColor2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ProfileActionTile(
          icon: Icons.widgets_outlined,
          title: 'Home screen widget',
          subtitle: 'Add or manage your note widget',
          onTap: () => WidgetSetupHelper.addWidgetToHomeScreen(context),
        ),
        const SizedBox(height: 8),
        ProfileActionTile(
          icon: Icons.palette_outlined,
          title: 'Change App Theme',
          subtitle: AppThemeProvider.instance.currentThemeName,
          onTap: () => ThemePickerSheet.show(context),
        ),
        const SizedBox(height: 8),
        ProfileActionTile(
          icon: Icons.sync_rounded,
          title: 'Sync status',
          subtitle: 'Real-time sync is active',
          onTap: () => AppConstants.showToast('Sync is running'),
        ),
        const SizedBox(height: 24),
        CustomButton(
          onTap: () => controller.signOutAndNavigate(context),
          label: 'Sign out',
          color: AppColors.btnColorLight,
          style: getMediumStyle(color: AppColors.textColorRed),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'SyncNotes v1.0.0',
            style: getRegularStyle(fontSize: 11, color: AppColors.textColor2),
          ),
        ),
      ],
    );
  }
}
