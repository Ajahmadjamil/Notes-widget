import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

class AudioRecorderService {
  AudioRecorderService();

  final AudioRecorder _recorder = AudioRecorder();
  final _uuid = const Uuid();

  String? _path;
  DateTime? _startedAt;
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  Future<bool> ensureMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> start({
    required String ownerId,
    required String noteId,
  }) async {
    if (_isRecording) return;
    final allowed = await ensureMicPermission();
    if (!allowed) {
      throw StateError('Microphone permission denied');
    }

    final root = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(root.path, 'note_media', ownerId, noteId));
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    _path = p.join(folder.path, 'aud_${_uuid.v4()}.m4a');
    _startedAt = DateTime.now();

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _path!,
    );
    _isRecording = true;
  }

  /// Stops recording and returns the file + duration in ms.
  Future<({File file, int durationMs})?> stop() async {
    if (!_isRecording) return null;
    final path = await _recorder.stop();
    _isRecording = false;
    final started = _startedAt;
    _startedAt = null;
    final resolved = path ?? _path;
    _path = null;
    if (resolved == null || resolved.isEmpty) return null;
    final file = File(resolved);
    if (!await file.exists()) return null;
    final durationMs = started == null
        ? 0
        : DateTime.now().difference(started).inMilliseconds;
    return (file: file, durationMs: durationMs);
  }

  Future<void> cancel() async {
    if (_isRecording) {
      await _recorder.stop();
      _isRecording = false;
    }
    final path = _path;
    _path = null;
    _startedAt = null;
    if (path != null) {
      final f = File(path);
      if (await f.exists()) {
        await f.delete();
      }
    }
  }

  Future<void> dispose() async {
    await cancel();
    await _recorder.dispose();
  }
}
