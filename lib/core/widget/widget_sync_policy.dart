import 'package:noteswidgetapp/core/widget/active_widget_note_service.dart';
import 'package:noteswidgetapp/core/widget/shared_note_widget_cache.dart';

/// When to push remote shared-note content to the home screen widget.
class WidgetSyncPolicy {
  WidgetSyncPolicy._();

  static Future<bool> shouldUpdateHomeWidget(String sharedNoteId) async {
    if (await ActiveWidgetNoteService.shouldSyncToWidget(sharedNoteId)) {
      return true;
    }
    final cached = await SharedNoteWidgetCache.read();
    final cachedId = cached?['sharedNoteId'] as String?;
    return cachedId != null && cachedId == sharedNoteId;
  }
}
