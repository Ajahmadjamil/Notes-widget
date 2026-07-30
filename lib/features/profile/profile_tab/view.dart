import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/alerts/custom_loading.dart';
import 'package:noteswidgetapp/core/constants/app_constants.dart';
import 'package:noteswidgetapp/core/shared/animations/app_animations.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/shared/widgets/custom_button.dart';
import 'package:noteswidgetapp/core/supabase/app_supabase.dart';
import 'package:noteswidgetapp/core/sync/push_sync_service.dart';
import 'package:noteswidgetapp/core/sync/shared_note_poll_service.dart';
import 'package:noteswidgetapp/core/sync/shared_note_realtime_service.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/core/theme/theme_picker_sheet.dart';
import 'package:noteswidgetapp/core/theme/theme_provider.dart';
import 'package:noteswidgetapp/core/widget/widget_setup_helper.dart';
import 'package:noteswidgetapp/features/authentication/signin/repository.dart';
import 'package:noteswidgetapp/features/authentication/signin/view.dart';
import 'package:noteswidgetapp/features/profile/model/user_profile.dart';
import 'package:noteswidgetapp/features/profile/repository/user_profile_repository.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> with AutomaticKeepAliveClientMixin {
  UserProfile? _profile;
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = AppSupabase.currentUserId;
    if (uid == null) return;
    final profile = await UserProfileRepository().fetchProfile(uid);
    if (mounted) setState(() { _profile = profile; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: AppColors.selectedColor));
    }

    final name = _profile?.displayName ?? _profile?.username ?? 'User';
    final username = _profile?.username;
    final email = _profile?.email ?? AppSupabase.client.auth.currentUser?.email;

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
                    style: getBoldStyle(fontSize: 28, color: AppColors.selectedColor),
                  ),
                ),
                const SizedBox(height: 14),
                Text(name, style: getBoldStyle(fontSize: 20, color: AppColors.textColor)),
                if (username != null) ...[
                  const SizedBox(height: 4),
                  Text('@$username', style: getRegularStyle(color: AppColors.textColor2)),
                ],
                if (email != null) ...[
                  const SizedBox(height: 2),
                  Text(email, style: getRegularStyle(fontSize: 12, color: AppColors.textColor2)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _ActionTile(
          icon: Icons.widgets_outlined,
          title: 'Home screen widget',
          subtitle: 'Add or manage your note widget',
          onTap: () => WidgetSetupHelper.addWidgetToHomeScreen(context),
        ),
        const SizedBox(height: 8),
        _ActionTile(
          icon: Icons.palette_outlined,
          title: 'Change App Theme',
          subtitle: AppThemeProvider.instance.currentThemeName,
          onTap: () => ThemePickerSheet.show(context),
        ),
        const SizedBox(height: 8),
        _ActionTile(
          icon: Icons.sync_rounded,
          title: 'Sync status',
          subtitle: 'Real-time sync is active',
          onTap: () => AppConstants.showToast('Sync is running'),
        ),
        const SizedBox(height: 24),
        CustomButton(
          onTap: () => _signOut(context),
          label: 'Sign out',
          color: AppColors.btnColorLight,
          style: getMediumStyle(color: AppColors.textColorRed),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text('SyncNotes v1.0.0', style: getRegularStyle(fontSize: 11, color: AppColors.textColor2)),
        ),
      ],
    );
  }

  Future<void> _signOut(BuildContext context) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.selectedColor.withValues(alpha: 0.4),
      builder: (_) => const PopScope(
        canPop: false,
        child: CustomLoading(),
      ),
    );

    try {
      SharedNotePollService.instance.stop();
      await SharedNoteRealtimeService.instance.stop();
      await PushSyncService.clearTokenOnSignOut();
      await PushSyncService.dispose();
      await SignInRepository().signOut();
    } finally {
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }

    if (!context.mounted) return;
    AppConstants.showToast('Signed out');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      borderRadius: 18,
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.selectedColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.selectedColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: getSemiBoldStyle(fontSize: 14, color: AppColors.textColor)),
                Text(subtitle, style: getRegularStyle(fontSize: 12, color: AppColors.textColor2)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.textColor2, size: 18),
        ],
      ),
    );
  }
}
