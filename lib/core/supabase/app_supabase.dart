import 'package:google_sign_in/google_sign_in.dart';
import 'package:noteswidgetapp/core/supabase/google_auth_config.dart';
import 'package:noteswidgetapp/core/supabase/schema_capabilities.dart';
import 'package:noteswidgetapp/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppSupabase {
  AppSupabase._();

  static bool _initialized = false;

  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;

  static String? get currentUserId => currentUser?.id;

  static Future<void> initialize() async {
    if (_initialized) return;

    if (!SupabaseConfig.isConfigured) {
      throw StateError(
        'Supabase is not configured. Copy lib/core/supabase/supabase_secrets.example.dart '
        'to supabase_secrets.dart or use --dart-define=SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }

    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );

    await GoogleSignIn.instance.initialize(
      serverClientId: GoogleAuthConfig.webClientId,
    );

    await SchemaCapabilities.ensureProbed(Supabase.instance.client);

    _initialized = true;
  }
}
