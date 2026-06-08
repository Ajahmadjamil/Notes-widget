import 'package:noteswidgetapp/core/widget/home_widget_service.dart';
import 'package:noteswidgetapp/core/widget/shared_note_widget_cache.dart';
import 'package:noteswidgetapp/features/shared_note/repository/shared_note_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which friend's shared note is shown on the home screen widget.
class ActiveWidgetNoteService {
  ActiveWidgetNoteService._();

  static const _keyActiveNoteId = 'active_widget_shared_note_id';

  static Future<String?> getActiveNoteId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyActiveNoteId);
  }

  static Future<bool> shouldSyncToWidget(String sharedNoteId) async {
    final active = await getActiveNoteId();
    if (active == null || active.isEmpty) return false;
    return active == sharedNoteId;
  }

  /// Pins this friend's shared note to the home screen widget.
  static Future<void> setActiveFriendNote({
    required String sharedNoteId,
    required String friendLabel,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveNoteId, sharedNoteId);

    final note = await SharedNoteRepository().fetchOnce(sharedNoteId);
    if (note != null) {
      await SharedNoteWidgetCache.updateFromNote(note, friendLabel: friendLabel);
    } else {
      await HomeWidgetService.updateDisplay(
        title: 'Shared note',
        body: 'Open the app to load this note',
        sharedNoteId: sharedNoteId,
        friendLabel: friendLabel,
      );
    }
  }
}
