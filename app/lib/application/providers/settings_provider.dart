import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A module the user can show/hide in the bottom navigation, per the
/// Settings screen described in FDD Section 5.2 ("Settings — to select the
/// modules required, which shows up in the front page at the bottom as a
/// fixed button with icons").
class NavModule {
  const NavModule({
    required this.id,
    required this.label,
    required this.icon,
    this.alwaysOn = false,
  });

  final String id;
  final String label;
  final IconData icon;
  final bool alwaysOn;
}

const List<NavModule> kAllNavModules = [
  NavModule(id: 'home', label: 'Home', icon: Icons.home_outlined, alwaysOn: true),
  NavModule(id: 'create', label: 'Create', icon: Icons.edit_outlined, alwaysOn: true),
  NavModule(id: 'library', label: 'Library', icon: Icons.menu_book_outlined),
  NavModule(id: 'calendar', label: 'Calendar', icon: Icons.calendar_month_outlined),
  NavModule(id: 'admin', label: 'Admin', icon: Icons.shield_outlined),
];

class ModuleSelectionNotifier extends StateNotifier<Set<String>> {
  ModuleSelectionNotifier() : super({'home', 'create', 'library', 'calendar'});

  void toggle(String moduleId) {
    final module = kAllNavModules.firstWhere((m) => m.id == moduleId);
    if (module.alwaysOn) return;

    state = state.contains(moduleId)
        ? {...state}..remove(moduleId)
        : {...state, moduleId};
  }
}

final moduleSelectionProvider =
    StateNotifierProvider<ModuleSelectionNotifier, Set<String>>((ref) {
  return ModuleSelectionNotifier();
});

/// The modules to actually render in the bottom nav, in a stable order.
final visibleNavModulesProvider = Provider<List<NavModule>>((ref) {
  final selected = ref.watch(moduleSelectionProvider);
  return kAllNavModules.where((m) => selected.contains(m.id)).toList();
});
