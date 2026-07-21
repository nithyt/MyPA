import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/auth_provider.dart';

enum ProfileMenuAction { settings, profile, signOut }

/// Top-right profile avatar with a dropdown: Settings, Profile, Sign out —
/// matching the requested Home screen spec and FDD Section 2.2.
class ProfileMenu extends ConsumerWidget {
  const ProfileMenu({
    super.key,
    required this.onSettings,
    required this.onProfile,
    this.avatarUrl,
  });

  final VoidCallback onSettings;
  final VoidCallback onProfile;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final initials = _initialsFor(user?.email);

    return PopupMenuButton<ProfileMenuAction>(
      tooltip: 'Account',
      offset: const Offset(0, 44),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: ProfileMenuAction.settings,
          child: ListTile(leading: Icon(Icons.settings_outlined), title: Text('Settings')),
        ),
        const PopupMenuItem(
          value: ProfileMenuAction.profile,
          child: ListTile(leading: Icon(Icons.person_outline), title: Text('Profile')),
        ),
        const PopupMenuItem(
          value: ProfileMenuAction.signOut,
          child: ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Sign out', style: TextStyle(color: Colors.red)),
          ),
        ),
      ],
      onSelected: (action) async {
        switch (action) {
          case ProfileMenuAction.settings:
            onSettings();
          case ProfileMenuAction.profile:
            onProfile();
          case ProfileMenuAction.signOut:
            await ref.read(authRepositoryProvider).signOut();
        }
      },
      child: CircleAvatar(
        radius: 18,
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
        child: avatarUrl == null ? Text(initials) : null,
      ),
    );
  }

  String _initialsFor(String? email) {
    if (email == null || email.isEmpty) return '?';
    return email.substring(0, 1).toUpperCase();
  }
}
