import 'package:flutter/material.dart';

/// Matches FDD Section 3.2 "Prompt Library" wireframe.
///
/// TODO (Phase 1 build): read from the `prompt_library` table
/// (TDD Section 3.5), filter by category, and support the "Use" action
/// that loads a prompt into CreateScreen. System prompts are seeded in
/// supabase/migrations/20260721000005_seed_data.sql; the full documented
/// set lives in docs/05-user-docs/MyPA_Prompt_Library_v1.0.docx.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Prompt library — coming next.\n\n'
            'Backing data already seeded in prompt_library (see migration 5).',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
