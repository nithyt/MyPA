import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_client.dart';

/// Wraps Supabase Auth. Kept thin — the point of the data layer is to be the
/// only place that knows about the Supabase SDK (Architecture v1.4, Section 4.2),
/// so the rest of the app never imports supabase_flutter directly.
class AuthRepository {
  const AuthRepository();

  Stream<AuthState> get onAuthStateChange => supabase.auth.onAuthStateChange;

  User? get currentUser => supabase.auth.currentUser;

  Future<void> signInWithEmail({required String email, required String password}) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUpWithEmail({required String email, required String password}) async {
    await supabase.auth.signUp(email: email, password: password);
  }

  /// Deep-link redirect must be registered per-platform (Android intent filter,
  /// iOS associated domain, etc.) — see Environment Setup Guide.
  Future<void> signInWithGoogle() async {
    await supabase.auth.signInWithOAuth(OAuthProvider.google);
  }

  Future<void> signInWithApple() async {
    await supabase.auth.signInWithOAuth(OAuthProvider.apple);
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}
