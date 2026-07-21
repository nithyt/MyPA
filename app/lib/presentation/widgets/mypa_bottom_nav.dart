import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/settings_provider.dart';

/// Fixed bottom navigation whose visible items are driven entirely by
/// which modules the user has enabled in Settings (FDD Section 5.2) —
/// matching the requested behavior: "Settings - to select the modules
/// required, which shows up in the front page at the bottom as fixed
/// button with icons."
class MyPABottomNav extends ConsumerWidget {
  const MyPABottomNav({super.key, required this.currentIndex, required this.onDestinationSelected});

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modules = ref.watch(visibleNavModulesProvider);

    return NavigationBar(
      selectedIndex: currentIndex.clamp(0, modules.length - 1),
      onDestinationSelected: onDestinationSelected,
      destinations: [
        for (final module in modules)
          NavigationDestination(icon: Icon(module.icon), label: module.label),
      ],
    );
  }
}
