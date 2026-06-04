import 'package:flutter/foundation.dart';
import 'package:noteswidgetapp/core/widget/shared_note_widget_cache.dart';
import 'package:noteswidgetapp/core/widget/widget_sync_policy.dart';

/// Applies shared-note FCM data to widget cache (silent, no UI).
class WidgetPushHandler {
  WidgetPushHandler._();

  static const String dataType = 'widget_sync';

  static Future<void> applyFromData(Map<String, dynamic> data) async {
    if (data['type'] != dataType) return;

    final sharedNoteId = data['sharedNoteId'] as String?;
    final title = data['title'] as String? ?? '';
    final body = data['body'] as String? ?? '';
    final updatedAt = int.tryParse('${data['updatedAt'] ?? ''}') ??
        DateTime.now().millisecondsSinceEpoch;
    final friendLabel = data['friendLabel'] as String? ?? '';

    if (sharedNoteId == null || sharedNoteId.isEmpty) return;

    if (!await WidgetSyncPolicy.shouldUpdateHomeWidget(sharedNoteId)) {
      if (kDebugMode) {
        print('WidgetPushHandler: skip $sharedNoteId (not active widget note)');
      }
      return;
    }

    if (kDebugMode) {
      print('WidgetPushHandler: silent widget update for $sharedNoteId');
    }

    await SharedNoteWidgetCache.update(
      sharedNoteId: sharedNoteId,
      title: title,
      body: body,
      updatedAt: updatedAt,
      friendLabel: friendLabel,
    );
  }
}
