import 'dart:io';

import 'package:noteswidgetapp/core/supabase/app_supabase.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class NoteMediaStorage {
  NoteMediaStorage._();

  static const bucket = 'note-media';
  static const _uuid = Uuid();

  static SupabaseClient get _client => AppSupabase.client;

  static String objectPath({
    required String ownerId,
    required String noteId,
    required String fileName,
  }) =>
      '$ownerId/$noteId/$fileName';

  static String sharedObjectPath({
    required String sharedNoteId,
    required String fileName,
  }) =>
      'shared/$sharedNoteId/$fileName';

  /// Uploads a local file; returns the storage object path.
  static Future<String> uploadFile({
    required String ownerId,
    required String noteId,
    required File file,
    required String mimeType,
  }) async {
    final ext = p.extension(file.path).isNotEmpty
        ? p.extension(file.path)
        : (mimeType.startsWith('audio/') ? '.m4a' : '.jpg');
    final name = '${_uuid.v4()}$ext';
    final path = objectPath(ownerId: ownerId, noteId: noteId, fileName: name);

    await _client.storage.from(bucket).upload(
          path,
          file,
          fileOptions: FileOptions(
            contentType: mimeType,
            upsert: false,
          ),
        );
    return path;
  }

  /// Shared-note media under `shared/{sharedNoteId}/…` (friendship RLS).
  static Future<String> uploadSharedFile({
    required String sharedNoteId,
    required File file,
    required String mimeType,
  }) async {
    final ext = p.extension(file.path).isNotEmpty
        ? p.extension(file.path)
        : (mimeType.startsWith('audio/') ? '.m4a' : '.jpg');
    final name = '${_uuid.v4()}$ext';
    final path = sharedObjectPath(sharedNoteId: sharedNoteId, fileName: name);

    await _client.storage.from(bucket).upload(
          path,
          file,
          fileOptions: FileOptions(
            contentType: mimeType,
            upsert: false,
          ),
        );
    return path;
  }

  static Future<String> createSignedUrl(String storagePath) async {
    return _client.storage.from(bucket).createSignedUrl(storagePath, 60 * 60);
  }

  static Future<void> deleteObject(String storagePath) async {
    if (storagePath.isEmpty) return;
    try {
      await _client.storage.from(bucket).remove([storagePath]);
    } catch (_) {
      // Best-effort cleanup; ignore missing objects.
    }
  }

  static Future<void> deleteMany(Iterable<String> paths) async {
    final list = paths.where((p) => p.isNotEmpty).toList();
    if (list.isEmpty) return;
    try {
      await _client.storage.from(bucket).remove(list);
    } catch (_) {}
  }
}
