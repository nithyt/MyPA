import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mypa/application/providers/settings_provider.dart';

// NOTE: This is a minimal smoke test scaffold, not a full test suite.
// Testing MyPAApp directly requires a mocked Supabase client (initSupabase()
// hits a real network endpoint in main.dart) — wire that up with a fake/mock
// SupabaseClient before expanding this file, per the Test Plan Document
// (docs/04-qa/), Section 2 "Unit testing".
void main() {
  test('ModuleSelectionNotifier keeps always-on modules enabled', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(moduleSelectionProvider.notifier);

    // 'home' and 'create' are alwaysOn (settings_provider.dart) — toggling
    // them must be a no-op, matching FDD Section 5.2's "Always on" labels.
    notifier.toggle('home');
    expect(container.read(moduleSelectionProvider).contains('home'), isTrue);

    notifier.toggle('library');
    expect(container.read(moduleSelectionProvider).contains('library'), isFalse);
  });

  test('visibleNavModulesProvider reflects selection', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final initialCount = container.read(visibleNavModulesProvider).length;
    expect(initialCount, greaterThan(0));
  });
}
