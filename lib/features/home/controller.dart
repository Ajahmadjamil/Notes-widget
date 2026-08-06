import 'package:flutter/foundation.dart';
import 'package:noteswidgetapp/core/supabase/app_supabase.dart';
import 'package:noteswidgetapp/core/widget/active_widget_note_service.dart';
import 'package:noteswidgetapp/features/profile/model/user_profile.dart';
import 'package:noteswidgetapp/features/profile/repository/user_profile_repository.dart';

/// Home tab state: welcome name, Mine/Shared segment, active widget note id.
class HomeTabController with ChangeNotifier {
  final UserProfileRepository _profileRepo = UserProfileRepository();

  int segment = 0;
  String userName = '';
  String? activeWidgetNoteId;
  bool _disposed = false;

  bool get isMineSelected => segment == 0;
  bool get isSharedSelected => segment == 1;

  Future<void> init() async {
    await Future.wait([
      loadUserName(),
      loadActiveWidgetNote(),
    ]);
  }

  void setSegment(int index) {
    if (segment == index) return;
    segment = index;
    _notify();
  }

  Future<void> loadUserName() async {
    final uid = AppSupabase.currentUserId;
    if (uid == null) return;

    final profile = await _profileRepo.fetchProfile(uid);
    final name = _resolveDisplayName(profile);
    if (_disposed) return;
    userName = name;
    _notify();
  }

  Future<void> loadActiveWidgetNote() async {
    final id = await ActiveWidgetNoteService.getActiveNoteId();
    if (_disposed) return;
    activeWidgetNoteId = id;
    _notify();
  }

  String _resolveDisplayName(UserProfile? profile) {
    final display = profile?.displayName?.trim();
    if (display != null && display.isNotEmpty) {
      return _capitalize(display.split(' ').first);
    }

    final username = profile?.username?.trim();
    if (username != null && username.isNotEmpty) {
      return _capitalize(username);
    }

    final email = profile?.email ?? AppSupabase.currentUser?.email;
    if (email != null && email.contains('@')) {
      return _capitalize(email.split('@').first);
    }

    return 'there';
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
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
