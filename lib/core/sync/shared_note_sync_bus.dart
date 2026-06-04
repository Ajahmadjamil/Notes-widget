import 'dart:async';

import 'package:noteswidgetapp/features/shared_note/model/shared_note.dart';

/// Broadcasts inbound shared-note updates to editors and other listeners.
class SharedNoteSyncBus {
  SharedNoteSyncBus._();

  static final _controller = StreamController<SharedNote>.broadcast();

  static Stream<SharedNote> streamFor(String sharedNoteId) {
    return _controller.stream.where((n) => n.sharedNoteId == sharedNoteId);
  }

  static void emit(SharedNote note) {
    if (!_controller.isClosed) {
      _controller.add(note);
    }
  }
}
