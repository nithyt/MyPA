import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/providers/auth_provider.dart';
import '../presentation/screens/admin_screen.dart';
import '../presentation/screens/calendar_screen.dart';
import '../presentation/screens/create_screen.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/library_screen.dart';
import '../presentation/screens/login_screen.dart';
import '../presentation/screens/profile_screen.dart';
import '../presentation/screens/settings_screen.dart';

/// Bridges a Stream (Supabase's onAuthStateChange) to a Listenable, which is
/// what GoRouter's `refreshListenable` expects. This lets the router
/// re-evaluate its redirect logic the moment auth state changes, without
/// tearing down and recreating the whole GoRouter instance.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authRepository.onAuthStateChange),
    redirect: (context, state) {
      final isLoggedIn = authRepository.currentUser != null;
      final isGoingToLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !isGoingToLogin) return '/login';
      if (isLoggedIn && isGoingToLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      // Pushed on top of the shell, not a bottom-nav tab (FDD Section 2.2 —
      // Account/Settings are reached via the profile menu, not the nav bar).
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),

      // The shell wraps every bottom-nav tab in the persistent HomeShell
      // (ad banners, header, bottom nav) — see presentation/screens/home_screen.dart.
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomeDashboard()),
          GoRoute(path: '/create', builder: (context, state) => const CreateScreen()),
          GoRoute(path: '/library', builder: (context, state) => const LibraryScreen()),
          GoRoute(path: '/calendar', builder: (context, state) => const CalendarScreen()),
          GoRoute(path: '/admin', builder: (context, state) => const AdminScreen()),
        ],
      ),
    ],
  );
});
