/// MyPA — Environment configuration.
///
/// Only the Supabase URL and anon key belong here — both are safe to ship
/// in a client build because every table is protected by Row Level Security
/// (see Technical Design Document v1.3, Section 4). No provider secrets
/// (OpenRouter, social platform app secrets, etc.) are ever read from the
/// client; those live only in Supabase Edge Function environment variables
/// (Architecture Document v1.4, Section 6.1).
///
/// Values are supplied at build/run time via --dart-define, e.g.:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJ...
class Env {
  Env._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
