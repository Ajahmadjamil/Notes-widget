import 'supabase_secrets.dart' as secrets;

/// Supabase URL and anon key from --dart-define or [supabase_secrets.dart].
class SupabaseConfig {
  SupabaseConfig._();

  static String get url {
    const fromEnv = String.fromEnvironment('SUPABASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return secrets.supabaseUrl;
  }

  static String get anonKey {
    const fromEnv = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (fromEnv.isNotEmpty) return fromEnv;
    return secrets.supabaseAnonKey;
  }

  static bool get isConfigured =>
      url.isNotEmpty &&
      !url.contains('YOUR_PROJECT') &&
      anonKey.isNotEmpty &&
      !anonKey.contains('YOUR_ANON');
}
