import 'package:noteswidgetapp/core/widget/home_widget_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local cache for the home screen widget (latest shared note preview).
class SharedNoteWidgetCache {
  SharedNoteWidgetCache._();

  static const _keyNoteId = 'widget_shared_note_id';
  static const _keyTitle = 'widget_shared_title';
  static const _keyBody = 'widget_shared_body';
  static const _keyUpdatedAt = 'widget_shared_updated_at';
  static const _keyFriendLabel = 'widget_friend_label';

  static Future<void> update({
    required String sharedNoteId,
    required String title,
    required String body,
    required int updatedAt,
    String friendLabel = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNoteId, sharedNoteId);
    await prefs.setString(_keyTitle, title);
    await prefs.setString(_keyBody, body);
    await prefs.setInt(_keyUpdatedAt, updatedAt);
    if (friendLabel.isNotEmpty) {
      await prefs.setString(_keyFriendLabel, friendLabel);
    }

    await HomeWidgetService.updateDisplay(
      title: title,
      body: body,
      sharedNoteId: sharedNoteId,
      friendLabel: friendLabel.isNotEmpty
          ? friendLabel
          : (prefs.getString(_keyFriendLabel) ?? ''),
    );
  }

  static Future<Map<String, dynamic>?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_keyNoteId);
    if (id == null) return null;
    return {
      'sharedNoteId': id,
      'title': prefs.getString(_keyTitle) ?? '',
      'body': prefs.getString(_keyBody) ?? '',
      'updatedAt': prefs.getInt(_keyUpdatedAt) ?? 0,
      'friendLabel': prefs.getString(_keyFriendLabel) ?? '',
    };
  }
}
