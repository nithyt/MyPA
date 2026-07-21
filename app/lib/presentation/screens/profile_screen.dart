import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/auth_provider.dart';

/// Matches FDD Section 2.2 "Account & Subscription" wireframe.
/// TODO: wire to the accounts/subscriptions tables (TDD Section 3.1) once
/// an AccountRepository + provider exist — currently shows auth identity only.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email'),
            subtitle: Text(user?.email ?? 'Not signed in'),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.workspace_premium_outlined),
            title: Text('Plan'),
            subtitle: Text('TODO: read from subscriptions table (TDD Section 3.1)'),
          ),
          const ListTile(
            leading: Icon(Icons.link),
            title: Text('Connected accounts'),
            subtitle: Text('TODO: read from social_connections table (TDD Section 3.5)'),
          ),
        ],
      ),
    );
  }
}
