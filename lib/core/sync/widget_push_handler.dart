import 'package:flutter/foundation.dart';
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

  /// [usePayloadOnly] — true in FCM background isolate (no network / no Supabase).
  static Future<void> applyFromData(
    Map<String, dynamic> data, {
    bool usePayloadOnly = false,
  }) async {
    if (data['type'] != dataType) return;

    final sharedNoteId = data['sharedNoteId'] as String?;
    if (sharedNoteId == null || sharedNoteId.isEmpty) return;

    final friendLabel = data['friendLabel'] as String? ?? '';
    final title = data['title'] as String? ?? 'Shared note';
    final body = data['body'] as String? ?? '';
    final updatedAt = int.tryParse('${data['updatedAt'] ?? ''}') ??
        DateTime.now().millisecondsSinceEpoch;

    if (kDebugMode) {
      print('WidgetPushHandler: $sharedNoteId payloadOnly=$usePayloadOnly');
    }

    if (usePayloadOnly) {
      await _applyPayloadToWidget(
        sharedNoteId: sharedNoteId,
        title: title,
        body: body,
        updatedAt: updatedAt,
        friendLabel: friendLabel,
      );
      return;
    }

    try {
      final note = await SharedNoteRepository().fetchOnce(sharedNoteId);
      if (note != null) {
        await SharedNoteInboundSync.apply(
          note,
          friendLabel: friendLabel,
          force: true,
        );
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
    );
  }

  static Future<void> _applyPayloadToWidget({
    required String sharedNoteId,
    required String title,
    required String body,
    required int updatedAt,
    required String friendLabel,
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
    );
    SharedNoteSyncBus.emit(partial);

    await SharedNoteWidgetCache.update(
      sharedNoteId: sharedNoteId,
      title: title,
      body: body,
      updatedAt: updatedAt,
      friendLabel: friendLabel,
    );

    if (kDebugMode) {
      print('WidgetPushHandler: widget updated from FCM payload');
    }
  }
}
