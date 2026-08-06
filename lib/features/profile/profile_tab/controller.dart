import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/alerts/custom_loading.dart';
import 'package:noteswidgetapp/core/constants/app_constants.dart';
import 'package:noteswidgetapp/core/supabase/app_supabase.dart';
import 'package:noteswidgetapp/core/sync/push_sync_service.dart';
import 'package:noteswidgetapp/core/sync/shared_note_poll_service.dart';
import 'package:noteswidgetapp/core/sync/shared_note_realtime_service.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/features/authentication/signin/repository.dart';
import 'package:noteswidgetapp/features/authentication/signin/view.dart';
import 'package:noteswidgetapp/features/profile/model/user_profile.dart';
import 'package:noteswidgetapp/features/profile/repository/user_profile_repository.dart';

class ProfileTabController with ChangeNotifier {
  final UserProfileRepository _repo = UserProfileRepository();
  final SignInRepository _signInRepo = SignInRepository();

  UserProfile? profile;
  bool isLoading = true;
  bool _disposed = false;

  Future<void> load() async {
    final uid = AppSupabase.currentUserId;
    if (uid == null) {
      isLoading = false;
      _notify();
      return;
    }
    profile = await _repo.fetchProfile(uid);
    isLoading = false;
    _notify();
  }

  String get displayName =>
      profile?.displayName ?? profile?.username ?? 'User';

  String? get username => profile?.username;

  String? get email =>
      profile?.email ?? AppSupabase.client.auth.currentUser?.email;

  /// Tears down sync services and signs out. Caller shows loading + navigates.
  Future<void> signOut() async {
    SharedNotePollService.instance.stop();
    await SharedNoteRealtimeService.instance.stop();
    await PushSyncService.clearTokenOnSignOut();
    await PushSyncService.dispose();
    await _signInRepo.signOut();
  }

  Future<void> signOutAndNavigate(BuildContext context) async {
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
      await signOut();
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

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
