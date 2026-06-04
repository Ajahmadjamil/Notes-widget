import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:noteswidgetapp/features/friends/repository/friends_repository.dart';
import 'package:noteswidgetapp/features/shared_note/editor/view.dart';

/// Opens the shared note editor from widget deep links.
class DeepLinkHandler {
  DeepLinkHandler._();

  static Uri? _pendingUri;

  static Future<void> captureWidgetLaunchUri() async {
    try {
      final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (uri != null) {
        _pendingUri = uri;
      }
    } catch (_) {}
  }

  static void listenForWidgetClicks(BuildContext context) {
    HomeWidget.widgetClicked.listen((uri) async {
      if (!context.mounted) return;
      await _openFromUri(context, uri);
    });
  }

  static Future<bool> openPendingSharedNote(BuildContext context) async {
    final uri = _pendingUri;
    _pendingUri = null;
    if (uri == null) return false;
    return _openFromUri(context, uri);
  }

  static Future<bool> _openFromUri(BuildContext context, Uri? uri) async {
    if (uri == null) return false;
    if (uri.host != 'shared-note') return false;

    final noteId = uri.queryParameters['noteId'];
    if (noteId == null || noteId.isEmpty) return false;

    final friendLabel = uri.queryParameters['friend'] ?? 'Shared note';
    String? friendUid;

    try {
      final friends = await FriendsRepository().fetchFriends();
      for (final f in friends) {
        if (f.sharedNoteId == noteId) {
          friendUid = f.friendUid;
          break;
        }
      }
    } catch (_) {}

    if (!context.mounted) return false;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SharedNoteEditorScreen(
          key: ValueKey('note_${friendUid ?? 'w'}_$noteId'),
          sharedNoteId: noteId,
          friendUid: friendUid,
          friendLabel: friendLabel,
        ),
      ),
    );
    return true;
  }
}
