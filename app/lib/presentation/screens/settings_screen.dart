import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/settings_provider.dart';

/// Lets the user choose which modules show up in the bottom nav — matching
/// the requested behavior and the interactive prototype demonstrated earlier.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(moduleSelectionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Modules shown at the bottom',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          for (final module in kAllNavModules)
            CheckboxListTile(
              value: selected.contains(module.id),
              onChanged: module.alwaysOn
                  ? null
                  : (_) => ref.read(moduleSelectionProvider.notifier).toggle(module.id),
              secondary: Icon(module.icon),
              title: Text(module.label),
              subtitle: module.alwaysOn ? const Text('Always on') : null,
            ),
        ],
      ),
    );
  }
}
