import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:noteswidgetapp/core/sync/shared_note_inbound_sync.dart';

/// Foreground-only poll fallback when Realtime misses an update.
class SharedNotePollService {
  SharedNotePollService._();
  static final SharedNotePollService instance = SharedNotePollService._();

  Timer? _timer;
  bool _foreground = false;
  static const _interval = Duration(seconds: 15);

  void start() {
    _foreground = true;
    _restartTimer();
    if (kDebugMode) print('SharedNotePollService: started (foreground)');
  }

  void pause() {
    _foreground = false;
    _timer?.cancel();
    _timer = null;
    if (kDebugMode) print('SharedNotePollService: paused (background)');
  }

  void resume() {
    _foreground = true;
    _restartTimer();
    _tick();
  }

  void stop() {
    _foreground = false;
    _timer?.cancel();
    _timer = null;
  }

  void _restartTimer() {
    _timer?.cancel();
    if (!_foreground) return;
    _timer = Timer.periodic(_interval, (_) => _tick());
  }

  Future<void> _tick() async {
    if (!_foreground) return;

    try {
      await SharedNoteInboundSync.syncActiveWidgetNote();
    } catch (e) {
      if (kDebugMode && _foreground) {
        print('SharedNotePollService tick: $e');
      }
    }
  }
}
