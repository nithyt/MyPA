import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';

/// Initializes the Supabase client once at app startup. Call this before
/// [runApp] in main.dart.
Future<void> initSupabase() async {
  if (!Env.isConfigured) {
    throw StateError(
      'Supabase is not configured. Pass --dart-define=SUPABASE_URL=... '
      'and --dart-define=SUPABASE_ANON_KEY=... when running/building the app. '
      'See docs/06-environment/MyPA_Environment_Setup_v1.0.docx.',
    );
  }

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
  );
}

/// Shorthand accessor used throughout the data layer.
SupabaseClient get supabase => Supabase.instance.client;
