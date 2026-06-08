import 'package:noteswidgetapp/core/notes/drawing_data.dart';
import 'package:noteswidgetapp/core/notes/note_type.dart';
import 'package:noteswidgetapp/core/widget/home_widget_service.dart';
import 'package:noteswidgetapp/core/widget/widget_drawing_renderer.dart';
import 'package:noteswidgetapp/features/shared_note/model/shared_note.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local cache for the home screen widget (latest shared note preview).
class SharedNoteWidgetCache {
  SharedNoteWidgetCache._();

  static const _keyNoteId = 'widget_shared_note_id';
  static const _keyTitle = 'widget_shared_title';
  static const _keyBody = 'widget_shared_body';
  static const _keyUpdatedAt = 'widget_shared_updated_at';
  static const _keyFriendLabel = 'widget_friend_label';
  static const _keyNoteType = 'widget_note_type';
  static const _keyDrawingData = 'widget_drawing_data';

  static Future<void> updateFromNote(
    SharedNote note, {
    String friendLabel = '',
  }) {
    return update(
      sharedNoteId: note.sharedNoteId,
      title: note.title,
      body: note.body,
      updatedAt: note.updatedAt,
      friendLabel: friendLabel,
      noteType: note.noteType,
      drawingData: note.drawingData,
    );
  }

  static Future<void> update({
    required String sharedNoteId,
    required String title,
    required String body,
    required int updatedAt,
    String friendLabel = '',
    NoteType noteType = NoteType.text,
    String drawingData = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final label = friendLabel.isNotEmpty
        ? friendLabel
        : (prefs.getString(_keyFriendLabel) ?? '');

    await prefs.setString(_keyNoteId, sharedNoteId);
    await prefs.setString(_keyTitle, title);
    await prefs.setString(_keyBody, body);
    await prefs.setInt(_keyUpdatedAt, updatedAt);
    await prefs.setString(_keyNoteType, noteType.value);
    await prefs.setString(_keyDrawingData, drawingData);
    if (friendLabel.isNotEmpty) {
      await prefs.setString(_keyFriendLabel, friendLabel);
    }

    if (noteType == NoteType.drawing) {
      final data = DrawingData.decode(drawingData);
      final base64 = await WidgetDrawingRenderer.renderToBase64(data);
      final imagePath = await WidgetDrawingRenderer.renderToFile(data);
      await HomeWidgetService.updateDisplay(
        title: title,
        body: body,
        sharedNoteId: sharedNoteId,
        friendLabel: label,
        noteType: NoteType.drawing,
        drawingImagePath: imagePath,
        drawingBase64: base64,
      );
      return;
    }

    await HomeWidgetService.updateDisplay(
      title: title,
      body: body,
      sharedNoteId: sharedNoteId,
      friendLabel: label,
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
      'noteType': prefs.getString(_keyNoteType) ?? NoteType.text.value,
      'drawingData': prefs.getString(_keyDrawingData) ?? '',
    };
  }
}
