import 'package:flutter/material.dart';

/// Matches FDD Section 5.2 (Team & Roles, Usage & Quotas, Approval Workflow,
/// Brand Asset Library). Only visible when the Admin module is enabled in
/// Settings and the signed-in user holds an admin/manager team_members role
/// (TDD Section 4.2) — that role gate still needs to be added here once
/// AccountRepository/TeamRepository exist; this stub does not yet check it.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Team, quota, and approval management — coming next.\n\n'
            'TODO: gate this screen behind an admin/manager role check '
            '(TDD Section 4.2) before it ships.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
