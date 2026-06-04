import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/constants/app_constants.dart';
import 'package:noteswidgetapp/core/navigation/auth_navigation.dart';
import 'package:noteswidgetapp/features/profile/repository/user_profile_repository.dart';

class UsernameSetupController with ChangeNotifier {
  final UserProfileRepository _repo = UserProfileRepository();

  final usernameController = TextEditingController();
  final usernameFocusNode = FocusNode();

  bool isLoading = false;

  Future<void> submit(BuildContext context) async {
    final authUser = FirebaseAuth.instance.currentUser;
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
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('Username FirebaseException: ${e.code} ${e.message}');
      }
      AppConstants.showToast('Database error: ${e.message ?? e.code}');
    } catch (e, stack) {
      if (kDebugMode) {
        print('Username save error: $e\n$stack');
      }
      // Profile may have saved; try continuing if username is already on file.
      try {
        final uid = authUser.uid;
        final profile = await _repo.fetchProfile(uid);
        if (profile != null && profile.hasUsername) {
          await _repo.repairSearchIndexes(uid);
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
