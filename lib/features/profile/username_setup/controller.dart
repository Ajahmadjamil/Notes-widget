import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/constants/app_constants.dart';
import 'package:noteswidgetapp/core/navigation/auth_navigation.dart';
import 'package:noteswidgetapp/core/supabase/app_supabase.dart';
import 'package:noteswidgetapp/features/profile/repository/user_profile_repository.dart';

class UsernameSetupController with ChangeNotifier {
  final UserProfileRepository _repo = UserProfileRepository();

  final usernameController = TextEditingController();
  final usernameFocusNode = FocusNode();

  bool isLoading = false;

  Future<void> submit(BuildContext context) async {
    final authUser = AppSupabase.currentUser;
    if (authUser == null) {
      AppConstants.showToast('Not signed in');
      return;
    }

    final username = usernameController.text.trim();
    if (username.isEmpty) {
      AppConstants.showToast('Please enter a username');
      usernameFocusNode.requestFocus();
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      await _repo.claimUsername(authUser: authUser, username: username);
      if (!context.mounted) return;
      AppConstants.showToast('Username saved');
      await AuthNavigation.goAfterAuth(context);
    } on UsernameTakenException {
      AppConstants.showToast('Username is already taken');
    } on InvalidUsernameException catch (e) {
      AppConstants.showToast(e.message);
    } catch (e, stack) {
      if (kDebugMode) {
        print('Username save error: $e\n$stack');
      }
      try {
        final profile = await _repo.fetchProfile(authUser.id);
        if (profile != null && profile.hasUsername) {
          if (!context.mounted) return;
          AppConstants.showToast('Username saved');
          await AuthNavigation.goAfterAuth(context);
          return;
        }
      } catch (_) {}
      AppConstants.showToast('Could not save username: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    usernameFocusNode.dispose();
    super.dispose();
  }
}
