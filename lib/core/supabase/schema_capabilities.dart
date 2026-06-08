import 'package:noteswidgetapp/core/supabase/app_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Whether `note_type` / `drawing_data` columns exist on Supabase tables.
class SchemaCapabilities {
  SchemaCapabilities._();

  static bool? _drawingNotesSupported;
  static Future<void>? _probeFuture;

  static bool get drawingNotesSupported => _drawingNotesSupported ?? false;

  static Future<void> ensureProbed([SupabaseClient? client]) {
    _probeFuture ??= _probe(client ?? AppSupabase.client);
    return _probeFuture!;
  }

  static Future<void> _probe(SupabaseClient client) async {
    try {
      await client.from('shared_notes').select('note_type').limit(1);
      _drawingNotesSupported = true;
    } on PostgrestException catch (e) {
      if (_isMissingColumn(e)) {
        _drawingNotesSupported = false;
      } else {
        _drawingNotesSupported = false;
      }
    } catch (_) {
      _drawingNotesSupported = false;
    }
  }

  static bool _isMissingColumn(PostgrestException e) =>
      e.code == '42703' || e.code == 'PGRST204';
}
