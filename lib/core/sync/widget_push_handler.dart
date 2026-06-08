import 'package:flutter/foundation.dart';
import 'package:noteswidgetapp/core/notes/note_type.dart';
import 'package:noteswidgetapp/core/supabase/app_supabase.dart';
import 'package:noteswidgetapp/core/sync/shared_note_inbound_sync.dart';
import 'package:noteswidgetapp/core/sync/shared_note_sync_bus.dart';
import 'package:noteswidgetapp/core/widget/shared_note_widget_cache.dart';
import 'package:noteswidgetapp/core/widget/widget_sync_policy.dart';
import 'package:noteswidgetapp/features/shared_note/model/shared_note.dart';
import 'package:noteswidgetapp/features/shared_note/repository/shared_note_repository.dart';

/// Applies shared-note FCM data → widget + editor (works when app is killed).
class WidgetPushHandler {
  WidgetPushHandler._();

  static const String dataType = 'widget_sync';

  static Future<void> applyFromData(Map<String, dynamic> data) async {
    if (data['type'] != dataType) return;

    final sharedNoteId = data['sharedNoteId'] as String?;
    if (sharedNoteId == null || sharedNoteId.isEmpty) return;

    final friendLabel = data['friendLabel'] as String? ?? '';
    final title = data['title'] as String? ?? 'Shared note';
    final body = data['body'] as String? ?? '';
    final noteType = NoteType.fromString(
      data['noteType'] as String? ?? data['note_type'] as String?,
    );
    final drawingData =
        data['drawingData'] as String? ?? data['drawing_data'] as String? ?? '';
    final updatedAt = int.tryParse('${data['updatedAt'] ?? ''}') ??
        DateTime.now().millisecondsSinceEpoch;

    if (kDebugMode) {
      print(
        'WidgetPushHandler: $sharedNoteId type=${noteType.value} incomplete=${_payloadIncomplete(data)}',
      );
    }

    // Always load the full note from Supabase (background + foreground).
    // FCM often has empty body for handwriting, or missing noteType on old pushes.
    try {
      await AppSupabase.initialize();
      final note = await SharedNoteRepository().fetchOnce(sharedNoteId);
      if (note != null) {
        await SharedNoteInboundSync.apply(
          note,
          friendLabel: friendLabel,
          force: true,
        );
        if (kDebugMode) {
          print(
            'WidgetPushHandler: synced from Supabase (${note.noteType.value}, body=${note.body.length}, drawing=${note.drawingData.length})',
          );
        }
        return;
      }
    } catch (e) {
      if (kDebugMode) print('WidgetPushHandler fetch error: $e');
    }

    await _applyPayloadToWidget(
      sharedNoteId: sharedNoteId,
      title: title,
      body: body,
      updatedAt: updatedAt,
      friendLabel: friendLabel,
      noteType: noteType,
      drawingData: drawingData,
    );
  }

  static bool _payloadIncomplete(Map<String, dynamic> data) {
    final body = (data['body'] as String? ?? '').trim();
    final noteTypeRaw = data['noteType'] as String? ?? data['note_type'] as String?;
    final drawingData =
        data['drawingData'] as String? ?? data['drawing_data'] as String? ?? '';
    if (noteTypeRaw == null || noteTypeRaw.isEmpty) return true;
    if (noteTypeRaw == 'drawing' && drawingData.isEmpty) return true;
    if (noteTypeRaw == 'text' && body.isEmpty) return true;
    return false;
  }

  static Future<void> _applyPayloadToWidget({
    required String sharedNoteId,
    required String title,
    required String body,
    required int updatedAt,
    required String friendLabel,
    required NoteType noteType,
    required String drawingData,
  }) async {
    if (!await WidgetSyncPolicy.shouldUpdateHomeWidget(sharedNoteId)) {
      if (kDebugMode) {
        print('WidgetPushHandler: skip widget for $sharedNoteId');
      }
      return;
    }

    final partial = SharedNote(
      sharedNoteId: sharedNoteId,
      friendshipId: '',
      user1: '',
      user2: '',
      title: title,
      body: body,
      createdAt: updatedAt,
      updatedAt: updatedAt,
      updatedBy: '',
      noteType: noteType,
      drawingData: drawingData,
    );
    SharedNoteSyncBus.emit(partial);

    if (noteType == NoteType.drawing) {
      await SharedNoteWidgetCache.update(
        sharedNoteId: sharedNoteId,
        title: title,
        body: '',
        updatedAt: updatedAt,
        friendLabel: friendLabel,
        noteType: NoteType.drawing,
        drawingData: drawingData,
      );
    } else {
      final displayBody = body.trim().isNotEmpty
          ? body
          : (title.trim().isNotEmpty && title != 'Shared note' ? title : body);
      await SharedNoteWidgetCache.update(
        sharedNoteId: sharedNoteId,
        title: title,
        body: displayBody,
        updatedAt: updatedAt,
        friendLabel: friendLabel,
      );
    }

    if (kDebugMode) {
      print('WidgetPushHandler: widget updated from FCM payload (${noteType.value})');
    }
  }
}
