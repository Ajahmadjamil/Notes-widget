import 'package:noteswidgetapp/core/notes/document_data.dart';
import 'package:noteswidgetapp/core/supabase/app_supabase.dart';
import 'package:noteswidgetapp/core/supabase/schema_capabilities.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:noteswidgetapp/features/notes/model/note.dart';

class NotesSupabaseDataSource {
  SupabaseClient get _client => AppSupabase.client;

  Future<Map<String, Note>> fetchAllNotes(String uid) async {
    final rows = await _client
        .from('personal_notes')
        .select()
        .eq('user_id', uid);

    final result = <String, Note>{};
    for (final raw in rows as List) {
      final data = Map<String, dynamic>.from(raw as Map);
      final noteId = data['id'] as String;
      result[noteId] = Note.fromSupabase(noteId, data);
    }
    return result;
  }

  Future<void> saveNote(String uid, Note note) async {
    await SchemaCapabilities.ensureProbed(_client);

    final payload = <String, dynamic>{
      'id': note.noteId,
      'user_id': uid,
      'title': note.title,
      'body': note.body,
      'created_at': note.createdAt,
      'updated_at': note.updatedAt,
    };
    if (SchemaCapabilities.drawingNotesSupported) {
      payload['note_type'] = note.noteType.value;
      payload['drawing_data'] = note.drawingData;
    }
    if (SchemaCapabilities.documentNotesSupported) {
      // Never upload device-local file paths to the cloud.
      payload['document_data'] = _cloudDocumentData(note.documentData);
    }

    await _client.from('personal_notes').upsert(payload);
  }

  String _cloudDocumentData(String raw) {
    final doc = DocumentData.decode(raw);
    if (doc.blocks.isEmpty) return raw;
    final cleaned = doc.blocks
        .map((b) => b.copyWith(localPath: ''))
        .toList();
    return DocumentData(blocks: cleaned).encode();
  }

  Future<void> deleteNote(String uid, String noteId) async {
    await _client
        .from('personal_notes')
        .delete()
        .eq('user_id', uid)
        .eq('id', noteId);
  }
}
