import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers/ai_models_provider.dart';
import '../../application/providers/settings_provider.dart';
import '../../domain/entities/ad.dart';
import '../widgets/ad_banner.dart';
import '../widgets/mypa_bottom_nav.dart';
import '../widgets/profile_menu.dart';
import '../widgets/voice_search_bar.dart';

/// The app shell: top ad banner, header (voice search + profile menu),
/// routed content area, bottom ad banner, and a bottom nav whose items
/// come from Settings — matching the requested Home screen spec and the
/// FDD Section 3.2 "Home / Dashboard" wireframe.
///
/// This mirrors the interactive HTML prototype demonstrated earlier in the
/// project, now as real Flutter widgets wired to live Supabase data instead
/// of mock JS state.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.child});

  /// The routed child for whichever nav destination is active
  /// (go_router's ShellRoute passes this in — see core/router.dart).
  final Widget child;

  int _indexForLocation(String location, List<NavModule> modules) {
    final moduleId = location == '/' ? 'home' : location.replaceFirst('/', '');
    final index = modules.indexWhere((m) => m.id == moduleId);
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modules = ref.watch(visibleNavModulesProvider);
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexForLocation(location, modules);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AdBanner(placement: AdPlacement.top),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: VoiceSearchBar(
                      onSubmitted: (query) {
                        // TODO: wire to the Create flow's guided step 1
                        // (FDD Section 3.2) once /create is implemented.
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ProfileMenu(
                    onSettings: () => context.push('/settings'),
                    onProfile: () => context.push('/profile'),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
            const AdBanner(placement: AdPlacement.bottom),
          ],
        ),
      ),
      bottomNavigationBar: MyPABottomNav(
        currentIndex: currentIndex,
        onDestinationSelected: (index) {
          final route = modules[index].id;
          context.go(route == 'home' ? '/' : '/$route');
        },
      ),
    );
  }
}

/// The Home tab's own content (dashboard cards) — separate from HomeShell,
/// which is the persistent wrapper around every tab.
class HomeDashboard extends ConsumerWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiModelsAsync = ref.watch(activeAiModelsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Good morning 👋', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI model for your next post', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                aiModelsAsync.when(
                  data: (models) {
                    if (models.isEmpty) {
                      return const Text('No AI models available — check your plan.');
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final model in models)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(model.displayName),
                            trailing: Text(
                              model.isFree
                                  ? 'Free'
                                  : '~${model.estimatedCreditsForDisplay()} credits',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => Text('Could not load AI models: $error'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // TODO: upcoming posts / recent performance cards
        // (FDD Section 3.2 Home / Dashboard wireframe) once the Content
        // Calendar and Analytics modules are implemented.
      ],
    );
  }
}
