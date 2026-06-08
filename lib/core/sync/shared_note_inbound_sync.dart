import 'package:flutter/foundation.dart';
import 'package:noteswidgetapp/core/sync/shared_note_sync_bus.dart';
import 'package:noteswidgetapp/core/widget/active_widget_note_service.dart';
import 'package:noteswidgetapp/core/widget/shared_note_widget_cache.dart';
import 'package:noteswidgetapp/core/widget/widget_sync_policy.dart';
import 'package:noteswidgetapp/features/shared_note/model/shared_note.dart';
import 'package:noteswidgetapp/features/shared_note/repository/shared_note_repository.dart';

/// Applies a remote shared-note snapshot to widget cache + in-app listeners.
class SharedNoteInboundSync {
  SharedNoteInboundSync._();

  static final Map<String, int> _lastAppliedByNoteId = {};

  static Future<void> apply(
    SharedNote note, {
    String friendLabel = '',
    bool force = false,
  }) async {
    final prev = _lastAppliedByNoteId[note.sharedNoteId] ?? 0;
    final drawingChanged = note.isDrawing && note.drawingData.isNotEmpty;
    if (!force &&
        !drawingChanged &&
        note.updatedAt > 0 &&
        note.updatedAt <= prev) {
      return;
    }
    _lastAppliedByNoteId[note.sharedNoteId] = note.updatedAt;

    SharedNoteSyncBus.emit(note);

    if (!await WidgetSyncPolicy.shouldUpdateHomeWidget(note.sharedNoteId)) {
      if (kDebugMode) {
        print('InboundSync: skip widget for ${note.sharedNoteId}');
      }
      return;
    }

    if (kDebugMode) {
      print('InboundSync: widget + bus for ${note.sharedNoteId}');
    }

    await SharedNoteWidgetCache.updateFromNote(note, friendLabel: friendLabel);
  }

  /// Pull latest active widget note from Supabase (resume / poll fallback).
  static Future<void> syncActiveWidgetNote({String friendLabel = ''}) async {
    final activeId = await _activeNoteId();
    if (activeId == null || activeId.isEmpty) return;

    final note = await SharedNoteRepository().fetchOnce(activeId);
    if (note == null) return;

    await apply(note, friendLabel: friendLabel, force: true);
  }

  static Future<String?> _activeNoteId() async {
    final active = await ActiveWidgetNoteService.getActiveNoteId();
    if (active != null && active.isNotEmpty) return active;
    final cached = await SharedNoteWidgetCache.read();
    return cached?['sharedNoteId'] as String?;
  }
}
